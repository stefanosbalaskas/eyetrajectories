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
# Allow explicit archive choices when multiple 2000-study runs exist.
select_archive <- function(n, env_key) {
  requested <- Sys.getenv(env_key, unset = "")
  if (!nzchar(requested)) return(archives[[choose(n)]])
  requested <- normalizePath(requested, winslash = "/", mustWork = TRUE)
  loc <- which(vapply(folders, function(folder)
    identical(normalizePath(folder, winslash = "/", mustWork = TRUE),
              requested), logical(1)))
  if (length(loc) != 1L || study_counts[loc] != n)
    stop(env_key, " must name a complete ", n,
         "-study-per-scenario archive.", call. = FALSE)
  archives[[loc]]
}
pilot <- select_archive(200L, "ET_CONFORMAL_PILOT_DIR")
replication <- select_archive(2000L, "ET_CONFORMAL_REPLICATION_DIR")

first_ids <- paste(pilot$study_seeds$scenario, pilot$study_seeds$seed)
second_ids <- paste(replication$study_seeds$scenario, replication$study_seeds$seed)
overlap <- intersect(first_ids, second_ids)
# A shared random seed is not by itself proof of identical output if code or
# input contracts changed. Verify EVERY matched alpha-level record.
if (length(overlap)) {
  fields <- c("status", "quantile_rank", "threshold", "null_score",
              "shifted_score", "null_flag", "shifted_flag")
  if (!all(fields %in% names(pilot$trials)) ||
      !all(fields %in% names(replication$trials)))
    stop("Cannot verify overlapping outputs: trial fields are missing.",
         call. = FALSE)
  match_p <- pilot$trials[
    paste(pilot$trials$scenario, pilot$trials$seed) %in% overlap,
    c("scenario", "seed", "alpha", fields), drop = FALSE]
  match_r <- replication$trials[
    paste(replication$trials$scenario, replication$trials$seed) %in% overlap,
    c("scenario", "seed", "alpha", fields), drop = FALSE]
  paired <- merge(match_p, match_r, by = c("scenario", "seed", "alpha"),
                  suffixes = c("_pilot", "_large"), sort = TRUE)
  expected <- length(overlap) * length(unique(pilot$summary$alpha))
  if (nrow(paired) != expected ||
      nrow(match_p) != expected || nrow(match_r) != expected)
    stop("Overlapping seed IDs do not have complete matching alpha records.",
         call. = FALSE)
  same_values <- function(a, b) {
    if (is.numeric(a) && is.numeric(b))
      return(isTRUE(all.equal(a, b, tolerance = 1e-10,
                              check.attributes = FALSE)))
    identical(as.vector(a), as.vector(b))
  }
  differing <- fields[!vapply(fields, function(field)
    same_values(paired[[paste0(field, "_pilot")]],
                paired[[paste0(field, "_large")]]), logical(1))]
  if (length(differing))
    stop("Overlapping seeds give DIFFERENT output records for: ",
         paste(differing, collapse = ", "),
         ". Cannot safely deduplicate; inspect code and manifests.",
         call. = FALSE)
}
new_ids <- setdiff(second_ids, first_ids)
total_unique <- length(union(first_ids, second_ids))
extra <- replication$trials[
  !(paste(replication$trials$scenario, replication$trials$seed) %in%
      first_ids), , drop = FALSE]
if (!nrow(extra))
  stop("Large archive contains no new generated datasets.", call. = FALSE)

summarize_new <- function(df) {
  success <- df$status == "ok"
  n <- sum(success)
  k <- sum(df$null_flag[success])
  ci <- if (n) stats::binom.test(k, n)$conf.int else c(NA_real_, NA_real_)
  data.frame(
    scenario = df$scenario[1L], alpha = df$alpha[1L],
    newly_generated_datasets = nrow(df),
    successful_fits = n, failed_fits = nrow(df) - n,
    false_alarms = k,
    false_alarm_rate = if (n) k / n else NA_real_,
    exact_95_lower = ci[1L], exact_95_upper = ci[2L])
}
new_cells <- split(extra, interaction(extra$scenario, extra$alpha, drop=TRUE))
novel_summary <- do.call(rbind, lapply(new_cells, summarize_new))
rownames(novel_summary) <- NULL
novel_summary <- novel_summary[order(novel_summary$alpha,
                                     novel_summary$scenario), , drop=FALSE]
p <- pilot$summary
r <- replication$summary
matches <- merge(
  p[, c("scenario", "alpha", "false_alarm_rate", "failed_datasets")],
  r[, c("scenario", "alpha", "false_alarm_rate", "failed_datasets",
        "false_alarm_exact_95_lower", "false_alarm_exact_95_upper",
        "successful_datasets")],
  by = c("scenario", "alpha"), suffixes = c("_pilot", "_large_archive")
)
matches$delta_large_minus_pilot <- with(
  matches, false_alarm_rate_large_archive - false_alarm_rate_pilot)
matches <- matches[order(matches$alpha, matches$scenario), , drop=FALSE]
rownames(matches) <- NULL

get_offset <- function(folder) {
  m <- grep("^Independent seed offset:",
            readLines(file.path(folder, "MANIFEST.txt"), warn=FALSE),
            value=TRUE)
  if (length(m)) trimws(sub("^Independent seed offset:", "", m[1L]))
  else "not recorded (likely legacy runner)"
}
cat("Pilot archive: ", normalizePath(pilot$path, winslash="/"), "\n", sep="")
cat("Larger archive: ", normalizePath(replication$path, winslash="/"),
    "\n", sep="")
cat("Recorded seed offsets (pilot / large): ",
    get_offset(pilot$path), " / ", get_offset(replication$path), "\n", sep="")
cat("Pilot generated datasets: ", pilot$study_count, "\n", sep="")
cat("Large archive generated datasets: ", replication$study_count,
    "\n", sep="")
cat("Reused scenario-specific seeds: ", length(overlap), "\n", sep="")
if (length(overlap))
  cat("Overlapping trial scores/flags/cutoffs: IDENTICAL at both alphas\n")
cat("Genuinely NEW datasets in large archive: ", length(new_ids), "\n", sep="")
cat("Unique generated datasets across BOTH archives: ",
    total_unique, "\n", sep="")
cat("All trial-summary/CI/paired-alpha checks: PASS\n")
if (length(overlap))
  cat("NOTE: the larger archive is an EXTENSION, not an independent replication.\n")
else
  cat("The large archive has no duplicated scenario-specific seeds.\n")
cat("\nEntire 2000-dataset-per-scenario archive (includes any reused pilot data):\n")
print(matches, row.names=FALSE)
cat("\nNew-only subset, excluding pilot scenario/seed IDs:\n")
print(novel_summary, row.names=FALSE)
# Read-only; all original archives are retained unmodified.
