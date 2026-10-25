# Two-level descriptive functional decomposition. No covariance-based mixed
# model inference or independently calibrated prediction bands are implied.
#' Fit a nested participant/trial functional decomposition
#'
#' Uses equally weighted participant mean curves for between-participant FPCA
#' and trial deviations from the participant mean for within-participant FPCA.
#' This is a descriptive two-level FPCA, not a REML functional mixed model.
#' @param x A complete native trajectory collection.
#' @param participant Participant label per curve, or a metadata column name.
#' @param n_between Number of between-participant components.
#' @param n_within Number of within-participant components.
#' @export
etr_fit_multilevel_fpca <- function(x, participant, n_between = 2L, n_within = 2L) {
  etr_validate(x, require_complete = TRUE)
  if (length(participant) == 1L && is.character(participant) &&
      participant %in% names(x$metadata)) participant <- x$metadata[[participant]]
  n <- dim(x$values)[1L]
  .etr_assert(length(participant) == n && !anyNA(participant),
              "participant must identify every curve")
  participants <- unique(as.character(participant))
  group <- match(as.character(participant), participants)
  .etr_assert(length(participants) >= 3L && all(tabulate(group) >= 2L),
              "requires >= 3 participants, each with >= 2 trials")
  .etr_assert(is.numeric(n_between) && length(n_between) == 1L &&
                is.finite(n_between) && n_between == as.integer(n_between) &&
                n_between >= 1L && n_between <= length(participants) - 1L,
              "n_between must be an integer from 1 to n_participants - 1")
  .etr_assert(is.numeric(n_within) && length(n_within) == 1L &&
                is.finite(n_within) && n_within == as.integer(n_within) &&
                n_within >= 1L && n_within <= n - length(participants),
              "n_within must be an integer from 1 to residual degrees of freedom")
  ng <- length(participants); nt <- length(x$time); nd <- dim(x$values)[3]
  means <- array(0, c(ng, nt, nd))
  for (g in seq_len(ng)) for (j in seq_len(nd)) {
    z <- matrix(x$values[group == g, , j, drop = FALSE],
                nrow = sum(group == g), ncol = nt)
    means[g, , j] <- colMeans(z)
  }
  residual <- x$values
  for (i in seq_len(n)) for (j in seq_len(nd))
    residual[i, , j] <- x$values[i, , j] - means[group[i], , j]
  between_x <- etr_trajectory_set(x$time, means, participants, x$dimension_names,
                                   coordinate_system = x$coordinate_system,
                                   time_unit = x$time_unit)
  within_x <- etr_trajectory_set(x$time, residual, x$curve_ids, x$dimension_names,
                                  coordinate_system = x$coordinate_system,
                                  time_unit = x$time_unit)
  between <- etr_fit_fpca(between_x, n_components = as.integer(n_between))
  within <- etr_fit_fpca(within_x, n_components = as.integer(n_within))
  structure(list(between = between, within = within,
                 participants = participants, group_index = group,
                 participant_means = means, residuals = residual,
                 curve_ids = x$curve_ids,
                 allocation = "equal_participant_weights",
                 estimator = "two_level_descriptive_fpca"),
            class = "etr_multilevel_fpca")
}

#' Tidy between- and within-participant FPCA score frames
#' @param fit A two-level etr_multilevel_fpca fit.
#' @export
etr_multilevel_scores <- function(fit) {
  .etr_assert(inherits(fit, "etr_multilevel_fpca"), "fit must be etr_multilevel_fpca")
  b <- etr_fpca_scores(fit$between)
  w <- etr_fpca_scores(fit$within)
  w$participant <- fit$participants[fit$group_index]
  list(between = b, within = w)
}

#' Descriptive integrated between/within variance decomposition
#' @param fit A two-level etr_multilevel_fpca fit.
#' @export
etr_multilevel_variance <- function(fit) {
  .etr_assert(inherits(fit, "etr_multilevel_fpca"), "fit must be etr_multilevel_fpca")
  # Sample-covariance trace of subject means and participant-centred trials.
  # These are different design strata; not an additive marginal covariance
  # estimator unless appropriate weighting/variance assumptions hold.
  b <- fit$between$total_variance
  r <- fit$within$total_variance
  data.frame(stratum = c("between_participants", "within_participants"),
             integrated_variance = c(b, r),
             normalization = c("sample_subject_mean", "sample_trial_residual"),
             row.names = NULL)
}
