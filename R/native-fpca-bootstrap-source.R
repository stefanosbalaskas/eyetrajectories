# Stage 27: seven Python-free source-aligned FPCA bootstrap reporting/plots.
# Reporting and plotted source geometry are narrower than complete Python
# public source contracts. No estimator is recomputed or certified here.
.etr_reporting_digits <- function(digits) {
  .etr_assert(is.numeric(digits)&&length(digits)==1L&&
    !is.logical(digits)&&is.finite(digits)&&
    digits==as.integer(digits)&&digits>=0L&&digits<=12L,
    "digits must be an integer between 0 and 12")
  as.integer(digits)
}
.etr_format_report_decimal <- function(x,digits) sprintf(paste0("%.",digits,"f"),x)

# Match Python repr() of supported scalar provenance labels, including
# apostrophes, double quotes, escapes and non-ASCII scientific descriptions.
.etr_fpca_source_py_repr <- function(x) {
  .etr_assert(is.character(x) && length(x)==1L && !is.na(x),
    "provenance label must be one nonmissing text value")
  quote<-if(grepl("'",x,fixed=TRUE) && !grepl('"',x,fixed=TRUE))
    '"' else "'"
  encodeString(x,quote=quote)
}
.etr_fpca_matched_similarities <- function(result,kind) {
  .etr_assert(inherits(result,kind)&&
    is.matrix(result$similarities)&&
    is.numeric(result$similarities)&&
    nrow(result$similarities)>=1L&&ncol(result$similarities)>=1L&&
    all(is.finite(result$similarities))&&
    all(result$similarities>=0&result$similarities<=1),
    paste("result must have finite matched bootstrap similarities for",kind))
  result$similarities
}
.etr_fpca_similarity_medians_text <- function(x,digits) {
  s<-apply(x,2L,stats::median)
  paste(paste0("FPC",seq_along(s),"=",.etr_format_report_decimal(s,digits)),
    collapse=", ")
}
.etr_validate_positive_component_count <- function(x,kind) {
  .etr_assert(is.numeric(x)&&length(x)==1L&&
    is.finite(x)&&x==as.integer(x)&&x>0L,
    paste(kind,"must be positive integer"))
  as.integer(x)
}

#' Exact-source-wording matched-bootstrap FPCA score uncertainty description
#' @param result Native bootstrapped FPCA target-score result.
#' @param digits Numeric printing precision.
#' @return Single descriptive manuscript string.
#' @export
etr_fpca_score_uncertainty_reporting_text <- function(result,digits=3L) {
  digits<-.etr_reporting_digits(digits)
  sims<-.etr_fpca_matched_similarities(result,"etr_fpca_score_uncertainty")
  .etr_assert(is.matrix(result$median)&&
    ncol(result$median)==ncol(sims)&&
    nrow(result$median)==length(result$target_curve_ids)&&
    is.numeric(result$level)&&length(result$level)==1L&&
    is.finite(result$level)&&result$level>0&&result$level<1,
    "source score uncertainty geometry or interval level is invalid")
  scaling<-result$provenance$fpca_score_uncertainty$scaling
  if(is.null(scaling))scaling<-"unknown"
  .etr_assert(is.character(scaling)&&length(scaling)==1L&&!is.na(scaling),
    "scaling must be single text value")
  paste0("FPC score sensitivity to basis estimation was evaluated with ",
    nrow(sims)," ",result$resampling_unit,"-level bootstrap refits ",
    "(scaling=",.etr_fpca_source_py_repr(scaling),") for ",nrow(result$median)," fixed ",
    result$target_source," target trajectory/trajectories. Bootstrap ",
    "components were matched and sign-aligned to the full-sample ",
    "reference (median absolute similarities: ",
    .etr_fpca_similarity_medians_text(sims,digits),"). Pointwise ",
    .etr_format_report_decimal(100*result$level,1L),
    "% percentile envelopes summarize variation in target scores ",
    "induced by re-estimation of the FPCA basis. These envelopes do ",
    "not include target measurement error, uncertainty in a latent ",
    "target curve, future-curve sampling variability, preprocessing ",
    "uncertainty, or full downstream-model uncertainty propagation.")
}

#' Published-source matched FPCA spectrum uncertainty reporting
#' @param result Native FPCA spectrum bootstrap result.
#' @param digits Numeric reporting precision.
#' @export
etr_fpca_spectrum_uncertainty_reporting_text <- function(result,digits=3L) {
  digits<-.etr_reporting_digits(digits)
  sims<-.etr_fpca_matched_similarities(result,"etr_fpca_spectrum_uncertainty")
  .etr_assert(is.numeric(result$reference$explained_variance_ratio)&&
    length(result$reference$explained_variance_ratio)>0L&&
    is.finite(result$reference$explained_variance_ratio[1L])&&
    result$simultaneous_scope%in%c("family","component")&&
    is.numeric(result$confidence_level)&&
    length(result$confidence_level)==1L&&
    is.finite(result$confidence_level)&&
    result$confidence_level>0&&result$confidence_level<1,
    "FPCA spectrum uncertainty has invalid scope or fitted ratio")
  scope<-if(result$simultaneous_scope=="family")
    "familywise across the requested components within each spectrum metric"
  else "component-wise within each spectrum metric"
  paste0("FPCA spectrum uncertainty was evaluated with ",nrow(sims),
    " ",result$resampling_unit,"-level bootstrap replicates. Bootstrap ",
    "FPCs were matched to the full-sample reference before eigenvalues ",
    "and variance ratios were attached to component identities. ",
    "Studentized ",.etr_format_report_decimal(100*result$confidence_level,1L),
    "% uncertainty intervals were calibrated ",scope,". Median ",
    "matched absolute similarities were ",.etr_fpca_similarity_medians_text(sims,digits),
    "; the reference FPC1 explained-variance ratio was ",
    .etr_format_report_decimal(result$reference$explained_variance_ratio[1L],digits),
    ". Familywise calibration, when requested, applies separately ",
    "to eigenvalues, explained-variance ratios, and cumulative ratios ",
    "rather than jointly across all three metrics. Intervals are not ",
    "clipped to the mathematical support and are bootstrap ",
    "approximations rather than exact finite-sample confidence guarantees.")
}

#' Published-source whole-unit functional mean band manuscript wording
#' @param result Native simultaneous observed-grid Gaussian multiplier band.
#' @param digits Critical-value display precision.
#' @export
etr_functional_mean_band_reporting_text <- function(result,digits=3L) {
  digits<-.etr_reporting_digits(digits)
  .etr_assert(inherits(result,"etr_functional_mean_band")&&
    is.numeric(result$confidence_level)&&
    length(result$confidence_level)==1L&&
    is.finite(result$confidence_level)&&
    is.numeric(result$critical_value)&&
    length(result$critical_value)==1L&&
    is.finite(result$critical_value)&&
    is.character(result$unit)&&length(result$unit)==1L&&
    length(result$unit_ids)>=1L,
    "result must be valid native functional mean band")
  cfg<-result$provenance$functional_mean_band
  nmult<-if(is.null(cfg$n_multiplier))"unknown" else
    as.character(cfg$n_multiplier)
  estimand<-if(is.null(cfg$estimand))"unspecified" else cfg$estimand
  .etr_assert(is.character(estimand)&&length(estimand)==1L&&
    !is.na(estimand),"estimand must be one text label")
  paste0("The functional mean was estimated from ",
    length(result$unit_ids)," ",result$unit,
    "-level inference units using estimand=",.etr_fpca_source_py_repr(estimand),". A ",
    .etr_format_report_decimal(100*result$confidence_level,1L),
    "% simultaneous observed-grid band was calibrated with a ",
    "studentized Gaussian multiplier maximum using ",nmult,
    " multiplier replicates (critical value=",
    .etr_format_report_decimal(result$critical_value,digits),"). The band is ",
    "simultaneous across the observed time-by-dimension grid and ",
    "does not claim continuous-domain coverage between sampled grid points.")
}

#' Source-aligned simultaneous matched FPCA component band description
#' @param result Native FPCA component shape bootstrap uncertainty result.
#' @param digits Numerical display precision.
#' @export
etr_fpca_component_band_reporting_text <- function(result,digits=2L) {
  digits<-.etr_reporting_digits(digits)
  sims<-.etr_fpca_matched_similarities(result,"etr_fpca_component_band")
  .etr_assert(result$simultaneous_scope%in%c("family","component")&&
    is.numeric(result$confidence_level)&&
    length(result$confidence_level)==1L&&
    is.finite(result$confidence_level),
    "component band has invalid familywise scope or level")
  scope<-if(result$simultaneous_scope=="family")
    "familywise across the requested FPCs and observed time-by-dimension grid"
  else "component-wise across each FPC's observed time-by-dimension grid"
  text<-paste0("Functional principal-component shape uncertainty was ",
    "evaluated with ",nrow(sims)," ",result$resampling_unit,
    "-level bootstrap replicates. Replicate FPCs were matched and ",
    "sign-aligned to the full-sample reference, then studentized maximum ",
    "absolute deviations were calibrated at ",
    .etr_format_report_decimal(100*result$confidence_level,1L),"% ",scope,
    ". Median matched absolute similarities were ",
    .etr_fpca_similarity_medians_text(sims,digits),". ")
  if(is.null(result$relative_gap_threshold)) {
    text<-paste0(text,"No numerical near-tie threshold was imposed; ",
      "component identifiability should therefore be assessed separately ",
      "with eigengap and subspace diagnostics. ")
  } else {
    gap<-result$minimum_relative_gaps
    .etr_assert(is.numeric(gap)&&length(gap)==ncol(sims)&&
      all(is.finite(gap))&&is.numeric(result$relative_gap_threshold)&&
      length(result$relative_gap_threshold)==1L&&
      is.finite(result$relative_gap_threshold),
      "relative-gap threshold and component gaps must be finite")
    minimum<-paste0("FPC",seq_along(gap),"=",
      .etr_format_report_decimal(gap,digits+1L))
    text<-paste0(text,"The pre-specified relative-gap screen used ",
      "threshold ",.etr_format_report_decimal(result$relative_gap_threshold,digits+1L),
      " (minimum adjacent gaps: ",paste(minimum,collapse=", "),"). ")
  }
  paste0(text,"The band is calibrated over the observed grid and does ",
    "not establish continuous-domain coverage between sampled times ",
    "or substantive identifiability of a near-tied individual FPC axis.")
}

.etr_validate_fpca_plot_component <- function(result,component,kind) {
  .etr_assert(inherits(result,kind),
    paste0("result must be a native ",kind," record"))
  fitted <- result$n_components
  # Bootstrap component bands carry retained rank in the fitted reference,
  # not in a second top-level field. Do not mutate their public schema.
  if(is.null(fitted)&&identical(kind,"etr_fpca_component_band"))
    fitted <- result$reference$n_components
  .etr_assert(is.numeric(fitted)&&length(fitted)==1L&&
    is.finite(fitted)&&fitted>=1&&fitted==floor(fitted),
    "result must declare a positive fitted FPC count")
  .etr_assert(is.numeric(component)&&length(component)==1L&&
    !is.logical(component)&&is.finite(component)&&
    component==floor(component)&&component>=0&&component<fitted,
    "component must identify a zero-based fitted FPC")
  as.integer(component)+1L
}
.etr_validate_plot_interval <- function(lower,estimate,upper) {
  .etr_assert(is.numeric(lower)&&is.numeric(estimate)&&
    is.numeric(upper)&&length(lower)==length(estimate)&&
    length(estimate)==length(upper)&&
    length(lower)>=1L&&all(is.finite(c(lower,estimate,upper)))&&
    all(lower<=estimate&estimate<=upper),
    "uncertainty interval endpoints must be finite and contain estimate")
}

#' Plot fixed-target basis-resampling FPCA score uncertainty
#' @param result Native score uncertainty.
#' @param component Python-compatible zero-based retained component index.
#' @param max_targets Maximum plotted fixed target trajectories.
#' @param strict_source_record If TRUE return source scientific Matplotlib
#'   score-interval, reference-scatter and zero-reference artist geometry
#'   as a typed native R record; no Python Axes identity is claimed.
#' @param ... Base R plotting options.
#' @return Invisible source scores and interval geometry.
#' @export
etr_plot_fpca_score_uncertainty <- function(result,component=0L,
    max_targets=30L,strict_source_record=FALSE,...) {
  .etr_fpca_uncertainty_strict(strict_source_record)
  k<-.etr_validate_fpca_plot_component(result,component,"etr_fpca_score_uncertainty")
  .etr_assert(is.numeric(max_targets)&&length(max_targets)==1L&&
    is.finite(max_targets)&&!is.logical(max_targets)&&
    max_targets==as.integer(max_targets)&&max_targets>=1L,
    "max_targets must be a positive integer")
  n<-min(as.integer(max_targets),length(result$target_curve_ids))
  .etr_assert(is.matrix(result$median)&&is.matrix(result$lower)&&
    is.matrix(result$upper)&&
    is.matrix(result$reference_scores)&&n>=1L&&
    nrow(result$median)>=n&&nrow(result$lower)>=n&&
    nrow(result$upper)>=n&&nrow(result$reference_scores)>=n,
    "target score and interval matrices must be complete")
  out<-data.frame(
    target_curve_id=result$target_curve_ids[seq_len(n)],
    median=result$median[seq_len(n),k],
    lower=result$lower[seq_len(n),k],
    upper=result$upper[seq_len(n),k],
    reference=result$reference_scores[seq_len(n),k],
    stringsAsFactors=FALSE)
  .etr_validate_plot_interval(out$lower,out$median,out$upper)
  .etr_assert(all(is.finite(out$reference)),
    "fixed target reference scores must be finite")
  x<-seq_len(n)-1L
  graphics::plot(x,out$median,pch=1,ylim=range(c(out$lower,
    out$upper,out$reference)),xaxt="n",xlab="Target trajectory",
    ylab=sprintf("FPC%d score",k),
    main="Basis-resampling FPC score uncertainty",...)
  graphics::arrows(x,out$lower,x,out$upper,length=.04,
    code=3,angle=90)
  graphics::points(x,out$reference,pch=4)
  graphics::abline(h=0,lty=2)
  graphics::axis(1,at=x,labels=out$target_curve_id,las=2)
  if(isTRUE(strict_source_record))
    return(invisible(.etr_fpca_score_uncertainty_artist(
      out,component,max_targets)))
  invisible(out)
}

#' Plot source matched FPCA spectrum uncertainty intervals
#' @param result Native FPC spectrum bootstrap result.
#' @param metric Source-defined spectrum measure.
#' @param strict_source_record If TRUE return matched source spectrum
#'   errorbar arrays, labels and calibration scope as native R artist data.
#' @param ... Base R graphics options.
#' @return Invisible retained-component source interval geometry.
#' @export
etr_plot_fpca_spectrum_uncertainty <- function(result,
    metric="explained_variance_ratio",strict_source_record=FALSE,...) {
  .etr_fpca_uncertainty_strict(strict_source_record)
  .etr_assert(inherits(result,"etr_fpca_spectrum_uncertainty")&&
    is.character(metric)&&length(metric)==1L&&
    !is.na(metric)&&metric%in%c("eigenvalue",
      "explained_variance_ratio","cumulative_variance_ratio"),
    "metric must be eigenvalue, explained_variance_ratio or cumulative_variance_ratio")
  n<-.etr_validate_positive_component_count(result$n_components,"n_components")
  estimate<-switch(metric,
    eigenvalue=result$reference$explained_variance[seq_len(n)],
    explained_variance_ratio=result$reference$explained_variance_ratio[seq_len(n)],
    cumulative_variance_ratio=cumsum(
      result$reference$explained_variance_ratio[seq_len(n)]))
  lower<-switch(metric,
    eigenvalue=result$eigenvalue_lower,
    explained_variance_ratio=result$explained_variance_ratio_lower,
    cumulative_variance_ratio=result$cumulative_variance_ratio_lower)
  upper<-switch(metric,
    eigenvalue=result$eigenvalue_upper,
    explained_variance_ratio=result$explained_variance_ratio_upper,
    cumulative_variance_ratio=result$cumulative_variance_ratio_upper)
  .etr_validate_plot_interval(lower,estimate,upper)
  out<-data.frame(component=seq_len(n),estimate=as.numeric(estimate),
    lower=as.numeric(lower),upper=as.numeric(upper))
  graphics::plot(out$component,out$estimate,pch=1,
    ylim=range(c(out$lower,out$upper)),
    xlab="Functional principal component",ylab=gsub("_"," ",metric),
    main=sprintf("FPCA spectrum uncertainty (%s)",
      result$simultaneous_scope),...)
  graphics::arrows(out$component,out$lower,out$component,out$upper,
    code=3,angle=90,length=.04)
  if(isTRUE(strict_source_record))
    return(invisible(.etr_fpca_spectrum_uncertainty_artist(
      result,metric,out)))
  invisible(out)
}

#' Plot source native FPCA component and simultaneous observed-grid band
#' @param result Native FPCA simultaneous component band result.
#' @param component Zero-based source FPC component.
#' @param dimension Named physical or abstract functional dimension.
#' @param strict_source_record If TRUE return source observed-grid band
#'   polygon, confidence-level label and reference FPC line geometry
#'   rather than a Python Matplotlib Axes object.
#' @param ... Base R graphics options.
#' @return Invisible observed-time component estimate and band geometry.
#' @export
etr_plot_fpca_component_band <- function(result,component=0L,
    dimension=NULL,strict_source_record=FALSE,...) {
  .etr_fpca_uncertainty_strict(strict_source_record)
  k<-.etr_validate_fpca_plot_component(result,component,"etr_fpca_component_band")
  ref<-result$reference
  if(is.null(dimension))dimension<-ref$dimension_names[1L]
  .etr_assert(is.character(dimension)&&length(dimension)==1L&&
    !is.na(dimension)&&dimension%in%ref$dimension_names,
    "dimension must identify a fitted FPCA channel")
  j<-match(dimension,ref$dimension_names)
  # Genuine bootstrap component bands store retained rank on the fitted
  # reference; the top-level result has no n_components field.
  expected_shape<-c(ref$n_components,length(ref$time),
    length(ref$dimension_names))
  .etr_assert(is.array(ref$components)&&
    length(dim(ref$components))==3L&&
    identical(dim(ref$components),expected_shape)&&
    is.array(result$lower)&&is.array(result$upper)&&
    identical(dim(result$lower),dim(result$upper))&&
    identical(dim(result$lower),expected_shape),
    "component bootstrap bands must have matching 3D shapes")
  out<-data.frame(time=ref$time,
    estimate=as.numeric(ref$components[k,,j]),
    lower=as.numeric(result$lower[k,,j]),
    upper=as.numeric(result$upper[k,,j]))
  .etr_validate_plot_interval(out$lower,out$estimate,out$upper)
  graphics::plot(out$time,out$estimate,type="l",
    ylim=range(c(out$lower,out$upper)),
    xlab=sprintf("Time (%s)",ref$time_unit),
    ylab=sprintf("FPC loading: %s",dimension),
    main=sprintf("FPC%d simultaneous band (%s)",k,
      result$simultaneous_scope),...)
  graphics::polygon(c(out$time,rev(out$time)),
    c(out$lower,rev(out$upper)),
    col=grDevices::adjustcolor("grey70",alpha.f=.3),border=NA)
  graphics::lines(out$time,out$estimate,lwd=2)
  if(isTRUE(strict_source_record))
    return(invisible(.etr_fpca_component_band_artist(
      result,component,dimension,out)))
  invisible(out)
}
