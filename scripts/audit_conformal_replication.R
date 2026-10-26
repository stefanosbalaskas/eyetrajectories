# Read-only, failure-inclusive comparison of archived conformal experiments.
# No R package imports or simulation reruns.
# After pulling the research branch:
#   source("scripts/audit_conformal_replication.R")
root <- file.path("artifacts", "conformal_monte_carlo")
if (!dir.exists(root)) stop("No archived conformal runs found.", call. = FALSE)
folders <- list.dirs(root, recursive = FALSE, full.names = TRUE)
folders <- folders[
  grepl("^run_[0-9]{8}_[0-9]{6}_pid[0-9]+$", basename(folders))
]
folders <- folders[vapply(folders, function(p) all(file.exists(
  file.path(p, c("conformal_summary.csv", "conformal_trials.csv", "MANIFEST.txt"))
)), logical(1))]
if (!length(folders)) stop("No complete conformal archives found.", call. = FALSE)

check_run <- function(folder) {
  sm <- utils::read.csv(file.path(folder, "conformal_summary.csv"),
                        stringsAsFactors = FALSE)
  tr <- utils::read.csv(file.path(folder, "conformal_trials.csv"),
                        stringsAsFactors = FALSE)
  fields <- c("scenario", "alpha", "requested_datasets", "successful_datasets",
              "failed_datasets", "observed_false_alarms", "observed_shifted_detections",
              "false_alarm_rate", "false_alarm_exact_95_lower",
              "false_alarm_exact_95_upper")
  if (!all(fields %in% names(sm)) ||
      !all(c("scenario", "alpha", "simulation", "seed", "status",
             "null_flag", "shifted_flag", "null_score", "shifted_score",
             "threshold") %in% names(tr))) {
    stop("Missing required fields in archive: ", folder, call. = FALSE)
  }
  if (nrow(tr) != sum(sm$requested_datasets))
    stop("Summary/trial count discrepancy: ", folder, call. = FALSE)
  for (i in seq_len(nrow(sm))) {
    cell <- tr[tr$scenario == sm$scenario[i] &
      abs(tr$alpha - sm$alpha[i]) < 1e-12, , drop = FALSE]
    ok <- cell$status == "ok"
    if (anyNA(ok)) stop("Unknown trial statuses: ", folder, call. = FALSE)
    n <- sum(ok)
    misses <- nrow(cell) - n
    positives <- sum(cell$null_flag[ok])
    detections <- sum(cell$shifted_flag[ok])
    if (nrow(cell) != sm$requested_datasets[i] ||
        n != sm$successful_datasets[i] ||
        misses != sm$failed_datasets[i] ||
        positives != sm$observed_false_alarms[i] ||
        detections != sm$observed_shifted_detections[i]) {
      stop("Summary and trials disagree at row ", i, ": ", folder,
           call. = FALSE)
    }
    if (n > 0L) {
      ci <- stats::binom.test(positives, n)$conf.int
      if (abs(positives/n - sm$false_alarm_rate[i]) > 1e-9 ||
          abs(ci[1L] - sm$false_alarm_exact_95_lower[i]) > 1e-6 ||
          abs(ci[2L] - sm$false_alarm_exact_95_upper[i]) > 1e-6) {
        stop("Rates or exact intervals disagree: ", folder, call. = FALSE)
      }
    }
  }
  key <- paste(tr$scenario, tr$simulation, sep = "/")
  key_seeds <- unique(tr[, c("scenario", "simulation", "seed"), drop = FALSE])
  if (anyDuplicated(key_seeds[, c("scenario", "simulation")]) ||
      anyDuplicated(key_seeds[, c("scenario", "seed")])) {
    stop("Repeated Monte Carlo generating-study identifiers: ", folder,
         call. = FALSE)
  }
  # Split once, rather than rescan every trial row for each study.
  study_groups <- split(tr, key)
  for (identifier in names(study_groups)) {
    d <- study_groups[[identifier]]
    d <- d[order(d$alpha), , drop = FALSE]
    if (nrow(d) != length(unique(sm$alpha))) {
      stop("Missing alpha evaluation for study ", identifier, call. = FALSE)
    }
    if (all(d$status == "ok")) {
      if (max(d$null_score)-min(d$null_score) > 1e-10 ||
          max(d$shifted_score)-min(d$shifted_score) > 1e-10 ||
          any(diff(d$threshold) > 1e-10) ||
          any(diff(as.integer(d$null_flag)) < 0L) ||
          any(diff(as.integer(d$shifted_flag)) < 0L)) {
        stop("Paired-alpha consistency failed in ", identifier, call. = FALSE)
      }
    }
  }
  list(summary = sm, trials = tr, study_seeds = key_seeds,
       study_count = nrow(key_seeds), path = folder)
}
archives <- lapply(folders, check_run)
study_counts <- vapply(archives, function(x) {
  n <- unique(x$summary$requested_datasets)
  if (length(n) != 1L) stop("Unequal per-cell replication sizes")
  n
}, integer(1))
choose <- function(n) {
  k <- which(study_counts == n)
  if (!length(k)) stop("Cannot locate ", n, "-study-per-scenario archive.")
  k[order(basename(folders[k]), decreasing = TRUE)][1L]
}
pilot <- archives[[choose(200L)]]
replication <- archives[[choose(2000L)]]
first_ids <- paste(pilot$study_seeds$scenario, pilot$study_seeds$seed)
second_ids <- paste(replication$study_seeds$scenario, replication$study_seeds$seed)
overlap <- intersect(first_ids, second_ids)
if (length(overlap))
  stop("Pilot and replication reuse ", length(overlap),
       " scenario-specific seeds. They are NOT disjoint experiments.",
       call. = FALSE)
p <- pilot$summary
r <- replication$summary
matches <- merge(
  p[, c("scenario", "alpha", "false_alarm_rate", "failed_datasets")],
  r[, c("scenario", "alpha", "false_alarm_rate", "failed_datasets",
        "false_alarm_exact_95_lower", "false_alarm_exact_95_upper",
        "successful_datasets")],
  by = c("scenario", "alpha"), suffixes = c("_pilot", "_replication")
)
matches$delta_replication_minus_pilot <- with(
  matches, false_alarm_rate_replication - false_alarm_rate_pilot)
matches <- matches[order(matches$alpha, matches$scenario), , drop = FALSE]
rownames(matches) <- NULL
cat("Pilot archive: ", normalizePath(pilot$path, winslash = "/"), "\n", sep = "")
cat("Replication archive: ",
    normalizePath(replication$path, winslash = "/"), "\n", sep = "")
cat("Independent pilot generating datasets: ", pilot$study_count, "\n",
    sep = "")
cat("Independent new replication generating datasets: ",
    replication$study_count, "\n", sep = "")
cat("Overlapping scenario/seed pairs: ", length(overlap), "\n", sep = "")
cat("All archived trial-summary, exact-CI and paired-alpha checks: PASS\n")
print(matches, row.names = FALSE)
# Deliberately do not write or overwrite scientific simulation artifacts.
