# Source scientific Matplotlib artist geometry for frozen eyetrajectoriespy 1.2.0.
# plotting.py at c1cd95ad718327550f7e55393ff38582872f7a94.
# No new inference, p-value computation, or live Python Axes object.

.etr_wild_precision_artist <- function(frame,alpha,show_targetwise,max_targets) {
  need<-c("target_index","target_curve_id","adjusted","adjusted_lower",
    "adjusted_upper","targetwise","targetwise_lower","targetwise_upper")
  .etr_assert(is.data.frame(frame)&&identical(names(frame),need)&&
    nrow(frame)>=1L&&
    all(is.finite(as.matrix(frame[c("target_index","adjusted",
      "adjusted_lower","adjusted_upper","targetwise","targetwise_lower",
      "targetwise_upper")])))&&
    all(frame$adjusted_lower<=frame$adjusted)&
    all(frame$adjusted<=frame$adjusted_upper)&
    all(frame$targetwise_lower<=frame$targetwise)&
    all(frame$targetwise<=frame$targetwise_upper),
    "source Monte Carlo artist requires finite ordered bootstrap tail intervals")
  x<-as.numeric(frame$target_index)
  adjusted<-as.numeric(frame$adjusted)
  artists<-list(list(
    kind="errorbar",label="maxT tail probability",marker="o",
    linestyle="none",capsize=3,xdata=x,ydata=adjusted,
    yerr=rbind(adjusted-as.numeric(frame$adjusted_lower),
      as.numeric(frame$adjusted_upper)-adjusted),
    lower=as.numeric(frame$adjusted_lower),
    upper=as.numeric(frame$adjusted_upper)))
  if(isTRUE(show_targetwise)) {
    targetwise<-as.numeric(frame$targetwise)
    artists[[length(artists)+1L]]<-list(
      kind="errorbar",label="target-wise tail probability",marker="x",
      linestyle="none",capsize=3,xdata=x,ydata=targetwise,
      yerr=rbind(targetwise-as.numeric(frame$targetwise_lower),
        as.numeric(frame$targetwise_upper)-targetwise),
      lower=as.numeric(frame$targetwise_lower),
      upper=as.numeric(frame$targetwise_upper))
  }
  alpha_label<-sprintf("alpha=%g",alpha)
  artists[[length(artists)+1L]]<-list(
    kind="horizontal_reference",label=alpha_label,
    linestyle="--",x_transform="axes_fraction",
    xdata=c(0,1),ydata=c(alpha,alpha))
  axis<-list(title="Monte Carlo precision of fixed-family wild-bootstrap tests",
    xlabel="Fixed target trajectory",ylabel="Bootstrap exceedance probability",
    xticks=x,xticklabels=as.character(frame$target_curve_id),
    xtick_rotation=90,ylim=c(-.02,1.02),artists=artists,
    legend=TRUE,legend_labels=vapply(artists,function(a)a$label,character(1L)))
  .etr_fpca_inference_artist_record(
    "plot_fpca_wild_bootstrap_monte_carlo_diagnostics",axis,
    options=list(max_targets=as.integer(max_targets),
      show_targetwise=isTRUE(show_targetwise),
      significance_level=as.numeric(alpha),n_plotted=nrow(frame)))
}

.etr_wild_simultaneous_artist <- function(frame,show_targetwise,max_targets) {
  need<-c("target_index","target_curve_id","reference_projection",
    "simultaneous_lower","simultaneous_upper",
    "targetwise_lower","targetwise_upper")
  .etr_assert(is.data.frame(frame)&&identical(names(frame),need)&&
    nrow(frame)>=1L&&
    all(is.finite(as.matrix(frame[c("target_index","reference_projection",
      "simultaneous_lower","simultaneous_upper","targetwise_lower",
      "targetwise_upper")])))&&
    all(frame$simultaneous_lower<=frame$reference_projection)&
    all(frame$reference_projection<=frame$simultaneous_upper)&
    all(frame$targetwise_lower<=frame$reference_projection)&
    all(frame$reference_projection<=frame$targetwise_upper),
    "source simultaneous artist requires finite ordered projection intervals")
  x<-as.numeric(frame$target_index)
  y<-as.numeric(frame$reference_projection)
  artists<-list(list(
    kind="errorbar",label="familywise simultaneous interval",marker="o",
    linestyle="none",capsize=3,xdata=x,ydata=y,
    yerr=rbind(y-as.numeric(frame$simultaneous_lower),
      as.numeric(frame$simultaneous_upper)-y),
    lower=as.numeric(frame$simultaneous_lower),
    upper=as.numeric(frame$simultaneous_upper)))
  if(isTRUE(show_targetwise))artists[[length(artists)+1L]]<-list(
    kind="errorbar",label="target-wise interval",marker=".",
    linestyle="none",capsize=2,xdata=x,ydata=y,
    yerr=rbind(y-as.numeric(frame$targetwise_lower),
      as.numeric(frame$targetwise_upper)-y),
    lower=as.numeric(frame$targetwise_lower),
    upper=as.numeric(frame$targetwise_upper))
  artists[[length(artists)+1L]]<-list(
    kind="horizontal_reference",label="_child_zero",linestyle="--",
    x_transform="axes_fraction",xdata=c(0,1),ydata=c(0,0))
  axis<-list(
    title="Familywise heteroscedastic Gaussian FPCR projection inference",
    xlabel="Fixed target trajectory",ylabel="Centered FPCR projection",
    xticks=x,xticklabels=as.character(frame$target_curve_id),
    xtick_rotation=90,artists=artists,legend=TRUE,
    legend_labels=vapply(artists[-length(artists)],
      function(a)a$label,character(1L)))
  .etr_fpca_inference_artist_record(
    "plot_fpca_wild_bootstrap_simultaneous_interval",axis,
    options=list(max_targets=as.integer(max_targets),
      show_targetwise=isTRUE(show_targetwise),n_plotted=nrow(frame)))
}
