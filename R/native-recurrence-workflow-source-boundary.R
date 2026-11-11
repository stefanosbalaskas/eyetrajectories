# Source-scientific nested record boundary for Python 1.2 W4 recurrence.
# Frozen source: eyetrajectoriespy/workflows/_recurrence.py,
# recurrence.py, nonlinear_types.py and nonlinear_reporting.py.
# Commit c1cd95ad718327550f7e55393ff38582872f7a94.
# This represents Python dataclass scientific fields as native R lists,
# not Python dataclass/CSR identities. Native elapsed timings are real R
# measurements and are not represented as identical to Python timings.

.etr_recurrence_workflow_python_boundary<-function(result){
  .etr_assert(inherits(result,"etr_recurrence_workflow")&&
    is.list(result$embedding)&&is.list(result$recurrence)&&
    is.list(result$metrics)&&is.list(result$config),
    "recurrence source boundary requires an executed native W4 workflow")
  cfg<-result$config
  source_config_fields<-c("curve","dimensions","embedding_dimension",
    "delay","radius","delay_units","metric","theiler_window",
    "theiler_window_units","min_diagonal_length","min_vertical_length",
    "preprocessing")
  .etr_assert(setequal(names(cfg),source_config_fields),
    "recurrence source configuration does not match frozen Python fields")
  source_config<-cfg[source_config_fields]
  source_config$preprocessing<-list(steps=list())
  embedding<-result$embedding
  native_rec<-result$recurrence
  .etr_assert(is.numeric(embedding$time)&&length(embedding$time)>=2L&&
    all(is.finite(embedding$time))&&all(diff(embedding$time)>0)&&
    is.numeric(embedding$delay_samples)&&
    is.numeric(native_rec$recurrence_rate)&&
    length(native_rec$recurrence_rate)==1L&&
    identical(native_rec$kind,"auto"),
    "recurrence source boundary requires complete embedded auto recurrence")
  # The Python source selects the embedded-state representation, not a
  # newly declared TrajectorySet with a different source_kind.
  info<-list(source_kind="DelayEmbeddingResult",
    embedding_dimension=as.integer(embedding$embedding_dimension),
    delay_samples=as.integer(embedding$delay_samples),
    delay_time=as.numeric(embedding$delay_time),
    state_names=as.character(embedding$state_names),
    coordinate_system=embedding$coordinate_system,
    source_provenance=embedding$provenance)
  selected<-if(is.character(cfg$curve))
    match(cfg$curve,embedding$curve_ids) else as.integer(cfg$curve)+1L
  rec_prov<-c(list(operation="recurrence_matrix"),info,
    list(radius_policy="fixed",
      target_recurrence_rate=NULL,
      achieved_recurrence_rate=as.numeric(native_rec$recurrence_rate),
      metric=cfg$metric,
      theiler_window_samples=as.integer(native_rec$theiler),
      sparse=TRUE,
      threshold_operator="<=",
      diagonal_included=FALSE,
      recurrence_rate_scale="0_to_1",
      recurrence_rate_denominator=
        "eligible_off_diagonal_pairs_outside_theiler_window",
      target_rate_tie_policy=NULL))
  source_recurrence<-list(
    matrix=native_rec$matrix,
    time_a=embedding$time,
    time_b=embedding$time,
    source_curve_ids=as.character(embedding$curve_ids[[selected]]),
    radius=as.numeric(native_rec$radius),
    target_recurrence_rate=NULL,
    achieved_recurrence_rate=as.numeric(native_rec$recurrence_rate),
    metric=cfg$metric,
    theiler_window_samples=as.integer(native_rec$theiler),
    kind="auto",
    state_dimension=as.integer(dim(embedding$values)[3L]),
    provenance=rec_prov,
    time_unit=embedding$time_unit)
  numeric_metric_fields<-c("recurrence_rate","determinism",
    "mean_diagonal_length","max_diagonal_length",
    "diagonal_entropy","laminarity","trapping_time",
    "max_vertical_length","center_of_recurrence_mass",
    "n_recurrence_points","n_diagonal_lines","n_vertical_lines",
    "min_diagonal_length","min_vertical_length")
  m<-result$metrics
  .etr_assert(all(numeric_metric_fields%in%names(m)),
    "recurrence source boundary needs all fourteen RQA metrics")
  source_metrics<-m[numeric_metric_fields]
  source_metrics$provenance<-list(
    operation="rqa_metrics",
    recurrence_provenance=rec_prov,
    min_diagonal_length=as.integer(cfg$min_diagonal_length),
    min_vertical_length=as.integer(cfg$min_vertical_length),
    sampling_contract="approximately_regular_grid",
    sampling_step_a=as.numeric(stats::median(diff(embedding$time))),
    sampling_step_b=NULL,
    ratio_scale="0_to_1",
    recurrence_rate_denominator_policy=
      rec_prov$recurrence_rate_denominator,
    line_border_policy=paste(
      "finite-matrix border lines are counted at their observed length;",
      "no border-effect correction is applied"),
    line_entropy_probability=paste(
      "frequency of each qualifying line length divided by the total",
      "number of qualifying lines"),
    corm_definition="100 * mean upper-triangle recurrence lag / (n-1)")
  # All source decisions include the explicit analyst/derived attribution.
  source_decision_fields<-c("curve","dimensions","embedding_dimension",
    "delay","delay_units","radius","metric","theiler_window",
    "theiler_window_units","min_diagonal_length","min_vertical_length")
  source_decisions<-lapply(source_config[source_decision_fields],
    function(value)list(value=value,source="analyst",criterion=NULL))
  source_decisions$resolved_delay_samples<-list(
    value=as.integer(embedding$delay_samples),source="derived",
    criterion=paste(
      "resolved by delay_embed_trajectory from the declared delay",
      "and source time grid"))
  source_decisions$resolved_theiler_window_samples<-list(
    value=as.integer(native_rec$theiler),source="derived",
    criterion=paste(
      "resolved by recurrence_matrix from the declared Theiler",
      "window and embedded-state time grid"))
  source_steps<-result$steps
  .etr_assert(length(source_steps)==3L&&
    identical(vapply(source_steps,function(s)s$name,character(1L)),
      c("delay_embedding","recurrence","rqa")),
    "source recurrence workflow requires three actual scientific steps")
  for(i in seq_along(source_steps))
    source_steps[[i]][["function"]]<-c(
      "delay_embed_trajectory","recurrence_matrix","rqa_metrics")[[i]]
  result$config<-source_config
  result$recurrence<-source_recurrence
  result$metrics<-source_metrics
  result$steps<-source_steps
  result$decisions<-source_decisions
  result$provenance<-list(
    input_layout="complete_common_grid",
    state_representation="delay_embedding",
    preprocessing_executed=FALSE,
    fixed_radius_policy=TRUE,
    target_recurrence_rate_selection_performed=FALSE,
    automatic_embedding_parameter_selection=FALSE,
    automatic_rqa_parameter_selection=FALSE)
  result$tables$rqa_metrics<-as.data.frame(
    source_metrics[numeric_metric_fields],check.names=FALSE)
  .etr_assert(nrow(result$tables$rqa_metrics)==1L,
    "recurrence RQA source table must contain one row")
  result
}
