# Diagnostics aligned to frozen Python 1.2 functional_mixed_effects_nested.py.
# Retains covariance's natural numerical boundary: no ridge, clipping or
# refitting. Internal helper only, not a new public Python-parity claim.
.etr_nested_source_covariance_diagnostics <- function(covariance) {
  .etr_assert(is.matrix(covariance) && is.numeric(covariance) &&
    nrow(covariance)==ncol(covariance) && nrow(covariance)>0L &&
    all(is.finite(covariance)),
    "fitted covariance contains non-finite values or invalid shape")
  .etr_assert(all(abs(covariance-t(covariance)) <=
    1e-12 + 1e-10*abs(t(covariance))),
    "fitted covariance is not symmetric")
  values <- sort(as.numeric(eigen(covariance,symmetric=TRUE,
    only.values=TRUE)$values))
  scale <- max(1, max(abs(covariance)))
  .etr_assert(min(values)>=-1e-10*scale,
    "fitted covariance is not positive semidefinite")
  largest <- max(abs(values))
  singular_tolerance <- max(.Machine$double.eps*max(1,largest),1e-14)
  list(eigenvalues=values,
    condition_number=if(min(values)<=0) Inf else max(values)/min(values),
    boundary=as.logical(min(values)<=1e-8*scale),
    singular=as.logical(min(values)<=singular_tolerance),
    scale=scale)
}
.etr_nested_source_joint_diagnostics <- function(participant,trial,residual_variance) {
  .etr_assert(is.numeric(residual_variance) && length(residual_variance)==1L &&
    is.finite(residual_variance) && residual_variance>0,
    "residual variance must be positive finite")
  p <- .etr_nested_source_covariance_diagnostics(participant)
  t <- .etr_nested_source_covariance_diagnostics(trial)
  reference_scale <- max(max(abs(p$eigenvalues)),residual_variance,.Machine$double.eps)
  t$boundary <- isTRUE(t$boundary) || max(t$eigenvalues) <= .10*reference_scale
  list(participant=p,trial=t)
}
