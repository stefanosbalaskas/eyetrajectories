# Frozen Python 1.2 workflows/_dense_regression.py.
# Native base-R working independence GEE; published uses statsmodels GEE.
# No numerical contract is marked independently certified.

#' Run explicitly specified participant-clustered generalized functional GEE
#' @param trajectories Complete native functional trajectories.
#' @param design Curve-aligned numeric design table.
#' @param config Named parameters matching the bounded native GEE fit.
#'   Empty preprocessing required; family/link/basis never auto-selected.
#' @param python_boundary_mode Use source-order input and the version-one
#'   workflow audit fields, including measured fit time and source reports.
#' @return Native fitted workflow with declared source differences.
#' @export
etr_run_generalized_functional_workflow<-function(
    trajectories,design,config,python_boundary_mode=FALSE){
  .etr_assert(is.logical(python_boundary_mode)&&length(python_boundary_mode)==1L&&
    !is.na(python_boundary_mode),"python_boundary_mode must be TRUE or FALSE")
  cfg<-.etr_source_workflow_config(config,list(
    predictors=NULL,participant_column=NULL,dimension=NULL,
    family=NULL,binomial_denominator=NULL,exposure=NULL,
    exposure_units=NULL,basis_size=5L,spline_degree=3L,
    working_correlation="independence",covariance_type="robust",
    maxiter=100L,ctol=1e-8,preprocessing=list()),
    required=c("predictors","participant_column","dimension","family"))
  if(python_boundary_mode){
    cfg$family<-tolower(trimws(.etr_gfosr_predict_scalar(cfg$family,"family")))
    for(name in c("binomial_denominator","exposure")){
      value<-cfg[[name]]
      if(!is.null(value)){
        shape<-dim(value)
        value<-as.numeric(.etr_gfosr_numeric_values(value,name,numpy=TRUE))
        if(!is.null(shape))dim(value)<-shape
        cfg[[name]]<-value
      }
    }
  }
  arguments<-cfg[setdiff(names(cfg),"preprocessing")]
  start<-proc.time()[["elapsed"]]
  fit<-do.call(etr_fit_generalized_function_on_scalar_regression,
    c(list(trajectories=trajectories,design=design,
      python_boundary_mode=python_boundary_mode),arguments))
  elapsed<-proc.time()[["elapsed"]]-start
  table<-etr_generalized_function_on_scalar_coefficient_frame(fit)
  if(python_boundary_mode){
    arguments$predictors<-unname(as.list(arguments$predictors))
    step<-list(name="fit",
      `function`="fit_generalized_function_on_scalar_regression",
      status="completed",parameters=arguments,
      elapsed_seconds=elapsed,warnings=character())
    values<-arguments[c("predictors","participant_column","dimension","family")]
    values$binomial_denominator_supplied<-!is.null(cfg$binomial_denominator)
    values$exposure_supplied<-!is.null(cfg$exposure)
    values<-c(values,arguments[c("exposure_units","basis_size","spline_degree",
      "working_correlation","covariance_type")])
    decisions<-lapply(values,.etr_source_workflow_decision)
    provenance<-list(input_layout="complete_common_grid",
      preprocessing_executed=FALSE,automatic_family_selection=FALSE,
      binomial_denominator_inferred=FALSE,poisson_exposure_inferred=FALSE,
      automatic_working_correlation_selection=FALSE,
      automatic_model_selection_performed=FALSE)
    return(structure(list(workflow_schema_version=1L,
      workflow_contract="generalized_functional:v1",config=cfg,fit=fit,
      steps=list(step),decisions=decisions,provenance=provenance,
      reports=list(fit=etr_generalized_function_on_scalar_reporting_text(fit)),
      tables=list(coefficients=table)),
      class=c("etr_generalized_functional_workflow","etr_workflow_audit_result")))
  }
  source_names<-c("predictors","participant_column","dimension","family",
    "binomial_denominator","exposure","exposure_units","basis_size",
    "spline_degree","working_correlation","covariance_type","maxiter","ctol")
  decisions<-lapply(cfg[source_names],.etr_source_workflow_decision)
  structure(list(workflow_schema_version=1L,
    workflow_contract="generalized_functional:native_independence_gee",
    config=cfg,fit=fit,steps=list(.etr_source_workflow_step(
      "fit_generalized_function_on_scalar_regression",
      arguments)),
    decisions=decisions,
    provenance=list(input_layout="complete_common_grid",
      preprocessing_executed=FALSE,automatic_family_selection=FALSE,
      automatic_link_selection=FALSE,
      automatic_basis_selection=FALSE,
      automatic_model_selection_performed=FALSE,
      independent_unit="participant",
      native_solver="base_R_glm_fit_cluster_robust_sandwich",
      python_solver="statsmodels_GEE",
      source_schema_equivalent=FALSE,
      independently_certified_full_contract=FALSE),
    reports=list(fit=paste0("Native explicitly specified ",
      fit$family,"/",fit$link,
      " functional GEE with participant-cluster sandwich and ",
      fit$basis_size," B-spline basis functions; ",
      "source Python backend and schema not independently certified.")),
    tables=list(coefficients=table)),
    class="etr_generalized_functional_workflow")
}
