# Bounded Python-free workflow orchestration, frozen Python 1.2 W3 semantics.
# Python dataclasses, timing records and publication schema remain unported.
# These are native R records; NOT fully certified Python-source contracts.

.etr_source_workflow_config <- function(config,defaults,required=character()){
  .etr_assert(is.list(config)&&!is.data.frame(config)&&
    (length(config)==0L||(!is.null(names(config))&&
      !anyNA(names(config))&&all(nzchar(names(config)))&&
      !anyDuplicated(names(config)))),
    "config must be a named list with distinct keys")
  .etr_assert(all(names(config)%in%names(defaults)),
    "config contains unsupported fields; no implicit workflow actions")
  .etr_assert(all(required%in%names(config)),
    "config is missing mandatory explicit parameters")
  for(nm in names(config))defaults[nm]<-list(config[[nm]])
  .etr_assert(is.list(defaults$preprocessing)&&
    length(defaults$preprocessing)==0L,
    "workflow requires empty preprocessing; no hidden transformation")
  defaults
}
.etr_source_workflow_decision <- function(value,source="analyst",criterion=NULL){
  list(value=value,source=source,criterion=criterion)
}
.etr_source_workflow_step <- function(fun,parameters) {
  # Native R performs the synchronous fit prior to creating this record.
  # No fabricated time/performance observations are reported.
  list(name="fit",`function`=fun,parameters=parameters,status="completed",
    duration_seconds=NA_real_,duration_measured=FALSE)
}

#' Run native common-grid FPCA through a strictly declarative workflow
#'
#' @param trajectories Complete common-grid native trajectories.
#' @param config Named list with n_components, scaling and empty preprocessing.
#' @return Source-inspired native workflow with FPCA fit, scores, variance
#'   table, declarations and complete audit of absent preprocessing.
#' @export
etr_run_fpca_workflow <- function(trajectories,config=list()){
  etr_validate(trajectories,require_complete=TRUE)
  cfg<-.etr_source_workflow_config(config,
    list(n_components=.95,scaling="none",preprocessing=list()))
  .etr_assert(is.character(cfg$scaling)&&length(cfg$scaling)==1L&&
    !is.na(cfg$scaling)&&cfg$scaling%in%c("none","dimension_sd"),
    "scaling must be none or dimension_sd")
  .etr_assert(is.numeric(cfg$n_components)&&length(cfg$n_components)==1L&&
    !is.na(cfg$n_components)&&is.finite(cfg$n_components)&&
    ((typeof(cfg$n_components)=="integer"&&cfg$n_components>=1L)||
     (typeof(cfg$n_components)=="double"&&cfg$n_components>0&&
      cfg$n_components<1)),
    "n_components must be positive integer or fraction strictly between 0 and 1")
  fit<-etr_fit_fpca(trajectories,
    n_components=cfg$n_components,scaling=cfg$scaling)
  parameters=list(n_components=cfg$n_components,scaling=cfg$scaling)
  structure(list(workflow_schema_version=1L,
    workflow_contract="fpca:v1",config=cfg,fit=fit,
    steps=list(.etr_source_workflow_step("fit_fpca",parameters)),
    decisions=list(
      requested_n_components=.etr_source_workflow_decision(cfg$n_components),
      retained_n_components=.etr_source_workflow_decision(
        fit$n_components,"derived",
        "resolved from declared component count or variance threshold"),
      scaling=.etr_source_workflow_decision(cfg$scaling)),
    provenance=list(input_layout="complete_common_grid",
      preprocessing_executed=FALSE,
      automatic_model_selection_performed=FALSE,
      component_resolution_rule_changed=FALSE,
      source_schema_equivalent=FALSE),
    reports=list(fit=paste0("Native quadrature FPCA retained ",
      fit$n_components," component(s), scaling=",cfg$scaling,".")),
    tables=list(scores=etr_fpca_scores(fit),
      explained_variance=etr_fpca_variance_frame(fit))),
    class="etr_fpca_workflow")
}

#' Run native observed-grid function-on-scalar regression declaratively
#'
#' @param trajectories Complete common-grid functional responses.
#' @param design Curve-aligned numeric predictor data.frame.
#' @param config Explicit predictors, optional dimensions and unit, and
#'   empty preprocessing. No hidden interpolation or encoding is performed.
#' @return Native FOS fit with auditable decisions, coefficients and provenance.
#' @export
etr_run_function_on_scalar_workflow <- function(
    trajectories,design,config){
  etr_validate(trajectories,require_complete=TRUE)
  cfg<-.etr_source_workflow_config(config,
    list(predictors=NULL,dimensions=NULL,participant_column=NULL,
      unit="curve",preprocessing=list()),required="predictors")
  .etr_assert(is.character(cfg$predictors)&&length(cfg$predictors)>=1L&&
    !anyNA(cfg$predictors)&&all(nzchar(cfg$predictors))&&
    !anyDuplicated(cfg$predictors),
    "predictors must contain unique nonempty names")
  .etr_assert(cfg$unit%in%c("curve","participant")&&
    length(cfg$unit)==1L&&!is.na(cfg$unit),
    "unit must be curve or participant")
  .etr_assert((cfg$unit=="curve"&&is.null(cfg$participant_column))||
    (cfg$unit=="participant"&&is.character(cfg$participant_column)&&
      length(cfg$participant_column)==1L&&nzchar(cfg$participant_column)),
    "participant_column must match declared inference unit")
  fit<-etr_fit_function_on_scalar_regression(trajectories,
    design,predictors=cfg$predictors,dimensions=cfg$dimensions,
    participant_column=cfg$participant_column,unit=cfg$unit)
  parameters=cfg[c("predictors","dimensions","participant_column","unit")]
  decisions=lapply(parameters,.etr_source_workflow_decision)
  structure(list(workflow_schema_version=1L,
    workflow_contract="function_on_scalar:v1",config=cfg,fit=fit,
    steps=list(.etr_source_workflow_step(
      "fit_function_on_scalar_regression",parameters)),
    decisions=decisions,
    provenance=list(input_layout="complete_common_grid",
      preprocessing_executed=FALSE,
      automatic_predictor_encoding=FALSE,
      automatic_model_selection_performed=FALSE,
      functional_mixed_effects_inferred=FALSE,
      source_schema_equivalent=FALSE),
    reports=list(fit=paste0("Native observed-grid OLS: ",
      fit$unit,", ",length(fit$predictor_names),
      " predictor(s); source reporting text unqualified.")),
    tables=list(coefficients=etr_function_on_scalar_coefficient_frame(fit))),
    class="etr_function_on_scalar_workflow")
}
