# Bounded native joint functional mixed-effects model with correlated residuals.
# Python frozen source: functional_mixed_effects_nested.py @ c1cd95ad.
# Native scientific estimator, NOT an identical Python optimizer/result contract.
# Participant B-spline random intercept; within-curve AR(1) or exponential
# serial covariance; no trial random effect or random slope in this function.

.etr_joint_serial_grid <- function(time, family) {
  .etr_assert(is.numeric(time) && length(time) >= 3L &&
    all(is.finite(time)) && all(diff(time) > 0),
    "serial covariance requires a finite increasing grid with >=3 observations")
  .etr_assert(is.character(family) && length(family) == 1L &&
    !is.na(family) && family %in% c("ar1", "exponential"),
    "residual_correlation must be 'ar1' or 'exponential'")
  gaps <- diff(time)
  regular <- all(abs(gaps - gaps[1L]) <=
    (max(1e-12, abs(gaps[1L])*1e-10) + 1e-8*abs(gaps[1L])))
  .etr_assert(family != "ar1" || regular,
    "AR(1) requires an equally spaced grid; use exponential on irregular time grids")
  # Rescaling time controls optimization conditioning without changing the
  # physical-time exponential model. phi is always reported in source units.
  scale <- stats::median(gaps)
  .etr_assert(is.finite(scale) && scale > 0 &&
    all(is.finite((time - time[1L]) / scale)),
    "physical-time grid cannot be scaled safely")
  list(regular=regular, scale=scale, scaled=(time-time[1L])/scale)
}

.etr_joint_serial_correlation_matrix <- function(time, family, parameter) {
  .etr_assert(is.numeric(time) && length(time) >= 2L &&
    all(is.finite(time)) && all(diff(time) > 0),
    "time must be strictly increasing and finite")
  .etr_assert(is.numeric(parameter) && length(parameter) == 1L &&
    is.finite(parameter), "serial correlation parameter must be finite")
  if (identical(family,"ar1")) {
    .etr_assert(abs(parameter) < 1,
      "AR(1) rho must be strictly inside (-1,1)")
    lag <- abs(outer(seq_along(time),seq_along(time),"-"))
    return(parameter^lag)
  }
  .etr_assert(identical(family,"exponential") && parameter > 0,
    "exponential phi must be strictly positive")
  exp(-abs(outer(time,time,"-"))/parameter)
}

#' Joint B-spline functional mixed model with serial residual correlation
#'
#' Fits a participant-level unstructured B-spline random intercept model using
#' nlme and within-source-curve residual correlation: AR(1) for regular grids,
#' or exponential decay on physical time for arbitrary increasing grids.
#' Residual correlations do not extend across separate source curves/trials.
#' This is a native R likelihood model, not a certified Python 1.2 contract.
#'
#' @param trajectories Complete finite etr_trajectory_set.
#' @param design One row per curve with unique curve_id and numeric predictors.
#' @param predictors Named numeric fixed predictors; may be character(0).
#' @param participant_column Metadata field identifying participants.
#' @param dimension Name of one response channel.
#' @param residual_correlation Exactly "ar1" or "exponential".
#' @param fixed_basis_size Number of fixed B-spline basis functions.
#' @param random_basis_size Number of random B-spline basis functions.
#' @param spline_degree B-spline degree 1 through 5.
#' @param reml TRUE for restricted maximum likelihood, FALSE for ML.
#' @param maxiter Maximum optimizer iterations, at least 10.
#' @return An etr_joint_bspline_mixed_correlated S3 model with fixed curves,
#'   SEs, conditional fitted curves, random-effect covariance, residual
#'   variance, correlation family and parameters, and nlme backend fit.
#' @export
etr_fit_joint_bspline_functional_correlated <- function(
    trajectories, design, predictors, participant_column, dimension,
    residual_correlation = "ar1", fixed_basis_size = 6L,
    random_basis_size = 4L, spline_degree = 3L,
    reml = TRUE, maxiter = 500L) {
  if (!requireNamespace("nlme", quietly=TRUE))
    stop("The optional package 'nlme' is required",call.=FALSE)
  .etr_assert(exists("etr_fit_joint_bspline_functional_mixed_effects",
    mode="function"), "Batch 35 joint mixed-effects method required")
  grid <- .etr_joint_serial_grid(trajectories$time, residual_correlation)
  # The established native joint model validates source data and creates
  # exact fixed/random spline designs. Its own fit is only an initial safety
  # check; a separate, full ML/REML fit estimates the serial covariance.
  base <- etr_fit_joint_bspline_functional_mixed_effects(
    trajectories=trajectories, design=design, predictors=predictors,
    participant_column=participant_column, dimension=dimension,
    fixed_basis_size=fixed_basis_size, random_basis_size=random_basis_size,
    spline_degree=spline_degree, reml=reml, maxiter=maxiter)
  ids <- base$curve_ids
  nt <- base$n_time
  nc <- base$n_curves
  np <- base$n_participants
  X <- base$fixed_long_design
  Z <- base$random_long_design
  fixed_names <- colnames(X)
  random_names <- colnames(Z)
  .etr_assert(is.matrix(X) && is.matrix(Z) &&
    length(fixed_names) == ncol(X) && length(random_names) == ncol(Z),
    "existing joint B-spline design has missing column names")
  observed <- as.vector(t(base$observed_functions))
  time <- base$time
  dat <- data.frame(
    .etr_y = observed,
    .etr_pid = factor(rep(base$curve_participant_ids,each=nt),
      levels=base$participant_ids),
    .etr_curve = factor(rep(ids,each=nt),levels=ids),
    .etr_index = rep(seq_len(nt),times=nc),
    .etr_scaled_time = rep(grid$scaled,times=nc))
  for (k in seq_along(fixed_names)) dat[[fixed_names[k]]] <- X[,k]
  for (k in seq_along(random_names)) dat[[random_names[k]]] <- Z[,k]
  fixed_formula <- stats::reformulate(fixed_names,
    response=".etr_y",intercept=FALSE)
  random_formula <- stats::reformulate(random_names,intercept=FALSE)
  corr <- if (identical(residual_correlation,"ar1"))
    nlme::corAR1(value=0.2,form=~.etr_index | .etr_pid/.etr_curve)
  else nlme::corCAR1(value=0.5,
    form=~.etr_scaled_time | .etr_pid/.etr_curve)
  fit <- tryCatch(
    nlme::lme(fixed=fixed_formula,
      random=list(.etr_pid=nlme::pdSymm(random_formula)),
      correlation=corr, data=dat,
      method=if (reml) "REML" else "ML",
      control=nlme::lmeControl(maxIter=as.integer(maxiter),
        msMaxIter=as.integer(maxiter),returnObject=FALSE)),
    error=function(e) stop(paste("serial B-spline model failed to converge:",
      conditionMessage(e)),call.=FALSE))
  fe <- nlme::fixef(fit)
  .etr_assert(all(fixed_names %in% names(fe)),
    "joint serial fit omitted fixed spline coefficients")
  coefficient_names <- base$predictor_names
  nf <- ncol(base$fixed_basis)
  fixed_coefficients <- matrix(as.numeric(fe[fixed_names]),
    nrow=length(coefficient_names),ncol=nf,byrow=TRUE,
    dimnames=list(coefficient_names,NULL))
  fixed_functions <- fixed_coefficients %*% t(base$fixed_basis)
  dimnames(fixed_functions) <- list(coefficient_names,NULL)
  vc <- as.matrix(stats::vcov(fit))
  .etr_assert(all(fixed_names %in% rownames(vc)) &&
    all(fixed_names %in% colnames(vc)),
    "serial fit fixed-effect covariance lacks expected columns")
  vc <- vc[fixed_names,fixed_names,drop=FALSE]
  se <- matrix(NA_real_,length(coefficient_names),nt,
    dimnames=list(coefficient_names,NULL))
  for (j in seq_along(coefficient_names)) {
    ii <- (j-1L)*nf+seq_len(nf)
    block <- vc[ii,ii,drop=FALSE]
    se[j,] <- sqrt(pmax(0,rowSums((base$fixed_basis %*% block)*base$fixed_basis)))
  }
  re <- as.matrix(nlme::ranef(fit))
  .etr_assert(all(random_names %in% colnames(re)) &&
    !is.null(rownames(re)) &&
    all(base$participant_ids %in% rownames(re)),
    "serial fit random-effect table has unexpected dimensions")
  b <- re[base$participant_ids,random_names,drop=FALSE]
  random_functions <- b %*% t(base$random_basis)
  rownames(random_functions) <- base$participant_ids
  group <- match(base$curve_participant_ids,base$participant_ids)
  fitted_values <- base$scalar_design %*% fixed_functions +
    random_functions[group,,drop=FALSE]
  residuals <- base$observed_functions - fitted_values
  sigma2 <- as.numeric(fit$sigma)^2
  G <- tryCatch(as.matrix(nlme::getVarCov(fit,type="random.effects")),
    error=function(e) NULL)
  nr <- ncol(base$random_basis)
  if (is.null(G) || !identical(dim(G),c(nr,nr)))
    G <- as.matrix(nlme::pdMatrix(fit$modelStruct$reStruct[[1L]]))*sigma2
  .etr_assert(identical(dim(G),c(nr,nr)) && all(is.finite(G)) &&
    all(is.finite(se)) && is.finite(sigma2) && sigma2 > 0,
    "serial mixed-effects covariance extraction invalid")
  rho <- as.numeric(stats::coef(fit$modelStruct$corStruct,
    unconstrained=FALSE))
  .etr_assert(length(rho) == 1L && is.finite(rho),
    "estimated residual correlation parameter missing")
  if (identical(residual_correlation,"ar1")) {
    .etr_assert(abs(rho) < 1,"estimated AR(1) correlation outside (-1,1)")
    parameter <- rho
    parameter_name <- "rho"
    parameter_units <- "index_step"
  } else {
    .etr_assert(rho > 0 && rho < 1,
      "estimated continuous AR(1) correlation outside (0,1)")
    parameter <- -grid$scale/log(rho)
    parameter_name <- "phi"
    parameter_units <- trajectories$time_unit
  }
  C <- .etr_joint_serial_correlation_matrix(time,residual_correlation,parameter)
  .etr_assert(all(is.finite(C)) && max(abs(C-t(C))) < 1e-12 &&
    max(abs(diag(C)-1)) < 1e-12,
    "serial correlation matrix is invalid")
  structure(list(
    method=if(reml) "joint_bspline_correlated_REML" else "joint_bspline_correlated_ML",
    estimator=paste0("nlme_unstructured_participant_random_bspline_intercept_",
      residual_correlation),backend="nlme::lme",
    source_python_full_parity=FALSE,
    dimension=dimension,dimension_name=dimension,
    time=time,time_unit=trajectories$time_unit,
    curve_ids=ids,source_curve_ids=ids,
    fixed_basis_size=ncol(base$fixed_basis),
    random_basis_size=ncol(base$random_basis),
    coefficient_names=base$predictor_names,
    scalar_design_matrix=base$scalar_design,
    log_likelihood=as.numeric(stats::logLik(fit)),
    participant_ids=base$participant_ids,
    curve_participant_ids=base$curve_participant_ids,
    predictor_names=coefficient_names,
    fixed_basis=base$fixed_basis,random_basis=base$random_basis,
    fixed_basis_coefficients=fixed_coefficients,
    fixed_coefficient_functions=fixed_functions,
    fixed_standard_errors=se,fixed_parameter_covariance=vc,
    random_effect_coefficients=b,
    random_effect_functions=random_functions,
    random_effect_covariance=G,residual_variance=sigma2,
    residual_correlation=residual_correlation,
    residual_correlation_parameter=parameter,
    residual_correlation_parameter_name=parameter_name,
    residual_correlation_parameter_units=parameter_units,
    residual_correlation_matrix=C,
    fitted_functions=fitted_values,residual_functions=residuals,
    observed_functions=base$observed_functions,
    fixed_long_design=X,random_long_design=Z,
    scalar_design=base$scalar_design,
    n_participants=np,n_curves=nc,n_time=nt,
    spline_degree=base$spline_degree,reml=reml,
    fitted_model=fit,provenance=list(
      scientific_scope="participant_Bspline_intercept_serial_curve_residual",
      serial_residual_independent_across_source_curves=TRUE,
      trial_random_effect_supported=FALSE,
      random_slope_supported=FALSE,
      numerical_source_full_domain_certified=FALSE)),
    class=c("etr_joint_bspline_mixed_correlated","etr_joint_bspline_mixed"))
}
