# Python 1.2 source sparse_partial_conformal.py (frozen
# c1cd95ad718327550f7e55393ff38582872f7a94).
# Split-conformal simultaneous *future observed* measurements on a declared
# finite grid. Actual observations must exactly match forecast timestamps;
# no interpolation, no latent-trajectory or continuous-time coverage claims.

.etr_spnpc_one<-function(x,i){
  etr_irregular_trajectory_set(
    list(x$time[[i]]),list(x$values[[i]]),
    as.character(x$curve_ids[i]),
    x$dimension_names,metadata=x$metadata[i,,drop=FALSE],
    coordinate_system=x$coordinate_system,time_unit=x$time_unit)
}

.etr_spnpc_observed_future<-function(x,dimension,grid){
  .etr_assert(length(x$curve_ids)==1L&&
    dimension%in%x$dimension_names,
    "calibration curve must be single observed target dimension")
  tt<-x$time[[1L]]
  observed<-as.numeric(x$values[[1L]][,
    match(dimension,x$dimension_names)])
  result<-numeric(length(grid))
  for(j in seq_along(grid)){
    ix<-which(tt==grid[j])
    if(length(ix)!=1L)
      .etr_spn_fail("calibration_future_grid_observation_missing",
        "each declared target timestamp must have exactly one raw calibration observation")
    v<-observed[ix]
    if(!is.finite(v))
      .etr_spn_fail("calibration_future_grid_observation_nonfinite",
        "calibration response on declared future grid must be finite")
    result[j]<-v
  }
  result
}

.etr_spnpc_group_values<-function(fit,calibration,group_column){
  fit_ids<-as.character(fit$curve_ids)
  cal_ids<-as.character(calibration$curve_ids)
  if(length(intersect(fit_ids,cal_ids))>0L)
    stop("proper-training fit and calibration curve IDs must be disjoint",
      call.=FALSE)
  .etr_assert(fit$dimension%in%calibration$dimension_names&&
    identical(fit$coordinate_system,calibration$coordinate_system)&&
    identical(fit$time_unit,calibration$time_unit),
    "calibration dimension or units do not match fitted training population")
  if(is.null(group_column))
    return(list(units=cal_ids,training_units=fit_ids))
  .etr_assert(is.character(group_column)&&length(group_column)==1L&&
    group_column%in%names(calibration$metadata)&&
    group_column%in%names(fit$metadata),
    "group_column must occur in both calibration and training metadata")
  cg<-as.character(calibration$metadata[[group_column]])
  tg<-as.character(fit$metadata[[group_column]])
  .etr_assert(all(nzchar(cg))&&all(nzchar(tg))&&
    !anyNA(cg)&&!anyNA(tg),
    "declared exchangeability groups must be nonempty and finite identifiers")
  .etr_assert(length(intersect(unique(cg),unique(tg)))==0L,
    "proper-training and calibration participant/group units must be disjoint")
  list(units=cg,training_units=tg)
}

#' Calibrate source-model conditional sparse PACE future prediction
#'
#' @description Split-conformal finite-grid simultaneous future observed
#' measurement band; one max standardized residual per calibration curve
#' and optionally maximum across repeated curves in participant/group.
#' Calibration values must be observed at exactly every target time.
#' @param fit Fitted native sparse PACE population covariance model.
#' @param calibration Independent calibration irregular curves.
#' @param history_cutoff Prediction history cutoff.
#' @param prediction_grid Finite increasing future grid.
#' @param alpha Error probability; finite-sample quantile must exist.
#' @param group_column Optional exchangeability grouping column.
#' @param min_history_observations,condition_limit,history_ridge Source controls.
#' @return Calibration curve/unit scores and exact finite-sample critical value.
#' @export
etr_calibrate_sparse_fpca_partial_conformal_native<-function(
    fit,calibration,history_cutoff,prediction_grid,
    alpha=.05,group_column=NULL,min_history_observations=2L,
    condition_limit=NULL,history_ridge=NULL){
  .etr_assert(inherits(fit,"etr_sparse_fpca_native"),
    "calibration needs native sparse FPCA population fit")
  .etr_irregular_validate_samples(calibration)
  .etr_assert(is.numeric(alpha)&&length(alpha)==1L&&
    is.finite(alpha)&&alpha>0&&alpha<1,
    "alpha must lie in (0,1)")
  partition<-.etr_spnpc_group_values(fit,calibration,group_column)
  n<-length(calibration$curve_ids)
  rows<-vector("list",n)
  for(i in seq_len(n)){
    single<-.etr_spnpc_one(calibration,i)
    prediction<-etr_sparse_fpca_partial_trajectory_prediction_native(
      fit,single,history_cutoff,prediction_grid,
      min_history_observations=min_history_observations,
      condition_limit=condition_limit,history_ridge=history_ridge)
    truth<-.etr_spnpc_observed_future(single,
      fit$dimension,prediction$prediction_grid)
    scale<-prediction$observed_predictive_standard_errors
    if(any(!is.finite(scale))||any(scale<=0))
      .etr_spn_fail("invalid_conformal_predictive_scale",
        "conditional observed prediction standard errors must be positive")
    score<-max(abs(truth-prediction$conditional_mean)/scale)
    if(!is.finite(score))
      .etr_spn_fail("nonfinite_conformal_score",
        "calibration nonconformity score was not finite")
    rows[[i]]<-data.frame(
      curve_id=as.character(calibration$curve_ids[i]),
      calibration_unit=as.character(partition$units[i]),
      nonconformity_score=score,
      n_history=length(prediction$history_times),
      n_future_grid=length(prediction$prediction_grid),
      stringsAsFactors=FALSE)
  }
  curve_scores<-do.call(rbind,rows)
  groups<-split(curve_scores$nonconformity_score,
    curve_scores$calibration_unit)
  sorted_ids<-sort(names(groups))
  scores<-as.numeric(vapply(sorted_ids,function(id)
    max(groups[[id]]),numeric(1L)))
  m<-length(scores)
  rank<-as.integer(ceiling((m+1L)*(1-alpha)))
  if(rank>m)
    .etr_spn_fail("insufficient_calibration_units_for_alpha",
      "alpha below finite-sample calibration resolution")
  critical<-sort(scores)[rank]
  prov<-list(
    method="participant_aware_split_conformal_max_standardized_future_residual",
    prediction_target=
      "future_observed_measurements_on_declared_finite_grid",
    nonconformity="maximum_standardized_absolute_future_residual",
    standardization="model_based_observed_predictive_standard_error",
    calibration_unit=if(is.null(group_column))"curve"else"group",
    group_column=group_column,
    group_aggregation="maximum_curve_nonconformity_within_group",
    proper_training_curve_ids_disjoint=TRUE,
    proper_training_units=partition$training_units,
    raw_future_response_interpolation_performed=FALSE,
    future_grid_observation_match="exact_timestamp_equality",
    finite_sample_order_statistic_rank=rank,
    finite_sample_quantile_rule=
      "ceil((n_calibration_units+1)*(1-alpha))",
    simultaneous_scope="declared_finite_future_grid",
    continuous_domain_coverage_claimed=FALSE,
    latent_function_coverage_claimed=FALSE,
    exchangeability_required=TRUE,
    population_estimation_uncertainty_separately_propagated=FALSE)
  structure(list(reference=fit,
    calibration_curve_ids=as.character(calibration$curve_ids),
    calibration_unit_ids=sorted_ids,
    curve_scores=curve_scores,unit_scores=scores,
    alpha=alpha,critical_value=critical,
    history_cutoff=as.numeric(history_cutoff),
    prediction_grid=as.numeric(prediction_grid),
    group_column=group_column,
    min_history_observations=as.integer(min_history_observations),
    condition_limit=condition_limit,history_ridge=history_ridge,
    n_calibration_units=m,
    method="participant_aware_split_conformal_max_standardized_future_residual",
    provenance=prov,independent_full_source_certified=FALSE),
    class="etr_sparse_fpca_partial_conformal_calibration_native")
}

#' Apply native calibrated sparse PACE simultaneous prediction band
#' @param calibration Native split-conformal calibration result.
#' @param trajectory Single new independent target irregular trajectory.
#' @return Simultaneous future observed-measurement band on declared grid.
#' @export
etr_sparse_fpca_conformal_prediction_band_native<-function(
    calibration,trajectory){
  .etr_assert(inherits(calibration,
    "etr_sparse_fpca_partial_conformal_calibration_native"),
    "calibration must be a native sparse partial conformal record")
  .etr_irregular_validate_samples(trajectory)
  .etr_assert(length(trajectory$curve_ids)==1L,
    "target trajectory must contain one future-prediction curve")
  id<-as.character(trajectory$curve_ids[1L])
  fit<-calibration$reference
  .etr_assert(!(id%in%c(fit$curve_ids,
    calibration$calibration_curve_ids)),
    "target curve ID must be disjoint from training and calibration")
  target_unit<-id
  if(!is.null(calibration$group_column)){
    key<-calibration$group_column
    .etr_assert(key%in%names(trajectory$metadata),
      "target metadata missing declared group_column")
    target_unit<-as.character(trajectory$metadata[[key]][1L])
    .etr_assert(!(target_unit%in%
      c(calibration$calibration_unit_ids,
        calibration$provenance$proper_training_units)),
      "target participant/group must be disjoint from training and calibration")
  }
  prediction<-etr_sparse_fpca_partial_trajectory_prediction_native(
    fit,trajectory,calibration$history_cutoff,
    calibration$prediction_grid,
    min_history_observations=calibration$min_history_observations,
    condition_limit=calibration$condition_limit,
    history_ridge=calibration$history_ridge)
  scale<-prediction$observed_predictive_standard_errors
  cutoff<-calibration$critical_value
  prov<-list(method="finite_grid_simultaneous_split_conformal_prediction_band",
    prediction_target="future_observed_measurements_on_declared_finite_grid",
    simultaneous_scope="declared_finite_future_grid",
    continuous_domain_coverage_claimed=FALSE,
    latent_function_coverage_claimed=FALSE,
    exchangeability_unit=if(is.null(calibration$group_column))
      "curve" else "participant_or_group",
    target_unit=target_unit,calibration_critical_value=cutoff,
    alpha=calibration$alpha,
    raw_future_response_interpolation_performed=FALSE)
  structure(list(calibration=calibration,prediction=prediction,
    lower=prediction$conditional_mean-cutoff*scale,
    upper=prediction$conditional_mean+cutoff*scale,
    critical_value=cutoff,alpha=calibration$alpha,
    target_calibration_unit=target_unit,
    method="finite_grid_simultaneous_split_conformal_prediction_band",
    provenance=prov,independent_full_source_certified=FALSE),
    class="etr_sparse_fpca_conformal_prediction_band_native")
}

#' Tidy native sparse finite-grid simultaneous conformal prediction
#' @param result Native sparse PACE conformal prediction band.
#' @return Future grid bands with conditional mean and predictive SE.
#' @export
etr_sparse_fpca_conformal_band_frame_native<-function(result){
  .etr_assert(inherits(result,
    "etr_sparse_fpca_conformal_prediction_band_native"),
    "result must be native sparse PACE conformal band")
  p<-result$prediction
  data.frame(curve_id=p$curve_id,dimension=p$dimension,
    time=p$prediction_grid,
    conditional_mean=p$conditional_mean,
    observed_predictive_standard_error=
      p$observed_predictive_standard_errors,
    lower=result$lower,upper=result$upper,
    alpha=result$alpha,critical_value=result$critical_value,
    stringsAsFactors=FALSE)
}
