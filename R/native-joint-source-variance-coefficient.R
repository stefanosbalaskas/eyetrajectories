# Native joint Gaussian fit adapters for existing public source numerical
# reporting functions. No model refit, covariance estimation, or Python bridge.
# Frozen Python reference: eyetrajectoriespy==1.2.0
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Full Python dataclass, optimizer and domain parity remains uncertified.

.etr_joint_source_variance_record <- function(fit) {
  .etr_assert(inherits(fit,"etr_joint_bspline_mixed"),
    "variance record requires a native joint B-spline mixed fit")
  t <- fit$time
  B <- fit$random_basis
  G <- fit$random_effect_covariance
  .etr_assert(is.numeric(t) && is.null(dim(t)) &&
    length(t)>=2L && all(is.finite(t)) && all(diff(t)>0),
    "joint fit time must be a finite strictly increasing vector")
  .etr_assert(is.matrix(B) && is.numeric(B) &&
    nrow(B)==length(t) && ncol(B)>=1L && all(is.finite(B)),
    "joint fit random basis is not a finite time-by-basis matrix")
  k <- ncol(B)
  slope <- inherits(fit,"etr_joint_bspline_mixed_slope") ||
    inherits(fit,"etr_joint_bspline_mixed_nested_slope")
  n_random <- if(slope)2L*k else k
  .etr_assert(is.matrix(G) && is.numeric(G) &&
    identical(dim(G),c(n_random,n_random)) &&
    all(is.finite(G)) && max(abs(G-t(G)))<=1e-6,
    "joint random covariance must be a finite symmetric basis matrix")
  .etr_assert(is.numeric(fit$residual_variance) &&
    length(fit$residual_variance)==1L &&
    is.finite(fit$residual_variance) && fit$residual_variance>0,
    "joint residual variance must be positive and finite")
  trial <- if(inherits(fit,"etr_joint_bspline_mixed_nested_trial") ||
    inherits(fit,"etr_joint_bspline_mixed_nested_slope"))
    "functional_intercept" else NULL
  intercept <- G[seq_len(k),seq_len(k),drop=FALSE]
  out <- list(time=t,random_basis=B,
    random_intercept_covariance=intercept,
    random_slope_covariance=NULL,
    random_intercept_slope_covariance=NULL,
    trial_random_effect=trial,
    trial_random_basis=NULL,
    trial_random_effect_covariance=NULL,
    residual_variance=fit$residual_variance)
  if(slope){
    i <- k+seq_len(k)
    out$random_slope_covariance <- G[i,i,drop=FALSE]
    out$random_intercept_slope_covariance <-
      G[seq_len(k),i,drop=FALSE]
  }
  if(!is.null(trial)){
    C <- fit$trial_random_effect_covariance
    Bt <- fit$trial_random_basis
    .etr_assert(is.matrix(Bt) && is.numeric(Bt) &&
      nrow(Bt)==length(t) && ncol(Bt)>=1L &&
      all(is.finite(Bt)),
      "nested trial basis must be a finite time-by-basis matrix")
    .etr_assert(is.matrix(C) && is.numeric(C) &&
      identical(dim(C),c(ncol(Bt),ncol(Bt))) &&
      all(is.finite(C)) && max(abs(C-t(C)))<=1e-6,
      "nested trial covariance must match the trial basis")
    out$trial_random_basis <- Bt
    out$trial_random_effect_covariance <- C
  }
  out
}

.etr_joint_source_coefficient_frame <- function(fit,band=NULL){
  .etr_assert(inherits(fit,"etr_joint_bspline_mixed"),
    "coefficient frame requires a native joint B-spline mixed fit")
  .etr_assert(is.null(band),
    "native joint-source simultaneous bootstrap bands are not verified")
  dimension <- if(!is.null(fit$dimension_name))
    fit$dimension_name else fit$dimension
  .etr_assert(is.character(dimension) && length(dimension)==1L &&
    !is.na(dimension) && nzchar(dimension),
    "joint coefficient result requires a nonempty dimension")
  .etr_joint_workflow_coefficient_frame(fit,dimension)
}
