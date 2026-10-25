# Experimental cluster-resampling methods for common-grid functional means.
# The resampling unit is the participant, NEVER individual trials.
.etr_seed_scope <- function(seed, operation) {
  .etr_assert(is.numeric(seed) && length(seed) == 1L && is.finite(seed) &&
                seed == as.integer(seed), "seed must be a finite integer")
  had <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had) prior <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (had) assign(".Random.seed", prior, envir = .GlobalEnv) else if
      (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
        rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(as.integer(seed))
  operation()
}

.etr_participant_matrix <- function(x, participant) {
  etr_validate(x, require_complete = TRUE)
  n <- dim(x$values)[1]
  if (length(participant) == 1L && is.character(participant) &&
      participant %in% names(x$metadata)) participant <- x$metadata[[participant]]
  .etr_assert(length(participant) == n && !anyNA(participant),
              "participant must identify every trajectory")
  ids <- unique(as.character(participant))
  group <- match(as.character(participant), ids)
  ng <- length(ids)
  .etr_assert(ng >= 3L, "requires at least three independent participants")
  nt <- length(x$time); nd <- dim(x$values)[3]
  z <- matrix(0, ng, nt * nd)
  for (g in seq_len(ng)) for (j in seq_len(nd)) for (t in seq_len(nt))
    z[g, (t - 1L) * nd + j] <- mean(x$values[group == g, t, j])
  list(matrix = z, participant_ids = ids, n_subjects = ng,
       n_time = nt, n_dim = nd, time = x$time,
       dimensions = x$dimension_names)
}
.etr_on_grid <- function(z, nt, nd) t(matrix(z, nrow = nd, ncol = nt))

#' Participant-cluster bootstrap confidence bands for functional means
#'
#' Treats independent participant-mean curves as the resampling units. Produces
#' exploratory pointwise percentile and max-standardized (fixed empirical SE) simultaneous bands.
#' No universal nominal-coverage guarantee is made for small clusters or
#' non-Gaussian, heteroskedastic or informative observation processes.
#' @param x Complete native common-grid trajectories.
#' @param participant Participant IDs per curve or metadata field.
#' @param B Number of cluster bootstrap replicates (>= 39).
#' @param alpha Target miscoverage probability in (0,1).
#' @param seed Deterministic RNG seed; R global RNG state restored.
#' @export
etr_bootstrap_mean_band <- function(x, participant, B = 399L, alpha = 0.05, seed = 1L) {
  g <- .etr_participant_matrix(x, participant)
  .etr_assert(is.numeric(B) && length(B) == 1L && is.finite(B) &&
                B == as.integer(B) && B >= 39L && B <= 20000L, "B must be integer 39 to 20000")
  .etr_assert(is.numeric(alpha) && length(alpha) == 1L &&
                is.finite(alpha) && alpha > 0 && alpha < 1,
              "alpha must be in (0,1)")
  z <- g$matrix; ng <- g$n_subjects
  mean_curve <- colMeans(z)
  se <- apply(z, 2L, stats::sd) / sqrt(ng)
  active <- which(se > .Machine$double.eps)
  .etr_assert(as.double(ncol(z)) * as.double(B) <= 1e7,
              "cluster mean bootstrap array exceeds 10 million cells")
  boots <- .etr_seed_scope(seed, function() {
    replicate(as.integer(B),
      colMeans(z[sample.int(ng, ng, replace = TRUE), , drop = FALSE]))
  })
  boots <- matrix(boots, nrow = ncol(z), ncol = as.integer(B))
  lower <- apply(boots, 1L, stats::quantile, probs = alpha / 2, names = FALSE)
  upper <- apply(boots, 1L, stats::quantile, probs = 1 - alpha / 2, names = FALSE)
  stat <- if (length(active)) {
    apply(abs(sweep(sweep(boots[active, , drop = FALSE], 1L,
                          mean_curve[active], "-"),
                    1L, se[active], "/")), 2L, max)
  } else rep(0, B)
  cutoff <- unname(stats::quantile(stat, probs = 1 - alpha, names = FALSE, type = 1))
  to_grid <- function(v) .etr_on_grid(v, g$n_time, g$n_dim)
  structure(list(mean = to_grid(mean_curve),
                 se = to_grid(se),
                 pointwise_lower = to_grid(lower),
                 pointwise_upper = to_grid(upper),
                 simultaneous_lower = to_grid(mean_curve - cutoff * se),
                 simultaneous_upper = to_grid(mean_curve + cutoff * se),
                 cutoff = cutoff, alpha = alpha, B = as.integer(B),
                 independent_clusters = ng, resampling_unit = "participant",
                 time = g$time, dimensions = g$dimensions,
                 method = "participant_mean_cluster_bootstrap_fixed_se_max_standardized"),
            class = "etr_mean_band")
}

#' Generate known-truth two-level synthetic functional trajectories
#'
#' Produces participant-level and trial-level stochastic variation around an
#' exactly specified functional population mean. The generator is independent
#' of the fitting and bootstrap functions.
#' @param n_subjects Number of independent participants, >= 3.
#' @param trials_per_subject Number of repeated trials, >= 2.
#' @param n_time Number of equally spaced common-grid measurements, >= 5.
#' @param subject_sd Standard deviation of subject random curve effects.
#' @param trial_sd Standard deviation of trial random curve effects.
#' @param noise_sd Standard deviation of sample-level measurement noise.
#' @param seed Generator RNG seed.
#' @export
etr_simulate_hierarchical <- function(n_subjects = 20L, trials_per_subject = 3L,
                                      n_time = 41L, subject_sd = 0.35,
                                      trial_sd = 0.15, noise_sd = 0.05, seed = 7L) {
  params <- c(n_subjects, trials_per_subject, n_time)
  .etr_assert(all(is.finite(params)) && all(params == as.integer(params)) &&
                n_subjects >= 3L && trials_per_subject >= 2L && n_time >= 5L,
              "at least 3 subjects, 2 trials per subject and 5 grid points required")
  scales <- c(subject_sd, trial_sd, noise_sd)
  .etr_assert(all(is.finite(scales)) && all(scales >= 0) &&
                subject_sd + trial_sd > 0, "nonnegative SDs and nondegenerate random curves required")
  .etr_seed_scope(seed, function() {
    time <- seq(0, 1, length.out = as.integer(n_time))
    mu <- cbind(sin(2*pi*time), cos(2*pi*time))
    subj <- rep(seq_len(n_subjects), each = trials_per_subject)
    n <- length(subj)
    effects <- matrix(stats::rnorm(n_subjects * 2L, sd = subject_sd), nrow = n_subjects)
    trials <- matrix(stats::rnorm(n * 2L, sd = trial_sd), nrow = n)
    values <- array(0, c(n, length(time), 2L))
    for (i in seq_len(n)) for (j in seq_len(2L)) {
      basis <- if (j == 1L) sin(pi * time) else cos(pi * time)
      values[i, , j] <- mu[, j] + (effects[subj[i], j] + trials[i, j]) * basis +
        stats::rnorm(length(time), sd = noise_sd)
    }
    trajectories <- etr_trajectory_set(time, values,
                         paste0("p", subj, "_t", rep(seq_len(trials_per_subject), n_subjects)),
                         c("x", "y"),
                         data.frame(participant = paste0("p", subj)),
                         coordinate_system = "normalized", time_unit = "s")
    list(trajectories = trajectories, participant = paste0("p", subj),
         truth_mean = mu, generating_parameters = list(subject_sd = subject_sd,
             trial_sd = trial_sd, noise_sd = noise_sd), seed = as.integer(seed))
  })
}

#' Independent finite-sample coverage simulation for cluster mean bands
#'
#' A Monte Carlo diagnostic, NOT a certificate of nominal frequentist coverage.
#' @param simulations Number of independently generated datasets.
#' @param B Number of bootstrap draws per dataset.
#' @param alpha Target miscoverage.
#' @param n_subjects Number of generated participants.
#' @param seed Initial deterministic seed.
#' @export
etr_evaluate_mean_band_coverage <- function(simulations = 20L, B = 99L,
                                             alpha = 0.10, n_subjects = 20L,
                                             seed = 100L) {
  .etr_assert(is.numeric(simulations) && length(simulations) == 1L &&
                is.finite(simulations) && simulations == as.integer(simulations) &&
                simulations >= 5L && simulations <= 500L,
              "simulations must be integer from 5 to 500")
  .etr_assert(is.numeric(seed) && length(seed) == 1L && is.finite(seed) &&
                seed == as.integer(seed), "seed must be finite integer")
  trials <- logical(as.integer(simulations))
  per_point <- numeric(as.integer(simulations))
  for (i in seq_len(simulations)) {
    sample <- etr_simulate_hierarchical(n_subjects = n_subjects, seed = seed + 2L*i)
    band <- etr_bootstrap_mean_band(sample$trajectories, sample$participant,
                                     B = B, alpha = alpha, seed = seed + 2L*i + 1L)
    inside <- sample$truth_mean >= band$simultaneous_lower &
      sample$truth_mean <= band$simultaneous_upper
    trials[i] <- all(inside)
    per_point[i] <- mean(sample$truth_mean >= band$pointwise_lower &
                         sample$truth_mean <= band$pointwise_upper)
  }
  p <- mean(trials)
  structure(list(simultaneous_coverage = p,
                 monte_carlo_se = sqrt(p*(1-p)/simulations),
                 mean_pointwise_coverage = mean(per_point),
                 simulations = simulations, B = B, alpha = alpha,
                 n_subjects = n_subjects, trials = trials,
                 evidence = "synthetic_known_truth_monte_carlo"),
            class = "etr_coverage_audit")
}
