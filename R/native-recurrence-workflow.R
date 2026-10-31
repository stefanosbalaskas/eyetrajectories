# Native R subset of frozen Python 1.2 W4 recurrence workflow.
# Only Euclidean distance and sample-unit delays/windows are implemented.
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
  .etr_assert(identical(cfg$metric,"euclidean"),
    "only Euclidean recurrence is implemented")
  .etr_assert(identical(cfg$delay_units,"samples")&&
    identical(cfg$theiler_window_units,"samples"),
    "time-unit delays or Theiler windows are not source-qualified")
  for(nm in c("embedding_dimension","delay","min_diagonal_length",
    "min_vertical_length")){
    v<-cfg[[nm]]
    .etr_assert(is.numeric(v)&&length(v)==1L&&is.finite(v)&&
      v==floor(v)&&v>=1L,paste(nm,"must be positive integer"))
  }
  .etr_assert(is.numeric(cfg$radius)&&length(cfg$radius)==1L&&
    is.finite(cfg$radius)&&cfg$radius>0,
    "radius must be finite and positive")
  .etr_assert(is.numeric(cfg$theiler_window)&&
    length(cfg$theiler_window)==1L&&
    is.finite(cfg$theiler_window)&&
    cfg$theiler_window==floor(cfg$theiler_window)&&
    cfg$theiler_window>=0L,
    "theiler_window must be nonnegative sample integer")
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
  embedding<-etr_delay_embed_trajectory(trajectories,
    embedding_dimension=as.integer(cfg$embedding_dimension),
    delay=as.integer(cfg$delay),delay_units="samples",
    dimensions=cfg$dimensions)
  embedded<-etr_trajectory_set(embedding$time,embedding$values,
    embedding$curve_ids,embedding$state_names,
    coordinate_system=embedding$coordinate_system,
    time_unit=embedding$time_unit,
    provenance=embedding$provenance)
  recurrence<-etr_recurrence_matrix(embedded,curve=selected,
    radius=cfg$radius,theiler=as.integer(cfg$theiler_window))
  metrics<-.etr_recurrence_quantifiers_full(recurrence,
    min_diagonal_length=as.integer(cfg$min_diagonal_length),
    min_vertical_length=as.integer(cfg$min_vertical_length))
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
    decisions=decisions,
    provenance=list(input_layout="complete_common_grid",
      state_representation="delay_embedding",
      preprocessing_executed=FALSE,fixed_radius_policy=TRUE,
      target_recurrence_rate_selection_performed=FALSE,
      automatic_embedding_parameter_selection=FALSE,
      automatic_rqa_parameter_selection=FALSE,
      source_schema_equivalent=FALSE,
      metric_scope="euclidean_samples_only"),
    reports=list(rqa=etr_rqa_reporting_text(recurrence,metrics)),
    tables=list(rqa_metrics=frame)),
    class="etr_recurrence_workflow")
}
