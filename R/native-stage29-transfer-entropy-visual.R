# Stage 29: native transfer-entropy source plots, no Python bridge.
# These display source numerical results and do NOT establish causality.

.etr29_te_plot_slice <- function(result,parameter,metric,filters) {
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
    metric="transfer_entropy_bits",filters=NULL,...) {
  t<-.etr29_te_plot_slice(result,parameter,metric,filters)
  graphics::plot(t[[parameter]],t[[metric]],type="o",pch=1,
    xlab=gsub("_"," ",parameter),ylab=gsub("_"," ",metric),
    main="Transfer-entropy specification sensitivity",...)
  invisible(t)
}

.etr29_te_null_hist <- function(result,kind,field,observed_field,
    title,xlab,ylab,bins,...) {
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
  values<-as.numeric(result[[field]])
  observed<-as.numeric(result$observed[[observed_field]])
  if(is.character(bins)) {
    # Python's numpy 'auto' FD/Sturges dispatch differs from R Sturges.
    # This behavior remains explicitly uncertified in the source gap ledger.
    br<-"Sturges"
  } else {
    rng<-range(values)
    if(rng[1L]==rng[2L])rng<-rng+c(-.5,.5)
    br<-seq(rng[1L],rng[2L],length.out=as.integer(bins)+1L)
  }
  h<-graphics::hist(values,breaks=br,right=FALSE,
    include.lowest=TRUE,xlab=xlab,ylab=ylab,main=title,...)
  graphics::abline(v=observed,lty=2)
  invisible(list(surrogate=values,observed=observed,
    breaks=as.numeric(h$breaks),counts=as.integer(h$counts),
    binning=if(is.character(bins))"R_Sturges_not_numpy_auto" else
      "explicit_equal_width"))
}

#' Plot the source-only circular-shift null and observed transfer entropy
#' @param result Native TE circular-shift test result.
#' @param bins Positive fixed bin count or 'auto' (R Sturges).
#' @param ... Base R graphics options.
#' @return Invisible source null and histogram geometry.
#' @export
etr_plot_transfer_entropy_circular_shift_test <- function(
    result,bins="auto",...) {
  .etr29_te_null_hist(result,
    kind="etr_transfer_entropy_circular_shift_test",
    field="surrogate_transfer_entropy_bits",
    observed_field="transfer_entropy_bits",
    title="Transfer-entropy circular-shift test",
    xlab="Transfer entropy (bits)",ylab="Circular-shift surrogates",
    bins=bins,...)
}

#' Plot source-shift null and observed conditional transfer entropy
#' @param result Native conditional TE circular-shift result.
#' @param bins Positive fixed bin count or 'auto' (R Sturges).
#' @param ... Base R graphics options.
#' @return Invisible source null and histogram geometry.
#' @export
etr_plot_conditional_transfer_entropy_circular_shift_test <- function(
    result,bins="auto",...) {
  .etr29_te_null_hist(result,
    kind="etr_conditional_transfer_entropy_circular_shift_test",
    field="surrogate_conditional_transfer_entropy_bits",
    observed_field="conditional_transfer_entropy_bits",
    title="Conditional-TE circular-shift test",
    xlab="Conditional transfer entropy (bits)",
    ylab="Source-only circular-shift surrogates",
    bins=bins,...)
}
