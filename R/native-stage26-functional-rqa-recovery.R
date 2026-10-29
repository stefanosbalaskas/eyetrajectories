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
    c<-value$component
    .etr_assert(is.numeric(c)&&length(c)==1L&&is.finite(c)&&
      c==as.integer(c)&&c>=0,"component must be a zero-based integer")
    key<-paste0(key,".component_",as.integer(c)+1L)
  }
  key
}

#' Turn native semantically annotated recovery values into an auditable table
#' @param assessment Native list with values of known recovery metrics.
#' @return Native data.frame of source metric, value, component, source and metadata.
#' @export
etr_functional_recovery_assessment_frame <- function(assessment) {
  .etr_assert(is.list(assessment)&&is.list(assessment$values)&&
    length(assessment$values)>=1L,
    "assessment must have at least one semantic recovery value")
  defs<-etr_functional_recovery_metric_catalog()
  rows<-lapply(assessment$values,function(z){
    .etr_assert(is.list(z)&&is.list(z$metric)&&
      is.character(z$metric$name)&&length(z$metric$name)==1L&&
      z$metric$name%in%names(defs)&&
      is.numeric(z$value)&&length(z$value)==1L,
      "assessment values must carry a known metric and numeric scalar")
    .etr_assert(is.null(z$source)||
      (is.character(z$source)&&length(z$source)==1L&&
       !is.na(z$source)),
      "recovery source must be a single optional text label")
    def<-defs[[z$metric$name]]
    .etr_assert(identical(z$metric,unclass(def))||
      identical(z$metric,def),
      "assessment metric metadata must match the published source catalog")
    if(!is.null(z$component))etr_functional_recovery_value_key(z)
    data.frame(metric=def$name,value=as.numeric(z$value),
      component=if(is.null(z$component))NA_integer_
        else as.integer(z$component)+1L,
      source=if(is.null(z$source))NA_character_
        else as.character(z$source),
      quantity=def$quantity,direction=def$direction,units=def$units,
      scope=def$scope,description=def$description,
      stringsAsFactors=FALSE,check.names=FALSE)
  })
  x<-do.call(rbind,rows);rownames(x)<-NULL;x
}

#' Compact known-truth recovery assessment text without estimator retuning
#' @param assessment Native semantic recovery assessment with provenance.
#' @return A deterministic manuscript-oriented source-aligned description.
#' @export
etr_functional_recovery_reporting_text <- function(assessment) {
  frame<-etr_functional_recovery_assessment_frame(assessment)
  names<-paste(sort(unique(frame$metric)),collapse=", ")
  estimator<-if(is.null(assessment$provenance$estimator))
    "unspecified" else assessment$provenance$estimator
  .etr_assert(is.character(estimator)&&length(estimator)==1L&&
    !is.na(estimator),
    "recovery estimator provenance must be a single string")
  paste0("Known-truth recovery was evaluated after fitting for estimator '",
    estimator,"'. Recorded metric families: ",names,
    ". Metric direction, units, scope, and component/source labels are ",
    "retained explicitly. Recovery truth is an evaluation input only ",
    "and is not an estimator-tuning input.")
}

.etr_validate_rqa_window_pairs <- function(pairs) {
  if(is.matrix(pairs)&&is.numeric(pairs)&&ncol(pairs)==2L)
    pairs<-lapply(seq_len(nrow(pairs)),function(i)as.numeric(pairs[i,]))
  .etr_assert(is.list(pairs)&&length(pairs)>=1L,
    "window_step_pairs must be a nonempty list or 2-column matrix")
  for(i in seq_along(pairs)){
    v<-pairs[[i]]
    .etr_assert(is.numeric(v)&&length(v)==2L&&
      all(is.finite(v))&&all(v>0)&&all(v==as.integer(v)),
      "window and step must be positive finite integer sample counts")
  }
  pairs
}

#' Audited multiscale windowed RQA without automatic specification selection
#' @param trajectories Native complete functional trajectories.
#' @param metrics Unique RQA statistics to compare.
#' @param window_step_pairs List of explicit sample (window,step) pairs.
#' @param radius Positive declared Euclidean recurrence radius.
#' @param ... Additional fixed native RQA parameters forwarded to windowed RQA.
#' @return Native design, descriptive summary and exact-center pairwise tables.
#' @export
etr_windowed_rqa_sensitivity <- function(trajectories,metrics,
    window_step_pairs,window_units="samples",step_units="samples",
    radius,target_recurrence_rate=NULL,metric="euclidean",
    theiler_window=0L,theiler_window_units="samples",dimensions=NULL,
    min_diagonal_length=2L,min_vertical_length=2L,
    undefined_policy="raise") {
  etr_validate(trajectories,require_complete=TRUE)
  pairs<-.etr_validate_rqa_window_pairs(window_step_pairs)
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
          cor<-if(n>=2L&&stats::sd(v)>.Machine$double.eps&&
            stats::sd(w)>.Machine$double.eps)
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
      specification_ids=ids,no_automatic_specification_selection=TRUE,
      pairwise_time_alignment="exact_shared_window_centers_only",
      interpolation_used_for_sensitivity_comparison=FALSE,
      summary_statistics_are_descriptive_not_inferential=TRUE)),
    class="etr_windowed_rqa_sensitivity")
}

#' Simultaneous observed-grid unit-level band for derived windowed-RQA functions
#' @param trajectories Native source trajectory collection.
#' @param metrics RQA metrics to transform into derived functional observations.
#' @param window,step Explicit integer sample-width and step.
#' @param unit Inference unit, curve or participant.
#' @param participant_column Required when inference units are participants.
#' @param radius Mandatory finite fixed Euclidean radius in native R.
#' @param confidence_level,n_multiplier,random_state Multiplier band specification.
#' @param ... Native fixed-radius windowed-RQA parameters.
#' @export
etr_windowed_rqa_functional_mean_band <- function(trajectories,
    metrics,window,step,unit,participant_column=NULL,
    window_units="samples",step_units="samples",
    radius,target_recurrence_rate=NULL,metric="euclidean",
    theiler_window=0L,theiler_window_units="samples",dimensions=NULL,
    min_diagonal_length=2L,min_vertical_length=2L,
    confidence_level=.95,n_multiplier=2000L,random_state=0L){
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
    participant_column=participant_column,random_state=random_state)
  structure(list(functional_rqa=functional,band=band,unit=unit,
    participant_column=participant_column,
    provenance=list(operation="windowed_rqa_functional_mean_band",
      resampling_unit=unit,
      window_rows_resampled_as_independent=FALSE,
      whole_function_resampling_contract=TRUE,
      within_function_temporal_dependence_preserved=TRUE,
      within_source_curve_block_bootstrap=FALSE,
      inference_scope=paste("simultaneous observed-grid mean band for",
        "independent curve/participant functional units"))),
    class="etr_windowed_rqa_mean_band")
}
