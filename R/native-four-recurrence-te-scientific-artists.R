# Frozen eyetrajectoriespy 1.2.0 scientific Matplotlib source artist geometry.
# Oracle commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Native R source artist records; NEVER Python Axes object identity.
#
# These functions do not run estimation, resampling or reconstruction.

.etr_joint_recurrence_source_artist <- function(result,geometry,max_points) {
  .etr_assert(is.data.frame(geometry)&&
    identical(names(geometry),c("col_index","row_index"))&&
    all(is.finite(as.matrix(geometry))),
    "joint recurrence scientific artist requires finite sparse coordinates")
  # scipy.sparse CSR.tocoo() emits row-major source coordinates.
  # Native base R which(..., arr.ind=TRUE) emits column-major indices.
  if(nrow(geometry)>0L)
    geometry<-geometry[order(geometry$row_index,
      geometry$col_index),,drop=FALSE]
  offsets<-unname(cbind(as.numeric(geometry$col_index),
    as.numeric(geometry$row_index)))
  n<-nrow(result$matrix)
  ax<-list(
    title=sprintf("Joint recurrence (JRR=%.3f, components=%d)",
      result$joint_recurrence_rate,length(result$component_labels)),
    xlabel="State index",ylabel="State index",
    inverted_yaxis=TRUE,aspect="equal",adjustable="box",
    legend=FALSE,legend_labels=character(0),
    artists=list(list(kind="scatter",marker="s",
      size=4,offsets=offsets)))
  .etr_nonlinear_artist_record("plot_joint_recurrence",list(ax),
    options=list(n_states=n,n_sparse_points=nrow(offsets),
      max_points=max_points,source_coo_order="row_major"))
}

.etr_windowed_rqa_trajectories_source_artist <- function(result,metric,
    geometry,show_mean,max_curves) {
  .etr_assert(is.list(geometry)&&is.numeric(geometry$time)&&
    is.matrix(geometry$curve_values)&&
    length(geometry$time)==ncol(geometry$curve_values)&&
    nrow(geometry$curve_values)>=1L&&
    all(is.finite(geometry$time)),
    "windowed RQA source artist needs finite center times and curve matrix")
  n<-nrow(geometry$curve_values)
  artists<-lapply(seq_len(n),function(i)
    list(kind="line",marker="None",linestyle="-",alpha=.45,
      xdata=as.numeric(geometry$time),
      ydata=as.numeric(geometry$curve_values[i,])))
  if(isTRUE(show_mean)) {
    .etr_assert(is.numeric(geometry$across_curve_mean)&&
      length(geometry$across_curve_mean)==length(geometry$time),
      "windowed RQA mean artist needs full ensemble mean on source grid")
    artists[[n+1L]]<-list(kind="line",marker="None",
      linestyle="-",linewidth=2.2,label="Across-curve mean",
      xdata=as.numeric(geometry$time),
      ydata=as.numeric(geometry$across_curve_mean))
  }
  meta<-result$trajectories$provenance
  units<-if(is.list(meta)&&
      is.list(meta$metric_units)&&
      !is.null(meta$metric_units[[metric]]))
      meta$metric_units[[metric]] else "metric units"
  .etr_assert(is.character(units)&&length(units)==1L&&
    !is.na(units)&&nzchar(units),"RQA metric units must be a valid string")
  ax<-list(title=paste0("Functional windowed RQA: ",metric),
    xlabel=sprintf("Window center (%s)",result$time_unit),
    ylabel=paste0(metric," (",units,")"),
    legend=isTRUE(show_mean),
    legend_labels=if(isTRUE(show_mean))"Across-curve mean" else character(0),
    artists=artists)
  .etr_nonlinear_artist_record("plot_windowed_rqa_trajectories",
    list(ax),options=list(metric=metric,show_mean=isTRUE(show_mean),
      max_curves=max_curves,n_plotted_curves=n))
}

.etr_rqa_sensitivity_source_artist <- function(result,parameter,metric,frame) {
  .etr_assert(is.data.frame(frame)&&identical(names(frame),
    c(parameter,metric))&&nrow(frame)>0L&&
    is.numeric(frame[[parameter]])&&is.numeric(frame[[metric]])&&
    all(is.finite(frame[[parameter]]))&&
    all(is.finite(frame[[metric]])),
    "RQA scientific source artist requires finite uniquely selected slice")
  ax<-list(title=paste0("RQA parameter sensitivity: ",result$curve_id),
    xlabel=parameter,ylabel=metric,legend=FALSE,
    legend_labels=character(0),
    artists=list(list(kind="line",marker="o",
      linestyle="-",xdata=as.numeric(frame[[parameter]]),
      ydata=as.numeric(frame[[metric]]))))
  .etr_nonlinear_artist_record("plot_rqa_sensitivity",list(ax),
    options=list(parameter=parameter,metric=metric,n_points=nrow(frame)))
}

.etr_te_sensitivity_source_artist <- function(parameter,metric,frame) {
  .etr_assert(is.data.frame(frame)&&identical(names(frame),
    c(parameter,metric))&&nrow(frame)>0L&&
    all(is.finite(frame[[parameter]]))&&
    all(is.finite(frame[[metric]])),
    "transfer entropy scientific source artist requires a finite sensitivity slice")
  ax<-list(title="Transfer-entropy specification sensitivity",
    xlabel=gsub("_"," ",parameter),ylabel=gsub("_"," ",metric),
    legend=FALSE,legend_labels=character(0),
    artists=list(list(kind="line",marker="o",linestyle="-",
      xdata=as.numeric(frame[[parameter]]),
      ydata=as.numeric(frame[[metric]]))))
  .etr_nonlinear_artist_record("plot_transfer_entropy_sensitivity",
    list(ax),options=list(parameter=parameter,metric=metric,
      n_points=nrow(frame),causal_identification_claim=FALSE))
}
