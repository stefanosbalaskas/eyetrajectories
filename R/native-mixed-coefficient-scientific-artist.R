# Frozen Python eyetrajectoriespy 1.2.0 plotting.py:
# plot_functional_mixed_effects_coefficient, commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
# This is native R scientific geometry, never a Python Matplotlib Axes.

.etr_mixed_coefficient_plot_source <- function(result,coefficient) {
  .etr_assert(is.list(result),
    "mixed coefficient source result must be a native list or band record")
  is_band<-all(c("reference","lower","upper","confidence_level",
    "simultaneous_scope")%in%names(result))
  fit<-if(is_band)result$reference else result
  .etr_assert(is.list(fit)&&
    all(c("time","time_unit","dimension_name","coefficient_names",
      "coefficient_functions")%in%names(fit)),
    "source mixed fit needs time, units, coefficient names and functions")
  time<-fit$time
  ids<-fit$coefficient_names
  .etr_assert(is.numeric(time)&&!is.logical(time)&&
    length(time)>=1L&&all(is.finite(time))&&
    !anyDuplicated(time)&&all(diff(time)>0),
    "source mixed observed time grid must be finite and strictly increasing")
  .etr_assert(is.character(ids)&&length(ids)>=1L&&!anyNA(ids)&&
    all(nzchar(ids))&&!anyDuplicated(ids),
    "source mixed coefficient_names must be nonempty and distinct")
  for(field in c("time_unit","dimension_name"))
    .etr_assert(is.character(fit[[field]])&&
      length(fit[[field]])==1L&&!is.na(fit[[field]])&&
      nzchar(fit[[field]]),
      paste0("source mixed ",field," must be a nonempty string"))
  nc<-length(ids);nt<-length(time)
  matrix_source<-function(x,name,nonnegative=FALSE) {
    .etr_assert(is.matrix(x)&&is.numeric(x)&&!is.logical(x)&&
      identical(dim(x),c(nc,nt))&&all(is.finite(x))&&
      (!nonnegative||all(x>=0)),
      paste0("source mixed ",name," must be finite ",
        nc,"-by-",nt,if(nonnegative)" nonnegative" else ""))
    x
  }
  estimate<-matrix_source(fit$coefficient_functions,
    "coefficient_functions")
  if(is.character(coefficient)) {
    .etr_assert(length(coefficient)==1L&&!is.na(coefficient)&&
      coefficient%in%ids,
      "Unknown coefficient")
    k<-match(coefficient,ids)
  } else {
    .etr_assert(is.integer(coefficient)&&length(coefficient)==1L&&
      !is.na(coefficient)&&coefficient>=0L&&coefficient<nc,
      "coefficient must be a source name or zero-based integer index")
    k<-as.integer(coefficient)+1L
  }
  name<-ids[k]
  if(is_band) {
    lower<-matrix_source(result$lower,"lower")
    upper<-matrix_source(result$upper,"upper")
    .etr_assert(all(lower<=upper),
      "source mixed simultaneous lower bounds must not exceed upper")
    level<-result$confidence_level
    scope<-result$simultaneous_scope
    .etr_assert(is.numeric(level)&&!is.logical(level)&&
      length(level)==1L&&is.finite(level)&&level>0&&level<1,
      "source mixed simultaneous confidence_level must be in (0,1)")
    .etr_assert(is.character(scope)&&length(scope)==1L&&
      !is.na(scope)&&nzchar(scope),
      "source mixed simultaneous_scope must be nonempty")
    caption<-sprintf("%.1f%% simultaneous band (%s)",
      100*level,scope)
    lower<-as.numeric(lower[k,]);upper<-as.numeric(upper[k,])
    interval_type<-"simultaneous_source_band"
  } else {
    .etr_assert("coefficient_standard_errors"%in%names(fit),
      "source mixed pointwise result requires coefficient_standard_errors")
    se<-matrix_source(fit$coefficient_standard_errors,
      "coefficient_standard_errors",nonnegative=TRUE)
    z<-1.959963984540054
    lower<-as.numeric(estimate[k,]-z*se[k,])
    upper<-as.numeric(estimate[k,]+z*se[k,])
    caption<-"95% pointwise Wald interval"
    interval_type<-"pointwise_95_Wald_not_simultaneous"
  }
  data<-data.frame(time=as.numeric(time),
    estimate=as.numeric(estimate[k,]),
    lower=lower,upper=upper,coefficient=name,
    interval_type=interval_type,stringsAsFactors=FALSE)
  artists<-list(
    list(kind="fill_between",xdata=data$time,y1=data$lower,
      y2=data$upper,alpha=.2,label=caption),
    list(kind="line",xdata=data$time,ydata=data$estimate,
      marker="None",linestyle="-",label=name),
    list(kind="horizontal_reference",xdata=c(0,1),ydata=c(0,0),
      x_transform="axes_fraction",linestyle="--"))
  axis<-list(
    title=paste0("Functional mixed-effects coefficient: ",name),
    xlabel=paste0("Time (",fit$time_unit,")"),
    ylabel=paste0("Coefficient: ",fit$dimension_name),
    artists=artists,legend=TRUE,legend_labels=c(caption,name))
  record<-.etr_nonlinear_artist_record(
    "plot_functional_mixed_effects_coefficient",list(axis),
    options=list(coefficient=name,coefficient_index=as.integer(k-1L),
      interval_type=interval_type,
      simultaneous_band_input=is_band,
      calibration_reused=is_band,
      normal_quantile_if_unbanded=if(is_band)NULL else z))
  list(data=data,record=record)
}

.etr_mixed_coefficient_source_plot <- function(x,...) {
  d<-x$data
  graphics::plot(d$time,d$estimate,type="n",
    xlab=x$record$axes[[1L]]$xlabel,
    ylab=x$record$axes[[1L]]$ylabel,
    main=x$record$axes[[1L]]$title,
    ylim=range(c(d$lower,d$upper,0)),...)
  graphics::polygon(c(d$time,rev(d$time)),
    c(d$lower,rev(d$upper)),border=NA,
    col=grDevices::adjustcolor("grey60",alpha.f=.2))
  graphics::lines(d$time,d$estimate)
  graphics::abline(h=0,lty=2)
  graphics::legend("topright",
    legend=x$record$axes[[1L]]$legend_labels,
    lty=c(NA,1),pch=c(15,NA),bty="n")
  invisible(x$record)
}
