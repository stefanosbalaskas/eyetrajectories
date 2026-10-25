# Independent known-truth simulation harness, generated in R without Python.
#' Simulate sparsely observed univariate functional data with known curves
#'
#' Covariance is rank-one; observations have independent Gaussian noise. This
#' generator is separate from fdapace, with true curves defined on a dense grid.
#' @param n_subjects Independent curves, >= 20.
#' @param min_observations Minimum observations per curve, >= 3.
#' @param max_observations Maximum observations per curve, >= minimum.
#' @param noise_sd Observation noise standard deviation.
#' @param score_sd Score standard deviation.
#' @param seed Reproducible seed, global RNG restored.
#' @export
etr_simulate_sparse_known_truth <- function(n_subjects = 45L, min_observations = 5L,
                                            max_observations = 10L, noise_sd = 0.10,
                                            score_sd = 0.60, seed = 22L) {
  p <- c(n_subjects, min_observations, max_observations)
  .etr_assert(all(is.finite(p)) && all(p == as.integer(p)) &&
                n_subjects >= 20L && min_observations >= 3L &&
                max_observations >= min_observations && max_observations <= 101L,
              "require >= 20 curves and observation counts from 3 to 101")
  .etr_assert(all(is.finite(c(noise_sd, score_sd))) && noise_sd >= 0 && score_sd > 0,
              "noise_sd must be nonnegative and score_sd positive")
  .etr_seed_scope(seed, function() {
    grid <- seq(0, 1, length.out = 101L)
    true_mean <- sin(2*pi*grid)
    basis <- cos(pi*grid)
    scores <- stats::rnorm(as.integer(n_subjects), sd = score_sd)
    truth <- outer(scores, basis) +
      matrix(true_mean, nrow = as.integer(n_subjects),
             ncol = length(grid), byrow = TRUE)
    times <- vector("list", n_subjects)
    observed <- vector("list", n_subjects)
    for (i in seq_len(n_subjects)) {
      ni <- min_observations + sample.int(max_observations - min_observations + 1L, 1L) - 1L
      at <- sort(sample.int(length(grid), ni, replace = FALSE))
      times[[i]] <- grid[at]
      observed[[i]] <- truth[i, at] + stats::rnorm(ni, sd = noise_sd)
    }
    list(curves = etr_sparse_curves(times, observed,
                                  paste0("sim", seq_len(n_subjects)), "s"),
         grid = grid, true_mean = true_mean, true_curves = truth,
         true_scores = scores, score_sd = score_sd, noise_sd = noise_sd,
         seed = seed, source = "independent_rank_one_generator")
  })
}

#' Evaluate sparse PACE reconstruction against independently generated truth
#'
#' This diagnostic uses interpolation of known mathematical truth to the
#' fdapace work grid. Results are empirical errors, not confidence coverage.
#' @param simulations Number of independent generating datasets.
#' @param n_subjects Curves per dataset.
#' @param seed Initial seed.
#' @param max_components Requested maximum PACE components.
#' @export
etr_evaluate_sparse_pace_recovery <- function(simulations = 5L, n_subjects = 45L,
                                               seed = 100L, max_components = 2L) {
  .etr_assert(is.numeric(simulations) && length(simulations) == 1L &&
                is.finite(simulations) && simulations == as.integer(simulations) &&
                simulations >= 2L && simulations <= 50L,
              "simulations must be an integer in [2,50]")
  errors <- rep(NA_real_, simulations)
  mean_errors <- rep(NA_real_, simulations)
  failures <- character(simulations)
  for (i in seq_len(simulations)) {
    sample <- etr_simulate_sparse_known_truth(n_subjects, seed = seed + i)
    result <- tryCatch({
      fit <- etr_fit_sparse_pace(sample$curves, max_components = max_components)
      pred <- etr_sparse_pace_fitted(fit)
      ref <- t(vapply(seq_len(nrow(sample$true_curves)), function(j) {
        stats::approx(sample$grid, sample$true_curves[j, ],
                      xout = pred$time, rule = 1)$y
      }, numeric(length(pred$time))))
      mean_ref <- stats::approx(sample$grid, sample$true_mean,
                                xout = pred$time, rule = 1)$y
      c(sqrt(mean((pred$fitted - ref)^2)), sqrt(mean((fit$model$mu - mean_ref)^2)))
    }, error = function(e) {
      failures[i] <<- conditionMessage(e)
      c(NA_real_, NA_real_)
    })
    errors[i] <- result[1L]
    mean_errors[i] <- result[2L]
  }
  data.frame(simulation = seq_len(simulations), curve_rmse = errors,
             mean_rmse = mean_errors, failed = nzchar(failures),
             message = failures, stringsAsFactors = FALSE)
}

#' Evaluate multilevel FPCA mean recovery against independent known truth
#' @param simulations Number of repeated generated datasets.
#' @param n_subjects Number of independent participants.
#' @param seed Initial random seed.
#' @export
etr_evaluate_multilevel_recovery <- function(simulations = 10L,
                                              n_subjects = 20L, seed = 200L) {
  .etr_assert(is.numeric(simulations) && length(simulations) == 1L &&
                is.finite(simulations) && simulations == as.integer(simulations) &&
                simulations >= 3L && simulations <= 100L,
              "simulations must be integer in [3,100]")
  records <- lapply(seq_len(simulations), function(i) {
    z <- etr_simulate_hierarchical(n_subjects = n_subjects, seed = seed + i)
    fit <- etr_fit_multilevel_fpca(z$trajectories, z$participant, 2L, 2L)
    data.frame(simulation = i,
               population_mean_rmse = sqrt(mean((fit$between$mean - z$truth_mean)^2)),
               between_integrated_variance = fit$between$total_variance,
               within_integrated_variance = fit$within$total_variance)
  })
  do.call(rbind, records)
}
