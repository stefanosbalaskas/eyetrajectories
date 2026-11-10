# Whole-participant ML/REML likelihood refits across explicit R/nlme
# joint functional covariance structures. Frozen Python scientific reference:
# eyetrajectoriespy 1.2 functional_mixed_effects_full_refit.py, source
# c1cd95ad718327550f7e55393ff38582872f7a94.
#
# Only actual joint likelihood fits are supported. Every replicate rebuilds
# the source model specification, assigns *independent* identities to repeated
# participant draws, and refits all covariance parameters. No moments,
# fixed-covariance bootstrap, or alternate estimator is silently substituted.
# Numeric algorithms and optimizer differ from Python statsmodels; therefore
# this is author-side scientific implementation, not source certification.

.etr_joint_structured_refit_kind<-function(reference){
  if(inherits(reference,"etr_joint_bspline_mixed_nested_slope"))
    return("nested_slope")
  if(inherits(reference,"etr_joint_bspline_mixed_nested_trial"))
    return("nested_trial")
  if(inherits(reference,"etr_joint_bspline_mixed_slope"))
    return("slope")
  if(inherits(reference,"etr_joint_bspline_mixed_correlated"))
    return("serial")
  stop("structured bootstrap requires a supported joint likelihood subclass",
    call.=FALSE)
}

.etr_joint_structured_refit_solver<-function(kind,reference,trajectories,
    design,random_slope_predictor=NULL){
  predictors<-as.character(reference$predictor_names)[-1L]
  degree<-reference$spline_degree
  nf<-ncol(reference$fixed_basis)
  nr<-ncol(reference$random_basis)
  maxiter<-if(is.null(reference$maxiter))500L else
    as.integer(reference$maxiter)
  args<-list(trajectories=trajectories,design=design,
    predictors=predictors,participant_column=".etr_bootstrap_pid",
    dimension=reference$dimension_name,
    fixed_basis_size=nf,random_basis_size=nr,
    spline_degree=degree,reml=reference$reml,maxiter=maxiter)
  correlation<-reference[["residual_correlation",exact=TRUE]]
  if(is.null(correlation))correlation<-"iid"
  if(kind%in%c("slope","nested_slope")){
    .etr_assert(is.character(random_slope_predictor)&&
      length(random_slope_predictor)==1L&&
      random_slope_predictor%in%predictors,
      "structured likelihood bootstrap requires a declared random_slope_predictor")
    args$random_slope_predictor<-random_slope_predictor
  }
  if(kind%in%c("nested_trial","nested_slope")){
    .etr_assert(identical(reference$trial_random_effect,
      "functional_intercept")&&
      is.matrix(reference$trial_random_basis)&&
      ncol(reference$trial_random_basis)>=1L,
      "nested functional trial covariance reference is incomplete")
    args$trial_column<-".etr_bootstrap_trial"
    args$trial_random_basis_size<-ncol(reference$trial_random_basis)
  }
  if(kind!="slope")args$residual_correlation<-correlation
  fn<-switch(kind,
    slope=etr_fit_joint_bspline_functional_random_slope,
    serial=etr_fit_joint_bspline_functional_correlated,
    nested_trial=etr_fit_joint_bspline_functional_nested_trial,
    nested_slope=etr_fit_joint_bspline_functional_nested_slope)
  .etr_assert(is.function(fn),"unsupported structured joint likelihood solver")
  do.call(fn,args)
}

.etr_joint_structured_full_refit_bootstrap<-function(
    result,n_bootstrap=1000L,random_state=0L,
    sampled_participant_indices=NULL){
  kind<-.etr_joint_structured_refit_kind(result)
  .etr_assert(inherits(result,"etr_joint_bspline_mixed")&&
    inherits(result$fitted_model,"lme")&&
    identical(result$backend,"nlme::lme"),
    "structured full-refit requires a converged joint nlme likelihood fit")
  controls<-.etr_joint_mixed_boot_controls(n_bootstrap,random_state,20L)
  B<-controls$n_bootstrap
  random_state<-controls$random_state
  group_ids<-as.character(result$participant_ids)
  group<-as.character(result$curve_participant_ids)
  N<-length(group_ids)
  nt<-length(result$time)
  Y<-result$observed_functions
  X<-result$scalar_design
  nc<-nrow(Y)
  nf<-ncol(result$fixed_basis)
  nr<-ncol(result$random_basis)
  np<-nrow(result$fixed_basis_coefficients)
  q<-ncol(result$random_effect_covariance)
  nested<-kind%in%c("nested_trial","nested_slope")
  slope<-kind%in%c("slope","nested_slope")
  correlation<-result[["residual_correlation",exact=TRUE]]
  if(is.null(correlation))correlation<-"iid"
  .etr_assert(correlation%in%c("iid","ar1","exponential")&&
    (kind!="serial"||correlation!="iid")&&
    (kind!="slope"||correlation=="iid"),
    "declared structured residual covariance is unsupported")
  .etr_assert(length(group_ids)>0L&&!anyDuplicated(group_ids)&&
    length(group)==nc&&all(group%in%group_ids)&&
    is.matrix(Y)&&is.numeric(Y)&&
    all(is.finite(Y))&&is.matrix(X)&&is.numeric(X)&&
    identical(dim(X),c(nc,np))&&all(is.finite(X))&&
    is.matrix(result$random_effect_covariance)&&
    identical(dim(result$random_effect_covariance),c(q,q))&&
    q==(if(slope)2L*nr else nr),
    "structured reference design/covariance dimensions are inconsistent")
  .etr_assert(N>=max(4L,nr+1L)&&
    !is.null(result$dimension_name)&&
    all(c("Intercept",as.character(result$predictor_names)[-1L])==
      as.character(result$predictor_names)),
    "structured joint likelihood reference is incomplete")
  source_bundles<-lapply(group_ids,function(id)which(group==id))
  .etr_assert(all(lengths(source_bundles)>0L),
    "reference contains an empty participant cluster")
  if(nested).etr_assert(
    length(result$curve_trial_ids)==nc &&
      all(nzchar(as.character(result$curve_trial_ids))),
    "nested source trial identities are incomplete")
  draws<-.etr_joint_mixed_boot_draws(B,N,random_state,sampled_participant_indices)
  sampled<-draws$indices
  nt_trial<-if(nested)ncol(result$trial_random_basis)else 0L
  fixed<-array(NA_real_,c(B,np,nf))
  curves<-array(NA_real_,c(B,np,nt))
  covs<-array(NA_real_,c(B,q,q))
  intercept<-array(NA_real_,c(B,nr,nr))
  slopes<-if(slope)array(NA_real_,c(B,nr,nr))else NULL
  crosses<-if(slope)array(NA_real_,c(B,nr,nr))else NULL
  trials<-if(nested)array(NA_real_,c(B,nt_trial,nt_trial))else NULL
  eigenvalues<-matrix(NA_real_,B,q)
  condition<-rep(NA_real_,B)
  boundary<-logical(B);singular<-logical(B);slope_boundary<-logical(B)
  trial_eigen<-if(nested)matrix(NA_real_,B,nt_trial)else NULL
  trial_condition<-if(nested)rep(NA_real_,B)else NULL
  trial_boundary<-if(nested)logical(B)else NULL
  trial_singular<-if(nested)logical(B)else NULL
  rho<-if(correlation!="iid")rep(NA_real_,B)else NULL
  rho_boundary<-if(correlation!="iid")logical(B)else NULL
  rho_independence<-if(correlation!="iid")logical(B)else NULL
  rho_condition<-if(correlation!="iid")rep(NA_real_,B)else NULL
  sigma2<-rep(NA_real_,B);loglik<-rep(NA_real_,B)
  source_ids<-vector("list",B)
  bootstrap_ids<-vector("list",B)
  trial_audit<-vector("list",B)
  warnings<-vector("list",B)
  coefficient_names<-as.character(result$predictor_names)[-1L]
  for(b in seq_len(B)){
    bundle<-.etr_joint_refit_draw_bundle(source_bundles,group_ids,sampled[b,],b-1L)
    source_rows<-bundle$rows
    source_ids[[b]]<-bundle$source_ids
    bootstrap_ids[[b]]<-bundle$participant_ids
    meta<-data.frame(.etr_bootstrap_pid=bundle$membership,
      stringsAsFactors=FALSE)
    if(nested){
      # Python gives each source trial occurrence an independent trial ID,
      # including repeated draws from the same source participant.
      trial_ids<-sprintf("%s_trial_%04d",
        bundle$membership,bundle$within_draw)
      meta$.etr_bootstrap_trial<-trial_ids
      trial_audit[[b]]<-data.frame(
        source_participant_id=as.character(group[source_rows]),
        bootstrap_participant_id=bundle$membership,
        source_trial_id=as.character(
          result$curve_trial_ids[source_rows]),
        bootstrap_trial_id=trial_ids,
        stringsAsFactors=FALSE)
    }
    tr<-etr_trajectory_set(result$time,
      array(as.numeric(Y[source_rows,,drop=FALSE]),
        dim=c(length(source_rows),nt,1L)),
      bundle$curve_ids,as.character(result$dimension_name),
      metadata=meta,
      coordinate_system=if(is.null(result$coordinate_system))
        "unknown" else result$coordinate_system,
      time_unit=result$time_unit)
    d<-data.frame(curve_id=bundle$curve_ids,stringsAsFactors=FALSE)
    for(j in seq_along(coefficient_names))
      d[[coefficient_names[[j]]]]<-X[source_rows,j+1L]
    alerts<-character()
    fit<-tryCatch(
      withCallingHandlers(
        .etr_joint_structured_refit_solver(kind,result,tr,d,
          result$random_slope_predictor),
        warning=function(w){
          alerts<<-c(alerts,conditionMessage(w))
          invokeRestart("muffleWarning")
        }),
      error=function(e)stop(sprintf(
        "structured full-refit bootstrap %s replicate %d failed; no source draw discarded/redrawn: %s",
        kind,b,conditionMessage(e)),call.=FALSE))
    fixed[b,,]<-fit$fixed_basis_coefficients
    curves[b,,]<-fit$fixed_coefficient_functions
    covs[b,,]<-fit$random_effect_covariance
    covariance<-.etr_nested_source_covariance_diagnostics(
      fit$random_effect_covariance)
    eigenvalues[b,]<-covariance$eigenvalues
    condition[b]<-covariance$condition_number
    boundary[b]<-covariance$boundary
    singular[b]<-covariance$singular
    intercept[b,,]<-if(nested)
      fit$random_intercept_covariance else
        fit$random_effect_covariance[seq_len(nr),seq_len(nr),drop=FALSE]
    if(slope){
      slopes[b,,]<-if(nested)fit$random_slope_covariance else
        fit$random_effect_covariance[nr+seq_len(nr),
          nr+seq_len(nr),drop=FALSE]
      crosses[b,,]<-if(nested)
        fit$random_intercept_slope_covariance else
          fit$random_effect_covariance[seq_len(nr),
            nr+seq_len(nr),drop=FALSE]
      evs<-eigen(slopes[b,,],symmetric=TRUE,only.values=TRUE)$values
      slope_boundary[b]<-max(evs)<=.10*max(
        max(abs(covariance$eigenvalues)),.Machine$double.eps)||
        min(evs)<=1e-8*covariance$scale
    }
    if(nested){
      trials[b,,]<-fit$trial_random_effect_covariance
      trial_eigen[b,]<-fit$trial_random_effect_covariance_eigenvalues
      trial_condition[b]<-fit$trial_random_effect_covariance_condition_number
      trial_boundary[b]<-fit$trial_random_effect_boundary_fit
      trial_singular[b]<-fit$trial_random_effect_singular
      boundary[b]<-boundary[b]||trial_boundary[b]
    }
    if(!is.null(rho)){
      residual_diagnostics<-if(nested)fit else
        .etr_nested_source_residual_contract(fit$time,correlation,
          fit$residual_correlation_parameter,fit$residual_correlation_matrix,
          fit$residual_functions,fit$residual_variance,fit$time_unit)
      rho[b]<-fit$residual_correlation_parameter
      rho_boundary[b]<-residual_diagnostics$residual_correlation_boundary_fit
      rho_independence[b]<-isTRUE(
        residual_diagnostics$residual_correlation_independence_limit_fit)
      rho_condition[b]<-
        residual_diagnostics$residual_correlation_condition_number
      boundary[b]<-boundary[b]||rho_boundary[b]
    }
    sigma2[b]<-fit$residual_variance
    loglik[b]<-as.numeric(stats::logLik(fit$fitted_model))
    warnings[[b]]<-unique(alerts)
  }
  avg<-matrix(apply(curves,c(2L,3L),mean),nrow=np,ncol=nt)
  se<-matrix(apply(curves,c(2L,3L),stats::sd),nrow=np,ncol=nt)
  .etr_assert(all(is.finite(avg))&&all(is.finite(se))&&
    all(is.finite(sigma2))&&all(sigma2>0)&&
    all(is.finite(loglik)),
    "structured likelihood bootstrap summaries are nonfinite")
  provenance<-result$provenance
  provenance$functional_mixed_effects_full_refit_bootstrap<-list(
    method="participant_cluster_case_bootstrap_full_ml_reml_refit",
    source_model_structure=kind,residual_correlation=correlation,
    n_bootstrap=B,random_state=random_state,
    sampled_indices_supplied=!is.null(sampled_participant_indices),
    native_rng=draws$engine,
    duplicate_participant_draws_receive_distinct_group_ids=TRUE,
    nested_trials_receive_distinct_ids=nested,
    participant_covariance_refit=TRUE,
    random_slope_covariance_refit=slope,
    trial_random_effect_covariance_refit=nested,
    residual_correlation_parameter_refit=correlation!="iid",
    residual_variance_refit=TRUE,
    fixed_basis_refit=FALSE,
    failure_policy="raise",
    native_optimizer="nlme::lme",
    python_statsmodels_optimizer_equivalent=FALSE,
    independent_full_source_certified=FALSE)
  structure(list(
    reference=result,
    bootstrap_fixed_basis_coefficients=fixed,
    bootstrap_coefficient_functions=curves,
    sampled_participant_indices=sampled,
    sampled_source_participant_ids=source_ids,
    bootstrap_participant_ids=bootstrap_ids,
    bootstrap_mean=avg,bootstrap_standard_errors=se,
    random_effect_covariances=covs,
    random_intercept_covariances=intercept,
    random_slope_covariances=slopes,
    random_intercept_slope_covariances=crosses,
    random_effect_covariance_eigenvalues=eigenvalues,
    random_effect_covariance_condition_numbers=condition,
    random_effect_boundary_flags=boundary,
    random_effect_singular_flags=singular,
    random_slope_boundary_flags=slope_boundary,
    residual_variances=sigma2,log_likelihoods=loglik,
    convergence_flags=rep(TRUE,B),backend_warnings=warnings,
    trial_random_effect_covariances=trials,
    trial_random_effect_covariance_eigenvalues=trial_eigen,
    trial_random_effect_covariance_condition_numbers=trial_condition,
    trial_random_effect_boundary_flags=trial_boundary,
    trial_random_effect_singular_flags=trial_singular,
    bootstrap_trial_audit=trial_audit,
    residual_correlation_parameters=rho,
    residual_correlation_boundary_flags=rho_boundary,
    residual_correlation_independence_flags=rho_independence,
    residual_correlation_condition_numbers=rho_condition,
    random_state=random_state,
    bootstrap_type="full_refit",failure_policy="raise",
    variance_components_refit=TRUE,
    provenance=provenance,
    source_python_full_contract_certified=FALSE,
    independent_full_source_certified=FALSE),
    class=c("etr_joint_mixed_structured_full_refit_bootstrap",
      "etr_mixed_effects_full_refit_bootstrap"))
}
