#!/usr/bin/env Rscript
# Paired, failure-inclusive finite-sample coverage comparison.
# NOT a calibrated new estimator. Do not import results into an R release.
# Run from repo root: source("scripts/run_phase3_interval_comparison.R")
# Default: 30 independent studies per cell, B=199, sizes 12,24,48.
# Larger run: Sys.setenv(ET_INTERVAL_SIMS="100", ET_INTERVAL_B="399")
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION", fields = "Package")[1L]) != "eyetrajectories")
  stop("Run from the eyetrajectories repository root.", call. = FALSE)
if (!requireNamespace("pkgload", quietly = TRUE))
  stop("pkgload must be installed to use the exact source checkout.")
pkgload::load_all(".", quiet = TRUE)
get_int <- function(key, default, low, high) {
  txt <- Sys.getenv(key, unset = as.character(default))
  x <- suppressWarnings(as.integer(txt))
  if (length(x) != 1L || is.na(x) || as.character(x) != txt ||
      x < low || x > high)
    stop(key, " must be integer from ", low, " through ", high)
  x
}
nsim <- get_int("ET_INTERVAL_SIMS", 30L, 5L, 500L)
B <- get_int("ET_INTERVAL_B", 199L, 39L, 20000L)
alpha <- 0.10
sizes_txt <- Sys.getenv("ET_INTERVAL_SUBJECTS", unset = "12,24,48")
sizes <- suppressWarnings(as.integer(strsplit(sizes_txt, ",", fixed = TRUE)[[1L]]))
if (!length(sizes) || anyNA(sizes) || any(sizes < 8L | sizes %% 2L != 0L) ||
    anyDuplicated(sizes))
  stop("ET_INTERVAL_SUBJECTS must contain distinct even integers >= 8.")
out <- file.path("artifacts", "phase3_interval_comparison")
dir.create(out, recursive = TRUE, showWarnings = FALSE)

# Calculate per-participant curves by averaging replicated trials first.
# matrix(values, nrow=ncurves) has columns time-major within each channel;
# this is also the ordering of as.vector(time x channel truth).
participant_means <- function(sim) {
  v <- sim$trajectories$values
  obs <- matrix(v, nrow = dim(v)[1L])
  ids <- unique(as.character(sim$participant))
  z <- t(vapply(ids, function(id)
    colMeans(obs[as.character(sim$participant) == id, , drop = FALSE]),
    numeric(ncol(obs))))
  list(z = z, ids = ids)
}
# Exact two-sided marginal Student t + Bonferroni over all grid cells.
# Under the deliberately Gaussian independent-subject generator,
# this is a simultaneous >=(1-alpha) coverage *reference*, often very wide.
# It is NOT a universal interval recipe for real missing/heteroskedastic gaze.
bonferroni_reference <- function(sim, design) {
  p <- participant_means(sim)
  z <- p$z
  m <- ncol(z)
  if (design == "participant_mean") {
    estimate <- colMeans(z)
    se <- apply(z, 2L, stats::sd) / sqrt(nrow(z))
    df <- nrow(z) - 1L
    truth <- as.vector(sim$truth_mean)
  } else {
    g <- as.character(sim$treatment[match(p$ids, sim$participant)])
    a <- z[g == "control", , drop = FALSE]
    b <- z[g == "treatment", , drop = FALSE]
    n0 <- nrow(a)
    n1 <- nrow(b)
    if (n0 < 3L || n1 < 3L) stop("Both groups require >=3 participants")
    estimate <- colMeans(b) - colMeans(a)
    df <- n0 + n1 - 2L
    pooled <- ((n0 - 1L)*apply(a, 2L, stats::var) +
               (n1 - 1L)*apply(b, 2L, stats::var)) / df
    se <- sqrt(pmax(pooled, 0) * (1/n0 + 1/n1))
    truth <- as.vector(sim$true_contrast)
  }
  critical <- stats::qt(1-alpha/(2*m), df = df)
  lower <- estimate - critical*se
  upper <- estimate + critical*se
  if (any(!is.finite(c(lower, upper, truth))))
    stop("Non-finite oracle reference.")
  list(inside = all(truth >= lower & truth <= upper),
       mean_width = mean(upper-lower), critical = critical)
}
record <- function(design, n, i, seed, method, fit) {
  if (inherits(fit, "error")) {
    return(data.frame(design = design, n_subjects = n, simulation = i,
      generator_seed = seed, method = method, status = "failed",
      includes_truth = NA, mean_width = NA_real_,
      error = conditionMessage(fit)))
  }
  data.frame(design = design, n_subjects = n, simulation = i,
    generator_seed = seed, method = method, status = "ok",
    includes_truth = isTRUE(fit$inside), mean_width = fit$mean_width,
    error = NA_character_)
}
records <- list()
for (design in c("group_contrast", "participant_mean")) for (n in sizes) {
  cat("Comparing ", design, " at N=", n, " with ", nsim,
      " paired generated studies\n", sep = "")
  for (i in seq_len(nsim)) {
    seed <- as.integer(310000L + 1000L*n + 2L*i +
      if (design == "participant_mean") 70000L else 0L)
    sample <- tryCatch(
      if (design == "group_contrast") {
        eyetrajectories::etr_simulate_group_contrast(
          n_subjects = n, n_time = 41L, seed = seed)
      } else {
        eyetrajectories::etr_simulate_hierarchical(
          n_subjects = n, n_time = 41L, seed = seed)
      }, error = function(e) e)
    if (inherits(sample, "error")) {
      records[[length(records)+1L]] <- record(
        design, n, i, seed, "fixed_se_cluster_bootstrap", sample)
      records[[length(records)+1L]] <- record(
        design, n, i, seed, "gaussian_t_bonferroni_reference", sample)
      next
    }
    baseline <- tryCatch({
      fit <- if (design == "group_contrast")
        eyetrajectories::etr_bootstrap_group_contrast(
          sample$trajectories, sample$participant, sample$treatment,
          B = B, alpha = alpha, seed = seed + 1L)
      else eyetrajectories::etr_bootstrap_mean_band(
          sample$trajectories, sample$participant,
          B = B, alpha = alpha, seed = seed + 1L)
      lo <- as.vector(fit$simultaneous_lower)
      hi <- as.vector(fit$simultaneous_upper)
      truth <- as.vector(if (design == "group_contrast")
        sample$true_contrast else sample$truth_mean)
      if (any(!is.finite(c(lo, hi, truth))))
        stop("Non-finite baseline interval")
      list(inside = all(truth >= lo & truth <= hi),
           mean_width = mean(hi - lo))
    }, error = function(e) e)
    reference <- tryCatch(
      bonferroni_reference(sample, design), error = function(e) e)
    records[[length(records)+1L]] <- record(
      design, n, i, seed, "fixed_se_cluster_bootstrap", baseline)
    records[[length(records)+1L]] <- record(
      design, n, i, seed, "gaussian_t_bonferroni_reference", reference)
  }
}
trials <- do.call(rbind, records)
rownames(trials) <- NULL
summaries <- lapply(split(trials, list(
  trials$design, trials$n_subjects, trials$method), drop = TRUE),
  function(df) {
    ok <- df$status == "ok"
    nfit <- sum(ok)
    k <- sum(df$includes_truth[ok])
    ci <- if (nfit) as.numeric(stats::binom.test(k, nfit)$conf.int)
          else c(NA_real_, NA_real_)
    data.frame(design = df$design[1L], n_subjects = df$n_subjects[1L],
       method = df$method[1L], requested = nrow(df), fitted = nfit,
       fit_failures = nrow(df)-nfit,
       covered = k, conditional_coverage = if (nfit) k/nfit else NA_real_,
       exact_95_lower = ci[1L], exact_95_upper = ci[2L],
       operational_coverage = k/nrow(df),
       mean_band_width = if (nfit) mean(df$mean_width[ok]) else NA_real_,
       target = 1-alpha)
  })
summary <- do.call(rbind, summaries)
rownames(summary) <- NULL
utils::write.csv(trials, file.path(out, "paired_interval_trials.csv"),
                 row.names = FALSE)
utils::write.csv(summary, file.path(out, "paired_interval_summary.csv"),
                 row.names = FALSE)
errors <- trials[trials$status != "ok", , drop = FALSE]
failed_file <- file.path(out, "paired_interval_failures.csv")
if (nrow(errors)) utils::write.csv(errors, failed_file, row.names = FALSE)
else if (file.exists(failed_file)) unlink(failed_file)
writeLines(c(
  "Exploratory paired interval audit; NOT a new qualified estimator",
  paste("Run UTC:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste("Source R package:",
    unname(read.dcf("DESCRIPTION", fields = "Version")[1L])),
  paste("R:", R.version.string),
  paste("Simulated independent studies per cell:", nsim),
  paste("Bootstrap draws per current-band fit:", B),
  paste("N:", paste(sizes, collapse = ",")),
  "Full common grid: 41 x 2; alpha=0.10; 90% nominal reference.",
  "Two methods are evaluated on exactly the same generated datasets.",
  "Bonferroni uses finite-sample marginal Student t with 82-cell multiplicity.",
  "Two-group comparator assumes equal marginal variances and Gaussian sampling.",
  "It is conservative under the stated independent Gaussian DGP only.",
  "Wider bands may outperform narrow ones; examine width, not coverage alone.",
  "Original production R uncertainty functions are UNCHANGED.",
  "No guarantee outside this Gaussian synthetic data-generating process."
), file.path(out, "MANIFEST.txt"))
print(summary, row.names = FALSE)
cat("Saved paired interval audit to ",
    normalizePath(out, winslash = "/"), "\n", sep = "")
if (nrow(errors))
  stop("Some interval calculations failed; inspect paired_interval_failures.csv")
