# Frozen Python 1.2 generalized_function_on_scalar.py participant-case bootstrap.
# Full GEE fits are repeated for each participant-resampled replicate.
# Source RNG is NumPy PCG64; optional fixed indices replay the source draws.

#' Whole-participant case bootstrap of native generalized functional GEE
#'
#' @param result Native generalized functional GEE fit.
#' @param n_bootstrap Number of full GEE refits (>=100).
#' @param random_state Native base-R seed; not NumPy PCG64 equivalent.
#' @param failed_replicate_policy Exactly "raise"; no failed rep is replaced.
#' @param sampled_participant_indices Optional B-by-participant matrix of
#'   zero-based retained Python source draw indices for exact oracle replay.
#' @return Native bootstrap with coefficient functions and complete source
#'   participant and new cluster-ID audit per replicate.
#' @export
etr_bootstrap_generalized_function_on_scalar_coefficients<-function(
    result,n_bootstrap=100L,random_state=0L,
    failed_replicate_policy="raise",sampled_participant_indices=NULL){
  .etr_assert(inherits(result,"etr_generalized_function_on_scalar"),
    "result must be a native generalized functional GEE fit")
  .etr_assert(is.numeric(n_bootstrap)&&length(n_bootstrap)==1L&&
    is.finite(n_bootstrap)&&n_bootstrap==floor(n_bootstrap)&&
    n_bootstrap>=100L,
    "n_bootstrap must be an integer >=100")
  .etr_assert(identical(failed_replicate_policy,"raise"),
    "failed_replicate_policy must be raise: no silent replacement")
  .etr_assert(is.numeric(random_state)&&length(random_state)==1L&&
    is.finite(random_state)&&random_state==floor(random_state)&&
    random_state>=0L&&random_state<=.Machine$integer.max,
    "random_state must be a supported nonnegative R integer")
  B<-as.integer(n_bootstrap)
  ids<-result$participant_ids
  np<-length(ids)
  group<-as.character(result$curve_participant_ids)
  .etr_assert(length(group)==nrow(result$observed_functions)&&
    all(group%in%ids)&&np>0L,
    "source participant/curve membership is inconsistent")
  if(is.null(sampled_participant_indices)){
    sampled<-.etr_seed_scope(as.integer(random_state),function()
      matrix(sample.int(np,B*np,replace=TRUE)-1L,nrow=B,ncol=np))
  }else{
    sampled<-sampled_participant_indices
    .etr_assert(is.matrix(sampled)&&is.numeric(sampled)&&
      identical(dim(sampled),c(B,np))&&
      all(is.finite(sampled))&&all(sampled==floor(sampled))&&
      all(sampled>=0L)&all(sampled<np),
      "sampled_participant_indices must be a finite B-by-participant zero-based index matrix")
    sampled<-matrix(as.integer(sampled),B,np)
  }
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
    new_ids<-sprintf("bootstrap_%04d_curve_%04d",b-1L,
      seq_along(indices)-1L)
    responses<-result$observed_functions[indices,,drop=FALSE]
    trajectories<-etr_trajectory_set(
      result$time,array(as.numeric(responses),
        dim=c(length(indices),nt,1L)),new_ids,
      result$dimension_name,
      metadata=data.frame(participant_id=memberships,
        stringsAsFactors=FALSE),
      coordinate_system=result$coordinate_system,
      time_unit=result$time_unit)
    design<-data.frame(curve_id=new_ids,stringsAsFactors=FALSE)
    for(j in seq_along(result$predictor_names))
      design[[result$predictor_names[j]]]<-
        result$scalar_design_matrix[indices,j+1L]
    fit<-tryCatch(
      etr_fit_generalized_function_on_scalar_regression(
        trajectories,design,result$predictor_names,
        participant_column="participant_id",
        dimension=result$dimension_name,family=result$family,
        binomial_denominator=if(is.null(result$binomial_denominators))
          NULL else result$binomial_denominators[indices,,drop=FALSE],
        exposure=if(is.null(result$exposure))NULL else
          result$exposure[indices,,drop=FALSE],
        exposure_units=result$exposure_units,
        basis_size=result$basis_size,
        spline_degree=result$spline_degree,
        working_correlation=result$working_correlation,
        covariance_type=result$covariance_type,
        maxiter=result$maxiter,ctol=result$ctol),
      error=function(e)stop(paste0(
        "generalized function-on-scalar participant bootstrap failed ",
        "at replicate ",b-1L,
        "; not silently dropped or redrawn: ",conditionMessage(e)),
        call.=FALSE))
    draws[b,,]<-fit$coefficient_functions
  }
  prov<-result$provenance
  prov$generalized_function_on_scalar_bootstrap<-list(
    method="whole_participant_case_bootstrap_full_gee_refit",
    n_bootstrap=B,random_state=as.integer(random_state),
    source_draws_supplied=!is.null(sampled_participant_indices),
    native_random_engine="base_R_not_NumPy_PCG64",
    resampling_unit="participant",
    whole_participant_curve_bundles_resampled=TRUE,
    duplicate_source_participants_receive_distinct_group_ids=TRUE,
    family_refit=result$family,link_refit=result$link,
    working_correlation_refit="independence",
    basis_refit=FALSE,basis_selected_automatically=FALSE,
    failed_replicate_policy="raise",failed_replicates_redrawn=FALSE,
    exposure_observed_and_fixed=!is.null(result$exposure),
    binomial_denominator_observed_and_fixed=
      !is.null(result$binomial_denominators),
    full_source_contract_certified=FALSE)
  structure(list(
    reference=result,
    bootstrap_coefficient_functions=draws,
    sampled_participant_indices=sampled,
    sampled_source_participant_ids=source_audit,
    sampled_bootstrap_participant_ids=cluster_audit,
    random_state=as.integer(random_state),
    failure_policy="raise",provenance=prov),
    class="etr_generalized_function_on_scalar_bootstrap")
}
