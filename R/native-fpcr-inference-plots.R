# Six read-only native FPCR/PACE plotting integrations from published
# eyetrajectoriespy 1.2.0 src/eyetrajectoriespy/plotting.py at
# c1cd95ad718327550f7e55393ff38582872f7a94.
# No new estimators, no Python runtime or automatic inference.

.etr_fpcr_plot_count <- function(max_targets,n){
  .etr_assert(is.numeric(max_targets)&&length(max_targets)==1L&&
    !is.na(max_targets)&&is.finite(max_targets)&&
    max_targets==floor(max_targets)&&max_targets>=1,
    "max_targets must be a positive integer")
  min(n,max_targets)
}

.etr_fpcr_plot_intervals <- function(ids,center,lower,upper,
    max_targets,reference=NULL,operation,title,ylabel) {
  ids<-.etr_frame_ids(ids,"target_curve_ids")
  n<-length(ids)
  for(nm in c("center","lower","upper"))
    .etr_frame_vector(get(nm),n,nm)
  if(!is.null(reference)).etr_frame_vector(reference,n,"reference")
  .etr_assert(all(lower<=center&center<=upper),
    "interval center must lie between lower and upper bounds")
  k<-.etr_fpcr_plot_count(max_targets,n)
  take<-seq_len(k);x<-as.integer(take-1L)
  geometry<-data.frame(x=x,curve_id=ids[take],
    center=center[take],lower=lower[take],upper=upper[take],
    stringsAsFactors=FALSE)
  if(!is.null(reference))geometry$reference<-reference[take]
  limits<-range(c(geometry$lower,geometry$upper,
    if(!is.null(reference))geometry$reference))
  if(diff(limits)==0)limits<-limits+c(-.5,.5)
  graphics::plot(x,geometry$center,type="p",pch=16,ylim=limits,
    xaxt="n",xlab="Fixed target trajectory",ylab=ylabel,main=title)
  # Zero-width intervals are valid geometry but should not create
  # base R zero-length arrows, which issue a graphics warning.
  nonzero<-which(geometry$upper>geometry$lower)
  if(length(nonzero))graphics::arrows(
    geometry$x[nonzero],geometry$lower[nonzero],
    geometry$x[nonzero],geometry$upper[nonzero],
    code=3,angle=90,length=.05)
  if(!is.null(reference))graphics::points(x,geometry$reference,pch=4)
  graphics::axis(1,at=x,labels=geometry$curve_id,las=2)
  graphics::legend("topright",legend=c(
    if(!is.null(reference))"full-sample conditional mean",
    if(identical(operation,"plot_fpca_wild_bootstrap_projection"))
      "studentized wild-bootstrap interval" else
    if(identical(operation,"plot_fpca_regression_future_prediction_interval"))
      "future-outcome predictive interval" else
      "bootstrap median + conditional-mean envelope"),
    pch=c(if(!is.null(reference))4,16),bty="n")
  invisible(list(geometry=geometry,
    provenance=list(backend="base_R",source_operation=operation,
      source_x_zero_based=TRUE,python_axes_return_equivalence=FALSE)))
}

#' Plot fixed-target wild-bootstrap FPCR projection intervals natively
#' @param result Explicit source-compatible result with target IDs and bounds.
#' @param max_targets Positive integer number of fixed targets to display.
#' @return Invisible numerical source geometry and backend provenance.
#' @export
etr_plot_fpca_wild_bootstrap_projection <- function(result,max_targets=30L){
  .etr_frame_record(result,c("target_curve_ids",
    "reference_projection","lower","upper"),"result")
  .etr_fpcr_plot_intervals(result$target_curve_ids,
    result$reference_projection,result$lower,result$upper,max_targets,
    operation="plot_fpca_wild_bootstrap_projection",
    title="Heteroscedastic Gaussian FPCR projection inference",
    ylabel="Centered FPCR projection")
}

#' Plot fixed-target future-outcome FPCR predictive intervals natively
#' @param result Source-compatible predictive result with uncertainty and bounds.
#' @param max_targets Positive integer number of fixed targets.
#' @return Invisible interval and conditional-mean numerical geometry.
#' @export
etr_plot_fpca_regression_future_prediction_interval <- function(
    result,max_targets=30L){
  .etr_frame_record(result,c("regression_uncertainty",
    "median","lower","upper"),"result")
  base<-result$regression_uncertainty
  .etr_frame_record(base,c("target_curve_ids",
    "reference_mean_predictions"),"result$regression_uncertainty")
  .etr_fpcr_plot_intervals(base$target_curve_ids,
    result$median,result$lower,result$upper,max_targets,
    reference=base$reference_mean_predictions,
    operation="plot_fpca_regression_future_prediction_interval",
    title="Gaussian FPCR future-outcome prediction",ylabel="Scalar response")
}

#' Plot conditional mean FPCR uncertainty for fixed targets natively
#' @param result Explicit source-compatible regression uncertainty record.
#' @param max_targets Positive integer number of fixed targets.
#' @return Invisible source interval and reference-mean numerical geometry.
#' @export
etr_plot_fpca_regression_mean_prediction_uncertainty <- function(
    result,max_targets=30L){
  .etr_frame_record(result,c("target_curve_ids","prediction_median",
    "prediction_lower","prediction_upper",
    "reference_mean_predictions"),"result")
  .etr_fpcr_plot_intervals(result$target_curve_ids,
    result$prediction_median,result$prediction_lower,
    result$prediction_upper,max_targets,
    reference=result$reference_mean_predictions,
    operation="plot_fpca_regression_mean_prediction_uncertainty",
    title="FPCR conditional-mean uncertainty",ylabel="Conditional mean response")
}

.etr_fpcr_plot_slope <- function(uncertainty,lower,upper,
    dimension,operation,title,scope,level) {
  .etr_frame_record(uncertainty,c("reference_fpca","reference_slope"),
    "regression uncertainty")
  fpca<-uncertainty$reference_fpca
  .etr_frame_record(fpca,c("time","time_unit","dimension_names"),"reference_fpca")
  ids<-.etr_frame_ids(fpca$dimension_names,"dimension_names")
  time<-.etr_frame_time(fpca$time)
  .etr_assert(is.character(fpca$time_unit)&&
    length(fpca$time_unit)==1L&&
    !is.na(fpca$time_unit)&&nzchar(fpca$time_unit),
    "reference_fpca time_unit must be a nonempty string")
  if(is.null(dimension))dimension<-ids[[1L]]
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    !is.na(dimension)&&dimension%in%ids,"Unknown dimension")
  j<-match(dimension,ids);nt<-length(time);nd<-length(ids)
  for(nm in c("lower","upper"))
    .etr_frame_matrix(get(nm),nt,nd,nm)
  .etr_frame_matrix(uncertainty$reference_slope,nt,nd,"reference_slope")
  .etr_assert(is.numeric(level)&&length(level)==1L&&
    is.finite(level)&&level>0&&level<1,"confidence level must lie in (0,1)")
  .etr_assert(all(lower[,j]<=uncertainty$reference_slope[,j])&&
    all(uncertainty$reference_slope[,j]<=upper[,j]),
    "reference slope must lie inside supplied diagnostic bounds")
  geometry<-data.frame(time=time,
    reference=uncertainty$reference_slope[,j],
    lower=lower[,j],upper=upper[,j])
  limits<-range(c(0,geometry$lower,geometry$upper))
  if(diff(limits)==0)limits<-limits+c(-.5,.5)
  graphics::plot(time,geometry$reference,type="n",
    ylim=limits,xlab=paste0("Time (",fpca$time_unit,")"),
    ylab=paste0("Slope for ",dimension),main=title)
  graphics::polygon(c(time,rev(time)),
    c(geometry$lower,rev(geometry$upper)),
    col=grDevices::adjustcolor("gray",alpha.f=.2),border=NA)
  graphics::lines(time,geometry$reference)
  graphics::abline(h=0,lty=2)
  graphics::legend("topright",legend=c(
    sprintf("%.1f%% %s",100*level,scope),
    "full-sample FPCR slope"),fill=c("gray",NA),
    lty=c(NA,1),bty="n")
  invisible(list(dimension=dimension,geometry=geometry,
    confidence_level=level,scope=scope,
    provenance=list(backend="base_R",source_operation=operation,
      python_axes_return_equivalence=FALSE)))
}

#' Plot source-aligned observed-grid simultaneous FPCR slope band
#' @param result Explicit slope band record with regression_uncertainty.
#' @param dimension Optional declared channel name.
#' @return Invisible numeric time, slope and band geometry.
#' @export
etr_plot_fpca_regression_slope_band <- function(result,dimension=NULL) {
  .etr_frame_record(result,c("regression_uncertainty","lower","upper",
    "confidence_level","simultaneous_scope"),"result")
  .etr_fpcr_plot_slope(result$regression_uncertainty,
    result$lower,result$upper,dimension,
    operation="plot_fpca_regression_slope_band",
    title="Gaussian FPCR simultaneous slope band",
    scope=paste0("observed-grid ",result$simultaneous_scope," band"),
    level=result$confidence_level)
}

#' Plot source-aligned pointwise bootstrap FPCR slope uncertainty
#' @param result Explicit regression uncertainty record with slope bounds.
#' @param dimension Optional declared channel name.
#' @return Invisible numerical source slope/percentile envelope.
#' @export
etr_plot_fpca_regression_slope_uncertainty <- function(result,dimension=NULL) {
  .etr_frame_record(result,c("slope_lower","slope_upper","level"),"result")
  .etr_fpcr_plot_slope(result,
    result$slope_lower,result$slope_upper,dimension,
    operation="plot_fpca_regression_slope_uncertainty",
    title="Gaussian FPCR slope uncertainty",
    scope="pointwise percentile envelope",level=result$level)
}

#' Plot sparse PACE per-curve score-system condition diagnostics natively
#' @param result Explicit sparse FPCA source record with score_diagnostics.
#' @return Invisible exact source finite/ok/flagged masks and scatter data.
#' @export
etr_plot_sparse_fpca_score_diagnostics <- function(result) {
  .etr_frame_record(result,"score_diagnostics","result")
  f<-result$score_diagnostics
  .etr_assert(is.data.frame(f)&&nrow(f)>0L&&
    all(c("n_samples","condition_number","status_code")%in%names(f)),
    "result does not contain complete PACE score diagnostics")
  .etr_assert(is.numeric(f$n_samples)&&!anyNA(f$n_samples)&&
    all(is.finite(f$n_samples))&&all(f$n_samples>=0),
    "n_samples must be finite and nonnegative")
  .etr_assert(is.numeric(f$condition_number)&&
    is.character(f$status_code)&&!anyNA(f$status_code),
    "condition_number and status_code must be numeric and strings")
  finite<-is.finite(f$condition_number)&f$condition_number>0
  .etr_assert(any(finite),
    "score diagnostics do not contain positive finite condition numbers")
  ok<-finite&(f$status_code=="ok")
  failed<-finite&(f$status_code!="ok")
  plot_data<-data.frame(n_samples=as.numeric(f$n_samples),
    condition_number=as.numeric(f$condition_number),
    status_code=f$status_code,finite=finite,ok=ok,
    flagged=failed,stringsAsFactors=FALSE)
  xrange<-range(plot_data$n_samples[finite])
  if(diff(xrange)==0)xrange<-xrange+c(-.5,.5)
  graphics::plot(plot_data$n_samples[finite],
    plot_data$condition_number[finite],type="n",log="y",
    xlim=xrange,xlab="Observed samples used for PACE score",
    ylab="Conditional covariance condition number",
    main="Sparse PACE score-system conditioning")
  if(any(ok))graphics::points(plot_data$n_samples[ok],
    plot_data$condition_number[ok],pch=16)
  if(any(failed))graphics::points(plot_data$n_samples[failed],
    plot_data$condition_number[failed],pch=4)
  if(any(failed))graphics::legend("topright",
    legend=c(if(any(ok))"score system ok",
      "flagged/failed score system"),
    pch=c(if(any(ok))16,4),bty="n")
  invisible(list(geometry=plot_data,
    provenance=list(backend="base_R",log_y=TRUE,
      source_operation="plot_sparse_fpca_score_diagnostics",
      python_axes_return_equivalence=FALSE)))
}
