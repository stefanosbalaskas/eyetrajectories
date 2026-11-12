# Frozen eyetrajectoriespy==1.2.0 scientific Matplotlib artist geometry.
# src/eyetrajectoriespy/plotting.py, c1cd95ad718327550f7e55393ff38582872f7a94.
# Read-only scientific coordinates/labels, NOT a live Python Axes or rendering parity.

.etr_fpca_inference_artist_record <- function(name, axis, options=list()) {
  .etr_assert(is.character(name)&&length(name)==1L&&
    is.list(axis)&&is.list(axis$artists)&&length(axis$artists)>=2L&&
    is.character(axis$title)&&length(axis$title)==1L&&
    is.character(axis$xlabel)&&length(axis$xlabel)==1L&&
    is.character(axis$ylabel)&&length(axis$ylabel)==1L,
    "scientific artist source record requires valid plot metadata")
  structure(list(source_export=name,
    renderer="native_R_base_graphics",
    python_return_kind="matplotlib.axes.Axes",
    panel_layout=c(1L,1L),axes=list(axis),source_options=options,
    matplotlib_object_identity=FALSE,
    source_scientific_geometry_reviewed=TRUE,
    independently_certified=FALSE),
    class=c("etr_fpca_inference_artist_source_record","list"))
}

.etr_fpca_component_envelope_artist <- function(frame,component,dimension,
    level,unit) {
  .etr_assert(is.data.frame(frame)&&nrow(frame)>=2L&&
    identical(names(frame),c("time","lower","median","upper","reference"))&&
    all(is.finite(as.matrix(frame)))&&
    all(frame$lower<=frame$median)&all(frame$median<=frame$upper)&&
    is.numeric(level)&&length(level)==1L&&is.finite(level)&&
    level>0&&level<1,
    "matched FPCA pointwise envelope requires ordered finite data")
  band_label<-sprintf("%.0f%% pointwise envelope",100*level)
  axis<-list(
    title=sprintf("FPC%d matched-bootstrap envelope",as.integer(component)+1L),
    xlabel=sprintf("Time (%s)",unit),
    ylabel=sprintf("FPC loading: %s",dimension),
    artists=list(
      list(kind="fill_between",label=band_label,alpha=.2,
        xdata=as.numeric(frame$time),lower=as.numeric(frame$lower),
        upper=as.numeric(frame$upper)),
      list(kind="line",label="bootstrap median",linestyle="--",
        xdata=as.numeric(frame$time),ydata=as.numeric(frame$median)),
      list(kind="line",label="reference FPC",linestyle="-",
        xdata=as.numeric(frame$time),ydata=as.numeric(frame$reference))),
    legend=TRUE,
    legend_labels=c(band_label,"bootstrap median","reference FPC"))
  .etr_fpca_inference_artist_record("plot_fpca_component_envelope",axis,
    options=list(component=as.integer(component),dimension=dimension,
      level=as.numeric(level)))
}

.etr_fpca_wild_projection_artist <- function(frame,max_targets) {
  .etr_assert(is.data.frame(frame)&&nrow(frame)>=1L&&
    identical(names(frame),c("x","curve_id","center","lower","upper"))&&
    all(is.finite(as.matrix(frame[c("x","center","lower","upper")])))&&
    all(frame$lower<=frame$center)&all(frame$center<=frame$upper),
    "wild-bootstrap projection needs finite centered intervals")
  x<-as.numeric(frame$x);center<-as.numeric(frame$center)
  axis<-list(
    title="Heteroscedastic Gaussian FPCR projection inference",
    xlabel="Fixed target trajectory",ylabel="Centered FPCR projection",
    xticks=x,xticklabels=as.character(frame$curve_id),xtick_rotation=90,
    artists=list(
      list(kind="errorbar",label="studentized wild-bootstrap interval",
        marker="o",linestyle="none",capsize=3,
        xdata=x,ydata=center,
        yerr=rbind(center-as.numeric(frame$lower),
          as.numeric(frame$upper)-center),
        lower=as.numeric(frame$lower),upper=as.numeric(frame$upper)),
      list(kind="horizontal_reference",label="_child_zero",
        xdata=c(0,1),ydata=c(0,0),x_transform="axes_fraction",
        linestyle="--")),
    legend=TRUE,legend_labels="studentized wild-bootstrap interval")
  .etr_fpca_inference_artist_record("plot_fpca_wild_bootstrap_projection",
    axis,options=list(max_targets=as.integer(max_targets),
      n_plotted=nrow(frame)))
}

.etr_fpca_family_test_artist <- function(frame,show_targetwise,
    max_targets) {
  .etr_assert(is.data.frame(frame)&&nrow(frame)>=1L&&
    identical(names(frame),c("target_index","target_curve_id",
      "adjusted_p_value","targetwise_p_value","significance_level"))&&
    all(is.finite(as.matrix(frame[c("target_index","adjusted_p_value",
      "targetwise_p_value","significance_level")])))&&
    all(as.matrix(frame[c("adjusted_p_value","targetwise_p_value")])>=0)&
    all(as.matrix(frame[c("adjusted_p_value","targetwise_p_value")])<=1)&
    length(unique(frame$significance_level))==1L&&
    frame$significance_level[1L]>0&&frame$significance_level[1L]<1,
    "fixed-family test needs finite p-values and a single alpha")
  x<-as.numeric(frame$target_index); alpha<-frame$significance_level[1L]
  artists<-list(list(kind="scatter",marker="o",
    label="single-step maxT adjusted",
    offsets=unname(cbind(x,as.numeric(frame$adjusted_p_value)))))
  if(isTRUE(show_targetwise))
    artists[[length(artists)+1L]]<-list(kind="scatter",marker="x",
      label="target-wise",
      offsets=unname(cbind(x,as.numeric(frame$targetwise_p_value))))
  alpha_label<-sprintf("alpha=%.6g",alpha)
  artists[[length(artists)+1L]]<-list(kind="horizontal_reference",
    linestyle="--",label=alpha_label,x_transform="axes_fraction",
    xdata=c(0,1),ydata=c(alpha,alpha))
  axis<-list(
    title="Fixed-family heteroscedastic Gaussian FPCR tests",
    xlabel="Fixed target trajectory",ylabel="Bootstrap tail probability",
    ylim=c(-.02,1.02),xticks=x,
    xticklabels=as.character(frame$target_curve_id),
    xtick_rotation=90,artists=artists,legend=TRUE,
    legend_labels=vapply(artists,function(a)a$label,character(1L)))
  .etr_fpca_inference_artist_record("plot_fpca_wild_bootstrap_family_test",
    axis,options=list(max_targets=as.integer(max_targets),
      show_targetwise=isTRUE(show_targetwise),n_plotted=nrow(frame),
      significance_level=as.numeric(alpha)))
}
