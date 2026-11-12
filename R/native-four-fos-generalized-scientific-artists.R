# Frozen eyetrajectoriespy==1.2.0 scientific Matplotlib artist coordinates.
# Commit c1cd95ad718327550f7e55393ff38582872f7a94.
# These native-R records are NOT Python Matplotlib Axes or pixel renderings.
# Scientific means, coefficients, bootstrap intervals and estimators are not refitted.

.etr_fos_artist_line <- function(time,estimate,label=NULL) {
  list(kind="line",marker="None",linestyle="-",label=label,
    xdata=as.numeric(time),ydata=as.numeric(estimate))
}

.etr_fos_artist_fill <- function(time,lower,upper,label=NULL) {
  .etr_assert(is.numeric(time)&&is.numeric(lower)&&is.numeric(upper)&&
    length(time)==length(lower)&&length(time)==length(upper)&&
    length(time)>=1L&&all(is.finite(c(time,lower,upper)))&&
    all(lower<=upper),
    "source simultaneous band needs finite ordered bounds on observed grid")
  list(kind="fill_between",alpha=.2,label=label,
    xdata=as.numeric(time),y1=as.numeric(lower),y2=as.numeric(upper))
}

.etr_fos_artist_reference <- function(y,dashed=FALSE) {
  list(kind="horizontal_reference",x_transform="axes_fraction",
    ydata=rep(as.numeric(y),2L),xdata=c(0,1),
    linewidth=if(dashed)NULL else 1.0,
    linestyle=if(dashed)"--" else "-")
}

.etr_gfos_predictions_source_artist <- function(result,frame) {
  is_band<-is.list(result)&&"prediction"%in%names(result)
  prediction<-if(is_band)result$prediction else result
  time<-prediction$reference$time
  ids<-as.character(prediction$profile_ids)
  .etr_assert(is.data.frame(frame)&&
    nrow(frame)==length(ids)*length(time),
    "generalized FOS prediction artists require complete source grid")
  labels<-ifelse(prediction$extrapolation_flags,
    paste0(ids," (extrapolation)"),ids)
  artists<-list()
  for(i in seq_along(ids)) {
    artists[[length(artists)+1L]]<-.etr_fos_artist_line(
      time,prediction$mean_functions[i,],labels[i])
    if(is_band)
      artists[[length(artists)+1L]]<-.etr_fos_artist_fill(
        time,result$mean_lower[i,],result$mean_upper[i,])
  }
  family<-prediction$reference$family
  scale<-prediction$prediction_scale
  ylabel<-if(identical(family,"binomial"))"Marginal probability" else
    if(identical(scale,"rate"))"Marginal exposure-adjusted rate" else
      "Marginal expected count"
  ax<-list(title="Generalized FoSR fixed-profile marginal predictions",
    xlabel=paste0("Time (",prediction$reference$time_unit,")"),
    ylabel=ylabel,artists=artists,
    legend=TRUE,legend_labels=labels)
  .etr_nonlinear_artist_record(
    "plot_generalized_function_on_scalar_predictions",list(ax),
    options=list(n_profiles=length(ids),banded=is_band,
      prediction_scale=scale,family=family,
      simultaneous_band_estimand="precomputed_only"))
}

.etr_gfos_mean_difference_source_artist <- function(result,frame) {
  time<-frame$time
  level<-result$confidence_level
  .etr_assert(is.numeric(level)&&length(level)==1L&&
    is.finite(level)&&level>0&&level<1,
    "generalized FOS contrast requires confidence level in (0,1)")
  scale<-result$contrast_scale
  labels<-c(probability_difference="Marginal probability difference",
    rate_difference="Marginal rate difference",
    rate_ratio="Marginal rate ratio",
    expected_count_difference="Marginal expected-count difference")
  .etr_assert(scale%in%names(labels),"unknown contrast_scale")
  band_label<-sprintf("%.0f%% simultaneous band",100*level)
  ref<-if(identical(scale,"rate_ratio"))1 else 0
  artists<-list(
    .etr_fos_artist_line(time,frame$estimate,"estimate"),
    .etr_fos_artist_fill(time,frame$lower,frame$upper,band_label),
    .etr_fos_artist_reference(ref))
  ax<-list(title=paste0("Generalized FoSR ",
      gsub("_"," ",scale,fixed=TRUE),": ",
      result$profile_a," - ",result$profile_b),
    xlabel=paste0("Time (",
      result$prediction_bootstrap$prediction$reference$time_unit,")"),
    ylabel=unname(labels[[scale]]),artists=artists,
    legend=TRUE,legend_labels=c("estimate",band_label))
  .etr_nonlinear_artist_record(
    "plot_generalized_function_on_scalar_mean_difference",list(ax),
    options=list(contrast_scale=scale,
      horizontal_reference=ref,
      confidence_level=level,
      calibrated_interval_reused=TRUE))
}

.etr_gfos_coefficients_source_artist <- function(result,coefficient,frame) {
  is_band<-is.list(result)&&
    all(c("reference","lower","upper")%in%names(result))
  fit<-if(is_band)result$reference else result
  name<-as.character(coefficient)
  .etr_assert(length(name)==1L&&identical(frame$time,fit$time),
    "generalized FOS source coefficient needs the original observed grid")
  artists<-list(.etr_fos_artist_line(frame$time,frame$estimate,"estimate"))
  labels<-"estimate"
  if(is_band) {
    level<-result$confidence_level
    .etr_assert(is.numeric(level)&&length(level)==1L&&
      !is.logical(level)&&is.finite(level)&&
      level>0&&level<1,
      "source simultaneous coefficient band confidence_level must be in (0,1)")
    label<-sprintf("%.0f%% simultaneous band",100*level)
    artists[[length(artists)+1L]]<-.etr_fos_artist_fill(
      frame$time,frame$lower,frame$upper,label)
    labels<-c(labels,label)
  }
  artists[[length(artists)+1L]]<-.etr_fos_artist_reference(0)
  ax<-list(title=paste0(
      "Generalized function-on-scalar coefficient: ",name),
    xlabel=paste0("Time (",fit$time_unit,")"),
    ylabel=paste0(name," coefficient (",fit$link," scale)"),
    artists=artists,legend=TRUE,legend_labels=labels)
  .etr_nonlinear_artist_record(
    "plot_generalized_function_on_scalar_coefficients",list(ax),
    options=list(coefficient=name,banded=is_band,
      physical_scale="declared_link_scale",
      observed_grid_only=TRUE))
}

.etr_fos_coefficients_source_artist <- function(fit,geometry) {
  .etr_assert(is.list(geometry)&&
    all(c("time","estimate","coefficient","dimension","band")%in%
      names(geometry)),
    "source FOS scientific artist requires native coefficient geometry")
  time<-geometry$time
  artists<-list()
  labels<-character()
  if(!is.null(geometry$band)) {
    b<-geometry$band
    level<-b$confidence_level
    scope<-b$simultaneous_scope
    .etr_assert(is.numeric(level)&&length(level)==1L&&
      !is.logical(level)&&is.finite(level)&&level>0&&level<1&&
      is.character(scope)&&length(scope)==1L&&
      !is.na(scope)&&nzchar(scope),
      "source FOS band requires calibrated confidence level and scope")
    band_label<-sprintf("%.1f%% simultaneous band (%s)",100*level,scope)
    artists[[1L]]<-.etr_fos_artist_fill(
      time,geometry$lower,geometry$upper,band_label)
    labels<-c(labels,band_label)
  }
  artists[[length(artists)+1L]]<-.etr_fos_artist_line(
    time,geometry$estimate,geometry$coefficient)
  labels<-c(labels,geometry$coefficient)
  artists[[length(artists)+1L]]<-.etr_fos_artist_reference(
    0,dashed=TRUE)
  ax<-list(title=paste0("Function-on-scalar coefficient: ",
      geometry$coefficient),
    xlabel=paste0("Time (",fit$time_unit,")"),
    ylabel=paste0("Coefficient: ",geometry$dimension),
    artists=artists,legend=TRUE,legend_labels=labels)
  .etr_nonlinear_artist_record(
    "plot_function_on_scalar_coefficients",list(ax),
    options=list(coefficient=geometry$coefficient,
      dimension=geometry$dimension,
      banded=!is.null(geometry$band),
      source_scientific_estimator="precomputed_function_on_scalar",
      observed_grid_only=TRUE))
}
