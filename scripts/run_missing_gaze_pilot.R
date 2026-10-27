#!/usr/bin/env Rscript
# Research-only missing-gaze engineering pilot; no interval estimation.
# Run from the eyetrajectories checkout:
#   source("scripts/run_missing_gaze_pilot.R")
# Options: ET_OBS_REPS=20, ET_OBS_SEVERITY=moderate,
#   ET_OBS_SEED_OFFSET=125000000, ET_OBS_FAMILIES=gaussian_baseline
# New independent replications MUST use new seed offsets.
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION", fields = "Package")[1L]) != "eyetrajectories")
  stop("Run from the eyetrajectories checkout.", call. = FALSE)
source("scripts/observation_process_fixture.R", local = TRUE)

strict_integer <- function(key, default, low, high) {
  value <- Sys.getenv(key, unset = as.character(default))
  x <- suppressWarnings(as.integer(value))
  if (is.na(x) || length(x) != 1L || as.character(x) != value ||
      x < low || x > high)
    stop("Invalid ", key, "; expected integer in [", low, ", ", high,
         "].", call. = FALSE)
  x
}
reps <- strict_integer("ET_OBS_REPS", 20L, 3L, 200L)
offset <- strict_integer("ET_OBS_SEED_OFFSET", 125000000L,
                          1000000L, 1800000000L)
severity <- Sys.getenv("ET_OBS_SEVERITY", unset = "moderate")
if (!severity %in% c("mild", "moderate", "severe"))
  stop("ET_OBS_SEVERITY must be mild, moderate or severe.", call. = FALSE)
families <- strsplit(Sys.getenv("ET_OBS_FAMILIES",
                     unset = "gaussian_baseline"), ",", fixed = TRUE)[[1L]]
supported_families <- c("gaussian_baseline", "heavy_t3",
                         "heteroskedastic_groups", "skewed_lognormal")
if (!length(families) || anyDuplicated(families) ||
    !all(families %in% supported_families))
  stop("Invalid ET_OBS_FAMILIES.", call. = FALSE)
mechanisms <- c("complete", "mcar_gaze", "mar_gaze", "mnar_gaze",
                 "mar_dropout", "mnar_dropout", "unequal_density",
                 "sparse_asynchronous")
sizes <- c(12L, 24L, 48L)
design <- expand.grid(family = families, mechanism = mechanisms,
                      n_subjects = sizes, simulation = seq_len(reps),
                      stringsAsFactors = FALSE)
# A separate complete dataset is generated for every mechanism-condition
# replicate. Multiple reported point metrics from one dataset are paired.
design$generator_seed <- as.numeric(offset) +
  100000L * as.numeric(interaction(design$family, design$mechanism,
                                  design$n_subjects, drop = TRUE)) +
  7L * design$simulation
design$mask_seed <- design$generator_seed + 40000L
if (any(design$mask_seed > .Machine$integer.max) ||
    anyDuplicated(design$generator_seed) ||
    anyDuplicated(design$mask_seed) ||
    any(design$mask_seed %in% design$generator_seed))
  stop("Generating-study seed collision inside design.", call. = FALSE)
design$generator_seed <- as.integer(design$generator_seed)
design$mask_seed <- as.integer(design$mask_seed)
root <- file.path("artifacts", "missing_gaze_pilot")
prior_dirs <- if (dir.exists(root))
  list.dirs(root, recursive = FALSE, full.names = TRUE) else character()
prior_files <- file.path(prior_dirs, "missing_gaze_trials.csv")
for (f in prior_files[file.exists(prior_files)]) {
  prior <- utils::read.csv(f, stringsAsFactors = FALSE)
  if (!all(c("generator_seed", "mask_seed") %in% names(prior)))
    stop("Previous archive lacks seeds, cannot check: ", f, call. = FALSE)
  both_new <- c(design$generator_seed, design$mask_seed)
  both_old <- c(prior$generator_seed, prior$mask_seed)
  collisions <- intersect(unique(both_new), unique(both_old))
  if (length(collisions))
    stop("MISSING-GAZE SEED COLLISION PRECHECK: ", length(collisions),
         " reused seeds in ", f,
         ". Choose a NEW ET_OBS_SEED_OFFSET; nothing was run.",
         call. = FALSE)
}
out <- file.path(root, paste0("run_", format(Sys.time(),
              "%Y%m%d_%H%M%S", tz = "UTC"), "_pid", Sys.getpid()))
if (dir.exists(out)) stop("Run archive already exists.", call. = FALSE)
dir.create(out, recursive = TRUE, showWarnings = FALSE)
if (!dir.exists(out)) stop("Cannot create research archive.", call. = FALSE)

rows <- vector("list", nrow(design))
for (k in seq_len(nrow(design))) {
  d <- design[k, , drop = FALSE]
  result <- tryCatch({
    latent <- et_obs_generate_complete(d$n_subjects, d$generator_seed,
                                      family = d$family)
    mask <- et_obs_make_mask(latent, d$mechanism, d$mask_seed,
                            severity = severity)
    observed <- et_obs_observed_only(latent, mask)
    if (anyNA(observed$samples$Y) ||
        nrow(observed$samples) != sum(mask$keep))
      stop("Observed-only fixture integrity failure.")
    score <- et_obs_naive_diagnostic(observed, latent$truth_mean,
                                    latent$truth_contrast)
    list(status = score$status, error = NA_character_,
         observed_participants = score$observed_participants,
         observed_fraction = score$observed_fraction,
         mean_supported_fraction = score$mean_supported_fraction,
         contrast_supported_fraction = score$contrast_supported_fraction,
         minimum_group_participants_per_coordinate =
           score$minimum_group_participants_per_coordinate,
         mean_bias_supported = score$mean_bias_supported,
         mean_rmse_supported = score$mean_rmse_supported,
         contrast_bias_supported = score$contrast_bias_supported,
         contrast_rmse_supported = score$contrast_rmse_supported)
  }, error = function(e) {
    list(status = "numerical_failure",
         error = conditionMessage(e), observed_participants = NA_integer_,
         observed_fraction = NA_real_,
         mean_supported_fraction = NA_real_,
         contrast_supported_fraction = NA_real_,
         minimum_group_participants_per_coordinate = NA_integer_,
         mean_bias_supported = NA_real_, mean_rmse_supported = NA_real_,
         contrast_bias_supported = NA_real_,
         contrast_rmse_supported = NA_real_)
  })
  rows[[k]] <- cbind(d, severity = severity, as.data.frame(result,
                      stringsAsFactors = FALSE))
  if (k %% 20L == 0L || k == nrow(design))
    cat("Observation pilot:", k, "/", nrow(design), "datasets\n")
}
trials <- do.call(rbind, rows)
trial_path <- file.path(out, "missing_gaze_trials.csv")
utils::write.csv(trials, trial_path, row.names = FALSE, na = "")
by_cell <- split(trials, interaction(trials$family, trials$mechanism,
                                     trials$n_subjects, drop = TRUE))
summary <- do.call(rbind, lapply(by_cell, function(z) {
  ok <- z$status == "success"
  num_mean <- function(column, valid = !is.na(column)) {
    if (!any(valid)) NA_real_ else mean(column[valid])
  }
  data.frame(family = z$family[1L], mechanism = z$mechanism[1L],
     n_subjects = z$n_subjects[1L], severity = z$severity[1L],
     requested_datasets = nrow(z),
     full_grid_supported = sum(ok),
     no_observation_support = sum(z$status == "no_observation_support"),
     numerical_failures = sum(z$status == "numerical_failure"),
     mean_observed_fraction = num_mean(z$observed_fraction),
     mean_support_fraction = num_mean(z$mean_supported_fraction),
     contrast_support_fraction = num_mean(z$contrast_supported_fraction),
     naive_mean_rmse_supported = num_mean(z$mean_rmse_supported),
     naive_contrast_rmse_supported = num_mean(z$contrast_rmse_supported))
}))
rownames(summary) <- NULL
utils::write.csv(summary, file.path(out, "missing_gaze_summary.csv"),
                 row.names = FALSE, na = "")
writeLines(c(
  "RESEARCH ONLY: observed-data engineering pilot, not coverage qualification",
  paste("date_utc:", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
  paste("seed_offset:", offset),
  paste("repetitions_per_cell:", reps),
  paste("severity:", severity),
  paste("families:", paste(families, collapse = ",")),
  paste("requested_independent_datasets:", nrow(design)),
  paste("archive_rows:", nrow(trials)),
  "Estimands: unconditional full-population mean, null full-population contrast",
  "Reported naive biases/RMSEs are restricted to supported coordinates.",
  "No confidence bands; no simultaneous coverage; no implicit imputation.",
  "MNAR mechanisms use latent outcomes only to generate masking.",
  "Sparse asynchronous grids are subsets of the 41-point master grid.",
  "Dataset independence is per generator seed; metrics within study are paired."
), file.path(out, "manifest.txt"))
cat("Research observation pilot archive:", normalizePath(out),
    "\nFailure-inclusive studies:", nrow(trials),
    "\nSuccess with full grid:", sum(trials$status == "success"),
    "\nNo-support:", sum(trials$status == "no_observation_support"),
    "\nNumerical failures:", sum(trials$status == "numerical_failure"),
    "\nNo interval calibration or release authorization follows.\n")
