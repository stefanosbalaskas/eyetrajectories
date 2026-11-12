# Two scientific routes coexist in this public API:
# - Historical restricted mixed moments inputs retain the timewise moments
#   participant bootstrap (scientifically different from Python MixedLM).
# - Joint spline likelihood inputs now dispatch to full within-participant
#   GLS conditional resampling or native nlme iid likelihood full refitting.
# The joint full-refit implementation is limited to iid participant random
# intercepts. Python 1.2 optimizer and all typed input/error domains are
# NOT independently certified. Unsupported covariance families fail closed.

.etr_joint_mixed_boot_controls<-function(n_bootstrap,random_state,minimum){
  .etr_assert(is.numeric(n_bootstrap)&&length(n_bootstrap)==1L&&
    is.null(dim(n_bootstrap))&&is.finite(n_bootstrap)&&
    n_bootstrap==floor(n_bootstrap)&&
    n_bootstrap>=minimum&&n_bootstrap<=.Machine$integer.max,
    paste("n_bootstrap must be an integer at least",minimum))
  .etr_assert(is.null(random_state)||
    (is.numeric(random_state)&&length(random_state)==1L&&
      is.null(dim(random_state))&&is.finite(random_state)&&
      random_state==floor(random_state)&&random_state>=0&&
      random_state<2^53),
    "random_state must be NULL or an exactly represented nonnegative integer below 2^53")
  if(!is.null(random_state)&&random_state<=.Machine$integer.max)
    random_state<-as.integer(random_state)
  list(n_bootstrap=as.integer(n_bootstrap),random_state=random_state)
}

.etr_joint_mixed_boot_draws<-function(B,N,random_state,sampled){
  if(!is.null(sampled)){
    .etr_assert(is.matrix(sampled)&&is.numeric(sampled)&&
      identical(dim(sampled),c(B,N))&&
      all(is.finite(sampled))&&all(sampled==floor(sampled))&&
      all(sampled>=0L)&&all(sampled<N),
      "sampled_participant_indices must be finite zero-based B-by-participant indices")
    return(list(indices=matrix(as.integer(sampled),B,N),
      engine="caller_supplied_fixed_indices"))
  }
  if(is.null(random_state))
    return(list(indices=matrix(sample.int(N,as.double(B)*N,replace=TRUE)-1L,B,N),
      engine="base_R_unseeded"))
  list(indices=.etr_numpy_seeded_case_indices(random_state,B,N),
    engine="numpy_pcg64")
}

.etr_joint_refit_draw_bundle<-function(bundles,ids,sampled,replicate){
  chosen<-sampled+1L
  selected<-bundles[chosen]
  size<-lengths(selected)
  draw<-seq_along(selected)-1L
  within_draw<-sequence(size)-1L
  participant_ids<-sprintf("bootstrap_%04d_draw_%04d",replicate,draw)
  list(rows=unlist(selected,use.names=FALSE),
    source_ids=ids[chosen],participant_ids=participant_ids,
    membership=rep(participant_ids,times=size),within_draw=within_draw,
    curve_ids=sprintf("b%04d_d%04d_c%04d",replicate,
      rep(draw,times=size),within_draw))
}

.etr_native_mixed_boot_indices<-function(reference,n_bootstrap,
    random_state,sampled_participant_indices){
  .etr_mixed_moments_fit(reference)
  .etr_assert(is.numeric(n_bootstrap)&&length(n_bootstrap)==1L&&
    is.finite(n_bootstrap)&&n_bootstrap==floor(n_bootstrap)&&
    n_bootstrap>=100L&&n_bootstrap<=.Machine$integer.max,
    "n_bootstrap must be an integer at least 100")
  .etr_assert(is.numeric(random_state)&&length(random_state)==1L&&
    is.finite(random_state)&&random_state==floor(random_state)&&
    random_state>=0&&random_state<=.Machine$integer.max,
    "random_state must be a native nonnegative integer")
  n<-reference$n_participants
  B<-as.integer(n_bootstrap)
  if(!is.null(sampled_participant_indices)){
    ix<-sampled_participant_indices
    .etr_assert(is.matrix(ix)&&is.numeric(ix)&&
      identical(dim(ix),c(B,n))&&all(is.finite(ix))&&
      all(ix==floor(ix))&&all(ix>=0)&&all(ix<n),
      "sampled_participant_indices must be zero-based B-by-participant matrix")
    return(matrix(as.integer(ix),nrow=B))
  }
  .etr_seed_scope(as.integer(random_state),function()
    matrix(sample.int(n,B*n,replace=TRUE)-1L,nrow=B,ncol=n))
}

.etr_native_mixed_boot_summary<-function(draws){
  dims<-dim(draws);B<-dims[1L]
  m<-apply(draws,c(2L,3L),mean)
  se<-apply(draws,c(2L,3L),stats::sd)
  list(mean=matrix(m,nrow=dims[2L],ncol=dims[3L]),
    se=matrix(se,nrow=dims[2L],ncol=dims[3L]))
}

#' Participant case bootstrap conditional on native mixed-moments covariance
#'
#' @description This is the *native moments* analogue of the Python
#'   conditional GLS bootstrap. Each independent participant contributes
#'   fixed-grid GLS information and scores under the fixed reference random
#'   intercept and residual covariance (diagonal at each time). The source
#'   Python spline-coefficient MixedLM GLS covariance is NOT reproduced.
#' @param result Converged restricted native mixed-moments fit.
#' @param n_bootstrap Number of participant case replicates >=100.
#' @param random_state Joint likelihood fits use NumPy-compatible PCG64
#'   for exactly represented nonnegative integer seeds below 2^53. NULL
#'   uses ambient base R draws. Native moments fits use base R integer seeds.
#' @param sampled_participant_indices Optional zero-based B-by-participant
#'   retained Python index matrix.
#' @return Native fixed-covariance participant-case coefficient bootstrap.
#' @export
etr_bootstrap_functional_mixed_effects_coefficients<-function(
    result,n_bootstrap=1000L,random_state=0L,
    sampled_participant_indices=NULL,strict_source_record=FALSE){
  .etr_mixed_w3_source_mode(strict_source_record,result,
    sampled_participant_indices)
  if(inherits(result,"etr_joint_bspline_mixed")){
    out<-.etr_joint_fixed_covariance_gls_bootstrap(
      result,n_bootstrap,random_state,sampled_participant_indices)
    if(isTRUE(strict_source_record))
      return(.etr_mixed_w3_coefficients_record(out))
    return(out)
  }
  ix<-.etr_native_mixed_boot_indices(result,n_bootstrap,
    random_state,sampled_participant_indices)
  B<-nrow(ix);G<-ncol(ix)
  X<-result$scalar_design_matrix
  Y<-result$observed_functions
  ids<-result$participant_ids
  group<-result$curve_participant_ids
  p<-ncol(X);nt<-ncol(Y)
  contribution_info<-array(0,c(G,p,p,nt))
  contribution_score<-array(0,c(G,p,nt))
  for(g in seq_len(G)){
    rows<-which(group==ids[g])
    Xg<-X[rows,,drop=FALSE]
    m<-length(rows)
    for(t in seq_len(nt)){
      # Joint covariance for repeat trials at this time:
      # participant random intercept + independent residual variance.
      V<-matrix(result$random_intercept_covariance[t,t],
        nrow=m,ncol=m)+
        diag(result$residual_variance,m)
      .etr_assert(all(is.finite(V))&&min(eigen(V,symmetric=TRUE,
        only.values=TRUE)$values)>0,
        "reference mixed-moments conditional covariance not positive definite")
      VinvX<-solve(V,Xg)
      contribution_info[g,,,t]<-crossprod(Xg,VinvX)
      contribution_score[g,,t]<-crossprod(Xg,
        solve(V,Y[rows,t]))
    }
  }
  draws<-array(0,c(B,p,nt))
  for(b in seq_len(B)){
    sample<-ix[b,]+1L
    for(t in seq_len(nt)){
      info<-matrix(0,p,p);score<-numeric(p)
      for(g in sample){
        info<-info+contribution_info[g,,,t]
        score<-score+contribution_score[g,,t]
      }
      .etr_assert(qr(info)$rank==p,
        paste("conditional participant bootstrap rank failure replicate",b))
      draws[b,,t]<-as.vector(solve(info,score))
    }
  }
  summ<-.etr_native_mixed_boot_summary(draws)
  structure(list(reference=result,
    bootstrap_coefficient_functions=draws,
    bootstrap_fixed_basis_coefficients=NULL,
    sampled_participant_indices=ix,
    bootstrap_mean=summ$mean,
    bootstrap_standard_errors=summ$se,
    random_state=as.integer(random_state),
    covariance_conditioning="native_timewise_fixed_participant_and_residual_covariances",
    provenance=list(
      estimator="native_two_level_moments_timewise_GLS",
      method="participant_cluster_case_bootstrap_fixed_covariance_gls",
      fixed_effects_reestimated_each_replicate=TRUE,
      covariance_components_refit=FALSE,
      full_python_source_contract_equivalent=FALSE,
      full_source_contract_certified=FALSE)),
    class="etr_mixed_moments_conditional_bootstrap")
}

#' Full participant-case re-estimation of native functional mixed moments
#'
#' @description Refit all fixed coefficients, PSD projected participant
#'   covariance and residual variance for each replacement sample. Distinct
#'   sampled occurrences receive new independent participant IDs. This is
#'   not a Python Gaussian spline MixedLM/REML full-refit bootstrap.
#' @param result Converged restricted native mixed-moments fit.
#' @param n_bootstrap Number of full re-estimations >=100.
#' @param random_state Joint likelihood fits use NumPy-compatible PCG64
#'   for exactly represented nonnegative integer seeds below 2^53. NULL
#'   uses ambient base R draws. Native moments fits use base R integer seeds.
#' @param sampled_participant_indices Optional zero-based B-by-participant
#'   fixed source draw index matrix.
#' @return Native full-refit participant bootstrap with covariance audit.
#' @export
etr_bootstrap_functional_mixed_effects_full_refit<-function(
    result,n_bootstrap=1000L,random_state=0L,
    sampled_participant_indices=NULL,strict_source_record=FALSE){
  .etr_mixed_w3_source_mode(strict_source_record,result,
    sampled_participant_indices)
  if(inherits(result,"etr_joint_bspline_mixed")){
    out<-.etr_joint_likelihood_full_refit_bootstrap(
      result,n_bootstrap,random_state,sampled_participant_indices)
    if(isTRUE(strict_source_record))
      return(.etr_mixed_w3_full_refit_record(out))
    return(out)
  }
  ix<-.etr_native_mixed_boot_indices(result,n_bootstrap,
    random_state,sampled_participant_indices)
  B<-nrow(ix);G<-ncol(ix);nt<-length(result$time)
  ids<-result$participant_ids
  group<-result$curve_participant_ids
  bundles<-lapply(ids,function(id)which(group==id))
  p<-ncol(result$scalar_design_matrix)
  draws<-array(0,c(B,p,nt))
  covars<-array(0,c(B,nt,nt))
  rv<-numeric(B)
  source_ids<-vector("list",B)
  new_groups<-vector("list",B)
  ridge<-result$provenance$covariance_ridge
  for(b in seq_len(B)){
    sampled<-ix[b,]+1L
    rows<-unlist(bundles[sampled],use.names=FALSE)
    new_ids<-sprintf("boot_%04d_curve_%05d",b-1L,
      seq_along(rows)-1L)
    cluster_ids<-sprintf("boot_%04d_participant_%04d",b-1L,
      seq_len(G)-1L)
    source_ids[[b]]<-ids[sampled]
    new_groups[[b]]<-cluster_ids
    groups<-rep(cluster_ids,lengths(bundles[sampled]))
    tr<-etr_trajectory_set(result$time,
      array(as.numeric(result$observed_functions[rows,,drop=FALSE]),
        dim=c(length(rows),nt,1L)),
      new_ids,result$dimension_name,
      metadata=data.frame(participant_id=groups),
      coordinate_system="unknown",time_unit=result$time_unit)
    design<-data.frame(curve_id=new_ids)
    for(j in seq_along(result$predictor_names)){
      design[[result$predictor_names[j]]]<-
        result$scalar_design_matrix[rows,j+1L]
    }
    fit<-tryCatch(etr_fit_functional_mixed_effects_regression(
      tr,design,result$predictor_names,
      participant_column="participant_id",
      dimension=result$dimension_name,covariance_ridge=ridge),
      error=function(e)stop(
        paste("native mixed full-refit participant bootstrap replicate",
          b,"failed; no dropped or redrawn replicate:",
          conditionMessage(e)),call.=FALSE))
    draws[b,,]<-fit$coefficient_functions
    covars[b,,]<-fit$random_intercept_covariance
    rv[b]<-fit$residual_variance
  }
  summ<-.etr_native_mixed_boot_summary(draws)
  structure(list(reference=result,
    bootstrap_coefficient_functions=draws,
    bootstrap_fixed_basis_coefficients=NULL,
    random_intercept_covariances=covars,
    residual_variances=rv,
    sampled_participant_indices=ix,
    sampled_source_participant_ids=source_ids,
    sampled_bootstrap_participant_ids=new_groups,
    bootstrap_mean=summ$mean,
    bootstrap_standard_errors=summ$se,
    random_state=as.integer(random_state),
    failure_policy="raise",
    provenance=list(
      estimator="native_two_level_functional_method_of_moments",
      method="whole_participant_case_bootstrap_full_moments_refit",
      covariance_components_refit=TRUE,
      duplicate_participant_draws_receive_distinct_group_ids=TRUE,
      no_failed_replicates_dropped_or_redrawn=TRUE,
      full_python_source_contract_equivalent=FALSE,
      full_source_contract_certified=FALSE)),
    class="etr_mixed_moments_full_refit_bootstrap")
}
