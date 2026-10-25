# Independent participant bootstrap spectrum and analytic variance checks.
#' Bootstrap sign-invariant dense FPCA eigenvalues by participant
#'
#' A participant-resampled sampling distribution for the eigenvalues of
#' participant-mean trajectories. Every bootstrap refits PCA completely.
#' Percentile intervals are exploratory; ties and small clusters may impair
#' coverage. Replicate failures remain visible instead of being dropped.
#' @param x Complete common-grid native trajectory collection.
#' @param participant Participant ID per curve or metadata column.
#' @param n_components Fixed retained component count.
#' @param B Number of bootstrap replicates (39-5000).
#' @param alpha Target miscoverage fraction (0,1).
#' @param seed RNG seed.
#' @export
etr_bootstrap_fpca_spectrum <- function(x, participant,
                                        n_components = 2L, B = 199L,
                                        alpha = .10, seed = 1L) {
  z <- .etr_participant_matrix(x, participant)
  ns <- z$n_subjects; nt <- z$n_time; nd <- z$n_dim
  .etr_assert(ns >= 6L, "FPCA spectrum bootstrap requires >= 6 participants")
  .etr_assert(is.numeric(n_components) && length(n_components) == 1L &&
    is.finite(n_components) && n_components == as.integer(n_components) &&
    n_components >= 1L && n_components <= ns-1L,
    "n_components must be integer 1 to n_participants-1")
  .etr_assert(is.numeric(B) && length(B) == 1L && is.finite(B) &&
    B == as.integer(B) && B >= 39L && B <= 5000L,
    "B must be integer 39 to 5000")
  .etr_assert(is.numeric(alpha) && length(alpha) == 1L &&
    is.finite(alpha) && alpha > 0 && alpha < 1, "alpha must lie in (0,1)")
  values <- array(0, c(ns, nt, nd))
  for (i in seq_len(ns)) values[i, , ] <- .etr_on_grid(z$matrix[i, ], nt, nd)
  original <- etr_trajectory_set(x$time, values, z$participant_ids,
                                 x$dimension_names, coordinate_system = x$coordinate_system,
                                 time_unit = x$time_unit)
  model <- etr_fit_fpca(original, as.integer(n_components))
  lambda <- matrix(NA_real_, nrow = B, ncol = n_components)
  failures <- rep("", B)
  .etr_seed_scope(seed, function() {
    for (b in seq_len(B)) {
      ix <- sample.int(ns, ns, replace = TRUE)
      replicate <- etr_trajectory_set(x$time, values[ix, , , drop = FALSE],
                        paste0("resample_",seq_len(ns)), x$dimension_names,
                        coordinate_system = x$coordinate_system,
                        time_unit = x$time_unit)
      trial <- tryCatch(etr_fit_fpca(replicate, as.integer(n_components)),
                        error = function(e) e)
      if (inherits(trial, "error")) {
        failures[b] <<- conditionMessage(trial)
      } else {
        lambda[b, ] <<- trial$explained_variance
      }
    }
    invisible(NULL)
  })
  success <- apply(lambda, 1L, function(q) all(is.finite(q)))
  table <- data.frame(replicate = seq_len(B), ok = success,
                      message = failures, lambda, check.names = FALSE)
  names(table)[seq.int(4L,ncol(table))] <- paste0("lambda", seq_len(n_components))
  lower <- upper <- rep(NA_real_, n_components)
  if (sum(success) >= 39L) for (j in seq_len(n_components)) {
    lower[j] <- unname(stats::quantile(lambda[success,j], alpha/2))
    upper[j] <- unname(stats::quantile(lambda[success,j], 1-alpha/2))
  }
  list(eigenvalues = model$explained_variance,
       lower = lower, upper = upper, alpha = alpha,
       failures = sum(!success), successes = sum(success),
       replicates = table, n_subjects = ns, seed = seed,
       inference_scope = "exploratory_cluster_bootstrap_spectrum_no_calibration")
}

#' Analytic integrated between-participant variance under known-truth generator
#'
#' For independent subject and trial Gaussian coefficients on sin(pi*t)
#' and cos(pi*t), plus independent sample noise, this yields the exact
#' integrated trace of the participant-mean covariance on the given grid.
#' @param time Common strictly increasing grid.
#' @param trials_per_subject Independent trials per subject.
#' @param subject_sd Subject random-effect standard deviation.
#' @param trial_sd Trial random-effect standard deviation.
#' @param noise_sd Sample-level random measurement error standard deviation.
#' @export
etr_analytic_between_variance <- function(time, trials_per_subject,
                                           subject_sd = .35, trial_sd = .15,
                                           noise_sd = .05) {
  w <- etr_trapezoid_weights(time)
  .etr_assert(is.numeric(trials_per_subject) && length(trials_per_subject) == 1L &&
    is.finite(trials_per_subject) && trials_per_subject >= 2 &&
    trials_per_subject == as.integer(trials_per_subject),
    "trials_per_subject must be integer >= 2")
  sd <- c(subject_sd,trial_sd,noise_sd)
  .etr_assert(length(sd)==3L && all(is.finite(sd)) && all(sd>=0),
              "variance components must be non-negative finite scalars")
  v <- subject_sd^2 + trial_sd^2 / trials_per_subject
  sum(w * (v * (sin(pi*time)^2 + cos(pi*time)^2) +
             2 * noise_sd^2 / trials_per_subject))
}

#' Monte Carlo audit of multilevel between-subject integrated variance
#'
#' Generates independent datasets using the hierarchical known-truth
#' simulator; compares the between-subject sample covariance trace with
#' an analytic theoretical trace. Monte Carlo variability is retained.
#' @param simulations Independent generating datasets (>= 5).
#' @param n_subjects Independent participants.
#' @param trials_per_subject Repeated trajectories per participant.
#' @param n_time Common-grid points.
#' @param subject_sd Subject-level standard deviation.
#' @param trial_sd Trial-level standard deviation.
#' @param noise_sd Measurement standard deviation.
#' @param seed Initial seed.
#' @export
etr_evaluate_between_variance <- function(simulations = 20L,
                                           n_subjects = 24L,
                                           trials_per_subject = 3L,
                                           n_time = 41L, subject_sd = .35,
                                           trial_sd = .15, noise_sd = .05,
                                           seed = 123L) {
  .etr_assert(is.numeric(simulations) && length(simulations) == 1L &&
    is.finite(simulations) && simulations == as.integer(simulations) &&
    simulations >= 5L && simulations <= 1000L,
    "simulations must be integer 5 to 1000")
  result <- numeric(simulations); target <- NULL
  for (i in seq_len(simulations)) {
    sim <- etr_simulate_hierarchical(n_subjects = n_subjects,
                   trials_per_subject = trials_per_subject, n_time = n_time,
                   subject_sd = subject_sd, trial_sd = trial_sd,
                   noise_sd = noise_sd, seed = seed + i)
    fit <- etr_fit_multilevel_fpca(sim$trajectories, sim$participant, 2L, 2L)
    result[i] <- fit$between$total_variance
    if (is.null(target)) target <- etr_analytic_between_variance(
      sim$trajectories$time, trials_per_subject,
      subject_sd, trial_sd, noise_sd)
  }
  d <- result - target
  list(observed = result, analytic_truth = target,
       mean_estimate = mean(result), mean_bias = mean(d),
       mc_se_of_mean = stats::sd(result)/sqrt(simulations),
       rmse = sqrt(mean(d^2)), simulations = simulations,
       qualification = "independent_analytic_trace_audit_not_inferential_calibration")
}
