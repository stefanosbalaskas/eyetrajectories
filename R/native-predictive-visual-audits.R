# Read-only native diagnostic plots pinned to published Python 1.2.0
# src/eyetrajectoriespy/plotting.py, frozen source
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Plots are Python-independent R base graphics; return numeric audit geometry.

.etr_diagnostic_plot_numeric <- function(x,what) {
  .etr_assert(is.numeric(x)&&length(x)>0L&&!anyNA(x)&&
    all(is.finite(x)),paste0(what," must be finite numeric"))
  as.numeric(x)
}
.etr_diagnostic_plot_range <- function(y) {
  limits<-range(y)
  if(diff(limits)==0)limits<-limits+c(-.5,.5)
  limits
}

#' Native predictive FPCA cross-validation loss diagnostic
#' @param result Explicit source-compatible record with fold_losses
#'   data frame and declared family/loss.
#' @return Invisible source-aligned mean, sample SD, SE and plot geometry.
#' @details Source pandas groupby uses sample SD (ddof=1), setting the
#'   single-fold SD to zero. No model selection is performed.
#' @export
etr_plot_fpca_regression_cv <- function(result) {
  .etr_frame_record(result,c("fold_losses","loss","family"),"result")
  frame<-result$fold_losses
  .etr_assert(is.data.frame(frame)&&
    all(c("n_components","loss")%in%names(frame))&&nrow(frame)>=1L,
    "fold_losses must be a nonempty data frame with n_components and loss")
  h<-frame$n_components;y<-.etr_diagnostic_plot_numeric(frame$loss,"fold loss")
  .etr_assert(is.numeric(h)&&length(h)==length(y)&&
    all(is.finite(h))&&all(h>=1)&&all(h==floor(h)),
    "n_components must be positive integer-valued")
  .etr_assert(is.character(result$loss)&&length(result$loss)==1L&&
    !is.na(result$loss)&&nzchar(result$loss)&&
    is.character(result$family)&&length(result$family)==1L&&
    !is.na(result$family)&&nzchar(result$family),
    "loss and family must be nonempty strings")
  candidates<-sort(unique(h))
  counts<-vapply(candidates,function(k)sum(h==k),integer(1L))
  means<-vapply(candidates,function(k)mean(y[h==k]),numeric(1L))
  sd<-vapply(candidates,function(k)
    if(sum(h==k)==1L)0 else stats::sd(y[h==k]),numeric(1L))
  summary<-data.frame(n_components=as.integer(candidates),
    mean_loss=means,sd_loss=sd,n_folds=counts,
    se_loss=sd/sqrt(counts))
  yr<-.etr_diagnostic_plot_range(c(means-summary$se_loss,
    means+summary$se_loss))
  graphics::plot(candidates,means,type="b",pch=16,ylim=yr,
    xlab="Retained functional principal components",
    ylab=paste0("Held-out ",result$loss),
    main=paste0("Predictive FPCA regression CV (",result$family,")"))
  # A single-fold group has zero source SE; base R arrows on a zero
  # segment may warn. Preserve zero-width bounds in returned geometry.
  nonzero<-which(summary$se_loss>0)
  if(length(nonzero))graphics::arrows(candidates[nonzero],
    means[nonzero]-summary$se_loss[nonzero],candidates[nonzero],
    means[nonzero]+summary$se_loss[nonzero],angle=90,code=3,length=.05)
  invisible(list(summary=summary,
    line=data.frame(x=candidates,y=means),
    errorbar=data.frame(x=candidates,
      lower=means-summary$se_loss,upper=means+summary$se_loss),
    provenance=list(backend="base_R",variance_ddof=1L,
      source_operation="plot_fpca_regression_cv",
      python_axes_return_equivalence=FALSE)))
}

#' Native nested predictive FPCA regression held-out loss diagnostic
#' @param result Explicit nested CV record with outer_folds and loss.
#' @return Invisible source-aligned outer-fold line geometry.
#' @export
etr_plot_nested_fpca_regression_cv <- function(result) {
  .etr_frame_record(result,c("outer_folds","loss"),"result")
  f<-result$outer_folds
  .etr_assert(is.data.frame(f)&&
    all(c("outer_fold","loss")%in%names(f))&&nrow(f)>=1L,
    "outer_folds must have outer_fold and loss columns")
  x<-.etr_diagnostic_plot_numeric(f$outer_fold,"outer fold")
  y<-.etr_diagnostic_plot_numeric(f$loss,"outer fold loss")
  .etr_assert(all(x>=0)&&all(x==floor(x)),
    "outer_fold must be a nonnegative integer index")
  .etr_assert(is.character(result$loss)&&length(result$loss)==1L&&
    !is.na(result$loss)&&nzchar(result$loss),
    "loss must be a nonempty string")
  x<-x+1
  graphics::plot(x,y,type="b",pch=16,
    xlab="Outer fold",ylab=paste0("Outer held-out ",result$loss),
    main="Nested predictive FPCA regression",
    ylim=.etr_diagnostic_plot_range(y))
  invisible(list(line=data.frame(x=x,y=y),
    provenance=list(backend="base_R",
      source_operation="plot_nested_fpca_regression_cv",
      python_axes_return_equivalence=FALSE)))
}

#' Native full-refit versus fixed-covariance bootstrap sensitivity plot
#' @param comparison Explicit R data frame with coefficient,time,band-width ratio.
#' @param coefficient Nonempty selected coefficient name.
#' @return Invisible source-aligned sorted ratio line and identity baseline.
#' @export
etr_plot_functional_mixed_effects_bootstrap_comparison <- function(
    comparison,coefficient) {
  cols<-c("coefficient","time",
    "full_refit_to_fixed_covariance_width_ratio")
  .etr_assert(is.data.frame(comparison)&&
    all(cols%in%names(comparison)),
    "comparison must have coefficient, time and full_refit_to_fixed_covariance_width_ratio")
  .etr_assert(is.character(coefficient)&&length(coefficient)==1L&&
    !is.na(coefficient)&&nzchar(coefficient),
    "coefficient must be a nonempty string")
  .etr_assert(is.character(comparison$coefficient)&&
    !anyNA(comparison$coefficient),
    "comparison coefficient must be a nonmissing character vector")
  f<-comparison[comparison$coefficient==coefficient,,drop=FALSE]
  .etr_assert(nrow(f)>0L,"Unknown coefficient")
  f<-f[order(f$time,method="radix"),,drop=FALSE]
  x<-.etr_diagnostic_plot_numeric(f$time,"selected time")
  y<-.etr_diagnostic_plot_numeric(
    f$full_refit_to_fixed_covariance_width_ratio,
    "bootstrap band-width ratio")
  graphics::plot(x,y,type="l",
    xlab="Time",ylab="Full-refit / fixed-covariance band width",
    main=paste0("Mixed-effects bootstrap sensitivity: ",coefficient),
    ylim=.etr_diagnostic_plot_range(c(1,y)))
  graphics::abline(h=1,lty=2)
  invisible(list(coefficient=coefficient,line=data.frame(x=x,y=y),
    identity_baseline=1,
    provenance=list(backend="base_R",
      source_operation="plot_functional_mixed_effects_bootstrap_comparison",
      python_axes_return_equivalence=FALSE)))
}

#' Native FPCA wild-bootstrap truncation scan interval-width or center plot
#' @param result Explicit native scan record or selection record with $scan.
#' @param target One-based native target index or recorded curve identifier.
#' @param metric Either width or center.
#' @return Invisible source-line geometry with optional selected h.
#' @details Source Python numeric target indices are zero-based; native R
#'   numeric indices are one-based. No automatic truncation selection occurs.
#' @export
etr_plot_fpca_wild_bootstrap_truncation_scan <- function(result,
    target=1L,metric="width") {
  .etr_assert(is.list(result),"result must be an explicit native scan or selection record")
  selection<-if(!is.null(result$scan))result else NULL
  scan<-if(is.null(selection))result else result$scan
  .etr_frame_record(scan,c("candidate_components","target_curve_ids",
    "widths","centers"),"scan")
  ids<-.etr_frame_ids(scan$target_curve_ids,"target_curve_ids")
  h<-scan$candidate_components
  .etr_assert(is.numeric(h)&&length(h)>=1L&&
    all(is.finite(h))&&all(h>=1)&&
    all(h==floor(h))&&!anyDuplicated(h),
    "candidate_components must be distinct positive integer values")
  .etr_frame_matrix(scan$widths,length(h),length(ids),"scan$widths")
  .etr_frame_matrix(scan$centers,length(h),length(ids),"scan$centers")
  k<-.etr_simulation_plot_index(target,length(ids),ids,"target")
  .etr_assert(is.character(metric)&&length(metric)==1L&&
    !is.na(metric)&&metric%in%c("width","center"),
    "metric must be width or center")
  y<-as.numeric(scan[[if(metric=="width")"widths" else "centers"]][,k])
  selected<-NA_integer_
  if(!is.null(selection)){
    .etr_assert(is.numeric(selection$selected_components)&&
      length(selection$selected_components)==length(ids),
      "selected_components must match source target count")
    value<-selection$selected_components[k]
    .etr_assert(is.na(value)||(is.finite(value)&&value>=1&&
      value==floor(value)),
      "selected component must be NA or a positive integer")
    if(!is.na(value))selected<-as.integer(value)
  }
  yr<-.etr_diagnostic_plot_range(y)
  graphics::plot(h,y,type="b",pch=16,
    xlab="Inference truncation h",
    ylab=if(metric=="width")"Interval width" else "Interval center",
    main=paste0("Wild-bootstrap truncation scan: ",ids[k]),ylim=yr)
  if(!is.na(selected)){
    graphics::abline(v=selected,lty=2)
    graphics::legend("topright",
      legend=paste0("selected h=",selected),lty=2,bty="n")
  }
  invisible(list(target_curve_id=ids[k],metric=metric,
    line=data.frame(x=as.integer(h),y=y),
    selected_inference_components=selected,
    provenance=list(backend="base_R",
      source_operation="plot_fpca_wild_bootstrap_truncation_scan",
      python_axes_return_equivalence=FALSE,
      python_numeric_target_index_parity=FALSE)))
}
