# Stable scientific names; no stage-numbered public or internal helpers.
# Source benchmark: published eyetrajectoriespy==1.2.0 reporting.py,
# plotting.py, nonlinear_plotting.py and mixed-effect diagnostics.

.etr_choose_named_component <- function(names,coefficient) {
  .etr_assert(is.character(names)&&length(names)>=1L&&
    !anyNA(names)&&!anyDuplicated(names),
    "fitted coefficient identities must be unique")
  if(is.character(coefficient)) {
    .etr_assert(length(coefficient)==1L&&!is.na(coefficient)&&
      coefficient%in%names,
      "coefficient must identify an existing fitted coefficient")
    return(match(coefficient,names))
  }
  .etr_assert(is.numeric(coefficient)&&length(coefficient)==1L&&
    !is.logical(coefficient)&&is.finite(coefficient)&&
    coefficient==as.integer(coefficient)&&coefficient>=0L&&
    coefficient<length(names),
    "coefficient must be a valid zero-based integer or exact name")
  as.integer(coefficient)+1L
}
.etr_valid_report_fields <- function(text,label) {
  .etr_assert(is.character(text)&&length(text)>=1L&&
    all(!is.na(text)&nzchar(text)),paste(label,"must be nonempty text"))
  invisible(text)
}
.etr_native_fos_geometry <- function(result,coefficient,dimension,band) {
  .etr_function_scalar_result_check(result)
  k<-.etr_choose_named_component(result$coefficient_names,coefficient)
  if(is.null(dimension))dimension<-result$dimension_names[1L]
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    !is.na(dimension)&&dimension%in%result$dimension_names,
    "dimension must identify a source FOS functional channel")
  j<-match(dimension,result$dimension_names)
  nt<-length(result$time)
  estimate<-as.numeric(result$coefficients[k,,j])
  .etr_assert(length(estimate)==nt&&all(is.finite(estimate)),
    "FOS coefficient values must be finite observed-grid estimates")
  if(is.null(band))return(list(
    time=result$time,estimate=estimate,
    lower=NULL,upper=NULL,coefficient=result$coefficient_names[k],
    dimension=dimension,band=NULL))
  .etr_assert(inherits(band,"etr_function_on_scalar_band")&&
    identical(band$reference,result)&&
    identical(dim(band$lower),dim(result$coefficients))&&
    identical(dim(band$upper),dim(result$coefficients)),
    "FOS band must correspond to the exact source fit and grid")
  lower<-as.numeric(band$lower[k,,j]);upper<-as.numeric(band$upper[k,,j])
  .etr_assert(length(lower)==nt&&length(upper)==nt&&
    all(is.finite(c(lower,upper)))&&
    all(lower<=estimate&estimate<=upper),
    "FOS simultaneous band endpoints must contain the coefficient estimate")
  list(time=result$time,estimate=estimate,lower=lower,upper=upper,
    coefficient=result$coefficient_names[k],dimension=dimension,
    band=band)
}

#' Plot one source function-on-scalar fixed coefficient and optional band
#' @param result Native observed-grid function-on-scalar fit.
#' @param coefficient Source zero-based fitted coefficient index or exact name.
#' @param dimension Named functional channel, default first.
#' @param band Optional corresponding native simultaneous-band result.
#' @param ... Base graphics options.
#' @return Invisible observed-grid estimate and optional simultaneous bounds.
#' @export
etr_plot_function_on_scalar_coefficients <- function(result,coefficient,
    dimension=NULL,band=NULL,strict_source_record=FALSE,...) {
  .etr_fpca_uncertainty_strict(strict_source_record)
  if(isTRUE(strict_source_record)&&inherits(result,"etr_function_on_scalar_band")) {
    .etr_assert(is.null(band),
      "source band result cannot be combined with a second band")
    band<-result
    result<-band$reference
  }
  g<-.etr_native_fos_geometry(result,coefficient,dimension,band)
  yrange<-range(c(g$estimate,g$lower,g$upper,0))
  graphics::plot(g$time,g$estimate,type="n",ylim=yrange,
    xlab=sprintf("Time (%s)",result$time_unit),
    ylab=sprintf("Coefficient: %s",g$dimension),
    main=sprintf("Function-on-scalar coefficient: %s",g$coefficient),...)
  if(!is.null(g$lower))graphics::polygon(c(g$time,rev(g$time)),
    c(g$lower,rev(g$upper)),border=NA,
    col=grDevices::adjustcolor("grey60",alpha.f=.25))
  graphics::lines(g$time,g$estimate,lwd=2)
  graphics::abline(h=0,lty=2)
  if(isTRUE(strict_source_record))
    return(invisible(.etr_fos_coefficients_source_artist(result,g)))
  invisible(g[c("time","estimate","lower","upper","coefficient","dimension")])
}

#' Published Python 1.2 source-aligned function-on-scalar text
#' @param result Native function-on-scalar regression.
#' @param band Corresponding native bootstrap band, if any.
#' @return Manuscript-ready limited observational-grid model statement.
#' @export
etr_function_on_scalar_reporting_text <- function(result,band=NULL) {
  .etr_function_scalar_result_check(result)
  .etr_valid_report_fields(result$predictor_names,"predictors")
  .etr_valid_report_fields(result$dimension_names,"dimensions")
  .etr_assert(result$unit%in%c("curve","participant")&&
    length(result$unit_ids)>=1L,
    "FOS inference units must be declared")
  units<-if(result$unit=="participant")
    paste0(length(result$unit_ids),
      " participant-average functional responses from ",
      length(result$source_curve_ids),
      " source curves; declared predictors were required to be constant within participant")
  else paste0(length(result$unit_ids),
      " curve-level functional responses treated as independent inference units")
  suffix<-""
  if(!is.null(band)){
    .etr_assert(inherits(band,"etr_function_on_scalar_band")&&
      identical(band$reference,result)&&
      is.list(band$bootstrap)&&
      is.array(band$bootstrap$bootstrap_coefficients)&&
      length(dim(band$bootstrap$bootstrap_coefficients))==4L&&
      dim(band$bootstrap$bootstrap_coefficients)[1L]>=1L&&
      is.character(band$bootstrap$multiplier)&&
      length(band$bootstrap$multiplier)==1L,
      "band.reference and bootstrap metadata must match source FOS model")
    n_bootstrap<-dim(band$bootstrap$bootstrap_coefficients)[1L]
    suffix<-sprintf(
      " Wild-bootstrap %.1f%% simultaneous coefficient bands were calibrated with %s %s multiplier replicates using %s-scope maxima over the observed grid.",
      100*band$confidence_level,as.integer(n_bootstrap),
      band$bootstrap$multiplier,band$simultaneous_scope)
  }
  paste0(
    "Function-on-scalar regression was fitted by ordinary least squares ",
    "independently at each observed time-by-dimension grid point with a ",
    "shared design matrix (predictors: ",
    paste(result$predictor_names,collapse=", "),
    "; functional dimensions: ",paste(result$dimension_names,collapse=", "),
    "). Inference used ",units,". ",
    "Pointwise standard errors used the HC1 sandwich estimator. No ",
    "functional smoothing, basis regularization, automatic categorical ",
    "encoding, predictor scaling, interaction construction, or model ",
    "selection was performed.",
    suffix,
    " The model is not a functional mixed-effects model, and any ",
    "simultaneous-band claim applies to the observed grid rather than ",
    "unsampled times.")
}

#' Show the reported restricted functional mixed-effects coefficient
#' @param result Native mixed-moments fitted model.
#' @param coefficient Source zero-based or exact fixed coefficient identity.
#' @param ... Base R graphics arguments.
#' @return Invisible pointwise 95 percent Wald numerical geometry.
#' @export
etr_plot_functional_mixed_effects_coefficient <- function(result,coefficient,...) {
  .etr_mixed_moments_fit(result)
  k<-.etr_choose_named_component(result$coefficient_names,coefficient)
  nt<-length(result$time)
  estimate<-as.numeric(result$coefficient_functions[k,])
  se<-as.numeric(result$coefficient_standard_errors[k,])
  .etr_assert(length(estimate)==nt&&length(se)==nt&&
    all(is.finite(c(estimate,se)))&&all(se>=0),
    "mixed-moments fitted coefficient and Wald standard errors must be finite")
  z<-1.959963984540054
  lower<-estimate-z*se;upper<-estimate+z*se
  graphics::plot(result$time,estimate,type="n",
    xlab=sprintf("Time (%s)",result$time_unit),
    ylab=sprintf("Coefficient: %s",result$dimension_name),
    main=paste("Functional mixed-effects coefficient:",
      result$coefficient_names[k]),
    ylim=range(c(lower,upper,0)),...)
  graphics::polygon(c(result$time,rev(result$time)),
    c(lower,rev(upper)),border=NA,
    col=grDevices::adjustcolor("grey60",alpha.f=.25))
  graphics::lines(result$time,estimate,lwd=2)
  graphics::abline(h=0,lty=2)
  invisible(data.frame(time=result$time,estimate=estimate,
    lower=lower,upper=upper,coefficient=result$coefficient_names[k],
    interval_type="pointwise_95_Wald_not_simultaneous"))
}

.etr_conformal_review <- function(result) {
  # The existing native split-conformal screen stores calibration scores
  # but not fitted source component count. Do not silently manufacture it.
  .etr_assert(is.list(result)&&is.data.frame(result$test)&&
    is.data.frame(result$calibration)&&is.list(result$cutoff)&&
    all(c("curve_id","score")%in%names(result$test))&&
    all(c("curve_id","score")%in%names(result$calibration)),
    "requires a native split-conformal FPCA anomaly-screen result")
  cal<-as.numeric(result$calibration$score)
  targets<-as.numeric(result$test$score)
  alpha<-result$cutoff$alpha
  .etr_assert(length(cal)>=1L&&length(targets)>=1L&&
    all(is.finite(cal))&&all(cal>=0)&&
    all(is.finite(targets))&&all(targets>=0)&&
    is.numeric(alpha)&&length(alpha)==1L&&is.finite(alpha)&&
    alpha>0&&alpha<1&&
    all(!is.na(result$test$curve_id))&&
    !anyDuplicated(result$test$curve_id),
    "native conformal calibration and target scores must be valid")
  p<-vapply(targets,function(x)
    (1+sum(cal>=x))/(length(cal)+1),numeric(1L))
  flags<-p<=alpha
  if("is_anomaly"%in%names(result$test)) {
    supplied<-result$test$is_anomaly
    .etr_assert(is.logical(supplied)&&length(supplied)==length(flags)&&
      !anyNA(supplied)&&identical(as.logical(supplied),as.logical(flags)),
      "native conformal flags disagree with conservative calibrated p-values")
  }
  list(alpha=alpha,curve_ids=as.character(result$test$curve_id),
    p_values=p,n_calibration=length(cal),
    flags=flags)
}

#' Plot marginal split-conformal p-values from the native FPCA screen
#' @param result Native split-conformal FPCA output.
#' @param max_targets Maximum target trajectories to plot.
#' @param ... Base R graphics arguments.
#' @return Invisible exact reconstructed conservative marginal p-values.
#' @export
etr_plot_conformal_fpca_anomaly <- function(result,max_targets=50L,
    strict_source_record=FALSE,...) {
  .etr_fpca_uncertainty_strict(strict_source_record)
  if(isTRUE(strict_source_record)) {
    .etr_assert(is.integer(max_targets)&&length(max_targets)==1L&&
      !is.na(max_targets)&&max_targets>=1L,
      "strict source max_targets must be a positive integer")
    coords<-.etr_conformal_source_pvalue_frame(result,max_targets)
    graphics::plot(coords$target_index,coords$p_value,pch=1,
      ylim=c(0,1),xaxt="n",xlab="Target trajectory",
      ylab="Marginal conformal p-value",
      main="Split-conformal FPCA anomaly review",...)
    graphics::axis(1,at=coords$target_index,labels=coords$curve_id,las=2)
    graphics::abline(h=result$alpha,lty=2)
    graphics::legend("topright",legend=paste0("alpha=",
      format(result$alpha,scientific=FALSE,trim=TRUE)),lty=2,bty="n")
    return(invisible(.etr_conformal_pvalue_source_artist(result,coords)))
  }
  a<-.etr_conformal_review(result)
  .etr_assert(is.numeric(max_targets)&&length(max_targets)==1L&&
    !is.logical(max_targets)&&is.finite(max_targets)&&
    max_targets==as.integer(max_targets)&&max_targets>=1L,
    "max_targets must be a positive integer")
  n<-min(as.integer(max_targets),length(a$p_values))
  coords<-data.frame(curve_id=a$curve_ids[seq_len(n)],
    target_index=seq_len(n)-1L,p_value=a$p_values[seq_len(n)],
    stringsAsFactors=FALSE)
  graphics::plot(coords$target_index,coords$p_value,pch=1,
    ylim=c(0,1),xaxt="n",
    xlab="Target trajectory",ylab="Marginal conformal p-value",
    main="Split-conformal FPCA anomaly review",...)
  graphics::axis(1,at=coords$target_index,labels=coords$curve_id,las=2)
  graphics::abline(h=a$alpha,lty=2)
  invisible(coords)
}

#' Source-aligned marginal anomaly reporting from native conformal scores
#' @param result Native conformal result, either the source-field semantic
#'   record or an older native split-conformal calibration/test score record.
#' @param n_components Optional fitted FPCA component count; source-field
#'   records carry this themselves. Older native records must supply it.
#' @param digits Printed decimal places (native supported domain 0 to 12).
#' @return Conservative statement with explicit marginal interpretation.
#' @export
etr_conformal_fpca_anomaly_reporting_text <- function(result,
    n_components=NULL,digits=3L) {
  .etr_assert(is.list(result),"result must be a native conformal record")
  source_record<-all(c("calibration_scores","target_scores",
    "review_flags","n_components","nonconformity")%in%names(result))
  if(source_record){
    .etr_assert(is.numeric(result$calibration_scores)&&
      length(result$calibration_scores)>=1L&&
      all(is.finite(result$calibration_scores))&&
      is.numeric(result$target_scores)&&
      length(result$target_scores)>=1L&&
      all(is.finite(result$target_scores)),
      "source conformal calibration_scores and target_scores must be finite")
    .etr_assert(is.logical(result$review_flags)&&
      length(result$review_flags)==length(result$target_scores)&&
      !anyNA(result$review_flags),
      "source conformal review_flags must align with targets")
    .etr_assert(is.numeric(result$alpha)&&length(result$alpha)==1L&&
      is.finite(result$alpha)&&result$alpha>0&&result$alpha<1,
      "source conformal alpha must be strictly between zero and one")
    .etr_assert(is.character(result$nonconformity)&&
      length(result$nonconformity)==1L&&
      !is.na(result$nonconformity)&&nzchar(result$nonconformity),
      "source conformal nonconformity must be declared")
    covariance<-result$mahalanobis_covariance
    .etr_assert(is.null(covariance)||
      (is.character(covariance)&&length(covariance)==1L&&
      !is.na(covariance)&&nzchar(covariance)),
      "source conformal mahalanobis_covariance must be declared or NULL")
    if(!is.null(n_components))
      .etr_assert(identical(as.integer(n_components),
        as.integer(result$n_components)),
        "n_components override disagrees with the fitted source result")
    n_components<-result$n_components
    a<-list(alpha=result$alpha,flags=result$review_flags,
      n_calibration=length(result$calibration_scores),
      n_targets=length(result$target_scores),
      nonconformity=result$nonconformity,covariance=covariance)
  } else {
    # Backward-compatible source-semantic projection for native screens
    # that predate the original Python result's stored FPCA metadata.
    a<-.etr_conformal_review(result)
    if(is.null(n_components))n_components<-result$n_components
    a$n_targets<-length(a$p_values)
    a$nonconformity<-"integrated_reconstruction_error"
    a$covariance<-NULL
  }
  .etr_assert(is.numeric(n_components)&&length(n_components)==1L&&
    !is.logical(n_components)&&is.finite(n_components)&&
    n_components==floor(n_components)&&n_components>=1L,
    "n_components must be explicitly supplied or retained by the source FPCA fit")
  .etr_assert(is.numeric(digits)&&length(digits)==1L&&
    !is.logical(digits)&&is.finite(digits)&&digits==floor(digits)&&
    digits>=0L&&digits<=12L,"digits must be an integer between 0 and 12")
  fmt<-function(x)sprintf(paste0("%.",as.integer(digits),"f"),x)
  covariance_text<-if(is.null(a$covariance))"" else
    paste0(" using ",a$covariance," score covariance")
  paste0(
    "Split-conformal functional anomaly review fitted an FPCA reference with ",
    as.integer(n_components)," component(s) on the proper-training set and used ",
    a$n_calibration," calibration trajectory(ies). Nonconformity was ",
    a$nonconformity,covariance_text,
    ". Marginal conformal p-values used the ",
    "conservative greater-than-or-equal tie rule; the minimum attainable ",
    "p-value was ",fmt(1/(a$n_calibration+1)),". At alpha=",
    fmt(a$alpha),", ",sum(a$flags)," of ",a$n_targets,
    " target trajectory(ies) were flagged for review. Flags are not automatic ",
    "exclusions. The marginal conformal interpretation requires curve-level ",
    "exchangeability of inlier trajectories. No calibration-conditional ",
    "adjustment, multiple-testing correction, or FDR guarantee was applied.")
}

#' Population mean RQA bootstrap percentile interval graphic
#' @param result Native whole-unit RQA bootstrap result.
#' @param metrics Optional ordered subset of source RQA metrics.
#' @param ... Base R graphics arguments.
#' @return Invisible numeric mean/percentile interval source rows.
#' @export
etr_plot_rqa_metric_mean_bootstrap <- function(result,metrics=NULL,
    strict_source_record=FALSE,...) {
  .etr_fpca_uncertainty_strict(strict_source_record)
  .etr_assert(inherits(result,"etr_rqa_metric_bootstrap")&&
    is.data.frame(result$summary_table)&&
    all(c("metric","mean","lower","upper")%in%
      names(result$summary_table)),
    "requires a native whole-unit RQA metric bootstrap result")
  if(is.null(metrics))metrics<-result$metrics
  .etr_assert(is.character(metrics)&&length(metrics)>=1L&&
    all(!is.na(metrics)&nzchar(metrics))&&
    all(metrics%in%result$metrics),
    "metrics must be nonempty and registered in the source RQA bootstrap")
  frame<-result$summary_table[
    match(metrics,result$summary_table$metric),,drop=FALSE]
  .etr_assert(nrow(frame)==length(metrics)&&
    all(is.finite(frame$mean))&&all(is.finite(frame$lower))&&
    all(is.finite(frame$upper))&&
    all(frame$lower<=frame$mean&frame$mean<=frame$upper),
    "RQA bootstrap percentile limits must contain source means")
  x<-seq_along(metrics)-1L
  graphics::plot(x,frame$mean,pch=1,xaxt="n",
    ylim=range(c(frame$lower,frame$upper)),xlab="RQA metric",
    ylab="RQA metric",
    main=sprintf("RQA population mean (%s-level bootstrap)",result$unit),...)
  graphics::arrows(x,frame$lower,x,frame$upper,code=3,
    length=.04,angle=90)
  graphics::axis(1,at=x,labels=metrics,las=2)
  rownames(frame)<-NULL
  if(isTRUE(strict_source_record))
    return(invisible(.etr_rqa_mean_bootstrap_source_artist(
      result,metrics,frame)))
  invisible(frame)
}

#' Plot native method-of-moments functional variance decomposition
#' @param result Restricted native two-level functional mixed-moments model.
#' @param ... Base R graphics arguments.
#' @param model Model label, required for strict source sensitivity
#'   and prohibited for direct fitted Gaussian likelihood models.
#' @param strict_source_record Use the real native nlme Gaussian
#'   covariance components to return a source-scientific line geometry
#'   record. Never claim Python Matplotlib Axes identity.
#' @return Invisible complete time/component source frame.
#' @export
etr_plot_functional_variance_decomposition <- function(result,...,
    model=NULL,strict_source_record=FALSE) {
  .etr_mixed_artist_check(strict_source_record,result,"variance")
  if(isTRUE(strict_source_record))
    return(invisible(.etr_mixed_artist_variance(result,model=model)))
  .etr_assert(is.null(model),
    "model is only accepted with strict Gaussian source sensitivity")
  .etr_mixed_moments_fit(result)
  frame<-etr_functional_mixed_effects_variance_decomposition(result)
  .etr_assert(is.data.frame(frame)&&
    all(c("time","value","component")%in%names(frame))&&
    all(is.finite(frame$time))&&all(is.finite(frame$value)),
    "functional variance decomposition contains invalid source rows")
  graphics::plot(NA_real_,NA_real_,
    xlim=range(frame$time),ylim=range(c(frame$value,0)),
    xlab=sprintf("Time (%s)",result$time_unit),
    ylab="Variance / cross-covariance",
    main="Functional variance decomposition: model",...)
  for(i in unique(frame$component)){
    t<-frame[frame$component==i,,drop=FALSE]
    graphics::lines(t$time,t$value,
      col=match(i,unique(frame$component)))
  }
  graphics::abline(h=0)
  invisible(frame)
}
