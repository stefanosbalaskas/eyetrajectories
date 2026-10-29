# Native recovery evidence tables and graphics, aligned to the
# published eyetrajectoriespy 1.2 simulate.py / recovery.py contracts.
# No simulation, estimator reruns, or automatic qualification thresholds.

.etr_recovery_scalar <- function(x,kind,name) {
  .etr_assert(is.numeric(x)&&length(x)==1L&&!is.logical(x)&&
    is.finite(x)&&(kind!="integer"||x==as.integer(x)),
    paste(name,"must be a finite",kind,"scalar"))
  invisible(x)
}

#' Build an explicit native functional Monte Carlo recovery evidence set
#' @param records Nonempty list of scenario replicate records.
#' @param metric_definitions Named recovery metric metadata records.
#' @return Validated native recovery result, preserving failed replicates.
#' @export
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
    .etr_recovery_scalar(r$replicate,"integer","replicate")
    .etr_recovery_scalar(r$seed,"integer","seed")
    .etr_assert(r$replicate>=0L,"replicate index must be nonnegative")
    .etr_assert(is.numeric(r$metrics)&&
      (length(r$metrics)==0L||!is.null(names(r$metrics)))&&
      !anyDuplicated(names(r$metrics))&&
      all(nzchar(names(r$metrics)))&&all(is.finite(r$metrics)),
      "record metrics must be finite named numeric or empty on failure")
    if(r$status=="ok") {
      .etr_assert(length(r$metrics)>=1L,
        "successful records require at least one metric")
      .etr_assert(is.null(r$error_type)&&is.null(r$error_message),
        "successful records cannot carry errors")
    } else {
      .etr_assert(length(r$metrics)==0L&&
        is.character(r$error_type)&&length(r$error_type)==1L&&
        nzchar(r$error_type)&&
        is.character(r$error_message)&&length(r$error_message)==1L&&
        nzchar(r$error_message),
        "failed records must have no metrics and explicit errors")
    }
    if(length(r$metric_values)>0L) {
      .etr_assert(is.list(r$metric_values),
        "metric_values must be a list of structured recovery values")
      keys<-character(length(r$metric_values))
      for(j in seq_along(r$metric_values)){
        v<-r$metric_values[[j]]
        .etr_assert(is.list(v)&&is.list(v$metric)&&
          is.character(v$metric$name)&&length(v$metric$name)==1L&&
          is.numeric(v$value)&&length(v$value)==1L&&
          is.finite(v$value),
          "structured metric values require finite metric/value")
        if(!is.null(v$component)){
          .etr_recovery_scalar(v$component,"integer","component")
          .etr_assert(v$component>=0L,"component index must be nonnegative")
        }
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
    structured<-record$metric_values
    if(length(structured)){
      for(v in structured){
        rows[[length(rows)+1L]]<-list(
          scenario=record$scenario_name,replicate=as.integer(record$replicate),
          seed=as.integer(record$seed),metric=v$metric$name,value=v$value,
          component=if(is.null(v$component))NA_integer_
            else as.integer(v$component)+1L,
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
          scenario=record$scenario_name,replicate=as.integer(record$replicate),
          seed=as.integer(record$seed),metric=nm,
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
  scenarios<-sort(unique(vapply(result$records,
    function(x)x$scenario_name,character(1L))))
  out<-lapply(scenarios,function(name){
    x<-result$records[vapply(result$records,
      function(r)identical(r$scenario_name,name),logical(1L))]
    n<-length(x)
    good<-sum(vapply(x,function(z)identical(z$status,"ok"),logical(1L)))
    failed<-n-good
    p<-failed/n
    data.frame(scenario=name,n_total=n,n_success=good,n_failed=failed,
      failure_proportion=p,failure_mcse=sqrt(p*(1-p)/n))
  })
  tab<-do.call(rbind,out)
  rownames(tab)<-NULL
  tab
}

#' Descriptive Monte Carlo recovery summaries with explicit failure frequency
#' @param result Native recovery evidence.
#' @return Source-aligned groupwise metrics; no pass/fail thresholds inferred.
#' @export
etr_functional_recovery_summary_frame <- function(result) {
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
  distinct<-unique(value[,group,drop=FALSE])
  # pandas groupby(..., dropna=False, sort=True) keeps NA as a group.
  ord<-do.call(order,c(distinct, list(na.last=TRUE)))
  distinct<-distinct[ord,,drop=FALSE]
  rows<-lapply(seq_len(nrow(distinct)),function(i) {
    match_group<-rep(TRUE,nrow(value))
    for(key in group) {
      a<-value[[key]];b<-distinct[[key]][i]
      match_group<-match_group & if(is.na(b))is.na(a) else
        !is.na(a)&a==b
    }
    v<-value$value[match_group]
    n<-length(v)
    qs<-as.numeric(stats::quantile(v,c(.05,.25,.50,.75,.95),
      names=FALSE,type=7))
    sd<-if(n>1L)stats::sd(v) else 0
    parts<-distinct[i,,drop=FALSE]
    f<-fail[fail$scenario==parts$scenario,,drop=FALSE]
    .etr_assert(nrow(f)==1L,"recovery failure summary scenario join is ambiguous")
    data.frame(parts,n=n,mean=mean(v),sd=sd,median=qs[3L],
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
  if(has_band)graphics::arrows(x,subset$q25,x,subset$q75,
    length=.04,code=3,angle=90)
  graphics::axis(1,at=x,labels=labels,las=2)
  invisible(data.frame(label=labels,x=x,estimate=y,
    lower=if(has_band)subset$q25 else rep(NA_real_,length(y)),
    upper=if(has_band)subset$q75 else rep(NA_real_,length(y))))
}
