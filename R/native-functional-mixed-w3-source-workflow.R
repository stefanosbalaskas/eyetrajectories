# Frozen Python 1.2 Gaussian functional mixed-effects workflow SCIENTIFIC
# envelope: workflows/_dense_regression.py::run_functional_mixed_effects_workflow
# and dataclasses FunctionalMixedEffectsWorkflowConfig / Result.
# Pinned source c1cd95ad718327550f7e55393ff38582872f7a94.
#
# Native fit is real nlme Gaussian spline likelihood, not statsmodels MixedLM.
# No Python class, optimizer or literal report-text parity is claimed.
# No model-selection, covariance, fallback or preprocessing substitutions.

.etr_joint_w3_config_fields<-c(
  "predictors","participant_column","dimension","fixed_basis_size",
  "random_basis_size","random_slope_predictor","trial_column",
  "trial_random_effect","trial_random_basis_size",
  "residual_correlation","spline_degree","reml","method","maxiter",
  "preprocessing")

.etr_joint_w3_workflow_fields<-c(
  "workflow_schema_version","workflow_contract","config","fit",
  "steps","decisions","provenance","reports","tables")

.etr_joint_w3_provenance_fields<-c(
  "input_layout","preprocessing_executed",
  "automatic_random_effect_selection",
  "automatic_residual_correlation_selection",
  "automatic_optimizer_fallback",
  "automatic_model_selection_performed")

.etr_joint_w3_step_fields<-c(
  "name","function","status","parameters",
  "elapsed_seconds","warnings")

.etr_joint_workflow_w3_execute<-function(trajectories,design,config){
  .etr_assert(is.list(config)&&!is.data.frame(config)&&
    identical(config$estimator,"native_joint_bspline_gaussian"),
    "source-scientific mixed workflow requires Gaussian spline likelihood")
  # Frozen Python default is 3; native R default is 4. Use the declared
  # Python default only in strict scientific workflow mode. For nested
  # models where degree 3 requires >= 4, the genuine native estimator
  # rejects that unidentifiable default; no hidden adjustment is made.
  source_cfg<-config
  if(!"trial_random_basis_size"%in%names(source_cfg))
    source_cfg$trial_random_basis_size<-3L
  warnings<-character()
  started<-proc.time()[["elapsed"]]
  # One and only one genuine Gaussian mixed likelihood fit. Record the
  # observed end-to-end native fit-and-audit time instead of inventing
  # Python timed_step values; warnings are signaled normally.
  native<-withCallingHandlers(
    .etr_source_joint_bspline_workflow(
      trajectories,design,source_cfg),
    warning=function(w)
      warnings<<-c(warnings,conditionMessage(w)))
  elapsed<-max(0,as.numeric(proc.time()[["elapsed"]]-started))
  .etr_assert(inherits(native$fit,"etr_joint_bspline_mixed")&&
    inherits(native$fit$fitted_model,"lme")&&
    identical(native$fit$backend,"nlme::lme")&&
    is.finite(native$fit$residual_variance)&&
    native$fit$residual_variance>0,
    "strict native source workflow requires completed Gaussian joint fit")
  cfg<-native$config
  .etr_assert(all(.etr_joint_w3_config_fields[-15L]%in%names(cfg))&&
    identical(cfg$method,"nlme::lme")&&
    identical(cfg$estimator,"native_joint_bspline_gaussian")&&
    is.list(cfg$preprocessing)&&length(cfg$preprocessing)==0L,
    "strict native source W3 scientific config or estimator incomplete")
  parameters<-cfg[.etr_joint_w3_config_fields[-15L]]
  .etr_assert(identical(names(parameters),
    .etr_joint_w3_config_fields[-15L]),
    "source mixed workflow parameter ordering is incomplete")
  source_config<-parameters
  source_config$preprocessing<-list(steps=list())
  .etr_assert(identical(names(source_config),
    .etr_joint_w3_config_fields),
    "source mixed W3 config must contain exactly fifteen ordered fields")
  .etr_assert(length(native$steps)==1L&&
    is.character(native$steps[[1L]][["function"]])&&
    length(native$steps[[1L]][["function"]])==1L,
    "native mixed workflow must have a single explicit likelihood fitting step")
  step<-list(
    name="fit",
    `function`=native$steps[[1L]][["function"]],
    status="completed",
    parameters=parameters,
    elapsed_seconds=elapsed,
    warnings=warnings)
  .etr_assert(identical(names(step),.etr_joint_w3_step_fields),
    "source W3 step is missing an audit field")
  decisions<-lapply(parameters,.etr_source_workflow_decision)
  .etr_assert(identical(names(decisions),names(parameters))&&
    all(vapply(decisions,function(x)
      identical(x$source,"analyst"),logical(1L))),
    "native W3 decisions must preserve analyst parameter provenance")
  .etr_assert(all(.etr_joint_w3_provenance_fields%in%
    names(native$provenance)),
    "native W3 must declare absence of automatic selection and preprocessing")
  provenance<-native$provenance[.etr_joint_w3_provenance_fields]
  .etr_assert(identical(names(provenance),
    .etr_joint_w3_provenance_fields)&&
    identical(provenance$input_layout,"complete_common_grid")&&
    all(!unlist(provenance[-1L],use.names=FALSE)),
    "native W3 has unexpected preprocessing or automatic selection")
  table<-native$tables$coefficients
  .etr_assert(is.data.frame(table)&&
    identical(names(table),c(
      "coefficient","time","dimension","estimate",
      "standard_error","lower_95_wald","upper_95_wald"))&&
    nrow(table)==length(native$fit$time)*
      nrow(native$fit$fixed_coefficient_functions)&&
    all(is.finite(table$estimate))&&
    all(is.finite(table$standard_error)),
    "source W3 mixed coefficient scientific table is incomplete")
  .etr_assert(is.list(native$reports)&&
    is.character(native$reports$fit)&&length(native$reports$fit)==1L,
    "native W3 likelihood reporting was not completed")
  result<-list(
    workflow_schema_version=1L,
    workflow_contract="functional_mixed_effects:v1",
    config=source_config,
    fit=native$fit,
    steps=list(step),
    decisions=decisions,
    provenance=provenance,
    reports=native$reports,
    tables=native$tables)
  .etr_assert(identical(names(result),.etr_joint_w3_workflow_fields),
    "native Gaussian source W3 workflow result field ordering changed")
  structure(result,class=c(
    "etr_functional_mixed_effects_w3_scientific_workflow",
    "etr_functional_mixed_effects_workflow"))
}
