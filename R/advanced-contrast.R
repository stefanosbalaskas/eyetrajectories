#' Between-group cluster bootstrap functional mean contrast
#'
#' Computes group difference of participant-mean functions and resamples
#' independent participants separately within groups. Assumes every participant
#' belongs to precisely one of two groups. This is a descriptive independent-
#' clusters estimator, not a causal effect or calibrated simultaneous test.
#' @param x Complete common-grid trajectories.
#' @param participant Participant identifier per curve or metadata column.
#' @param group Two-group identifier per curve or metadata column.
#' @param B Bootstrap repetitions, integer >= 39.
#' @param alpha Nominal error probability (0,1); coverage unqualified.
#' @param seed Seed; global R RNG state restored.
#' @export
etr_bootstrap_group_contrast <- function(x, participant, group, B = 399L,
                                         alpha = 0.05, seed = 3L) {
  z <- .etr_participant_matrix(x, participant)
  n <- dim(x$values)[1L]
  if (length(group) == 1L && is.character(group) &&
      group %in% names(x$metadata)) group <- x$metadata[[group]]
  .etr_assert(length(group) == n && !anyNA(group), "group must identify each curve")
  if (length(participant) == 1L && is.character(participant) &&
      participant %in% names(x$metadata)) participant <- x$metadata[[participant]]
  keys <- unique(as.character(participant))
  .etr_assert(identical(keys, z$participant_ids), "participant order mismatch")
  grp <- vapply(keys, function(key) {
    g <- unique(as.character(group[as.character(participant) == key]))
    .etr_assert(length(g) == 1L, "participant must belong to exactly one group")
    g
  }, character(1))
  levels <- unique(grp)
  .etr_assert(length(levels) == 2L, "group must have exactly two levels")
  idx <- lapply(levels, function(k) which(grp == k))
  .etr_assert(all(lengths(idx) >= 3L), "at least 3 independent participants per group required")
  .etr_assert(is.numeric(B) && length(B) == 1L && is.finite(B) &&
                B == as.integer(B) && B >= 39L && B <= 20000L,
              "B must be integer 39 to 20000")
  .etr_assert(is.numeric(alpha) && length(alpha) == 1L && is.finite(alpha) &&
                alpha > 0 && alpha < 1, "alpha must lie in (0,1)")
  group_a <- z$matrix[idx[[1L]], , drop = FALSE]
  group_b <- z$matrix[idx[[2L]], , drop = FALSE]
  mean_a <- colMeans(group_a); mean_b <- colMeans(group_b)
  delta <- mean_b - mean_a
  se <- sqrt(apply(group_a, 2L, stats::var) / nrow(group_a) +
             apply(group_b, 2L, stats::var) / nrow(group_b))
  boots <- .etr_seed_scope(seed, function() {
    replicate(as.integer(B), {
      a <- colMeans(group_a[sample.int(nrow(group_a), nrow(group_a), TRUE), , drop = FALSE])
      b <- colMeans(group_b[sample.int(nrow(group_b), nrow(group_b), TRUE), , drop = FALSE])
      b - a
    })
  })
  boots <- matrix(boots, nrow = length(delta), ncol = as.integer(B))
  point_lo <- apply(boots, 1L, stats::quantile, probs = alpha/2, names = FALSE)
  point_hi <- apply(boots, 1L, stats::quantile, probs = 1-alpha/2, names = FALSE)
  nonzero <- which(is.finite(se) & se > .Machine$double.eps)
  stats <- if (length(nonzero)) {
    apply(abs(sweep(sweep(boots[nonzero, , drop = FALSE], 1L,
                 delta[nonzero], "-"), 1L, se[nonzero], "/")), 2L, max)
  } else rep(0, B)
  critical <- unname(stats::quantile(stats, 1-alpha, names = FALSE, type = 1))
  .etr_assert(is.finite(critical), "non-finite bootstrap critical value")
  to_grid <- function(q) .etr_on_grid(q, z$n_time, z$n_dim)
  structure(list(contrast = paste0(levels[2L], " minus ", levels[1L]),
                 difference = to_grid(delta), se = to_grid(se),
                 pointwise_lower = to_grid(point_lo),
                 pointwise_upper = to_grid(point_hi),
                 simultaneous_lower = to_grid(delta - critical*se),
                 simultaneous_upper = to_grid(delta + critical*se),
                 critical = critical,
                 group_levels = levels, participants_per_group = lengths(idx),
                 resampling_unit = "participant", B = as.integer(B), alpha = alpha,
                 time = x$time, dimensions = x$dimension_names,
                 scientific_status = "exploratory_no_coverage_guarantee"),
            class = "etr_group_contrast")
}

#' Reconstruct individual curves from descriptive multilevel FPCA
#' @param fit etr_multilevel_fpca fit.
#' @param n_between Retained between-participant components.
#' @param n_within Retained within-participant components.
#' @export
etr_multilevel_reconstruct <- function(fit, n_between = NULL, n_within = NULL) {
  .etr_assert(inherits(fit, "etr_multilevel_fpca"), "fit must be etr_multilevel_fpca")
  if (is.null(n_between)) n_between <- fit$between$n_components
  if (is.null(n_within)) n_within <- fit$within$n_components
  a <- etr_reconstruct_fpca(fit$between, n_between)
  b <- etr_reconstruct_fpca(fit$within, n_within)
  n <- length(fit$curve_ids)
  v <- b$values
  for (i in seq_len(n)) {
    v[i, , ] <- v[i, , ] + a$values[fit$group_index[i], , ]
  }
  etr_trajectory_set(b$time, v, fit$curve_ids, b$dimension_names,
                     coordinate_system = b$coordinate_system, time_unit = b$time_unit)
}

#' Multilevel fit diagnostics, including unbalanced cluster sizes
#' @param fit etr_multilevel_fpca fit.
#' @export
etr_multilevel_diagnostics <- function(fit) {
  .etr_assert(inherits(fit, "etr_multilevel_fpca"), "fit must be etr_multilevel_fpca")
  counts <- tabulate(fit$group_index, nbins = length(fit$participants))
  rec <- etr_multilevel_reconstruct(fit)
  original <- array(0, dim(rec$values))
  for (i in seq_len(length(fit$curve_ids))) {
    original[i, , ] <- fit$residuals[i, , ] +
      fit$participant_means[fit$group_index[i], , ]
  }
  list(n_participants = length(fit$participants), n_curves = length(fit$curve_ids),
       minimum_trials = min(counts), maximum_trials = max(counts),
       mean_trials = mean(counts),
       fitted_reconstruction_rmse = sqrt(mean((rec$values - original)^2)),
       between_components = fit$between$n_components,
       within_components = fit$within$n_components,
       variance = etr_multilevel_variance(fit),
       interpretation = "descriptive_two_level_not_REML")
}
