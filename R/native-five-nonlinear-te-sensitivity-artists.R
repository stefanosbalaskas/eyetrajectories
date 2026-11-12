# Source-scientific Matplotlib artist geometry for five nonlinear
# and transfer-entropy plots, frozen eyetrajectoriespy==1.2.0:
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Native R artist records only, not live Python Matplotlib Axes.

.etr_nonlinear_parameter_source_artist <- function(result,parameter,
    response,frame,source_kind) {
  .etr_assert(source_kind%in%c("kantz","lyapunov")&&
    is.character(parameter)&&length(parameter)==1L&&
    is.character(response)&&length(response)==1L&&
    is.data.frame(frame)&&nrow(frame)>=1L&&
    identical(names(frame),c(parameter,response))&&
    is.numeric(frame[[parameter]])&&is.numeric(frame[[response]])&&
    all(is.finite(frame[[parameter]]))&&
    all(is.finite(frame[[response]]))&&
    !anyDuplicated(frame[[parameter]]),
    "source nonlinear sensitivity artist requires a finite unique parameter slice")
  .etr_assert(is.character(result$curve_id)&&
    length(result$curve_id)==1L&&!is.na(result$curve_id),
    "source nonlinear sensitivity requires one curve identifier")
  if(identical(response,"exponent"))
    .etr_assert(is.character(result$exponent_unit)&&
      length(result$exponent_unit)==1L&&!is.na(result$exponent_unit),
      "source exponent sensitivity requires a physical exponent unit")
  title<-if(identical(source_kind,"kantz"))
    sprintf("Kantz sensitivity: %s",result$curve_id) else
    sprintf("Rosenstein sensitivity: %s",result$curve_id)
  artists<-list(list(kind="line",marker="o",linestyle="-",
    xdata=as.numeric(frame[[parameter]]),
    ydata=as.numeric(frame[[response]])))
  if(identical(response,"exponent"))
    artists[[2L]]<-list(kind="horizontal_reference",
      linestyle=":",x_transform="axes_fraction",
      xdata=c(0,1),ydata=c(0,0),
      label="_child_zero")
  axis<-list(title=title,xlabel=parameter,
    ylabel=if(identical(response,"exponent"))
      sprintf("%s (%s)",response,result$exponent_unit) else response,
    artists=artists,legend=FALSE,legend_labels=character(0))
  .etr_nonlinear_artist_record(
    if(identical(source_kind,"kantz"))
      "plot_kantz_sensitivity" else "plot_lyapunov_sensitivity",
    list(axis),options=list(parameter=parameter,response=response,
      n_points=nrow(frame),
      zero_exponent_reference=identical(response,"exponent")))
}

.etr_windowed_rqa_sensitivity_source_artist <- function(result,profiles,
    curve_id,metric) {
  .etr_assert(is.list(profiles)&&length(profiles)>=1L&&
    is.character(curve_id)&&length(curve_id)==1L&&
    is.character(metric)&&length(metric)==1L,
    "source windowed RQA sensitivity requires explicit curve and metric")
  artists<-lapply(profiles,function(frame) {
    .etr_assert(is.data.frame(frame)&&nrow(frame)>=1L&&
      all(c("specification_id","time","value","window","step")%in%
        names(frame))&&
      is.numeric(frame$time)&&is.numeric(frame$value)&&
      all(is.finite(frame$time))&&any(is.finite(frame$value)),
      "source windowed RQA sensitivity requires finite observed times and metrics")
    label<-sprintf("%s: W=%s, S=%s",
      as.character(frame$specification_id[1L]),frame$window[1L],
      frame$step[1L])
    list(kind="line",label=label,marker="o",linestyle="-",
      xdata=as.numeric(frame$time),ydata=as.numeric(frame$value))
  })
  axis<-list(
    title=sprintf("Window/step sensitivity: %s / %s",curve_id,metric),
    xlabel=sprintf("Window center (%s)",result$analyses[[1L]]$time_unit),
    ylabel=metric,legend=TRUE,
    legend_labels=vapply(artists,function(x)x$label,character(1L)),
    artists=artists)
  .etr_nonlinear_artist_record("plot_windowed_rqa_sensitivity",
    list(axis),options=list(curve_id=curve_id,metric=metric,
      n_specifications=length(artists)))
}

.etr_te_shift_source_artist <- function(data,operation) {
  .etr_assert(operation%in%c(
      "plot_transfer_entropy_circular_shift_test",
      "plot_conditional_transfer_entropy_circular_shift_test")&&
    is.list(data)&&is.numeric(data$breaks)&&
    is.numeric(data$counts)&&
    length(data$breaks)==length(data$counts)+1L&&
    length(data$counts)>=1L&&
    all(is.finite(data$breaks))&&
    all(diff(data$breaks)>0)&&
    all(is.finite(data$counts))&&all(data$counts>=0)&&
    is.numeric(data$observed)&&length(data$observed)==1L&&
    is.finite(data$observed),
    "source TE circular-shift artist requires finite NumPy histogram bins")
  conditional<-identical(operation,
    "plot_conditional_transfer_entropy_circular_shift_test")
  title<-if(conditional)"Conditional-TE circular-shift test" else
    "Transfer-entropy circular-shift test"
  xlabel<-if(conditional)"Conditional transfer entropy (bits)" else
    "Transfer entropy (bits)"
  ylabel<-if(conditional)"Source-only circular-shift surrogates" else
    "Circular-shift surrogates"
  axis<-list(title=title,xlabel=xlabel,ylabel=ylabel,
    artists=list(
      list(kind="histogram",bins=data$binning,
        edges=as.numeric(data$breaks),
        counts=as.numeric(data$counts),
        lower=as.numeric(data$breaks[-length(data$breaks)]),
        upper=as.numeric(data$breaks[-1L]),
        sample_size=length(data$surrogate)),
      list(kind="vertical_reference",linestyle="--",
        x_transform="data",y_transform="axes_fraction",
        xdata=rep(as.numeric(data$observed),2L),
        ydata=c(0,1))),
    legend=FALSE,legend_labels=character(0))
  .etr_nonlinear_artist_record(operation,list(axis),
    options=list(binning=data$binning,n_surrogates=length(data$surrogate),
      observed=data$observed,causal_identification_claim=FALSE))
}
