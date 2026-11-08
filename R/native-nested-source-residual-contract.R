# Pinned frozen Python 1.2 nested-mixed source residual diagnostics.
# Scientific model fitting, covariances, and BLUPs are unchanged.
.etr_nested_source_residual_contract <- function(time,family,parameter,
  correlation,residuals,residual_variance,time_unit) {
  time <- as.numeric(time)
  correlation <- as.matrix(correlation)
  residuals <- as.matrix(residuals)
  nt <- length(time)
  .etr_assert(nt>=2L && all(is.finite(time)) && all(diff(time)>0),
    "source residual diagnostics require increasing finite times")
  .etr_assert(identical(dim(correlation),c(nt,nt)) &&
    all(is.finite(correlation)) && max(abs(correlation-t(correlation)))<1e-10,
    "source residual correlation matrix must be finite symmetric")
  .etr_assert(ncol(residuals)==nt && all(is.finite(residuals)),
    "source residual functions must have one finite row per curve")
  .etr_assert(length(residual_variance)==1L &&
    is.finite(residual_variance) && residual_variance>0,
    "source residual variance must be finite and positive")
  dt <- diff(time)
  regular <- all(abs(dt-dt[1L]) <=
    max(1e-12,abs(dt[1L])*1e-10)+1e-8*abs(dt[1L]))
  interval <- if(regular) dt[1L] else NA_real_
  bounds <- NULL
  transformed_bounds <- NULL
  transformed <- NULL
  if (identical(family,"ar1")) {
    .etr_assert(regular,"AR(1) source requires a regular time grid")
    .etr_assert(length(parameter)==1L && is.finite(parameter) &&
      abs(parameter)<1,"AR(1) parameter must be inside (-1,1)")
    transformed <- atanh(parameter)
    transformed_bounds <- c(-7,7)
    bounds <- tanh(transformed_bounds)
    unit <- "dimensionless"
  } else if (identical(family,"exponential")) {
    .etr_assert(length(parameter)==1L && is.finite(parameter) &&
      parameter>0,"exponential source requires a positive finite phi")
    lo <- max(min(dt)*1e-4,.Machine$double.xmin)
    hi <- max((tail(time,1L)-time[1L])*1e4,lo*10)
    bounds <- c(lo,hi)
    transformed_bounds <- log(bounds)
    transformed <- log(parameter)
    unit <- time_unit
  } else if (identical(family,"iid")) {
    unit <- NA_character_
  } else stop("unknown source residual family",call.=FALSE)
  v <- sort(eigen(correlation,symmetric=TRUE,only.values=TRUE)$values)
  .etr_assert(all(is.finite(v)),"residual correlation eigenvalues must be finite")
  condition <- if(min(v)<=0) Inf else max(v)/min(v)
  boundary <- FALSE
  outside_source_bounds <- FALSE
  if(!is.null(transformed)) {
    edge <- max(1e-3,1e-4*diff(transformed_bounds))
    boundary <- transformed<=transformed_bounds[1L]+edge ||
      transformed>=transformed_bounds[2L]-edge
    outside_source_bounds <- transformed<transformed_bounds[1L] ||
      transformed>transformed_bounds[2L]
  }
  offdiag <- correlation
  diag(offdiag) <- 0
  independent <- identical(family,"exponential") &&
    max(abs(offdiag))<=0.05
  # Source: solve_triangular(cholesky(sigma^2 * C), residual, lower=True).
  lower <- t(chol(residual_variance*correlation))
  white <- t(vapply(seq_len(nrow(residuals)), function(i)
    as.numeric(forwardsolve(lower,residuals[i,])), numeric(nt)))
  dimnames(white) <- dimnames(residuals)
  list(
    residual_correlation_eigenvalues=as.numeric(v),
    residual_correlation_condition_number=as.numeric(condition),
    residual_correlation_boundary_fit=as.logical(boundary),
    residual_correlation_independence_limit_fit=as.logical(independent),
    residual_correlation_optimizer_bounds=bounds,
    residual_correlation_grid_regular=as.logical(regular),
    residual_correlation_grid_interval=interval,
    residual_correlation_parameter_unit=unit,
    residual_correlation_outside_python_optimizer_bounds=
      as.logical(outside_source_bounds),
    whitened_residual_functions=white)
}
