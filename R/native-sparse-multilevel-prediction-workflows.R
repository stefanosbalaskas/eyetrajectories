# Frozen Python 1.2 workflows/_sparse_multilevel.py and
# _sparse_prediction.py. Native transparent scientific ALTERNATIVES.
# No source multilevel sparse PACE or partial-score prediction equivalence.

.etr_native_sparse_interpolate<-function(x,dimension,grid){
  .etr_assert(inherits(x,"etr_irregular_trajectory_set"),
    "inputs must be native irregular trajectory sets")
  .etr_irregular_validate_samples(x)
  .etr_assert(is.character(dimension)&&
    length(dimension)==1L&&!is.na(dimension)&&
    dimension%in%x$dimension_names,
    "dimension must identify one observed irregular channel")
  .etr_assert(is.numeric(grid)&&is.null(dim(grid))&&
    length(grid)>=3L&&all(is.finite(grid))&&all(diff(grid)>0),
    "evaluation_grid must contain >=3 finite strictly increasing time points")
  d<-match(dimension,x$dimension_names)
  n<-length(x$curve_ids);nt<-length(grid)
  out<-matrix(0,n,nt)
  for(i in seq_len(n)){
    tt<-x$time[[i]]
    .etr_assert(grid[1L]>=tt[1L]&&tail(grid,1L)<=tail(tt,1L),
      "evaluation_grid must lie within every source curve support; extrapolation refused")
    yy<-x$values[[i]][,d]
    .etr_assert(all(is.finite(yy)),
      "native explicit sparse interpolation requires finite observed data")
    out[i,]<-stats::approx(tt,yy,xout=grid,
      method="linear",rule=1)$y
  }
  .etr_assert(all(is.finite(out)),"explicit interpolation failed")
  out
}

#' Run explicit-grid descriptive sparse multilevel functional workflow
#' @param trajectories Native irregular curves with participant metadata.
#' @param config Explicit backend, dimension, participant_column,
#'   evaluation_grid and n_between/n_within. Interpolation is deliberately
#'   required and changes the sparse source estimand.
#' @param observation_process Must be NULL.
#' @return Native interpolated-grid two-level descriptive FPCA workflow.
#'   Not Python irregular multilevel PACE covariance/BLUP inference.
#' @export
etr_run_sparse_multilevel_workflow<-function(trajectories,config,
    observation_process=NULL){
  cfg<-.etr_source_workflow_config(config,list(
    backend=NULL,dimension=NULL,participant_column=NULL,
    evaluation_grid=NULL,n_between=2L,n_within=2L,
    preprocessing=list()),
    required=c("backend","dimension","participant_column","evaluation_grid"))
  .etr_assert(identical(cfg$backend,
    "explicit_linear_interpolation_dense_multilevel"),
    "must explicitly choose linear interpolated dense multilevel R alternative")
  .etr_assert(is.null(observation_process),
    "native interpolated multilevel cannot analyze observation_process")
  .etr_assert(inherits(trajectories,"etr_irregular_trajectory_set"),
    "requires native irregular trajectory collection")
  .etr_assert(is.character(cfg$participant_column)&&
    length(cfg$participant_column)==1L&&
    cfg$participant_column%in%names(trajectories$metadata),
    "participant_column must exist in source irregular metadata")
  grid<-cfg$evaluation_grid
  mat<-.etr_native_sparse_interpolate(trajectories,cfg$dimension,grid)
  arr<-array(mat,dim=c(nrow(mat),ncol(mat),1L))
  dense<-etr_trajectory_set(grid,arr,trajectories$curve_ids,
    cfg$dimension,metadata=trajectories$metadata,
    coordinate_system=trajectories$coordinate_system,
    time_unit=trajectories$time_unit)
  fit<-etr_fit_multilevel_fpca(dense,
    participant=cfg$participant_column,
    n_between=cfg$n_between,n_within=cfg$n_within)
  params<-cfg[setdiff(names(cfg),"preprocessing")]
  structure(list(workflow_schema_version=1L,
    workflow_contract="sparse_multilevel:explicit_interpolated_dense_alternative",
    config=cfg,fit=fit,
    interpolation_grid=grid,
    steps=list(.etr_source_workflow_step(
      "explicit_linear_interpolation_then_descriptive_multilevel_FPCA",params)),
    decisions=lapply(params,.etr_source_workflow_decision),
    provenance=list(input_layout="native_irregular",
      interpolation_explicit=TRUE,
      interpolation_method="linear_no_extrapolation",
      sparse_covariance_PACE_applied=FALSE,
      preprocessing_executed=FALSE,
      source_python_equivalent=FALSE,
      full_source_contract_certified=FALSE),
    reports=list(fit="Explicitly interpolated native two-level descriptive FPCA; not sparse multilevel source PACE."),
    tables=list(
      between_scores=etr_multilevel_scores(fit)$between,
      within_scores=etr_multilevel_scores(fit)$within,
      variance=etr_multilevel_variance(fit))),
    class="etr_native_sparse_multilevel_workflow")
}

#' Native mean-curve split conformal sparse prediction baseline
#'
#' @description Conformal bands on target *observed sample times*, based on
#'   maximum residual deviation across each calibration curve against the
#'   pooled training mean. It is not Python PACE partial-curve prediction;
#'   target values are never used in calibration/training.
#' @param proper_training,calibration,target Disjoint independent irregular
#'   trajectory collections, with common dimension and time units.
#' @param config Explicit dimension, evaluation_grid, alpha,
#'   backend="native_mean_curve_split_conformal", empty preprocessing.
#' @return Native baseline split conformal prediction workflow with recorded
#'   curve-wise scores and target observed-time bounds.
#' @export
etr_run_sparse_prediction_workflow<-function(proper_training,calibration,
    target,config){
  cfg<-.etr_source_workflow_config(config,list(
    backend=NULL,dimension=NULL,evaluation_grid=NULL,alpha=.1,
    preprocessing=list()),
    required=c("backend","dimension","evaluation_grid","alpha"))
  .etr_assert(identical(cfg$backend,
    "native_mean_curve_split_conformal"),
    "explicitly choose native_mean_curve_split_conformal; Python PACE prediction not implemented")
  datasets<-list(proper_training,calibration,target)
  .etr_assert(all(vapply(datasets,inherits,logical(1L),
    "etr_irregular_trajectory_set")),
    "proper_training calibration and target must be native irregular sets")
  for(x in datasets){
    .etr_irregular_validate_samples(x)
    .etr_assert(cfg$dimension%in%x$dimension_names,
      "all splits must contain the declared functional dimension")
    .etr_assert(identical(x$time_unit,proper_training$time_unit),
      "split time units must match exactly")
  }
  ids<-unlist(lapply(datasets,function(x)x$curve_ids),
    use.names=FALSE)
  .etr_assert(!anyDuplicated(ids),
    "proper training calibration and targets must have disjoint curve IDs")
  .etr_assert(is.numeric(cfg$alpha)&&length(cfg$alpha)==1L&&
    is.finite(cfg$alpha)&&cfg$alpha>0&&cfg$alpha<1,
    "alpha must lie strictly between 0 and 1")
  grid<-cfg$evaluation_grid
  training<-.etr_native_sparse_interpolate(
    proper_training,cfg$dimension,grid)
  mu<-colMeans(training)
  .etr_assert(nrow(training)>=3L,
    "proper training requires at least three independent curves")
  n_cal<-length(calibration$curve_ids)
  quantile_index<-as.integer(ceiling((n_cal+1)*(1-cfg$alpha)))
  .etr_assert(n_cal>=2L&&quantile_index<=n_cal,
    "insufficient independent calibration curves for finite split conformal cutoff")
  score<-numeric(n_cal)
  for(i in seq_len(n_cal)){
    tt<-calibration$time[[i]]
    .etr_assert(all(tt>=grid[1L] & tt<=tail(grid,1L)),
      "calibration observations must be within declared evaluation_grid support")
    j<-match(cfg$dimension,calibration$dimension_names)
    obs<-calibration$values[[i]][,j]
    .etr_assert(all(is.finite(obs)),
      "calibration channel must have complete finite observations")
    pred<-stats::approx(grid,mu,xout=tt,rule=1)$y
    score[i]<-max(abs(obs-pred))
  }
  cutoff<-sort(score)[quantile_index]
  d<-match(cfg$dimension,target$dimension_names)
  bounds<-lapply(seq_along(target$curve_ids),function(i){
    tt<-target$time[[i]]
    .etr_assert(all(tt>=grid[1L] & tt<=tail(grid,1L)),
      "target observed times must lie within declared evaluation_grid support")
    pred<-stats::approx(grid,mu,xout=tt,rule=1)$y
    data.frame(curve_id=target$curve_ids[[i]],time=tt,
      prediction=pred,lower=pred-cutoff,upper=pred+cutoff,
      observed_value_used_for_prediction=FALSE,
      stringsAsFactors=FALSE)
  })
  predictions<-do.call(rbind,bounds);rownames(predictions)<-NULL
  audit<-data.frame(curve_id=calibration$curve_ids,
    maximum_observed_time_residual=score)
  params<-cfg[setdiff(names(cfg),"preprocessing")]
  structure(list(workflow_schema_version=1L,
    workflow_contract="sparse_prediction:native_mean_curve_split_conformal",
    config=cfg,
    fit=list(estimated_mean=mu,time=grid,backend=cfg$backend),
    predictions=predictions,
    calibration_scores=audit,
    cutoff=cutoff,alpha=cfg$alpha,
    steps=list(.etr_source_workflow_step(
      "proper_training_mean_then_curve_max_split_conformal",params)),
    decisions=lapply(params,.etr_source_workflow_decision),
    provenance=list(
      independent_unit="source_curve",
      training_calibration_target_disjoint=TRUE,
      conformal_target="observed_sample_grid_maximum_residual",
      target_values_used_for_model_fit=FALSE,
      finite_sample_rank=quantile_index,
      PACE_partial_curve_scoring=FALSE,
      prediction_future_outcome_scope=FALSE,
      source_python_equivalent=FALSE,
      full_source_contract_certified=FALSE),
    reports=list(fit="Native mean-curve observed-time split conformal baseline; not Python sparse PACE partial-curve predictive inference."),
    tables=list(calibration=audit,predictions=predictions)),
    class="etr_native_sparse_prediction_workflow")
}
