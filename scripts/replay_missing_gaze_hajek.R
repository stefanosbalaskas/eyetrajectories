#!/usr/bin/env Rscript
# RESEARCH ONLY — DETERMINISTIC REPLAY OF THE SAME 240 DATASETS.
# Not a new independent replication and not scientific validation.
# Source archive and its exact seeds are READ ONLY and audit-checked.
# Reconstruction is accepted only when original saved HT/naive metrics
# are reproduced before attempting new Hájek analyses.
#
# Requires the owner-local first-stage 240-study archive.
#   Sys.setenv(ET_OBS_IPW_AUDIT_DIR =
#     "artifacts/missing_gaze_ipw_pilot/run_20261027_103444_pid51684")
#   source("scripts/replay_missing_gaze_hajek.R")
#   Sys.unsetenv("ET_OBS_IPW_AUDIT_DIR")
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION",fields="Package")[1L])!="eyetrajectories")
  stop("Run from eyetrajectories checkout.",call.=FALSE)
source("scripts/audit_missing_gaze_ipw_pilot.R",local=TRUE)
source("scripts/observation_process_fixture.R",local=TRUE)
source("scripts/observation_ipw_research.R",local=TRUE)
source("scripts/observation_hajek_research.R",local=TRUE)
source("scripts/analyze_missing_gaze_ipw_helpers.R",local=TRUE)

required <- c("generator_seed","mask_seed","n_subjects","family",
              "mechanism","severity","status",
              "mean_coordinate_support","observed_fraction",
              "observed_participants",
              "naive_mean_signed_supported","naive_mean_rmse_supported",
              "naive_contrast_signed_supported",
              "naive_contrast_rmse_supported",
              "ht_mean_signed_supported","ht_mean_rmse_supported",
              "ht_contrast_signed_supported","ht_contrast_rmse_supported",
              "ht_mean_signed_all_grid","ht_mean_rmse_all_grid",
              "ht_contrast_signed_all_grid","ht_contrast_rmse_all_grid")
if (!all(required %in% names(trials)))
  stop("Missing saved trial fields for exact replay.",call.=FALSE)
if (any(trials$status=="numerical_failure"))
  stop("This replay requires complete archived fit provenance; ",
       "numerical failure rows need a separate replay contract.",call.=FALSE)
if (anyDuplicated(c(trials$generator_seed,trials$mask_seed)))
  stop("Original seed uniqueness violated.",call.=FALSE)

same_numeric <- function(x,y,tol=1e-8) {
  if (length(x)!=1L || length(y)!=1L)
    return(FALSE)
  if (is.na(x) || is.na(y)) return(is.na(x) && is.na(y))
  if (!is.finite(x) || !is.finite(y)) return(FALSE)
  abs(x-y)<=tol*max(1,abs(x),abs(y))
}
metrics <- setdiff(required,c("generator_seed","mask_seed",
                              "n_subjects","family","mechanism",
                              "severity","status"))
point_metric <- function(est, truth, support) {
  if (!any(support)) return(c(signed=NA_real_,rmse=NA_real_))
  if (any(!is.finite(est[support])))
    stop("Undefined candidate on a supported coordinate.",call.=FALSE)
  e <- est[support]-truth[support]
  c(signed=mean(e),rmse=sqrt(mean(e^2)))
}

records <- vector("list",nrow(trials))
for (k in seq_len(nrow(trials))) {
  spec <- trials[k,,drop=FALSE]
  latent <- et_obs_generate_complete(as.integer(spec$n_subjects),
    as.integer(spec$generator_seed),family=as.character(spec$family))
  mask <- et_obs_make_mask(latent,as.character(spec$mechanism),
    as.integer(spec$mask_seed),severity=as.character(spec$severity))
  observed <- et_obs_observed_only(latent,mask)
  previous <- et_obs_ipw_point_diagnostics(observed,latent$truth_mean,
    latent$truth_contrast,severity=as.character(spec$severity))
  if (!identical(previous$status,as.character(spec$status)))
    stop("REPLAY STATUS MISMATCH at row ",k,call.=FALSE)
  for (field in metrics) {
    if(!same_numeric(previous[[field]],spec[[field]]))
      stop("REPLAY ARCHIVE MISMATCH row ",k," field ",field,
           "; refusing to compare methods.",call.=FALSE)
  }
  candidate <- et_obs_participant_hajek(
    observed,severity=as.character(spec$severity))
  if (!identical(previous$status,candidate$status) ||
      !identical(previous$common_support,candidate$support))
    stop("Replay candidate/common-group support mismatch at row ",
         k,call.=FALSE)
  hm <- point_metric(candidate$mean_estimate,latent$truth_mean,
                     previous$common_support)
  hc <- point_metric(candidate$contrast_estimate,latent$truth_contrast,
                     previous$common_support)
  records[[k]] <- cbind(spec,
    hajek_mean_signed_supported=unname(hm[1L]),
    hajek_mean_rmse_supported=unname(hm[2L]),
    hajek_contrast_signed_supported=unname(hc[1L]),
    hajek_contrast_rmse_supported=unname(hc[2L]),
    hajek_undefined_coordinates=candidate$undefined_coordinates)
  if (k%%20L==0L || k==nrow(trials))
    cat("Reproduced frozen archived study:",k,"/",nrow(trials),"\n")
}
replayed <- do.call(rbind,records)
rownames(replayed) <- NULL

groups <- split(replayed,interaction(replayed$family,replayed$mechanism,
                                     replayed$n_subjects,
                                     replayed$severity,drop=TRUE))
comparisons <- list()
q <- 0L
for (i in seq_along(groups)) {
  z <- groups[[i]]
  spec <- z[1L,c("family","mechanism","n_subjects","severity"),
             drop=FALSE]
  for (estimand in c("mean","contrast"))
    for (baseline in c("naive","ht"))
      for (support_set in c("available_coordinates","full_grid_only")) {
        work <- z
        # et_ipw_paired_accuracy expects 'naive' (baseline) and 'ht'
        # (candidate) fields. This is only a local adapter; output is
        # explicitly relabeled to avoid implying Hájek = old HT.
        for (suffix in c("rmse_supported","signed_supported")) {
          work[[paste0("naive_",estimand,"_",suffix)]] <-
            z[[paste0(baseline,"_",estimand,"_",suffix)]]
          work[[paste0("ht_",estimand,"_",suffix)]] <-
            z[[paste0("hajek_",estimand,"_",suffix)]]
        }
        q <- q+1L
        result <- et_ipw_paired_accuracy(work,estimand,support_set,
          bootstrap_seed=as.integer(1930000000L+100L*i+5L*q),B=1999L)
        result$baseline_method <- baseline
        result$candidate_method <- "participant_hajek"
        names(result) <- sub("^naive_mean_functional_rmse$",
                              "baseline_mean_functional_rmse",names(result))
        names(result) <- sub("^ht_mean_functional_rmse$",
                              "hajek_mean_functional_rmse",names(result))
        names(result) <- sub("^ht_naive_mean_rmse_ratio$",
                              "hajek_baseline_mean_rmse_ratio",names(result))
        names(result) <- sub("^ht_better_dataset_fraction$",
                              "hajek_better_dataset_fraction",names(result))
        names(result) <- sub("^naive_mean_signed_error$",
                              "baseline_mean_signed_error",names(result))
        names(result) <- sub("^ht_mean_signed_error$",
                              "hajek_mean_signed_error",names(result))
        comparisons[[q]] <- cbind(spec,result)
      }
}
report <- do.call(rbind,comparisons)
rownames(report) <- NULL
if (nrow(report)!=length(groups)*8L ||
    sum(report$requested_datasets)!=8L*nrow(trials) ||
    nrow(replayed)!=nrow(trials))
  stop("Replay denominator reconciliation failed.",call.=FALSE)

root <- file.path("artifacts","missing_gaze_hajek_replay")
out <- file.path(root,paste0("replay_",
  format(Sys.time(),"%Y%m%d_%H%M%S",tz="UTC"),"_pid",Sys.getpid()))
if (dir.exists(out)) stop("Replay output exists.",call.=FALSE)
dir.create(out,recursive=TRUE,showWarnings=FALSE)
if (!dir.exists(out)) stop("Cannot create new replay output.",call.=FALSE)
utils::write.csv(replayed,file.path(out,"replayed_studies.csv"),
                 row.names=FALSE,na="")
utils::write.csv(report,file.path(out,"paired_hajek_comparison.csv"),
                 row.names=FALSE,na="")
writeLines(c(
  "RESEARCH-ONLY replay of archived datasets, NOT new independent MC!",
  paste("source_archive:",chosen),
  paste("replayed_independent_datasets:",nrow(trials)),
  paste("matched_comparison_cells:",nrow(report)),
  "Every original naive/HT archive metric was first reproduced.",
  "Candidate: participant-normalized, baseline-inclusion-weighted Hájek.",
  "Complete-data candidate equality tested; missingness bias remains open.",
  "Mean is eligible-group-size weighted. Participant trial mean first.",
  "Undefined cells are NA: never a zero value or interpolated gaze.",
  "Mild/moderate/severe follow explicit archive mechanism severity.",
  "Point error comparisons on identical supported coordinates by dataset.",
  "Five unsupported original studies retained and status unchanged.",
  "Paired 1999-resample intervals quantify MC uncertainty in RMSE differences.",
  "No new generating seeds, no second independent experiment.",
  "NO confidence bands, MNAR claims, scientific certification, merge or CRAN."
),file.path(out,"manifest.txt"))
cat("PARTICIPANT HÁJEK DETERMINISTIC REPLAY COMPLETE (RESEARCH ONLY)\n",
 "Exact source archive: ",chosen,"\n",
 "Fresh analysis output: ",normalizePath(out,winslash="/"),"\n",
 "Original generating datasets verified: ",nrow(replayed),"\n",
 "Comparison rows: ",nrow(report),"\n",
 "No new independent Monte Carlo datasets.\n",sep="")
print(report[report$subset=="full_grid_only" &
                report$estimand=="mean",
  c("mechanism","n_subjects","baseline_method",
    "paired_datasets","baseline_mean_functional_rmse",
    "hajek_mean_functional_rmse","mean_paired_rmse_difference",
    "paired_difference_lower_95","paired_difference_upper_95")
],row.names=FALSE)
