# Source-scientific native plot artist geometry, frozen Python
# eyetrajectoriespy==1.2.0, plotting.py commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
# R returns inspectable artist records, not live Python matplotlib Axes.

.etr_predictive_plot_artist_record <- function(name,axis,source_options=list()) {
  .etr_assert(is.character(name)&&length(name)==1L&&
    is.list(axis)&&is.character(axis$title)&&length(axis$title)==1L&&
    is.character(axis$xlabel)&&length(axis$xlabel)==1L&&
    is.character(axis$ylabel)&&length(axis$ylabel)==1L&&
    is.list(axis$artists)&&length(axis$artists)>0L,
    "source predictive artist record requires nonempty scientific artists")
  structure(list(source_export=name,renderer="native_R_base_graphics",
    python_return_kind="matplotlib.axes.Axes",
    panel_layout=c(1L,1L),axes=list(axis),source_options=source_options,
    matplotlib_object_identity=FALSE,
    source_scientific_geometry_reviewed=TRUE,
    independently_certified=FALSE),
    class=c("etr_predictive_scientific_artist_record","list"))
}

.etr_predictive_cv_source_artist <- function(data,loss,family) {
  .etr_assert(is.list(data)&&is.data.frame(data$summary)&&
    is.data.frame(data$line)&&is.data.frame(data$errorbar)&&
    nrow(data$line)==nrow(data$errorbar)&&
    identical(as.numeric(data$line$x),as.numeric(data$errorbar$x)),
    "source CV artist requires aligned finite summary, line and errorbar")
  x<-as.numeric(data$line$x);y<-as.numeric(data$line$y)
  low<-as.numeric(data$errorbar$lower)
  high<-as.numeric(data$errorbar$upper)
  .etr_assert(length(x)>=1L&&all(is.finite(c(x,y,low,high)))&&
    all(low<=y)&all(y<=high),
    "source CV artist requires finite ordered mean-loss errorbars")
  axis<-list(title=paste0("Predictive FPCA regression CV (",family,")"),
    xlabel="Retained functional principal components",
    ylabel=paste0("Held-out ",loss),
    artists=list(list(kind="errorbar",marker="o",capsize=3,
      linestyle="-",xdata=x,ydata=y,
      yerr=rbind(y-low,high-y),lower=low,upper=high)),
    legend=FALSE,legend_labels=character(0))
  .etr_predictive_plot_artist_record("plot_fpca_regression_cv",axis,
    list(family=family,loss=loss,n_candidates=length(x)))
}

.etr_predictive_nested_cv_source_artist <- function(data,loss) {
  .etr_assert(is.list(data)&&is.data.frame(data$line)&&
    identical(names(data$line),c("x","y"))&&
    nrow(data$line)>=1L&&
    all(is.finite(as.matrix(data$line))),
    "source nested CV artist requires finite ordered outer-fold losses")
  x<-as.numeric(data$line$x);y<-as.numeric(data$line$y)
  axis<-list(title="Nested predictive FPCA regression",
    xlabel="Outer fold",ylabel=paste0("Outer held-out ",loss),
    artists=list(list(kind="line",marker="o",
      linestyle="-",xdata=x,ydata=y)),legend=FALSE,
    legend_labels=character(0))
  .etr_predictive_plot_artist_record("plot_nested_fpca_regression_cv",
    axis,list(loss=loss,n_outer_folds=length(x)))
}

.etr_predictive_truncation_source_artist <- function(data) {
  .etr_assert(is.list(data)&&is.data.frame(data$line)&&
    identical(names(data$line),c("x","y"))&&
    nrow(data$line)>=1L&&all(is.finite(as.matrix(data$line)))&&
    is.character(data$target_curve_id)&&length(data$target_curve_id)==1L&&
    is.character(data$metric)&&length(data$metric)==1L&&
    data$metric%in%c("width","center"),
    "source truncation artist requires finite selected-target geometry")
  x<-as.numeric(data$line$x);y<-as.numeric(data$line$y)
  artists<-list(list(kind="line",marker="o",
    linestyle="-",xdata=x,ydata=y))
  legend<-FALSE
  if(length(data$selected_inference_components)==1L&&
      !is.na(data$selected_inference_components)){
    selected<-as.numeric(data$selected_inference_components)
    .etr_assert(is.finite(selected)&&selected==floor(selected)&&selected>=1,
      "selected truncation must be a finite positive integer or missing")
    artists[[length(artists)+1L]]<-list(kind="vertical_reference",
      linestyle="--",x_transform="data",y_transform="axes_fraction",
      xdata=c(selected,selected),ydata=c(0,1),
      label=paste0("selected h=",as.integer(selected)))
    legend<-TRUE
  }
  axis<-list(title=paste0("Wild-bootstrap truncation scan: ",
      data$target_curve_id),
    xlabel="Inference truncation h",
    ylabel=if(data$metric=="width")"Interval width" else "Interval center",
    artists=artists,legend=legend,
    legend_labels=if(legend)artists[[2L]]$label else character(0))
  .etr_predictive_plot_artist_record(
    "plot_fpca_wild_bootstrap_truncation_scan",axis,
    list(target_curve_id=data$target_curve_id,metric=data$metric,
      selected_inference_components=data$selected_inference_components,
      target_index_zero_based=TRUE))
}
