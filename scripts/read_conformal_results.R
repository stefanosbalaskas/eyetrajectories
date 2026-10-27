# Read and validate archived conformal Monte Carlo output from the
# current eyetrajectories source checkout. This does NOT refit models.
#
# source("scripts/read_conformal_results.R")
# Optional: Sys.setenv(ET_CONFORMAL_RUN_DIR =
#   "artifacts/conformal_monte_carlo/run_YYYYMMDD_HHMMSS_pidNNNN")
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION", fields = "Package")[1L]) !=
      "eyetrajectories") {
  stop("Run from the eyetrajectories project root.", call. = FALSE)
}
base <- file.path("artifacts", "conformal_monte_carlo")
manual <- Sys.getenv("ET_CONFORMAL_RUN_DIR", unset = "")
if (nzchar(manual)) {
  run_dir <- manual
} else {
  if (!dir.exists(base))
    stop("No conformal run directory exists: ", base, call. = FALSE)
  candidates <- list.dirs(base, full.names = TRUE, recursive = FALSE)
  candidates <- candidates[
    grepl("^run_[0-9]{8}_[0-9]{6}_pid[0-9]+$", basename(candidates))
  ]
  candidates <- candidates[
    file.exists(file.path(candidates, "conformal_summary.csv")) &
    file.exists(file.path(candidates, "conformal_trials.csv"))
  ]
  if (!length(candidates))
    stop("No complete archived conformal run found in ", base,
         call. = FALSE)
  run_dir <- candidates[order(basename(candidates), decreasing = TRUE)][1L]
}
summary_file <- file.path(run_dir, "conformal_summary.csv")
trials_file <- file.path(run_dir, "conformal_trials.csv")
if (!file.exists(summary_file) || !file.exists(trials_file))
  stop("The selected run has no summary and/or trial records: ",
       run_dir, call. = FALSE)

results <- utils::read.csv(summary_file, stringsAsFactors = FALSE)
trials <- utils::read.csv(trials_file, stringsAsFactors = FALSE)
essential <- c("scenario", "alpha", "requested_datasets",
               "successful_datasets", "failed_datasets", "false_alarm_rate",
               "false_alarm_exact_95_lower", "false_alarm_exact_95_upper",
               "continuous_rank_reference", "shifted_detection_rate")
if (!all(essential %in% names(results)))
  stop("Summary file is missing required fields.", call. = FALSE)
if (!all(c("scenario", "alpha", "status", "simulation") %in% names(trials)))
  stop("Trial file is missing required fields.", call. = FALSE)
if (nrow(trials) != sum(results$requested_datasets) ||
    any(results$requested_datasets !=
        results$successful_datasets + results$failed_datasets)) {
  stop("Summary counts disagree with archived trial records.", call. = FALSE)
}
for (i in seq_len(nrow(results))) {
  cell <- trials[
    trials$scenario == results$scenario[i] &
    abs(trials$alpha - results$alpha[i]) < 1e-12, , drop = FALSE
  ]
  if (nrow(cell) != results$requested_datasets[i] ||
      sum(cell$status == "ok") != results$successful_datasets[i] ||
      sum(cell$status == "failed") != results$failed_datasets[i]) {
    stop("Mismatch between trial records and summary at cell ", i,
         call. = FALSE)
  }
}
selection <- results[, essential, drop = FALSE]
selection <- selection[order(selection$alpha, selection$scenario), ,
                       drop = FALSE]
rownames(selection) <- NULL
cat("Archived conformal run: ",
    normalizePath(run_dir, winslash = "/", mustWork = TRUE),
    "\n", sep = "")
cat("Independent simulated datasets (not scenario-alpha rows): ",
    length(unique(paste(trials$scenario, trials$simulation))), "\n", sep = "")
cat("Scenario-alpha evaluation rows: ", nrow(trials), "\n", sep = "")
print(selection, row.names = FALSE)
cat("\nOnly iid-exchangeable scores have the classical no-ties rank reference.\n")
cat("This is a pilot audit, not certified anomaly-control or confidence bands.\n")
