# Native first-party parity port of frozen Python 1.2
# simulate.py::run_functional_recovery_scenarios structured recovery branch.
# Source SHA c1cd95ad718327550f7e55393ff38582872f7a94.
# The estimator never receives simulation truth. A recovery assessment
# carries semantic metric definitions, zero-based components, and sources.

.etr_recovery_runner_assessment <- function(assessment) {
  .etr_assert(inherits(assessment,"etr_functional_recovery_assessment")&&
    is.list(assessment)&&is.list(assessment$values)&&
    length(assessment$values)>0L,
    "structured recovery assessment must contain at least one metric value")
  values<-assessment$values
  provenance<-if(is.null(assessment$provenance))list()
    else assessment$provenance
  .etr_assert(.etr_provenance_valid(provenance),
    "assessment provenance must be a JSON-like named mapping")
  metrics<-numeric(length(values))
  keys<-character(length(values))
  definitions<-list()
  labels<-character(length(values))
  for(i in seq_along(values)){
    v<-values[[i]]
    .etr_assert(is.list(v)&&is.list(v$metric),
      "recovery assessment values must contain semantic metric definitions")
    metric<-v$metric
    fields<-c("name","quantity","direction","units","scope","description")
    .etr_assert(all(fields%in%names(metric))&&
      all(vapply(fields,function(field)
        is.character(metric[[field]])&&length(metric[[field]])==1L&&
        !is.na(metric[[field]])&&
        nzchar(trimws(metric[[field]])),logical(1L)))&&
      metric$direction%in%c("higher_is_better","lower_is_better"),
      "recovery metric definition must contain six valid source fields")
    .etr_assert(is.numeric(v$value)&&length(v$value)==1L&&
      is.finite(v$value),
      "recovery assessment metrics must be finite scalar values")
    if(!is.null(v$component))
      .etr_assert(is.numeric(v$component)&&
        length(v$component)==1L&&is.finite(v$component)&&
        v$component>=0&&v$component==floor(v$component),
        "recovery component must be a nonnegative zero-based integer")
    if(!is.null(v$source))
      .etr_assert(is.character(v$source)&&length(v$source)==1L&&
        !is.na(v$source)&&nzchar(trimws(v$source)),
        "recovery source must be a nonempty text label")
    # Published Python checks duplicate semantic triples (metric,
    # component, source), then publishes deterministic flat keys.
    labels[i]<-paste(metric$name,
      if(is.null(v$component))"<none>" else format(v$component),
      if(is.null(v$source))"<none>" else v$source,sep="\u001f")
    keys[i]<-etr_functional_recovery_value_key(v)
    metrics[i]<-as.numeric(v$value)
    if(!metric$name%in%names(definitions))
      definitions[[metric$name]]<-metric
    else .etr_assert(identical(definitions[[metric$name]],metric),
      paste("recovery metric definitions are inconsistent for",
        metric$name))
  }
  .etr_assert(!anyDuplicated(labels),
    "recovery assessment contains duplicate metric labels")
  # Python FunctionalRecoveryAssessment rejects duplicate semantic triples,
  # but as_mapping() uses a dict comprehension. Two *different* triples can
  # have the same flattened key (e.g. metric "a.source_b" versus metric "a"
  # with source "b"). In that case the last value replaces the first while
  # the detailed semantic values are retained in their source order.
  flattened<-numeric(0)
  for(i in seq_along(keys)){
    found<-match(keys[[i]],names(flattened))
    if(is.na(found))
      flattened<-c(flattened,stats::setNames(metrics[[i]],keys[[i]]))
    else flattened[[found]]<-metrics[[i]]
  }
  list(metrics=flattened,metric_values=values,
    assessment_provenance=provenance,definitions=definitions)
}

.etr_recovery_runner_metrics <- function(recovered) {
  if(inherits(recovered,"etr_functional_recovery_assessment"))
    return(.etr_recovery_runner_assessment(recovered))
  # Python run_functional_recovery_scenarios passes plain mappings to
  # FunctionalRecoveryRecord, which coerces names and float-like values.
  # The native accepted domain is named scalar vectors or heterogeneous
  # named lists; arbitrary Python Mapping protocols remain out of scope.
  .etr_assert((is.atomic(recovered)||is.list(recovered))&&
    !is.object(recovered)&&is.null(dim(recovered))&&
    length(recovered)>0L&&!is.null(names(recovered)),
    "recovery must return named finite numeric-like metrics or structured assessment")
  metrics<-.etr_recovery_source_metric_mapping(recovered)
  .etr_assert(length(metrics)>0L,
    "successful records require at least one metric")
  list(metrics=metrics,metric_values=list(),
    assessment_provenance=list(),definitions=list())
}
