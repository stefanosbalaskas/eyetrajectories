.etr_rqa_source_population_sd<-function(z) {
  # Frozen Python functional_rqa.py _pairwise_exact_center_comparison
  # checks np.std(z, ddof=0), not R stats::sd(z) (ddof=1).
  sqrt(mean((z-mean(z))^2))
}

# Stage 26: research numerical integration of windowed functional RQA and
# published Python 1.2 recovery metadata. All native; no Python bridge.

#' Return the pinned published 1.2 functional-recovery metric registry
#' @return Ordered list of 27 named native metric definitions, not Python dataclasses.
#' @export
etr_functional_recovery_metric_catalog <- function() {
  f<-system.file("extdata","native_recovery_metric_catalog_py120.csv",
    package="eyetrajectories")
  .etr_assert(nzchar(f),"pinned published recovery metric catalog is missing")
  x<-utils::read.csv(f,stringsAsFactors=FALSE,
    check.names=FALSE,encoding="UTF-8",comment.char="#")
  cols<-c("metric","quantity","direction","units","scope","description")
  .etr_assert(identical(names(x),cols)&&nrow(x)==27L&&
    !anyDuplicated(x$metric)&&
    all(vapply(x,function(a)is.character(a)&&
      all(!is.na(a)&nzchar(a)),logical(1L)))&&
    all(x$direction%in%c("lower_is_better","higher_is_better")),
    "published Python recovery metric catalog has changed or is invalid")
  out<-lapply(seq_len(nrow(x)),function(i){
    a<-as.list(x[i,,drop=FALSE])
    a$name<-a$metric;a$metric<-NULL
    a<-a[c("name","quantity","direction","units","scope","description")]
    structure(a,class="etr_recovery_metric")
  })
  names(out)<-x$metric
  out
}

#' Return a tidy native R copy of the pinned Python recovery metric catalog
#' @return Six-column 27-row data.frame, preserving source order and UTF-8 metadata.
#' @export
etr_functional_recovery_metric_catalog_frame <- function() {
  defs<-etr_functional_recovery_metric_catalog()
  x<-do.call(rbind,lapply(defs,function(z){
    data.frame(metric=z$name,quantity=z$quantity,direction=z$direction,
      units=z$units,scope=z$scope,description=z$description,
      stringsAsFactors=FALSE,check.names=FALSE)
  }))
  rownames(x)<-NULL
  x
}

#' Deterministic recovery value key using Python zero-based component index
#' @param value Native recovery-value list with metric, optional source, component.
#' @return Single flat key; component numbering in output begins at one.
#' @export
etr_functional_recovery_value_key <- function(value) {
  .etr_assert(is.list(value)&&is.list(value$metric)&&
    is.character(value$metric$name)&&length(value$metric$name)==1L&&
    !is.na(value$metric$name)&&nzchar(value$metric$name),
    "value must supply a named recovery metric")
  key<-value$metric$name
  if(!is.null(value$source)){
    .etr_assert(is.character(value$source)&&length(value$source)==1L&&
      !is.na(value$source),"source must be one text value")
    key<-paste0(key,".source_",value$source)
  }
  if(!is.null(value$component)){
    component<-.etr_recovery_component_label(value$component)
    key<-paste0(key,".component_",sprintf("%.0f",component))
  }
  key
}

# Whitespace recognized by Python str.strip() for source text fields.
.etr_recovery_source_trim <- function(x) {
  whitespace<-paste0("[\\x{0009}-\\x{000D}\\x{001C}-\\x{0020}",
    "\\x{0085}\\x{00A0}\\x{1680}\\x{2000}-\\x{200A}\\x{2028}\\x{2029}",
    "\\x{202F}\\x{205F}\\x{3000}]")
  x<-sub(paste0("(*UTF)^",whitespace,"+"),"",enc2utf8(x),perl=TRUE)
  sub(paste0("(*UTF)",whitespace,"+\\z"),"",x,perl=TRUE)
}

.etr_recovery_source_number <- function(x,integer=FALSE) {
  .etr_assert(is.null(dim(x))&&length(x)==1L&&!is.na(x)&&
    (is.numeric(x)||is.logical(x)||is.character(x))&&!is.complex(x),
    "source recovery value or component must be one numeric scalar")
  if(is.character(x)){
    x<-.etr_recovery_source_trim(x)
    if(integer)
      .etr_assert(grepl("^[+-]?[0-9](?:_?[0-9])*$",x,perl=TRUE),
        "source component must contain an integer literal")
    x<-.etr_numpy_float_text(x,"source recovery value must be numeric")
  }
  x<-suppressWarnings(as.numeric(x))
  .etr_assert(is.finite(x),"source recovery values must be finite")
  if(integer)trunc(x) else x
}

# Python FunctionalRecoveryMetric.__post_init__ and
# FunctionalRecoveryValue.__post_init__ use str(value).strip() for
# ordinary semantic text fields and source labels. Do not use R
# as.character(TRUE) = "TRUE" or erase the .0 of a source float.
.etr_recovery_source_str <- function(x) {
  .etr_assert(is.atomic(x) && is.null(dim(x)) && !is.object(x) &&
    length(x)==1L && !is.na(x) || (is.double(x) && length(x)==1L &&
    is.nan(x) && is.null(dim(x))),
    "source recovery text must be an ordinary Python scalar analogue")
  if(is.character(x))return(.etr_recovery_source_trim(x))
  if(is.logical(x))return(if(x) "True" else "False")
  if(is.integer(x))return(as.character(x))
  .etr_assert(is.double(x) && !is.complex(x),
    "source recovery text must be an ordinary Python scalar analogue")
  if(is.nan(x))return("nan")
  if(is.infinite(x))return(if(x>0) "inf" else "-inf")
  .etr_python_json_float(x)
}

#' Turn native semantically annotated recovery values into an auditable table
#' @param assessment Native list with finite values of built-in or custom
#'   recovery metrics.
#' @param python_boundary_mode Use the mapped Python scalar, text and metric
#'   metadata conventions.
#' @return Native data.frame of source metric, value, component, source and metadata.
#' @export
etr_functional_recovery_assessment_frame <- function(assessment,
    python_boundary_mode=FALSE) {
  .etr_assert(is.logical(python_boundary_mode)&&length(python_boundary_mode)==1L&&
    !is.na(python_boundary_mode),"python_boundary_mode must be TRUE or FALSE")
  .etr_assert(is.list(assessment)&&is.list(assessment$values)&&
    length(assessment$values)>=1L,
    "assessment must have at least one semantic recovery value")
  defs<-if(!python_boundary_mode)etr_functional_recovery_metric_catalog()
  trim<-if(python_boundary_mode).etr_recovery_source_trim else trimws
  fields<-c("name","quantity","direction","units","scope","description")
  rows<-lapply(assessment$values,function(z){
    .etr_assert(is.list(z)&&is.list(z$metric)&&
      all(fields%in%names(z$metric)),
      "assessment values must carry metric metadata and a finite numeric scalar")
    value<-z$value
    component<-z$component
    if(python_boundary_mode){
      value<-.etr_recovery_source_number(value)
      if(!is.null(component))
        component<-.etr_recovery_source_number(component,integer=TRUE)
    }
    .etr_assert(is.numeric(value)&&!is.complex(value)&&length(value)==1L&&
      is.finite(value),"assessment values must carry a finite numeric scalar")
    def<-z$metric[fields]
    # Source dataclass constructors normalize each non-direction semantic
    # field via Python str(...).strip() before the public frame is called.
    if(python_boundary_mode)
      for(field in c("name","quantity","units","scope","description"))
        def[[field]]<-.etr_recovery_source_str(def[[field]])
    .etr_assert(all(vapply(def,function(x)is.character(x)&&
      length(x)==1L&&!is.na(x)&&nzchar(trim(x)),logical(1L)))&&
      def$direction%in%c("lower_is_better","higher_is_better"),
      "recovery metric metadata must have nonempty text and a valid direction")
    def<-lapply(def,trim)
    registered<-defs[[def$name]]
    if(!is.null(registered))
      .etr_assert(identical(z$metric,unclass(registered))||identical(z$metric,registered),
        "assessment metric metadata must match the published source catalog")
    # Python source labels are coerced by str(source).strip() at
    # FunctionalRecoveryValue construction, not limited to str inputs.
    source_label<-if(python_boundary_mode&&!is.null(z$source))
      .etr_recovery_source_str(z$source) else z$source
    .etr_assert(is.null(source_label)||
      (is.character(source_label)&&length(source_label)==1L&&
       !is.na(source_label)&&nzchar(trim(source_label))),
      "recovery source must be a single optional text label")
    data.frame(metric=def$name,value=as.numeric(value),
      component=.etr_recovery_component_label(component),
      source=if(is.null(source_label))NA_character_
        else trim(source_label),
      quantity=def$quantity,direction=def$direction,units=def$units,
      scope=def$scope,description=def$description,
      stringsAsFactors=FALSE,check.names=FALSE)
  })
  x<-do.call(rbind,rows)
  .etr_assert(!anyDuplicated(x[c("metric","component","source")]),
    "recovery assessment contains duplicate metric labels")
  rownames(x)<-NULL
  x
}

.etr_recovery_estimator_repr <- function(x) {
  if(is.null(x))return("None")
  .etr_assert(!is.object(x)&&is.null(dim(x)),
    "recovery estimator provenance must use plain source-mapped values")
  if(is.list(x)){
    values<-vapply(x,.etr_recovery_estimator_repr,character(1L))
    if(is.null(names(x)))return(paste0("[",paste(values,collapse=", "),"]"))
    keys<-vapply(names(x),.etr_python_workflow_identifier_repr,character(1L))
    .etr_assert(!anyDuplicated(keys),"recovery estimator mapping keys must be unique")
    return(paste0("{",paste(paste0(keys,": ",values),collapse=", "),"}"))
  }
  .etr_assert(length(x)==1L&&(!is.na(x)||is.nan(x)),
    "recovery estimator provenance must be a scalar, list, mapping or NULL")
  if(is.character(x))return(.etr_python_workflow_identifier_repr(x))
  if(is.logical(x))return(if(x)"True" else "False")
  if(is.integer(x))return(as.character(x))
  .etr_assert(is.double(x),"unsupported recovery estimator provenance value")
  if(is.nan(x))return("nan")
  if(is.infinite(x))return(if(x>0)"inf" else "-inf")
  .etr_python_json_float(x)
}

#' Compact known-truth recovery assessment text without estimator retuning
#' @param assessment Native semantic recovery assessment with provenance.
#' @param python_boundary_mode Accept the mapped source estimator representations
#'   in addition to native string identifiers.
#' @return A deterministic manuscript-oriented source-aligned description.
#' @export
etr_functional_recovery_reporting_text <- function(assessment,
    python_boundary_mode=FALSE) {
  frame<-etr_functional_recovery_assessment_frame(assessment,python_boundary_mode)
  names<-paste(sort(unique(enc2utf8(frame$metric)),method="radix"),collapse=", ")
  provenance<-assessment$provenance
  if(python_boundary_mode){
    .etr_assert(is.null(provenance)||is.list(provenance),
      "recovery provenance must be a mapping")
    estimator<-if("estimator"%in%names(provenance))provenance[["estimator"]]
      else "unspecified"
    label<-.etr_recovery_estimator_repr(estimator)
  }else{
    estimator<-if(is.null(provenance$estimator))"unspecified" else provenance$estimator
    .etr_assert(is.character(estimator)&&length(estimator)==1L&&!is.na(estimator),
      "recovery estimator provenance must be a single string")
    label<-.etr_python_workflow_identifier_repr(estimator)
  }
  paste0("Known-truth recovery was evaluated after fitting for estimator ",
    label,". Recorded metric families: ",names,
    ". Metric direction, units, scope, and component/source labels are ",
    "retained explicitly. Recovery truth is an evaluation input only ",
    "and is not an estimator-tuning input.")
}

.etr_validate_rqa_window_pairs <- function(pairs,
    window_units="samples",step_units="samples") {
  if(is.matrix(pairs)&&is.numeric(pairs)&&ncol(pairs)==2L)
    pairs<-lapply(seq_len(nrow(pairs)),function(i)as.numeric(pairs[i,]))
  .etr_assert(is.list(pairs)&&length(pairs)>=1L,
    "window_step_pairs must be a nonempty list or 2-column matrix")
  .etr_assert(is.character(window_units)&&length(window_units)==1L&&
    !is.na(window_units)&&nzchar(window_units)&&
    is.character(step_units)&&length(step_units)==1L&&
    !is.na(step_units)&&nzchar(step_units),
    "window_units and step_units must be nonempty strings")
  for(i in seq_along(pairs)){
    v<-pairs[[i]]
    # Frozen Python 1.2 accepts any two-item Sequence whose elements are
    # Python/NumPy numeric scalars, including (5, 2.0), but rejects bool.
    # A source-like R list(list(5L,2.0),...) must not be rejected merely
    # because it is not an atomic numeric vector. Do not unlist() mixed
    # values: its coercion can turn Boolean TRUE into text unexpectedly.
    if(is.list(v) && !is.data.frame(v) && is.null(dim(v))){
      .etr_assert(length(v)==2L && all(vapply(v,function(z)
        is.numeric(z)&&!is.logical(z)&&!is.factor(z)&&
          length(z)==1L&&is.null(dim(z))&&is.finite(z)&&z>0,
        logical(1L))),
        "window and step must be positive finite numeric values")
      v<-vapply(v,as.numeric,numeric(1L),USE.NAMES=FALSE)
    }
    .etr_assert(is.numeric(v)&&!is.logical(v)&&length(v)==2L&&
      all(is.finite(v))&&all(v>0),
      "window and step must be positive finite numeric values")
    pairs[[i]]<-as.numeric(v)
    # Python's validator allows physical-time fractional widths. Its
    # sample-unit _resolve_samples rejects nonintegral sample counts.
    if(identical(window_units,"samples")||identical(step_units,"samples"))
      .etr_assert(all(v[c(identical(window_units,"samples"),
        identical(step_units,"samples"))]==floor(v[c(
          identical(window_units,"samples"),
          identical(step_units,"samples"))])),
        "window and step must be positive finite integer sample counts when using samples")
  }
  pairs
}

#' Audited multiscale windowed RQA without automatic specification selection
#' @param trajectories Native complete functional trajectories.
#' @param metrics Unique RQA statistics to compare.
#' @param window_step_pairs List or two-column numeric matrix of explicit
#'   (window,step) pairs. Fractional positive widths are supported for
#'   physical time units; sample-unit widths must be integral.
#' @param radius Positive declared Euclidean recurrence radius.
#' @param ... Additional fixed native RQA parameters forwarded to windowed RQA.
#' @return Native design, descriptive summary and exact-center pairwise tables.
#' @export
etr_windowed_rqa_sensitivity <- function(trajectories,metrics,
    window_step_pairs,window_units="samples",step_units="samples",
    radius=NULL,target_recurrence_rate=NULL,metric="euclidean",
    theiler_window=0L,theiler_window_units="samples",dimensions=NULL,
    min_diagonal_length=2L,min_vertical_length=2L,
    undefined_policy="raise") {
  # Source completeness is selected-curve/channel scoped inside
  # windowed_rqa, not a blanket check over unrelated source channels.
  etr_validate(trajectories,require_complete=FALSE)
  pairs<-.etr_validate_rqa_window_pairs(window_step_pairs,
    window_units=window_units,step_units=step_units)
  analyses<-lapply(pairs,function(p)etr_windowed_rqa_trajectory_set(
    trajectories,metrics=metrics,window=p[1L],step=p[2L],
    window_units=window_units,step_units=step_units,radius=radius,
    target_recurrence_rate=target_recurrence_rate,metric=metric,
    theiler_window=theiler_window,
    theiler_window_units=theiler_window_units,dimensions=dimensions,
    min_diagonal_length=min_diagonal_length,
    min_vertical_length=min_vertical_length,
    undefined_policy=undefined_policy))
  resolved<-vapply(analyses,function(z)
    paste(z$window_samples,z$step_samples,sep="/"),character(1L))
  .etr_assert(!anyDuplicated(resolved),
    "duplicate resolved window/step specifications are not allowed")
  ids<-paste0("spec_",seq_along(analyses))
  design<-do.call(rbind,lapply(seq_along(analyses),function(i){
    a<-analyses[[i]];tab<-a$window_results[[1L]]$table
    centers<-a$trajectories$time
    coverage<-integer(length(trajectories$time))
    w<-a$window_samples
    for(start in tab$start_index) {
      ix<-as.integer(start)+seq_len(w)
      .etr_assert(all(ix>=1L&ix<=length(coverage)),
        "window indices exceed original source sample grid")
      coverage[ix]<-coverage[ix]+1L
    }
    analyzed<-coverage>0L
    .etr_assert(any(analyzed),
      "no original samples were included in windowed RQA")
    data.frame(specification_id=ids[i],
      requested_window=as.numeric(pairs[[i]][1L]),
      requested_step=as.numeric(pairs[[i]][2L]),
      window_units=window_units,step_units=step_units,
      window_samples=as.integer(w),
      step_samples=as.integer(a$step_samples),
      window_span_time=tab$end_time[1L]-tab$start_time[1L],
      profile_grid_spacing_time=if(length(centers)>1L)
        stats::median(diff(centers)) else NaN,
      profile_time_unit=trajectories$time_unit,
      n_windows=length(centers),
      overlap_samples=as.integer(a$overlap_samples),
      overlap_fraction=a$overlap_fraction,
      functional_support_start=centers[1L],
      functional_support_end=tail(centers,1L),
      dropped_tail_samples=as.integer(a$dropped_tail_samples),
      n_analyzed_source_samples=sum(analyzed),
      analyzed_source_fraction=mean(analyzed),
      fraction_analyzed_samples_reused=sum(coverage>1L)/sum(analyzed),
      mean_window_memberships_per_analyzed_sample=mean(coverage[analyzed]),
      max_window_memberships=max(coverage),check.names=FALSE)
  }))
  rownames(design)<-NULL
  summary<-do.call(rbind,lapply(seq_along(analyses),function(i){
    x<-analyses[[i]]$trajectories
    do.call(rbind,lapply(seq_along(x$curve_ids),function(c){
      do.call(rbind,lapply(seq_along(metrics),function(m){
        v<-as.numeric(x$values[c,,m]);v<-v[is.finite(v)]
        data.frame(specification_id=ids[i],curve_id=x$curve_ids[c],
          metric=metrics[m],n_windows=length(x$time),
          n_finite_windows=length(v),
          mean=if(length(v))mean(v) else NaN,
          standard_deviation=if(length(v)>1L)stats::sd(v) else NaN,
          minimum=if(length(v))min(v) else NaN,
          maximum=if(length(v))max(v) else NaN)
      }))
    }))
  }))
  rownames(summary)<-NULL
  pairwise<-list()
  if(length(analyses)>1L)for(i in seq_len(length(analyses)-1L))
    for(j in seq.int(i+1L,length(analyses))){
      left<-analyses[[i]]$trajectories
      right<-analyses[[j]]$trajectories
      common<-intersect(left$time,right$time)
      a<-match(common,left$time);b<-match(common,right$time)
      for(c in seq_along(left$curve_ids))
        for(m in seq_along(metrics)){
          v<-as.numeric(left$values[c,a,m])
          w<-as.numeric(right$values[c,b,m])
          ok<-is.finite(v)&is.finite(w)
          v<-v[ok];w<-w[ok];n<-length(v)
          differences<-v-w
          # Source uses np.std(..., ddof=0) for the low-variance
          # correlation gate, not R's sample sd(ddof=1). For n=2 the
          # thresholds differ, so compare the source population SD.
          cor<-if(n>=2L&&
            .etr_rqa_source_population_sd(v)>.Machine$double.eps&&
            .etr_rqa_source_population_sd(w)>.Machine$double.eps)
              stats::cor(v,w) else NaN
          pairwise[[length(pairwise)+1L]]<-data.frame(
            specification_a=ids[i],specification_b=ids[j],
            curve_id=left$curve_ids[c],metric=metrics[m],
            n_common_centers=n,
            rmse=if(n)sqrt(mean(differences^2)) else NaN,
            mean_absolute_difference=if(n)mean(abs(differences)) else NaN,
            max_absolute_difference=if(n)max(abs(differences)) else NaN,
            correlation=cor)
        }
    }
  pairwise<-if(length(pairwise))do.call(rbind,pairwise) else data.frame(
    specification_a=character(),specification_b=character(),
    curve_id=character(),metric=character(),n_common_centers=integer(),
    rmse=double(),mean_absolute_difference=double(),
    max_absolute_difference=double(),correlation=double())
  rownames(pairwise)<-NULL
  structure(list(analyses=analyses,design_table=design,
    summary_table=summary,pairwise_table=pairwise,metrics=metrics,
    provenance=list(operation="windowed_rqa_sensitivity",
      source_provenance=if(is.null(trajectories$provenance))
        list() else trajectories$provenance,
      specification_ids=ids,
      requested_window_step_pairs=lapply(pairs,as.numeric),
      resolved_window_step_samples=lapply(analyses,function(a)
        as.integer(c(a$window_samples,a$step_samples))),
      no_automatic_specification_selection=TRUE,
      pairwise_time_alignment="exact_shared_window_centers_only",
      interpolation_used_for_sensitivity_comparison=FALSE,
      summary_statistics_are_descriptive_not_inferential=TRUE,
      profile_grid_spacing_interpretation=paste(
        "derived-function temporal grid spacing; not an estimate of",
        "independent-information resolution"),
      window_dependence_interpretation=paste(
        "sample-reuse diagnostics quantify deterministic overlap only;",
        "serial dependence can remain even when overlap_fraction is zero"))),
    class="etr_windowed_rqa_sensitivity")
}

#' Simultaneous observed-grid unit-level band for derived windowed-RQA functions
#' @param trajectories Native source trajectory collection.
#' @param metrics RQA metrics to transform into derived functional observations.
#' @param window,step Explicit integer sample-width and step.
#' @param unit Inference unit, curve or participant.
#' @param participant_column Required when inference units are participants.
#' @param radius Fixed positive radius or NULL when using a target rate.
#' @param target_recurrence_rate Optional source-aligned target density in (0, 1).
#' @param confidence_level,n_multiplier,random_state Multiplier band specification.
#' @param gaussian_multiplier_draws Optional fixed source-aligned matrix of
#'   Gaussian multiplier draws, one row per replicate and one column per
#'   independent curve or participant. Allows exact finite-sample replay.
#' @param random_engine Seeded multiplier RNG: `"numpy"` or `"base_R"`.
#' @param ... Native fixed-radius windowed-RQA parameters.
#' @export
etr_windowed_rqa_functional_mean_band <- function(trajectories,
    metrics,window,step,unit,participant_column=NULL,
    window_units="samples",step_units="samples",
    radius=NULL,target_recurrence_rate=NULL,metric="euclidean",
    theiler_window=0L,theiler_window_units="samples",dimensions=NULL,
    min_diagonal_length=2L,min_vertical_length=2L,
    confidence_level=.95,n_multiplier=2000L,random_state=0L,
    gaussian_multiplier_draws=NULL,random_engine="numpy"){
  .etr_assert(identical(unit,"curve")||identical(unit,"participant"),
    "unit must be 'curve' or 'participant'")
  functional<-etr_windowed_rqa_trajectory_set(
    trajectories,metrics=metrics,window=window,step=step,
    window_units=window_units,step_units=step_units,
    radius=radius,target_recurrence_rate=target_recurrence_rate,
    metric=metric,theiler_window=theiler_window,
    theiler_window_units=theiler_window_units,dimensions=dimensions,
    min_diagonal_length=min_diagonal_length,
    min_vertical_length=min_vertical_length,
    undefined_policy="raise")
  band<-etr_multiplier_functional_mean_band(
    functional$trajectories,confidence_level=confidence_level,
    n_multiplier=n_multiplier,unit=unit,
    participant_column=participant_column,random_state=random_state,
    gaussian_multiplier_draws=gaussian_multiplier_draws,
    random_engine=random_engine)
  structure(list(functional_rqa=functional,band=band,unit=unit,
    participant_column=participant_column,
    provenance=list(operation="windowed_rqa_functional_mean_band",
      functional_rqa_provenance=if(is.null(functional$provenance))
        list() else functional$provenance,
      functional_mean_band_provenance=if(is.null(band$provenance))
        list() else band$provenance,
      resampling_unit=unit,
      # Frozen Python 1.2 retains the caller's participant_column in the
      # wrapper provenance even when unit="curve" (the multiplier
      # implementation may ignore it for curve-level inference).
      # Do not silently discard this user-supplied audit provenance.
      participant_column=participant_column,
      window_rows_resampled_as_independent=FALSE,
      whole_function_resampling_contract=TRUE,
      within_function_temporal_dependence_preserved=TRUE,
      within_source_curve_block_bootstrap=FALSE,
      inference_scope=paste("simultaneous observed-grid mean band for",
        "independent curve/participant functional units"))),
    class="etr_windowed_rqa_mean_band")
}
