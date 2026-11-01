# Stage 17: independent delay embedding, divergence, and Lyapunov fits.
# Python 1.2 reference: embedding.py and nonlinear_dynamics.py.
# Numeric R-only implementations; no inference of deterministic chaos.

.etr_nonlinear_integer <- function(x,minimum,name) {
  .etr_assert(is.numeric(x)&&length(x)==1L&&is.finite(x)&&
    x==as.integer(x)&&x>=minimum,paste(name,"must be integer >=",minimum))
  as.integer(x)
}
.etr_nonlinear_curve <- function(ids,curve){
  if(is.character(curve)) {
    .etr_assert(length(curve)==1L&&curve%in%ids,
      "curve_id was not found")
    return(match(curve,ids))
  }
  .etr_assert(is.numeric(curve)&&length(curve)==1L&&
    is.finite(curve)&&curve==as.integer(curve)&&
    curve>=0L&&curve<length(ids),
    "curve must be a zero-based integer index or source curve_id")
  as.integer(curve)+1L
}
.etr_nonlinear_embedding <- function(z){
  .etr_assert(inherits(z,"etr_delay_embedding_set")&&
    is.array(z$values)&&length(dim(z$values))==3L&&
    all(is.finite(z$values))&&
    dim(z$values)[1L]==length(z$curve_ids)&&
    dim(z$values)[2L]==length(z$time)&&
    all(is.finite(z$time))&&all(diff(z$time)>0),
    "embedding must be a complete native delay-coordinate result")
  invisible(z)
}

#' Native multichannel delay-coordinate trajectory reconstruction
#' @param trajectories Complete native shared-grid functional trajectories.
#' @param embedding_dimension Number of lagged state blocks (>=1).
#' @param delay Positive delay (sample count or physical time).
#' @param delay_units "samples", seconds/milliseconds alias, or the trajectory
#'   time unit; physical-time delays require approximately regular sampling.
#' @param dimensions Nonempty explicitly selected functional dimensions.
#' @export
etr_delay_embed_trajectory <- function(trajectories,embedding_dimension,
    delay,delay_units="samples",dimensions=NULL){
  etr_validate(trajectories,require_complete=TRUE)
  m<-.etr_nonlinear_integer(embedding_dimension,1L,"embedding_dimension")
  lag<-.etr_source_time_unit_samples(trajectories$time,delay,
    units=delay_units,time_unit=trajectories$time_unit,name="delay")
  .etr_assert(is.character(dimensions)&&length(dimensions)>0L&&
    !anyNA(dimensions)&&!anyDuplicated(dimensions)&&
    all(dimensions%in%trajectories$dimension_names),
    "dimensions must be explicit, unique, known trajectory channels")
  n<-length(trajectories$curve_ids);nt<-length(trajectories$time)
  first<-(m-1L)*lag
  .etr_assert(first<nt-1L,
    "embedding_dimension and delay leave fewer than two reconstructed states")
  endpts<-seq.int(first+1L,nt);nstate<-length(endpts)
  nd<-length(dimensions);out<-array(0,c(n,nstate,m*nd))
  selected<-match(dimensions,trajectories$dimension_names)
  cols<-character(m*nd)
  for(j in seq_len(m)){
    source_time<-endpts-(j-1L)*lag
    for(d in seq_len(nd)){
      col<-(j-1L)*nd+d
      out[,,col]<-matrix(trajectories$values[,
        source_time,selected[d],drop=FALSE],n,nstate)
      cols[col]<-sprintf("%s[t-%d*delay]",dimensions[d],j-1L)
    }
  }
  step<-tryCatch(.etr_series_regular_spacing(trajectories$time),
    error=function(e)NA_real_)
  structure(list(values=out,time=trajectories$time[endpts],
    curve_ids=trajectories$curve_ids,
    source_dimension_names=dimensions,state_names=cols,
    embedding_dimension=m,delay_samples=lag,
    delay_time=if(is.finite(step))lag*step else NaN,
    time_unit=trajectories$time_unit,
    coordinate_system=trajectories$coordinate_system,
    provenance=list(operation="delay_embed_trajectory",
      source_provenance=trajectories$provenance,
      dimensions=dimensions,embedding_dimension=m,delay_samples=lag,
      requested_delay=delay,requested_delay_units=delay_units,
      constant_delay_time=is.finite(step),
      automatic_parameter_selection=FALSE,scaling="none")),
    class="etr_delay_embedding_set")
}
.etr_nonlinear_state <- function(embedding,curve,theiler_window,max_horizon,
                        theiler_window_units,max_horizon_units){
  .etr_nonlinear_embedding(embedding)
  th<-.etr_source_time_unit_samples(embedding$time,
    theiler_window,theiler_window_units,embedding$time_unit,
    "theiler_window",allow_zero=TRUE)
  horizon<-.etr_source_time_unit_samples(embedding$time,
    max_horizon,max_horizon_units,embedding$time_unit,
    "max_horizon",allow_zero=TRUE)
  .etr_assert(horizon>=1L,
    "max_horizon must be at least one sample")
  i<-.etr_nonlinear_curve(embedding$curve_ids,curve)
  n<-length(embedding$time)
  .etr_assert(horizon<n,"max_horizon must be smaller than state count")
  .etr_assert(n<=1600L,"exact nearest-neighbor divergence is capped at 1600 states")
  step<-.etr_series_regular_spacing(embedding$time)
  states<-matrix(embedding$values[i,,,drop=FALSE],
    nrow=n,ncol=dim(embedding$values)[3L])
  list(states=states,n=n,theiler=th,horizon=horizon,
    curve_id=embedding$curve_ids[i],step=step)
}

#' Rosenstein nearest-neighbor mean log divergence by observed horizon
#' @param embedding Complete native delay-coordinate result.
#' @param curve Zero-based curve index or exact ID.
#' @param theiler_window Minimum temporal neighbor exclusion in samples.
#' @param max_horizon Positive observed sample horizon.
#' @param theiler_window_units,max_horizon_units Observed sample or
#'   physical-time units; non-sample units require a regular embedded grid.
#' @export
etr_local_divergence_curve <- function(embedding,curve,
    theiler_window,max_horizon,theiler_window_units="samples",
    max_horizon_units="samples"){
  z<-.etr_nonlinear_state(embedding,curve,theiler_window,max_horizon,
    theiler_window_units,max_horizon_units)
  n<-z$n;st<-z$states;nd<-ncol(st)
  nn<-integer(n)
  for(i in seq_len(n)){
    d<-sqrt(rowSums((st-matrix(st[i,],n,nd,byrow=TRUE))^2))
    good<-which(seq_len(n)!=i&abs(seq_len(n)-i)>z$theiler&
                  is.finite(d)&d>0)
    .etr_assert(length(good)>0L,
      "no positive-distance temporally separated nearest neighbor")
    nn[i]<-good[which.min(d[good])]
  }
  horizons<-0:z$horizon
  averages<-rep(NaN,length(horizons))
  pairs<-zeros<-integer(length(horizons))
  for(k in horizons){
    ref<-which(seq_len(n)+k<=n & nn+k<=n)
    if(!length(ref))next
    dist<-sqrt(rowSums((st[ref+k,,drop=FALSE]-
      st[nn[ref]+k,,drop=FALSE])^2))
    zeros[k+1L]<-sum(dist<=0)
    pos<-dist[dist>0]
    pairs[k+1L]<-length(pos)
    if(length(pos))averages[k+1L]<-mean(log(pos))
  }
  structure(list(horizons=as.integer(horizons),
    time_lags=as.numeric(horizons*z$step),
    mean_log_divergence=averages,pair_counts=pairs,
    zero_distance_counts=zeros,
    nearest_neighbor_indices=as.integer(nn-1L),
    theiler_window_samples=z$theiler,max_horizon_samples=z$horizon,
    curve_id=z$curve_id,time_unit=embedding$time_unit,
    provenance=list(operation="local_divergence_curve",
      estimator_family="Rosenstein nearest-neighbor divergence",
      zero_distance_policy="excluded_from_log_and_counted_explicitly",
      nearest_neighbor_ties="smallest_source_index_in_native_R",
      automatic_fit_interval_selection=FALSE)),
    class="etr_local_divergence")
}

#' Fixed-radius Kantz neighborhood mean-log-divergence curve
#' @param radius Positive fixed radius in embedded-state Euclidean geometry.
#' @param min_neighbors Minimum surviving neighbors per reference state.
#' @inheritParams etr_local_divergence_curve
#' @export
etr_kantz_divergence_curve <- function(embedding,curve,radius,
    theiler_window,max_horizon,min_neighbors=2L,
    theiler_window_units="samples",max_horizon_units="samples"){
  .etr_assert(is.numeric(radius)&&length(radius)==1L&&
    is.finite(radius)&&radius>0,"radius must be positive and finite")
  minimum<-.etr_nonlinear_integer(min_neighbors,1L,"min_neighbors")
  z<-.etr_nonlinear_state(embedding,curve,theiler_window,max_horizon,
    theiler_window_units,max_horizon_units)
  n<-z$n;st<-z$states;nd<-ncol(st)
  neighbors<-vector("list",n);initial<-integer(n)
  for(i in seq_len(n)){
    dist<-sqrt(rowSums((st-matrix(st[i,],n,nd,byrow=TRUE))^2))
    neighbors[[i]]<-which(seq_len(n)!=i &
      abs(seq_len(n)-i)>z$theiler & dist<=radius)
    initial[i]<-length(neighbors[[i]])
  }
  horizons<-0:z$horizon
  means<-rep(NaN,length(horizons))
  references<-pairs<-zeros<-integer(length(horizons))
  for(k in horizons){
    logref<-numeric()
    for(i in seq_len(n)){
      if(i+k>n)next
      ids<-neighbors[[i]]
      ids<-ids[ids+k<=n]
      if(length(ids)<minimum)next
      d<-sqrt(rowSums((st[ids+k,,drop=FALSE]-
        matrix(st[i+k,],length(ids),nd,byrow=TRUE))^2))
      pairs[k+1L]<-pairs[k+1L]+length(d)
      avg<-mean(d)
      if(avg<=0){zeros[k+1L]<-zeros[k+1L]+1L;next}
      logref<-c(logref,log(avg))
    }
    references[k+1L]<-length(logref)
    if(length(logref))means[k+1L]<-mean(logref)
  }
  .etr_assert(references[1L]>0L,
    "no reference has declared minimum neighbors inside radius")
  structure(list(horizons=as.integer(horizons),
    time_lags=as.numeric(horizons*z$step),
    mean_log_divergence=means,reference_counts=references,
    pair_counts=pairs,zero_mean_neighborhood_counts=zeros,
    initial_neighbor_counts=initial,radius=radius,min_neighbors=minimum,
    theiler_window_samples=z$theiler,max_horizon_samples=z$horizon,
    curve_id=z$curve_id,time_unit=embedding$time_unit,
    provenance=list(operation="kantz_divergence_curve",
      estimator_family="Kantz fixed-radius neighborhood divergence",
      radius=radius,min_neighbors=minimum,
      neighborhood_expansion_policy="none_fail_or_skip_reference",
      automatic_fit_interval_selection=FALSE)),
    class="etr_kantz_divergence")
}

.etr_nonlinear_lyapunov <- function(divergence,kind,fit_start,fit_end,fit_units){
  .etr_assert(inherits(divergence,kind),
    paste("divergence must be",kind))
  .etr_assert(identical(fit_units,"samples"),
    "time-based Lyapunov fit windows are not yet qualified; use samples")
  first<-.etr_nonlinear_integer(fit_start,0L,"fit_start")
  last<-.etr_nonlinear_integer(fit_end,1L,"fit_end")
  .etr_assert(last>first&&last<=divergence$max_horizon_samples,
    "fit_end must exceed fit_start and remain within computed horizon")
  ids<-which(divergence$horizons>=first&
    divergence$horizons<=last&
    is.finite(divergence$mean_log_divergence)&
    (if(identical(kind,"etr_local_divergence"))
      divergence$pair_counts>0 else divergence$reference_counts>0))
  .etr_assert(length(ids)>=3L,
    "declared fit interval contains fewer than three finite divergence points")
  factor<-switch(tolower(divergence$time_unit),
    "s"=1,"sec"=1,"second"=1,"seconds"=1,
    "ms"=.001,"millisecond"=.001,"milliseconds"=.001,NA_real_)
  x<-divergence$time_lags[ids]*
    if(is.finite(factor))factor else 1
  y<-divergence$mean_log_divergence[ids]
  .etr_assert(stats::sd(x)>0,
    "declared fit segment has constant time values")
  fit<-stats::lm(y~x)
  coef<-stats::coef(fit);summary<-summary(fit)
  structure(list(exponent=as.numeric(coef[2L]),
    exponent_unit=if(is.finite(factor))"1/s" else
      paste0("1/",divergence$time_unit),
    intercept=as.numeric(coef[1L]),
    r_squared=as.numeric(summary$r.squared),
    standard_error=as.numeric(summary$coefficients[2L,2L]),
    fit_start=divergence$time_lags[first+1L],
    fit_end=divergence$time_lags[last+1L],
    n_fit_points=length(ids),divergence=divergence,
    provenance=list(operation=if(identical(kind,"etr_local_divergence"))
      "estimate_largest_lyapunov_rosenstein" else
      "estimate_largest_lyapunov_kantz",
      fit_start_samples=first,fit_end_samples=last,
      fit_interval_selected_automatically=FALSE,
      interpretation_boundary=paste("Local-divergence slope is not",
        "standalone evidence of deterministic chaos"))),
    class="etr_largest_lyapunov")
}
#' Fit explicitly declared Rosenstein local-divergence segment
#' @param divergence Native Rosenstein local-divergence result.
#' @param fit_start,fit_end Explicit zero-based sample-index horizon endpoints.
#' @param fit_units Only "samples" currently supported.
#' @export
etr_estimate_largest_lyapunov_rosenstein <- function(divergence,
    fit_start,fit_end,fit_units="samples"){
  .etr_nonlinear_lyapunov(divergence,"etr_local_divergence",
    fit_start,fit_end,fit_units)
}
#' Fit explicitly declared Kantz local-divergence segment
#' @inheritParams etr_estimate_largest_lyapunov_rosenstein
#' @export
etr_estimate_largest_lyapunov_kantz <- function(divergence,
    fit_start,fit_end,fit_units="samples"){
  .etr_nonlinear_lyapunov(divergence,"etr_kantz_divergence",
    fit_start,fit_end,fit_units)
}
