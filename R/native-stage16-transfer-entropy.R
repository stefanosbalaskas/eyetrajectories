# Stage 16 — base-R empirical discrete information dynamics.
# Audited against eyetrajectoriespy==1.2.0 transfer_entropy.py,
# conditional_transfer_entropy.py, transfer_entropy_sensitivity.py.
# No Python runtime, implicit discretization or causal interpretation.
.etr16_states <- function(x,label){
  .etr_assert(is.numeric(x) && is.null(dim(x)) && length(x)>0L &&
    all(is.finite(x)) && all(x==floor(x)) &&
    all(abs(x)<2^53),paste(label,"requires finite 1D integer-coded states"))
  as.numeric(x)
}
.etr16_int <- function(x,label){
  .etr_assert(is.numeric(x)&&length(x)==1L&&!is.na(x)&&is.finite(x)&&
    x==floor(x)&&x>=1L,paste(label,"must be a positive integer"))
  as.integer(x)
}
.etr16_key <- function(z)paste(format(z,scientific=FALSE,trim=TRUE),
  collapse="\034")
.etr16_count <- function(keys){
  z<-table(keys)
  as.integer(z[match(keys,names(z))])
}
.etr16_hist <- function(x,index,history,lag=1L){
  # Source uses x[t - lag - offset] for offset=0,...,history-1.
  vapply(seq_len(history),function(j)
    x[index-lag-(j-1L)],numeric(length(index)))
}
.etr16_data <- function(source,target,condition=NULL,target_history,
  source_history,source_lag,condition_history=NULL,condition_lag=NULL){
  x<-.etr16_states(source,"source");y<-.etr16_states(target,"target")
  .etr_assert(length(x)==length(y),"source and target lengths must agree")
  kh<-.etr16_int(target_history,"target_history")
  lh<-.etr16_int(source_history,"source_history")
  dl<-.etr16_int(source_lag,"source_lag")
  has_condition<-!is.null(condition)
  if(has_condition){
    z<-.etr16_states(condition,"condition")
    .etr_assert(length(z)==length(y),
      "source, target, and condition must have the same length")
    ch<-.etr16_int(condition_history,"condition_history")
    cl<-.etr16_int(condition_lag,"condition_lag")
  }else{z<-NULL;ch<-cl<-NULL}
  first<-max(kh,dl+lh-1L,
    if(has_condition)cl+ch-1L else 0L)
  .etr_assert(length(y)>first,"history and lag leave no transitions")
  time<-seq.int(first+1L,length(y))
  n<-length(time)
  Y<-matrix(0,n,kh);X<-matrix(0,n,lh)
  for(j in seq_len(kh))Y[,j]<-y[time-j]
  for(j in seq_len(lh))X[,j]<-x[time-dl-(j-1L)]
  if(has_condition){
    Z<-matrix(0,n,ch)
    for(j in seq_len(ch))Z[,j]<-z[time-cl-(j-1L)]
  }else Z<-matrix(numeric(0),nrow=n,ncol=0L)
  a<-vapply(seq_len(n),function(i).etr16_key(Y[i,]),character(1L))
  b<-vapply(seq_len(n),function(i).etr16_key(X[i,]),character(1L))
  c<-if(has_condition)vapply(seq_len(n),function(i)
    .etr16_key(Z[i,]),character(1L)) else rep("",n)
  current<-format(y[time],scientific=FALSE,trim=TRUE)
  # Joined keys have explicit field separators; integer states are atomic.
  kfull<-paste(current,a,b,c,sep="\035")
  khistory<-paste(a,b,c,sep="\035")
  kconditioned<-paste(current,a,c,sep="\035")
  kbase<-paste(a,c,sep="\035")
  local<-log2(.etr16_count(kfull)*.etr16_count(kbase)/
    (.etr16_count(khistory)*.etr16_count(kconditioned)))
  history_support<-as.integer(table(khistory))
  fields<-list(
    local=as.numeric(local),time_indices=as.integer(time-1L),
    source_states=x,target_states=y,condition_states=z,
    target_history_states=Y,source_history_states=X,
    condition_history_states=Z,target_history=kh,source_history=lh,
    source_lag=dl,condition_history=ch,condition_lag=cl,
    n_observations=length(y),n_effective=n,
    n_source_states=length(unique(x)),n_target_states=length(unique(y)),
    n_target_histories=length(unique(a)),
    n_joint_histories=length(unique(khistory)),
    singleton_joint_history_fraction=mean(history_support==1L),
    min_joint_history_count=min(history_support),
    max_joint_history_count=max(history_support),
    mean_joint_history_count=mean(history_support))
  if(has_condition){
    fields$n_condition_states<-length(unique(z))
    fields$n_condition_histories<-length(unique(c))
    fields$n_target_condition_histories<-length(unique(kbase))
    fields$n_source_condition_histories<-length(unique(paste(b,c,sep="\035")))
  }
  fields
}
.etr16_shifts <- function(shifts,n) {
  .etr_assert(is.numeric(shifts)&&is.null(dim(shifts))&&length(shifts)>0L&&
    all(is.finite(shifts))&&all(shifts==floor(shifts))&&
    all(shifts>=1L & shifts<n)&&!anyDuplicated(shifts),
    "shifts must be distinct integers satisfying 1 <= shift < series length")
  as.integer(shifts)
}
.etr16_roll <- function(x,k){
  n<-length(x);c(tail(x,k),head(x,n-k))
}
.etr16_frame <- function(result,conditional=FALSE){
  local<-if(conditional)result$local_conditional_transfer_entropy_bits
    else result$local_transfer_entropy_bits
  n<-length(local)
  z<-data.frame(time_index=result$time_indices,
    target_state=result$target_states[result$time_indices+1L])
  z$target_history<-I(lapply(seq_len(n),function(i)
    as.integer(result$target_history_states[i,])))
  z$source_history<-I(lapply(seq_len(n),function(i)
    as.integer(result$source_history_states[i,])))
  if(conditional)z$condition_history<-I(lapply(seq_len(n),function(i)
    as.integer(result$condition_history_states[i,])))
  z[[if(conditional)"local_conditional_transfer_entropy_bits"
    else "local_transfer_entropy_bits"]]<-local
  z
}

#' Empirical plugin discrete transfer entropy in bits
#' @param source,target Explicit one-dimensional integer-coded states.
#' @param target_history,source_history,source_lag Positive sample-index specification.
#' @export
etr_discrete_transfer_entropy <- function(source,target,
    target_history,source_history,source_lag){
  d<-.etr16_data(source,target,target_history=target_history,
    source_history=source_history,source_lag=source_lag)
  structure(c(list(transfer_entropy_bits=mean(d$local),
    local_transfer_entropy_bits=d$local),d[
      setdiff(names(d),c("local","condition_states","condition_history_states",
        "condition_history","condition_lag","mean_joint_history_count"))],
    list(provenance=list(operation="discrete_transfer_entropy",
      estimator="empirical_plugin_conditional_mutual_information",
      log_base=2L,target_history=d$target_history,
      source_history=d$source_history,source_lag_samples=d$source_lag,
      automatic_discretization=FALSE,automatic_history_selection=FALSE,
      automatic_lag_selection=FALSE))),
    class="etr_discrete_transfer_entropy")
}
#' Exact history and local TE contribution audit
#' @param result Native discrete TE result.
#' @export
etr_transfer_entropy_local_frame <- function(result){
  .etr_assert(inherits(result,"etr_discrete_transfer_entropy"),
    "result must be native discrete transfer entropy")
  .etr16_frame(result)
}
#' Circular source-shift null with declared nonzero shifts
#' @param shifts Distinct, explicitly selected circular offsets.
#' @inheritParams etr_discrete_transfer_entropy
#' @export
etr_transfer_entropy_circular_shift_test <- function(source,target,
    target_history,source_history,source_lag,shifts){
  x<-.etr16_states(source,"source");p<-.etr16_shifts(shifts,length(x))
  obs<-etr_discrete_transfer_entropy(x,target,target_history,source_history,source_lag)
  sur<-vapply(p,function(s)etr_discrete_transfer_entropy(
    .etr16_roll(x,s),target,target_history,source_history,source_lag
    )$transfer_entropy_bits,numeric(1L))
  center<-mean(sur)
  structure(list(observed=obs,shifts=p,
    surrogate_transfer_entropy_bits=sur,surrogate_mean_bits=center,
    surrogate_centered_transfer_entropy_bits=obs$transfer_entropy_bits-center,
    upper_tail_p_value=(1+sum(sur>=obs$transfer_entropy_bits))/(length(sur)+1),
    p_value_resolution=1/(length(sur)+1),
    provenance=list(operation="transfer_entropy_circular_shift_test",
      null="analyst_declared_circular_source_shifts",
      tail="upper",p_value="plus_one_monte_carlo",
      shifts_samples=p,automatic_shift_generation=FALSE)),
    class="etr_transfer_entropy_circular_shift_test")
}

#' Empirical discrete conditional transfer entropy in bits
#' @param condition Explicit conditioning-process state sequence.
#' @param condition_history,condition_lag Positive sample-index specification.
#' @inheritParams etr_discrete_transfer_entropy
#' @export
etr_conditional_transfer_entropy <- function(source,target,condition,
    target_history,source_history,condition_history,source_lag,condition_lag){
  d<-.etr16_data(source,target,condition,target_history,source_history,
    source_lag,condition_history,condition_lag)
  structure(c(list(conditional_transfer_entropy_bits=mean(d$local),
    local_conditional_transfer_entropy_bits=d$local),
    d[setdiff(names(d),"local")],
    list(provenance=list(operation="conditional_transfer_entropy",
      estimator="empirical_plugin_conditional_mutual_information",
      log_base=2L,target_history=d$target_history,
      source_history=d$source_history,condition_history=d$condition_history,
      source_lag_samples=d$source_lag,condition_lag_samples=d$condition_lag,
      automatic_discretization=FALSE,automatic_history_selection=FALSE,
      automatic_lag_selection=FALSE,causal_identification_claimed=FALSE))),
    class="etr_conditional_transfer_entropy")
}
#' Exact conditioning histories and local conditional-TE contributions
#' @inheritParams etr_transfer_entropy_local_frame
#' @export
etr_conditional_transfer_entropy_local_frame <- function(result){
  .etr_assert(inherits(result,"etr_conditional_transfer_entropy"),
    "result must be native conditional transfer entropy")
  .etr16_frame(result,conditional=TRUE)
}
#' Conditional TE source-only circular shift null
#' @inheritParams etr_conditional_transfer_entropy
#' @inheritParams etr_transfer_entropy_circular_shift_test
#' @export
etr_conditional_transfer_entropy_circular_shift_test <- function(source,
    target,condition,target_history,source_history,condition_history,
    source_lag,condition_lag,shifts){
  x<-.etr16_states(source,"source");p<-.etr16_shifts(shifts,length(x))
  obs<-etr_conditional_transfer_entropy(x,target,condition,
    target_history,source_history,condition_history,source_lag,condition_lag)
  sur<-vapply(p,function(s)etr_conditional_transfer_entropy(
    .etr16_roll(x,s),target,condition,target_history,source_history,
    condition_history,source_lag,condition_lag
    )$conditional_transfer_entropy_bits,numeric(1L))
  center<-mean(sur)
  structure(list(observed=obs,shifts=p,
    surrogate_conditional_transfer_entropy_bits=sur,
    surrogate_mean_bits=center,
    surrogate_centered_conditional_transfer_entropy_bits=
      obs$conditional_transfer_entropy_bits-center,
    upper_tail_p_value=(1+sum(sur>=obs$conditional_transfer_entropy_bits))/
      (length(sur)+1),
    p_value_resolution=1/(length(sur)+1),
    provenance=list(operation="conditional_transfer_entropy_circular_shift_test",
      null="analyst_declared_source_only_circular_shifts",
      shifted_process="source",fixed_processes=c("target","condition"),
      tail="upper",p_value="plus_one_monte_carlo",
      shifts_samples=p,automatic_shift_generation=FALSE,
      causal_identification_claimed=FALSE)),
    class="etr_conditional_transfer_entropy_circular_shift_test")
}
#' Full Cartesian grid of predeclared transfer entropy specifications
#' @param target_histories,source_histories,source_lags Positive unique integer grids.
#' @inheritParams etr_transfer_entropy_circular_shift_test
#' @export
etr_transfer_entropy_parameter_sensitivity <- function(source,target,
    target_histories,source_histories,source_lags,shifts=NULL){
  grid<-list(target_histories=target_histories,
    source_histories=source_histories,source_lags=source_lags)
  for(k in names(grid)){
    v<-grid[[k]]
    .etr_assert(is.numeric(v)&&is.null(dim(v))&&length(v)>0L &&
      all(is.finite(v))&&all(v==floor(v))&&all(v>=1L)&&
      !anyDuplicated(v),paste(k,"must have distinct positive integer values"))
  }
  set<-expand.grid(source_lag=source_lags,
    source_history=source_histories,target_history=target_histories,
    KEEP.OUT.ATTRS=FALSE,stringsAsFactors=FALSE)
  # Python itertools.product varies source_lag fastest.
  set<-set[,c("target_history","source_history","source_lag")]
  rows<-vector("list",nrow(set))
  for(i in seq_len(nrow(set))){
    t<-set$target_history[i];h<-set$source_history[i];l<-set$source_lag[i]
    z<-tryCatch(if(is.null(shifts))etr_discrete_transfer_entropy(
      source,target,t,h,l)else etr_transfer_entropy_circular_shift_test(
      source,target,t,h,l,shifts),error=function(e)
      stop(sprintf("TE sensitivity failed for target_history=%d, source_history=%d, source_lag=%d: %s",
        t,h,l,conditionMessage(e)),call.=FALSE))
    obs<-if(is.null(shifts))z else z$observed
    rows[[i]]<-data.frame(specification_id=as.integer(i-1L),
      target_history=as.integer(t),source_history=as.integer(h),
      source_lag=as.integer(l),
      transfer_entropy_bits=obs$transfer_entropy_bits,
      n_effective=obs$n_effective,
      effective_fraction=obs$n_effective/obs$n_observations,
      n_target_histories=obs$n_target_histories,
      n_joint_histories=obs$n_joint_histories,
      singleton_joint_history_fraction=obs$singleton_joint_history_fraction,
      min_joint_history_count=obs$min_joint_history_count,
      max_joint_history_count=obs$max_joint_history_count,
      mean_joint_history_count=obs$n_effective/obs$n_joint_histories,
      surrogate_mean_bits=if(is.null(shifts))NaN else z$surrogate_mean_bits,
      surrogate_centered_transfer_entropy_bits=
        if(is.null(shifts))NaN else z$surrogate_centered_transfer_entropy_bits,
      upper_tail_p_value=if(is.null(shifts))NaN else z$upper_tail_p_value,
      p_value_resolution=if(is.null(shifts))NaN else z$p_value_resolution,
      n_shifts=if(is.null(shifts))0L else length(z$shifts))
  }
  tab<-do.call(rbind,rows)
  metrics<-c("transfer_entropy_bits","n_effective","effective_fraction",
    "n_target_histories","n_joint_histories",
    "singleton_joint_history_fraction","min_joint_history_count",
    "mean_joint_history_count")
  if(!is.null(shifts))metrics<-c(metrics,"surrogate_mean_bits",
    "surrogate_centered_transfer_entropy_bits","upper_tail_p_value")
  summ<-do.call(rbind,lapply(metrics,function(m){
    v<-tab[[m]];finite<-v[is.finite(v)]
    q<-if(length(finite))as.numeric(stats::quantile(finite,
      c(.25,.5,.75),names=FALSE,type=7L))else rep(NaN,3L)
    data.frame(metric=m,n_specifications=length(v),
      n_finite=length(finite),finite_fraction=length(finite)/length(v),
      minimum=if(length(finite))min(finite)else NaN,
      q25=q[1L],median=q[2L],q75=q[3L],
      maximum=if(length(finite))max(finite)else NaN,
      range=if(length(finite))diff(range(finite))else NaN,
      standard_deviation=if(length(finite)>1L)stats::sd(finite)else NaN)
  }))
  structure(list(table=tab,summary_table=summ,
    parameter_columns=c("target_history","source_history","source_lag"),
    metric_columns=metrics,source_states=.etr16_states(source,"source"),
    target_states=.etr16_states(target,"target"),
    target_histories=as.integer(target_histories),
    source_histories=as.integer(source_histories),
    source_lags=as.integer(source_lags),
    shifts=if(is.null(shifts))NULL else .etr16_shifts(shifts,length(source)),
    provenance=list(operation="transfer_entropy_parameter_sensitivity",
      design="full_cartesian_product",n_specifications=nrow(tab),
      automatic_discretization=FALSE,
      automatic_specification_ranking=FALSE,
      failed_specification_policy="raise",
      summary_interpretation="descriptive_across_declared_specifications")),
    class="etr_transfer_entropy_sensitivity")
}
#' Compact source-oriented discrete transfer entropy reporting
#' @inheritParams etr_transfer_entropy_local_frame
#' @export
etr_transfer_entropy_reporting_text <- function(result){
  .etr_assert(inherits(result,"etr_discrete_transfer_entropy"),
    "result must be native discrete transfer entropy")
  sprintf(paste0("Discrete empirical transfer entropy from source to target was ",
    "%.6g bits using target history k=%d, source history l=%d, and source ",
    "lag d=%d sample(s), based on %d effective transitions. Joint-history ",
    "support included %d observed states, with %.3f occurring once. ",
    "The estimate is conditional on the declared discrete state representation ",
    "and does not by itself establish causal influence."),
    result$transfer_entropy_bits,result$target_history,result$source_history,
    result$source_lag,result$n_effective,result$n_joint_histories,
    result$singleton_joint_history_fraction)
}
