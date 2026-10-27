#!/usr/bin/env Rscript
# Read-only, failure-inclusive archive reconciliation for missing-gaze pilot.
# Run from repo root after executing scripts/run_missing_gaze_pilot.R
# Optional ET_OBS_AUDIT_DIR points at a specific timestamped run.
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION", fields = "Package")[1L]) != "eyetrajectories")
  stop("Run from repository root.", call. = FALSE)
root <- file.path("artifacts", "missing_gaze_pilot")
path <- Sys.getenv("ET_OBS_AUDIT_DIR", unset = "")
if (!nzchar(path)) {
  dirs <- if (dir.exists(root))
    list.dirs(root, recursive = FALSE, full.names = TRUE) else character()
  dirs <- dirs[file.exists(file.path(dirs, "missing_gaze_trials.csv")) &
                 file.exists(file.path(dirs, "missing_gaze_summary.csv"))]
  if (!length(dirs)) stop("No completed pilot archive.", call. = FALSE)
  path <- dirs[order(basename(dirs), decreasing = TRUE)[1L]]
}
path <- normalizePath(path, winslash = "/", mustWork = TRUE)
trials <- utils::read.csv(file.path(path, "missing_gaze_trials.csv"),
                          stringsAsFactors = FALSE)
summary <- utils::read.csv(file.path(path, "missing_gaze_summary.csv"),
                           stringsAsFactors = FALSE)
req <- c("family", "mechanism", "n_subjects", "simulation",
         "generator_seed", "mask_seed", "severity", "status",
         "observed_fraction", "mean_supported_fraction",
         "contrast_supported_fraction", "mean_rmse_supported",
         "contrast_rmse_supported")
if (!all(req %in% names(trials)) || !nrow(trials) || !nrow(summary))
  stop("Missing required archive fields or empty archive.", call. = FALSE)
if (anyNA(trials[, c("family", "mechanism", "n_subjects", "simulation",
                      "generator_seed", "mask_seed", "severity", "status")]))
  stop("Missing study keys/status values.", call. = FALSE)
if (anyDuplicated(paste(trials$family, trials$mechanism,
                        trials$n_subjects, trials$simulation,
                        trials$severity, sep = ":")))
  stop("Duplicate condition/study keys.", call. = FALSE)
if (anyDuplicated(c(trials$generator_seed, trials$mask_seed)))
  stop("Generator or mask seed reused.", call. = FALSE)
allowed_status <- c("success", "no_observation_support",
                    "numerical_failure")
if (!all(trials$status %in% allowed_status))
  stop("Unrecognized status: no implicit failure conversion.", call. = FALSE)
valid <- trials$status != "numerical_failure"
for (field in c("observed_fraction", "mean_supported_fraction",
                "contrast_supported_fraction")) {
  z <- trials[[field]][valid]
  if (anyNA(z) || any(!is.finite(z)) || any(z < 0 | z > 1))
    stop("Invalid diagnostic fraction: ", field, call. = FALSE)
}
if (any(trials$status == "success" &
        trials$contrast_supported_fraction < 1))
  stop("Success declared without full contrast grid.", call. = FALSE)
if (any(trials$status == "success" &
        trials$mean_supported_fraction < 1))
  stop("Success declared without full mean grid.", call. = FALSE)
if (!all(c("requested_datasets", "full_grid_supported",
           "no_observation_support", "numerical_failures") %in%
         names(summary)))
  stop("Summary lacks failure-inclusive counts.", call. = FALSE)
for (s in seq_len(nrow(summary))) {
  z <- summary[s, , drop = FALSE]
  subset <- trials[trials$family == z$family &
                     trials$mechanism == z$mechanism &
                     trials$n_subjects == z$n_subjects &
                     trials$severity == z$severity, , drop = FALSE]
  if (!nrow(subset) || nrow(subset) != z$requested_datasets ||
      sum(subset$status == "success") != z$full_grid_supported ||
      sum(subset$status == "no_observation_support") !=
        z$no_observation_support ||
      sum(subset$status == "numerical_failure") != z$numerical_failures)
    stop("Trial/summary mismatch at summary row ", s, call. = FALSE)
  for (pair in list(
    c("observed_fraction", "mean_observed_fraction"),
    c("mean_supported_fraction", "mean_support_fraction"),
    c("contrast_supported_fraction", "contrast_support_fraction"),
    c("mean_bias_supported", "naive_mean_bias_supported"),
    c("mean_rmse_supported", "naive_mean_rmse_supported"),
    c("contrast_bias_supported", "naive_contrast_bias_supported"),
    c("contrast_rmse_supported", "naive_contrast_rmse_supported"))) {
    vals <- subset[[pair[1L]]]
    expected <- if (all(is.na(vals))) NA_real_ else mean(vals, na.rm = TRUE)
    actual <- z[[pair[2L]]]
    if (xor(is.na(actual), is.na(expected)) ||
        (!is.na(expected) && abs(expected - actual) > 1e-9))
      stop("Metric summary mismatch at row ", s, ": ", pair[2L],
           call. = FALSE)
  }
}
if (sum(summary$requested_datasets) != nrow(trials))
  stop("Reported cells do not exhaust all studies.", call. = FALSE)
cat("MISSING-GAZE ARCHIVE AUDIT PASS\n",
    "Independent generating studies: ", nrow(trials),
    "\nSummary cells: ", nrow(summary),
    "\nFull-grid supported: ", sum(trials$status == "success"),
    "\nNo support: ", sum(trials$status == "no_observation_support"),
    "\nNumerical failures: ", sum(trials$status == "numerical_failure"),
    "\nNo band coverage was evaluated. No research release authorized.\n",
    sep = "")
