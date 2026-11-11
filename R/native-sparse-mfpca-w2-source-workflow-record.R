# Canonical scientific W2 envelopes for paired and asynchronous native
# sparse multivariate PACE.  Python 1.2 source at commit
# c1cd95ad718327550f7e55393ff38582872f7a94:
# workflows/_sparse_mfpca.py, workflows/_sparse_async.py.
# The fit is entirely native R; Python dataclass identity is never claimed.

.etr_sparse_mfpca_w2_observation_config<-function(value){
  if(is.null(value))return(NULL)
  .etr_assert(is.list(value)&&!is.data.frame(value),
    "observation_diagnostics must be a source-style named list")
  defaults<-list(predictors=NULL,history_predictors=character(),
    eccentricity_reference=NULL,risk_set="all_candidates",
    time_basis="linear",time_bins=NULL,association_bins=4L,
    low_support_threshold=.10)
  .etr_assert(!is.null(names(value))&&
    !anyNA(names(value))&&!anyDuplicated(names(value))&&
    all(names(value)%in%names(defaults)),
    "observation_diagnostics contains unsupported source fields")
  for(nm in names(value))defaults[nm]<-list(value[[nm]])
  defaults
}

.etr_sparse_mfpca_w2_uncertainty_config<-function(value){
  if(is.null(value))return(NULL)
  .etr_assert(is.list(value)&&!is.data.frame(value)&&
    (length(value)==0L||!is.null(names(value)))&&
    all(names(value)%in%c("condition_limit","failure_action")),
    "score_uncertainty must contain source condition_limit/failure_action")
  defaults<-list(condition_limit=NULL,failure_action="error")
  for(nm in names(value))defaults[nm]<-list(value[[nm]])
  defaults
}

.etr_sparse_mfpca_w2_paired_config<-function(cfg){
  .etr_assert(is.list(cfg)&&identical(cfg$backend,"native_covariance"),
    "source W2 paired MFPCA requires real native covariance estimator")
  list(
    n_components=cfg$n_components,
    evaluation_grid=as.numeric(cfg$evaluation_grid),
    measurement_error=cfg$measurement_error,
    dimensions=as.character(cfg$dimensions),
    mean_bandwidth=cfg$mean_bandwidth,
    covariance_bandwidth=cfg$covariance_bandwidth,
    bandwidth_selection=.etr_sparse_fpca_w2_source_bandwidth_config(
      cfg$bandwidth_selection),
    measurement_error_variance=cfg$measurement_error_variance,
    measurement_error_covariance=cfg$measurement_error_covariance,
    analysis_support_action=cfg$analysis_support_action,
    psd_action=cfg$psd_action,psd_tolerance=cfg$psd_tolerance,
    positive_eigen_tolerance=cfg$positive_eigen_tolerance,
    score_ridge=cfg$score_ridge,score_condition_limit=cfg$score_condition_limit,
    min_score_time_points=cfg$min_score_time_points,
    score_failure_action=cfg$score_failure_action,
    mean_min_local_points=cfg$mean_min_local_points,
    covariance_min_local_pairs=cfg$covariance_min_local_pairs,
    score_uncertainty=.etr_sparse_mfpca_w2_uncertainty_config(
      cfg$score_uncertainty),
    observation_diagnostics=.etr_sparse_mfpca_w2_observation_config(
      cfg$observation_diagnostics),
    preprocessing=list(steps=list()))
}

.etr_sparse_mfpca_w2_async_config<-function(cfg){
  .etr_assert(is.list(cfg)&&identical(cfg$backend,"native_covariance"),
    "source W2 async MFPCA requires real native covariance estimator")
  list(
    n_components=cfg$n_components,
    evaluation_grid=as.numeric(cfg$evaluation_grid),
    mean_bandwidth=cfg$mean_bandwidth,
    covariance_bandwidth=cfg$covariance_bandwidth,
    measurement_error=cfg$measurement_error,
    dimensions=as.character(cfg$dimensions),
    measurement_error_variance=cfg$measurement_error_variance,
    measurement_error_covariance=cfg$measurement_error_covariance,
    analysis_support_action=cfg$analysis_support_action,
    same_time_tolerance=cfg$same_time_tolerance,
    psd_action=cfg$psd_action,psd_tolerance=cfg$psd_tolerance,
    positive_eigen_tolerance=cfg$positive_eigen_tolerance,
    score_ridge=cfg$score_ridge,
    score_condition_limit=cfg$score_condition_limit,
    min_score_observations=cfg$min_score_observations,
    score_failure_action=cfg$score_failure_action,
    mean_min_local_points=cfg$mean_min_local_points,
    covariance_min_local_pairs=cfg$covariance_min_local_pairs,
    observation_diagnostics=.etr_sparse_mfpca_w2_observation_config(
      cfg$observation_diagnostics),
    preprocessing=list(steps=list()))
}

.etr_sparse_mfpca_w2_paired_record<-function(native,cfg){
  .etr_assert(inherits(native,"etr_native_sparse_mfpca_workflow")&&
    inherits(native$fit,"etr_sparse_mfpca_source"),
    "paired W2 record requires real source-mode joint covariance PACE fit")
  selection<-native$bandwidth_selection
  selected<-!is.null(selection)
  bw<-if(selected)selection$selected_bandwidths else
    list(mean_bandwidth=cfg$mean_bandwidth,
      covariance_bandwidth=cfg$covariance_bandwidth)
  .etr_assert(is.numeric(bw[["mean_bandwidth"]])&&
    length(bw[["mean_bandwidth"]])==1L&&
    is.finite(bw[["mean_bandwidth"]])&&
    bw[["mean_bandwidth"]]>0&&
    is.numeric(bw[["covariance_bandwidth"]])&&
    length(bw[["covariance_bandwidth"]])==1L&&
    is.finite(bw[["covariance_bandwidth"]])&&
    bw[["covariance_bandwidth"]]>0,
    "paired source W2 requires finite accepted bandwidths")
  if(selected)
    .etr_assert(is.character(selection$criterion)&&
      length(selection$criterion)==1L&&nzchar(selection$criterion),
      "audited paired bandwidth choice requires selection criterion")
  decisions<-list(
    n_components=.etr_source_workflow_decision(cfg$n_components),
    mean_bandwidth=.etr_source_workflow_decision(
      as.numeric(bw[["mean_bandwidth"]]),
      if(selected)"audited_selector"else"analyst",
      if(selected)selection$criterion else NULL),
    covariance_bandwidth=.etr_source_workflow_decision(
      as.numeric(bw[["covariance_bandwidth"]]),
      if(selected)"audited_selector"else"analyst",
      if(selected)selection$criterion else NULL),
    measurement_error=.etr_source_workflow_decision(cfg$measurement_error),
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
  result<-structure(list(
    workflow_schema_version=1L,workflow_contract="sparse_mfpca:v1",
    config=.etr_sparse_mfpca_w2_paired_config(cfg),fit=native$fit,
    bandwidth_selection=selection,
    score_uncertainty=native$score_uncertainty,
    observation_diagnostics=native$observation_diagnostics,
    steps=lapply(native$steps,.etr_sparse_fpca_w2_source_step),
    decisions=decisions,
    provenance=list(raw_interpolation_performed=FALSE,
      native_paired_observation_grids_retained=TRUE,
      bandwidth_mode=if(selected)"audited_selector"else"fixed",
      automatic_model_selection_performed=FALSE),
    reports=reports,tables=tables),
    class=c("etr_sparse_mfpca_paired_source_workflow",
      "etr_native_sparse_mfpca_workflow"))
  .etr_assert(identical(names(result),c(
    "workflow_schema_version","workflow_contract","config","fit",
    "bandwidth_selection","score_uncertainty",
    "observation_diagnostics","steps","decisions","provenance",
    "reports","tables")),
    "paired source W2 result schema is not canonical")
  result
}

.etr_sparse_mfpca_w2_async_record<-function(native,cfg){
  .etr_assert(inherits(native,"etr_native_sparse_mfpca_workflow")&&
    inherits(native$fit,"etr_sparse_mfpca_async_source"),
    "async W2 record requires real directional covariance PACE fit")
  decisions<-list(
    n_components=.etr_source_workflow_decision(cfg$n_components),
    mean_bandwidth=.etr_source_workflow_decision(cfg$mean_bandwidth),
    covariance_bandwidth=.etr_source_workflow_decision(
      cfg$covariance_bandwidth),
    measurement_error=.etr_source_workflow_decision(cfg$measurement_error),
    same_time_tolerance=.etr_source_workflow_decision(cfg$same_time_tolerance),
    psd_action=.etr_source_workflow_decision(cfg$psd_action),
    observation_diagnostics_requested=.etr_source_workflow_decision(
      !is.null(cfg$observation_diagnostics)))
  reports<-list(fit=native$reports$fit)
  tables<-list(scores=native$tables$scores)
  if(!is.null(native$observation_diagnostics)){
    reports$observation_diagnostics<-native$reports$observation_diagnostics
    tables$observation_global<-native$tables$observation_global
    tables$observation_time<-native$tables$observation_time
    tables$observation_associations<-native$tables$observation_associations
  }
  result<-structure(list(
    workflow_schema_version=1L,workflow_contract="sparse_mfpca_async:v1",
    config=.etr_sparse_mfpca_w2_async_config(cfg),
    fit=native$fit,
    observation_diagnostics=native$observation_diagnostics,
    steps=lapply(native$steps,.etr_sparse_fpca_w2_source_step),
    decisions=decisions,
    provenance=list(
      raw_interpolation_performed=FALSE,
      raw_synchronization_performed=FALSE,
      time_binning_performed=FALSE,
      coordinate_specific_native_grids_retained=TRUE,
      bandwidth_mode="fixed",
      paired_bandwidth_selector_reused=FALSE,
      automatic_model_selection_performed=FALSE),
    reports=reports,tables=tables),
    class=c("etr_sparse_mfpca_async_source_workflow",
      "etr_native_sparse_mfpca_workflow"))
  .etr_assert(identical(names(result),c(
    "workflow_schema_version","workflow_contract","config","fit",
    "observation_diagnostics","steps","decisions","provenance",
    "reports","tables")),
    "async source W2 result schema is not canonical")
  result
}
