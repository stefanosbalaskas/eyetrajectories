# Source pin: eyetrajectoriespy 1.2.0 generalized_function_on_scalar.py
# and functional_mixed_effects.py at c1cd95ad718327550f7e55393ff38582872f7a94.
# Explicit working independence GEE with participant-cluster robust sandwich.
# Base-R glm.fit solves the canonical score equation; Python uses statsmodels.
# Full accepted domains/backend-warning schema not independently certified.

.etr_native_generalized_response_array<-function(values,n,nt,name,
    positive=FALSE,integer=FALSE){
  if(is.null(values))return(NULL)
  if(is.numeric(values)&&is.null(dim(values))&&length(values)==n)
    values<-matrix(rep(values,each=nt),nrow=n,byrow=TRUE)
  .etr_assert(is.matrix(values)&&is.numeric(values)&&
    identical(dim(values),c(n,nt))&&all(is.finite(values)),
    paste0(name," must be a finite n_curves-by-n_time matrix or curve vector"))
  if(positive).etr_assert(all(values>0),paste(name,"must be strictly positive"))
  if(integer).etr_assert(all(values==round(values)),
    paste(name,"must contain integer values"))
  values
}

.etr_native_generalized_basis<-function(time,n_basis,degree){
  .etr_assert(is.numeric(n_basis)&&length(n_basis)==1L&&
    is.finite(n_basis)&&n_basis==floor(n_basis)&&n_basis>=1,
    "basis_size must be a positive integer")
  .etr_assert(is.numeric(degree)&&length(degree)==1L&&
    is.finite(degree)&&degree==floor(degree)&&degree>=0,
    "spline_degree must be a nonnegative integer")
  .etr_assert(n_basis>=degree+1L,
    "basis_size must be at least spline_degree + 1")
  inside<-as.integer(n_basis-degree-1L)
  knots<-c(rep(time[1L],degree+1L),
    if(inside>0L)seq(time[1L],tail(time,1L),
      length.out=inside+2L)[-c(1L,inside+2L)],
    rep(tail(time,1L),degree+1L))
  basis<-splines::splineDesign(knots,time,ord=degree+1L,
    outer.ok=TRUE)
  basis[nrow(basis),]<-0
  basis[nrow(basis),ncol(basis)]<-1
  .etr_assert(ncol(basis)==n_basis&&qr(basis)$rank==n_basis,
    "generalized function-on-scalar basis rank deficient")
  list(basis=unname(basis),knots=knots)
}

#' Fit explicit native participant-clustered generalized function-on-scalar GEE
#' @param trajectories Complete common-grid native trajectories.
#' @param design One unique curve_id per source trajectory, numeric predictors.
#' @param predictors Declared numeric predictors without automatic encoding.
#' @param participant_column Metadata field naming independent participants.
#' @param dimension Response channel.
#' @param family Exactly "binomial" or "poisson".
#' @param binomial_denominator Optional positive integer trials per curve/time.
#' @param exposure Optional strictly positive Poisson exposure per curve/time.
#' @param exposure_units User-declared exposure units, only with exposure.
#' @param basis_size,spline_degree Fixed clamped B-spline specification.
#' @param working_correlation Exactly "independence"; no implicit selection.
#' @param covariance_type Exactly "robust" participant-cluster sandwich.
#' @param maxiter,ctol GLM iteration and convergence tolerance.
#' @return Native GEE model record and audited source scientific quantities.
#' @export
etr_fit_generalized_function_on_scalar_regression<-function(
    trajectories,design,predictors,participant_column,dimension,family,
    binomial_denominator=NULL,exposure=NULL,exposure_units=NULL,
    basis_size=5L,spline_degree=3L,working_correlation="independence",
    covariance_type="robust",maxiter=100L,ctol=1e-8){
  etr_validate(trajectories,require_complete=TRUE)
  .etr_assert(all(is.finite(trajectories$values))&&
    trajectories$coordinate_system!="probability_simplex",
    "generalized function-on-scalar requires complete finite non-simplex data")
  .etr_assert(identical(working_correlation,"independence")&&
    identical(covariance_type,"robust"),
    "only independence working correlation and robust covariance supported")
  .etr_assert(is.numeric(maxiter)&&length(maxiter)==1L&&
    is.finite(maxiter)&&maxiter==floor(maxiter)&&maxiter>=1L,
    "maxiter must be positive integer")
  .etr_assert(is.numeric(ctol)&&length(ctol)==1L&&
    is.finite(ctol)&&ctol>0,
    "ctol must be finite positive")
  .etr_assert(is.character(family)&&length(family)==1L&&
    !is.na(family)&&family%in%c("binomial","poisson"),
    "family must explicitly be binomial or poisson")
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    !is.na(dimension)&&dimension%in%trajectories$dimension_names,
    "dimension must be one known response channel")
  .etr_assert(is.data.frame(design)&&"curve_id"%in%names(design)&&
    !anyNA(design$curve_id)&&!anyDuplicated(design$curve_id)&&
    nrow(design)==length(trajectories$curve_ids),
    "design must contain one unique source curve_id per curve")
  aligned<-match(trajectories$curve_ids,as.character(design$curve_id))
  .etr_assert(!anyNA(aligned),"design is missing source curve IDs")
  .etr_assert(is.character(predictors)&&length(predictors)>=1L&&
    !anyNA(predictors)&&all(nzchar(predictors))&&
    !anyDuplicated(predictors)&&
    all(predictors%in%names(design))&&!any(predictors=="curve_id"),
    "predictors must be unique declared design columns")
  X<-cbind(Intercept=1,
    as.matrix(design[aligned,predictors,drop=FALSE]))
  .etr_assert(is.numeric(X)&&all(is.finite(X)),
    "predictors must be complete finite numeric")
  colnames(X)<-c("Intercept",predictors)
  .etr_assert(qr(X)$rank==ncol(X),
    "scalar design matrix rank deficient")
  n<-nrow(X);nt<-length(trajectories$time)
  y<-matrix(trajectories$values[,,match(dimension,
    trajectories$dimension_names),drop=FALSE],nrow=n,ncol=nt)
  .etr_assert(is.character(participant_column)&&
    length(participant_column)==1L&&!is.na(participant_column)&&
    participant_column%in%names(trajectories$metadata),
    "participant_column must be in source metadata")
  groups<-as.character(trajectories$metadata[[participant_column]])
  .etr_assert(!anyNA(groups)&&all(nzchar(groups)),
    "participant identifiers must be complete")
  participants<-unique(groups);np<-length(participants)
  basis_data<-.etr_native_generalized_basis(trajectories$time,
    basis_size,spline_degree)
  basis<-basis_data$basis;K<-ncol(basis);p<-ncol(X)
  .etr_assert(np>p*K,
    "participant count must exceed expanded coefficient parameter count")
  .etr_assert(n*nt>=p*K,"expanded design cannot be estimated")
  den<-.etr_native_generalized_response_array(
    binomial_denominator,n,nt,"binomial_denominator",
    positive=TRUE,integer=TRUE)
  exp<-.etr_native_generalized_response_array(
    exposure,n,nt,"exposure",positive=TRUE)
  .etr_assert((family=="binomial"&&is.null(exp))||
    (family=="poisson"&&is.null(den)),
    "binomial denominator and Poisson exposure must match declared family")
  .etr_assert(is.null(exposure_units)||
    (is.character(exposure_units)&&length(exposure_units)==1L&&
      !is.na(exposure_units)&&nzchar(trimws(exposure_units))&&
      !is.null(exp)),
    "exposure_units requires explicit Poisson exposure")
  if(family=="binomial"){
    if(is.null(den)){
      .etr_assert(all(y%in%c(0,1)),
        "Bernoulli outcomes must be exactly zero or one")
      observed<-y
      w<-rep(1,n*nt)
    }else{
      .etr_assert(all(y>=0)&all(y==round(y))&&all(y<=den),
        "grouped binomial successes must be integer counts within denominator")
      observed<-y/den
      w<-as.vector(t(den))
    }
    family_object<-stats::binomial(link="logit")
  }else{
    .etr_assert(all(y>=0)&all(abs(y-round(y))<=1e-12),
      "Poisson outcomes must be nonnegative integer counts")
    observed<-y;w<-rep(1,n*nt)
    family_object<-stats::poisson(link="log")
  }
  nrows<-n*nt
  expanded<-matrix(0,nrows,p*K)
  for(i in seq_len(n))for(j in seq_len(p)){
    rows<-seq.int((i-1L)*nt+1L,length.out=nt)
    cols<-seq.int((j-1L)*K+1L,length.out=K)
    expanded[rows,cols]<-X[i,j]*basis
  }
  .etr_assert(qr(expanded)$rank==ncol(expanded),
    "expanded GEE spline design rank deficient")
  outcome<-as.vector(t(observed))
  offset<-if(is.null(exp))rep(0,nrows)else
    as.vector(t(log(exp)))
  glm<-suppressWarnings(stats::glm.fit(x=expanded,y=outcome,
    weights=w,offset=offset,family=family_object,
    control=stats::glm.control(epsilon=ctol,maxit=as.integer(maxiter))))
  .etr_assert(isTRUE(glm$converged)&&!anyNA(glm$coefficients)&&
    all(is.finite(glm$coefficients)),
    "independence GEE did not converge or yielded nonfinite coefficients")
  beta<-as.numeric(glm$coefficients)
  eta<-as.vector(expanded%*%beta)+offset
  mu<-as.numeric(family_object$linkinv(eta))
  .etr_assert(all(is.finite(mu)),
    "fitted generalized marginal means must be finite")
  variance_weights<-if(family=="binomial")
    w*mu*(1-mu) else mu
  bread<-crossprod(expanded,expanded*variance_weights)
  .etr_assert(qr(bread)$rank==ncol(expanded),
    "GEE robust information matrix is rank deficient")
  inverse<-solve(bread)
  residual_score<-if(family=="binomial")
    w*(outcome-mu) else outcome-mu
  cluster<-rep(match(groups,participants),each=nt)
  meat<-matrix(0,p*K,p*K)
  for(g in seq_len(np)){
    ix<-which(cluster==g)
    score<-crossprod(expanded[ix,,drop=FALSE],residual_score[ix])
    meat<-meat+tcrossprod(score)
  }
  covariance<-inverse%*%meat%*%inverse
  covariance<-(covariance+t(covariance))/2
  bcoef<-matrix(beta,nrow=p,ncol=K,byrow=TRUE)
  coef_fun<-bcoef%*%t(basis)
  se<-matrix(0,p,nt)
  for(i in seq_len(p)){
    ix<-seq.int((i-1L)*K+1L,length.out=K)
    V<-covariance[ix,ix,drop=FALSE]
    se[i,]<-sqrt(pmax(0,rowSums((basis%*%V)*basis)))
  }
  rate_eta<-X%*%coef_fun
  count_eta<-rate_eta+matrix(offset,nrow=n,byrow=TRUE)
  fitted_mean<-matrix(mu,nrow=n,byrow=TRUE)
  prov<-list(operation="fit_generalized_function_on_scalar_regression",
    method="marginal_function_on_scalar_gee",
    native_solver="base_R_glm_fit_cluster_robust_sandwich",
    source_solver="statsmodels_GEE",
    family=family,link=if(family=="binomial")"logit"else"log",
    working_correlation="independence",covariance="participant_robust",
    participants_as_independent_clusters=TRUE,
    basis_selected_automatically=FALSE,preprocessing=FALSE,
    categorical_encoding=FALSE,
    binomial_denominator_fixed=!is.null(den),
    poisson_exposure_fixed=!is.null(exp),
    full_source_contract_certified=FALSE)
  structure(list(
    coefficient_functions=coef_fun,
    coefficient_standard_errors=se,
    basis_coefficients=bcoef,parameter_covariance=covariance,
    basis=basis,basis_knots=basis_data$knots,
    linear_predictor_functions=rate_eta,
    linear_predictor_rate=if(is.null(exp))NULL else rate_eta,
    linear_predictor_count=if(family=="poisson")count_eta else NULL,
    mean_functions=fitted_mean,observed_functions=y,
    scalar_design_matrix=X,
    expanded_design_rank=qr(expanded)$rank,
    coefficient_names=colnames(X),predictor_names=predictors,
    participant_column=participant_column,participant_ids=participants,
    curve_participant_ids=groups,
    curves_per_participant=as.integer(tabulate(cluster[seq(1L,nrows,by=nt)],
      nbins=np)),
    source_curve_ids=trajectories$curve_ids,time=trajectories$time,
    dimension_name=dimension,coordinate_system=trajectories$coordinate_system,
    time_unit=trajectories$time_unit,
    family=family,link=if(family=="binomial")"logit"else"log",
    basis_size=as.integer(K),spline_degree=as.integer(spline_degree),
    working_correlation="independence",covariance_type="robust",
    scale=1,maxiter=as.integer(maxiter),ctol=ctol,converged=TRUE,
    backend_warnings=character(),
    exposure=exp,log_exposure=if(is.null(exp))NULL else log(exp),
    rate_functions=if(is.null(exp))NULL else exp(rate_eta),
    exposure_units=exposure_units,
    exposure_expanded_from_curve=
      !is.null(exp)&&is.null(dim(exposure)),
    binomial_successes=if(is.null(den))NULL else y,
    binomial_denominators=den,
    binomial_observed_proportions=if(is.null(den))NULL else observed,
    binomial_expected_successes=if(is.null(den))NULL else mu*den,
    binomial_denominator_expanded_from_curve=
      !is.null(den)&&is.null(dim(binomial_denominator)),
    provenance=prov),class="etr_generalized_function_on_scalar")
}
