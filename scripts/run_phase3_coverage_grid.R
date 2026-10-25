#!/usr/bin/env Rscript
# Exploratory known-truth coverage audit, not inferential qualification.
# Run from RStudio at the repository root:
#   source("scripts/run_phase3_coverage_grid.R")
# Configuration: ET_PHASE3_GRID_SIMS (100), ET_PHASE3_GRID_B (399),
# ET_PHASE3_GRID_SUBJECTS (12,24,48)
if (!file.exists("DESCRIPTION")) stop("Run from package repository root.")
if (!requireNamespace("eyetrajectories", quietly = TRUE))
  stop("Install the locally checked eyetrajectories source package first.")
parse_integer <- function(key, default, low, high) {
  raw <- Sys.getenv(key, unset = as.character(default))
  x <- suppressWarnings(as.integer(raw))
  if (length(x) != 1L || is.na(x) || as.character(x) != raw ||
      x < low || x > high)
    stop(key, " must be an integer from ", low, " through ", high)
  x
}
nsim <- parse_integer("ET_PHASE3_GRID_SIMS", 100L, 5L, 500L)
B <- parse_integer("ET_PHASE3_GRID_B", 399L, 39L, 20000L)
txt <- Sys.getenv("ET_PHASE3_GRID_SUBJECTS", unset = "12,24,48")
sizes <- suppressWarnings(as.integer(strsplit(txt, ",", fixed = TRUE)[[1L]]))
if (!length(sizes) || anyNA(sizes) ||
    any(sizes < 8L | sizes %% 2L != 0L) || anyDuplicated(sizes))
  stop("ET_PHASE3_GRID_SUBJECTS requires distinct even integers >= 8.")
out <- file.path("artifacts", "phase3_coverage_grid")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
run_one <- function(method, n_subjects, first_seed, index) {
  gen_seed <- first_seed + 2L * index
  fit_seed <- gen_seed + 1L
  template <- data.frame(
    method = method, n_subjects = n_subjects, B = B, alpha = .10,
    first_seed = first_seed, simulation = index, generator_seed = gen_seed,
    bootstrap_seed = fit_seed, status = "failed",
    simultaneous_inclusion = NA,
    mean_pointwise_inclusion = NA_real_,
    contrast_rmse = NA_real_, error = NA_character_
  )
  result <- tryCatch({
    if (method == "group_contrast") {
      sample <- eyetrajectories::etr_simulate_group_contrast(
        n_subjects = n_subjects, seed = gen_seed)
      fit <- eyetrajectories::etr_bootstrap_group_contrast(
        sample$trajectories, sample$participant, sample$treatment,
        B = B, alpha = .10, seed = fit_seed)
      truth <- sample$true_contrast
      estimated <- fit$difference
    } else {
      sample <- eyetrajectories::etr_simulate_hierarchical(
        n_subjects = n_subjects, seed = gen_seed)
      fit <- eyetrajectories::etr_bootstrap_mean_band(
        sample$trajectories, sample$participant,
        B = B, alpha = .10, seed = fit_seed)
      truth <- sample$truth_mean
      estimated <- fit$mean
    }
    pointwise <- truth >= fit$pointwise_lower & truth <= fit$pointwise_upper
    simultaneous <- truth >= fit$simultaneous_lower &
                    truth <= fit$simultaneous_upper
    if (anyNA(pointwise) || anyNA(simultaneous))
      stop("Non-finite or missing band-inclusion comparisons")
    template$status <- "ok"
    template$simultaneous_inclusion <- all(simultaneous)
    template$mean_pointwise_inclusion <- mean(pointwise)
    template$contrast_rmse <- if (method == "group_contrast")
      sqrt(mean((estimated - truth)^2)) else NA_real_
    template
  }, error = function(e) {
    template$error <- conditionMessage(e)
    template
  })
  result
}
run_design <- function(method, n) {
  seed <- as.integer(101000L + 100L * n +
    if (method == "participant_mean") 50000L else 0L)
  cases <- do.call(rbind, lapply(seq_len(nsim), function(i)
    run_one(method, n, seed, i)))
  ok <- cases$status == "ok"
  nfit <- sum(ok)
  k <- sum(cases$simultaneous_inclusion[ok])
  exact <- function(successes, n) {
    if (n == 0L) return(c(NA_real_, NA_real_))
    as.numeric(stats::binom.test(successes, n,
                                 conf.level = .95)$conf.int)
  }
  ci_cond <- exact(k, nfit)
  ci_oper <- exact(k, nsim)
  conditional <- if (nfit) k / nfit else NA_real_
  operational <- k / nsim
  pointwise <- if (nfit) mean(cases$mean_pointwise_inclusion[ok]) else NA_real_
  summary <- data.frame(
    method = method, n_subjects = n,
    participants_per_group = if (method == "group_contrast") n/2L else NA_integer_,
    B = B, alpha = .10, first_seed = seed, requested_studies = nsim,
    successful_fits = nfit, failed_fits = nsim - nfit,
    bands_containing_truth = k,
    conditional_coverage = conditional,
    conditional_mc_se = if (nfit)
      sqrt(conditional*(1-conditional)/nfit) else NA_real_,
    conditional_exact_95_lower = ci_cond[1L],
    conditional_exact_95_upper = ci_cond[2L],
    operational_success_fraction = operational,
    operational_exact_95_lower = ci_oper[1L],
    operational_exact_95_upper = ci_oper[2L],
    mean_pointwise_inclusion_among_fits = pointwise,
    nominal_reference = .90
  )
  list(cases = cases, summary = summary)
}
all_cases <- list()
all_summaries <- list()
for (method in c("group_contrast", "participant_mean")) for (n in sizes) {
  key <- paste(method, n, sep = "_")
  cat("Auditing ", key, ": ", nsim, " datasets, ", B,
      " bootstrap replicates per dataset\n", sep = "")
  ans <- run_design(method, n)
  all_cases[[key]] <- ans$cases
  all_summaries[[key]] <- ans$summary
  print(ans$summary, row.names = FALSE)
}
trials <- do.call(rbind, all_cases)
summary <- do.call(rbind, all_summaries)
rownames(trials) <- NULL
rownames(summary) <- NULL
utils::write.csv(summary, file.path(out, "coverage_grid_summary.csv"),
                 row.names = FALSE)
utils::write.csv(trials, file.path(out, "coverage_grid_trials.csv"),
                 row.names = FALSE)
if (any(trials$status != "ok")) {
  utils::write.csv(trials[trials$status != "ok", , drop = FALSE],
                   file.path(out, "coverage_grid_failures.csv"),
                   row.names = FALSE)
}
sha <- tryCatch(system2("git", c("rev-parse", "HEAD"),
                        stdout = TRUE, stderr = FALSE),
                error = function(e) "unavailable")
if (!length(sha)) sha <- "unavailable"
writeLines(c(
  "Experimental Phase 3 known-truth coverage grid — NOT release qualification",
  paste("Run UTC:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste("R:", R.version.string),
  paste("Installed package version:",
        as.character(utils::packageVersion("eyetrajectories"))),
  paste("Source Git HEAD (not proof of installed package identity):", sha[1L]),
  paste("Independent studies per design:", nsim),
  paste("Bootstrap replicates:", B),
  paste("Participants:", paste(sizes, collapse = ",")),
  "Target simultaneous coverage: 0.90",
  "Conditional coverage uses successfully fitted datasets only.",
  "Operational success treats failed fits as unsuccessful interval production.",
  "Both proportions and failure counts must be interpreted together.",
  "Exact binomial intervals describe Monte Carlo precision, not calibration."
), file.path(out, "MANIFEST.txt"))
cat("Wrote per-replicate, failure-inclusive outputs in ", out, "\n", sep = "")
if (any(trials$status != "ok"))
  stop("Some fits failed; inspect coverage_grid_failures.csv.",
       call. = FALSE)
