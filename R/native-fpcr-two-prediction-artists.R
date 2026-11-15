# Source scientific Matplotlib artists for two native FPCR prediction plots.
# Frozen eyetrajectoriespy==1.2.0 plotting.py,
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Explicit strict R record, no automatic Python runtime, no estimator changes.

.etr_fpcr_prediction_artist <- function(frame,operation,max_targets) {
  needed<-c("x","curve_id","center","lower","upper","reference")
  .etr_assert(is.data.frame(frame)&&identical(names(frame),needed)&&
    nrow(frame)>=1L&&
    all(is.finite(as.matrix(frame[c("x","center","lower",
      "upper","reference")])))&&
    all(frame$lower<=frame$center)&all(frame$center<=frame$upper),
    "source FPCR prediction artist requires complete finite intervals")
  .etr_assert(is.character(operation)&&length(operation)==1L&&
    operation%in%c("plot_fpca_regression_future_prediction_interval",
      "plot_fpca_regression_mean_prediction_uncertainty"),
    "unrecognized FPCR prediction source artist")
  title<-if(operation=="plot_fpca_regression_future_prediction_interval")
    "Gaussian FPCR future-outcome prediction" else
    "FPCR conditional-mean uncertainty"
  ylabel<-if(operation=="plot_fpca_regression_future_prediction_interval")
    "Scalar response" else "Conditional mean response"
  label<-if(operation=="plot_fpca_regression_future_prediction_interval")
    "future-outcome predictive interval" else
    "bootstrap median + conditional-mean envelope"
  x<-as.numeric(frame$x);center<-as.numeric(frame$center)
  artists<-list(
    list(kind="errorbar",label=label,marker="o",
      linestyle="none",capsize=3,xdata=x,ydata=center,
      yerr=rbind(center-as.numeric(frame$lower),
        as.numeric(frame$upper)-center),
      lower=as.numeric(frame$lower),
      upper=as.numeric(frame$upper)),
    list(kind="scatter",label="full-sample conditional mean",
      marker="x",offsets=unname(cbind(x,as.numeric(frame$reference)))))
  axis<-list(title=title,xlabel="Fixed target trajectory",ylabel=ylabel,
    xticks=x,xticklabels=as.character(frame$curve_id),xtick_rotation=90,
    artists=artists,legend=TRUE,
    legend_labels=c("full-sample conditional mean",label))
  .etr_fpca_inference_artist_record(operation,axis,options=list(
    max_targets=as.integer(max_targets),n_plotted=nrow(frame)))
}
