#!/usr/bin/env Rscript
# RESEARCH ONLY: independent, failure-inclusive observed-data pilot.
# Compares naive participant-balanced vs design-known Horvitz-Thompson
# POINT estimators. Does NOT construct confidence intervals or impute gaze.
# Run from checkout root:
#  source("scripts/run_missing_gaze_ipw_pilot.R")
# Options: ET_OBS_IPW_REPS=20, ET_OBS_IPW_SEED_OFFSET=330000000,
# ET_OBS_IPW_SEVERITY=moderate, ET_OBS_IPW_FAMILIES=gaussian_baseline
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION",fields="Package")[1L])!="eyetrajectories")
  stop("Run from the eyetrajectories checkout.",call.=FALSE)
source("scripts/observation_process_fixture.R",local=TRUE)
source("scripts/observation_ipw_research.R",local=TRUE)

int_env <- function(key,default,minvalue,maxvalue) {
  raw <- Sys.getenv(key,unset=as.character(default))
  value <- suppressWarnings(as.integer(raw))
  if (length(value)!=1L || is.na(value) || as.character(value)!=raw ||
      value<minvalue || value>maxvalue)
    stop("Invalid ",key,": integer required.",call.=FALSE)
  value
}
reps <- int_env("ET_OBS_IPW_REPS",20L,3L,200L)
offset <- int_env("ET_OBS_IPW_SEED_OFFSET",330000000L,
                  1000000L,1800000000L)
severity <- Sys.getenv("ET_OBS_IPW_SEVERITY",unset="moderate")
if (!severity %in% c("mild","moderate","severe"))
  stop("Invalid ET_OBS_IPW_SEVERITY.",call.=FALSE)
families <- strsplit(Sys.getenv("ET_OBS_IPW_FAMILIES",
                                unset="gaussian_baseline"),",",
                     fixed=TRUE)[[1L]]
allowed_families <- c("gaussian_baseline","heavy_t3",
                      "heteroskedastic_groups","skewed_lognormal")
if (!length(families) || anyDuplicated(families) ||
    !all(families %in% allowed_families))
  stop("Invalid ET_OBS_IPW_FAMILIES.",call.=FALSE)
mechanisms <- c("complete","mcar_gaze","mar_gaze","mar_dropout")
sizes <- c(12L,24L,48L)
conditions <- expand.grid(family=families,mechanism=mechanisms,
                           n_subjects=sizes,simulation=seq_len(reps),
                           stringsAsFactors=FALSE)
cell <- as.integer(interaction(conditions$family,conditions$mechanism,
                               conditions$n_subjects,drop=TRUE))
conditions$generator_seed <- as.numeric(offset)+
  100000L*cell+7L*conditions$simulation
conditions$mask_seed <- conditions$generator_seed+40000L
if (any(conditions$mask_seed>.Machine$integer.max) ||
    anyDuplicated(c(conditions$generator_seed,conditions$mask_seed)))
  stop("Generator/mask seed collision in requested design.",call.=FALSE)
conditions$generator_seed <- as.integer(conditions$generator_seed)
conditions$mask_seed <- as.integer(conditions$mask_seed)

root <- file.path("artifacts","missing_gaze_ipw_pilot")
prior_dirs <- if (dir.exists(root))
  list.dirs(root,recursive=FALSE,full.names=TRUE) else character()
prior_files <- file.path(prior_dirs,"ipw_trials.csv")
for (f in prior_files[file.exists(prior_files)]) {
  previous <- utils::read.csv(f,stringsAsFactors=FALSE)
  if (!all(c("generator_seed","mask_seed") %in% names(previous)))
    stop("Cannot verify prior seed provenance: ",f,call.=FALSE)
  overlap <- intersect(unique(c(conditions$generator_seed,
                                 conditions$mask_seed)),
                       unique(c(previous$generator_seed,
                                 previous$mask_seed)))
  if (length(overlap))
    stop("IPW SEED COLLISION PRECHECK: ",length(overlap),
         " reused seed(s); use a new ET_OBS_IPW_SEED_OFFSET.",
         call.=FALSE)
}
# Also block direct reuse of the FIRST-STAGE observed-data pilot seeds.
prior_first <- if (dir.exists(file.path("artifacts","missing_gaze_pilot")))
  list.dirs(file.path("artifacts","missing_gaze_pilot"),
            recursive=FALSE,full.names=TRUE) else character()
for (f in file.path(prior_first,"missing_gaze_trials.csv")) if(file.exists(f)) {
  previous <- utils::read.csv(f,stringsAsFactors=FALSE)
  if (!all(c("generator_seed","mask_seed") %in% names(previous)))
    stop("Prior first-stage archive has no readable seed keys.",call.=FALSE)
  if (length(intersect(unique(c(conditions$generator_seed,
                                 conditions$mask_seed)),
                       unique(c(previous$generator_seed,
                                 previous$mask_seed)))))
    stop("IPW SEED COLLISION WITH FIRST-STAGE PILOT.",call.=FALSE)
}
output <- file.path(root,paste0("run_",
  format(Sys.time(),"%Y%m%d_%H%M%S",tz="UTC"),"_pid",Sys.getpid()))
if (dir.exists(output)) stop("Output already exists.",call.=FALSE)
dir.create(output,recursive=TRUE,showWarnings=FALSE)
if (!dir.exists(output)) stop("Cannot create output.",call.=FALSE)

metrics <- c("mean_coordinate_support","minimum_group_participants_per_coordinate",
  "observed_fraction","observed_participants",
  "naive_mean_signed_supported","naive_mean_rmse_supported",
  "naive_contrast_signed_supported","naive_contrast_rmse_supported",
  "ht_mean_signed_supported","ht_mean_rmse_supported",
  "ht_contrast_signed_supported","ht_contrast_rmse_supported",
  "ht_mean_signed_all_grid","ht_mean_rmse_all_grid",
  "ht_contrast_signed_all_grid","ht_contrast_rmse_all_grid",
  "max_observed_ipw")
rows <- vector("list",nrow(conditions))
for (i in seq_len(nrow(conditions))) {
  spec <- conditions[i,,drop=FALSE]
  ans <- tryCatch({
    latent <- et_obs_generate_complete(
      n_subjects=spec$n_subjects,seed=spec$generator_seed,
      family=spec$family)
    mask <- et_obs_make_mask(latent,spec$mechanism,
                             seed=spec$mask_seed,severity=severity)
    observed <- et_obs_observed_only(latent,mask)
    if (nrow(observed$samples)!=sum(mask$keep))
      stop("Observed-data mask cardinality mismatch.")
    et_obs_ipw_point_diagnostics(observed,latent$truth_mean,
                                 latent$truth_contrast,severity=severity)
  },error=identity)
  record <- as.list(rep(NA_real_,length(metrics)))
  names(record) <- metrics
  if (inherits(ans,"error")) {
    status <- "numerical_failure"
    error <- conditionMessage(ans)
  } else {
    status <- ans$status
    error <- NA_character_
    for (key in metrics) record[[key]] <- ans[[key]]
  }
  rows[[i]] <- cbind(spec,severity=severity,status=status,error=error,
                      as.data.frame(record,stringsAsFactors=FALSE))
  if (i %% 20L==0L || i==nrow(conditions))
    cat("Known-design IPW pilot:",i,"/",nrow(conditions),"\n")
}
trial <- do.call(rbind,rows)
utils::write.csv(trial,file.path(output,"ipw_trials.csv"),
                 row.names=FALSE,na="")
groups <- split(trial,interaction(trial$family,trial$mechanism,
                                  trial$n_subjects,drop=TRUE))
safe_mean <- function(x) if(all(is.na(x))) NA_real_ else mean(x,na.rm=TRUE)
summary <- do.call(rbind,lapply(groups,function(z) {
  k <- sum(z$status=="success")
  n <- nrow(z)
  ci <- stats::binom.test(k,n)$conf.int
  data.frame(family=z$family[1L],mechanism=z$mechanism[1L],
    n_subjects=z$n_subjects[1L],severity=z$severity[1L],
    requested_datasets=n,full_grid_supported=k,
    no_observation_support=sum(z$status=="no_observation_support"),
    numerical_failures=sum(z$status=="numerical_failure"),
    support_rate=k/n,exact_95_lower=ci[1L],exact_95_upper=ci[2L],
    mean_coordinate_support=safe_mean(z$mean_coordinate_support),
    mean_observed_fraction=safe_mean(z$observed_fraction),
    naive_mean_rmse_supported=safe_mean(z$naive_mean_rmse_supported),
    ht_mean_rmse_supported=safe_mean(z$ht_mean_rmse_supported),
    naive_contrast_rmse_supported=safe_mean(z$naive_contrast_rmse_supported),
    ht_contrast_rmse_supported=safe_mean(z$ht_contrast_rmse_supported),
    ht_mean_signed_all_grid=safe_mean(z$ht_mean_signed_all_grid),
    ht_contrast_signed_all_grid=safe_mean(z$ht_contrast_signed_all_grid),
    ht_mean_rmse_all_grid=safe_mean(z$ht_mean_rmse_all_grid),
    ht_contrast_rmse_all_grid=safe_mean(z$ht_contrast_rmse_all_grid))
}))
rownames(summary) <- NULL
utils::write.csv(summary,file.path(output,"ipw_summary.csv"),
                 row.names=FALSE,na="")
writeLines(c(
  "RESEARCH ONLY: observed-data, design-known IPW point-estimate pilot",
  paste("timestamp_utc:",format(Sys.time(),"%Y-%m-%dT%H:%M:%SZ",
                              tz="UTC")),
  paste("seed_offset:",offset),
  paste("severity:",severity),
  paste("reps_per_cell:",reps),
  paste("families:",paste(families,collapse=",")),
  paste("generated_studies:",nrow(trial)),
  "Point methods: naive participant-balanced; design-known HT (not fitted PS).",
  "Eligible targets: full-population mean, full-population null contrast.",
  "MCAR/MAR generator design probabilities use OBSERVED Z/time only.",
  "All-grid HT errors include zero observed-cell contributions with fixed N*J scaling.",
  "Supported-coordinate naive/HT error is conditioned on grid support.",
  "Outcomes sharing a generating dataset are paired, not independent.",
  "No confidence bands, no coverage qualification, no native estimator changes."
),file.path(output,"manifest.txt"))
cat("KNOWN-DESIGN IPW PILOT FINISHED (not statistically qualified)\n",
    "Source output: ",normalizePath(output,winslash="/"),"\n",
    "Generated studies: ",nrow(trial),"\n",
    "Fully supported: ",sum(trial$status=="success"),"\n",
    "No support: ",sum(trial$status=="no_observation_support"),"\n",
    "Numerical failures: ",sum(trial$status=="numerical_failure"),"\n",
    "No CI coverage, estimator replacement or release authorization.\n",
    sep="")
