# Native frozen-FPCA split-conformal anomaly screening; no Python needed.
#' Compute the rank-based split conformal nonconformity threshold
#' @param calibration_scores Finite nonnegative scores from held-out units.
#' @param alpha Desired miscoverage in (0,1).
#' @return Threshold and quantile-rank metadata.
#' @export
etr_split_conformal_threshold <- function(calibration_scores, alpha = .10) {
  .etr_assert(is.numeric(calibration_scores) &&
                length(calibration_scores) >= 1L &&
                all(is.finite(calibration_scores)) &&
                all(calibration_scores >= 0),
              "calibration scores must be finite and nonnegative")
  .etr_assert(is.numeric(alpha) && length(alpha) == 1L &&
                is.finite(alpha) && alpha > 0 && alpha < 1,
              "alpha must be strictly between 0 and 1")
  n <- length(calibration_scores)
  rank <- ceiling((n + 1) * (1 - alpha))
  threshold <- if (rank > n) Inf else sort(calibration_scores)[rank]
  list(threshold = threshold, rank = rank, n_calibration = n,
       alpha = alpha,
       scope = "marginal_one_exchangeable_future_unit",
       method = "split_conformal_rank_nonconformity")
}

#' Integrated held-out reconstruction residuals for a frozen FPCA fit
#' @param fit Frozen native etr_fpca fitted on training curves.
#' @param x Independent complete curves on identical grid/channels.
#' @return Data frame with curve_id and root integrated residual score.
#' @export
etr_fpca_reconstruction_scores <- function(fit, x) {
  .etr_assert(inherits(fit, "etr_fpca"), "fit must be native etr_fpca")
  etr_validate(x, require_complete = TRUE)
  scores <- etr_transform_fpca(fit, x)
  n <- dim(x$values)[1L]
  nt <- length(x$time); nd <- dim(x$values)[3L]
  .etr_assert(ncol(scores) == fit$n_components,
              "component count does not match fitted FPCA")
  square <- numeric(n)
  for (j in seq_len(nd)) for (tt in seq_len(nt)) {
    reconstructed <- fit$mean[tt, j] +
      as.vector(scores %*% as.vector(fit$components[, tt, j]))
    square <- square + (x$values[, tt, j] - reconstructed)^2 *
      fit$weights[tt]
  }
  data.frame(curve_id = x$curve_ids, score = sqrt(pmax(0, square)),
             row.names = NULL)
}

#' Split-conformal held-out FPCA anomaly screen
#' @param fit Frozen FPCA fitted only on independent training curves.
#' @param calibration Independent held-out calibration trajectory set.
#' @param test Independent held-out trajectories to screen.
#' @param alpha Miscoverage in (0,1).
#' @return List of per-curve anomaly flags and calibration evidence.
#' @export
etr_split_conformal_fpca_anomalies <- function(fit, calibration,
                                               test, alpha = .10) {
  .etr_assert(inherits(fit, "etr_fpca"), "fit must be native etr_fpca")
  etr_validate(calibration, require_complete = TRUE)
  etr_validate(test, require_complete = TRUE)
  .etr_assert(!anyDuplicated(c(fit$curve_ids, calibration$curve_ids,
                                test$curve_ids)),
              "train, calibration, and test IDs must be mutually disjoint")
  cal <- etr_fpca_reconstruction_scores(fit, calibration)
  scored <- etr_fpca_reconstruction_scores(fit, test)
  cutoff <- etr_split_conformal_threshold(cal$score, alpha)
  scored$threshold <- cutoff$threshold
  scored$is_anomaly <- scored$score > cutoff$threshold
  list(test = scored, calibration = cal, cutoff = cutoff,
       training_ids = fit$curve_ids,
       assumptions = paste(
         "Per-curve marginal guarantee requires exchangeable independent",
         "calibration/test curves and a frozen training model.",
         "Not valid as a simultaneous band or batch-wise guarantee;",
         "within-participant dependent trials may violate exchangeability."))
}
