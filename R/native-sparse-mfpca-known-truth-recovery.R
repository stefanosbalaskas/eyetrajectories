# Frozen Python 1.2 recovery.py::evaluate_sparse_mfpca_recovery.

#' Evaluate known-truth sparse bivariate MFPCA
#'
#' Compares named planar covariance blocks and matched components on the
#' generating grid. Complete tied eigenspaces use principal angles and
#' orthogonal Procrustes score error. Fits that split a tied truth group
#' are rejected.
#' @param result Native source-shaped bivariate sparse joint-PACE result.
#' @param truth Source-shaped generating truth with two ordered channels.
#' @return Native recovery assessment with explicit alignment provenance.
#' @export
etr_evaluate_sparse_mfpca_recovery <- function(result, truth) {
  .etr_recovery_source_fields(result, c("evaluation_grid", "dimensions", "mean",
    "eigenfunctions", "eigenvalues", "scores", "quadrature_weights",
    "covariance_cxx", "covariance_cxy", "covariance_cyx", "covariance_cyy",
    "measurement_error_covariance"), "sparse MFPCA fit")
  .etr_recovery_source_fields(truth, c("truth_grid", "dimension_names", "mean",
    "eigenfunctions", "eigenvalues", "scores", "latent_on_truth_grid",
    "measurement_noise_covariance"), "sparse MFPCA generating truth")
  grid <- truth$truth_grid
  .etr_recovery_require_grid(result$evaluation_grid, grid,
    "sparse MFPCA recovery requires exact truth evaluation grid")
  dimensions <- truth$dimension_names
  .etr_assert(is.character(dimensions) && length(dimensions) == 2L &&
    identical(result$dimensions, dimensions),
    "sparse MFPCA recovery requires exactly two dimensions in source order")
  weights <- result$quadrature_weights
  target_weights <- etr_trapezoid_weights(grid)
  .etr_assert(is.numeric(weights) && is.null(dim(weights)) &&
    length(weights) == length(grid) && all(is.finite(weights)) &&
    all(abs(weights - target_weights) <= 1e-14),
    "sparse MFPCA recovery requires declared functional quadrature weights")
  fit <- list(mean = result$mean, components = result$eigenfunctions,
    explained_variance = result$eigenvalues, scores = result$scores, weights = weights)
  covariance <- list(cxx = result$covariance_cxx, cxy = result$covariance_cxy,
    cyx = result$covariance_cyx, cyy = result$covariance_cyy)
  value <- .etr_recovery_value_factory()
  recovery <- .etr_fpca_recovery_population(fit, truth, value, covariance)
  values <- c(recovery$values, .etr_sparse_recovery_diagnostics(result, value))

  supplied <- result$measurement_error_covariance
  actual <- truth$measurement_noise_covariance
  .etr_assert(is.matrix(supplied) && is.numeric(supplied) &&
    is.matrix(actual) && is.numeric(actual),
    "source measurement error covariance must be a numeric matrix")
  agreement <- identical(dim(supplied), dim(actual)) &&
    all(is.finite(supplied) & is.finite(actual) & abs(supplied - actual) <= 1e-12)
  provenance <- result[["provenance", exact = TRUE]]
  .etr_assert(is.null(provenance) || is.list(provenance), "sparse MFPCA provenance must be a record")
  sparse <- provenance[["sparse_mfpca", exact = TRUE]]
  .etr_assert(is.null(sparse) || is.list(sparse), "sparse_mfpca provenance must be a record")
  structure(list(values = values, provenance = list(
    estimator = "native_sparse_mfpca_joint_pace", truth_grid_match = "exact",
    dimensions = as.list(dimensions), covariance_recovery = "named_block_quadrature_ise",
    joint_covariance_ise_definition = "cxx + cxy + cyx + cyy",
    matched_truth_components = recovery$matched_truth_components,
    alignment_signs = recovery$alignment_signs,
    truth_eigenvalue_tie_relative_tolerance = recovery$tie_tolerance,
    tied_truth_component_groups = recovery$ties,
    tied_score_subspace_sources = recovery$tied_sources,
    component_metrics_omitted_for_tied_eigenspaces = length(recovery$ties) > 0L,
    measurement_error_mode = sparse$measurement_error_mode,
    measurement_error_truth_supplied = agreement,
    measurement_error_recovery_metric_reported = FALSE)),
    class = "etr_functional_recovery_assessment")
}
