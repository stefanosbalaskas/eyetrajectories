# Source-scientific native R representation of the frozen W2 sparse workflow.
# Frozen Python 1.2 commit c1cd95ad718327550f7e55393ff38582872f7a94
# src/eyetrajectoriespy/workflows/_sparse_fpca.py.
# Native source PACE estimation is retained; this is never a Python dataclass.

.etr_sparse_fpca_w2_source_bandwidth_config<-function(value){
  if(is.null(value))return(NULL)
  .etr_assert(is.list(value)&&!is.data.frame(value),
    "bandwidth_selection must be an explicit source configuration")
  .etr_assert(is.null(value$fold_assignments),
    "strict sparse W2 source cannot use R-only supplied fold assignments")
  defaults<-list(mean_bandwidths=NULL,covariance_bandwidths=NULL,
    n_splits=5L,resampling_unit="curve",group_column=NULL,
    shuffle=TRUE,random_state=0L,min_valid_folds=NULL,
    failure_action="retain",predictive_condition_limit=1e12)
  .etr_assert(all(names(value)%in%
    c(names(defaults),"group_tie_order")),
    "bandwidth_selection contains unsupported source fields")
  if(identical(value$resampling_unit,"group"))
    .etr_assert(identical(value$group_tie_order,"numpy_scalar")||
      identical(value$group_tie_order,"numpy_simd"),
      "group bandwidth selection requires a declared source NumPy tie profile")
  for(nm in intersect(names(defaults),names(value)))
    defaults[nm]<-list(value[[nm]])
  defaults
}

.etr_sparse_fpca_w2_source_config<-function(cfg){
  .etr_assert(is.list(cfg)&&identical(cfg$backend,"native_covariance"),
    "source W2 sparse workflow requires native_covariance estimator")
  selection<-.etr_sparse_fpca_w2_source_bandwidth_config(
    cfg$bandwidth_selection)
  request<-cfg$score_uncertainty
  if(!is.null(request)){
    .etr_assert(is.list(request)&&!is.data.frame(request)&&
      all(names(request)%in%c("condition_limit","failure_action")),
      "score_uncertainty must use frozen source fields")
    defaults<-list(condition_limit=NULL,failure_action="error")
    for(nm in names(request))defaults[nm]<-list(request[[nm]])
    request<-defaults
  }
  observation<-cfg$observation_diagnostics
  if(!is.null(observation)){
    .etr_assert(is.list(observation)&&!is.data.frame(observation),
      "observation_diagnostics must use frozen source fields")
    defaults<-list(predictors=NULL,history_predictors=character(),
      eccentricity_reference=NULL,risk_set="all_candidates",
      time_basis="linear",time_bins=NULL,association_bins=4L,
      low_support_threshold=.10)
    .etr_assert(all(names(observation)%in%names(defaults)),
      "observation_diagnostics contains unsupported source fields")
    for(nm in names(observation))defaults[nm]<-list(observation[[nm]])
    observation<-defaults
  }
  list(
    dimension=cfg$dimension,n_components=cfg$n_components,
    evaluation_grid=as.numeric(cfg$evaluation_grid),
    mean_bandwidth=cfg$mean_bandwidth,
    covariance_bandwidth=cfg$covariance_bandwidth,
    bandwidth_selection=selection,
    noise_bandwidth=cfg$noise_bandwidth,noise_support=cfg$noise_support,
    analysis_support_action=cfg$analysis_support_action,
    mean_smoother=cfg$mean_smoother,
    covariance_smoother=cfg$covariance_smoother,
    kernel=cfg$kernel,noise_variance_method=cfg$noise_variance_method,
    measurement_error_variance=cfg$measurement_error_variance,
    psd_action=cfg$psd_action,psd_tolerance=cfg$psd_tolerance,
    positive_eigen_tolerance=cfg$positive_eigen_tolerance,
    score_ridge=cfg$score_ridge,
    score_condition_limit=cfg$score_condition_limit,
    min_score_samples=cfg$min_score_samples,
    score_failure_action=cfg$score_failure_action,
    mean_min_local_points=cfg$mean_min_local_points,
    covariance_min_local_pairs=cfg$covariance_min_local_pairs,
    noise_min_local_points=cfg$noise_min_local_points,
    score_uncertainty=request,observation_diagnostics=observation,
    preprocessing=list(steps=list()))
}

.etr_sparse_fpca_w2_source_step<-function(step){
  .etr_assert(is.list(step)&&is.character(step$name)&&
    is.character(step[["function"]])&&
    is.character(step$status)&&identical(step$status,"completed")&&
    is.list(step$parameters)&&
    is.numeric(step$elapsed_seconds)&&length(step$elapsed_seconds)==1L&&
    is.finite(step$elapsed_seconds)&&step$elapsed_seconds>=0,
    "source sparse W2 workflow requires truly timed completed steps")
  list(name=step$name,`function`=step[["function"]],status=step$status,
    parameters=step$parameters,elapsed_seconds=step$elapsed_seconds,
    warnings=as.character(step$warnings))
}

.etr_sparse_fpca_source_workflow_record<-function(native,cfg){
  .etr_assert(inherits(native,"etr_sparse_fpca_workflow")&&
    inherits(native$fit,"etr_sparse_fpca_native"),
    "source W2 workflow requires a real native sparse covariance fit")
  config<-.etr_sparse_fpca_w2_source_config(cfg)
  selection<-native$bandwidth_selection
  selected<-!is.null(selection)
  mean_bw<-if(selected)as.numeric(selection$selected_bandwidths[["mean_bandwidth"]]) else cfg$mean_bandwidth
  cov_bw<-if(selected)as.numeric(selection$selected_bandwidths[["covariance_bandwidth"]]) else cfg$covariance_bandwidth
  .etr_assert(is.numeric(mean_bw)&&length(mean_bw)==1L&&
    is.finite(mean_bw)&&mean_bw>0&&
    is.numeric(cov_bw)&&length(cov_bw)==1L&&
    is.finite(cov_bw)&&cov_bw>0,
    "source W2 workflow requires accepted fixed or selected bandwidths")
  if(selected){
    .etr_assert(is.character(selection$criterion)&&
      length(selection$criterion)==1L&&nzchar(selection$criterion),
      "source W2 audited selection requires criterion")
  }
  decisions<-list(
    n_components=.etr_source_workflow_decision(cfg$n_components),
    mean_bandwidth=.etr_source_workflow_decision(mean_bw,
      if(selected)"audited_selector"else"analyst",
      if(selected)selection$criterion else NULL),
    covariance_bandwidth=.etr_source_workflow_decision(cov_bw,
      if(selected)"audited_selector"else"analyst",
      if(selected)selection$criterion else NULL),
    noise_variance_method=.etr_source_workflow_decision(cfg$noise_variance_method),
    psd_action=.etr_source_workflow_decision(cfg$psd_action),
    score_uncertainty_requested=.etr_source_workflow_decision(
      !is.null(cfg$score_uncertainty)),
    observation_diagnostics_requested=.etr_source_workflow_decision(
      !is.null(cfg$observation_diagnostics)))
  reports<-list(fit=native$reports$fit)
  tables<-list(scores=native$tables$scores)
  if(selected){
    reports$bandwidth_selection<-native$reports$bandwidth_selection
    tables$bandwidth_candidates<-native$tables$bandwidth_candidates
    tables$bandwidth_curve_losses<-native$tables$bandwidth_curve_losses
  }
  if(!is.null(native$score_uncertainty)){
    reports$score_uncertainty<-native$reports$score_uncertainty
    tables$score_uncertainty<-native$tables$score_uncertainty
  }
  if(!is.null(native$observation_diagnostics)){
    reports$observation_diagnostics<-native$reports$observation_diagnostics
    tables$observation_global<-native$tables$observation_global
    tables$observation_time<-native$tables$observation_time
    tables$observation_associations<-native$tables$observation_associations
  }
  provenance<-list(
    raw_interpolation_performed=FALSE,
    native_observation_grids_retained=TRUE,
    bandwidth_mode=if(selected)"audited_selector"else"fixed",
    automatic_model_selection_performed=FALSE)
  out<-structure(list(
    workflow_schema_version=1L,workflow_contract="sparse_fpca:v1",
    config=config,fit=native$fit,
    bandwidth_selection=selection,
    score_uncertainty=native$score_uncertainty,
    observation_diagnostics=native$observation_diagnostics,
    steps=lapply(native$steps,.etr_sparse_fpca_w2_source_step),
    decisions=decisions,provenance=provenance,
    reports=reports,tables=tables),
    class=c("etr_sparse_fpca_source_workflow","etr_sparse_fpca_workflow"))
  .etr_assert(identical(names(out),c(
    "workflow_schema_version","workflow_contract","config","fit",
    "bandwidth_selection","score_uncertainty",
    "observation_diagnostics","steps","decisions","provenance",
    "reports","tables")),
    "native sparse W2 source workflow schema differs from frozen Python")
  out
}
