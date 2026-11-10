# Native whole-participant *likelihood* full-refit bootstrap.
# Source scientific algorithm: frozen eyetrajectoriespy 1.2
# functional_mixed_effects_full_refit.py.
#
# This is deliberately restricted to the participant-intercept iid
# unstructured B-spline covariance model supported by nlme. On every draw,
# the Gaussian ML/REML optimizer refits fixed effects, participant random
# covariance and residual variance. No timewise moments substitute is used.
# Python statsmodels optimizer and exact typed return parity are NOT asserted.

.etr_joint_likelihood_full_refit_bootstrap<-function(
    result,n_bootstrap=1000L,random_state=0L,
    sampled_participant_indices=NULL){
  if(inherits(result,"etr_joint_bspline_mixed_correlated")||
      inherits(result,"etr_joint_bspline_mixed_slope")||
      inherits(result,"etr_joint_bspline_mixed_nested_trial")||
      inherits(result,"etr_joint_bspline_mixed_nested_slope"))
    return(.etr_joint_structured_full_refit_bootstrap(
      result,n_bootstrap,random_state,sampled_participant_indices))
  .etr_assert(inherits(result,"etr_joint_bspline_mixed")&&
    inherits(result$fitted_model,"lme"),
    "full-refit bootstrap requires a converged joint spline likelihood model")
  .etr_assert(!inherits(result,"etr_joint_bspline_mixed_slope")&&
    is.null(result[["trial_random_effect",exact=TRUE]])&&
    (is.null(result[["residual_correlation",exact=TRUE]])||
      identical(result[["residual_correlation",exact=TRUE]],"iid"))&&
    identical(result$backend,"nlme::lme"),
    "native joint full-refit supports only iid participant random-intercept likelihood; serial, slope and nested-trial variants require separate source-qualified refitters")
  .etr_assert(is.numeric(n_bootstrap)&&length(n_bootstrap)==1L&&
    !is.logical(n_bootstrap)&&is.finite(n_bootstrap)&&
    n_bootstrap==floor(n_bootstrap)&&n_bootstrap>=20L&&
    n_bootstrap<=.Machine$integer.max,
    "n_bootstrap must be an integer >=20 for full-refit diagnostics")
  .etr_assert(is.null(random_state)||
    (is.numeric(random_state)&&length(random_state)==1L&&
    !is.logical(random_state)&&is.finite(random_state)&&
    random_state==floor(random_state)&&
    random_state>=0L&&random_state<=.Machine$integer.max),
    "random_state must be NULL or a supported nonnegative integer")
  ids<-as.character(result$participant_ids)
  members<-as.character(result$curve_participant_ids)
  N<-length(ids);B<-as.integer(n_bootstrap)
  n<-nrow(result$observed_functions);nt<-length(result$time)
  nf<-ncol(result$fixed_basis);nr<-ncol(result$random_basis)
  p<-nrow(result$fixed_basis_coefficients)
  .etr_assert(N>=4L&&!anyDuplicated(ids)&&
    length(members)==n&&all(members%in%ids)&&
    is.matrix(result$observed_functions)&&
    identical(dim(result$observed_functions),c(n,nt))&&
    all(is.finite(result$observed_functions))&&
    is.matrix(result$scalar_design)&&
    identical(dim(result$scalar_design),c(n,p))&&
    all(is.finite(result$scalar_design)),
    "reference participant and fixed-spline geometry are incomplete")
  .etr_assert(identical(result$spline_degree,
    as.integer(result$spline_degree))&&
    is.logical(result$reml)&&length(result$reml)==1L,
    "reference B-spline degree or likelihood method is incomplete")
  original_participants<-lapply(ids,function(id)
    which(members==id))
  .etr_assert(all(lengths(original_participants)>0L),
    "every source participant must contribute a curve bundle")
  if(is.null(sampled_participant_indices)){
    sampled<-if(is.null(random_state))
      matrix(sample.int(N,B*N,replace=TRUE)-1L,nrow=B,ncol=N) else
      .etr_numpy_seeded_case_indices(random_state,B,N)
  }else{
    sampled<-sampled_participant_indices
    .etr_assert(is.matrix(sampled)&&is.numeric(sampled)&&
      identical(dim(sampled),c(B,N))&&
      all(is.finite(sampled))&&
      all(sampled==floor(sampled))&&
      all(sampled>=0L)&&all(sampled<N),
      "sampled_participant_indices must be finite zero-based B-by-participant indices")
    sampled<-matrix(as.integer(sampled),nrow=B,ncol=N)
  }
  beta<-array(NA_real_,c(B,p,nf))
  coeff<-array(NA_real_,c(B,p,nt))
  covs<-array(NA_real_,c(B,nr,nr))
  eig<-matrix(NA_real_,B,nr)
  condition<-numeric(B)
  boundary<-logical(B)
  singular<-logical(B)
  variance<-numeric(B)
  loglik<-numeric(B)
  audits<-vector("list",B)
  bootstrap_ids<-vector("list",B)
  warnings<-vector("list",B)
  predictor_names<-as.character(result$predictor_names)[-1L]
  .etr_assert(length(predictor_names)==p-1L,
    "reference fitted coefficient names do not match the scalar design")
  for(b in seq_len(B)){
    sampled_source<-sampled[b,]+1L
    rows<-unlist(original_participants[sampled_source],use.names=FALSE)
    occurrences<-lengths(original_participants[sampled_source])
    labels<-sprintf("bootstrap_%04d_draw_%04d",
      b-1L,seq_len(N)-1L)
    new_curve_ids<-sprintf("b%04d_curve_%05d",
      b-1L,seq_along(rows)-1L)
    audits[[b]]<-ids[sampled_source]
    bootstrap_ids[[b]]<-labels
    source_y<-result$observed_functions[rows,,drop=FALSE]
    dat<-etr_trajectory_set(result$time,
      array(as.numeric(source_y),dim=c(length(rows),nt,1L)),
      new_curve_ids,as.character(result$dimension_name),
      metadata=data.frame(.etr_bootstrap_pid=
        rep(labels,times=occurrences)),
      coordinate_system=if(is.null(result$coordinate_system))
        "unknown" else result$coordinate_system,
      time_unit=result$time_unit)
    design<-data.frame(curve_id=new_curve_ids,
      stringsAsFactors=FALSE)
    if(length(predictor_names))for(j in seq_along(predictor_names))
      design[[predictor_names[[j]]]]<-
        result$scalar_design[rows,j+1L]
    backend_messages<-character()
    fit<-tryCatch(
      withCallingHandlers(
        etr_fit_joint_bspline_functional_mixed_effects(
          trajectories=dat,design=design,
          predictors=predictor_names,
          participant_column=".etr_bootstrap_pid",
          dimension=as.character(result$dimension_name),
          fixed_basis_size=nf,random_basis_size=nr,
          spline_degree=result$spline_degree,
          reml=result$reml,
          maxiter=if(is.null(result$maxiter))500L else
            result$maxiter),
        warning=function(w){
          backend_messages<<-c(backend_messages,conditionMessage(w))
          invokeRestart("muffleWarning")
        }),
      error=function(e)stop(sprintf(
        "full-refit participant bootstrap replicate %d failed; no replicate was silently discarded or redrawn: %s",
        b,conditionMessage(e)),call.=FALSE))
    beta[b,,]<-fit$fixed_basis_coefficients
    coeff[b,,]<-fit$fixed_coefficient_functions
    covs[b,,]<-fit$random_effect_covariance
    eigenvalues<-eigen(fit$random_effect_covariance,
      symmetric=TRUE,only.values=TRUE)$values
    eig[b,]<-eigenvalues
    condition[b]<-if(min(abs(eigenvalues))>0)
      max(abs(eigenvalues))/min(abs(eigenvalues)) else Inf
    boundary[b]<-min(eigenvalues)<=
      1e-7*max(1,max(abs(eigenvalues)))
    singular[b]<-min(abs(eigenvalues))<=
      1e-10*max(1,max(abs(eigenvalues)))
    variance[b]<-fit$residual_variance
    loglik[b]<-as.numeric(stats::logLik(fit$fitted_model))
    warnings[[b]]<-unique(backend_messages)
  }
  mean<-matrix(apply(coeff,c(2L,3L),mean),nrow=p,ncol=nt)
  se<-matrix(apply(coeff,c(2L,3L),stats::sd),nrow=p,ncol=nt)
  .etr_assert(all(is.finite(mean))&&all(is.finite(se))&&
    all(is.finite(variance))&&all(is.finite(loglik)),
    "full-refit likelihood bootstrap returned nonfinite diagnostics")
  prov<-result$provenance
  prov$functional_mixed_effects_full_refit_bootstrap<-list(
    method="participant_cluster_case_bootstrap_full_ml_reml_refit",
    n_bootstrap=B,
    random_state=if(is.null(random_state))NULL else
      as.integer(random_state),
    native_rng=if(!is.null(sampled_participant_indices))
      "caller_supplied_fixed_indices" else if(is.null(random_state))
      "base_R_unseeded" else "numpy_pcg64",
    participant_groups_duplicated_as_independent_draws=TRUE,
    whole_trial_bundles_resampled=TRUE,
    fixed_basis_refit=FALSE,
    fixed_effect_coefficients_refit=TRUE,
    participant_random_effect_covariance_refit=TRUE,
    residual_variance_refit=TRUE,
    residual_correlation="iid",
    supported_native_scope="unstructured_participant_intercept_iid",
    optimizer="nlme::lme",
    python_statsmodels_optimizer_equivalent=FALSE,
    full_source_contract_certified=FALSE,
    independent_full_source_certified=FALSE)
  structure(list(
    reference=result,bootstrap_fixed_basis_coefficients=beta,
    bootstrap_coefficient_functions=coeff,
    sampled_participant_indices=sampled,
    sampled_source_participant_ids=audits,
    bootstrap_participant_ids=bootstrap_ids,
    bootstrap_mean=mean,bootstrap_standard_errors=se,
    random_effect_covariances=covs,
    random_intercept_covariances=covs,
    random_slope_covariances=NULL,
    random_intercept_slope_covariances=NULL,
    random_effect_covariance_eigenvalues=eig,
    random_effect_covariance_condition_numbers=condition,
    random_effect_boundary_flags=boundary,
    random_effect_singular_flags=singular,
    random_slope_boundary_flags=rep(FALSE,B),
    residual_variances=variance,
    log_likelihoods=loglik,
    convergence_flags=rep(TRUE,B),
    backend_warnings=warnings,
    bootstrap_trial_audit=vector("list",B),
    trial_random_effect_covariances=NULL,
    trial_random_effect_covariance_eigenvalues=NULL,
    trial_random_effect_covariance_condition_numbers=NULL,
    trial_random_effect_boundary_flags=NULL,
    trial_random_effect_singular_flags=NULL,
    residual_correlation_parameters=NULL,
    residual_correlation_boundary_flags=NULL,
    residual_correlation_independence_flags=NULL,
    residual_correlation_condition_numbers=NULL,
    random_state=if(is.null(random_state))NULL else
      as.integer(random_state),
    bootstrap_type="full_refit",
    failure_policy="raise",
    variance_components_refit=TRUE,
    provenance=prov,
    source_python_full_contract_certified=FALSE,
    independent_full_source_certified=FALSE),
    class=c("etr_joint_mixed_likelihood_full_refit_bootstrap",
      "etr_mixed_effects_full_refit_bootstrap"))
}
