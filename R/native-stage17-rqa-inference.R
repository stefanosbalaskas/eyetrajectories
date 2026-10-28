# Stage 17: independently estimated RQA bootstrap and declared multiverse.
# Python reference rqa_inference.py and nonlinear_sensitivity.py.
# Supports fixed Euclidean radius and sample lags; unsupported source
# threshold/time-unit variants error rather than silently substituting.

.etr17_rqa_source <- function(x,dimensions,embedding_dimension,delay,
  delay_units){
  etr_validate(x,require_complete=TRUE)
  .etr_assert(is.character(dimensions)&&length(dimensions)>0L&&
    !anyNA(dimensions)&&!anyDuplicated(dimensions)&&
    all(dimensions%in%x$dimension_names),
    "dimensions must explicitly select unique existing channels")
  .etr_assert(identical(delay_units,"samples"),
    "delay_units must be samples in native RQA inference")
  if(is.null(embedding_dimension)){
    .etr_assert(is.null(delay),
      "delay must be NULL without embedding_dimension")
    cols<-match(dimensions,x$dimension_names)
    vals<-x$values[,,cols,drop=FALSE]
    return(etr_trajectory_set(x$time,vals,x$curve_ids,dimensions,
      metadata=x$metadata,coordinate_system=x$coordinate_system,
      time_unit=x$time_unit,provenance=x$provenance))
  }
  m<-.etr17_integer(embedding_dimension,2L,"embedding_dimension")
  .etr_assert(!is.null(delay),
    "delay required when embedding_dimension is specified")
  z<-etr_delay_embed_trajectory(x,m,delay,"samples",dimensions)
  etr_trajectory_set(z$time,z$values,z$curve_ids,z$state_names,
    metadata=x$metadata,coordinate_system=x$coordinate_system,
    time_unit=x$time_unit,provenance=z$provenance)
}
.etr17_rqa_metrics <- c("recurrence_rate","determinism",
 "mean_diagonal_length","max_diagonal_length","diagonal_entropy",
 "laminarity","trapping_time","max_vertical_length")

#' Independent-unit bootstrap of fixed-radius curve-level RQA means
#' @param trajectories Complete native curve collection.
#' @param dimensions Explicit channel selection.
#' @param metrics Explicit RQA metric names.
#' @param radius Fixed Euclidean recurrence radius; required in native subset.
#' @param target_recurrence_rate Unsupported adaptive threshold; errors.
#' @param distance_metric Must be "euclidean".
#' @param theiler_window Excluded temporal lag in samples.
#' @param theiler_window_units Only "samples" is supported.
#' @param min_diagonal_length,min_vertical_length Explicit line length cutoffs.
#' @param embedding_dimension Optional reconstructed state dimension >=2.
#' @param delay Optional sample delay required with embedding_dimension.
#' @param delay_units Only "samples" supported.
#' @param unit Curve or equal-weight participant independent units.
#' @param participant_column Required for participant-level inference.
#' @param confidence_level Nominal bootstrap percentile level.
#' @param n_bootstrap At least 100 whole-unit resamples.
#' @param random_state Scoped base R RNG, not NumPy streams.
#' @export
etr_bootstrap_rqa_metric_means <- function(trajectories,dimensions,metrics,
    radius=NULL,target_recurrence_rate=NULL,distance_metric="euclidean",
    theiler_window=0L,theiler_window_units="samples",
    min_diagonal_length=2L,min_vertical_length=2L,
    embedding_dimension=NULL,delay=NULL,delay_units="samples",
    unit="curve",participant_column=NULL,confidence_level=.95,
    n_bootstrap=2000L,random_state=0L){
  .etr_assert(is.null(target_recurrence_rate)&&!is.null(radius),
    "native RQA bootstrap currently requires explicit fixed radius; target_recurrence_rate unsupported")
  .etr_assert(identical(distance_metric,"euclidean"),
    "only Euclidean RQA metric is qualified")
  .etr_assert(identical(theiler_window_units,"samples"),
    "theiler_window_units must be samples")
  .etr_assert(is.character(metrics)&&length(metrics)>0L&&
    !anyNA(metrics)&&!anyDuplicated(metrics)&&
    all(metrics%in%.etr17_rqa_metrics),
    "metrics must be nonempty distinct supported RQA metrics")
  .etr_assert(is.numeric(radius)&&length(radius)==1L&&
    is.finite(radius)&&radius>=0,
    "radius must be finite nonnegative")
  th<-.etr17_integer(theiler_window,0L,"theiler_window")
  md<-.etr17_integer(min_diagonal_length,1L,"min_diagonal_length")
  mv<-.etr17_integer(min_vertical_length,1L,"min_vertical_length")
  nboot<-.etr17_integer(n_bootstrap,100L,"n_bootstrap")
  .etr15_prob(confidence_level,"confidence_level")
  .etr15_options(trajectories,unit,participant_column)
  data<-.etr17_rqa_source(trajectories,dimensions,
    embedding_dimension,delay,delay_units)
  nr<-length(data$curve_ids)
  obs<-data.frame(curve_id=data$curve_ids,stringsAsFactors=FALSE)
  for(metric in metrics)obs[[metric]]<-numeric(nr)
  obs$resolved_radius<-rep(as.numeric(radius),nr)
  obs$achieved_recurrence_rate<-numeric(nr)
  obs$theiler_window_samples<-rep(th,nr)
  for(i in seq_len(nr)){
    rec<-etr_recurrence_matrix(data,curve=i,radius=radius,theiler=th)
    q<-etr_rqa_metrics(rec,min_diagonal_length=md,min_vertical_length=mv)
    obs$achieved_recurrence_rate[i]<-rec$recurrence_rate
    for(metric in metrics){
      value<-q[[metric]]
      .etr_assert(is.numeric(value)&&length(value)==1L&&is.finite(value),
        paste("RQA metric",metric,"is undefined for curve",data$curve_ids[i],
          "; no dropping or imputation"))
      obs[[metric]][i]<-value
    }
  }
  n<-length(trajectories$curve_ids)
  if(unit=="curve"){
    ids<-trajectories$curve_ids
    tab<-data.frame(unit_id=ids,obs[,metrics,drop=FALSE],
      check.names=FALSE)
    counts<-rep(1L,length(ids))
  }else{
    g<-as.character(trajectories$metadata[[participant_column]])
    ids<-unique(g);counts<-vapply(ids,function(v)sum(g==v),integer(1L))
    tab<-data.frame(unit_id=ids,n_curves=counts)
    for(metric in metrics)tab[[metric]]<-vapply(ids,function(id)
      mean(obs[[metric]][g==id]),numeric(1L))
  }
  nunit<-length(ids)
  .etr_assert(nunit>=2L,"At least two independent RQA units required")
  vals<-as.matrix(tab[,metrics,drop=FALSE])
  observed<-colMeans(vals)
  restore<-.etr13_rng(random_state);on.exit(restore(),add=TRUE)
  draws<-matrix(0,nboot,length(metrics))
  for(i in seq_len(nboot))draws[i,]<-colMeans(
    vals[sample.int(nunit,nunit,replace=TRUE),,drop=FALSE])
  colnames(draws)<-metrics
  alpha<-(1-confidence_level)/2
  lower<-apply(draws,2L,stats::quantile,probs=alpha,names=FALSE,type=7L)
  upper<-apply(draws,2L,stats::quantile,probs=1-alpha,names=FALSE,type=7L)
  summary<-data.frame(metric=metrics,mean=as.numeric(observed),
    bootstrap_mean=colMeans(draws),
    bootstrap_bias=colMeans(draws)-as.numeric(observed),
    bootstrap_standard_error=apply(draws,2L,stats::sd),
    lower=as.numeric(lower),upper=as.numeric(upper))
  boot<-data.frame(bootstrap_id=seq_len(nboot),draws,check.names=FALSE)
  structure(list(observed_table=obs,unit_table=tab,
    bootstrap_table=boot,summary_table=summary,metrics=metrics,unit=unit,
    unit_ids=ids,participant_column=if(unit=="participant")participant_column else NULL,
    confidence_level=confidence_level,n_bootstrap=nboot,
    provenance=list(operation="bootstrap_rqa_metric_means",
      threshold_policy="fixed_radius",requested_radius=radius,
      distance_metric=distance_metric,dimensions=dimensions,
      metric_families=metrics,independent_unit=unit,
      curves_per_unit=counts,
      inference_boundary=paste("Population-average per-curve RQA metric",
        "bootstrap; not single-series recurrence uncertainty"),
      support_restriction="fixed-radius Euclidean sample-unit contract",
      random_engine="base_R_not_NumPy")),
    class="etr_rqa_metric_bootstrap")
}
