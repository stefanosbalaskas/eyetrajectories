# Frozen eyetrajectoriespy==1.2.0 scientific Matplotlib artist geometry:
# src/eyetrajectoriespy/plotting.py, commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
#
# Strict records preserve scientific artist values and source labels; actual
# base-R plots cannot return Python Matplotlib Axes or pixel-equivalent renders.

.etr_fpca_uncertainty_strict <- function(value) {
  .etr_assert(is.logical(value) && length(value)==1L && !is.na(value),
    "strict_source_record must be a nonmissing logical scalar")
  invisible(TRUE)
}

.etr_fpca_uncertainty_scope <- function(result) {
  .etr_assert(is.character(result$simultaneous_scope) &&
    length(result$simultaneous_scope)==1L &&
    !is.na(result$simultaneous_scope) &&
    result$simultaneous_scope%in%c("family","component"),
    "source simultaneous_scope must be family or component")
  if(identical(result$simultaneous_scope,"family")) "familywise"
  else "component-wise"
}

.etr_fpca_uncertainty_record <- function(name,axis,options=list()) {
  .etr_assert(is.list(axis) && is.list(axis$artists) &&
    length(axis$artists)>=1L &&
    is.character(axis$title) && length(axis$title)==1L &&
    is.character(axis$xlabel) && length(axis$xlabel)==1L &&
    is.character(axis$ylabel) && length(axis$ylabel)==1L,
    "FPCA source artist geometry requires complete plot metadata")
  structure(list(
    source_export=name,
    renderer="native_R_base_graphics",
    python_return_kind="matplotlib.axes.Axes",
    panel_layout=c(1L,1L),
    axes=list(axis),
    source_options=options,
    matplotlib_object_identity=FALSE,
    source_scientific_geometry_reviewed=TRUE,
    independently_certified=FALSE),
    class=c("etr_fpca_uncertainty_artist_source_record","list"))
}

.etr_fpca_score_uncertainty_artist <- function(frame,component,max_targets) {
  .etr_assert(is.data.frame(frame) &&
    identical(names(frame),c("target_curve_id","median","lower",
      "upper","reference")) && nrow(frame)>0L &&
    all(is.finite(as.matrix(frame[c("median","lower","upper","reference")]))),
    "source FPCA score artist requires finite fixed-target scores")
  n<-nrow(frame)
  x<-as.numeric(seq_len(n)-1L)
  med<-as.numeric(frame$median)
  lower<-as.numeric(frame$lower)
  upper<-as.numeric(frame$upper)
  .etr_assert(all(lower<=med) && all(upper>=med),
    "source FPCA score bootstrap bounds must contain the median")
  axis<-list(
    title="Basis-resampling FPC score uncertainty",
    xlabel="Target trajectory",
    ylabel=sprintf("FPC%d score",as.integer(component)+1L),
    xticks=x,xticklabels=as.character(frame$target_curve_id),
    xtick_rotation=90,
    artists=list(
      list(kind="errorbar",label="bootstrap median + percentile envelope",
        marker="o",linestyle="none",capsize=3,
        xdata=x,ydata=med,
        yerr=rbind(med-lower,upper-med),
        lower=lower,upper=upper),
      list(kind="scatter",label="full-sample reference score",
        marker="x",
        offsets=unname(cbind(x,as.numeric(frame$reference)))),
      list(kind="horizontal_reference",label="_child_zero",
        linestyle="--",xdata=c(0,1),ydata=c(0,0),
        x_transform="axes_fraction")),
    legend=TRUE,
    legend_labels=c("full-sample reference score",
      "bootstrap median + percentile envelope"))
  .etr_fpca_uncertainty_record("plot_fpca_score_uncertainty",axis,
    options=list(component=as.integer(component),
      max_targets=as.integer(max_targets),n_plotted=n))
}

.etr_fpca_spectrum_uncertainty_artist <- function(result,metric,frame) {
  .etr_assert(is.data.frame(frame) &&
    identical(names(frame),c("component","estimate","lower","upper")) &&
    nrow(frame)>0L &&
    all(is.finite(as.matrix(frame))) &&
    all(frame$lower<=frame$estimate) &&
    all(frame$upper>=frame$estimate),
    "source FPCA spectrum artist requires finite component intervals")
  scope<-.etr_fpca_uncertainty_scope(result)
  ylabel<-switch(metric,
    eigenvalue="Eigenvalue",
    explained_variance_ratio="Explained variance ratio",
    cumulative_variance_ratio="Cumulative explained variance ratio")
  .etr_assert(is.character(ylabel)&&length(ylabel)==1L,
    "source spectrum metric must have an exact Python ylabel")
  x<-as.numeric(frame$component)
  y<-as.numeric(frame$estimate)
  axis<-list(
    title=sprintf("FPCA spectrum uncertainty (%s)",scope),
    xlabel="Functional principal component",
    ylabel=ylabel,
    xticks=x,
    artists=list(list(
      kind="errorbar",label="_nolegend_",marker="o",
      linestyle="-",capsize=3,
      xdata=x,ydata=y,
      yerr=rbind(y-as.numeric(frame$lower),
        as.numeric(frame$upper)-y),
      lower=as.numeric(frame$lower),
      upper=as.numeric(frame$upper))),
    legend=FALSE)
  .etr_fpca_uncertainty_record("plot_fpca_spectrum_uncertainty",axis,
    options=list(metric=metric,simultaneous_scope=result$simultaneous_scope))
}

.etr_fpca_component_band_artist <- function(result,component,
    dimension,frame) {
  .etr_assert(is.data.frame(frame) &&
    identical(names(frame),c("time","estimate","lower","upper")) &&
    nrow(frame)>=2L &&
    all(is.finite(as.matrix(frame))) &&
    all(frame$lower<=frame$estimate) &&
    all(frame$upper>=frame$estimate),
    "source FPCA FPC band artist requires complete observed-grid bounds")
  .etr_assert(is.numeric(result$confidence_level) &&
    length(result$confidence_level)==1L &&
    is.finite(result$confidence_level) &&
    result$confidence_level>0 && result$confidence_level<1,
    "source FPCA component-band confidence must lie between 0 and 1")
  scope<-.etr_fpca_uncertainty_scope(result)
  label<-sprintf("%.1f%% simultaneous band",
    100*as.numeric(result$confidence_level))
  axis<-list(
    title=sprintf("FPC%d simultaneous band (%s)",
      as.integer(component)+1L,scope),
    xlabel=sprintf("Time (%s)",result$reference$time_unit),
    ylabel=sprintf("FPC loading: %s",dimension),
    artists=list(
      list(kind="fill_between",label=label,
        xdata=as.numeric(frame$time),
        lower=as.numeric(frame$lower),
        upper=as.numeric(frame$upper),
        alpha=.2),
      list(kind="line",label="reference FPC",
        xdata=as.numeric(frame$time),
        ydata=as.numeric(frame$estimate))),
    legend=TRUE,
    legend_labels=c(label,"reference FPC"))
  .etr_fpca_uncertainty_record("plot_fpca_component_band",axis,
    options=list(component=as.integer(component),
      dimension=dimension,
      simultaneous_scope=result$simultaneous_scope,
      confidence_level=as.numeric(result$confidence_level)))
}
