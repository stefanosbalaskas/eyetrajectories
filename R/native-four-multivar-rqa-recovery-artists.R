# Frozen eyetrajectoriespy 1.2.0 scientific plotting artist records.
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Native R returns geometry, not a Python matplotlib.axes.Axes.

.etr_mv_iaaft_source_artist <- function(result,frame) {
  .etr_assert(is.data.frame(frame)&&nrow(frame)>=1L&&
    all(c("surrogate","max_spectral_error",
      "max_cross_spectral_error")%in%names(frame))&&
    all(is.finite(frame$surrogate))&&
    all(is.finite(frame$max_spectral_error))&&
    all(is.finite(frame$max_cross_spectral_error)),
    "source multivariate IAAFT plot requires finite nonempty diagnostics")
  labels<-c("Max power-spectrum error","Max cross-spectrum error")
  artists<-list(
    list(kind="line",marker="o",linestyle="-",
      label=labels[1L],xdata=as.numeric(frame$surrogate),
      ydata=as.numeric(frame$max_spectral_error)),
    list(kind="line",marker="o",linestyle="-",
      label=labels[2L],xdata=as.numeric(frame$surrogate),
      ydata=as.numeric(frame$max_cross_spectral_error)))
  ax<-list(title=paste0("Multivariate IAAFT preservation diagnostics: ",
      result$reference_dimension," reference"),
    xlabel="Surrogate index",ylabel="Relative mismatch",
    artists=artists,legend=TRUE,legend_labels=labels)
  .etr_nonlinear_artist_record("plot_multivariate_iaaft_diagnostics",
    list(ax),options=list(n_surrogates=nrow(frame),
      source_max_across_spectral_dimensions=TRUE))
}

.etr_mv_surrogate_source_artist <- function(data,statistic) {
  .etr_assert(is.list(data)&&inherits(data$histogram,"histogram")&&
    is.numeric(data$observed_statistic)&&
    length(data$observed_statistic)==1L&&
    is.finite(data$observed_statistic)&&
    is.numeric(data$p_value)&&length(data$p_value)==1L&&
    is.finite(data$p_value)&&data$p_value>=0&&data$p_value<=1,
    "source multivariate surrogate plot requires finite source histogram")
  h<-data$histogram
  .etr_assert(length(h$breaks)==length(h$counts)+1L&&
    length(h$counts)>=2L&&
    all(is.finite(h$breaks))&&all(diff(h$breaks)>0)&&
    all(is.finite(h$counts))&&all(h$counts>=0),
    "source surrogate histogram requires positive ordered NumPy bins")
  artists<-list(
    list(kind="histogram",alpha=.7,
      edges=as.numeric(h$breaks),counts=as.numeric(h$counts),
      lower=as.numeric(h$breaks[-length(h$breaks)]),
      upper=as.numeric(h$breaks[-1L])),
    list(kind="vertical_reference",
      label="Observed",linestyle="--",
      xdata=rep(as.numeric(data$observed_statistic),2L),
      ydata=c(0,1),x_transform="data",y_transform="axes_fraction"))
  ax<-list(title=paste0("Multivariate IAAFT surrogate test (p=",
      sprintf("%.3g",data$p_value),")"),
    xlabel=statistic,ylabel="Surrogate count",
    artists=artists,legend=TRUE,legend_labels="Observed")
  .etr_nonlinear_artist_record("plot_multivariate_surrogate_nonlinearity",
    list(ax),options=list(n_bins=length(h$counts),
      numpylike_exact_bin_counting=TRUE))
}

.etr_rqa_mean_bootstrap_source_artist <- function(result,metrics,frame) {
  .etr_assert(is.character(metrics)&&length(metrics)>=1L&&
    is.data.frame(frame)&&nrow(frame)==length(metrics)&&
    all(c("metric","mean","lower","upper")%in%names(frame))&&
    identical(as.character(frame$metric),as.character(metrics))&&
    all(is.finite(as.matrix(frame[c("mean","lower","upper")])))&&
    all(frame$lower<=frame$mean&frame$mean<=frame$upper),
    "source RQA bootstrap artist requires finite ordered percentile intervals")
  x<-seq_along(metrics)-1L
  y<-as.numeric(frame$mean);lower<-as.numeric(frame$lower)
  upper<-as.numeric(frame$upper)
  axis<-list(title=sprintf("RQA population mean (%s-level bootstrap)",
      result$unit),xlabel="",ylabel="RQA metric",
    xticks=as.numeric(x),xticklabels=as.character(metrics),
    tick_rotation=30,tick_horizontal_alignment="right",
    artists=list(list(kind="errorbar",marker="o",
      linestyle="None",capsize=4,
      xdata=as.numeric(x),ydata=y,
      yerr=rbind(y-lower,upper-y),
      lower=lower,upper=upper)),
    legend=FALSE,legend_labels=character(0))
  .etr_nonlinear_artist_record("plot_rqa_metric_mean_bootstrap",
    list(axis),options=list(n_metrics=length(metrics),
      percentile_bootstrap=TRUE))
}

.etr_recovery_source_artist <- function(geometry,metric,statistic) {
  .etr_assert(is.data.frame(geometry)&&
    all(c("label","x","estimate","lower","upper")%in%names(geometry))&&
    nrow(geometry)>=1L&&
    is.numeric(geometry$estimate)&&
    all(is.finite(geometry$estimate)),
    "recovery summary source artist requires finite statistics")
  has_band<-identical(statistic,"median")&&
    all(is.finite(geometry$lower))&&
    all(is.finite(geometry$upper))
  x<-as.numeric(geometry$x);y<-as.numeric(geometry$estimate)
  artist<-if(has_band)
    list(kind="errorbar",marker="o",linestyle="None",
      capsize=3,xdata=x,ydata=y,
      yerr=rbind(y-as.numeric(geometry$lower),
        as.numeric(geometry$upper)-y),
      lower=as.numeric(geometry$lower),
      upper=as.numeric(geometry$upper)) else
    list(kind="line",marker="o",linestyle="None",
      xdata=x,ydata=y)
  ax<-list(title=gsub("_"," ",metric,fixed=TRUE),
    xlabel="",ylabel=gsub("_"," ",statistic,fixed=TRUE),
    xticks=x,xticklabels=as.character(geometry$label),
    tick_rotation=45,tick_horizontal_alignment="right",
    tight_layout=TRUE,legend=FALSE,
    legend_labels=character(0),artists=list(artist))
  .etr_nonlinear_artist_record("plot_functional_recovery_summary",
    list(ax),options=list(metric=metric,statistic=statistic,
      has_interquartile_errorbars=has_band,
      descriptive_not_pass_fail=TRUE))
}
