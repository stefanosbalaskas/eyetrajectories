# Frozen Python 1.2 workflows/_dense_regression.py.
# Native base-R working independence GEE; published uses statsmodels GEE.
# No numerical contract is marked independently certified.

#' Run explicitly specified participant-clustered generalized functional GEE
#' @param trajectories Complete native functional trajectories.
#' @param design Curve-aligned numeric design table.
#' @param config Named parameters matching the bounded native GEE fit.
#'   Empty preprocessing required; family/link/basis never auto-selected.
#' @return Native fitted workflow with declared source differences.
#' @export
etr_run_generalized_functional_workflow<-function(
    trajectories,design,config){
  cfg<-.etr_source_workflow_config(config,list(
    predictors=NULL,participant_column=NULL,dimension=NULL,
    family=NULL,binomial_denominator=NULL,exposure=NULL,
    exposure_units=NULL,basis_size=5L,spline_degree=3L,
    working_correlation="independence",covariance_type="robust",
    maxiter=100L,ctol=1e-8,preprocessing=list()),
    required=c("predictors","participant_column","dimension","family"))
  arguments<-cfg[setdiff(names(cfg),"preprocessing")]
  fit<-do.call(etr_fit_generalized_function_on_scalar_regression,
    c(list(trajectories=trajectories,design=design),arguments))
  table<-do.call(rbind,lapply(seq_along(fit$coefficient_names),function(i)
    data.frame(coefficient=fit$coefficient_names[i],time=fit$time,
      estimate=as.numeric(fit$coefficient_functions[i,]),
      standard_error=as.numeric(fit$coefficient_standard_errors[i,]),
      scale="link",family=fit$family,link=fit$link,
      stringsAsFactors=FALSE)))
  rownames(table)<-NULL
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
