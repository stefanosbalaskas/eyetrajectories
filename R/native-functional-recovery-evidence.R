# Native recovery evidence tables and graphics, aligned to the
# published eyetrajectoriespy 1.2 simulate.py / recovery.py contracts.
# No simulation, estimator reruns, or automatic qualification thresholds.

.etr_recovery_exact_integer <- function(x,name,minimum=-(2^53-1)) {
  .etr_assert(is.numeric(x)&&!is.complex(x)&&is.null(dim(x))&&
    length(x)==1L&&is.finite(x)&&x==trunc(x)&&
    x>=minimum&&x<=2^53-1,
    paste(name,"must be an exactly represented integer at or above",
      sprintf("%.0f",minimum)))
  if(abs(x)<=.Machine$integer.max)as.integer(x) else as.double(x)
}

.etr_recovery_component_label <- function(x) {
  if(is.null(x))return(NA_integer_)
  component<-.etr_recovery_exact_integer(x,"zero-based component",0)
  if(component<.Machine$integer.max)component+1L else as.double(component)+1
}

#' Build an explicit native functional Monte Carlo recovery evidence set
#' @param records Nonempty list of scenario replicate records.
#' @param metric_definitions Named recovery metric metadata records.
#' @return Validated native recovery result, preserving failed replicates.
#' @export
.etr_recovery_source_metric_mapping <- function(metrics) {
  # Python 1.2 FunctionalRecoveryRecord.__post_init__ applies
  # str(key).strip() and float(value) to every mapping entry.
  # Duplicate keys after stripping overwrite values in first-key order.
  .etr_assert(((is.atomic(metrics)&&!is.object(metrics)&&
      typeof(metrics)%in%c("double","integer","logical","character"))||
      (is.list(metrics)&&!is.object(metrics)))&&
    is.null(dim(metrics))&&
    (length(metrics)==0L||!is.null(names(metrics)))&&
    !anyNA(names(metrics)),
    "record metrics must be finite named numeric-like values or empty on failure")
  result<-numeric(0)
  for(i in seq_along(metrics)) {
    key<-trimws(names(metrics)[[i]],whitespace="[\\h\\v]")
    value<-.etr_recovery_source_float(metrics[[i]])
    .etr_assert(nzchar(key),
      "recovery metrics require nonblank names and finite numeric values")
    found<-match(key,names(result))
    if(is.na(found))result<-c(result,stats::setNames(value,key))
    else result[[found]]<-value
  }
  result
}


# Frozen Python float() permits underscore-separated ASCII decimal literals,
# but only between consecutive digits; as.numeric() does not. Conversely R
# accepts hexadecimal strings that Python float() rejects. This deliberately
# matches the explicit ASCII scalar subset, not arbitrary Python object
# __float__ protocols or Unicode decimal digits.
.etr_recovery_source_float <- function(value) {
  error <- "recovery metrics require nonblank names and finite numeric values"
  .etr_assert(is.atomic(value)&&!is.object(value)&&is.null(dim(value))&&
    length(value)==1L&&
    typeof(value)%in%c("double","integer","logical","character"),error)
  if(is.character(value)) {
    .etr_assert(length(value)==1L&&!is.na(value),error)
    source <- trimws(value,whitespace="[\\h\\v]")
    digit <- "[0-9](?:_?[0-9])*"
    pattern <- paste0("^[+-]?(?:",digit,"(?:\\.(?:",digit,
      ")?)?|\\.",digit,")(?:[eE][+-]?",digit,")?$")
    .etr_assert(grepl(pattern,source,perl=TRUE),error)
    value <- gsub("_","",source,fixed=TRUE)
  }
  converted <- suppressWarnings(as.numeric(value))
  .etr_assert(length(converted)==1L&&is.finite(converted),error)
  converted
}

etr_functional_recovery_result <- function(records,metric_definitions=list()) {
  .etr_assert(is.list(records)&&length(records)>=1L,
    "records must be a nonempty list of recovery replicates")
  .etr_assert(is.list(metric_definitions),
    "metric_definitions must be a list")
  if(length(metric_definitions)) {
    keys<-vapply(metric_definitions,function(d){
      .etr_assert(is.list(d)&&is.character(d$name)&&
        length(d$name)==1L&&!is.na(d$name)&&nzchar(d$name),
        "metric definition requires a nonempty name")
      d$name
    },character(1L))
    .etr_assert(!anyDuplicated(keys),"metric definitions must have unique names")
  }
  for(i in seq_along(records)) {
    r<-records[[i]]
    .etr_assert(is.list(r)&&is.character(r$scenario_name)&&
      length(r$scenario_name)==1L&&!is.na(r$scenario_name)&&
      nzchar(r$scenario_name)&&
      is.character(r$status)&&length(r$status)==1L&&
      !is.na(r$status)&&r$status%in%
      c("ok","simulation_failed","fit_failed","recovery_failed"),
      "each recovery record requires a scenario and known status")
    .etr_recovery_exact_integer(r$replicate,"replicate")
    .etr_recovery_exact_integer(r$seed,"seed")
    .etr_assert(r$replicate>=0L,"replicate index must be nonnegative")
    r$metrics<-.etr_recovery_source_metric_mapping(r$metrics)
    if(r$status=="ok") {
      .etr_assert(length(r$metrics)>=1L,
        "successful records require at least one metric")
      .etr_assert(is.null(r$error_type)&&is.null(r$error_message),
        "successful records cannot carry errors")
    } else {
      .etr_assert(length(r$metrics)==0L&&
        is.character(r$error_type)&&length(r$error_type)==1L&&
        !is.na(r$error_type)&&
        is.character(r$error_message)&&length(r$error_message)==1L&&
        !is.na(r$error_message),
        "failed records must have no metrics and explicit errors")
      r$error_type<-trimws(r$error_type,whitespace="[\\h\\v]")
      r$error_message<-trimws(r$error_message,whitespace="[\\h\\v]")
      .etr_assert(nzchar(r$error_type)&&nzchar(r$error_message),
        "failed records require error type and message after normalization")
    }
    if(length(r$metric_values)>0L) {
      .etr_assert(is.list(r$metric_values),
        "metric_values must be a list of structured recovery values")
      keys<-character(length(r$metric_values))
      for(j in seq_along(r$metric_values)){
        v<-r$metric_values[[j]]
        .etr_assert(is.list(v)&&is.list(v$metric)&&
          is.character(v$metric$name)&&length(v$metric$name)==1L&&
          is.numeric(v$value)&&!is.complex(v$value)&&length(v$value)==1L&&
          is.finite(v$value),
          "structured metric values require finite metric/value")
        keys[j]<-etr_functional_recovery_value_key(v)
      }
      .etr_assert(!anyDuplicated(keys)&&
        identical(sort(keys),sort(names(r$metrics)))&&
        all(vapply(seq_along(keys),function(j)
          isTRUE(all.equal(as.numeric(r$metrics[[keys[j]]]),
            as.numeric(r$metric_values[[j]]$value),tolerance=0)),
          logical(1L))),
        "structured metric values must exactly match flattened metrics")
    }
    records[[i]]<-r
  }
  structure(list(records=records,metric_definitions=metric_definitions),
    class="etr_functional_recovery_result")
}
.etr_check_recovery <- function(x) {
  .etr_assert(inherits(x,"etr_functional_recovery_result"),
    "result must be a native functional recovery result")
  invisible(x)
}

#' One long-form row per successful recovery replicate and source metric
#' @param result Native recovery evidence produced by etr_functional_recovery_result.
#' @return Tidy per-metric data frame (Python 1.2 source column order).
#' @export
etr_functional_recovery_frame <- function(result) {
  .etr_check_recovery(result)
  definitions<-result$metric_definitions
  def_names<-vapply(definitions,function(d)d$name,character(1L))
  fields<-c("scenario","replicate","seed","metric","value","component",
    "source","quantity","direction","units","scope")
  rows<-list()
  for(record in result$records) {
    if(record$status!="ok")next
    replicate<-.etr_recovery_exact_integer(record$replicate,"replicate",0)
    seed<-.etr_recovery_exact_integer(record$seed,"seed")
    structured<-record$metric_values
    if(length(structured)){
      for(v in structured){
        rows[[length(rows)+1L]]<-list(
          scenario=record$scenario_name,replicate=replicate,
          seed=seed,metric=v$metric$name,value=as.numeric(v$value),
          component=.etr_recovery_component_label(v$component),
          source=if(is.null(v$source))NA_character_ else as.character(v$source),
          quantity=v$metric$quantity,direction=v$metric$direction,
          units=v$metric$units,scope=v$metric$scope)
      }
    } else {
      for(nm in names(record$metrics)){
        def<-if(nm%in%def_names)definitions[[match(nm,def_names)]] else NULL
        get<-function(key)if(is.null(def)||is.null(def[[key]]))
          NA_character_ else as.character(def[[key]])
        rows[[length(rows)+1L]]<-list(
          scenario=record$scenario_name,replicate=replicate,
          seed=seed,metric=nm,
          value=as.numeric(record$metrics[[nm]]),component=NA_integer_,
          source=NA_character_,quantity=get("quantity"),
          direction=get("direction"),units=get("units"),scope=get("scope"))
      }
    }
  }
  if(!length(rows))return(data.frame())
  out<-do.call(rbind,lapply(rows,function(row)
    as.data.frame(row,stringsAsFactors=FALSE)))
  out<-out[,fields,drop=FALSE]
  rownames(out)<-NULL
  out
}

#' Explicit recovery failures and their binomial Monte Carlo standard errors
#' @param result Native recovery evidence.
#' @return One row per declared scenario with failure fraction and MCSE.
#' @export
etr_functional_recovery_failure_frame <- function(result) {
  .etr_check_recovery(result)
  labels<-enc2utf8(vapply(result$records,function(x)x$scenario_name,
    character(1L)))
  scenarios<-sort(unique(labels),method="radix")
  index<-match(labels,scenarios)
  success<-vapply(result$records,function(x)x$status=="ok",logical(1L))
  n<-tabulate(index,length(scenarios))
  good<-tabulate(index[success],length(scenarios))
  failed<-n-good
  p<-failed/n
  data.frame(scenario=scenarios,n_total=n,n_success=good,n_failed=failed,
    failure_proportion=p,failure_mcse=sqrt(p*(1-p)/n))
}

# NumPy uses a pairwise reduction with eight accumulators and 128-value
# blocks for contiguous doubles. R's mean deliberately uses wider arithmetic.
.etr_recovery_numpy_sum <- function(values) {
  n<-length(values)
  if(n<8L)return(Reduce(`+`,values,init=-0.0))
  if(n>128L){
    split<-n%/%16L*8L
    return(.etr_recovery_numpy_sum(values[seq_len(split)])+
      .etr_recovery_numpy_sum(values[seq.int(split+1L,n)]))
  }
  accum<-values[seq_len(8L)]
  end<-n-n%%8L
  if(end>8L)for(start in seq.int(9L,end,by=8L))
    accum<-accum+values[start+0:7]
  head<-((accum[1L]+accum[2L])+(accum[3L]+accum[4L]))+
    ((accum[5L]+accum[6L])+(accum[7L]+accum[8L]))
  if(end==n)head else Reduce(`+`,values[seq.int(end+1L,n)],init=head)
}

.etr_recovery_numpy_summary <- function(values,probs) {
  n<-length(values)
  mu<-(0.0+.etr_recovery_numpy_sum(values))/n
  sd<-if(n>1L)sqrt(.etr_recovery_numpy_sum((values-mu)^2)/(n-1L)) else 0
  ordered<-sort(values,method="radix")
  index<-(n-1L)*probs
  below<-floor(index)
  weight<-index-below
  low<-ordered[below+1L]
  high<-ordered[pmin(below+2L,n)]
  delta<-high-low
  # Frozen NumPy _lerp evaluates from the nearer endpoint.
  quantiles<-ifelse(weight<.5,low+delta*weight,high-delta*(1-weight))
  list(mean=mu,sd=sd,quantiles=quantiles)
}

#' Descriptive Monte Carlo recovery summaries with explicit failure frequency
#' @param result Native recovery evidence.
#' @param python_boundary_mode Use frozen NumPy double reductions and interpolation.
#' @return Source-aligned groupwise metrics; no pass/fail thresholds inferred.
#' @export
etr_functional_recovery_summary_frame <- function(result,python_boundary_mode=FALSE) {
  .etr_assert(is.logical(python_boundary_mode)&&length(python_boundary_mode)==1L&&
    !is.na(python_boundary_mode),"python_boundary_mode must be TRUE or FALSE")
  value<-etr_functional_recovery_frame(result)
  fail<-etr_functional_recovery_failure_frame(result)
  empty_fields<-c("scenario","metric","component","source",
    "n","mean","sd","median","iqr","q05","q25","q75","q95",
    "mcse_mean","n_total","n_success","n_failed",
    "failure_proportion","failure_mcse")
  if(!nrow(value)){
    result<-as.data.frame(setNames(rep(list(logical(0)),length(empty_fields)),
      empty_fields),stringsAsFactors=FALSE)
    return(result)
  }
  group<-c("scenario","metric","component","source",
    "quantity","direction","units","scope")
  # Sort once by code point and retain NA keys as the last level.
  # Radix ordering is stable, keeping source row order within each group.
  keys<-lapply(value[group],function(x)if(is.character(x))enc2utf8(x) else x)
  ord<-do.call(order,c(unname(keys),list(na.last=TRUE,method="radix")))
  start<-rep(FALSE,length(ord))
  start[1L]<-TRUE
  for(key in keys){
    key<-key[ord]
    a<-key[-length(ord)]
    b<-key[-1L]
    same<-(is.na(a)&is.na(b))|(!is.na(a)&!is.na(b)&a==b)
    start[-1L]<-start[-1L]|!same
  }
  boundaries<-c(which(start),length(ord)+1L)
  failure_row<-match(value$scenario,fail$scenario)
  probs<-c(.05,.25,.50,.75,.95)
  rows<-lapply(seq_len(length(boundaries)-1L),function(i) {
    members<-ord[seq.int(boundaries[i],boundaries[i+1L]-1L)]
    v<-value$value[members]
    n<-length(v)
    if(python_boundary_mode){
      moments<-.etr_recovery_numpy_summary(v,probs)
      mu<-moments$mean
      sd<-moments$sd
      qs<-moments$quantiles
    }else{
      mu<-mean(v)
      sd<-if(n>1L)stats::sd(v) else 0
      qs<-as.numeric(stats::quantile(v,probs,names=FALSE,type=7))
    }
    parts<-value[members[1L],group,drop=FALSE]
    f<-fail[failure_row[members[1L]],,drop=FALSE]
    data.frame(parts,n=n,mean=mu,sd=sd,median=qs[3L],
      iqr=qs[4L]-qs[2L],q05=qs[1L],q25=qs[2L],
      q75=qs[4L],q95=qs[5L],mcse_mean=sd/sqrt(n),
      n_total=f$n_total,n_success=f$n_success,n_failed=f$n_failed,
      failure_proportion=f$failure_proportion,
      failure_mcse=f$failure_mcse,check.names=FALSE)
  })
  out<-do.call(rbind,rows)
  rownames(out)<-NULL
  out
}

#' Draw metric-specific functional recovery summaries without thresholds
#' @param summary Source-aligned recovery summary data frame.
#' @param metric Exact metric name to plot.
#' @param statistic Numerical summary column; median shows IQR when available.
#' @param ... Base R graphics parameters.
#' @return Invisible exact numerical plotting geometry.
#' @export
etr_plot_functional_recovery_summary <- function(summary,metric,
    statistic="median",...) {
  .etr_assert(is.data.frame(summary)&&
    is.character(metric)&&length(metric)==1L&&!is.na(metric)&&
    nzchar(metric)&&
    is.character(statistic)&&length(statistic)==1L&&
    !is.na(statistic)&&nzchar(statistic)&&
    all(c("scenario","metric",statistic)%in%names(summary)),
    "summary requires source scenario metric and statistic columns")
  subset<-summary[!is.na(summary$metric)&
    summary$metric==metric,,drop=FALSE]
  .etr_assert(nrow(subset)>=1L,
    "metric is absent from the recovery summary")
  y<-subset[[statistic]]
  .etr_assert(is.numeric(y)&&all(is.finite(y)),
    "recovery statistic must be finite numeric source values")
  has_band<-statistic=="median"&&
    all(c("q25","q75")%in%names(subset))
  if(has_band).etr_assert(all(is.finite(subset$q25))&&
    all(is.finite(subset$q75))&&
    all(subset$q25<=y&y<=subset$q75),
    "recovery IQR must contain the source median")
  labels<-as.character(subset$scenario)
  if("source"%in%names(subset))
    labels<-paste0(labels,ifelse(is.na(subset$source),"",
      paste0(" / ",subset$source)))
  if("component"%in%names(subset))
    labels<-paste0(labels,ifelse(is.na(subset$component),"",
      paste0(" / C",as.integer(subset$component))))
  x<-seq_len(nrow(subset))-1L
  graphics::plot(x,y,pch=1,xaxt="n",xlab="Scenario",
    ylab=gsub("_"," ",statistic),main=gsub("_"," ",metric),
    ylim=range(if(has_band)c(subset$q25,subset$q75) else y),...)
  # A singleton source group has q25 == q75. R's arrows() warns on
  # zero-length intervals; the plotted point already represents that case.
  # Draw whiskers only for strictly positive interval width.
  if(has_band) {
    nondegenerate<-which(subset$q75>subset$q25)
    if(length(nondegenerate))
      graphics::arrows(x[nondegenerate],subset$q25[nondegenerate],
        x[nondegenerate],subset$q75[nondegenerate],
        length=.04,code=3,angle=90)
  }
  graphics::axis(1,at=x,labels=labels,las=2)
  invisible(data.frame(label=labels,x=x,estimate=y,
    lower=if(has_band)subset$q25 else rep(NA_real_,length(y)),
    upper=if(has_band)subset$q75 else rep(NA_real_,length(y))))
}
