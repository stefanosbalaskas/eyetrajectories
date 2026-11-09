# Frozen eyetrajectoriespy 1.2 sparse_multivariate.py::fit_sparse_mfpca
# jointly observed two-channel irregular time series. Explicit source-mode
# alternative to the existing marginal fdapace score-PCA backend.
# Source estimand: direct offdiagonal cross-covariance and joint-PACE scores.

#' Fit a native direct sparse multivariate FPCA joint PACE model
#'
#' @description Two jointly observed irregular dimensions, direct
#' cross-channel covariance surface smoothing, weighted PSD joint
#' covariance, and full-fitted-covariance PACE scoring.
#' @param trajectories Native irregular trajectory set with >=3 curves.
#' @param dimensions Exactly two jointly observed dimensions.
#' @param n_components Positive joint covariance component count.
#' @param evaluation_grid Explicit population grid.
#' @param mean_bandwidth,covariance_bandwidth Positive bandwidths.
#' @param measurement_error "diagonal" or "fixed_matrix".
#' @param measurement_error_variance Two fixed nonnegative noise variances.
#' @param measurement_error_covariance Optional symmetric PSD 2x2 matrix.
#' @param analysis_support_action "error" or "restrict".
#' @param psd_action "error" or "project".
#' @param psd_tolerance,positive_eigen_tolerance Nonnegative tolerances.
#' @param score_ridge Nonnegative regularizer in joint PACE covariance.
#' @param score_condition_limit Finite condition number ceiling >1.
#' @param min_score_time_points Minimum native observation times for scoring.
#' @param score_failure_action "error" or "retain_nan".
#' @param mean_min_local_points,covariance_min_local_pairs Local support.
#' @return Source-shaped joint sparse FPCA with covariance blocks and audit.
#' @export
etr_fit_sparse_mfpca_native<-function(
    trajectories,dimensions=c("x","y"),n_components=2L,
    evaluation_grid,mean_bandwidth,covariance_bandwidth,
    measurement_error="diagonal",measurement_error_variance=NULL,
    measurement_error_covariance=NULL,
    analysis_support_action="error",psd_action="error",
    psd_tolerance=1e-8,positive_eigen_tolerance=1e-10,
    score_ridge=0,score_condition_limit=1e12,
    min_score_time_points=2L,score_failure_action="error",
    mean_min_local_points=3L,covariance_min_local_pairs=6L){
  .etr_irregular_validate_samples(trajectories)
  .etr_assert(is.character(dimensions)&&length(dimensions)==2L&&
    !anyNA(dimensions)&&!anyDuplicated(dimensions)&&
    all(dimensions%in%trajectories$dimension_names),
    "dimensions must identify two distinct planar observation channels")
  .etr_assert(length(trajectories$curve_ids)>=3L,
    "insufficient_joint_support: need >=3 curves")
  .etr_assert(is.numeric(n_components)&&length(n_components)==1L&&
    is.finite(n_components)&&n_components==floor(n_components)&&
    n_components>=1L,
    "n_components must be a positive integer")
  k<-as.integer(n_components)
  .etr_assert(is.numeric(mean_bandwidth)&&
    length(mean_bandwidth)==1L&&is.finite(mean_bandwidth)&&
    mean_bandwidth>0&&
    is.numeric(covariance_bandwidth)&&
    length(covariance_bandwidth)==1L&&is.finite(covariance_bandwidth)&&
    covariance_bandwidth>0,
    "joint PACE bandwidths must be finite positive")
  .etr_assert(is.numeric(mean_min_local_points)&&
    length(mean_min_local_points)==1L&&
    is.finite(mean_min_local_points)&&
    mean_min_local_points==floor(mean_min_local_points)&&
    mean_min_local_points>=2L&&
    is.numeric(covariance_min_local_pairs)&&
    length(covariance_min_local_pairs)==1L&&
    is.finite(covariance_min_local_pairs)&&
    covariance_min_local_pairs==floor(covariance_min_local_pairs)&&
    covariance_min_local_pairs>=3L,
    "local support controls must be positive integers")
  .etr_assert(is.numeric(min_score_time_points)&&
    length(min_score_time_points)==1L&&
    is.finite(min_score_time_points)&&
    min_score_time_points==floor(min_score_time_points)&&
    min_score_time_points>=1L,
    "min_score_time_points must be positive integer")
  .etr_assert(score_failure_action%in%c("error","retain_nan"),
    "score_failure_action must be error or retain_nan")
  .etr_assert(is.numeric(score_condition_limit)&&
    length(score_condition_limit)==1L&&
    is.finite(score_condition_limit)&&score_condition_limit>1,
    "score_condition_limit must be finite greater than one")
  .etr_assert(is.numeric(score_ridge)&&length(score_ridge)==1L&&
    is.finite(score_ridge)&&score_ridge>=0,
    "score_ridge must be finite nonnegative")
  .etr_assert(is.numeric(positive_eigen_tolerance)&&
    length(positive_eigen_tolerance)==1L&&
    is.finite(positive_eigen_tolerance)&&
    positive_eigen_tolerance>=0,
    "positive_eigen_tolerance must be finite nonnegative")
  resolved<-.etr_spnm_error(measurement_error,
    measurement_error_variance,measurement_error_covariance)
  grid<-.etr_spn_grid(evaluation_grid)
  orig<-trajectories$time
  left<-min(vapply(orig,function(t)t[1L],numeric(1L)))
  right<-max(vapply(orig,function(t)tail(t,1L),numeric(1L)))
  tol<-1e-12*max(1,abs(left),abs(right))
  if(grid[1L]<left-tol||tail(grid,1L)>right+tol)
    .etr_spn_fail("evaluation_grid_outside_pooled_support",
      "joint sparse grid extends beyond observed pooled times")
  idx<-match(dimensions,trajectories$dimension_names)
  for(i in seq_along(trajectories$curve_ids)){
    v<-trajectories$values[[i]][,idx,drop=FALSE]
    both<-is.finite(v[,1L])&is.finite(v[,2L])
    if(any(xor(is.finite(v[,1L]),is.finite(v[,2L]))))
      .etr_spn_fail("coordinate_specific_missingness_unsupported",
        "jointly observed channels must have matching finite samples")
    if(any(!both))
      .etr_spn_fail("nonfinite_sparse_planar_observation",
        "joint observations must be finite")
  }
  .etr_assert(analysis_support_action%in%c("error","restrict"),
    "analysis_support_action must be error or restrict")
  masks<-lapply(orig,function(t)t>=grid[1L]&t<=tail(grid,1L))
  out_counts<-as.integer(vapply(masks,function(z)sum(!z),integer(1L)))
  if(analysis_support_action=="error"&&any(out_counts>0L))
    .etr_spn_fail("observations_outside_analysis_support",
      "raw joint observations lie outside population grid")
  times<-if(analysis_support_action=="restrict")
    Map(function(t,m)t[m],orig,masks)else orig
  observed<-lapply(seq_along(orig),function(i){
    v<-trajectories$values[[i]][,idx,drop=FALSE]
    if(analysis_support_action=="restrict")
      v[masks[[i]],,drop=FALSE]else v
  })
  if(sum(lengths(times))<3L)
    .etr_spn_fail("insufficient_joint_support",
      "fewer than three retained planar observations")
  t_pool<-unlist(times,use.names=FALSE)
  x_pool<-unlist(lapply(observed,function(z)z[,1L]),use.names=FALSE)
  y_pool<-unlist(lapply(observed,function(z)z[,2L]),use.names=FALSE)
  mx<-.etr_spn_mean(t_pool,x_pool,grid,mean_bandwidth,
    mean_min_local_points)
  my<-.etr_spn_mean(t_pool,y_pool,grid,mean_bandwidth,
    mean_min_local_points)
  residual_x<-vector("list",length(times))
  residual_y<-vector("list",length(times))
  for(i in seq_along(times)){
    ti<-times[[i]]
    if(!length(ti)){
      residual_x[[i]]<-numeric()
      residual_y[[i]]<-numeric()
    }else{
      residual_x[[i]]<-observed[[i]][,1L]-
        .etr_spn_mean(t_pool,x_pool,ti,mean_bandwidth,
          mean_min_local_points)$values
      residual_y[[i]]<-observed[[i]][,2L]-
        .etr_spn_mean(t_pool,y_pool,ti,mean_bandwidth,
          mean_min_local_points)$values
    }
  }
  pairs<-.etr_spnm_pairs(times,residual_x,residual_y)
  xx<-.etr_spnm_surface(pairs$xx,grid,covariance_bandwidth,
    covariance_min_local_pairs)
  xy<-.etr_spnm_surface(pairs$xy,grid,covariance_bandwidth,
    covariance_min_local_pairs,cross=TRUE)
  yy<-.etr_spnm_surface(pairs$yy,grid,covariance_bandwidth,
    covariance_min_local_pairs)
  joint<-.etr_spnm_operator(
    list(xx=xx$values,xy=xy$values,yy=yy$values),
    grid,psd_action,psd_tolerance)
  eig<-.etr_spnm_eigen(joint$matrix,grid,k,
    positive_eigen_tolerance)
  mean<-cbind(mx$values,my$values)
  scored<-.etr_spnm_score(trajectories$curve_ids,times,
    observed,grid,mean,joint$covariance,
    eig,resolved$covariance,score_ridge,
    score_condition_limit,as.integer(min_score_time_points),
    score_failure_action)
  support<-list(
    analysis_support=range(grid),
    analysis_support_action=analysis_support_action,
    original_sample_counts=as.integer(lengths(orig)),
    analysis_sample_counts=as.integer(lengths(times)),
    outside_observation_count=sum(out_counts),
    outside_counts_by_curve=out_counts)
  prov<-c(list(
    backend="native",fit_method="direct_sparse_block_covariance",
    score_method="joint_PACE",dimensions=dimensions,
    n_components=k,
    component_rank_rule="positive_fitted_joint_operator_spectrum",
    mean_bandwidth=mean_bandwidth,
    covariance_bandwidth=covariance_bandwidth),
    support,list(
    same_time_covariance_products_excluded=TRUE,
    cross_covariance_same_time_products_excluded=TRUE,
    measurement_error_independent_across_time_assumed=TRUE,
    yx_estimated_independently=FALSE,
    cross_covariance_self_symmetrized=FALSE,
    operator_storage_order="channel_major",
    score_observation_order="time_major_interleaved_xy",
    ordering_permutation_applied=TRUE,
    score_covariance_source=
      "full_fitted_joint_covariance_plus_measurement_error",
    rank_k_covariance_used_for_scoring=FALSE,
    measurement_error_mode=measurement_error,
    measurement_error_covariance=resolved$covariance,
    measurement_error_covariance_eigenvalues=resolved$eigenvalues,
    measurement_error_covariance_symmetry_error=resolved$symmetry_error,
    psd_action=psd_action,psd_tolerance=psd_tolerance,
    positive_eigen_tolerance=positive_eigen_tolerance,
    score_ridge=score_ridge,
    score_condition_limit=score_condition_limit,
    min_score_time_points=as.integer(min_score_time_points),
    score_failure_action=score_failure_action,
    mean_min_local_points=as.integer(mean_min_local_points),
    covariance_min_local_pairs=as.integer(covariance_min_local_pairs),
    raw_sparse_trajectory_interpolation_performed=FALSE,
    population_function_evaluation_at_native_times=TRUE,
    automatic_bandwidth_selection_performed=FALSE,
    cross_channel_covariance_modeled=TRUE,
    covariance_psd=joint$audit))
  provenance<-trajectories$provenance
  provenance$sparse_mfpca<-prov
  structure(list(
    scores=scored$scores,joint_scores=scored$scores,
    eigenvalues=eig$eigenvalues,
    eigenfunctions=eig$eigenfunctions,
    mean=mean,evaluation_grid=grid,
    dimensions=dimensions,curve_ids=trajectories$curve_ids,
    metadata=trajectories$metadata,
    coordinate_system=trajectories$coordinate_system,
    time_unit=trajectories$time_unit,n_components=k,
    quadrature_weights=eig$quadrature_weights,
    smoothed_cxx=joint$smoothed$cxx,
    smoothed_cxy=joint$smoothed$cxy,
    smoothed_cyx=joint$smoothed$cyx,
    smoothed_cyy=joint$smoothed$cyy,
    covariance_cxx=joint$covariance$cxx,
    covariance_cxy=joint$covariance$cxy,
    covariance_cyx=joint$covariance$cyx,
    covariance_cyy=joint$covariance$cyy,
    measurement_error_covariance=resolved$covariance,
    score_diagnostics=scored$diagnostics,
    mean_support_counts=cbind(mx$support_counts,my$support_counts),
    covariance_support_counts=list(
      cxx=xx$support_counts,cxy=xy$support_counts,
      cyy=yy$support_counts),
    covariance_pair_counts=as.list(pairs$counts),
    covariance_diagnostics=joint$audit,
    fit_method="direct_sparse_block_covariance",
    score_method="joint_PACE",provenance=provenance,
    source_python_full_contract_equivalent=FALSE,
    independently_fully_certified=FALSE),
    class=c("etr_sparse_mfpca_source","etr_native_sparse_mfpca"))
}
