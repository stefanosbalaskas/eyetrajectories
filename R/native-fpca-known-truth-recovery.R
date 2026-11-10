# Frozen Python 1.2 recovery.py::evaluate_fpca_recovery.

#' Known-truth FPCA recovery for one or multiple retained components
#'
#' Uses the exact generating grid and unit dimension scales. Reports
#' weighted covariance error, signed component matching, principal angles,
#' score agreement on finite pairs and latent reconstruction error.
#' @param result Native source-shaped unscaled FPCA fit.
#' @param truth Functional simulation truth with at least as many
#'   positive generating modes as fitted retained components.
#' @return Native recovery assessment with zero-based matched truth indices.
#' @export
etr_evaluate_fpca_recovery <- function(result, truth) {
  .etr_recovery_source_fields(result, c("time", "provenance", "dimension_names",
    "scale", "mean", "components", "explained_variance", "scores", "weights"),
    "FPCA fit")
  .etr_recovery_source_fields(truth, c("truth_grid", "dimension_names",
    "mean", "eigenfunctions", "eigenvalues", "scores", "latent_on_truth_grid"),
    "FPCA generating truth")
  .etr_recovery_require_grid(result$time, truth$truth_grid,
    "known-truth FPCA recovery requires exact source grid")
  .etr_assert(is.list(result$provenance),
    "FPCA provenance must be a source-shaped record")
  fpca <- result$provenance[["fpca", exact = TRUE]]
  .etr_assert(is.null(fpca) || is.list(fpca), "FPCA fit provenance must be source-shaped")
  scaling <- fpca[["scaling", exact = TRUE]]
  .etr_assert(is.null(scaling) || identical(scaling, "none"),
    "known-truth FPCA recovery requires scaling='none'")
  dimensions <- truth$dimension_names
  .etr_assert(is.character(dimensions) && length(dimensions) >= 1L &&
    !anyNA(dimensions) && !anyDuplicated(dimensions) &&
    identical(result$dimension_names, dimensions),
    "fitted dimension names/order do not match generating truth")
  .etr_assert(is.numeric(result$scale) && is.null(dim(result$scale)) &&
    length(result$scale) == length(dimensions) && all(is.finite(result$scale)) &&
    all(abs(result$scale - 1) <= 1e-12),
    "known-truth FPCA recovery requires unit dimension scales")
  recovery <- .etr_fpca_recovery_population(result, truth,
    .etr_recovery_value_factory())
  structure(list(values = recovery$values, provenance = list(
    estimator = "FPCA", multivariate = length(dimensions) > 1L,
    truth_grid_match = "exact", scaling = "none",
    matched_truth_components = recovery$matched_truth_components,
    alignment_signs = recovery$alignment_signs)),
    class = "etr_functional_recovery_assessment")
}
