# Native joint B-spline participant intercept/slope and nested trial functional
# random effects, with optional within-trial serial covariance.
# Frozen Python reference: eyetrajectoriespy 1.2.0
# functional_mixed_effects_nested.py @ c1cd95ad718327550f7e55393ff38582872f7a94.
# This bounded R/nlme optimizer is not a full Python source-contract certificate.

#' Joint B-spline functional participant random slope plus nested trial effects
#'
#' Estimates smooth fixed functions, correlated participant-specific random
#' intercept and slope functions and a separate nested trial random function.
#' Participant and trial random-effect spline coefficients each have a fully
#' unstructured covariance. The source curves are independent trials nested
#' in participants, and residual correlation is iid, regular-grid AR(1), or
#' irregular-grid physical-time exponential within each curve. The estimator
#' fits a native joint Gaussian ML/REML model with nlme; no Python is called.
#'
#' @param trajectories Complete finite common-grid trajectory collection.
#' @param design One row per trajectory with a unique curve_id.
#' @param predictors Numeric fixed-effect predictor names.
#' @param participant_column Metadata participant identifier.
#' @param trial_column Distinct nested trial identifier (one curve per trial).
#' @param dimension Name of one trajectory response channel.
#' @param random_slope_predictor Predictor that varies within every participant.
#' @param residual_correlation One of "iid", "ar1", "exponential".
#' @param fixed_basis_size Number of fixed-effect B-spline basis functions.
#' @param random_basis_size Number of participant random-effect basis functions.
#' @param trial_random_basis_size Number of trial random basis functions.
#' @param spline_degree Degree of all clamped B-splines, 1 through 5.
#' @param reml TRUE for restricted likelihood; FALSE for maximum likelihood.
#' @param maxiter Maximum optimizer iterations, an integer >= 10.
#' @return An object inheriting etr_joint_bspline_mixed with fixed functions,
#'   SEs, participant intercept/slope and trial BLUP functions, their covariance
#'   matrices, Gaussian fitted functions, residual correlation and nlme model.
#' @export
etr_fit_joint_bspline_functional_nested_slope <- function(
    trajectories,design,predictors,participant_column,trial_column,dimension,
    random_slope_predictor,residual_correlation="iid",
    fixed_basis_size=6L,random_basis_size=4L,
    trial_random_basis_size=4L,spline_degree=3L,
    reml=TRUE,maxiter=500L) {
  if (!requireNamespace("nlme",quietly=TRUE))
    stop("The optional package 'nlme' is required",call.=FALSE)
  .etr_assert(is.character(residual_correlation) &&
      length(residual_correlation)==1L && !is.na(residual_correlation) &&
      residual_correlation %in% c("iid","ar1","exponential"),
    "residual_correlation must be 'iid', 'ar1', or 'exponential'")
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(is.numeric(spline_degree) && length(spline_degree)==1L &&
      is.finite(spline_degree) && spline_degree==floor(spline_degree) &&
      spline_degree>=1L && spline_degree<=5L,
    "spline_degree must be an integer from 1 to 5")
  .etr_assert(is.numeric(trial_random_basis_size) &&
      length(trial_random_basis_size)==1L &&
      is.finite(trial_random_basis_size) &&
      trial_random_basis_size==floor(trial_random_basis_size) &&
      trial_random_basis_size>=spline_degree+1L &&
      trial_random_basis_size<=length(trajectories$time),
    "trial_random_basis_size must be an integer between degree+1 and grid size")
  .etr_assert(is.numeric(maxiter) && length(maxiter)==1L &&
      is.finite(maxiter) && maxiter==floor(maxiter) && maxiter>=10L,
    "maxiter must be an integer >= 10")
  .etr_assert(is.logical(reml) && length(reml)==1L && !is.na(reml),
    "reml must be a nonmissing logical scalar")
  .etr_assert(is.character(participant_column) &&
      length(participant_column)==1L && !is.na(participant_column) &&
      participant_column%in%names(trajectories$metadata),
    "participant_column must identify existing trajectory metadata")
  trial <- .etr_nested_trial_structure(trajectories,
    participant_column,trial_column)
  serial <- if (identical(residual_correlation,"iid")) NULL else
    .etr_joint_serial_grid(trajectories$time,residual_correlation)
  # Reuse the qualified Stage36 full input/domain/design validation. This
  # preliminary iid participant-only fit is NOT the returned joint estimator;
  # it prevents an automatic fallback on poorly identified random slopes.
  base <- etr_fit_joint_bspline_functional_random_slope(
    trajectories=trajectories,design=design,predictors=predictors,
    participant_column=participant_column,dimension=dimension,
    random_slope_predictor=random_slope_predictor,
    fixed_basis_size=fixed_basis_size,random_basis_size=random_basis_size,
    spline_degree=spline_degree,reml=reml,maxiter=maxiter)
  .etr_assert(identical(base$curve_participant_ids,trial$participant),
    "participant/trajectory alignment changed after baseline validation")
  nc <- base$n_curves; nt <- base$n_time
  nr <- ncol(base$random_basis); nd <- 2L*nr
  ntr <- as.integer(trial_random_basis_size)
  .etr_assert(length(unique(trial$composite)) > ntr*(ntr+1)/2,
    "number of nested trials must exceed trial covariance parameter count")
  .etr_assert(as.double(nc)*nt*(nd+ntr) <= 1e7,
    "nested slope expansion exceeds dense safety limit")
  trial_basis <- .etr_joint_bspline_basis(base$time,ntr,
    as.integer(spline_degree))
  X <- base$fixed_long_design
  Zp <- base$random_long_design
  fixed_names <- colnames(X)
  participant_names <- colnames(Zp)
  trial_names <- paste0(".etr_slt",seq_len(ntr))
  Zt <- matrix(NA_real_,nc*nt,ntr,dimnames=list(NULL,trial_names))
  for (j in seq_len(ntr)) Zt[,j] <- rep(trial_basis[,j],nc)
  .etr_assert(qr(Zt)$rank==ntr,
    "nested trial B-spline random design is rank deficient")
  dat <- data.frame(.etr_y=as.vector(t(base$observed_functions)),
    .etr_pid=factor(rep(trial$participant,each=nt),
      levels=trial$participant_ids),
    .etr_trial=factor(rep(trial$trial,each=nt),
      levels=unique(trial$trial)),
    .etr_time_index=rep(seq_len(nt),nc))
  if (!is.null(serial)) dat$.etr_time_scaled <- rep(serial$scaled,nc)
  for (j in seq_along(fixed_names)) dat[[fixed_names[j]]] <- X[,j]
  for (j in seq_along(participant_names)) dat[[participant_names[j]]] <- Zp[,j]
  for (j in seq_along(trial_names)) dat[[trial_names[j]]] <- Zt[,j]
  ff <- stats::reformulate(fixed_names,response=".etr_y",intercept=FALSE)
  pp <- stats::reformulate(participant_names,intercept=FALSE)
  tt <- stats::reformulate(trial_names,intercept=FALSE)
  corr <- switch(residual_correlation,
    iid=NULL,
    ar1=nlme::corAR1(value=.2,form=~.etr_time_index|.etr_pid/.etr_trial),
    exponential=nlme::corCAR1(value=.5,
      form=~.etr_time_scaled|.etr_pid/.etr_trial))
  fit <- tryCatch(nlme::lme(fixed=ff,
      random=list(.etr_pid=nlme::pdSymm(pp),
        .etr_trial=nlme::pdSymm(tt)),
      correlation=corr,data=dat,method=if(reml) "REML" else "ML",
      control=nlme::lmeControl(maxIter=as.integer(maxiter),
        msMaxIter=as.integer(maxiter),returnObject=FALSE)),
    error=function(e) stop(paste("nested-slope joint functional model failed:",
      conditionMessage(e)),call.=FALSE))
  fixed <- nlme::fixef(fit)
  .etr_assert(all(fixed_names %in% names(fixed)),
    "joint nested-slope model omitted fixed spline coefficients")
  nf <- ncol(base$fixed_basis)
  ncoef <- length(base$predictor_names)
  beta <- matrix(as.numeric(fixed[fixed_names]),ncoef,nf,byrow=TRUE,
    dimnames=list(base$predictor_names,NULL))
  functions <- beta %*% t(base$fixed_basis)
  dimnames(functions) <- list(base$predictor_names,NULL)
  vc <- as.matrix(stats::vcov(fit))
  .etr_assert(all(fixed_names %in% rownames(vc)) &&
      all(fixed_names %in% colnames(vc)),
    "joint nested-slope coefficient covariance is missing fixed parameter names")
  vc <- vc[fixed_names,fixed_names,drop=FALSE]
  se <- matrix(NA_real_,ncoef,nt,dimnames=list(base$predictor_names,NULL))
  for (j in seq_len(ncoef)) {
    ii <- (j-1L)*nf+seq_len(nf)
    se[j,] <- sqrt(pmax(0,rowSums((base$fixed_basis %*%
      vc[ii,ii,drop=FALSE])*base$fixed_basis)))
  }
  sigma2 <- as.numeric(fit$sigma)^2
  .etr_assert(is.finite(sigma2) && sigma2>0,
    "nested-slope residual variance must be positive finite")
  Gp <- .etr_nested_trial_covariance(fit,".etr_pid",nd,sigma2)
  Gt <- .etr_nested_trial_covariance(fit,".etr_trial",ntr,sigma2)
  source_diagnostics <- .etr_nested_source_joint_diagnostics(Gp,Gt,sigma2)
  if (identical(residual_correlation,"iid")) {
    parameter <- NA_real_;parameter_name <- NA_character_
    parameter_unit <- NA_character_;C <- diag(nt)
  } else {
    rho <- as.numeric(stats::coef(fit$modelStruct$corStruct,
      unconstrained=FALSE))
    .etr_assert(length(rho)==1L && is.finite(rho),
      "joint nested-slope residual correlation estimate invalid")
    if (identical(residual_correlation,"ar1")) {
      .etr_assert(abs(rho)<1,"AR(1) rho must be within (-1,1)")
      parameter <- rho;parameter_name <- "rho";parameter_unit <- "index_step"
    } else {
      .etr_assert(rho>0 && rho<1,
        "continuous serial correlation parameter must lie in (0,1)")
      parameter <- -serial$scale/log(rho)
      parameter_name <- "phi";parameter_unit <- trajectories$time_unit
    }
    C <- .etr_joint_serial_correlation_matrix(base$time,
      residual_correlation,parameter)
  }
  gpcoef <- matrix(NA_real_,length(trial$participant_ids),nd,
    dimnames=list(trial$participant_ids,participant_names))
  gtcoef <- matrix(NA_real_,nc,ntr,
    dimnames=list(base$curve_ids,trial_names))
  beta_vector <- as.numeric(fixed[fixed_names])
  # Independent conditional BLUP equations for the two nested levels. The
  # participant random-effect design has BOTH intercept/slope basis blocks.
  for (g in seq_along(trial$participant_ids)) {
    ci <- which(trial$participant==trial$participant_ids[g])
    m <- length(ci)
    rowid <- unlist(lapply(ci,function(i) (i-1L)*nt+seq_len(nt)),
      use.names=FALSE)
    zg <- Zp[rowid,,drop=FALSE]
    E <- dat$.etr_y[rowid] - as.vector(X[rowid,,drop=FALSE]%*%beta_vector)
    V <- zg%*%Gp%*%t(zg)
    for (h in seq_along(ci)) {
      rr <- (h-1L)*nt+seq_len(nt)
      Zth <- Zt[(ci[h]-1L)*nt+seq_len(nt),,drop=FALSE]
      V[rr,rr] <- V[rr,rr]+Zth%*%Gt%*%t(Zth)+sigma2*C
    }
    .etr_assert(all(is.finite(V)) && max(abs(V-t(V)))<1e-7,
      "nested-slope marginal covariance assembly failed")
    factor <- tryCatch(chol(V),error=function(e) NULL)
    .etr_assert(!is.null(factor),
      "nested-slope marginal covariance is not positive definite")
    w <- backsolve(factor,forwardsolve(t(factor),E))
    gpcoef[g,] <- as.vector(Gp%*%crossprod(zg,w))
    for (h in seq_along(ci)) {
      rr <- (h-1L)*nt+seq_len(nt)
      Zth <- Zt[(ci[h]-1L)*nt+seq_len(nt),,drop=FALSE]
      gtcoef[ci[h],] <- as.vector(Gt%*%crossprod(Zth,w[rr]))
    }
  }
  gpi <- gpcoef[,seq_len(nr),drop=FALSE]%*%t(base$random_basis)
  gps <- gpcoef[,nr+seq_len(nr),drop=FALSE]%*%t(base$random_basis)
  gtf <- gtcoef%*%t(trial_basis)
  grp <- match(trial$participant,trial$participant_ids)
  slope_mat <- matrix(base$random_slope_values,nrow=nc,ncol=nt)
  predicted <- base$scalar_design%*%functions+
    gpi[grp,,drop=FALSE]+gps[grp,,drop=FALSE]*slope_mat+gtf
  resid <- base$observed_functions-predicted
  .etr_assert(all(is.finite(predicted)) && all(is.finite(se)) &&
      all(se>=0),"nested-slope predictions or standard errors are invalid")
  residual_source <- .etr_nested_source_residual_contract(
    base$time,residual_correlation,parameter,C,resid,sigma2,
    trajectories$time_unit)
  structure(list(
    method=if(reml) "joint_nested_slope_bspline_REML" else
      "joint_nested_slope_bspline_ML",
    estimator=paste0("nlme_nested_participant_slope_trial_bspline_",
      residual_correlation),backend="nlme::lme",
    source_python_full_parity=FALSE,dimension=dimension,time=base$time,
    coordinate_system=trajectories$coordinate_system,
    curve_ids=base$curve_ids,participant_ids=trial$participant_ids,
    curve_participant_ids=trial$participant,
    source_trial_ids=trial$trial,curve_trial_ids=trial$trial,
    trial_ids=paste0(trial$participant,"::",trial$trial),composite_trial_ids=trial$composite,
    predictor_names=base$predictor_names,
    random_slope_predictor=random_slope_predictor,
    random_slope_values=base$random_slope_values,
    fixed_basis=base$fixed_basis,random_basis=base$random_basis,
    trial_column=trial_column,trial_random_effect="functional_intercept",
    trial_random_basis_size=ntr,
    trial_random_effect_covariance_parameter_count=as.integer(ntr*(ntr+1L)/2L),
    trial_random_effect_complexity_warning=FALSE,
    random_effect_dimension=ncol(gpcoef),
    random_effect_covariance_parameter_count=
      as.integer(ncol(gpcoef)*(ncol(gpcoef)+1L)/2L),
    random_effect_complexity_warning=
      length(trial$participant_ids)<=ncol(gpcoef)*(ncol(gpcoef)+1L)/2L,
    fixed_basis_size=ncol(base$fixed_basis),
    random_basis_size=nr,
    coefficient_names=base$predictor_names,
    dimension_name=dimension,source_curve_ids=base$curve_ids,
    time_unit=trajectories$time_unit,
    scalar_design_matrix=base$scalar_design,
    log_likelihood=as.numeric(stats::logLik(fit)),
    trial_random_basis=trial_basis,fixed_basis_coefficients=beta,
    coefficient_functions=functions,
    coefficient_standard_errors=se,
    random_effect_coefficients=gpcoef,
    random_intercept_coefficients=gpcoef[,seq_len(nr),drop=FALSE],
    random_slope_coefficients=gpcoef[,nr+seq_len(nr),drop=FALSE],
    random_effect_functions=gpi,
    random_intercept_functions=gpi,
    random_slope_functions=gps,
    random_intercept_covariance=Gp[seq_len(nr),seq_len(nr),drop=FALSE],
    random_slope_covariance=Gp[nr+seq_len(nr),nr+seq_len(nr),drop=FALSE],
    random_intercept_slope_covariance=
      Gp[seq_len(nr),nr+seq_len(nr),drop=FALSE],
    fixed_coefficient_functions=functions,fixed_standard_errors=se,
    fixed_parameter_covariance=vc,
    participant_random_effect_coefficients=gpcoef,
    participant_random_effect_functions=gpi,
    participant_random_slope_effect_functions=gps,
    trial_random_effect_coefficients=gtcoef,
    trial_random_effect_functions=gtf,
    random_effect_covariance_eigenvalues=source_diagnostics$participant$eigenvalues,
    random_effect_covariance_condition_number=source_diagnostics$participant$condition_number,
    random_effect_boundary_fit=source_diagnostics$participant$boundary,
    random_effect_singular=source_diagnostics$participant$singular,
    trial_random_effect_covariance_eigenvalues=source_diagnostics$trial$eigenvalues,
    trial_random_effect_covariance_condition_number=source_diagnostics$trial$condition_number,
    trial_random_effect_boundary_fit=source_diagnostics$trial$boundary,
    trial_random_effect_singular=source_diagnostics$trial$singular,
    random_effect_covariance=Gp,
    intercept_slope_covariance=Gp[seq_len(nr),nr+seq_len(nr),drop=FALSE],
    trial_random_effect_covariance=Gt,residual_variance=sigma2,
    residual_correlation=residual_correlation,
    residual_correlation_parameter=parameter,
    residual_correlation_parameter_name=parameter_name,
    residual_correlation_parameter_units=parameter_unit,
    residual_correlation_matrix=C,
    residual_correlation_eigenvalues=
      residual_source$residual_correlation_eigenvalues,
    residual_correlation_condition_number=
      residual_source$residual_correlation_condition_number,
    residual_correlation_boundary_fit=
      residual_source$residual_correlation_boundary_fit,
    residual_correlation_independence_limit_fit=
      residual_source$residual_correlation_independence_limit_fit,
    residual_correlation_optimizer_bounds=
      residual_source$residual_correlation_optimizer_bounds,
    residual_correlation_grid_regular=
      residual_source$residual_correlation_grid_regular,
    residual_correlation_grid_interval=
      residual_source$residual_correlation_grid_interval,
    residual_correlation_parameter_unit=
      residual_source$residual_correlation_parameter_unit,
    residual_correlation_outside_python_optimizer_bounds=
      residual_source$residual_correlation_outside_python_optimizer_bounds,
    whitened_residual_functions=
      residual_source$whitened_residual_functions,
    fitted_functions=predicted,residual_functions=resid,
    observed_functions=base$observed_functions,
    fixed_long_design=X,random_long_design=Zp,
    trial_random_long_design=Zt,scalar_design=base$scalar_design,
    n_participants=base$n_participants,n_curves=nc,n_time=nt,
    spline_degree=base$spline_degree,reml=reml,
    maxiter=as.integer(maxiter),fitted_model=fit,
    provenance=list(scientific_scope=
      "joint_participant_intercept_slope_nested_trial_bspline",
      one_curve_per_trial=TRUE,trial_dependence_preserved=TRUE,
      random_slope_supported=TRUE,residual_correlation=residual_correlation,
      preliminary_identifiability_fit="batch36_iid_random_slope",
      independent_full_domain_certified=FALSE)),
    class=c("etr_joint_bspline_mixed_nested_slope","etr_joint_bspline_mixed"))
}
