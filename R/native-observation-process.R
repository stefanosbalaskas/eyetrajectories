# Native candidate-sample diagnostics following Python 1.2 observation_process.py.

.etr_obs_history_names <- c(
  "previous_observed_x","previous_observed_y","previous_observed_eccentricity",
  "previous_observed_speed","time_since_last_observed",
  "preceding_observed_run_length","preceding_missing_run_length")
.etr_obs_scope <- "descriptive_observation_process_diagnostics"

.etr_obs_groups <- function(x)split(seq_along(x),factor(x,levels=unique(x)))
.etr_obs_labels <- function(x){
  if(is.logical(x))return(ifelse(x,"True","False"))
  if(is.double(x)&&is.numeric(x))return(vapply(x,function(value){
    if(is.infinite(value))return(if(value<0)"-inf"else"inf")
    .etr_obs_float_label(value)
  },character(1L)))
  as.character(x)
}
.etr_obs_number <- function(x){
  if(is.factor(x))x<-as.character(x)
  suppressWarnings(as.numeric(x))
}

#' Construct an explicit candidate-sample denominator
#' @export
etr_observation_process_data <- function(frame,curve_column,time_column,observed_column,
    group_column=NULL,candidate_predictors=character(),predictor_sources=NULL,
    coordinate_columns=character(),time_unit="unknown",coordinate_system="unknown",
    provenance=list()){
  .etr_assert(is.data.frame(frame)&&nrow(frame)>0L&&!anyDuplicated(names(frame)),
    "frame must contain at least one candidate sample and uniquely named columns")
  core<-list(curve_column,time_column,observed_column)
  declared<-c(core,if(!is.null(group_column))list(group_column))
  .etr_assert(all(vapply(declared,function(x)
    is.character(x)&&length(x)==1L&&!is.na(x)&&nzchar(x),logical(1L)))&&
    !anyDuplicated(unlist(declared)),"curve, time, observed and group columns must be distinct names")
  predictors<-unique(as.character(candidate_predictors))
  coordinates<-as.character(coordinate_columns)
  .etr_assert(length(coordinates)%in%c(0L,2L)&&!anyNA(coordinates),
    "coordinate_columns must be empty or contain exactly two columns")
  required<-c(unlist(declared),predictors,coordinates)
  .etr_assert(!anyNA(required)&&all(required%in%names(frame)),
    paste("frame is missing required columns:",paste(setdiff(required,names(frame)),collapse=", ")))
  .etr_assert(!any(required%in%.etr_obs_history_names),
    "declared candidate columns cannot use reserved history predictor names")
  .etr_assert(!anyNA(frame[[curve_column]]),"curve identifiers must not be missing")
  frame[[curve_column]]<-.etr_obs_labels(frame[[curve_column]])
  if(!is.null(group_column)){
    .etr_assert(!anyNA(frame[[group_column]]),"group identifiers must not be missing")
    frame[[group_column]]<-.etr_obs_labels(frame[[group_column]])
  }
  time<-.etr_obs_number(frame[[time_column]])
  .etr_assert(length(time)==nrow(frame)&&all(is.finite(time)),
    "candidate times must be finite numeric values")
  observed<-.etr_obs_number(frame[[observed_column]])
  .etr_assert(length(observed)==nrow(frame)&&all(observed%in%c(0,1)),
    "observed_column must be binary 0/1 or boolean")
  frame[[time_column]]<-time
  frame[[observed_column]]<-as.integer(observed)
  .etr_assert(!anyDuplicated(frame[c(curve_column,time_column)]),
    "candidate rows must be unique within curve/time")
  for(rows in .etr_obs_groups(frame[[curve_column]]))
    .etr_assert(all(diff(time[rows])>0),
      "candidate times must be strictly increasing in supplied row order within curve")

  sources<-as.list(predictor_sources)
  .etr_assert(length(names(sources))==length(sources)&&!anyDuplicated(names(sources))&&
    all(names(sources)%in%predictors),
    "predictor_sources contains names absent from candidate_predictors")
  resolved<-setNames(as.list(rep("candidate_time",length(predictors))),predictors)
  resolved[names(sources)]<-sources
  for(predictor in predictors){
    source<-resolved[[predictor]]
    .etr_assert(is.character(source)&&length(source)==1L&&
      source%in%c("candidate_time","design","external_candidate_time"),
      paste("invalid candidate predictor source for",predictor))
    .etr_assert(!anyNA(frame[[predictor]]),
      paste("candidate-time predictor is unavailable on some candidate rows:",predictor))
  }
  retained<-observed==1
  for(column in coordinates){
    values<-.etr_obs_number(frame[[column]])
    .etr_assert(all(is.finite(values[retained])),
      paste("coordinate column must be finite on observed rows:",column))
    .etr_assert(all(is.na(values[!retained])),
      paste("coordinate column contains values on unobserved rows:",column))
    frame[[column]]<-values
  }
  frame<-frame[order(frame[[curve_column]],time,method="radix"),,drop=FALSE]
  rownames(frame)<-NULL
  if(is.null(provenance))provenance<-list()
  .etr_assert(is.list(provenance)&&!is.data.frame(provenance),
    "provenance must be a list")
  audit<-list(denominator_source="explicit_candidate_rows",
    denominator_reconstructed_from_retained_timestamps=FALSE,
    nominal_sampling_rate_used_to_infer_missing_rows=FALSE,
    current_missing_gaze_imputed=FALSE,candidate_predictor_sources=resolved)
  provenance[names(audit)]<-audit
  structure(list(frame=frame,curve_column=curve_column,time_column=time_column,
    observed_column=observed_column,group_column=group_column,
    candidate_predictors=predictors,predictor_sources=resolved,
    coordinate_columns=coordinates,time_unit=as.character(time_unit),
    coordinate_system=as.character(coordinate_system),provenance=provenance,
    n_candidates=nrow(frame),n_observed=sum(retained),n_missing=sum(!retained),
    observed_fraction=mean(retained),curve_ids=unique(frame[[curve_column]])),
    class="etr_observation_process_data")
}

.etr_obs_rows <- function(rows,empty=data.frame()){
  if(!length(rows))return(empty)
  columns<-unique(unlist(lapply(rows,names),use.names=FALSE))
  values<-lapply(columns,function(column)unlist(lapply(rows,function(row){
    value<-row[[column]]
    if(is.null(value))NA else value
  }),use.names=FALSE))
  as.data.frame(setNames(values,columns),stringsAsFactors=FALSE,check.names=FALSE)
}

.etr_obs_hypot <- function(x,y){
  scale<-max(abs(x),abs(y))
  if(scale==0||is.infinite(scale))return(scale)
  scale*sqrt((x/scale)^2+(y/scale)^2)
}

.etr_obs_history <- function(process,curve_groups,time,observed,reference){
  x<-process$frame
  h<-matrix(NA_real_,nrow(x),length(.etr_obs_history_names),
    dimnames=list(NULL,.etr_obs_history_names))
  xy<-if(length(process$coordinate_columns))
    as.matrix(x[process$coordinate_columns])else NULL
  for(rows in curve_groups){
    last<-prior<-NA_integer_
    observed_run<-missing_run<-0L
    for(i in rows){
      h[i,6:7]<-c(observed_run,missing_run)
      if(!is.na(last)){
        h[i,5L]<-time[i]-time[last]
        if(!is.null(xy)){
          h[i,1:2]<-xy[last,]
          if(!is.null(reference)){
            delta<-xy[last,]-reference
            h[i,3L]<-.etr_obs_hypot(delta[1L],delta[2L])
          }
          if(!is.na(prior)){
            delta<-xy[last,]-xy[prior,]
            h[i,4L]<-.etr_obs_hypot(delta[1L],delta[2L])/(time[last]-time[prior])
          }
        }
      }
      if(observed[i]==1L){
        observed_run<-observed_run+1L
        missing_run<-0L
        prior<-last
        last<-i
      }else{
        missing_run<-missing_run+1L
        observed_run<-0L
      }
    }
  }
  x[.etr_obs_history_names]<-as.data.frame(h)
  x
}

.etr_obs_edges <- function(values,bins,name){
  if(is.null(bins))return(NULL)
  .etr_assert(is.numeric(bins)&&is.null(dim(bins))&&!anyNA(bins),
    paste(name,"must be an integer count or finite edge vector"))
  if(length(bins)==1L){
    .etr_assert(is.finite(bins)&&bins==floor(bins)&&bins>=2&&bins<.Machine$integer.max,
      paste(name,"integer must be >= 2"))
    limits<-range(values)
    .etr_assert(all(is.finite(limits)),paste(name,"cannot be constructed for nonfinite values"))
    .etr_assert(limits[2L]>limits[1L],paste(name,"cannot be constructed for constant values"))
    return(seq(limits[1L],limits[2L],length.out=bins+1L))
  }
  .etr_assert(length(bins)>=3L&&all(is.finite(bins)),
    paste(name,"edges must contain at least three finite values"))
  .etr_assert(all(diff(bins)>0),paste(name,"edges must be strictly increasing"))
  .etr_assert(bins[1L]<=min(values)&&tail(bins,1L)>=max(values),
    paste(name,"edges must cover all evaluated values"))
  as.numeric(bins)
}

.etr_obs_float_label <- function(x){
  if(x==0)return(if(1/x<0)"-0.0"else"0.0")
  magnitude<-abs(x)
  for(digits in 0:16){
    repr<-sprintf("%.*e",digits,magnitude)
    if(as.numeric(repr)==magnitude)break
  }
  parts<-strsplit(repr,"e",fixed=TRUE)[[1L]]
  exponent<-as.integer(parts[2L])
  figures<-sub("0+$","",gsub(".","",parts[1L],fixed=TRUE))
  point<-exponent+1L
  n<-nchar(figures)
  if(exponent< -4L||exponent>=16L){
    mantissa<-if(n==1L)figures else paste0(substr(figures,1L,1L),".",substring(figures,2L))
    value<-paste0(mantissa,"e",if(exponent<0L)"-"else"+",sprintf("%02d",abs(exponent)))
  }else if(point<=0L)value<-paste0("0.",strrep("0",-point),figures)
  else if(point>=n)value<-paste0(figures,strrep("0",point-n),".0")
  else value<-paste0(substr(figures,1L,point),".",substring(figures,point+1L))
  paste0(if(x<0)"-"else"",value)
}

.etr_obs_bins <- function(edges){
  # Membership uses the original edges. Reported interval labels use the
  # rounded breakpoints of pandas cut with include_lowest.
  round_breaks<-function(precision)vapply(edges,function(x)
    round(x,if(x!=0&&abs(x)<1)precision-1L-floor(log10(abs(x)))else precision),
    numeric(1L))
  for(precision in 3:19){
    displayed<-round_breaks(precision)
    if(!anyDuplicated(displayed))break
  }
  displayed[1L]<-displayed[1L]-10^(-precision)
  lower<-head(displayed,-1L);upper<-tail(displayed,-1L)
  label<-function(x)vapply(x,.etr_obs_float_label,character(1L))
  list(lower=lower,upper=upper,level=paste0("(",label(lower),", ",label(upper),"]"))
}

.etr_obs_profile_template <- function()data.frame(
  predictor=character(),source=character(),profile_type=character(),
  level=character(),lower=double(),upper=double(),candidate_count=integer(),
  observed_count=integer(),observed_fraction=double())

.etr_obs_profile <- function(values,observed,predictor,source,edges=NULL,numeric=FALSE){
  if(numeric){
    bins<-.etr_obs_bins(edges)
    groups<-split(seq_along(values),.bincode(values,edges,right=TRUE,include.lowest=TRUE))
    slots<-as.integer(names(groups))
    lower<-bins$lower[slots];upper<-bins$upper[slots]
    levels<-bins$level[slots]
  }else{
    groups<-.etr_obs_groups(.etr_obs_labels(values))
    levels<-names(groups)
    lower<-upper<-rep(NA_real_,length(groups))
  }
  data.frame(predictor=predictor,source=source,
    profile_type=if(numeric)"numeric_bin"else"category",
    level=levels,lower=lower,upper=upper,candidate_count=unname(lengths(groups)),
    observed_count=unname(vapply(groups,function(rows)sum(observed[rows]),integer(1L))),
    observed_fraction=unname(vapply(groups,function(rows)mean(observed[rows]),numeric(1L))),
    stringsAsFactors=FALSE)
}

.etr_obs_association <- function(values,observed,predictor,source,numeric){
  row<-list(predictor=predictor,source=source,
    predictor_type=if(numeric)"numeric"else"categorical")
  if(numeric&&!all(is.finite(values))){
    row$status_code<-"predictor_nonfinite"
    return(row)
  }
  if(!numeric)values<-.etr_obs_labels(values)
  n_unique<-length(unique(values))
  status<-if(n_unique<2L)"predictor_constant"else
    if(length(unique(observed))<2L)"outcome_constant"else"ok"
  row<-c(row,list(status_code=status,n_rows=length(values),n_unique=n_unique))
  if(status!="ok")return(row)
  statistics<-as.list(rep(NA_real_,7L))
  names(statistics)<-c("observed_mean","missing_mean","standardized_mean_difference",
    "spearman_rho","min_observed_fraction","max_observed_fraction","observed_fraction_range")
  if(numeric){
    retained<-values[observed==1L];missing<-values[observed==0L]
    n1<-length(retained);n0<-length(missing)
    mean1<-mean(retained);mean0<-mean(missing)
    statistics$observed_mean<-mean1
    statistics$missing_mean<-mean0
    if(n1>1L&&n0>1L){
      pooled<-sqrt(((n1-1L)*stats::var(retained)+(n0-1L)*stats::var(missing))/(n1+n0-2L))
      if(is.finite(pooled)&&pooled>0)statistics$standardized_mean_difference<-(mean1-mean0)/pooled
    }
    statistics$spearman_rho<-stats::cor(rank(values),observed)
  }else{
    rates<-vapply(.etr_obs_groups(values),function(rows)mean(observed[rows]),numeric(1L))
    statistics$min_observed_fraction<-min(rates)
    statistics$max_observed_fraction<-max(rates)
    statistics$observed_fraction_range<-diff(range(rates))
  }
  c(row,statistics)
}

.etr_obs_support <- function(curves,groups,observed,time,edges,threshold){
  empty<-data.frame(scope=character(),scope_id=character(),time_bin=character(),
    lower=double(),upper=double(),candidate_count=integer(),observed_count=integer(),
    missing_count=integer(),observed_fraction=double(),no_candidate_support=logical(),
    zero_observed_support=logical(),near_zero_observed_support=logical())
  if(is.null(edges))return(empty)
  bins<-.etr_obs_bins(edges)
  memberships<-.bincode(time,edges,right=TRUE,include.lowest=TRUE)
  count<-length(bins$level)
  summarise<-function(scope,slices)lapply(seq_along(slices),function(i){
    rows<-slices[[i]]
    n<-tabulate(memberships[rows],count)
    retained<-tabulate(memberships[rows[observed[rows]==1L]],count)
    fraction<-ifelse(n>0L,retained/n,NA_real_)
    data.frame(scope=scope,scope_id=names(slices)[i],time_bin=bins$level,
      lower=bins$lower,upper=bins$upper,candidate_count=n,observed_count=retained,
      missing_count=n-retained,observed_fraction=fraction,
      no_candidate_support=n==0L,zero_observed_support=n>0L&retained==0L,
      near_zero_observed_support=n>0L&fraction<threshold,stringsAsFactors=FALSE)
  })
  do.call(rbind,c(summarise("curve",curves),summarise("group",groups)))
}

#' Diagnose candidate-sample retention and past-only history
#' @export
etr_diagnose_observation_process <- function(process,predictors=NULL,
    history_predictors=character(),eccentricity_reference=NULL,
    risk_set="all_candidates",time_basis="linear",time_bins=NULL,
    association_bins=4L,low_support_threshold=.10){
  .etr_assert(inherits(process,"etr_observation_process_data"),
    "process must be an etr_observation_process_data")
  .etr_assert(is.null(time_basis)||identical(time_basis,"linear"),
    "time_basis must be NULL or linear")
  .etr_assert(is.numeric(low_support_threshold)&&length(low_support_threshold)==1L&&
    is.finite(low_support_threshold)&&low_support_threshold>=0&&low_support_threshold<=1,
    "low_support_threshold must be finite and within [0, 1]")
  .etr_assert(identical(risk_set,"all_candidates")||identical(risk_set,"after_observed"),
    "risk_set must be all_candidates or after_observed")
  requested<-if(is.null(predictors))process$candidate_predictors else unique(as.character(predictors))
  history<-unique(as.character(history_predictors))
  .etr_assert(all(requested%in%process$candidate_predictors),
    "predictors must have been declared as complete candidate-time predictors")
  .etr_assert(all(history%in%.etr_obs_history_names),"unknown history predictor")
  .etr_assert(is.null(eccentricity_reference)||
    (is.numeric(eccentricity_reference)&&is.null(dim(eccentricity_reference))&&
      length(eccentricity_reference)==2L&&all(is.finite(eccentricity_reference))),
    "eccentricity_reference must contain two finite coordinates")

  data<-process$frame
  time<-data[[process$time_column]]
  observed<-data[[process$observed_column]]
  curves<-.etr_obs_groups(data[[process$curve_column]])
  groups<-if(is.null(process$group_column))list()else .etr_obs_groups(data[[process$group_column]])
  candidate<-.etr_obs_history(process,curves,time,observed,eccentricity_reference)
  risk<-rep(TRUE,nrow(data))
  if(risk_set=="after_observed"){
    for(rows in curves)risk[rows]<-c(FALSE,head(observed[rows],-1L)==1L)
  }
  .etr_assert(any(risk),"selected risk_set contains no candidate rows")
  y<-observed[risk]
  count<-function(z)list(candidate_count=length(z),observed_count=sum(z),
    missing_count=length(z)-sum(z),observed_fraction=mean(z))
  global_summary<-.etr_obs_rows(list(c(count(observed),
    list(missing_fraction=1-mean(observed),curve_count=length(curves),
      group_count=if(length(groups))length(groups)else NA_integer_,
      risk_set=risk_set,risk_candidate_count=length(y),risk_observed_count=sum(y),
      risk_missing_count=length(y)-sum(y)))))
  median_interval<-function(t)if(length(t)>1L)stats::median(diff(t))else NA_real_
  curve_summary<-.etr_obs_rows(lapply(seq_along(curves),function(i){
    rows<-curves[[i]]
    t<-time[rows];z<-observed[rows];retained<-t[z==1L]
    runs<-rle(z)
    c(list(curve_id=names(curves)[i]),count(z),
      list(candidate_start=t[1L],candidate_end=tail(t,1L),
        observed_start=retained[1L],observed_end=if(length(retained))tail(retained,1L)else NA_real_,
        candidate_median_interval=median_interval(t),observed_median_interval=median_interval(retained),
        longest_observed_run=max(c(0L,runs$lengths[runs$values==1L])),
        longest_missing_run=max(c(0L,runs$lengths[runs$values==0L]))))
  }))
  group_summary<-.etr_obs_rows(lapply(seq_along(groups),function(i){
    rows<-groups[[i]]
    c(list(group_id=names(groups)[i],curve_count=length(unique(data[[process$curve_column]][rows]))),
      count(observed[rows]))
  }),data.frame(group_id=character(),curve_count=integer(),candidate_count=integer(),
    observed_count=integer(),missing_count=integer(),observed_fraction=double()))
  edges<-.etr_obs_edges(time,time_bins,"time_bins")
  support<-.etr_obs_support(curves,groups,observed,time,edges,low_support_threshold)
  time_summary<-if(is.null(edges)).etr_obs_profile_template()else
    .etr_obs_profile(time[risk],y,process$time_column,"candidate_time",edges,numeric=TRUE)
  associations<-profiles<-failures<-list()
  fail<-function(item,source,code,message){
    failures[[length(failures)+1L]]<<-list(item=item,source=source,status_code=code,message=message)
  }
  if(!is.null(time_basis))associations[[1L]]<-.etr_obs_association(
    time[risk],y,process$time_column,"candidate_time",numeric=TRUE)
  add<-function(values,kept,predictor,source,numeric,excluded=NULL){
    row<-.etr_obs_association(values,kept,predictor,source,numeric)
    row$n_excluded_insufficient_history<-excluded
    associations[[length(associations)+1L]]<<-row
    edges<-NULL
    if(numeric){
      edges<-tryCatch(.etr_obs_edges(values,association_bins,"association_bins"),
        error=function(e){
          fail(predictor,source,"profile_unavailable",conditionMessage(e))
          NULL
        })
      if(is.null(edges))return(invisible(NULL))
    }
    profiles[[length(profiles)+1L]]<<-.etr_obs_profile(
      values,kept,predictor,source,edges,numeric)
  }
  for(predictor in requested){
    values<-candidate[[predictor]][risk]
    numeric<-is.numeric(values)||is.logical(values)
    if(numeric)values<-as.numeric(values)
    add(values,y,predictor,process$predictor_sources[[predictor]],numeric)
  }
  for(predictor in history){
    if(predictor%in%.etr_obs_history_names[1:4]&&!length(process$coordinate_columns)){
      fail(predictor,"history","history_coordinates_unavailable",
        "raw observed coordinate columns were not supplied")
      next
    }
    if(predictor=="previous_observed_eccentricity"&&is.null(eccentricity_reference)){
      fail(predictor,"history","reference_definition_required",
        "eccentricity_reference is required for this history predictor")
      next
    }
    values<-candidate[[predictor]][risk]
    finite<-is.finite(values)
    if(!any(finite)){
      fail(predictor,"history","history_unavailable",
        "no candidate rows have sufficient prior observed history")
      next
    }
    add(values[finite],y[finite],predictor,"history",numeric=TRUE,excluded=sum(!finite))
  }
  provenance<-list(scope=.etr_obs_scope,denominator_source="explicit_candidate_rows",
    time_basis=time_basis,time_bins=edges,association_bins=association_bins,
    risk_set=risk_set,low_support_threshold=low_support_threshold,
    time_summary_uses_selected_risk_set=TRUE,support_summary_uses_full_candidate_denominator=TRUE,
    predictor_sources=process$predictor_sources,history_predictors=history,
    history_uses_past_information_only=TRUE,eccentricity_reference=eccentricity_reference,
    iid_sample_level_inference_performed=FALSE,p_values_reported=FALSE,
    missing_mechanism_classification_performed=FALSE,inverse_probability_weighting_performed=FALSE,
    inverse_intensity_correction_performed=FALSE,current_missing_gaze_imputed=FALSE,
    sparse_estimator_modified=FALSE)
  structure(list(process=process,candidate_frame=candidate,global_summary=global_summary,
    curve_summary=curve_summary,group_summary=group_summary,time_summary=time_summary,
    support_summary=support,associations=.etr_obs_rows(associations),
    profiles=if(length(profiles))do.call(rbind,profiles)else .etr_obs_profile_template(),
    failures=.etr_obs_rows(failures,data.frame(item=character(),source=character(),
      status_code=character(),message=character())),risk_set=risk_set,time_basis=time_basis,
    association_bins=association_bins,time_bins=time_bins,low_support_threshold=low_support_threshold,
    scope=.etr_obs_scope,provenance=provenance),class="etr_observation_process_diagnostic")
}

#' Extract a native observation-process diagnostic table
#' @export
etr_observation_process_frame <- function(result,table="associations"){
  .etr_assert(inherits(result,"etr_observation_process_diagnostic"),
    "result must be an etr_observation_process_diagnostic")
  fields<-c(global="global_summary",curves="curve_summary",groups="group_summary",
    time="time_summary",support="support_summary",associations="associations",
    profiles="profiles",failures="failures",candidates="candidate_frame")
  .etr_assert(is.character(table)&&length(table)==1L&&table%in%names(fields),
    paste("table must be one of",paste(sort(names(fields)),collapse=", ")))
  result[[fields[[table]]]]
}

#' Describe the explicit denominator and the scope of observation diagnostics
#' @export
etr_observation_process_reporting_text <- function(result){
  summary<-etr_observation_process_frame(result,"global")
  associations<-result$associations
  ok<-associations$predictor[which(associations$status_code=="ok")]
  group_phrase<-if(is.finite(summary$group_count))
    paste0(", across ",summary$group_count," declared groups")else""
  predictors<-if(length(ok))paste(ok,collapse=", ")else"no estimable requested predictors"
  paste0("Observation-process diagnostics used an explicit denominator of ",
    summary$candidate_count," candidate samples across ",summary$curve_count,
    " curves",group_phrase,"; ",summary$missing_count," samples (",
    sprintf("%.1f",100*summary$missing_fraction),"%) were not retained. ",
    "Descriptive associations were estimable for ",predictors,". ",nrow(result$failures),
    " diagnostic item(s) were retained with explicit failure/status records. ",
    "The analysis reports descriptive observation-process associations only: it ",
    "does not provide iid sample-level inference, classify the process as MAR/MNAR, ",
    "impute current missing gaze, or apply inverse-probability/intensity correction.")
}

.etr_sparse_observation_options <- function(process,request){
  if(is.null(request)&&is.null(process))return(NULL)
  .etr_assert(!is.null(request),
    "observation_process requires explicit config$observation_diagnostics")
  .etr_assert(inherits(process,"etr_observation_process_data"),
    "observation_diagnostics requires an explicit observation_process candidate denominator")
  defaults<-list(predictors=NULL,history_predictors=character(),eccentricity_reference=NULL,
    risk_set="all_candidates",time_basis="linear",time_bins=NULL,
    association_bins=4L,low_support_threshold=.10)
  .etr_assert(is.list(request)&&!is.data.frame(request)&&
    length(names(request))==length(request)&&!anyDuplicated(names(request))&&
    all(names(request)%in%names(defaults)),
    "observation_diagnostics must be a named list of diagnostic options")
  defaults[names(request)]<-request
  defaults
}

.etr_sparse_observation_workflow <- function(workflow,process,options){
  workflow["observation_diagnostics"]<-list(NULL)
  workflow$decisions$observation_diagnostics_requested<-
    .etr_source_workflow_decision(!is.null(options))
  if(is.null(options))return(workflow)
  run<-.etr_sparse_timed_step("observation_process_diagnostics",
    "diagnose_observation_process",options,
    do.call(etr_diagnose_observation_process,c(list(process=process),options)))
  result<-run$result
  workflow$observation_diagnostics<-result
  workflow$steps[[length(workflow$steps)+1L]]<-run$step
  workflow$reports$observation_diagnostics<-etr_observation_process_reporting_text(result)
  workflow$tables$observation_global<-result$global_summary
  workflow$tables$observation_time<-result$time_summary
  workflow$tables$observation_associations<-result$associations
  workflow
}
