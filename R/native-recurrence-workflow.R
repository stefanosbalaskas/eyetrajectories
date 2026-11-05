# Native R subset of frozen Python 1.2 W4 recurrence workflow.
# Supports three source distance metrics and Python 1.2 time-unit conversions.
# Python dataclass/schema parity and independent approval remain open.

#' Explicit source-aligned delay embedding and recurrence/RQA workflow
#' @param trajectories Complete native common-grid trajectories.
#' @param config Named list with curve, dimensions, embedding_dimension, delay,
#'   radius, and optional metric, Theiler window and RQA line lengths.
#' @return Audited native R recurrence workflow, not a Python dataclass.
#' @export
etr_run_recurrence_workflow <- function(trajectories,config){
  etr_validate(trajectories,require_complete=TRUE)
  cfg<-.etr_source_workflow_config(config,list(
    curve=NULL,dimensions=NULL,embedding_dimension=NULL,delay=NULL,
    radius=NULL,metric="euclidean",delay_units="samples",
    theiler_window=0L,theiler_window_units="samples",
    min_diagonal_length=2L,min_vertical_length=2L,
    preprocessing=list()),
    required=c("curve","dimensions","embedding_dimension","delay","radius"))
  .etr_assert(is.character(cfg$dimensions)&&length(cfg$dimensions)>0L&&
    !anyNA(cfg$dimensions)&&!anyDuplicated(cfg$dimensions)&&
    all(cfg$dimensions%in%trajectories$dimension_names),
    "dimensions must name distinct existing channels")
  .etr_assert(is.character(cfg$metric)&&length(cfg$metric)==1L&&
    !is.na(cfg$metric)&&cfg$metric%in%
      c("cityblock","euclidean","chebyshev"),
    "metric must be one of cityblock, euclidean, chebyshev")
  for(nm in c("embedding_dimension","min_diagonal_length",
    "min_vertical_length")){
    v<-cfg[[nm]]
    .etr_assert(is.numeric(v)&&length(v)==1L&&is.finite(v)&&
      v==floor(v)&&v>=1L,paste(nm,"must be positive integer"))
  }
  .etr_assert(is.numeric(cfg$radius)&&length(cfg$radius)==1L&&
    is.finite(cfg$radius)&&cfg$radius>0,
    "radius must be finite and positive")
  resolved_delay<-.etr_source_time_unit_samples(
    trajectories$time,cfg$delay,cfg$delay_units,
    trajectories$time_unit,name="delay")
  # Theiler resolution is intentionally deferred until embedding: Python
  # recurrence.py resolves it on the actual embedded-state time grid.
  if(is.character(cfg$curve)){
    .etr_assert(length(cfg$curve)==1L&&!is.na(cfg$curve)&&
      cfg$curve%in%trajectories$curve_ids,
      "curve must be a known curve ID")
    selected<-match(cfg$curve,trajectories$curve_ids)
  }else{
    .etr_assert(is.numeric(cfg$curve)&&length(cfg$curve)==1L&&
      is.finite(cfg$curve)&&cfg$curve==floor(cfg$curve)&&
      cfg$curve>=0&&cfg$curve<length(trajectories$curve_ids),
      "curve must be a zero-based index or known ID")
    selected<-as.integer(cfg$curve)+1L
  }
  # Native elapsed wall times are measured around the actual R operations.
  # They are never substituted for Python timings or certified as Python
  # runtime equivalence.
  start_embedding<-proc.time()[["elapsed"]]
  embedding<-etr_delay_embed_trajectory(trajectories,
    embedding_dimension=as.integer(cfg$embedding_dimension),
    delay=cfg$delay,delay_units=cfg$delay_units,
    dimensions=cfg$dimensions)
  elapsed_embedding<-max(0,proc.time()[["elapsed"]]-start_embedding)
  embedded<-etr_trajectory_set(embedding$time,embedding$values,
    embedding$curve_ids,embedding$state_names,
    coordinate_system=embedding$coordinate_system,
    time_unit=embedding$time_unit,
    provenance=embedding$provenance)
  resolved_theiler<-.etr_source_time_unit_samples(
    embedding$time,cfg$theiler_window,cfg$theiler_window_units,
    embedding$time_unit,name="theiler_window",allow_zero=TRUE)
  start_recurrence<-proc.time()[["elapsed"]]
  recurrence<-etr_recurrence_matrix(embedded,curve=selected,
    radius=cfg$radius,theiler=resolved_theiler,
    metric=cfg$metric)
  elapsed_recurrence<-max(0,proc.time()[["elapsed"]]-start_recurrence)
  start_rqa<-proc.time()[["elapsed"]]
  metrics<-.etr_recurrence_quantifiers_full(recurrence,
    min_diagonal_length=as.integer(cfg$min_diagonal_length),
    min_vertical_length=as.integer(cfg$min_vertical_length))
  elapsed_rqa<-max(0,proc.time()[["elapsed"]]-start_rqa)
  # Three real, native scientific steps follow the frozen W4 source order.
  # Step function names identify the actual R implementation, not a
  # fictitious invocation of the Python backend.
  steps<-list(
    etr_frozen_workflow_step_record("delay_embedding",
      "etr_delay_embed_trajectory","completed",
      parameters=list(embedding_dimension=cfg$embedding_dimension,
        delay=cfg$delay,delay_units=cfg$delay_units,
        dimensions=cfg$dimensions),elapsed_seconds=elapsed_embedding),
    etr_frozen_workflow_step_record("recurrence",
      "etr_recurrence_matrix","completed",
      parameters=list(curve=cfg$curve,radius=cfg$radius,
        metric=cfg$metric,theiler_window=cfg$theiler_window,
        theiler_window_units=cfg$theiler_window_units),
      elapsed_seconds=elapsed_recurrence),
    etr_frozen_workflow_step_record("rqa",
      ".etr_recurrence_quantifiers_full","completed",
      parameters=list(min_diagonal_length=cfg$min_diagonal_length,
        min_vertical_length=cfg$min_vertical_length),
      elapsed_seconds=elapsed_rqa))
  frame<-as.data.frame(lapply(metrics,identity),check.names=FALSE)
  .etr_assert(nrow(frame)==1L,"RQA must describe one curve")
  decisions<-lapply(cfg[setdiff(names(cfg),"preprocessing")],
    .etr_source_workflow_decision)
  decisions$resolved_delay_samples<-.etr_source_workflow_decision(
    embedding$delay_samples,"derived")
  decisions$resolved_theiler_window_samples<-.etr_source_workflow_decision(
    recurrence$theiler,"derived")
  structure(list(workflow_schema_version=1L,
    workflow_contract="recurrence:v1",config=cfg,
    embedding=embedding,recurrence=recurrence,metrics=metrics,
    steps=steps,decisions=decisions,
    provenance=list(input_layout="complete_common_grid",
      state_representation="delay_embedding",
      preprocessing_executed=FALSE,fixed_radius_policy=TRUE,
      target_recurrence_rate_selection_performed=FALSE,
      automatic_embedding_parameter_selection=FALSE,
      automatic_rqa_parameter_selection=FALSE,
      source_schema_equivalent=FALSE,
      metric_scope="source_cityblock_euclidean_chebyshev",
      metric_used=cfg$metric,
      physical_time_conversion_applied=!identical(cfg$delay_units,
        "samples")||!identical(cfg$theiler_window_units,"samples"),
      resolved_delay_samples=resolved_delay,
      resolved_theiler_window_samples=resolved_theiler),
    reports=list(rqa=etr_rqa_reporting_text(recurrence,metrics)),
    tables=list(rqa_metrics=frame)),
    class="etr_recurrence_workflow")
}
