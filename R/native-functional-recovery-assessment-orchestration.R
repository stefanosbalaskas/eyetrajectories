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
  # The Python flattened MappingProxyType dictionary cannot retain a
  # collision; fail closed instead of silently losing recovery evidence.
  .etr_assert(!anyDuplicated(keys),
    "recovery assessment flattened metric keys must be unique")
  names(metrics)<-keys
  list(metrics=metrics,metric_values=values,
    assessment_provenance=provenance,definitions=definitions)
}

.etr_recovery_runner_metrics <- function(recovered) {
  if(inherits(recovered,"etr_functional_recovery_assessment"))
    return(.etr_recovery_runner_assessment(recovered))
  .etr_assert(is.numeric(recovered)&&is.null(dim(recovered))&&
    length(recovered)>0L&&all(is.finite(recovered))&&
    !is.null(names(recovered))&&!anyNA(names(recovered))&&
    all(nzchar(names(recovered)))&&!anyDuplicated(names(recovered)),
    "recovery must return named finite numeric metrics or structured assessment")
  list(metrics=recovered,metric_values=list(),
    assessment_provenance=list(),definitions=list())
}
