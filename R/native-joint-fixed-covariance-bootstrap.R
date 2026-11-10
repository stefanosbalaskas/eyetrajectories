# Fixed-covariance participant-cluster GLS bootstrap for actual joint spline
# likelihood fits. Frozen Python 1.2:
# src/eyetrajectoriespy/functional_mixed_effects_inference.py
# at c1cd95ad718327550f7e55393ff38582872f7a94.
# Reference covariance matrices and fixed/random spline designs are held
# fixed. Unlike the existing mixed moments analogue, the Gaussian covariance
# couples all times and all source curves belonging to a participant.
# Independent source contract certification is not asserted.

.etr_joint_bootstrap_gls_contributions<-function(fit){
  .etr_assert(inherits(fit,"etr_joint_bspline_mixed")&&
    inherits(fit$fitted_model,"lme"),
    "joint GLS bootstrap requires a converged nlme spline likelihood fit")
  X<-fit$fixed_long_design
  Z<-fit$random_long_design
  G<-fit$random_effect_covariance
  C<-fit[["residual_correlation_matrix",exact=TRUE]]
  Y<-fit$observed_functions
  B<-fit$fixed_basis
  n<-fit$n_curves;nt<-length(fit$time)
  ids<-as.character(fit$participant_ids)
  membership<-as.character(fit$curve_participant_ids)
  p<-nrow(fit$fixed_basis_coefficients)
  nf<-ncol(B);k<-p*nf
  .etr_assert(is.matrix(X)&&is.numeric(X)&&
    identical(dim(X),c(n*nt,k))&&all(is.finite(X)),
    "joint fixed-long spline design is invalid")
  .etr_assert(is.matrix(G)&&is.numeric(G)&&
    nrow(G)>0L&&nrow(G)==ncol(G)&&
    all(is.finite(G))&&max(abs(G-t(G)))<=1e-7,
    "joint participant covariance must be finite symmetric")
  .etr_assert(is.matrix(Z)&&is.numeric(Z)&&
    identical(dim(Z),c(n*nt,ncol(G)))&&all(is.finite(Z)),
    "joint random-long spline design must match covariance")
  .etr_assert(is.matrix(C)&&is.numeric(C)&&
    identical(dim(C),c(nt,nt))&&all(is.finite(C))&&
    max(abs(C-t(C)))<=1e-8,
    "joint within-curve residual correlation must be finite symmetric")
  .etr_assert(is.numeric(fit$residual_variance)&&
    length(fit$residual_variance)==1L&&
    is.finite(fit$residual_variance)&&fit$residual_variance>0,
    "joint residual variance must be positive finite")
  .etr_assert(is.matrix(Y)&&is.numeric(Y)&&
    identical(dim(Y),c(n,nt))&&all(is.finite(Y))&&
    is.matrix(B)&&nrow(B)==nt&&ncol(B)==nf&&
    all(is.finite(B)),
    "joint observed functions or fixed basis have invalid geometry")
  .etr_assert(length(ids)==fit$n_participants&&
    length(ids)>0L&&!anyDuplicated(ids)&&
    length(membership)==n&&all(membership%in%ids),
    "joint participant membership must identify every source curve")
  .etr_assert(is.matrix(fit$fixed_basis_coefficients)&&
    all(is.finite(fit$fixed_basis_coefficients)),
    "joint fitted fixed-basis coefficients must be finite")
  residual_block<-fit$residual_variance*C
  .etr_assert(!inherits(try(chol(residual_block),silent=TRUE),"try-error"),
    "reference within-curve covariance is not positive definite")
  nested<-!is.null(fit$trial_random_effect)
  if(nested){
    .etr_assert(identical(fit$trial_random_effect,
      "functional_intercept"),
      "joint bootstrap supports only declared functional trial intercept")
    Bt<-fit$trial_random_basis
    H<-fit$trial_random_effect_covariance
    .etr_assert(is.matrix(Bt)&&is.numeric(Bt)&&
      nrow(Bt)==nt&&is.matrix(H)&&is.numeric(H)&&
      identical(dim(H),c(ncol(Bt),ncol(Bt)))&&
      all(is.finite(Bt))&&all(is.finite(H))&&
      max(abs(H-t(H)))<=1e-7,
      "nested trial covariance and basis must be finite and aligned")
    trial_block<-Bt%*%H%*%t(Bt)
  }else trial_block<-NULL
  np<-length(ids)
  information<-array(NA_real_,c(np,k,k))
  scores<-matrix(NA_real_,np,k)
  for(g in seq_len(np)){
    curves<-which(membership==ids[[g]])
    .etr_assert(length(curves)>0L,
      "reference participant has no associated source curves")
    ix<-as.integer(unlist(lapply(curves,function(i)
      (i-1L)*nt+seq_len(nt)),use.names=FALSE))
    Xg<-X[ix,,drop=FALSE]
    Zg<-Z[ix,,drop=FALSE]
    observed<-as.numeric(t(Y[curves,,drop=FALSE]))
    m<-length(curves)
    V<-Zg%*%G%*%t(Zg)+
      kronecker(diag(1,m),residual_block)
    if(nested)for(j in seq_len(m)){
      jj<-(j-1L)*nt+seq_len(nt)
      V[jj,jj]<-V[jj,jj]+trial_block
    }
    V<-(V+t(V))/2
    U<-tryCatch(chol(V),
      error=function(e)stop(paste(
        "reference participant marginal covariance could not be solved:",
        conditionMessage(e)),call.=FALSE))
    # One Cholesky factorization for all pK fixed-effect RHSs and response.
    W<-backsolve(U,forwardsolve(t(U),
      cbind(Xg,observed)))
    inverse_fixed<-W[,seq_len(k),drop=FALSE]
    inverse_y<-W[,k+1L]
    information[g,,]<-crossprod(Xg,inverse_fixed)
    scores[g,]<-as.numeric(crossprod(Xg,inverse_y))
  }
  total_information<-apply(information,c(2L,3L),sum)
  total_information<-matrix(total_information,nrow=k,ncol=k)
  total_scores<-colSums(scores)
  .etr_assert(qr(total_information)$rank==k,
    "reference fixed-covariance GLS system is rank deficient")
  reference_gls<-as.numeric(solve(total_information,total_scores))
  backend<-as.numeric(t(fit$fixed_basis_coefficients))
  max_difference<-max(abs(reference_gls-backend))
  .etr_assert(all(abs(reference_gls-backend)<=
    2e-7+2e-4*abs(backend)),
    "fixed-covariance GLS reconstruction does not reproduce the fitted joint model coefficients")
  list(information=information,scores=scores,
    max_reference_gls_difference=max_difference,
    n_parameters=k,n_coefficients=p,n_basis=nf,
    n_time=nt,participant_ids=ids)
}

.etr_joint_fixed_covariance_gls_bootstrap<-function(
    result,n_bootstrap=1000L,random_state=0L,
    sampled_participant_indices=NULL){
  .etr_assert(is.numeric(n_bootstrap)&&length(n_bootstrap)==1L&&
    !is.logical(n_bootstrap)&&is.finite(n_bootstrap)&&
    n_bootstrap==floor(n_bootstrap)&&n_bootstrap>=100L&&
    n_bootstrap<=.Machine$integer.max,
    "n_bootstrap must be an integer >=100")
  .etr_assert(is.null(random_state)||
    (is.numeric(random_state)&&length(random_state)==1L&&
      !is.logical(random_state)&&is.finite(random_state)&&
      random_state==floor(random_state)&&random_state>=0L&&
      random_state<=.Machine$integer.max),
    "random_state must be NULL or a supported nonnegative integer")
  source<-.etr_joint_bootstrap_gls_contributions(result)
  np<-length(source$participant_ids);B<-as.integer(n_bootstrap)
  if(is.null(sampled_participant_indices)){
    sample_once<-function()
      matrix(sample.int(np,B*np,replace=TRUE)-1L,nrow=B,ncol=np)
    indices<-if(is.null(random_state))sample_once() else
      .etr_seed_scope(as.integer(random_state),sample_once)
  }else{
    indices<-sampled_participant_indices
    .etr_assert(is.matrix(indices)&&is.numeric(indices)&&
      identical(dim(indices),c(B,np))&&
      all(is.finite(indices))&&
      all(indices==floor(indices))&&
      all(indices>=0)&&all(indices<np),
      "sampled_participant_indices must be a finite zero-based B-by-participant index matrix")
    indices<-matrix(as.integer(indices),B,np)
  }
  k<-source$n_parameters
  p<-source$n_coefficients
  nf<-source$n_basis
  nt<-source$n_time
  fixed<-array(NA_real_,c(B,p,nf))
  curves<-array(NA_real_,c(B,p,nt))
  for(b in seq_len(B)){
    selected<-indices[b,]+1L
    info<-matrix(0,k,k)
    score<-numeric(k)
    for(g in selected){
      info<-info+matrix(source$information[g,,],
        nrow=k,ncol=k)
      score<-score+source$scores[g,]
    }
    .etr_assert(qr(info)$rank==k,
      paste("participant-cluster bootstrap replicate",b,
        "produced a rank-deficient fixed-effect information matrix; no replicate was discarded"))
    beta<-tryCatch(solve(info,score),error=function(e)
      stop(paste("participant-cluster bootstrap replicate",b,
        "could not solve the fixed-effect GLS system; no replicate was discarded:",
        conditionMessage(e)),call.=FALSE))
    M<-matrix(as.numeric(beta),nrow=p,ncol=nf,byrow=TRUE)
    fixed[b,,]<-M
    curves[b,,]<-M%*%t(result$fixed_basis)
  }
  estimate<-matrix(apply(curves,c(2L,3L),mean),nrow=p,ncol=nt)
  se<-matrix(apply(curves,c(2L,3L),stats::sd),nrow=p,ncol=nt)
  .etr_assert(all(is.finite(estimate))&&all(is.finite(se)),
    "joint fixed-covariance bootstrap summary is not finite")
  conditioned<-if(is.null(result$trial_random_effect))
    "reference_participant_and_residual_covariance_fixed" else
    "reference_participant_and_trial_random_effect_covariances_and_residual_covariance_fixed"
  provenance<-result$provenance
  provenance$functional_mixed_effects_bootstrap<-list(
    method="participant_cluster_case_bootstrap_fixed_covariance_gls",
    n_bootstrap=B,
    random_state=if(is.null(random_state))NULL else as.integer(random_state),
    sampled_source_indices_supplied=!is.null(sampled_participant_indices),
    native_rng="base_R_not_NumPy_PCG64",
    resampling_unit="participant",
    whole_trial_bundles_resampled=TRUE,
    curves_resampled_independently=FALSE,
    fixed_effects_reestimated_each_replicate=TRUE,
    variance_components_refit=FALSE,
    random_effect_covariance_conditioned_on_reference=TRUE,
    trial_random_effect_covariance_conditioned_on_reference=
      !is.null(result$trial_random_effect),
    residual_variance_conditioned_on_reference=TRUE,
    residual_correlation_conditioned_on_reference=TRUE,
    fixed_basis_refit=FALSE,random_basis_refit=FALSE,
    reference_gls_max_abs_difference=
      source$max_reference_gls_difference,
    failed_replicate_policy="raise",
    source_python_full_contract_certified=FALSE,
    independent_full_source_certified=FALSE)
  structure(list(reference=result,
    bootstrap_fixed_basis_coefficients=fixed,
    bootstrap_coefficient_functions=curves,
    sampled_participant_indices=indices,
    bootstrap_mean=estimate,
    bootstrap_standard_errors=se,
    bootstrap_type="conditional_covariance",
    random_state=if(is.null(random_state))NULL else as.integer(random_state),
    covariance_conditioning=conditioned,
    provenance=provenance,
    source_python_full_contract_certified=FALSE,
    independent_full_source_certified=FALSE),
    class=c("etr_joint_mixed_fixed_covariance_bootstrap",
      "etr_mixed_effects_conditional_bootstrap"))
}
