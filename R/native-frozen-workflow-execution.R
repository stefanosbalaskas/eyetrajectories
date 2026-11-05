# Executable native R adapters for a bounded subset of frozen Python
# workflow configs. No Python runtime, estimator duplication or parity approval.
# Source pinned at c1cd95ad718327550f7e55393ff38582872f7a94.

.etr_frozen_empty_plan <- function(preprocessing) {
  if(is.null(preprocessing))
    return(etr_frozen_workflow_record("PreprocessingPlan",
      list(steps=list())))
  .etr_assert(inherits(preprocessing,"etr_frozen_py12_PreprocessingPlan") &&
    identical(names(preprocessing),"steps") &&
    is.list(preprocessing$steps),
    "preprocessing must be a frozen native PreprocessingPlan record")
  preprocessing
}

#' Native FPCA workflow config with source-aligned fields and validation
#' @param n_components Positive integer count, or float proportion within (0,1].
#' @param scaling Either none or dimension_sd.
#' @param preprocessing Frozen native preprocessing plan, NULL means empty.
#' @return Native record, not a Python class or source-certified estimator.
#' @export
etr_frozen_fpca_workflow_config <- function(n_components=0.95,
    scaling="none",preprocessing=NULL) {
  .etr_assert(is.numeric(n_components)&&length(n_components)==1L&&
    !is.na(n_components)&&is.finite(n_components)&&
    ((typeof(n_components)=="integer"&&n_components>=1L)||
      (typeof(n_components)=="double"&&
       n_components>0&&n_components<=1)),
    "n_components must be an integer count or finite proportion in (0,1]")
  .etr_assert(is.character(scaling)&&length(scaling)==1L&&
    !is.na(scaling)&&scaling%in%c("none","dimension_sd"),
    "scaling must be none or dimension_sd")
  etr_frozen_workflow_record("FPCAWorkflowConfig",
    list(n_components=n_components,scaling=scaling,
      preprocessing=.etr_frozen_empty_plan(preprocessing)))
}

#' Native function-on-scalar workflow config with source-aligned fields
#' @param predictors Nonempty distinct predictor names.
#' @param dimensions Optional distinct scientific channel names.
#' @param participant_column Optional grouping column.
#' @param unit curve or participant.
#' @inheritParams etr_frozen_fpca_workflow_config
#' @export
etr_frozen_function_on_scalar_workflow_config <- function(
    predictors,dimensions=NULL,participant_column=NULL,
    unit="curve",preprocessing=NULL) {
  .etr_assert(is.character(predictors)&&length(predictors)>=1L&&
    !anyNA(predictors)&&all(nzchar(predictors))&&
    !anyDuplicated(predictors),
    "predictors must contain unique nonempty names")
  .etr_assert(is.null(dimensions)||
    (is.character(dimensions)&&length(dimensions)>0L&&
      !anyNA(dimensions)&&all(nzchar(dimensions))&&
      !anyDuplicated(dimensions)),
    "dimensions must be NULL or distinct nonempty names")
  .etr_assert(is.character(unit)&&length(unit)==1L&&
    !is.na(unit)&&unit%in%c("curve","participant"),
    "unit must be curve or participant")
  .etr_assert((unit=="curve"&&is.null(participant_column))||
    (unit=="participant"&&is.character(participant_column)&&
      length(participant_column)==1L&&!is.na(participant_column)&&
      nzchar(participant_column)),
    "participant_column must agree with the inference unit")
  etr_frozen_workflow_record("FunctionOnScalarWorkflowConfig",
    list(predictors=predictors,dimensions=dimensions,
      participant_column=participant_column,unit=unit,
      preprocessing=.etr_frozen_empty_plan(preprocessing)))
}

#' Source-aligned recurrence configuration for native R execution
#' @param curve Curve ID or zero-based curve index.
#' @param dimensions Nonempty distinct channels.
#' @param embedding_dimension Positive embedded state size.
#' @param delay Positive lag.
#' @param radius Positive finite radius.
#' @param delay_units Delay units, native executor requires samples.
#' @param metric Source metric: cityblock, euclidean, or chebyshev.
#' @param theiler_window Exclusion lag, nonnegative integer.
#' @param theiler_window_units Exclusion lag units.
#' @param min_diagonal_length,min_vertical_length Positive RQA line minima.
#' @inheritParams etr_frozen_fpca_workflow_config
#' @export
etr_frozen_recurrence_workflow_config <- function(curve,dimensions,
    embedding_dimension,delay,radius,delay_units="samples",
    metric="euclidean",theiler_window=0L,
    theiler_window_units="samples",min_diagonal_length=2L,
    min_vertical_length=2L,preprocessing=NULL) {
  .etr_assert((is.character(curve)&&length(curve)==1L&&
    !is.na(curve)&&nzchar(curve))||
    (is.numeric(curve)&&length(curve)==1L&&is.finite(curve)&&
      curve==floor(curve)&&curve>=0),
    "curve must be zero-based index or nonempty string ID")
  .etr_assert(is.character(dimensions)&&length(dimensions)>=1L&&
    !anyNA(dimensions)&&all(nzchar(dimensions))&&
    !anyDuplicated(dimensions),
    "dimensions must be nonempty distinct channel names")
  for(nm in c("embedding_dimension","delay","min_diagonal_length",
    "min_vertical_length")){
    v<-get(nm)
    .etr_assert(is.numeric(v)&&length(v)==1L&&is.finite(v)&&
      v>=1&&v==floor(v),paste0(nm," must be positive integer"))
  }
  .etr_assert(is.numeric(radius)&&length(radius)==1L&&
    is.finite(radius)&&radius>0,"radius must be finite positive")
  .etr_assert(is.numeric(theiler_window)&&length(theiler_window)==1L&&
    is.finite(theiler_window)&&theiler_window>=0&&
    theiler_window==floor(theiler_window),
    "theiler_window must be nonnegative integer")
  for(nm in c("delay_units","metric","theiler_window_units")){
    v<-get(nm)
    .etr_assert(is.character(v)&&length(v)==1L&&
      !is.na(v)&&nzchar(v),paste0(nm," must be nonempty"))
  }
  etr_frozen_workflow_record("RecurrenceWorkflowConfig",
    list(curve=curve,dimensions=dimensions,
      embedding_dimension=embedding_dimension,delay=delay,radius=radius,
      delay_units=delay_units,metric=metric,
      theiler_window=theiler_window,
      theiler_window_units=theiler_window_units,
      min_diagonal_length=min_diagonal_length,
      min_vertical_length=min_vertical_length,
      preprocessing=.etr_frozen_empty_plan(preprocessing)))
}

#' Native source-field workflow decision record
#' @param value Explicit scientific decision value.
#' @param source analyst, audited_selector, workflow_contract, or derived.
#' @param criterion Selector rule, mandatory for audited_selector.
#' @export
etr_frozen_workflow_decision_record <- function(value,source,criterion=NULL){
  v<-list(value=value,source=source,criterion=criterion)
  .etr_workflow_validate_decisions(list(decision=v))
  etr_frozen_workflow_record("WorkflowDecisionRecord",v)
}

#' Native source-field workflow step record
#' @param name Step name.
#' @param function_name Explicit function name.
#' @param status completed, failed or skipped.
#' @param parameters Explicit JSON-compatible parameter mapping.
#' @param elapsed_seconds Finite nonnegative duration.
#' @param warnings Recorded warning strings.
#' @export
etr_frozen_workflow_step_record <- function(name,function_name,status,
    parameters=list(),elapsed_seconds,warnings=character()){
  v<-list(name=name,status=status,parameters=parameters,
    elapsed_seconds=elapsed_seconds,warnings=warnings)
  v<-append(v,list(function_name),after=1L)
  names(v)[2L]<-"function"
  .etr_workflow_validate_steps(list(v))
  etr_frozen_workflow_record("WorkflowStepRecord",v)
}

#' Run real native FPCA, function-on-scalar or recurrence from source records
#'
#' The source field declaration is honored, but native R scientific estimands,
#' timing, graphics and result classes remain different from Python 1.2.
#' Preprocessing is never hidden; only an empty explicit plan is accepted.
#' @param trajectories Complete native common-grid trajectory object.
#' @param config Frozen native config record from one of three constructors.
#' @param design Curve-aligned data.frame required for function-on-scalar.
#' @return Actual fitted R workflow, NOT a Python 1.2 result dataclass.
#' @export
etr_run_frozen_native_workflow <- function(trajectories,config,design=NULL){
  .etr_assert(inherits(config,"etr_frozen_workflow_record")&&
    identical(attr(config,"source_scientific_parity_certified"),FALSE),
    "config must be a frozen native workflow record")
  nm<-attr(config,"frozen_python_class")
  .etr_assert(nm%in%c("FPCAWorkflowConfig",
    "FunctionOnScalarWorkflowConfig","RecurrenceWorkflowConfig"),
    "no executable native R adapter for this frozen config")
  schema<-etr_frozen_workflow_schema(nm)
  .etr_assert(identical(names(config),schema$field_name),
    "source config field names or order mismatch")
  pre<-config$preprocessing
  .etr_assert(inherits(pre,"etr_frozen_py12_PreprocessingPlan")&&
    is.list(pre$steps)&&length(pre$steps)==0L,
    "native execution requires empty explicit preprocessing")
  cfg<-unclass(config)
  cfg$preprocessing<-list()
  if(nm=="FPCAWorkflowConfig"){
    .etr_assert(!(typeof(cfg$n_components)=="double"&&
      identical(cfg$n_components,1)),
      "floating 1.0 proportion is unsupported by native FPCA")
    .etr_assert(is.null(design),
      "FPCA native workflow does not accept design")
    return(etr_run_fpca_workflow(trajectories,cfg))
  }
  if(nm=="FunctionOnScalarWorkflowConfig"){
    .etr_assert(is.data.frame(design),
      "function-on-scalar execution requires design data.frame")
    return(etr_run_function_on_scalar_workflow(trajectories,design,cfg))
  }
  .etr_assert(is.null(design),
    "recurrence native workflow does not accept design")
  etr_run_recurrence_workflow(trajectories,cfg)
}
