# Stage 29: native transfer-entropy source plots, no Python bridge.
# These display source numerical results and do NOT establish causality.

.etr_select_te_plot_slice <- function(result,parameter,metric,filters) {
  .etr_assert(inherits(result,"etr_transfer_entropy_sensitivity")&&
    is.data.frame(result$table)&&nrow(result$table)>=1L&&
    is.character(parameter)&&length(parameter)==1L&&
    !is.na(parameter)&&parameter%in%result$parameter_columns&&
    is.character(metric)&&length(metric)==1L&&!is.na(metric)&&
    metric%in%result$metric_columns,
    "result, parameter and metric must identify native TE sensitivity")
  t<-result$table
  .etr_assert(all(c(parameter,metric)%in%names(t)),
    "selected native transfer-entropy table columns are missing")
  if(!is.null(filters)) {
    .etr_assert(is.list(filters)&&!is.null(names(filters))&&
      all(nzchar(names(filters)))&&
      !anyDuplicated(names(filters))&&
      all(names(filters)%in%result$parameter_columns)&&
      !parameter%in%names(filters),
      "filters must be distinct fixed TE specification parameters")
    for(nm in names(filters)) {
      .etr_assert(length(filters[[nm]])==1L&&!is.na(filters[[nm]]),
        "TE filter values must be one nonmissing value")
      t<-t[!is.na(t[[nm]])&t[[nm]]==filters[[nm]],,drop=FALSE]
    }
  }
  .etr_assert(nrow(t)>0L,"TE filters leave no sensitivity specifications")
  .etr_assert(!anyDuplicated(t[[parameter]]),
    "TE sensitivity slice contains multiple rows per parameter value; add filters")
  .etr_assert(is.numeric(t[[parameter]])&&
    is.numeric(t[[metric]])&&
    all(is.finite(t[[parameter]]))&&
    all(is.finite(t[[metric]])),
    "TE sensitivity source parameter/metric must be finite numeric values")
  t[order(t[[parameter]]),c(parameter,metric),drop=FALSE]
}

#' Show one explicitly identified transfer-entropy multiverse sensitivity slice
#' @param result Native TE parameter sensitivity result.
#' @param parameter Declared varying parameter.
#' @param metric Native TE statistic.
#' @param filters Fixed remaining specification parameter values.
#' @param ... Base R graphics options.
#' @return Invisible exact source x/y coordinates.
#' @export
etr_plot_transfer_entropy_sensitivity <- function(result,parameter,
    metric="transfer_entropy_bits",filters=NULL,
    strict_source_record=FALSE,...) {
  .etr_fpca_uncertainty_strict(strict_source_record)
  t<-.etr_select_te_plot_slice(result,parameter,metric,filters)
  graphics::plot(t[[parameter]],t[[metric]],type="o",pch=1,
    xlab=gsub("_"," ",parameter),ylab=gsub("_"," ",metric),
    main="Transfer-entropy specification sensitivity",...)
  if(isTRUE(strict_source_record)) {
    .etr_te_strict_source_validate_slice(result,parameter,filters)
    return(invisible(.etr_te_sensitivity_source_artist(
      parameter,metric,t)))
  }
  invisible(t)
}

# Native implementation of NumPy's finite-data histogram 'auto' rules.
# NumPy >=2.3 may use a relaxed FD width bounded by half the sqrt width;
# older NumPy applies classic FD/Sturges fallback. Explicitly select a
# policy rather than silently pretending the source NumPy version is fixed.
.etr_numpy_histogram_auto_breaks <- function(values,
    policy=c("relaxed","classic")) {
  policy<-match.arg(policy)
  .etr_assert(is.numeric(values)&&length(values)>=1L&&
    all(is.finite(values)),
    "NumPy histogram requires finite nonempty numeric surrogate samples")
  interval<-range(values)
  if(interval[1L]==interval[2L])
    return(seq(interval[1L]-.5,interval[2L]+.5,length.out=2L))
  span<-diff(interval)
  .etr_assert(is.finite(span)&&span>0,
    "NumPy histogram auto range must be positive finite")
  n<-length(values)
  q<-as.numeric(stats::quantile(values,c(.25,.75),
      names=FALSE,type=7))
  fd<-2*(q[2L]-q[1L])*(n^(-1/3))
  sturges<-span/(log2(n)+1)
  if(policy=="relaxed") {
    sqrt_width<-span/sqrt(n)
    width<-min(max(fd,sqrt_width/2),sturges)
  } else {
    width<-if(fd>0)min(fd,sturges) else sturges
  }
  .etr_assert(is.finite(width)&&width>0,
    "NumPy histogram automatic bin width must be positive finite")
  count<-ceiling(span/width)
  # A bounded resource policy is stricter than source NumPy; never clamp
  # because clamping would silently alter the scientific histogram.
  .etr_assert(is.finite(count)&&count>=1&&count<=10000,
    "NumPy automatic bin count exceeds native 10000-bin safety bound")
  seq(interval[1L],interval[2L],length.out=as.integer(count)+1L)
}

.etr_plot_te_surrogate_histogram <- function(result,kind,field,observed_field,
    title,xlab,ylab,bins,python_boundary_mode=FALSE,
    numpy_auto_policy="relaxed",strict_source_record=FALSE,...) {
  .etr_fpca_uncertainty_strict(strict_source_record)
  .etr_assert(inherits(result,kind)&&is.list(result$observed)&&
    is.numeric(result[[field]])&&length(result[[field]])>=1L&&
    all(is.finite(result[[field]]))&&
    is.numeric(result$observed[[observed_field]])&&
    length(result$observed[[observed_field]])==1L&&
    is.finite(result$observed[[observed_field]]),
    paste("result must be a finite native",kind,"source-shift null result"))
  .etr_assert((is.character(bins)&&length(bins)==1L&&
    !is.na(bins)&&identical(bins,"auto"))||
    (is.numeric(bins)&&length(bins)==1L&&!is.logical(bins)&&
      is.finite(bins)&&bins==as.integer(bins)&&
      bins>=1L&&bins<=10000L),
    "bins must be 'auto' or a positive integer up to 10000")
  .etr_assert(is.logical(python_boundary_mode)&&
    length(python_boundary_mode)==1L&&!is.na(python_boundary_mode),
    "python_boundary_mode must be a nonmissing logical scalar")
  .etr_assert(is.character(numpy_auto_policy)&&
    length(numpy_auto_policy)==1L&&!is.na(numpy_auto_policy)&&
    numpy_auto_policy%in%c("relaxed","classic"),
    "numpy_auto_policy must be relaxed or classic")
  values<-as.numeric(result[[field]])
  observed<-as.numeric(result$observed[[observed_field]])
  if(isTRUE(strict_source_record)) {
    .etr_assert(is.character(bins)||is.integer(bins),
      "source histogram bins must be an R integer or auto")
    if(is.character(bins))python_boundary_mode<-TRUE
  }
  python_auto<-is.character(bins)&&isTRUE(python_boundary_mode)
  if(python_auto){
    br<-.etr_numpy_histogram_auto_breaks(values,numpy_auto_policy)
  } else if(is.character(bins)) {
    br<-"Sturges"
  } else {
    rng<-range(values)
    if(rng[1L]==rng[2L])rng<-rng+c(-.5,.5)
    br<-seq(rng[1L],rng[2L],length.out=as.integer(bins)+1L)
  }
  if(python_auto||isTRUE(strict_source_record)) {
    # NumPy bins are left-closed/right-open, except the last bin,
    # whose right edge is included. R hist() applies a fuzzy edge
    # tolerance: recompute exact NumPy counts for the source geometry.
    h<-graphics::hist(values,breaks=br,right=FALSE,
      include.lowest=TRUE,plot=FALSE)
    h$counts<-as.integer(tabulate(findInterval(values,h$breaks,
      rightmost.closed=TRUE),nbins=length(h$breaks)-1L))
    h$density<-h$counts/(length(values)*diff(h$breaks))
    graphics::plot(h,freq=TRUE,xlab=xlab,ylab=ylab,main=title,...)
  } else {
    h<-graphics::hist(values,breaks=br,right=FALSE,
      include.lowest=TRUE,xlab=xlab,ylab=ylab,main=title,...)
  }
  graphics::abline(v=observed,lty=2)
  out<-list(surrogate=values,observed=observed,
    breaks=as.numeric(h$breaks),counts=as.integer(h$counts),
    binning=if(python_auto)
      paste0("numpy_auto_",numpy_auto_policy) else
      if(is.character(bins))"R_Sturges_not_numpy_auto" else
      "explicit_equal_width")
  if(isTRUE(strict_source_record))
    return(invisible(.etr_te_shift_source_artist(out,
      if(identical(observed_field,"conditional_transfer_entropy_bits"))
        "plot_conditional_transfer_entropy_circular_shift_test" else
        "plot_transfer_entropy_circular_shift_test")))
  invisible(out)
}

#' Plot the source-only circular-shift null and observed transfer entropy
#' @param result Native TE circular-shift test result.
#' @param bins Positive fixed bin count or 'auto'.
#' @param python_boundary_mode When TRUE with bins='auto', use
#'   NumPy-style histogram edges and left-inclusive counts rather
#'   than R's Sturges default. This does not change the R graphics backend.
#' @param numpy_auto_policy Choose 'relaxed' NumPy modern histogram
#'   FD/Sqrt/Sturges policy or 'classic' FD/Sturges fallback to support
#'   differing installed NumPy versions. Defaults to 'relaxed'.
#' @param ... Base R graphics options.
#' @return Invisible source null and histogram geometry.
#' @export
etr_plot_transfer_entropy_circular_shift_test <- function(
    result,bins="auto",python_boundary_mode=FALSE,
    numpy_auto_policy="relaxed",strict_source_record=FALSE,...) {
  .etr_plot_te_surrogate_histogram(result,
    kind="etr_transfer_entropy_circular_shift_test",
    field="surrogate_transfer_entropy_bits",
    observed_field="transfer_entropy_bits",
    title="Transfer-entropy circular-shift test",
    xlab="Transfer entropy (bits)",ylab="Circular-shift surrogates",
    bins=bins,python_boundary_mode=python_boundary_mode,
    numpy_auto_policy=numpy_auto_policy,
    strict_source_record=strict_source_record,...)
}

#' Plot source-shift null and observed conditional transfer entropy
#' @param result Native conditional TE circular-shift result.
#' @param bins Positive fixed bin count or 'auto'.
#' @param python_boundary_mode When TRUE with bins='auto', use
#'   NumPy-style histogram edges and left-inclusive counts rather
#'   than R's Sturges default. This does not change the R graphics backend.
#' @param numpy_auto_policy Choose 'relaxed' NumPy modern histogram
#'   FD/Sqrt/Sturges policy or 'classic' FD/Sturges fallback to support
#'   differing installed NumPy versions. Defaults to 'relaxed'.
#' @param ... Base R graphics options.
#' @return Invisible source null and histogram geometry.
#' @export
etr_plot_conditional_transfer_entropy_circular_shift_test <- function(
    result,bins="auto",python_boundary_mode=FALSE,
    numpy_auto_policy="relaxed",strict_source_record=FALSE,...) {
  .etr_plot_te_surrogate_histogram(result,
    kind="etr_conditional_transfer_entropy_circular_shift_test",
    field="surrogate_conditional_transfer_entropy_bits",
    observed_field="conditional_transfer_entropy_bits",
    title="Conditional-TE circular-shift test",
    xlab="Conditional transfer entropy (bits)",
    ylab="Source-only circular-shift surrogates",
    bins=bins,python_boundary_mode=python_boundary_mode,
    numpy_auto_policy=numpy_auto_policy,
    strict_source_record=strict_source_record,...)
}
