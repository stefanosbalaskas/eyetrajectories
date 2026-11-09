# Native likelihood residual data-contract adapter.
# Frozen source: eyetrajectoriespy 1.2.0 at
# c1cd95ad718327550f7e55393ff38582872f7a94,
# functional_mixed_effects_diagnostics.py.
# No native model refit, Python runtime bridge or certification is performed.

.etr_mixed_source_residual_view <- function(result) {
  if(inherits(result,"etr_functional_mixed_moments")) {
    .etr_mixed_moments_fit(result)
    return(result)
  }
  if(inherits(result,"etr_joint_bspline_mixed")) {
    .etr_assert(is.list(result) && identical(result$backend,"nlme::lme"),
      "joint residual analysis requires an actual native nlme fit")
    ids <- if(!is.null(result$source_curve_ids))
      result$source_curve_ids else result$curve_ids
    unit <- result$time_unit
    dimension <- if(!is.null(result$dimension_name))
      result$dimension_name else result$dimension
    data <- list(time=result$time,time_unit=unit,
      dimension_name=dimension,
      source_curve_ids=ids,
      curve_participant_ids=result$curve_participant_ids,
      residual_functions=result$residual_functions,
      residual_variance=result$residual_variance,
      residual_correlation_matrix=result$residual_correlation_matrix,
      provenance=list(
        residual_model="native_joint_nlme_likelihood_not_python_optimizer",
        source_python_full_parity=FALSE))
    class(data) <- "etr_joint_source_residual_view"
    result <- data
  }
  .etr_assert(inherits(result,"etr_joint_source_residual_view") &&
    is.list(result),
    "requires a native mixed-moments or joint B-spline likelihood fit")
  t <- result$time
  ids <- result$source_curve_ids
  participants <- result$curve_participant_ids
  residual <- result$residual_functions
  corr <- result$residual_correlation_matrix
  variance <- result$residual_variance
  .etr_assert(is.numeric(t) && is.null(dim(t)) &&
    length(t)>=2L && all(is.finite(t)) && all(diff(t)>0),
    "source residual time grid must be finite and strictly increasing")
  .etr_assert(is.character(result$time_unit) &&
    length(result$time_unit)==1L && !is.na(result$time_unit) &&
    nzchar(result$time_unit) &&
    is.character(result$dimension_name) &&
    length(result$dimension_name)==1L &&
    !is.na(result$dimension_name) && nzchar(result$dimension_name),
    "source residual time unit and response dimension are required")
  .etr_assert(is.character(ids) && length(ids)>=1L &&
    !anyNA(ids) && all(nzchar(ids)) && !anyDuplicated(ids) &&
    is.character(participants) && length(participants)==length(ids) &&
    !anyNA(participants) && all(nzchar(participants)),
    "source curve/participant identifiers must be complete and aligned")
  .etr_assert(is.matrix(residual) && is.numeric(residual) &&
    identical(dim(residual),c(length(ids),length(t))) &&
    all(is.finite(residual)),
    "joint conditional residual functions must be finite and curve-aligned")
  .etr_assert(is.numeric(variance) && length(variance)==1L &&
    is.finite(variance) && variance>0,
    "source joint residual variance must be positive")
  .etr_assert(is.matrix(corr) && is.numeric(corr) &&
    identical(dim(corr),c(length(t),length(t))) &&
    all(is.finite(corr)) &&
    max(abs(corr-base::t(corr)))<1e-8,
    "joint residual correlation matrix must be finite symmetric n_time square")
  invisible(result)
}
