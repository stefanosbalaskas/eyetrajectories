# Native sparse univariate FPCA/PACE and conditional-score Gaussian
# uncertainty. Frozen Python 1.2 sparse_native.py/sparse_score_uncertainty.py
# at c1cd95ad718327550f7e55393ff38582872f7a94.
# Scientifically matched numerical laws for declared fixed-noise subsets.
# No fdapace, no Python bridge, no full-contract or independent certification.

#' Native local-smoothing sparse FPCA with full-covariance PACE
#'
#' @description Implements Epanechnikov local-linear mean and off-diagonal
#' covariance estimation, weighted PSD operator repair, eigenfunction
#' normalization, and full-fitted-covariance PACE scoring on the original
#' sparse observation times. No raw-data interpolation or dense imputation.
#' Supports both explicit fixed measurement-error variance and the source
#' diagonal-difference estimator with a 45-degree rotated local-quadratic
#' latent covariance diagonal and declared noise support.
#' @param trajectories Native irregular trajectory set.
#' @param dimension One observed finite response dimension.
#' @param n_components Number of positive fitted covariance components.
#' @param evaluation_grid Finite strictly increasing population grid.
#' @param mean_bandwidth,covariance_bandwidth Positive local kernel bandwidths.
#' @param noise_bandwidth,noise_support Local bandwidth and integration
#'   interval for diagonal-difference measurement noise.
#' @param noise_variance_method "diagonal_difference" or "fixed".
#'   Supplying a measurement-error variance without a method selects
#'   "fixed" for compatibility with earlier native calls.
#' @param measurement_error_variance Declared nonnegative observation noise.
#' @param noise_min_local_points Minimum observations for noise smoothing.
#' @param analysis_support_action "error" or "restrict" raw samples to grid.
#' @param psd_action "error" or "project" weighted covariance operator.
#' @param psd_tolerance,positive_eigen_tolerance Numerical eigen tolerances.
#' @param score_ridge Fixed nonnegative PACE regularizer.
#' @param score_condition_limit Maximum supported condition number.
#' @param min_score_samples Minimum samples per curve.
#' @param score_failure_action "error" or "retain_nan".
#' @param mean_min_local_points,covariance_min_local_pairs Smoothing support.
#' @param mean_smoother,covariance_smoother Source smoothing names. Both must
#'   be "local_linear".
#' @param kernel Source kernel name. Must be "epanechnikov".
#' @return Source-shaped sparse FPCA list with numerical diagnostics.
#' @export
etr_fit_sparse_fpca_native<-function(
    trajectories,dimension,n_components,evaluation_grid,
    mean_bandwidth,covariance_bandwidth,
    noise_bandwidth=NULL,noise_support=NULL,
    noise_variance_method=if(is.null(measurement_error_variance))
      "diagonal_difference" else "fixed",measurement_error_variance=NULL,
    noise_min_local_points=3L,
    analysis_support_action="error",psd_action="error",
    psd_tolerance=1e-8,positive_eigen_tolerance=1e-10,
    score_ridge=0,score_condition_limit=1e12,
    min_score_samples=2L,score_failure_action="error",
    mean_min_local_points=3L,covariance_min_local_pairs=6L,
    mean_smoother="local_linear",covariance_smoother="local_linear",
    kernel="epanechnikov"){
  .etr_irregular_validate_samples(trajectories)
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    dimension%in%trajectories$dimension_names,
    "dimension must identify a source irregular channel")
  n_curves<-length(trajectories$curve_ids)
  if(n_curves<3L)
    .etr_spn_fail("insufficient_pooled_support",
      "native sparse FPCA requires at least three curves",list(n_curves=n_curves))
  .etr_assert(is.numeric(n_components)&&length(n_components)==1L&&
    !is.logical(n_components)&&is.finite(n_components)&&
    n_components==floor(n_components)&&n_components>=1L,
    "n_components must be positive integer")
  k<-as.integer(n_components)
  .etr_sparse_smoothing_settings(mean_smoother,covariance_smoother,kernel)
  .etr_assert(noise_variance_method%in%
    c("fixed","diagonal_difference"),
    "noise_variance_method must be fixed or diagonal_difference")
  if(identical(noise_variance_method,"fixed")){
    .etr_assert(is.numeric(measurement_error_variance)&&
      length(measurement_error_variance)==1L&&
      is.finite(measurement_error_variance)&&
      measurement_error_variance>=0,
      "measurement_error_variance must be finite and nonnegative")
    .etr_assert(is.null(noise_support),
      "noise_support must be NULL for fixed measurement error")
  }else{
    .etr_assert(is.null(measurement_error_variance),
      "measurement_error_variance must be NULL for diagonal_difference")
    .etr_assert(is.numeric(noise_min_local_points)&&
      length(noise_min_local_points)==1L&&
      noise_min_local_points>=2L&&
      noise_min_local_points==floor(noise_min_local_points),
      "noise_min_local_points must be integer >=2")
    .etr_assert(!is.null(noise_support),
      "noise_support is required for diagonal_difference")
  }
  .etr_assert(analysis_support_action%in%c("error","restrict"),
    "analysis_support_action must be error or restrict")
  .etr_assert(score_failure_action%in%c("error","retain_nan"),
    "score_failure_action must be error or retain_nan")
  for(z in list(score_ridge,psd_tolerance,positive_eigen_tolerance)){
    .etr_assert(is.numeric(z)&&length(z)==1L&&
      is.finite(z)&&z>=0,
      "ridge and covariance tolerances must be finite nonnegative")
  }
  .etr_assert(is.numeric(score_condition_limit)&&
    length(score_condition_limit)==1L&&
    is.finite(score_condition_limit)&&score_condition_limit>1,
    "score_condition_limit must exceed one")
  .etr_assert(is.numeric(min_score_samples)&&
    length(min_score_samples)==1L&&min_score_samples>=1L&&
    min_score_samples==floor(min_score_samples),
    "min_score_samples must be integer >=1")
  .etr_assert(is.numeric(mean_min_local_points)&&
    length(mean_min_local_points)==1L&&mean_min_local_points>=2L&&
    mean_min_local_points==floor(mean_min_local_points)&&
    is.numeric(covariance_min_local_pairs)&&
    length(covariance_min_local_pairs)==1L&&
    covariance_min_local_pairs>=3L&&
    covariance_min_local_pairs==floor(covariance_min_local_pairs),
    "local mean/pair support thresholds must be positive integers")
  grid<-.etr_spn_grid(evaluation_grid)
  t_all<-trajectories$time
  .etr_spn_check_grid_support(t_all,grid)
  d<-match(dimension,trajectories$dimension_names)
  original_y<-lapply(trajectories$values,function(v)as.numeric(v[,d]))
  nonfinite<-vapply(original_y,function(v)sum(!is.finite(v)),integer(1L))
  if(any(nonfinite>0L)){
    i<-which(nonfinite>0L)[1L]
    .etr_spn_fail("nonfinite_sparse_observation",
      "sparse observations must be finite",
      list(curve_id=trajectories$curve_ids[i],dimension=dimension,
        n_nonfinite=nonfinite[i]))
  }
  analysis<-.etr_spn_analysis_support(t_all,original_y,grid,analysis_support_action)
  times<-analysis$times
  values<-analysis$values
  t_pool<-unlist(times,use.names=FALSE)
  y_pool<-unlist(values,use.names=FALSE)
  mean<-.etr_spn_mean(t_pool,y_pool,grid,mean_bandwidth,
    mean_min_local_points)
  residuals<-Map(function(t,v)
    if(length(t))v-.etr_spn_mean(t_pool,y_pool,t,
      mean_bandwidth,mean_min_local_points)$values else numeric(),
    times,values)
  pairs<-.etr_spn_pairs(times,residuals)
  covariance<-.etr_spn_surface(
    pairs,grid,covariance_bandwidth,covariance_min_local_pairs)
  noise<-if(identical(noise_variance_method,"diagonal_difference")){
    rotated<-.etr_spn_rotated_diagonal(
      pairs,grid,covariance_bandwidth,covariance_min_local_pairs)
    .etr_spn_noise_diagonal_difference(
      times,residuals,grid,rotated$values,noise_bandwidth,
      noise_support,noise_min_local_points)
  }else NULL
  if(!is.null(noise)&&noise$status_code!="ok")
    .etr_spn_fail("noise_variance_invalid",
      "diagonal-difference measurement noise estimate is nonpositive")
  noise_variance<-if(is.null(noise))
    measurement_error_variance else noise$variance
  psd<-.etr_spn_psd(covariance$values,grid,psd_action,psd_tolerance)
  eig<-.etr_spn_eigensystem(psd$covariance,grid,k,
    positive_eigen_tolerance)
  score<-.etr_spn_score_system(
    trajectories$curve_ids,times,values,grid,mean$values,
    psd$covariance,eig$eigenvalues,eig$eigenfunctions,
    noise_variance,score_ridge,score_condition_limit,
    as.integer(min_score_samples),score_failure_action)
  info<-c(list(
    backend="native",dimension=dimension,n_components=k,
    component_rank_rule="positive_fitted_operator_spectrum",
    mean_smoother=mean_smoother,covariance_smoother=covariance_smoother,
    kernel=kernel,mean_bandwidth=mean_bandwidth,
    covariance_bandwidth=covariance_bandwidth,
    noise_bandwidth=noise_bandwidth,
    noise_variance_method=noise_variance_method,
    noise_variance=noise_variance,
    noise_latent_diagonal_method=if(is.null(noise))NULL else
      "rotated_local_quadratic_offdiagonal",
    noise_latent_diagonal_bandwidth=if(is.null(noise))NULL else
      covariance_bandwidth,
    noise_support=if(is.null(noise))NULL else as.numeric(noise_support),
    evaluation_grid=as.numeric(grid)),analysis$diagnostics,list(
    psd_action=psd_action,psd_tolerance=psd_tolerance,
    positive_eigen_tolerance=positive_eigen_tolerance,
    score_method="PACE",
    score_covariance_source="full_fitted_covariance_plus_noise",
    score_ridge=score_ridge,
    score_condition_limit=score_condition_limit,
    min_score_samples=as.integer(min_score_samples),
    score_failure_action=score_failure_action,
    mean_min_local_points=as.integer(mean_min_local_points),
    covariance_min_local_pairs=as.integer(covariance_min_local_pairs),
    noise_min_local_points=as.integer(noise_min_local_points),
    sample_counts=as.integer(lengths(times)),
    raw_sparse_trajectory_interpolation_performed=FALSE,
    population_function_evaluation_at_native_times=TRUE,
    cross_channel_covariance_modeled=FALSE,
    automatic_bandwidth_selection_performed=FALSE,
    covariance_psd=psd$audit,
    measurement_error_variance_supplied=if(is.null(noise))
      measurement_error_variance else NULL))
  provenance<-trajectories$provenance
  provenance$sparse_fpca<-info
  structure(list(
    scores=score$scores,
    eigenvalues=eig$eigenvalues,dimension=dimension,
    curve_ids=trajectories$curve_ids,
    metadata=trajectories$metadata,
    coordinate_system=trajectories$coordinate_system,
    time_unit=trajectories$time_unit,n_components=k,
    fit_method="native_covariance",
    fit_smoothing="local_linear_epanechnikov",
    score_method="PACE",score_smoothing=NULL,
    tolerance=positive_eigen_tolerance,normalize=FALSE,
    backend_object=NULL,backend_data=NULL,reconstructed_backend=NULL,
    evaluation_grid=grid,mean=mean$values,
    covariance=psd$covariance,eigenfunctions=eig$eigenfunctions,
    noise_variance=noise_variance,
    quadrature_weights=eig$quadrature_weights,
    score_diagnostics=score$diagnostics,
    covariance_diagnostics=psd$audit,
    mean_support_counts=mean$support_counts,
    covariance_support_counts=covariance$support_counts,
    noise_raw_diagonal=if(is.null(noise))NULL else noise$raw_diagonal,
    noise_diagonal_difference=if(is.null(noise))NULL else
      noise$diagonal_difference,
    provenance=provenance,
    source_python_full_contract_equivalent=FALSE,
    independent_full_source_certified=FALSE),
    class="etr_sparse_fpca_native")
}

.etr_sparse_smoothing_settings<-function(mean_smoother,covariance_smoother,kernel){
  .etr_assert(identical(mean_smoother,"local_linear"),
    "mean_smoother must be 'local_linear' in the first native tranche")
  .etr_assert(identical(covariance_smoother,"local_linear"),
    "covariance_smoother must be 'local_linear' in the first native tranche")
  .etr_assert(identical(kernel,"epanechnikov"),
    "kernel must be 'epanechnikov' in the first native tranche")
}

#' Conditional Gaussian uncertainty for fitted sparse FPCA/PACE scores
#'
#' @description Computes Lambda - Lambda Phi' Sigma^{-1} Phi Lambda for
#' observed sparse times with the *full* fitted covariance surface.
#' Conditions on the population fit; excludes estimation uncertainty.
#' @param fit Native sparse-FPCA population fit.
#' @param trajectories Matched native irregular source observations.
#' @param condition_limit Optional condition-number override.
#' @param failure_action "error" or "retain_nan".
#' @return Per-curve conditional covariance, standard errors and diagnostics.
#' @export
etr_sparse_fpca_score_uncertainty_native<-function(
    fit,trajectories,condition_limit=NULL,failure_action="error"){
  .etr_assert(inherits(fit,"etr_sparse_fpca_native")&&
    identical(fit$fit_method,"native_covariance")&&
    identical(fit$score_method,"PACE"),
    "fit must be a native sparse FPCA/PACE result")
  .etr_irregular_validate_samples(trajectories)
  .etr_assert(identical(fit$curve_ids,trajectories$curve_ids)&&
    fit$dimension%in%trajectories$dimension_names,
    "sparse FPCA fit/trajectory curve IDs and dimension must align")
  .etr_assert(identical(fit$coordinate_system,trajectories$coordinate_system),
    "trajectory coordinate_system does not match fit")
  .etr_assert(identical(fit$time_unit,trajectories$time_unit),
    "trajectory time_unit does not match fit")
  info<-fit$provenance$sparse_fpca
  .etr_assert(is.list(info)&&identical(info$backend,"native"),
    "fit provenance does not identify the native sparse FPCA backend")
  limit<-if(is.null(condition_limit))info$score_condition_limit
    else condition_limit
  if(is.null(limit))limit<-1e12
  if(.etr_trajectory_boundary_scalar(limit))
    limit<-.etr_trajectory_boundary_double(limit,"condition_limit must be numeric")
  .etr_assert(is.numeric(limit)&&length(limit)==1L&&
    is.finite(limit)&&limit>1,
    "condition_limit must be finite and greater than one")
  .etr_assert(failure_action%in%c("error","retain_nan"),
    "failure_action must be error or retain_nan")
  grid<-.etr_spn_uncertainty_grid(fit$evaluation_grid)
  k<-fit$n_components
  .etr_assert(is.numeric(k)&&length(k)==1L&&is.finite(k)&&k>=1&&k==floor(k),
    "fit n_components must be a positive integer")
  .etr_assert(is.numeric(fit$eigenvalues)&&is.null(dim(fit$eigenvalues))&&
    length(fit$eigenvalues)>=k&&all(is.finite(fit$eigenvalues[seq_len(k)]))&&
    all(fit$eigenvalues[seq_len(k)]>=0),
    "retained fit eigenvalues must be finite and non-negative")
  .etr_assert(is.numeric(fit$covariance)&&
    identical(dim(fit$covariance),rep(length(grid),2L)),
    "fit covariance shape does not match evaluation grid")
  .etr_assert(is.numeric(fit$eigenfunctions)&&is.matrix(fit$eigenfunctions)&&
    nrow(fit$eigenfunctions)>=k&&ncol(fit$eigenfunctions)==length(grid),
    "fit eigenfunctions do not align with retained components and evaluation grid")
  .etr_assert(is.numeric(fit$noise_variance)&&length(fit$noise_variance)==1L&&
    is.finite(fit$noise_variance)&&fit$noise_variance>=0,
    "fit noise_variance must be finite and non-negative")
  ridge<-info$score_ridge
  if(is.null(ridge))ridge<-0
  .etr_assert(is.numeric(ridge)&&length(ridge)==1L&&is.finite(ridge)&&ridge>=0,
    "fit score_ridge must be finite and non-negative")
  min_samples<-info$min_score_samples
  if(is.null(min_samples))min_samples<-2L
  .etr_assert(is.numeric(min_samples)&&length(min_samples)==1L&&
    is.finite(min_samples)&&min_samples>=1,"fit min_score_samples must be positive")
  action<-info$analysis_support_action
  if(is.null(action))action<-"error"
  .etr_assert(length(action)==1L&&action%in%c("error","restrict"),
    "fit has an unsupported analysis-support policy")
  mask<-lapply(trajectories$time,
    function(t)t>=grid[1L]&t<=tail(grid,1L))
  outside<-lengths(trajectories$time)-vapply(mask,sum,integer(1L))
  first_outside<-which(outside>0L)
  if(action=="error"&&length(first_outside))
    .etr_spn_fail("observations_outside_analysis_support",
      "observations lie outside the fitted evaluation-grid support",
      list(analysis_support=range(grid),
        outside_counts_by_curve=outside[seq_len(first_outside[1L])]))
  times<-if(action=="restrict")
    Map(function(t,m)t[m],trajectories$time,mask)else
      trajectories$time
  actual<-as.integer(lengths(times))
  .etr_assert(is.null(info$sample_counts)||identical(actual,as.integer(info$sample_counts)),
    "trajectories do not reproduce effective fit sample counts")
  retained<-seq_len(k)
  eigenvalues<-fit$eigenvalues[retained]
  z<-.etr_spn_score_system(fit$curve_ids,times,NULL,
    grid,NULL,fit$covariance,eigenvalues,
    fit$eigenfunctions[retained,,drop=FALSE],fit$noise_variance,
    ridge,limit,as.integer(min_samples),
    failure_action,posterior=TRUE)
  prov<-list(
    method="conditional_gaussian_given_fitted_population",
    covariance_source="full_fitted_covariance_plus_noise_and_declared_score_ridge",
    fitted_covariance_source="SparseFPCAResult.covariance",
    fitted_noise_source="SparseFPCAResult.noise_variance",
    eigensystem_source="SparseFPCAResult.eigenvalues_and_eigenfunctions",
    native_observation_times=TRUE,
    raw_sparse_trajectory_interpolation_performed=FALSE,
    score_ridge=ridge,
    condition_limit=limit,
    condition_limit_source=if(is.null(condition_limit))
      "fitted_score_condition_limit"else"explicit_override",
    failure_action=failure_action,
    posterior_psd_tolerance=1e-10*max(1,max(abs(eigenvalues))),
    population_estimation_uncertainty_included=FALSE,
    mean_estimation_uncertainty_included=FALSE,
    covariance_estimation_uncertainty_included=FALSE,
    eigensystem_estimation_uncertainty_included=FALSE,
    noise_variance_estimation_uncertainty_included=FALSE,
    bandwidth_uncertainty_included=FALSE,
    interpretation=paste("conditional on fitted mean/covariance/eigensystem and measurement-error",
      "variance; excludes population-estimation uncertainty"))
  structure(list(reference=fit,curve_ids=fit$curve_ids,
    covariance=z$covariance,standard_errors=z$standard_errors,
    correlations=.etr_spn_score_correlations(z$covariance,z$standard_errors),
    diagnostics=z$diagnostics,n_components=fit$n_components,
    method="conditional_gaussian_given_fitted_population",
    provenance=prov,
    source_python_full_contract_equivalent=FALSE,
    independent_full_source_certified=FALSE),
    class="etr_sparse_fpca_score_uncertainty_native")
}

#' Tidy conditional sparse PACE score uncertainty table
#' @param result Native conditional sparse PACE uncertainty.
#' @return One row per source curve and component.
#' @export
etr_sparse_fpca_score_uncertainty_frame_native<-function(result){
  .etr_assert(inherits(result,"etr_sparse_fpca_score_uncertainty_native"),
    "result must be native sparse PACE score uncertainty")
  n<-length(result$curve_ids);k<-result$n_components
  rows<-vector("list",n*k);ii<-1L
  for(i in seq_len(n))for(j in seq_len(k)){
    rows[[ii]]<-data.frame(
      curve_id=result$curve_ids[i],component=j,
      conditional_variance=result$covariance[i,j,j],
      conditional_standard_error=result$standard_errors[i,j],
      status_code=result$diagnostics$status_code[i],
      condition_number=result$diagnostics$condition_number[i],
      method=result$method,stringsAsFactors=FALSE)
    ii<-ii+1L
  }
  do.call(rbind,rows)
}
