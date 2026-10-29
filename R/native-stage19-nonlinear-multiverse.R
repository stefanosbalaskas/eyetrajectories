# Stage 19: independent native R specification multiverses,
# FPCA-score K-means, and distance-contract sensitivity.
# Published reference: eyetrajectoriespy==1.2.0 nonlinear_sensitivity.py,
# analysis.py, similarity_sensitivity.py.
# No automatic specification selection, chaos inference or Python bridge.

.etr19_grid <- function(x,name,minimum=0L,integer=TRUE,strict=FALSE) {
  .etr_assert(is.numeric(x)&&is.null(dim(x))&&length(x)>0L&&
    all(is.finite(x))&&all(x>=minimum)&&
    (!strict||all(x>minimum))&&
    (!integer||all(x==floor(x)))&&!anyDuplicated(x),
    paste(name,"must be distinct finite",if(integer)"integer" else "numeric",
      "values within the declared bounds"))
  if(integer)as.integer(x)else as.numeric(x)
}
.etr19_intervals <- function(x) {
  .etr_assert(is.list(x)&&length(x)>0L,
    "fit_intervals must be a nonempty list of declared start/end pairs")
  for(i in seq_along(x)){
    y<-x[[i]]
    .etr_assert(is.numeric(y)&&length(y)==2L&&all(is.finite(y))&&
      all(y==floor(y))&&y[1L]>=0&&y[2L]>y[1L],
      "each fit interval must be two ordered non-negative sample bounds")
  }
  names<-vapply(x,function(y)paste(y,collapse="|"),character(1L))
  .etr_assert(!anyDuplicated(names),"fit intervals must be distinct")
  lapply(x,as.integer)
}
.etr19_inputs <- function(x,curve,dimensions,delay_units,
  theiler_window_units,max_horizon_units=NULL,fit_units=NULL){
  etr_validate(x,require_complete=TRUE)
  .etr_assert(is.character(dimensions)&&length(dimensions)>0L&&
    !anyNA(dimensions)&&!anyDuplicated(dimensions)&&
    all(dimensions%in%x$dimension_names),
    "dimensions must be distinct, explicit existing channels")
  units<-c(delay_units,theiler_window_units,max_horizon_units,fit_units)
  .etr_assert(all(units=="samples"),
    "only sample-unit parameter sensitivity is qualified")
  .etr_nonlinear_curve(x$curve_ids,curve)
}
.etr19_summary <- function(tab,metrics,exponent=FALSE){
  rows<-vector("list",length(metrics))
  for(j in seq_along(metrics)){
    metric<-metrics[j];v<-as.numeric(tab[[metric]])
    good<-v[is.finite(v)]
    q<-if(length(good))as.numeric(stats::quantile(good,
      c(.25,.5,.75),names=FALSE,type=7L))else rep(NaN,3L)
    rows[[j]]<-data.frame(metric=metric,n_specifications=length(v),
      n_finite=length(good),finite_fraction=length(good)/length(v),
      minimum=if(length(good))min(good)else NaN,
      q25=q[1L],median=q[2L],q75=q[3L],
      maximum=if(length(good))max(good)else NaN,
      range=if(length(good))diff(range(good))else NaN,
      standard_deviation=if(length(good)>1L)stats::sd(good)else NaN,
      positive_fraction=if(exponent&&metric=="exponent"&&length(good))
        mean(good>0) else NaN)
  }
  do.call(rbind,rows)
}
.etr19_rowbind <- function(rows) {
  .etr_assert(length(rows)>0L,"parameter grid must not be empty")
  z<-do.call(rbind,rows);rownames(z)<-NULL
  z$specification_id<-sprintf("spec_%d",seq_len(nrow(z)))
  z[,c("specification_id",setdiff(names(z),"specification_id")),drop=FALSE]
}
.etr19_embed <- function(x,m,d,dimensions){
  tryCatch(etr_delay_embed_trajectory(x,embedding_dimension=m,
    delay=d,dimensions=dimensions),error=function(e)
      stop(sprintf("embedding_dimension=%d delay=%d: %s",
        m,d,conditionMessage(e)),call.=FALSE))
}

#' Complete declared Rosenstein divergence/linear-fit parameter multiverse
#' @param trajectories Native complete common-grid trajectories.
#' @param curve Source zero-based index or exact curve ID.
#' @param dimensions Explicit selected channels.
#' @param embedding_dimensions,delays,theiler_windows Distinct declared integer grids.
#' @param fit_intervals List of explicit c(start,end) sample intervals.
#' @param max_horizon Positive sample-index horizon.
#' @param delay_units,theiler_window_units,fit_units,max_horizon_units Only "samples".
#' @export
etr_lyapunov_parameter_sensitivity <- function(trajectories,curve,dimensions,
    embedding_dimensions,delays,theiler_windows,fit_intervals,max_horizon,
    delay_units="samples",theiler_window_units="samples",
    fit_units="samples",max_horizon_units="samples"){
  .etr19_inputs(trajectories,curve,dimensions,delay_units,
    theiler_window_units,max_horizon_units,fit_units)
  emb<-.etr19_grid(embedding_dimensions,"embedding_dimensions",2L)
  dl<-.etr19_grid(delays,"delays",1L)
  th<-.etr19_grid(theiler_windows,"theiler_windows",0L)
  intervals<-.etr19_intervals(fit_intervals)
  horizon<-.etr_nonlinear_integer(max_horizon,1L,"max_horizon")
  rows<-list()
  for(m in emb)for(d in dl){
    e<-.etr19_embed(trajectories,m,d,dimensions)
    for(tw in th){
      div<-tryCatch(etr_local_divergence_curve(e,curve,tw,horizon),
        error=function(e)stop(sprintf(
          "LLE divergence failed for m=%d delay=%d theiler=%d: %s",
          m,d,tw,conditionMessage(e)),call.=FALSE))
      for(pair in intervals){
        fit<-tryCatch(etr_estimate_largest_lyapunov_rosenstein(
          div,pair[1L],pair[2L]),error=function(e)
          stop(sprintf("LLE fit failed for m=%d delay=%d theiler=%d interval=%d:%d: %s",
            m,d,tw,pair[1L],pair[2L],conditionMessage(e)),call.=FALSE))
        ids<-which(div$horizons>=pair[1L]&div$horizons<=pair[2L])
        rows[[length(rows)+1L]]<-data.frame(
          embedding_dimension=m,requested_delay=as.numeric(d),
          delay_units="samples",delay_samples=d,delay_time=e$delay_time,
          requested_theiler_window=as.numeric(tw),
          theiler_window_units="samples",theiler_window_samples=tw,
          requested_fit_start=as.numeric(pair[1L]),
          requested_fit_end=as.numeric(pair[2L]),fit_units="samples",
          fit_start_samples=pair[1L],fit_end_samples=pair[2L],
          resolved_fit_start_time=fit$fit_start,
          resolved_fit_end_time=fit$fit_end,
          requested_max_horizon=as.numeric(horizon),
          max_horizon_units="samples",max_horizon_samples=horizon,
          exponent=fit$exponent,exponent_unit=fit$exponent_unit,
          r_squared=fit$r_squared,standard_error=fit$standard_error,
          intercept=fit$intercept,n_fit_points=fit$n_fit_points,
          minimum_pair_count_in_fit=min(div$pair_counts[ids]),
          total_zero_distance_count_in_fit=sum(div$zero_distance_counts[ids]))
      }
    }
  }
  tab<-.etr19_rowbind(rows)
  metrics<-c("exponent","r_squared","standard_error",
    "n_fit_points","minimum_pair_count_in_fit",
    "total_zero_distance_count_in_fit")
  structure(list(table=tab,summary_table=.etr19_summary(tab,metrics,TRUE),
    parameter_columns=c("embedding_dimension","requested_delay",
      "delay_samples","requested_theiler_window",
      "theiler_window_samples","requested_fit_start","requested_fit_end",
      "fit_start_samples","fit_end_samples"),
    curve_id=trajectories$curve_ids[.etr_nonlinear_curve(trajectories$curve_ids,curve)],
    exponent_unit=tab$exponent_unit[1L],
    provenance=list(operation="lyapunov_parameter_sensitivity",
      cartesian_product_evaluated=TRUE,n_specifications=nrow(tab),
      automatic_fit_interval_selection=FALSE,
      automatic_parameter_selection=FALSE,failed_specification_policy="error",
      positive_fraction_interpretation="descriptive_not_chaos_probability",
      source_contract="sample_units_only")),
    class="etr_lyapunov_parameter_sensitivity")
}

#' Complete fixed-radius Kantz sensitivity and declared slope intervals
#' @param radii Positive explicit fixed-neighborhood radius grid.
#' @param min_neighbors Positive neighborhood support grid.
#' @inheritParams etr_lyapunov_parameter_sensitivity
#' @export
etr_kantz_parameter_sensitivity <- function(trajectories,curve,dimensions,
    embedding_dimensions,delays,radii,min_neighbors,theiler_windows,
    fit_intervals,max_horizon,delay_units="samples",
    theiler_window_units="samples",fit_units="samples",
    max_horizon_units="samples"){
  .etr19_inputs(trajectories,curve,dimensions,delay_units,
    theiler_window_units,max_horizon_units,fit_units)
  emb<-.etr19_grid(embedding_dimensions,"embedding_dimensions",2L)
  dl<-.etr19_grid(delays,"delays",1L)
  rad<-.etr19_grid(radii,"radii",0L,FALSE,TRUE)
  neigh<-.etr19_grid(min_neighbors,"min_neighbors",1L)
  th<-.etr19_grid(theiler_windows,"theiler_windows",0L)
  intervals<-.etr19_intervals(fit_intervals)
  horizon<-.etr_nonlinear_integer(max_horizon,1L,"max_horizon")
  rows<-list()
  for(m in emb)for(d in dl){
    e<-.etr19_embed(trajectories,m,d,dimensions)
    for(radius in rad)for(minimum in neigh)for(tw in th){
      divergence<-tryCatch(etr_kantz_divergence_curve(
        e,curve,radius,tw,horizon,minimum),
        error=function(e)stop(sprintf(
          "Kantz divergence failed for m=%d delay=%d radius=%g neighbors=%d theiler=%d: %s",
          m,d,radius,minimum,tw,conditionMessage(e)),call.=FALSE))
      for(pair in intervals){
        fit<-tryCatch(etr_estimate_largest_lyapunov_kantz(
          divergence,pair[1L],pair[2L]),error=function(e)
          stop(sprintf(
            "Kantz fit failed for m=%d delay=%d radius=%g neighbors=%d theiler=%d interval=%d:%d: %s",
            m,d,radius,minimum,tw,pair[1L],pair[2L],conditionMessage(e)),
            call.=FALSE))
        ids<-which(divergence$horizons>=pair[1L]&
          divergence$horizons<=pair[2L])
        initial<-divergence$initial_neighbor_counts
        rows[[length(rows)+1L]]<-data.frame(
          embedding_dimension=m,requested_delay=as.numeric(d),
          delay_units="samples",delay_samples=d,delay_time=e$delay_time,
          requested_radius=radius,resolved_radius=divergence$radius,
          min_neighbors=minimum,
          requested_theiler_window=as.numeric(tw),
          theiler_window_units="samples",theiler_window_samples=tw,
          requested_fit_start=as.numeric(pair[1L]),
          requested_fit_end=as.numeric(pair[2L]),fit_units="samples",
          fit_start_samples=pair[1L],fit_end_samples=pair[2L],
          resolved_fit_start_time=fit$fit_start,
          resolved_fit_end_time=fit$fit_end,
          requested_max_horizon=as.numeric(horizon),
          max_horizon_units="samples",max_horizon_samples=horizon,
          exponent=fit$exponent,exponent_unit=fit$exponent_unit,
          r_squared=fit$r_squared,standard_error=fit$standard_error,
          intercept=fit$intercept,n_fit_points=fit$n_fit_points,
          minimum_reference_count_in_fit=min(divergence$reference_counts[ids]),
          minimum_pair_count_in_fit=min(divergence$pair_counts[ids]),
          total_zero_mean_neighborhood_count_in_fit=
            sum(divergence$zero_mean_neighborhood_counts[ids]),
          initial_neighbor_count_minimum=min(initial),
          initial_neighbor_count_median=stats::median(initial),
          initial_neighbor_count_maximum=max(initial),
          initial_supported_reference_fraction=mean(initial>=minimum))
      }
    }
  }
  tab<-.etr19_rowbind(rows)
  metrics<-c("exponent","r_squared","standard_error",
    "n_fit_points","minimum_reference_count_in_fit",
    "initial_supported_reference_fraction")
  structure(list(table=tab,summary_table=.etr19_summary(tab,metrics,TRUE),
    curve_id=trajectories$curve_ids[.etr_nonlinear_curve(trajectories$curve_ids,curve)],
    parameter_columns=c("embedding_dimension","requested_delay",
      "delay_samples","requested_radius","resolved_radius",
      "min_neighbors","requested_theiler_window",
      "theiler_window_samples","fit_start_samples","fit_end_samples"),
    exponent_unit=tab$exponent_unit[1L],
    provenance=list(operation="kantz_parameter_sensitivity",
      cartesian_product_evaluated=TRUE,n_specifications=nrow(tab),
      automatic_parameter_selection=FALSE,failed_specification_policy="error",
      interpretation="descriptive_multiverse_not_probability_of_chaos",
      neighborhood_radius_expansion=FALSE)),
    class="etr_kantz_parameter_sensitivity")
}

#' Declared fixed-radius RQA recurrence-parameter sensitivity
#' @param min_diagonal_lengths,min_vertical_lengths Positive integer RQA cutoff grids.
#' @param target_recurrence_rates Adaptive threshold grid unsupported; NULL required.
#' @param distance_metric Only Euclidean supported.
#' @inheritParams etr_kantz_parameter_sensitivity
#' @export
etr_rqa_parameter_sensitivity <- function(trajectories,curve,dimensions,
    embedding_dimensions,delays,theiler_windows,
    min_diagonal_lengths,min_vertical_lengths,
    radii=NULL,target_recurrence_rates=NULL,delay_units="samples",
    theiler_window_units="samples",distance_metric="euclidean"){
  .etr19_inputs(trajectories,curve,dimensions,delay_units,
    theiler_window_units)
  .etr_assert(identical(distance_metric,"euclidean"),
    "only Euclidean fixed-radius sensitivity is supported")
  .etr_assert(is.null(target_recurrence_rates)&&!is.null(radii),
    "adaptive target_recurrence_rates are unsupported; supply radii")
  emb<-.etr19_grid(embedding_dimensions,"embedding_dimensions",2L)
  dl<-.etr19_grid(delays,"delays",1L)
  th<-.etr19_grid(theiler_windows,"theiler_windows",0L)
  minD<-.etr19_grid(min_diagonal_lengths,"min_diagonal_lengths",1L)
  minV<-.etr19_grid(min_vertical_lengths,"min_vertical_lengths",1L)
  rad<-.etr19_grid(radii,"radii",0L,FALSE,TRUE)
  rows<-list()
  for(m in emb)for(d in dl){
    e<-.etr19_embed(trajectories,m,d,dimensions)
    data<-etr_trajectory_set(e$time,e$values,e$curve_ids,e$state_names,
      time_unit=e$time_unit,coordinate_system=e$coordinate_system)
    for(radius in rad)for(tw in th){
      rec<-tryCatch(etr_recurrence_matrix(data,
        curve=.etr_nonlinear_curve(data$curve_ids,curve),
        radius=radius,theiler=tw),
        error=function(e)stop(sprintf(
          "RQA sensitivity recurrence failed m=%d d=%d radius=%g theiler=%d: %s",
          m,d,radius,tw,conditionMessage(e)),call.=FALSE))
      for(diagCut in minD)for(vertCut in minV){
        metrics<-etr_rqa_metrics(rec,diagCut,vertCut)
        rows[[length(rows)+1L]]<-data.frame(
          embedding_dimension=m,requested_delay=as.numeric(d),
          delay_units="samples",delay_samples=d,delay_time=e$delay_time,
          threshold_policy="fixed_radius",requested_radius=radius,
          requested_target_recurrence_rate=NaN,
          resolved_radius=rec$radius,
          achieved_recurrence_rate=rec$recurrence_rate,
          requested_theiler_window=as.numeric(tw),
          theiler_window_units="samples",theiler_window_samples=tw,
          min_diagonal_length=diagCut,min_vertical_length=vertCut,
          distance_metric="euclidean",
          recurrence_rate=metrics$recurrence_rate,
          determinism=metrics$determinism,
          mean_diagonal_length=metrics$mean_diagonal_length,
          max_diagonal_length=metrics$max_diagonal_length,
          diagonal_entropy=metrics$diagonal_entropy,
          laminarity=metrics$laminarity,
          trapping_time=metrics$trapping_time,
          max_vertical_length=metrics$max_vertical_length,
          n_recurrence_points=metrics$n_recurrence_points,
          n_diagonal_lines=metrics$n_diagonal_lines,
          n_vertical_lines=metrics$n_vertical_lines)
      }
    }
  }
  tab<-.etr19_rowbind(rows)
  metrics<-c("recurrence_rate","determinism",
    "mean_diagonal_length","max_diagonal_length","diagonal_entropy",
    "laminarity","trapping_time","max_vertical_length")
  structure(list(table=tab,summary_table=.etr19_summary(tab,metrics),
    parameter_columns=c("embedding_dimension","requested_delay",
      "delay_samples","threshold_policy","requested_radius",
      "resolved_radius","requested_theiler_window","theiler_window_samples",
      "min_diagonal_length","min_vertical_length"),
    metric_columns=metrics,
    curve_id=trajectories$curve_ids[.etr_nonlinear_curve(trajectories$curve_ids,curve)],
    provenance=list(operation="rqa_parameter_sensitivity",
      threshold_policy="fixed_radius",distance_metric="euclidean",
      cartesian_product_evaluated=TRUE,n_specifications=nrow(tab),
      automatic_parameter_selection=FALSE,failed_specification_policy="error",
      summary_interpretation="descriptive_grid_not_sampling_distribution",
      unsupported_metric="center_of_recurrence_mass")),
    class="etr_rqa_parameter_sensitivity")
}
