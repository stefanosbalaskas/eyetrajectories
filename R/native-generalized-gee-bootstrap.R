# Refits the exact canonical independence-GEE score equations on the
# original fixed clamped B-spline basis, preserving participant clusters.
# Unlike the public fit, no TrajectorySet, metadata, or basis is rebuilt for
# each bootstrap replicate. The sandwich is recomputed and checked to retain
# source robust-inference failure boundaries (even though only coefficients
# are returned by the coefficient bootstrap).
.etr_gfosr_bootstrap_fixed_basis_refit<-function(result,indices,groups){
  y<-result$observed_functions[indices,,drop=FALSE]
  X<-result$scalar_design_matrix[indices,,drop=FALSE]
  basis<-result$basis
  n<-nrow(X);nt<-ncol(y);p<-ncol(X);K<-ncol(basis)
  .etr_assert(nrow(basis)==nt&&length(groups)==n&&
    !anyNA(groups)&&length(unique(groups))>p*K,
    "resampled participant or fixed-basis GEE geometry is invalid")
  .etr_assert(all(is.finite(y))&&all(is.finite(X))&&
    all(is.finite(basis)),"GEE bootstrap arrays must be finite")
  rows<-rep(seq_len(nt),times=n)
  expanded<-do.call(cbind,lapply(seq_len(p),function(j)
    basis[rows,,drop=FALSE]*rep(X[,j],each=nt)))
  source_mode<-identical(result$provenance$native_solver,
    "native_irls_gee_score_sandwich")
  .etr_assert(.etr_gfosr_design_rank(expanded,source_mode)==p*K,
    "resampled generalized GEE spline design is rank deficient")
  den<-if(is.null(result$binomial_denominators))NULL else
    result$binomial_denominators[indices,,drop=FALSE]
  exposure<-if(is.null(result$exposure))NULL else
    result$exposure[indices,,drop=FALSE]
  if(identical(result$family,"binomial")){
    if(is.null(den)){
      .etr_assert(all(y%in%c(0,1)),
        "bootstrap Bernoulli outcomes must be 0/1")
      observed<-y
      w<-rep(1,n*nt)
    }else{
      .etr_assert(all(den>0)&&all(is.finite(den))&&
        all(y>=0)&&all(y<=den),
        "bootstrap grouped-binomial denominator and successes are invalid")
      observed<-y/den
      w<-as.vector(t(den))
    }
    family_object<-stats::binomial(link="logit")
  }else{
    .etr_assert(identical(result$family,"poisson")&&
      all(y>=0)&&all(abs(y-round(y))<=1e-12),
      "bootstrap requires valid Poisson counts")
    observed<-y;w<-rep(1,n*nt)
    family_object<-stats::poisson(link="log")
  }
  offset<-if(is.null(exposure))rep(0,n*nt) else
    as.vector(t(log(exposure)))
  response<-as.vector(t(observed))
  if(source_mode){
    fit<-.etr_gfosr_source_gee_fit(expanded,response,w,offset,
      rep(groups,each=nt),result$family,result$maxiter,result$ctol)
    return(matrix(fit$beta,nrow=p,ncol=K,byrow=TRUE)%*%t(basis))
  }
  fit<-suppressWarnings(stats::glm.fit(x=expanded,y=response,
    weights=w,offset=offset,family=family_object,
    control=stats::glm.control(epsilon=result$ctol,
      maxit=as.integer(result$maxiter))))
  .etr_assert(isTRUE(fit$converged)&&
    length(fit$coefficients)==p*K&&
    all(is.finite(fit$coefficients)),
    "resampled generalized GEE did not converge")
  eta<-as.vector(expanded%*%fit$coefficients)+offset
  mu<-as.numeric(family_object$linkinv(eta))
  .etr_assert(all(is.finite(mu)),"bootstrap GEE means are nonfinite")
  variance_weights<-if(identical(result$family,"binomial"))
    w*mu*(1-mu) else mu
  bread<-crossprod(expanded,expanded*variance_weights)
  .etr_assert(qr(bread)$rank==p*K,
    "resampled GEE robust information matrix is rank deficient")
  inverse<-solve(bread)
  residual_score<-if(identical(result$family,"binomial"))
    w*(response-mu) else response-mu
  cluster<-rep(match(groups,unique(groups)),each=nt)
  meat<-matrix(0,p*K,p*K)
  for(g in seq_len(length(unique(groups)))){
    ix<-which(cluster==g)
    score<-as.vector(crossprod(expanded[ix,,drop=FALSE],
      residual_score[ix]))
    meat<-meat+tcrossprod(score)
  }
  covariance<-inverse%*%meat%*%inverse
  .etr_assert(all(is.finite(covariance)),
    "bootstrap GEE robust covariance is nonfinite")
  matrix(as.numeric(fit$coefficients),nrow=p,ncol=K,
    byrow=TRUE)%*%t(basis)
}

# Frozen Python 1.2 generalized_function_on_scalar.py participant-case bootstrap.
# Full GEE fits are repeated for each participant-resampled replicate.
# Seeded participant draws follow NumPy PCG64.

#' Whole-participant case bootstrap of native generalized functional GEE
#'
#' @param result Native generalized functional GEE fit.
#' @param n_bootstrap Number of full GEE refits (>=100).
#' @param random_state Exactly represented nonnegative integer below 2^53
#'   for NumPy-compatible PCG64 draws, or NULL for unseeded native R draws.
#' @param failed_replicate_policy Exactly "raise"; no failed rep is replaced.
#' @param sampled_participant_indices Optional B-by-participant matrix of
#'   zero-based retained Python source draw indices for exact oracle replay.
#' @return Native bootstrap with coefficient functions and complete source
#'   participant and new cluster-ID audit per replicate.
#' @export
etr_bootstrap_generalized_function_on_scalar_coefficients<-function(
    result,n_bootstrap=1000L,random_state=0L,
    failed_replicate_policy="raise",sampled_participant_indices=NULL){
  .etr_assert(inherits(result,"etr_generalized_function_on_scalar"),
    "result must be a native generalized functional GEE fit")
  controls<-.etr_joint_mixed_boot_controls(n_bootstrap,random_state,100L)
  .etr_assert(identical(failed_replicate_policy,"raise"),
    "failed_replicate_policy must be raise: no silent replacement")
  B<-controls$n_bootstrap
  random_state<-controls$random_state
  ids<-result$participant_ids
  np<-length(ids)
  group<-as.character(result$curve_participant_ids)
  .etr_assert(length(group)==nrow(result$observed_functions)&&
    all(group%in%ids)&&np>0L,
    "source participant/curve membership is inconsistent")
  selection<-.etr_joint_mixed_boot_draws(
    B,np,random_state,sampled_participant_indices)
  sampled<-selection$indices
  nt<-length(result$time);nco<-length(result$coefficient_names)
  draws<-array(NA_real_,c(B,nco,nt))
  source_audit<-vector("list",B)
  cluster_audit<-vector("list",B)
  bundles<-lapply(ids,function(id)which(group==id))
  for(b in seq_len(B)){
    bundle_order<-sampled[b,]+1L
    indices<-unlist(bundles[bundle_order],use.names=FALSE)
    new_clusters<-sprintf("bootstrap_%04d_participant_%04d",
      b-1L,seq_len(np)-1L)
    source_audit[[b]]<-as.character(ids[bundle_order])
    cluster_audit[[b]]<-as.character(new_clusters)
    memberships<-rep(new_clusters,lengths(bundles[bundle_order]))
    # Direct fixed-basis GEE solves the same cluster-independent score
    # equations as Python _fit_gee_arrays and validates the sandwich.
    # Avoid constructing and revalidating trajectories for every replicate.
    draws[b,,]<-tryCatch(
      .etr_gfosr_bootstrap_fixed_basis_refit(result,indices,memberships),
      error=function(e)stop(paste0(
        "generalized function-on-scalar participant bootstrap failed ",
        "at replicate ",b-1L,
        "; not silently dropped or redrawn: ",conditionMessage(e)),
        call.=FALSE))
  }
  prov<-result$provenance
  prov$generalized_function_on_scalar_bootstrap<-list(
    method="whole_participant_case_bootstrap_full_gee_refit",
    n_bootstrap=B,random_state=random_state,
    source_draws_supplied=!is.null(sampled_participant_indices),
    native_random_engine=selection$engine,
    resampling_unit="participant",
    whole_participant_curve_bundles_resampled=TRUE,
    duplicate_source_participants_receive_distinct_group_ids=TRUE,
    family_refit=result$family,link_refit=result$link,
    working_correlation_refit="independence",
    basis_refit=FALSE,basis_selected_automatically=FALSE,
    failed_replicate_policy="raise",failed_replicates_redrawn=FALSE,
    exposure_observed_and_fixed=!is.null(result$exposure),
    exposure_resampled_with_response_bundle=!is.null(result$exposure),
    exposure_measurement_uncertainty=FALSE,
    binomial_denominator_resampled_with_response_bundle=
      !is.null(result$binomial_denominators),
    binomial_denominator_measurement_uncertainty=FALSE,
    binomial_denominator_observed_and_fixed=
      !is.null(result$binomial_denominators),
    full_source_contract_certified=FALSE)
  structure(list(
    reference=result,
    bootstrap_coefficient_functions=draws,
    sampled_participant_indices=sampled,
    sampled_source_participant_ids=source_audit,
    sampled_bootstrap_participant_ids=cluster_audit,
    random_state=random_state,
    failure_policy="raise",provenance=prov),
    class="etr_generalized_function_on_scalar_bootstrap")
}
