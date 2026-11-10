# Frozen Python 1.2 recovery.py::evaluate_sparse_fpca_recovery.

.etr_sparse_recovery_diagnostics <- function(result, value) {
  diagnostics <- result[["score_diagnostics", exact = TRUE]]
  covariance <- result[["covariance_diagnostics", exact = TRUE]]
  .etr_assert(is.null(diagnostics) || is.data.frame(diagnostics),
    "sparse score_diagnostics must be a source-shaped data frame")
  .etr_assert(is.null(covariance) || is.list(covariance),
    "covariance_diagnostics must be a named source record")
  values <- list()
  if (is.null(diagnostics) || nrow(diagnostics) == 0L) {
    values[[1L]] <- value("score_failure_rate", mean(rowSums(!is.finite(result$scores)) > 0L))
  } else {
    if ("status_code" %in% names(diagnostics)) {
      status <- as.character(diagnostics$status_code)
      values[[length(values) + 1L]] <- value("score_failure_rate",
        mean(is.na(status) | status != "ok"))
    }
    if ("condition_number" %in% names(diagnostics)) {
      condition <- suppressWarnings(as.numeric(as.character(diagnostics$condition_number)))
      condition <- condition[is.finite(condition)]
      if (length(condition)) values <- c(values, list(
        value("score_condition_number_median", stats::median(condition)),
        value("score_condition_number_q95", stats::quantile(condition, .95, names = FALSE)),
        value("score_condition_number_max", max(condition))))
    }
  }
  correction <- covariance[["relative_operator_correction_frobenius_norm", exact = TRUE]]
  if (!is.null(correction) && is.numeric(correction) &&
    length(correction) == 1L && is.finite(correction)) {
    values <- c(values, list(
      value("psd_repair_applied", as.numeric(identical(covariance$applied_action, "project"))),
      value("psd_relative_operator_correction", correction)))
  }
  values
}

#' Evaluate known-truth univariate sparse PACE
#'
#' Matches fitted modes to the generating components on the exact grid.
#' Uses the directly estimated covariance, retains score diagnostics, and
#' compares measurement noise when a fitted variance is supplied.
#' @param result Native source-shaped sparse FPCA result.
#' @param truth Source-shaped functional simulator truth.
#' @return Native recovery assessment with matched component indices.
#' @export
etr_evaluate_sparse_fpca_recovery <- function(result, truth) {
  .etr_recovery_source_fields(result, c("evaluation_grid", "dimension",
    "mean", "covariance", "eigenfunctions", "eigenvalues", "scores"), "sparse FPCA fit")
  .etr_recovery_source_fields(truth, c("truth_grid", "dimension_names", "mean",
    "eigenfunctions", "eigenvalues", "scores", "latent_on_truth_grid",
    "measurement_noise_covariance"), "generating sparse FPCA truth")
  grid <- truth$truth_grid
  .etr_recovery_require_grid(result$evaluation_grid, grid,
    "sparse recovery requires an exact truth evaluation grid")
  .etr_assert(is.character(result$dimension) && length(result$dimension) == 1L &&
    !is.na(result$dimension), "sparse recovery dimension must be named")
  dimension <- match(result$dimension, truth$dimension_names)
  .etr_assert(!is.na(dimension), "sparse result dimension is absent from generating truth")
  nt <- length(grid)
  nd <- length(truth$dimension_names)
  .etr_assert(is.matrix(truth$mean) && is.numeric(truth$mean) &&
    identical(dim(truth$mean), c(nt, nd)), "truth mean must be time by dimension")
  .etr_assert(is.array(truth$eigenfunctions) && length(dim(truth$eigenfunctions)) == 3L &&
    identical(dim(truth$eigenfunctions)[2:3], c(nt, nd)),
    "truth functional eigenfunctions must have time/dimension geometry")
  .etr_assert(is.array(truth$latent_on_truth_grid) &&
    length(dim(truth$latent_on_truth_grid)) == 3L &&
    identical(dim(truth$latent_on_truth_grid)[2:3], c(nt, nd)),
    "truth latent curves must align with simulator scores")
  modes <- result$eigenfunctions
  .etr_assert(is.matrix(modes) && is.numeric(modes) && nrow(modes) >= 1L &&
    ncol(modes) == nt, "sparse eigenfunctions must have mode by time geometry")
  .etr_assert(is.numeric(result$mean) && is.null(dim(result$mean)) &&
    length(result$mean) == nt, "sparse mean must be a finite time vector")
  .etr_assert(is.matrix(result$covariance), "sparse covariance must match the observed source grid")
  weights <- result[["quadrature_weights", exact = TRUE]]
  if (is.null(weights)) weights <- etr_trapezoid_weights(grid)

  one_truth <- truth
  one_truth$dimension_names <- result$dimension
  one_truth$mean <- truth$mean[, dimension, drop = FALSE]
  one_truth$eigenfunctions <- truth$eigenfunctions[, , dimension, drop = FALSE]
  one_truth$latent_on_truth_grid <- truth$latent_on_truth_grid[, , dimension, drop = FALSE]
  fit <- list(mean = matrix(result$mean, ncol = 1L),
    components = array(modes, c(nrow(modes), nt, 1L)),
    explained_variance = result$eigenvalues, scores = result$scores, weights = weights)
  value <- .etr_recovery_value_factory()
  recovery <- .etr_fpca_recovery_population(fit, one_truth, value, result$covariance)
  values <- c(recovery$values, .etr_sparse_recovery_diagnostics(result, value))

  noise_covariance <- truth$measurement_noise_covariance
  .etr_assert(is.matrix(noise_covariance) && is.numeric(noise_covariance) &&
    identical(dim(noise_covariance), c(nd, nd)) && all(is.finite(noise_covariance)),
    "truth measurement_noise_covariance must match dimension order")
  true_noise <- noise_covariance[dimension, dimension]
  noise <- result[["noise_variance", exact = TRUE]]
  if (!is.null(noise)) {
    .etr_assert(is.numeric(noise) && length(noise) == 1L && is.finite(noise),
      "noise_variance must be finite scalar")
    absolute_error <- abs(noise - true_noise)
    values[[length(values) + 1L]] <- value("noise_variance_absolute_error", absolute_error)
    if (true_noise > 0) values[[length(values) + 1L]] <-
      value("noise_variance_relative_error", absolute_error / true_noise)
  }

  provenance <- result[["provenance", exact = TRUE]]
  .etr_assert(is.null(provenance) || is.list(provenance),
    "sparse provenance must be a source-shaped record")
  sparse <- provenance[["sparse_fpca", exact = TRUE]]
  .etr_assert(is.null(sparse) || is.list(sparse), "sparse_fpca provenance must be a named record")
  structure(list(values = values, provenance = list(
    estimator = "native_sparse_fpca_pace", truth_grid_match = "exact",
    dimension = result$dimension, noise_variance_method = sparse$noise_variance_method,
    measurement_error_variance_supplied = sparse$measurement_error_variance_supplied,
    matched_truth_components = recovery$matched_truth_components,
    alignment_signs = recovery$alignment_signs)),
    class = "etr_functional_recovery_assessment")
}
