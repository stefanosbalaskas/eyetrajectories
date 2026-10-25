#!/usr/bin/env Rscript
# Phase 3 coverage follow-up: empirical known-truth diagnostics, not validation.
# Run from project root: source("scripts/run_phase3_coverage_grid.R")
# Optional environment settings: ET_PHASE3_GRID_SIMS=100
# ET_PHASE3_GRID_B=399, ET_PHASE3_GRID_SUBJECTS=12,24,48
if (!file.exists("DESCRIPTION")) stop("Run from package repository root.")
if (!requireNamespace("eyetrajectories", quietly = TRUE))
  stop("Install eyetrajectories from the locally checked source first.")
parse_int <- function(key, fallback, lo, hi) {
  raw <- Sys.getenv(key, unset = as.character(fallback))
  x <- suppressWarnings(as.integer(raw))
  if (length(x) != 1L || is.na(x) || as.character(x) != raw ||
      x < lo || x > hi)
    stop(key, " must be an integer in [", lo, ", ", hi, "].")
  x
}
nsim <- parse_int("ET_PHASE3_GRID_SIMS", 100L, 5L, 500L)
B <- parse_int("ET_PHASE3_GRID_B", 399L, 39L, 20000L)
ns_text <- Sys.getenv("ET_PHASE3_GRID_SUBJECTS", unset = "12,24,48")
sizes <- suppressWarnings(as.integer(strsplit(ns_text, ",", fixed = TRUE)[[1L]]))
if (!length(sizes) || anyNA(sizes) ||
    any(sizes < 8L | sizes %% 2L != 0L) || anyDuplicated(sizes))
  stop("ET_PHASE3_GRID_SUBJECTS requires unique even participant counts >= 8.")
out <- file.path("artifacts", "phase3_coverage_grid")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
run_design <- function(method, n) {
  seed <- as.integer(101000L + 100L * n +
                       if (method == "participant_mean") 50000L else 0L)
  if (method == "group_contrast") {
    fit <- eyetrajectories::etr_evaluate_group_contrast_coverage(
      simulations = nsim, n_subjects = n, B = B, alpha = .1, seed = seed)
    cases <- fit$results
    pass <- as.logical(cases$simultaneous_inclusion)
  } else {
    fit <- eyetrajectories::etr_evaluate_mean_band_coverage(
      simulations = nsim, n_subjects = n, B = B, alpha = .1, seed = seed)
    pass <- as.logical(fit$trials)
    cases <- data.frame(
      simulation = seq_along(pass),
      simultaneous_inclusion = pass,
      mean_pointwise_inclusion = rep(NA_real_, length(pass)),
      contrast_rmse = rep(NA_real_, length(pass)))
  }
  if (length(pass) != nsim || anyNA(pass))
    stop("Incomplete or non-finite inclusion records.")
  k <- sum(pass)
  ci <- stats::binom.test(k, nsim, conf.level = .95)$conf.int
  cases$method <- method
  cases$n_subjects <- n
  cases$B <- B
  cases$alpha <- .1
  cases$seed <- seed
  cases <- cases[, c("method", "n_subjects", "B", "alpha", "seed",
                     "simulation", "simultaneous_inclusion",
                     "mean_pointwise_inclusion", "contrast_rmse")]
  tab <- data.frame(
    method = method, n_subjects = n,
    participants_per_group = if (method == "group_contrast") n/2L else NA_integer_,
    B = B, alpha = .1, seed = seed, simulations = nsim,
    included = k, excluded = nsim - k, observed_coverage = k/nsim,
    mc_se = sqrt((k/nsim)*(1-k/nsim)/nsim),
    exact_95_lower = ci[[1L]], exact_95_upper = ci[[2L]],
    nominal_reference = .9,
    mean_pointwise_inclusion = fit$mean_pointwise_coverage)
  list(cases = cases, summary = tab)
}
summaries <- list()
trials <- list()
failures <- list()
for (method in c("group_contrast", "participant_mean")) for (n in sizes) {
  label <- paste(method, n, sep = "_")
  cat("Starting ", label, " (", nsim, " studies; ", B,
      " bootstrap replicates)\n", sep = "")
  answer <- tryCatch(run_design(method, n), error = function(e) e)
  if (inherits(answer, "error")) {
    failures[[label]] <- data.frame(
      method = method, n_subjects = n,
      error = conditionMessage(answer))
    cat("DESIGN FAILED: ", conditionMessage(answer), "\n", sep = "")
  } else {
    summaries[[label]] <- answer$summary
    trials[[label]] <- answer$cases
  }
}
if (length(summaries)) {
  summary <- do.call(rbind, summaries)
  individual <- do.call(rbind, trials)
  rownames(summary) <- NULL
  rownames(individual) <- NULL
  utils::write.csv(summary, file.path(out, "coverage_grid_summary.csv"),
                   row.names = FALSE)
  utils::write.csv(individual, file.path(out, "coverage_grid_trials.csv"),
                   row.names = FALSE)
  print(summary, row.names = FALSE)
}
if (length(failures)) {
  utils::write.csv(do.call(rbind, failures),
                   file.path(out, "coverage_grid_failures.csv"),
                   row.names = FALSE)
}
sha <- tryCatch(system2("git", c("rev-parse", "HEAD"),
                        stdout = TRUE, stderr = FALSE),
                error = function(e) "unavailable")
if (!length(sha)) sha <- "unavailable"
writeLines(c(
  "Phase 3 synthetic coverage grid: NOT release qualification",
  paste("Run UTC:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste("R:", R.version.string),
  paste("Installed eyetrajectories version:",
        as.character(utils::packageVersion("eyetrajectories"))),
  paste("Source Git HEAD (does not verify installed package):", sha[1L]),
  paste("Studies per design:", nsim),
  paste("Bootstrap draws:", B),
  paste("Participants:", paste(sizes, collapse = ",")),
  "Simultaneous coverage target: 0.90",
  "Exact 95% binomial intervals reflect Monte Carlo precision, not calibration.",
  "All failed designs must be reported; outputs are exploratory."
), file.path(out, "MANIFEST.txt"))
cat("Wrote failure-inclusive audit in ", out, "\n", sep = "")
if (length(failures))
  stop("Some designs failed; inspect coverage_grid_failures.csv.")
