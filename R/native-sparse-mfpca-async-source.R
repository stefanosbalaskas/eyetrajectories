# Exact-union asynchronous source-model PACE composition.
# Frozen Python 1.2 sparse_multivariate_async.py:
# c1cd95ad718327550f7e55393ff38582872f7a94
# No raw curve interpolation, nearest-neighbour synchronization or binning.

#' Native direct asynchronous sparse multivariate FPCA and PACE
#'
#' @description Fits direct directional x/y cross-covariance from coordinate-
#' specific native grids with NaN representing an unobserved channel at each
#' union timestamp, preserving the statistical estimand of frozen Python 1.2.
#' Cross-coordinate products within declared same-time tolerance are excluded
#' from the latent covariance; cross-channel measurement noise is included
#' only for simultaneous scalar observations during full-covariance PACE.
#' @param trajectories Native irregular trajectories with exact union timestamps.
#' @param dimensions Two dimension names for x and y channels.
#' @param n_components Positive retained joint component count.
#' @param evaluation_grid Population covariance fitting grid, not raw imputation.
#' @param mean_bandwidth,covariance_bandwidth Positive kernel bandwidths.
#' @param measurement_error "diagonal" or "fixed_matrix".
#' @param measurement_error_variance Two nonnegative diagonal noise variances.
#' @param measurement_error_covariance Symmetric PSD two-by-two noise matrix.
#' @param analysis_support_action "error" or "restrict".
#' @param same_time_tolerance Nonnegative simultaneity time tolerance.
#' @param psd_action "error" or "project".
#' @param psd_tolerance,positive_eigen_tolerance Nonnegative tolerances.
#' @param score_ridge Nonnegative PACE regularization.
#' @param score_condition_limit Positive conditioning ceiling greater than one.
#' @param min_score_observations Minimum scalar observations per curve.
#' @param score_failure_action "error" or "retain_nan".
#' @param mean_min_local_points,covariance_min_local_pairs Minimum local support.
#' @return Native joint sparse asynchronous FPCA result with numerical audits.
#' @export
etr_fit_sparse_mfpca_async_native<-function(
    trajectories,dimensions=c("x","y"),n_components,
    evaluation_grid,mean_bandwidth,covariance_bandwidth,
    measurement_error,measurement_error_variance=NULL,
    measurement_error_covariance=NULL,
    analysis_support_action="error",same_time_tolerance=0,
    psd_action="error",psd_tolerance=1e-8,
    positive_eigen_tolerance=1e-10,
    score_ridge=0,score_condition_limit=1e12,
    min_score_observations=2L,score_failure_action="error",
    mean_min_local_points=3L,covariance_min_local_pairs=6L){
  .etr_assert(is.numeric(n_components)&&length(n_components)==1L&&
    !is.logical(n_components)&&is.finite(n_components)&&
    n_components>=1L&&n_components==floor(n_components),
    "n_components must be positive integer")
  .etr_assert(is.numeric(mean_bandwidth)&&
    length(mean_bandwidth)==1L&&is.finite(mean_bandwidth)&&
    mean_bandwidth>0&&is.numeric(covariance_bandwidth)&&
    length(covariance_bandwidth)==1L&&
    is.finite(covariance_bandwidth)&&covariance_bandwidth>0,
    "mean_bandwidth and covariance_bandwidth must be finite positive")
  .etr_assert(is.numeric(same_time_tolerance)&&
    length(same_time_tolerance)==1L&&
    is.finite(same_time_tolerance)&&same_time_tolerance>=0,
    "same_time_tolerance must be finite nonnegative")
  .etr_assert(psd_action%in%c("error","project")&&
    score_failure_action%in%c("error","retain_nan"),
    "unsupported async PSD or score failure action")
  for(z in list(psd_tolerance,positive_eigen_tolerance,score_ridge)){
    .etr_assert(is.numeric(z)&&length(z)==1L&&
      is.finite(z)&&z>=0,
      "joint PSD tolerances and ridge must be finite nonnegative")
  }
  .etr_assert(is.numeric(score_condition_limit)&&
    length(score_condition_limit)==1L&&
    is.finite(score_condition_limit)&&score_condition_limit>1,
    "score_condition_limit must be finite and >1")
  for(z in list(min_score_observations,mean_min_local_points,
      covariance_min_local_pairs)){
    .etr_assert(is.numeric(z)&&length(z)==1L&&
      !is.logical(z)&&is.finite(z)&&z==floor(z)&&z>=1L,
      "minimum scalar observations / smoothing support must be positive integers")
  }
  .etr_assert(mean_min_local_points>=3L&&
    covariance_min_local_pairs>=3L,
    "local-linear smoothing requires sufficient mean and covariance support")
  grid<-.etr_spn_grid(evaluation_grid)
  resolved<-.etr_spnm_error(measurement_error,
    measurement_error_variance,measurement_error_covariance)
  v<-.etr_spna_views(trajectories,dimensions,grid,
    analysis_support_action)
  tx<-unlist(v$tx,use.names=FALSE)
  xv<-unlist(v$xv,use.names=FALSE)
  ty<-unlist(v$ty,use.names=FALSE)
  yv<-unlist(v$yv,use.names=FALSE)
  meanx<-.etr_spn_mean(tx,xv,grid,mean_bandwidth,
    mean_min_local_points)
  meany<-.etr_spn_mean(ty,yv,grid,mean_bandwidth,
    mean_min_local_points)
  rx<-vector("list",length(v$tx));ry<-vector("list",length(v$ty))
  for(i in seq_along(v$tx)){
    rx[[i]]<-if(length(v$tx[[i]]))v$xv[[i]]-
      .etr_spn_mean(tx,xv,v$tx[[i]],mean_bandwidth,
        mean_min_local_points)$values else numeric()
    ry[[i]]<-if(length(v$ty[[i]]))v$yv[[i]]-
      .etr_spn_mean(ty,yv,v$ty[[i]],mean_bandwidth,
        mean_min_local_points)$values else numeric()
  }
  pairs<-.etr_spna_cross_pairs(
    v$tx,rx,v$ty,ry,same_time_tolerance)
  xx<-.etr_spnm_surface(pairs$xx,grid,covariance_bandwidth,
    as.integer(covariance_min_local_pairs))
  xy<-.etr_spnm_surface(pairs$xy,grid,covariance_bandwidth,
    as.integer(covariance_min_local_pairs),cross=TRUE)
  yy<-.etr_spnm_surface(pairs$yy,grid,covariance_bandwidth,
    as.integer(covariance_min_local_pairs))
  operator<-.etr_spnm_operator(list(
    xx=xx$values,xy=xy$values,yy=yy$values),
    grid,psd_action,psd_tolerance)
  eig<-.etr_spnm_eigen(operator$matrix,grid,
    as.integer(n_components),positive_eigen_tolerance)
  mean<-cbind(meanx$values,meany$values)
  scored<-.etr_spna_pace(trajectories$curve_ids,v,grid,
    mean,operator$covariance,eig,
    resolved$covariance,same_time_tolerance,
    score_ridge,score_condition_limit,
    as.integer(min_score_observations),score_failure_action)
  source<-list(
    backend="native",fit_method="direct_async_sparse_block_covariance",
    score_method="asynchronous_joint_PACE",
    dimensions=dimensions,n_components=as.integer(n_components),
    component_rank_rule="positive_fitted_joint_operator_spectrum",
    input_representation="exact_union_of_native_coordinate_timestamps",
    coordinate_specific_missingness_supported=TRUE,
    mean_bandwidth=mean_bandwidth,
    covariance_bandwidth=covariance_bandwidth,
    analysis_support=range(grid),
    analysis_support_action=analysis_support_action,
    same_time_tolerance=same_time_tolerance,
    cross_covariance_same_time_products_excluded=TRUE,
    cross_covariance_same_time_pair_count_excluded=
      pairs$audit$cross_same_time_pair_count_excluded,
    measurement_error_independent_across_distinct_times_assumed=TRUE,
    measurement_error_cross_covariance_scope="simultaneous_xy_only",
    yx_estimated_independently=FALSE,
    cross_covariance_self_symmetrized=FALSE,
    score_observation_order=
      "time_major_x_before_y_for_ties",
    paired_reduction_order="time_major_interleaved_xy",
    score_covariance_source=
      "full_fitted_joint_covariance_plus_async_measurement_error",
    rank_k_covariance_used_for_scoring=FALSE,
    measurement_error_mode=measurement_error,
    measurement_error_covariance=resolved$covariance,
    measurement_error_covariance_eigenvalues=resolved$eigenvalues,
    measurement_error_covariance_symmetry_error=resolved$symmetry_error,
    psd_action=psd_action,psd_tolerance=psd_tolerance,
    positive_eigen_tolerance=positive_eigen_tolerance,
    score_ridge=score_ridge,
    score_condition_limit=score_condition_limit,
    min_score_observations=as.integer(min_score_observations),
    score_failure_action=score_failure_action,
    mean_min_local_points=as.integer(mean_min_local_points),
    covariance_min_local_pairs=as.integer(covariance_min_local_pairs),
    raw_sparse_trajectory_interpolation_performed=FALSE,
    nearest_neighbour_synchronization_performed=FALSE,
    time_binning_performed=FALSE,
    population_function_evaluation_at_native_times=TRUE,
    automatic_bandwidth_selection_performed=FALSE,
    cross_channel_covariance_modeled=TRUE,
    covariance_psd=operator$audit)
  provenance<-trajectories$provenance
  provenance$sparse_mfpca_async<-source
  structure(list(
    scores=scored$scores,eigenvalues=eig$eigenvalues,
    eigenfunctions=eig$eigenfunctions,
    mean=mean,evaluation_grid=grid,dimensions=dimensions,
    curve_ids=trajectories$curve_ids,
    metadata=trajectories$metadata,
    coordinate_system=trajectories$coordinate_system,
    time_unit=trajectories$time_unit,
    n_components=as.integer(n_components),
    quadrature_weights=eig$quadrature_weights,
    smoothed_cxx=operator$smoothed$cxx,
    smoothed_cxy=operator$smoothed$cxy,
    smoothed_cyx=operator$smoothed$cyx,
    smoothed_cyy=operator$smoothed$cyy,
    covariance_cxx=operator$covariance$cxx,
    covariance_cxy=operator$covariance$cxy,
    covariance_cyx=operator$covariance$cyx,
    covariance_cyy=operator$covariance$cyy,
    measurement_error_covariance=resolved$covariance,
    score_diagnostics=scored$diagnostics,
    mean_support_counts=cbind(
      meanx$support_counts,meany$support_counts),
    covariance_support_counts=list(
      cxx=xx$support_counts,cxy=xy$support_counts,
      cyy=yy$support_counts),
    covariance_pair_counts=as.list(pairs$pair_counts),
    covariance_diagnostics=operator$audit,
    support_diagnostics=c(v$support,pairs$audit),
    fit_method="direct_async_sparse_block_covariance",
    score_method="asynchronous_joint_PACE",provenance=provenance,
    independent_full_source_certified=FALSE,
    source_python_full_domain_approved=FALSE),
    class="etr_sparse_mfpca_async_source")
}
