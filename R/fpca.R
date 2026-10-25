#' Fit quadrature-weighted functional PCA
#' @param trajectories A Python TrajectorySet from et_from_long() or et_simulate_planar().
#' @param n_components Integer component count or variance fraction.
#' @param scaling "none" or "dimension_sd".
#' @export
et_fit_fpca <- function(trajectories, n_components = 0.95,
                        scaling = c("none", "dimension_sd")) {
  et_call("fit_fpca", trajectories, n_components = n_components,
          scaling = match.arg(scaling))
}

#' Fit multivariate functional PCA
#'
#' This requires at least two functional channels and delegates directly to
#' eyetrajectoriespy.fit_mfpca().
#' @inheritParams et_fit_fpca
#' @export
et_fit_mfpca <- function(trajectories, n_components = 0.95,
                         scaling = c("none", "dimension_sd")) {
  et_call("fit_mfpca", trajectories, n_components = n_components,
          scaling = match.arg(scaling))
}

#' Tidy functional principal component scores
#' @param fit A Python FPCAResult.
#' @param prefix Prefix for score column names.
#' @export
et_scores <- function(fit, prefix = "FPC") {
  reticulate::py_to_r(et_call("fpca_score_frame", fit, prefix = prefix))
}

#' Extract explained variance from an FPCA result
#' @param fit A Python FPCAResult.
#' @param cumulative Return cumulative proportions instead of per-component proportions.
#' @export
et_explained_variance <- function(fit, cumulative = FALSE) {
  if (!is.logical(cumulative) || length(cumulative) != 1L || is.na(cumulative)) {
    stop("cumulative must be TRUE or FALSE", call. = FALSE)
  }
  if (cumulative) {
    reticulate::py_to_r(fit$cumulative_explained_variance())
  } else {
    reticulate::py_to_r(fit$explained_variance_ratio)
  }
}
