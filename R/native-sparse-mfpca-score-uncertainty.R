# Frozen Python 1.2 sparse_multivariate_score_uncertainty.py
# c1cd95ad718327550f7e55393ff38582872f7a94
# Conditional joint score covariance (not population-estimation uncertainty).
# Strict source model: full repaired covariance, time-major xy,
# two-channel measurement error, regularization and native observation times.

#' Native conditional joint PACE score covariance and uncertainty
#'
#' @description Computes Lambda - Lambda Phi_i' Sigma_i^-1 Phi_i Lambda
#' with complete native-time planar covariance (not rank-k covariance).
#' @param fit Native direct joint sparse MFPCA fit.
#' @param trajectories Aligned native paired irregular samples.
#' @param condition_limit Positive optional score-system condition threshold.
#' @param failure_action "error" or "retain_nan".
#' @return Conditional joint score covariances, standard errors, diagnostics.
#' @export
etr_sparse_mfpca_score_uncertainty_native<-function(fit,trajectories,
    condition_limit=NULL,failure_action="error"){
  .etr_assert(inherits(fit,"etr_sparse_mfpca_source")&&
    identical(fit$fit_method,"direct_sparse_block_covariance")&&
    identical(fit$score_method,"joint_PACE"),
    "fit must be a native direct joint sparse MFPCA/PACE result")
  .etr_irregular_validate_samples(trajectories)
  .etr_assert(identical(as.character(fit$curve_ids),
      as.character(trajectories$curve_ids))&&
    identical(fit$coordinate_system,trajectories$coordinate_system)&&
    identical(fit$time_unit,trajectories$time_unit),
    "joint sparse score uncertainty requires exact curve order and measurement units")
  .etr_assert(is.character(fit$dimensions)&&
    length(fit$dimensions)==2L&&!anyDuplicated(fit$dimensions)&&
    all(fit$dimensions%in%trajectories$dimension_names),
    "joint sparse fit dimensions do not match irregular observations")
  .etr_assert(failure_action%in%c("error","retain_nan"),
    "failure_action must be 'error' or 'retain_nan'")
  source<-fit$provenance$sparse_mfpca
  .etr_assert(is.list(source)&&
    identical(source$backend,"native")&&
    identical(source$score_method,"joint_PACE")&&
    identical(source$operator_storage_order,"channel_major")&&
    identical(source$score_observation_order,
      "time_major_interleaved_xy")&&
    identical(source$rank_k_covariance_used_for_scoring,FALSE),
    "fit provenance does not support full native-time joint PACE uncertainty")
  grid<-.etr_spn_grid(fit$evaluation_grid)
  k<-as.integer(fit$n_components);ng<-length(grid)
  .etr_assert(k>=1L&&is.numeric(fit$eigenvalues)&&
    length(fit$eigenvalues)>=k&&
    all(is.finite(fit$eigenvalues[seq_len(k)]))&&
    all(fit$eigenvalues[seq_len(k)]>=0),
    "retained joint population eigenvalues must be finite nonnegative")
  .etr_assert(is.array(fit$eigenfunctions)&&
    length(dim(fit$eigenfunctions))==3L&&
    dim(fit$eigenfunctions)[1L]>=k&&
    identical(dim(fit$eigenfunctions)[-1L],c(ng,2L))&&
    all(is.finite(fit$eigenfunctions)),
    "joint fitted eigenfunction geometry must be component-by-time-by-channel")
  blocks<-list(cxx=fit$covariance_cxx,cxy=fit$covariance_cxy,
    cyx=fit$covariance_cyx,cyy=fit$covariance_cyy)
  .etr_assert(all(vapply(blocks,function(C)
      is.matrix(C)&&identical(dim(C),c(ng,ng))&&
      all(is.finite(C)),logical(1L)))&&
    max(abs(blocks$cyx-t(blocks$cxy)))<=
      1e-12+1e-10*max(abs(blocks$cxy)),
    "joint fitted covariance blocks must be finite and satisfy Cyx=Cxy^T")
  measurement<-.etr_spnm_error("fixed_matrix",
    covariance=fit$measurement_error_covariance)$covariance
  ridge<-source$score_ridge
  limit<-if(is.null(condition_limit))source$score_condition_limit
    else condition_limit
  .etr_assert(is.numeric(ridge)&&length(ridge)==1L&&
    is.finite(ridge)&&ridge>=0,
    "fitted score_ridge must be finite nonnegative")
  .etr_assert(is.numeric(limit)&&length(limit)==1L&&
    is.finite(limit)&&limit>1,
    "condition_limit must be finite greater than one")
  min_time<-as.integer(source$min_score_time_points)
  .etr_assert(length(min_time)==1L&&min_time>=1L,
    "fitted min_score_time_points must be positive")
  index<-match(fit$dimensions,trajectories$dimension_names)
  for(i in seq_along(trajectories$curve_ids)){
    v<-trajectories$values[[i]][,index,drop=FALSE]
    good1<-is.finite(v[,1L]);good2<-is.finite(v[,2L])
    if(any(xor(good1,good2)))
      .etr_spn_fail("coordinate_specific_missingness_unsupported",
        "native joint score observations require paired finite channels")
    if(any(!(good1&good2)))
      .etr_spn_fail("nonfinite_sparse_planar_observation",
        "joint observations must be finite")
  }
  action<-source$analysis_support_action
  .etr_assert(action%in%c("error","restrict"),
    "fit analysis_support_action must be error or restrict")
  masks<-lapply(trajectories$time,
    function(t)t>=grid[1L]&t<=tail(grid,1L))
  if(identical(action,"error")&&any(vapply(masks,
      function(x)any(!x),logical(1L))))
    .etr_spn_fail("observations_outside_analysis_support",
      "joint uncertainty observation times exceed fit support")
  times<-if(identical(action,"restrict"))
    Map(function(t,m)t[m],trajectories$time,masks)
      else trajectories$time
  counts<-as.integer(lengths(times))
  .etr_assert(identical(counts,
    as.integer(source$analysis_sample_counts)),
    "joint uncertainty observations do not reproduce fitted analysis sample counts")
  prior<-diag(fit$eigenvalues[seq_len(k)],nrow=k)
  tol<-1e-10*max(1,max(abs(fit$eigenvalues[seq_len(k)])))
  n<-length(times)
  posterior<-array(NaN,c(n,k,k))
  stderr<-matrix(NaN,n,k)
  diag_rows<-vector("list",n)
  for(i in seq_len(n)){
    tt<-times[[i]];nt<-length(tt)
    status<-"ok";solve_status<-"not_attempted"
    condition<-low<-high<-post_low<-solve_relative<-NaN
    repaired<-FALSE
    if(nt<min_time)
      status<-"curve_too_sparse_for_joint_score_system"
    else{
      status<-tryCatch({
        xx<-.etr_spnm_interp(grid,blocks$cxx,tt)
        xy<-.etr_spnm_interp(grid,blocks$cxy,tt)
        yy<-.etr_spnm_interp(grid,blocks$cyy,tt)
        channel<-rbind(cbind(xx,xy),cbind(t(xy),yy))
        perm<-as.vector(rbind(seq_len(nt),nt+seq_len(nt)))
        C<-channel[perm,perm,drop=FALSE]
        Sigma<-C+kronecker(diag(nt),measurement)+
          diag(ridge,2L*nt)
        Sigma<-(Sigma+t(Sigma))/2
        eigenvalues<-eigen(Sigma,symmetric=TRUE,only.values=TRUE)$values
        low<-min(eigenvalues);high<-max(eigenvalues)
        condition<-if(low<=0)Inf else high/low
        if(low<=0)"joint_score_covariance_not_positive_definite"
        else if(condition>limit)"joint_score_covariance_ill_conditioned"
        else{
          Phi<-matrix(NA_real_,2L*nt,k)
          for(j in seq_len(k)){
            pointwise<-rbind(
              .etr_spn_eval(grid,fit$eigenfunctions[j,,1L],tt),
              .etr_spn_eval(grid,fit$eigenfunctions[j,,2L],tt))
            Phi[,j]<-as.vector(pointwise)
          }
          rhs<-Phi%*%prior
          solved<-tryCatch(solve(Sigma,rhs),error=function(e)NULL)
          if(is.null(solved))"joint_score_covariance_solve_failed"
          else{
            solve_relative<-sqrt(sum((Sigma%*%solved-rhs)^2))/
              max(1,sqrt(sum(rhs^2)))
            P<-prior-crossprod(rhs,solved)
            P<-(P+t(P))/2
            e<-eigen(P,symmetric=TRUE)
            post_low<-min(e$values)
            if(post_low< -tol)
              "conditional_joint_score_covariance_not_psd"
            else{
              if(post_low<0){
                P<-e$vectors%*%diag(pmax(e$values,0),nrow=k)%*%
                  t(e$vectors)
                P<-(P+t(P))/2
                repaired<-TRUE
              }
              posterior[i,,]<-P
              stderr[i,]<-sqrt(pmax(diag(P),0))
              solve_status<-"solved"
              "ok"
            }
          }
        }
      },error=function(e){
        if(grepl("native_time_outside_fitted_support",
            conditionMessage(e),fixed=TRUE))
          "native_time_outside_fitted_support"
        else stop(e)
      })
    }
    fitted_status<-if(is.data.frame(fit$score_diagnostics)&&
      all(c("curve_id","status_code")%in%
        names(fit$score_diagnostics))){
      match_status<-match(as.character(fit$curve_ids[i]),
        as.character(fit$score_diagnostics$curve_id))
      if(is.na(match_status))"unknown"
      else as.character(fit$score_diagnostics$status_code[match_status])
    }else"unknown"
    diag_rows[[i]]<-data.frame(
      curve_id=fit$curve_ids[i],
      n_time_points=nt,n_planar_observations=2L*nt,
      status_code=status,fit_score_status=fitted_status,
      solve_status=solve_status,condition_number=condition,
      minimum_eigenvalue=low,maximum_eigenvalue=high,
      posterior_minimum_eigenvalue=post_low,
      posterior_psd_repair_applied=repaired,
      solve_relative_residual=solve_relative,
      score_ridge=ridge,condition_limit=limit,
      observation_order="time_major_interleaved_xy",
      stringsAsFactors=FALSE)
  }
  audit<-do.call(rbind,diag_rows)
  if(failure_action=="error"&&any(audit$status_code!="ok")){
    ii<-which(audit$status_code!="ok")[1L]
    .etr_spn_score_fail(audit,ii,
      paste("conditional joint PACE uncertainty failed for curve",
        fit$curve_ids[ii]))
  }
  method<-"conditional_gaussian_given_fitted_joint_population"
  provenance<-list(
    method=method,
    covariance_source=
      "full_fitted_joint_covariance_plus_measurement_error_and_declared_score_ridge",
    fitted_covariance_source=
      "SparseMFPCAResult.covariance_cxx/cxy/cyx/cyy",
    fitted_measurement_error_source=
      "SparseMFPCAResult.measurement_error_covariance",
    eigensystem_source=
      "SparseMFPCAResult.eigenvalues_and_eigenfunctions",
    operator_storage_order="channel_major",
    score_observation_order="time_major_interleaved_xy",
    ordering_permutation_applied=TRUE,
    native_observation_times=TRUE,
    raw_sparse_trajectory_interpolation_performed=FALSE,
    rank_k_covariance_used_for_uncertainty=FALSE,
    score_ridge=ridge,condition_limit=limit,
    condition_limit_source=if(is.null(condition_limit))
      "fitted_score_condition_limit"else"explicit_override",
    failure_action=failure_action,
    posterior_psd_tolerance=tol,
    population_estimation_uncertainty_included=FALSE,
    mean_estimation_uncertainty_included=FALSE,
    covariance_estimation_uncertainty_included=FALSE,
    eigensystem_estimation_uncertainty_included=FALSE,
    measurement_error_specification_uncertainty_included=FALSE,
    bandwidth_uncertainty_included=FALSE,
    asynchronous_channel_grids_supported=FALSE)
  structure(list(reference=fit,curve_ids=fit$curve_ids,
    covariance=posterior,standard_errors=stderr,diagnostics=audit,
    n_components=k,method=method,provenance=provenance,
    source_python_full_contract_certified=FALSE,
    independent_full_source_certified=FALSE),
    class="etr_sparse_mfpca_score_uncertainty_native")
}

#' Native tidy conditional joint PACE score uncertainty
#' @param result Native conditional joint sparse PACE uncertainty.
#' @return Source-shaped tidy per-curve per-component frame.
#' @export
etr_sparse_mfpca_score_uncertainty_frame_native<-function(result){
  .etr_assert(inherits(result,"etr_sparse_mfpca_score_uncertainty_native"),
    "result must be native conditional joint PACE uncertainty")
  rows<-vector("list",length(result$curve_ids)*result$n_components)
  z<-1L
  for(i in seq_along(result$curve_ids))
    for(j in seq_len(result$n_components)){
      rows[[z]]<-data.frame(
        curve_id=as.character(result$curve_ids[i]),
        component=j,
        score=as.numeric(result$reference$scores[i,j]),
        conditional_variance=as.numeric(result$covariance[i,j,j]),
        conditional_se=as.numeric(result$standard_errors[i,j]),
        status_code=as.character(result$diagnostics$status_code[i]),
        fit_score_status=as.character(
          result$diagnostics$fit_score_status[i]),
        condition_number=as.numeric(
          result$diagnostics$condition_number[i]),
        method=result$method,
        stringsAsFactors=FALSE)
      z<-z+1L
    }
  do.call(rbind,rows)
}
