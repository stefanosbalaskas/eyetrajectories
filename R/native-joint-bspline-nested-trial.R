# Bounded native joint Gaussian functional mixed-effects model with participant
# and nested trial B-spline random intercept functions.
# Frozen scientific source: eyetrajectoriespy 1.2.0,
# functional_mixed_effects_nested.py @ c1cd95ad718327550f7e55393ff38582872f7a94.
# Different R optimizer and output representation; not full Python parity.

.etr_nested_trial_structure <- function(trajectories, participant_column,
    trial_column) {
  .etr_assert(is.character(trial_column) && length(trial_column) == 1L &&
      !is.na(trial_column) && nzchar(trial_column) &&
      !identical(trial_column, participant_column) &&
      trial_column %in% names(trajectories$metadata),
    "trial_column must identify a distinct metadata field")
  pid <- as.character(trajectories$metadata[[participant_column]])
  tid <- as.character(trajectories$metadata[[trial_column]])
  .etr_assert(length(tid) == length(trajectories$curve_ids) &&
      !anyNA(pid) && !anyNA(tid) && all(nzchar(pid)) && all(nzchar(tid)),
    "participant and trial identifiers must be complete and nonempty")
  # Python 0.48/0.49 requires one source curve per (participant, trial).
  composite <- paste(nchar(pid), pid, nchar(tid), tid, sep = ":")
  .etr_assert(!anyDuplicated(composite),
    "trial identifiers must be unique within each participant (one curve per trial)")
  groups <- unique(pid)
  .etr_assert(all(tabulate(match(pid,groups)) >= 2L),
    "each participant must contain at least two independent trials")
  list(participant=pid,trial=tid,composite=composite,participant_ids=groups)
}

.etr_nested_trial_covariance <- function(fit, name, n_expected, sigma2) {
  re <- fit$modelStruct$reStruct
  .etr_assert(name %in% names(re),
    paste("fitted model is missing nested covariance group",name))
  G <- as.matrix(nlme::pdMatrix(re[[name]]))*sigma2
  .etr_assert(is.matrix(G) && identical(dim(G),c(n_expected,n_expected)) &&
      all(is.finite(G)) && max(abs(G-t(G))) < 1e-7 &&
      min(eigen(G,symmetric=TRUE,only.values=TRUE)$values) > -1e-8,
    paste("invalid estimated random-effect covariance for",name))
  G
}

#' Native joint functional mixed-effects model with nested trial random effects
#'
#' Fits one Gaussian joint B-spline model with unstructured participant and
#' trial random-intercept coefficient covariances. Each trial is one source
#' trajectory, nested within a participant. Independent, discrete AR(1), or
#' physical-time exponential residual correlation is estimated separately
#' within each trial. This is a bounded native nlme scientific analogue of
#' the frozen Python 1.2 nested functional mixed-effects estimator, not a
#' complete cross-language source contract.
#'
#' @param trajectories Complete finite common-grid trajectory collection.
#' @param design One data.frame row per source curve with unique curve_id.
#' @param predictors Numeric fixed-effect predictor names; character(0) allowed.
#' @param participant_column Metadata field identifying participant groups.
#' @param trial_column Distinct metadata field identifying trials within group.
#' @param dimension Name of exactly one response channel.
#' @param residual_correlation One of "iid", "ar1", "exponential". AR(1)
#'   requires a regular time grid; exponential uses physical-time distances.
#' @param fixed_basis_size Number of fixed-effect B-spline basis functions.
#' @param random_basis_size Number of participant random basis functions.
#' @param trial_random_basis_size Number of nested trial random basis functions.
#' @param spline_degree B-spline degree from 1 to 5.
#' @param reml Use REML if TRUE, maximum likelihood otherwise.
#' @param maxiter Optimizer iteration limit (>=10).
#' @return S3 object inheriting etr_joint_bspline_mixed, with fixed functions,
#'   participant/trial random coefficient covariance matrices, BLUP functions,
#'   predicted and residual functions, serial correlation, and nlme model.
#' @export
etr_fit_joint_bspline_functional_nested_trial <- function(
    trajectories,design,predictors,participant_column,trial_column,dimension,
    residual_correlation="iid",fixed_basis_size=6L,random_basis_size=4L,
    trial_random_basis_size=3L,spline_degree=3L,reml=TRUE,maxiter=500L) {
  if (!requireNamespace("nlme",quietly=TRUE))
    stop("The optional R package 'nlme' is required",call.=FALSE)
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(is.character(participant_column) &&
      length(participant_column)==1L && !is.na(participant_column) &&
      participant_column %in% names(trajectories$metadata),
    "participant_column must be present in trajectory metadata")
  trial <- .etr_nested_trial_structure(trajectories,participant_column,trial_column)
  .etr_assert(is.character(residual_correlation) &&
      length(residual_correlation)==1L && !is.na(residual_correlation) &&
      residual_correlation %in% c("iid","ar1","exponential"),
    "residual_correlation must be 'iid', 'ar1', or 'exponential'")
  .etr_assert(is.numeric(trial_random_basis_size) &&
      length(trial_random_basis_size)==1L &&
      is.finite(trial_random_basis_size) &&
      trial_random_basis_size == floor(trial_random_basis_size) &&
      trial_random_basis_size>=spline_degree+1L &&
      trial_random_basis_size<=length(trajectories$time),
    "trial_random_basis_size must be an integer between degree+1 and grid size")
  serial <- if (identical(residual_correlation,"iid")) NULL else
    .etr_joint_serial_grid(trajectories$time,residual_correlation)
  # Batch35 is a checked baseline design builder. Its independent fit is not
  # substituted for the nested likelihood fit below.
  base <- etr_fit_joint_bspline_functional_mixed_effects(
    trajectories=trajectories,design=design,predictors=predictors,
    participant_column=participant_column,dimension=dimension,
    fixed_basis_size=fixed_basis_size,random_basis_size=random_basis_size,
    spline_degree=spline_degree,reml=reml,maxiter=maxiter)
  .etr_assert(identical(base$curve_participant_ids,trial$participant),
    "participant/trajectory alignment changed after baseline validation")
  nc <- base$n_curves; nt <- base$n_time; nr <- ncol(base$random_basis)
  ntr <- as.integer(trial_random_basis_size)
  .etr_assert(length(unique(trial$composite)) > ntr*(ntr+1)/2,
    "number of nested trials must exceed trial covariance parameter count")
  trial_basis <- .etr_joint_bspline_basis(base$time,ntr,as.integer(spline_degree))
  X <- base$fixed_long_design
  Zp <- base$random_long_design
  fixed_names <- colnames(X)
  participant_names <- colnames(Zp)
  trial_names <- paste0(".etr_tr",seq_len(ntr))
  Zt <- matrix(NA_real_,nc*nt,ntr,dimnames=list(NULL,trial_names))
  for (k in seq_len(ntr)) Zt[,k] <- rep(trial_basis[,k],nc)
  .etr_assert(qr(Zt)$rank == ntr,"nested trial B-spline design is rank deficient")
  dat <- data.frame(.etr_y=as.vector(t(base$observed_functions)),
    .etr_pid=factor(rep(trial$participant,each=nt),levels=trial$participant_ids),
    .etr_trial=factor(rep(trial$trial,each=nt),levels=unique(trial$trial)),
    .etr_time_index=rep(seq_len(nt),nc))
  if (!is.null(serial)) dat$.etr_time_scaled <- rep(serial$scaled,nc)
  for (k in seq_along(fixed_names)) dat[[fixed_names[k]]] <- X[,k]
  for (k in seq_along(participant_names)) dat[[participant_names[k]]] <- Zp[,k]
  for (k in seq_along(trial_names)) dat[[trial_names[k]]] <- Zt[,k]
  ff <- stats::reformulate(fixed_names,response=".etr_y",intercept=FALSE)
  pp <- stats::reformulate(participant_names,intercept=FALSE)
  tt <- stats::reformulate(trial_names,intercept=FALSE)
  corr <- switch(residual_correlation,
    iid=NULL,
    ar1=nlme::corAR1(value=.2,form=~.etr_time_index|.etr_pid/.etr_trial),
    exponential=nlme::corCAR1(value=.5,form=~.etr_time_scaled|.etr_pid/.etr_trial))
  fitted <- tryCatch(
    nlme::lme(fixed=ff,random=list(.etr_pid=nlme::pdSymm(pp),
        .etr_trial=nlme::pdSymm(tt)),correlation=corr,data=dat,
      method=if(reml) "REML" else "ML",
      control=nlme::lmeControl(maxIter=as.integer(maxiter),
        msMaxIter=as.integer(maxiter),returnObject=FALSE)),
    error=function(e) stop(paste("nested joint functional model failed:",
      conditionMessage(e)),call.=FALSE))
  fixed <- nlme::fixef(fitted)
  .etr_assert(all(fixed_names%in%names(fixed)),
    "fitted nested model omitted fixed B-spline coefficients")
  nf <- ncol(base$fixed_basis)
  nb <- length(base$predictor_names)
  beta <- matrix(as.numeric(fixed[fixed_names]),nb,nf,byrow=TRUE,
    dimnames=list(base$predictor_names,NULL))
  coefficient_functions <- beta%*%t(base$fixed_basis)
  dimnames(coefficient_functions) <- list(base$predictor_names,NULL)
  vc <- as.matrix(stats::vcov(fitted))
  .etr_assert(all(fixed_names%in%rownames(vc)) &&
    all(fixed_names%in%colnames(vc)),
    "fixed parameter covariance does not contain requested splines")
  vc <- vc[fixed_names,fixed_names,drop=FALSE]
  se <- matrix(NA_real_,nb,nt,dimnames=list(base$predictor_names,NULL))
  for (j in seq_len(nb)) {
    ii <- (j-1L)*nf+seq_len(nf)
    se[j,] <- sqrt(pmax(0,rowSums((base$fixed_basis%*%
      vc[ii,ii,drop=FALSE])*base$fixed_basis)))
  }
  sigma2 <- as.numeric(fitted$sigma)^2
  .etr_assert(is.finite(sigma2) && sigma2>0,
    "nested model residual variance is not positive finite")
  Gp <- .etr_nested_trial_covariance(fitted,".etr_pid",nr,sigma2)
  Gt <- .etr_nested_trial_covariance(fitted,".etr_trial",ntr,sigma2)
  if (identical(residual_correlation,"iid")) {
    parameter <- NA_real_;parameter_name <- NA_character_
    parameter_unit <- NA_character_;C <- diag(nt)
  } else {
    rho <- as.numeric(stats::coef(fitted$modelStruct$corStruct,
      unconstrained=FALSE))
    .etr_assert(length(rho)==1L && is.finite(rho),
      "nested residual correlation parameter invalid")
    if (identical(residual_correlation,"ar1")) {
      .etr_assert(abs(rho)<1,"AR(1) rho must be within (-1,1)")
      parameter <- rho;parameter_name <- "rho";parameter_unit <- "index_step"
    } else {
      .etr_assert(rho>0 && rho<1,
        "continuous correlation parameter must lie in (0,1)")
      parameter <- -serial$scale/log(rho)
      parameter_name <- "phi";parameter_unit <- trajectories$time_unit
    }
    C <- .etr_joint_serial_correlation_matrix(base$time,
      residual_correlation,parameter)
  }
  # Independent Gaussian conditional expectation for two nested random levels.
  # Each participant's marginal V is assembled from separately estimated Gp,
  # Gt, residual C; blockwise Cholesky avoids global dense inversion.
  gpcoef <- matrix(NA_real_,length(trial$participant_ids),nr,
    dimnames=list(trial$participant_ids,participant_names))
  gtcoef <- matrix(NA_real_,nc,ntr,
    dimnames=list(base$curve_ids,trial_names))
  beta_vector <- as.numeric(fixed[fixed_names])
  for (g in seq_along(trial$participant_ids)) {
    ci <- which(trial$participant==trial$participant_ids[g]);m <- length(ci)
    rowid <- as.vector(t(outer(ci-1L,seq_len(nt),function(i,j) i*nt+j)))
    # rowid is curve-major, matching R's long design and response vector.
    zg <- Zp[rowid,,drop=FALSE]
    E <- dat$.etr_y[rowid] - as.vector(X[rowid,,drop=FALSE]%*%beta_vector)
    V <- zg%*%Gp%*%t(zg)
    for (h in seq_along(ci)) {
      rr <- (h-1L)*nt+seq_len(nt)
      Zth <- Zt[(ci[h]-1L)*nt+seq_len(nt),,drop=FALSE]
      V[rr,rr] <- V[rr,rr] + Zth%*%Gt%*%t(Zth) + sigma2*C
    }
    .etr_assert(all(is.finite(V)) && max(abs(V-t(V))) < 1e-7,
      "nested participant covariance assembly failed")
    factor <- tryCatch(chol(V),error=function(e) NULL)
    .etr_assert(!is.null(factor),
      "nested marginal covariance is not positive definite")
    w <- backsolve(factor,forwardsolve(t(factor),E))
    gpcoef[g,] <- as.vector(Gp%*%crossprod(zg,w))
    for (h in seq_along(ci)) {
      rr <- (h-1L)*nt+seq_len(nt)
      Zth <- Zt[(ci[h]-1L)*nt+seq_len(nt),,drop=FALSE]
      gtcoef[ci[h],] <- as.vector(Gt%*%crossprod(Zth,w[rr]))
    }
  }
  gpfun <- gpcoef%*%t(base$random_basis)
  gtf <- gtcoef%*%t(trial_basis)
  grp <- match(trial$participant,trial$participant_ids)
  predicted <- base$scalar_design%*%coefficient_functions +
    gpfun[grp,,drop=FALSE]+gtf
  resid <- base$observed_functions - predicted
  .etr_assert(all(is.finite(predicted)) && all(is.finite(se)) &&
    all(se>=0),"nested mixed-model predictions or SEs are invalid")
  structure(list(
    method=if(reml) "joint_nested_bspline_REML" else "joint_nested_bspline_ML",
    estimator=paste0("nlme_nested_participant_trial_bspline_",residual_correlation),
    backend="nlme::lme",source_python_full_parity=FALSE,
    dimension=dimension,time=base$time,curve_ids=base$curve_ids,
    participant_ids=trial$participant_ids,
    curve_participant_ids=trial$participant,source_trial_ids=trial$trial,
    composite_trial_ids=trial$composite,
    predictor_names=base$predictor_names,
    fixed_basis=base$fixed_basis,random_basis=base$random_basis,
    trial_random_basis=trial_basis,
    fixed_basis_coefficients=beta,
    fixed_coefficient_functions=coefficient_functions,
    fixed_standard_errors=se,fixed_parameter_covariance=vc,
    participant_random_effect_coefficients=gpcoef,
    trial_random_effect_coefficients=gtcoef,
    participant_random_effect_functions=gpfun,
    trial_random_effect_functions=gtf,
    random_effect_covariance=Gp,
    trial_random_effect_covariance=Gt,
    residual_variance=sigma2,
    residual_correlation=residual_correlation,
    residual_correlation_parameter=parameter,
    residual_correlation_parameter_name=parameter_name,
    residual_correlation_parameter_units=parameter_unit,
    residual_correlation_matrix=C,
    fitted_functions=predicted,residual_functions=resid,
    observed_functions=base$observed_functions,
    fixed_long_design=X,random_long_design=Zp,
    trial_random_long_design=Zt,scalar_design=base$scalar_design,
    n_participants=base$n_participants,n_curves=nc,n_time=nt,
    spline_degree=base$spline_degree,reml=reml,fitted_model=fitted,
    provenance=list(scientific_scope="joint_participant_and_nested_trial_bspline",
      one_curve_per_trial=TRUE,trial_dependence_preserved=TRUE,
      random_slope_supported=FALSE,
      independent_full_domain_certified=FALSE)),
    class=c("etr_joint_bspline_mixed_nested_trial","etr_joint_bspline_mixed"))
}
