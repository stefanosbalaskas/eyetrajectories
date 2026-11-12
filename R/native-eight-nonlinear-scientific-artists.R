# Frozen Python 1.2.0 src/eyetrajectoriespy/nonlinear_plotting.py
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
# These are source-scientific Matplotlib coordinates, NOT Python Axes.
# Every function consumes precomputed native inference; no model refit.

.etr_nonlinear_artist_record <- function(name,axes,options=list()) {
  .etr_assert(is.character(name)&&length(name)==1L&&
    is.list(axes)&&length(axes)>=1L&&
    all(vapply(axes,function(ax)is.list(ax)&&is.list(ax$artists)&&
      is.character(ax$xlabel)&&length(ax$xlabel)==1L&&
      is.character(ax$ylabel)&&length(ax$ylabel)==1L,
      logical(1L))),
    "source nonlinear artist requires valid axes and artist arrays")
  structure(list(source_export=name,
    renderer="native_R_base_graphics",
    python_return_kind="matplotlib.axes.Axes",
    panel_layout=c(1L,1L),axes=axes,source_options=options,
    matplotlib_object_identity=FALSE,
    source_scientific_geometry_reviewed=TRUE,
    independently_certified=FALSE),
    class=c("etr_nonlinear_scientific_artist_record","list"))
}

.etr_nonlinear_delay_artists <- function(result,geometry) {
  x<-as.numeric(geometry$time)
  mark<-as.integer(geometry$first_ami_local_minimum_indices)+1L
  main<-list(title=sprintf("Embedding-delay diagnostics: %s / %s",
    result$curve_id,result$dimension),
    xlabel=sprintf("Lag (%s)",result$time_unit),
    ylabel="Average mutual information",legend=FALSE,
    artists=list(list(kind="line",label="AMI",
      marker="o",linestyle="-",xdata=x,ydata=as.numeric(geometry$ami))))
  secondary<-list(title="",xlabel="",ylabel="Autocorrelation",
    twinx_of=1L,legend=FALSE,
    artists=list(list(kind="line",label="ACF",
      marker="None",linestyle="--",
      xdata=x,ydata=as.numeric(geometry$autocorrelation))))
  if(length(mark)>0L)
    main$artists[[length(main$artists)+1L]]<-list(
      kind="scatter",label="First AMI local minimum",
      marker="x",size=70,
      offsets=unname(cbind(x[mark],as.numeric(geometry$ami[mark]))))
  .etr_nonlinear_artist_record("plot_embedding_delay_diagnostics",
    list(main,secondary),list(first_ami_local_minimum_indices=
      as.integer(geometry$first_ami_local_minimum_indices)))
}

.etr_nonlinear_dimension_artists <- function(result,frame) {
  axis<-list(title=sprintf("FNN diagnostics: %s / %s",
      result$curve_id,result$dimension),
    xlabel="Embedding dimension",ylabel="False-nearest-neighbor fraction",
    ylim_lower=0,legend=FALSE,
    artists=list(list(kind="line",marker="o",linestyle="-",
      xdata=as.numeric(frame$embedding_dimension),
      ydata=as.numeric(frame$false_neighbor_fraction))))
  .etr_nonlinear_artist_record("plot_embedding_dimension_diagnostics",
    list(axis))
}

.etr_nonlinear_degree_artists <- function(result,frame,normalized) {
  axis<-list(title=sprintf("Recurrence-network degree (density=%.3f)",
    result$graph_density),xlabel="State index",
    ylabel=if(normalized)"Normalized degree" else "Degree",
    legend=FALSE,
    artists=list(list(kind="line",marker="None",linestyle="-",
      xdata=as.numeric(frame$state_index),
      ydata=as.numeric(frame$degree))))
  .etr_nonlinear_artist_record("plot_recurrence_network_degree",
    list(axis),list(normalized=normalized))
}

.etr_nonlinear_radius_artists <- function(result,frame) {
  axis<-list(title=sprintf("Recurrence radius profile: %s",
      result$curve_id),
    xlabel=sprintf("Radius (%s state-space distance)",result$metric),
    ylabel="Recurrence rate",ylim=c(0,1),legend=FALSE,
    artists=list(list(kind="line",marker="o",linestyle="-",
      xdata=as.numeric(frame$radius),
      ydata=as.numeric(frame$recurrence_rate))))
  .etr_nonlinear_artist_record("plot_recurrence_rate_curve",list(axis))
}

.etr_nonlinear_windowed_artists <- function(result,frame,metrics) {
  artists<-lapply(metrics,function(metric)
    list(kind="line",marker="o",linestyle="-",label=metric,
      xdata=as.numeric(frame$center_time),
      ydata=as.numeric(frame[[metric]])))
  axis<-list(title="Windowed recurrence dynamics",
    xlabel=sprintf("Window center (%s)",result$time_unit),
    ylabel="RQA metric",legend=TRUE,
    legend_labels=as.character(metrics),artists=artists)
  .etr_nonlinear_artist_record("plot_windowed_rqa",list(axis),
    options=list(metrics=as.character(metrics)))
}

.etr_nonlinear_divergence_artists <- function(result,frame) {
  fitted<-inherits(result,"etr_largest_lyapunov")
  d<-if(fitted)result$divergence else result
  family<-d$provenance$estimator_family
  if(is.null(family))family<-"local divergence"
  .etr_assert(is.character(family)&&length(family)==1L&&
    !is.na(family)&&is.character(d$curve_id)&&length(d$curve_id)==1L,
    "source divergence family and curve identifiers must be strings")
  artists<-list(list(kind="line",marker="o",linestyle="-",
    label="Mean log divergence",
    xdata=as.numeric(frame$time_lag),
    ydata=as.numeric(frame$mean_log_divergence)))
  if(fitted) {
    ok<-which(is.finite(frame$fit))
    artists[[2L]]<-list(kind="line",marker="None",
      linestyle="--",
      label=sprintf("LLE fit: %.3g %s",
        result$exponent,result$exponent_unit),
      xdata=as.numeric(frame$time_lag[ok]),
      ydata=as.numeric(frame$fit[ok]))
  }
  axis<-list(title=sprintf("%s: %s",family,d$curve_id),
    xlabel=sprintf("Divergence lag (%s)",d$time_unit),
    ylabel="Mean log distance",legend=TRUE,
    legend_labels=vapply(artists,function(x)x$label,character(1L)),
    artists=artists)
  .etr_nonlinear_artist_record("plot_local_divergence",list(axis),
    options=list(largest_lyapunov_fit=fitted))
}

.etr_nonlinear_surrogate_artists <- function(result,geometry) {
  .etr_assert(is.list(geometry)&&
    is.numeric(geometry$breaks)&&is.numeric(geometry$counts)&&
    length(geometry$breaks)==length(geometry$counts)+1L&&
    length(geometry$counts)>=2L&&
    all(is.finite(geometry$breaks))&&
    all(is.finite(geometry$counts))&&
    all(geometry$counts>=0)&&
    is.numeric(geometry$observed)&&length(geometry$observed)==1L&&
    is.finite(geometry$observed),
    "source surrogate histogram requires ordered finite bin counts")
  lo<-geometry$breaks[-length(geometry$breaks)]
  hi<-geometry$breaks[-1L]
  axis<-list(
    title=sprintf("%s surrogate test (p=%.3g)",
      toupper(result$method),result$p_value),
    xlabel=result$statistic,ylabel="Surrogate count",legend=TRUE,
    legend_labels="Observed",
    artists=list(
      list(kind="histogram",alpha=.7,
        edges=as.numeric(geometry$breaks),
        lower=as.numeric(lo),upper=as.numeric(hi),
        counts=as.numeric(geometry$counts)),
      list(kind="vertical_reference",label="Observed",
        linestyle="--",y_transform="axes_fraction",
        xdata=rep(as.numeric(geometry$observed),2L),
        ydata=c(0,1))))
  .etr_nonlinear_artist_record("plot_surrogate_nonlinearity",
    list(axis),options=list(
      source_equal_width_histogram=TRUE,
      n_bins=length(geometry$counts)))
}

.etr_nonlinear_return_artists <- function(crossings,out) {
  .etr_assert(is.data.frame(out)&&nrow(out)>=1L&&
    all(c("current","next_state")%in%names(out))&&
    all(is.finite(out$current))&&all(is.finite(out$next_state)),
    "source Poincare return map needs finite consecutive states")
  lo<-min(c(out$current,out$next_state))
  hi<-max(c(out$current,out$next_state))
  artists<-list(
    list(kind="scatter",label="Successive crossings",marker="o",
      offsets=unname(cbind(as.numeric(out$current),
        as.numeric(out$next_state)))),
    list(kind="line",label="Identity",marker="None",
      linestyle=":",xdata=c(lo,hi),ydata=c(lo,hi)))
  curve<-attr(out,"fit_curve")
  if(!is.null(curve)){
    .etr_assert(is.data.frame(curve)&&
      all(c("x","y")%in%names(curve))&&nrow(curve)==100L&&
      all(is.finite(as.matrix(curve[c("x","y")]))),
      "source Poincare affine fit requires 100 finite interpolation points")
    artists[[3L]]<-list(kind="line",
      label="Local affine fit",marker="None",linestyle="--",
      xdata=as.numeric(curve$x),ydata=as.numeric(curve$y))
  }
  axis<-list(title="Empirical Poincare return map",
    xlabel=sprintf("%s at crossing n",crossings$state_dimensions[1L]),
    ylabel=sprintf("%s at crossing n+1",crossings$state_dimensions[1L]),
    legend=TRUE,
    legend_labels=vapply(artists,function(x)x$label,character(1L)),
    artists=artists)
  .etr_nonlinear_artist_record("plot_poincare_return_map",
    list(axis),options=list(has_local_affine_fit=!is.null(curve)))
}
