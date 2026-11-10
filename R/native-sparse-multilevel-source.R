# Native sparse participant/trial covariance and hierarchical BLUP,
# matching frozen Python 1.2 sparse_multilevel.py fixed-noise source model.
# Frozen commit c1cd95ad718327550f7e55393ff38582872f7a94.

#' Source-model native sparse multilevel FPCA with joint hierarchical BLUP
#'
#' @description Fits Y_ij(t)=mu(t)+U_i(t)+V_ij(t)+epsilon_ij(t)
#' from native irregular trials without interpolation. Between covariance
#' pools distinct trials of a participant; within covariance is the
#' smoothed total minus smoothed between. Both are independently PSD
#' repaired and scored by full-covariance participant-wise Gaussian BLUP.
#' @param trajectories Native irregular trial trajectories.
#' @param dimension Observed source signal dimension.
#' @param participant_column Required participant grouping metadata column.
#' @param participant_components,trial_components Positive retained ranks.
#' @param evaluation_grid Fitted population function grid.
#' @param mean_bandwidth,total_covariance_bandwidth,between_covariance_bandwidth Positive kernel bandwidths.
#' @param noise_bandwidth,noise_support Optional diagonal-difference noise controls.
#' @param analysis_support_action "error" or "restrict".
#' @param weighting "observation" is the source-supported weighting.
#' @param mean_smoother,covariance_smoother "local_linear".
#' @param kernel "epanechnikov".
#' @param noise_variance_method "fixed" or "diagonal_difference".
#' @param measurement_error_variance Supplied fixed nonnegative noise.
#' @param psd_action "error" or "project".
#' @param psd_tolerance,positive_eigen_tolerance PSD thresholds.
#' @param score_ridge,score_condition_limit Gaussian BLUP condition controls.
#' @param min_participant_score_samples Minimum pooled participant samples.
#' @param score_failure_action "error" or "retain_nan".
#' @param mean_min_local_points,total_covariance_min_local_pairs,between_covariance_min_local_pairs,noise_min_local_points Kernel support minima.
#' @return Native source-shaped sparse two-level FPCA fit and diagnostics.
#' @export
etr_fit_sparse_multilevel_fpca_native<-function(
    trajectories,dimension,participant_column,participant_components,
    trial_components,evaluation_grid,mean_bandwidth,
    total_covariance_bandwidth,between_covariance_bandwidth,
    noise_bandwidth=NULL,noise_support=NULL,
    analysis_support_action="error",weighting="observation",
    mean_smoother="local_linear",covariance_smoother="local_linear",
    kernel="epanechnikov",noise_variance_method="diagonal_difference",
    measurement_error_variance=NULL,psd_action="error",
    psd_tolerance=1e-8,positive_eigen_tolerance=1e-10,
    score_ridge=0,score_condition_limit=1e12,
    min_participant_score_samples=2L,score_failure_action="error",
    mean_min_local_points=3L,total_covariance_min_local_pairs=6L,
    between_covariance_min_local_pairs=6L,noise_min_local_points=3L){
  .etr_irregular_validate_samples(trajectories)
  .etr_assert(length(trajectories$curve_ids)>=3L&&
    is.character(dimension)&&length(dimension)==1L&&
    dimension%in%trajectories$dimension_names,
    "sparse multilevel requires three trials and a valid signal dimension")
  .etr_assert(is.character(participant_column)&&
    length(participant_column)==1L&&nzchar(participant_column)&&
    participant_column%in%names(trajectories$metadata),
    "participant_column must identify nonempty metadata field")
  participant<-as.character(
    trajectories$metadata[[participant_column]])
  .etr_assert(length(participant)==length(trajectories$curve_ids)&&
    all(nzchar(participant))&&!anyNA(participant),
    "participant identifiers must be nonempty and nonmissing")
  ids<-unique(participant)
  counts<-table(factor(participant,levels=ids))
  if(length(ids)<3L)
    .etr_spn_fail("insufficient_participants",
      "sparse multilevel source requires three participants")
  if(sum(counts>=2L)<3L)
    .etr_spn_fail("insufficient_repeated_participants",
      "between-trial covariance requires at least three repeatedly sampled participants")
  for(k in list(participant_components,trial_components)){
    .etr_assert(is.numeric(k)&&length(k)==1L&&
      !is.logical(k)&&is.finite(k)&&k==floor(k)&&k>=1L,
      "participant/trial component counts must be positive integers")
  }
  for(k in list(mean_bandwidth,total_covariance_bandwidth,
      between_covariance_bandwidth)){
    .etr_assert(is.numeric(k)&&length(k)==1L&&
      is.finite(k)&&k>0,
      "sparse multilevel population bandwidths must be finite positive")
  }
  for(k in list(mean_min_local_points,
      total_covariance_min_local_pairs,
      between_covariance_min_local_pairs,noise_min_local_points)){
    .etr_assert(is.numeric(k)&&length(k)==1L&&is.finite(k)&&
      k==floor(k)&&k>=2L,
      "all local smoothing support minima must be integer >=2")
  }
  .etr_assert(identical(weighting,"observation")&&
    identical(mean_smoother,"local_linear")&&
    identical(covariance_smoother,"local_linear")&&
    identical(kernel,"epanechnikov"),
    "source sparse multilevel requires observation weighting and Epanechnikov local-linear smoothing")
  .etr_assert(noise_variance_method%in%c(
    "fixed","diagonal_difference"),
    "invalid sparse multilevel measurement noise method")
  if(identical(noise_variance_method,"fixed")){
    .etr_assert(is.numeric(measurement_error_variance)&&
      length(measurement_error_variance)==1L&&
      is.finite(measurement_error_variance)&&
      measurement_error_variance>=0&&is.null(noise_support),
      "fixed noise requires explicit nonnegative measurement variance and no noise_support")
  }else{
    .etr_assert(is.null(measurement_error_variance)&&
      !is.null(noise_bandwidth)&&!is.null(noise_support),
      "diagonal_difference requires noise bandwidth/support but no fixed measurement variance")
  }
  .etr_assert(analysis_support_action%in%c("error","restrict")&&
    psd_action%in%c("error","project")&&
    score_failure_action%in%c("error","retain_nan"),
    "invalid multilevel support/PSD/score failure policy")
  for(k in list(psd_tolerance,positive_eigen_tolerance,score_ridge)){
    .etr_assert(is.numeric(k)&&length(k)==1L&&
      is.finite(k)&&k>=0,
      "PSD tolerances and ridge must be finite nonnegative")
  }
  .etr_assert(is.numeric(score_condition_limit)&&
    length(score_condition_limit)==1L&&
    is.finite(score_condition_limit)&&score_condition_limit>1,
    "score_condition_limit must be finite greater than one")
  .etr_assert(is.numeric(min_participant_score_samples)&&
    length(min_participant_score_samples)==1L&&
    !is.logical(min_participant_score_samples)&&
    is.finite(min_participant_score_samples)&&
    min_participant_score_samples>=1L&&
    min_participant_score_samples==floor(min_participant_score_samples),
    "min_participant_score_samples must be positive integer")
  grid<-.etr_spn_grid(evaluation_grid)
  raw_times<-trajectories$time
  .etr_spn_check_grid_support(raw_times,grid)
  dimix<-match(dimension,trajectories$dimension_names)
  raw_values<-lapply(trajectories$values,function(v)
    as.numeric(v[,dimix]))
  .etr_assert(all(vapply(raw_values,function(v)
    all(is.finite(v)),logical(1L))),
    "nonfinite_sparse_observation")
  analysis<-.etr_spn_analysis_support(raw_times,raw_values,grid,analysis_support_action)
  times<-analysis$times
  values<-analysis$values
  if(any(lengths(times)==0L))
    .etr_spn_fail("curve_without_analysis_support",
      "every trial must retain native observations within population support",
      list(curve_ids=trajectories$curve_ids[lengths(times)==0L]))
  pooled_time<-unlist(times,use.names=FALSE)
  pooled_value<-unlist(values,use.names=FALSE)
  fitted_mean<-.etr_spn_mean(pooled_time,pooled_value,grid,
    mean_bandwidth,mean_min_local_points)
  residuals<-Map(function(t,y)y-.etr_spn_mean(
    pooled_time,pooled_value,t,mean_bandwidth,
    mean_min_local_points)$values,times,values)
  total_pairs<-.etr_spn_pairs(times,residuals)
  cross<-.etr_spml_cross_pairs(times,residuals,participant)
  total<-.etr_spn_surface(total_pairs,grid,
    total_covariance_bandwidth,total_covariance_min_local_pairs)
  between<-.etr_spn_surface(cross$pairs,grid,
    between_covariance_bandwidth,between_covariance_min_local_pairs)
  within_smoothed<-((total$values-between$values)+
    t(total$values-between$values))/2
  noise<-NULL
  if(noise_variance_method=="diagonal_difference"){
    diagonal<-.etr_spn_rotated_diagonal(total_pairs,grid,
      total_covariance_bandwidth,total_covariance_min_local_pairs)
    noise<-.etr_spn_noise_diagonal_difference(
      times,residuals,grid,diagonal$values,
      noise_bandwidth,noise_support,noise_min_local_points)
    if(noise$status_code!="ok")
      .etr_spn_fail("noise_variance_invalid",
        "sparse multilevel diagonal-difference noise is not positive")
    noise_var<-noise$variance
  }else noise_var<-measurement_error_variance
  between_psd<-.etr_spn_psd(between$values,grid,psd_action,
    psd_tolerance)
  within_psd<-.etr_spn_psd(within_smoothed,grid,psd_action,
    psd_tolerance)
  eigen_participant<-.etr_spn_eigensystem(
    between_psd$covariance,grid,
    as.integer(participant_components),positive_eigen_tolerance)
  eigen_trial<-.etr_spn_eigensystem(
    within_psd$covariance,grid,
    as.integer(trial_components),positive_eigen_tolerance)
  scores<-.etr_spml_blup(trajectories$curve_ids,participant,
    times,values,grid,fitted_mean$values,between_psd$covariance,
    within_psd$covariance,
    eigen_participant,eigen_trial,noise_var,score_ridge,
    score_condition_limit,
    as.integer(min_participant_score_samples),
    score_failure_action)
  fp<-as.data.frame(scores$participant_scores)
  names(fp)<-paste0("participant_FPC",seq_len(participant_components))
  fp<-data.frame(stats::setNames(list(ids),participant_column),
    fp,check.names=FALSE)
  ft<-as.data.frame(scores$trial_scores)
  names(ft)<-paste0("trial_FPC",seq_len(trial_components))
  ft<-data.frame(curve_id=trajectories$curve_ids,
    stats::setNames(list(participant),participant_column),
    ft,check.names=FALSE)
  covariance_audit<-list(
    between=between_psd$audit,within=within_psd$audit,
    smoothed_within_definition="smoothed_total_minus_smoothed_between",
    score_total_definition="repaired_between_plus_repaired_within",
    post_psd_total_difference_frobenius_norm=sqrt(sum((
      between_psd$covariance+within_psd$covariance-
      total$values)^2)))
  support<-c(analysis$diagnostics,list(
    n_participants=length(ids),
    n_repeated_participants=sum(counts>=2L),
    raw_trial_counts_by_participant=as.list(counts),
    analysis_trial_counts_by_participant=as.list(counts),
    analysis_sample_counts_by_participant=as.list(
      vapply(ids,function(id)sum(lengths(times[participant==id])),
        integer(1L))),
    total_covariance_pair_count=length(total_pairs$products),
    between_covariance_pair_count=length(cross$pairs$products),
    between_pair_counts_by_participant=as.list(
      cross$participant_pair_counts),
    single_trial_participants=ids[counts==1L]))
  names(support$analysis_sample_counts_by_participant)<-ids
  source<-list(backend="native",
    method="sparse_two_level_covariance_BLUP",
    model="Y_ij(t)=mu(t)+U_i(t)+V_ij(t)+epsilon_ij(t)",
    dimension=dimension,participant_column=participant_column,
    participant_components=as.integer(participant_components),
    trial_components=as.integer(trial_components),
    n_participants=length(ids),
    n_trials=length(trajectories$curve_ids),
    exchangeable_trials_assumed=TRUE,
    trial_fixed_effects_estimated=FALSE,
    fixed_effect_requirement=
      "condition_or_visit effects must be absent, stratified, or removed upstream",
    weighting=weighting,
    weighting_interpretation=
      "pooled native observations for mean smoothing; pooled raw covariance pairs for covariance smoothing",
    equal_participant_weighting_claimed=FALSE,
    mean_smoother=mean_smoother,covariance_smoother=covariance_smoother,
    kernel=kernel,mean_bandwidth=mean_bandwidth,
    total_covariance_bandwidth=total_covariance_bandwidth,
    between_covariance_bandwidth=between_covariance_bandwidth,
    between_covariance_source=
      "same_participant_distinct_trial_cross_products",
    total_covariance_source="within_trial_offdiagonal_products",
    within_covariance_definition=
      "smoothed_total_minus_smoothed_between",
    measurement_error_method=noise_variance_method,
    noise_variance=noise_var,
    noise_bandwidth=noise_bandwidth,noise_support=noise_support,
    psd_action=psd_action,psd_tolerance=psd_tolerance,
    positive_eigen_tolerance=positive_eigen_tolerance,
    score_method="joint_hierarchical_Gaussian_BLUP",
    score_covariance_source="full_fitted_between_plus_within_plus_noise",
    score_covariance_with_ridge_source=scores$covariance_source,
    rank_k_covariance_used_for_scoring=FALSE,
    score_ridge=score_ridge,
    score_condition_limit=score_condition_limit,
    min_participant_score_samples=
      as.integer(min_participant_score_samples),
    score_failure_action=score_failure_action,
    raw_sparse_trajectory_interpolation_performed=FALSE,
    population_function_evaluation_at_native_times=TRUE,
    automatic_bandwidth_selection_performed=FALSE,
    population_estimation_uncertainty_propagated=FALSE,
    analysis_support_action=analysis_support_action,
    covariance_psd=covariance_audit)
  if(!is.null(measurement_error_variance))
    source$measurement_error_variance_supplied<-measurement_error_variance
  provenance<-trajectories$provenance
  provenance$sparse_multilevel_fpca<-source
  structure(list(
    evaluation_grid=grid,dimension=dimension,
    participant_column=participant_column,
    curve_ids=as.character(trajectories$curve_ids),
    participant_ids=ids,
    grand_mean=fitted_mean$values,
    smoothed_total_covariance=total$values,
    smoothed_between_covariance=between$values,
    smoothed_within_covariance=within_smoothed,
    total_covariance=between_psd$covariance+
      within_psd$covariance,
    between_covariance=between_psd$covariance,
    within_covariance=within_psd$covariance,
    participant_eigenvalues=eigen_participant$eigenvalues,
    participant_eigenfunctions=eigen_participant$eigenfunctions,
    trial_eigenvalues=eigen_trial$eigenvalues,
    trial_eigenfunctions=eigen_trial$eigenfunctions,
    participant_scores=fp,trial_scores=ft,
    score_diagnostics=scores$diagnostics,
    noise_variance=noise_var,
    quadrature_weights=eigen_participant$quadrature_weights,
    mean_support_counts=fitted_mean$support_counts,
    total_covariance_support_counts=total$support_counts,
    between_covariance_support_counts=between$support_counts,
    covariance_diagnostics=covariance_audit,
    support_diagnostics=support,
    noise_raw_diagonal=if(is.null(noise))NULL else noise$raw_diagonal,
    noise_diagonal_difference=if(is.null(noise))NULL else
      noise$diagonal_difference,
    metadata=trajectories$metadata,
    coordinate_system=trajectories$coordinate_system,
    time_unit=trajectories$time_unit,
    provenance=provenance,
    independent_full_source_certified=FALSE,
    source_python_full_domain_approved=FALSE),
    class="etr_sparse_multilevel_fpca_source")
}
