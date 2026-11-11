# Frozen Python 1.2 W3 source-scientific workflow presentation.
# Python source: workflows/_dense_regression.py and reporting.py at
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Native estimators, timings and scientific tensors are real R calculations,
# and neither sklearn model identity nor Python dataclass identity is claimed.

.etr_w3_source_elapsed_step<-function(name,parameters,start){
  duration<-max(0,as.numeric(proc.time()[["elapsed"]]-start))
  etr_frozen_workflow_step_record("fit",name,"completed",
    parameters=parameters,elapsed_seconds=duration,warnings=character())
}

.etr_w3_source_fpca_report<-function(fit){
  .etr_assert(inherits(fit,"etr_fpca")&&fit$n_components>=1L&&
    length(fit$explained_variance_ratio)==fit$n_components,
    "source FPCA report requires a complete native FPCA fit")
  individual<-100*as.numeric(fit$explained_variance_ratio)
  head<-paste(sprintf("FPC%d=%.1f%%",seq_len(min(length(individual),4L)),
    individual[seq_len(min(length(individual),4L))]),collapse=", ")
  pct<-100*sum(fit$explained_variance_ratio)
  paste0("Functional PCA retained ",fit$n_components,
    " component(s), explaining ",sprintf("%.1f",pct),
    "% of the weighted functional variance (",head,
    "). The analysis used ",fit$coordinate_system," coordinates, ",
    "time unit '",fit$time_unit,"', and channel scaling='",
    fit$scaling,"'.")
}

.etr_w3_source_fos_report<-function(fit){
  .etr_function_scalar_result_check(fit)
  predictors<-paste(fit$predictor_names,collapse=", ")
  dimensions<-paste(fit$dimension_names,collapse=", ")
  n_units<-length(fit$unit_ids)
  scope<-if(identical(fit$unit,"participant"))
    paste0(n_units," participant-average functional responses from ",
      length(fit$source_curve_ids),
      " source curves; declared predictors were required to be constant within participant")
  else paste0(n_units,
    " curve-level functional responses treated as independent inference units")
  paste0(
    "Function-on-scalar regression was fitted by ordinary least squares ",
    "independently at each observed time-by-dimension grid point with a ",
    "shared design matrix (predictors: ",predictors,
    "; functional dimensions: ",dimensions,
    "). Inference used ",scope,
    ". Pointwise standard errors used the HC1 sandwich estimator. No ",
    "functional smoothing, basis regularization, automatic categorical ",
    "encoding, predictor scaling, interaction construction, or model ",
    "selection was performed. The model is not a functional mixed-effects ",
    "model, and any simultaneous-band claim applies to the observed grid ",
    "rather than unsampled times.")
}

.etr_w3_source_fpca_result<-function(result,trajectories){
  .etr_assert(inherits(result,"etr_fpca_workflow")&&
    inherits(result$fit,"etr_fpca"),
    "FPCA source boundary requires a real native FPCA workflow")
  fit<-result$fit
  source_config<-list(n_components=result$config$n_components,
    scaling=result$config$scaling,
    preprocessing=list(steps=list()))
  source_fit_provenance<-trajectories$provenance
  if(is.null(source_fit_provenance))source_fit_provenance<-list()
  source_fit_provenance$fpca<-list(
    method="quadrature_weighted_grid_pca",
    n_components=as.integer(fit$n_components),
    requested_n_components=source_config$n_components,
    scaling=source_config$scaling)
  fit$provenance<-source_fit_provenance
  decisions<-list(
    requested_n_components=.etr_source_workflow_decision(
      source_config$n_components,"analyst"),
    retained_n_components=.etr_source_workflow_decision(
      as.integer(fit$n_components),"derived",
      "resolved by fit_fpca from the analyst-declared component count or variance threshold"),
    scaling=.etr_source_workflow_decision(source_config$scaling,"analyst"))
  table<-data.frame(component=seq_len(fit$n_components),
    explained_variance=as.numeric(fit$explained_variance),
    explained_variance_ratio=as.numeric(fit$explained_variance_ratio),
    cumulative_variance_ratio=cumsum(fit$explained_variance_ratio),
    check.names=FALSE)
  result$config<-source_config
  result$fit<-fit
  result$decisions<-decisions
  result$provenance<-list(input_layout="complete_common_grid",
    preprocessing_executed=FALSE,
    automatic_model_selection_performed=FALSE,
    component_resolution_rule_changed=FALSE)
  result$reports<-list(fit=.etr_w3_source_fpca_report(fit))
  result$tables<-list(scores=etr_fpca_scores(fit),
    explained_variance=table)
  result
}

.etr_w3_source_fos_result<-function(result){
  .etr_assert(inherits(result,"etr_function_on_scalar_workflow")&&
    inherits(result$fit,"etr_function_on_scalar"),
    "FOS source boundary requires a real native observed-grid regression")
  cfg<-result$config
  result$config<-list(predictors=cfg$predictors,
    dimensions=cfg$dimensions,participant_column=cfg$participant_column,
    unit=cfg$unit,preprocessing=list(steps=list()))
  parameters<-result$config[c("predictors","dimensions",
    "participant_column","unit")]
  result$decisions<-lapply(parameters,
    function(value).etr_source_workflow_decision(value,"analyst"))
  result$provenance<-list(input_layout="complete_common_grid",
    preprocessing_executed=FALSE,
    automatic_predictor_encoding=FALSE,
    automatic_model_selection_performed=FALSE,
    functional_mixed_effects_inferred=FALSE)
  result$reports<-list(fit=.etr_w3_source_fos_report(result$fit))
  result$tables<-list(coefficients=
    etr_function_on_scalar_coefficient_frame(result$fit))
  result
}
