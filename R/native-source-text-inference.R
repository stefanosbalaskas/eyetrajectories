# Pinned public Python 1.2.0 text contracts for generalized FoSR,
# covariance-sensitivity reporting, and multivariate surrogate inference.
# Read-only R-list subset. No model estimation or source certification.
# Python source commit c1cd95ad718327550f7e55393ff38582872f7a94.

.etr_source_text_word <- function(x,name) {
  .etr_scientific_frame_string(x,name)
  .etr_assert(!grepl("[^[:alnum:] _.-]",x),
    paste(name,"must contain only safe identifier characters"))
  x
}
.etr_source_text_int <- function(x,name,min=0L) {
  .etr_assert(is.numeric(x) && length(x)==1L && is.finite(x) &&
    x>=min && x==floor(x) && x<=.Machine$integer.max,
    paste(name,"must be a finite whole number"))
  as.integer(x)
}
.etr_source_text_number <- function(x,name,min=-Inf,max=Inf) {
  .etr_assert(is.numeric(x) && length(x)==1L && is.finite(x) &&
    x>=min && x<=max,
    paste(name,"must be a finite scalar in range"))
  as.numeric(x)
}
.etr_source_text_boolean <- function(x,name) {
  .etr_assert(is.logical(x)&&length(x)==1L&&!is.na(x),
    paste(name,"must be a nonmissing boolean"))
  x
}
.etr_source_text_vector <- function(x,name) {
  .etr_assert(is.numeric(x)&&length(x)>=1L&&all(is.finite(x)),
    paste(name,"must contain at least one finite number"))
  x
}
.etr_source_text_names <- function(x,name) {
  .etr_scientific_frame_ids(x,name)
  for(v in x).etr_source_text_word(v,name)
  x
}

#' Scientific wording for predeclared generalized FoSR fixed profiles
#' @param result Validated native R prediction-band record with a nested
#'   fixed-profile prediction and its original marginal reference.
#' @return Source-aligned reporting text, not recalibrated inference.
#' @export
etr_generalized_function_on_scalar_prediction_reporting_text <- function(result) {
  .etr_scientific_frame_fields(result,c("prediction","simultaneous_scope"))
  p<-result$prediction
  .etr_scientific_frame_fields(p,c("profile_ids","extrapolation_flags",
    "prediction_scale","reference"),"prediction")
  .etr_scientific_frame_fields(p$reference,c("family","link"),
    "prediction reference")
  ids<-.etr_scientific_frame_ids(p$profile_ids,"profile_ids")
  .etr_scientific_frame_vector(p$extrapolation_flags,length(ids),
    "extrapolation_flags",logical=TRUE)
  scale<-switch(.etr_source_text_word(p$prediction_scale,"prediction_scale"),
    probability="marginal probability",
    rate="marginal exposure-adjusted rate",
    expected_count="marginal expected count",
    NULL)
  .etr_assert(!is.null(scale),
    "prediction_scale must be probability, rate or expected_count")
  family<-.etr_source_text_word(p$reference$family,"family")
  link<-.etr_source_text_word(p$reference$link,"link")
  scope<-.etr_python_workflow_identifier_repr(
    .etr_gfosr_predict_scalar(result$simultaneous_scope,"simultaneous_scope"))
  extra<-ids[p$extrapolation_flags]
  extra_text<-if(length(extra)==0L)
    " No declared profile lay outside the observed scalar predictor ranges."
    else paste0(" The following fixed profiles were retained but flagged as ",
      "scalar-predictor extrapolations: ",paste(extra,collapse=", "),".")
  grouped<-if(!is.null(p$reference$binomial_denominators))
    paste0(" The fitted binomial model used explicit grouped success counts ",
      "and denominators; fixed-profile prediction targets success ",
      "probability and does not require or infer a target denominator.")
    else ""
  paste0("Fixed-profile ",scale,
    " functions were derived from the fitted ",family,"/",link,
    " marginal generalized function-on-scalar model. Profile values ",
    "were treated as fixed scientific targets and were not resampled. ",
    "Simultaneous bands were calibrated on the linear-predictor scale ",
    "using the retained whole-participant coefficient bootstrap and ",
    "then transformed through the strictly monotone inverse link. ",
    "The simultaneous scope was ",scope,
    " over the observed grid; no between-grid coverage is claimed ",
    "and no profile was selected automatically.",grouped,extra_text)
}

#' Source-aligned interpretation of an explicitly declared mean contrast
#' @param result Native mean-difference band with profile labels,
#'   confidence level, contrast scale and physical-bounds flag.
#' @return Source-aligned fixed-contrast reporting text.
#' @export
etr_generalized_function_on_scalar_mean_difference_reporting_text <- function(result) {
  .etr_scientific_frame_fields(result,c("contrast_scale","profile_a",
    "profile_b","confidence_level","interval_exceeds_physical_bounds"))
  measure<-switch(.etr_source_text_word(result$contrast_scale,
    "contrast_scale"),
    probability_difference="marginal probability difference",
    rate_difference="marginal exposure-adjusted rate difference",
    rate_ratio="marginal exposure-adjusted rate ratio",
    expected_count_difference="marginal expected-count difference",
    NULL)
  .etr_assert(!is.null(measure),"unsupported contrast_scale")
  a<-.etr_python_workflow_identifier_repr(
    .etr_gfosr_predict_scalar(result$profile_a,"profile_a"))
  b<-.etr_python_workflow_identifier_repr(
    .etr_gfosr_predict_scalar(result$profile_b,"profile_b"))
  level<-.etr_source_text_number(result$confidence_level,
    "confidence_level",min=0,max=1)
  .etr_assert(level>0 && level<1,
    "confidence_level must be strictly between zero and one")
  bounds<-.etr_source_text_boolean(
    result$interval_exceeds_physical_bounds,
    "interval_exceeds_physical_bounds")
  ratio<-if(identical(result$contrast_scale,"rate_ratio"))
    " The simultaneous interval was calibrated on the log-rate-ratio scale and exponentiated, preserving positivity." else ""
  exceeded<-if(bounds)
    paste0(" The untrimmed simultaneous band extended beyond the logical ",
      "[-1, 1] range of a probability difference; bounds were retained ",
      "rather than silently clipped.") else ""
  paste0("One predeclared ",measure," function was evaluated as ",a,
    " minus ",b,". The paired whole-participant bootstrap ",
    "coefficient draws were propagated through both fixed profiles, ",
    "preserving their dependence, and an observed-grid maximum ",
    "standardized-deviation band was calibrated at ",
    sprintf("%.1f",100*level),
    "%. The profile pair was not selected from the bootstrap results ",
    "and no multiple-contrast family adjustment is claimed.",
    ratio,exceeded)
}

#' Predeclared covariance-structure sensitivity scientific wording
#' @param result Native sensitivity record with reference label, explicit
#'   success/failure mappings and recorded information criterion convention.
#' @return A descriptive report, never an automatic model selection.
#' @export
etr_functional_mixed_effects_covariance_sensitivity_reporting_text <- function(result) {
  .etr_scientific_frame_fields(result,c("reference_label","fits",
    "failures","provenance"))
  reference<-.etr_gfosr_predict_scalar(result$reference_label,"reference_label")
  .etr_assert(is.list(result$fits) && is.list(result$failures),
    "fits and failures must be named mappings")
  .etr_scientific_frame_fields(result$provenance,
    c("functional_mixed_effects_covariance_sensitivity"),"provenance")
  inner<-result$provenance$functional_mixed_effects_covariance_sensitivity
  .etr_scientific_frame_fields(inner,c("information_criterion_mode"),
    "covariance provenance")
  mode<-.etr_gfosr_predict_scalar(inner$information_criterion_mode,
    "information_criterion_mode")
  paste0("Covariance structures were compared as a predeclared sensitivity ",
    "analysis against reference ",
    .etr_python_workflow_identifier_repr(reference),". ",
    length(result$fits)," declared structure(s) converged and ",
    length(result$failures),
    " failed structure(s) were retained explicitly rather than omitted. ",
    "Successful fits used identical observations, fixed-effect design and ",
    "basis, participant mapping, response dimension, time grid, and ",
    "ML/REML mode. Fixed coefficient-function changes, simultaneous-band ",
    "widths where supplied, functional participant/trial/residual variance ",
    "decomposition, raw and whitened residual dependence, covariance ",
    "diagnostics, log likelihood, AIC, and BIC were reported descriptively. ",
    "No covariance structure was ranked or automatically selected and no ",
    "likelihood-ratio p-values were computed. Information criteria used ",
    "the recorded convention ",.etr_python_workflow_identifier_repr(mode),
    "; BIC used the explicit observation count n_curves \u00d7 n_time.")
}

.etr_multivariate_source_report_check <- function(result) {
  .etr_scientific_frame_fields(result,c("n_surrogates",
    "dimension_names","reference_dimension","spectral_errors",
    "cross_spectral_errors","random_state"),"surrogate_result")
  ns<-.etr_source_text_int(result$n_surrogates,"n_surrogates",min=1L)
  dims<-.etr_scientific_frame_ids(result$dimension_names,"dimension_names")
  .etr_assert(length(dims)>=2L,
    "multivariate analysis requires at least two dimensions")
  reference<-.etr_gfosr_predict_scalar(result$reference_dimension,
    "reference_dimension")
  .etr_assert(reference%in%dims,
    "reference_dimension must be a declared dimension")
  spec<-.etr_source_text_vector(result$spectral_errors,
    "spectral_errors")
  cross<-.etr_source_text_vector(result$cross_spectral_errors,
    "cross_spectral_errors")
  .etr_assert(all(spec>=0)&&all(cross>=0),
    "relative spectrum mismatches must be nonnegative")
  if(!is.null(result$random_state))
    .etr_source_text_int(result$random_state,"random_state",min=0L)
  list(n=ns,dims=dims,reference=reference,
    spec=max(spec),cross=max(cross))
}

#' Reporting text for multivariate IAAFT surrogate generation
#' @inheritParams etr_functional_mixed_effects_covariance_sensitivity_reporting_text
#' @return A descriptive text with source spectral mismatch diagnostics.
#' @export
etr_multivariate_iaaft_reporting_text <- function(result) {
  v<-.etr_multivariate_source_report_check(result)
  paste0(v$n," multivariate IAAFT surrogates were generated for dimensions ",
    paste(v$dims,collapse=", ")," using ",
    .etr_python_workflow_identifier_repr(v$reference),
    " as the explicitly declared phase-reference dimension. Empirical ",
    "marginal distributions were restored exactly by rank remapping after ",
    "each Fourier adjustment, while per-dimension Fourier amplitudes and ",
    "inter-dimension phase differences were targeted jointly. Final ",
    "spectral preservation was therefore approximate after rank ",
    "remapping and was retained diagnostically (maximum relative ",
    "power-spectrum mismatch=",sprintf("%.4g",v$spec),
    "; maximum relative cross-spectrum mismatch=",
    sprintf("%.4g",v$cross),
    "). No dimension scaling, smoothing, interpolation, or automatic ",
    "reference-dimension selection was performed.")
}

#' Reporting text for multivariate surrogate nonlinearity inference
#' @inheritParams etr_functional_mixed_effects_covariance_sensitivity_reporting_text
#' @return A source-typed null-interpretation report.
#' @export
etr_multivariate_surrogate_nonlinearity_reporting_text <- function(result) {
  .etr_scientific_frame_fields(result,c("surrogate_statistics",
    "surrogate_result","statistic","alternative","p_value"))
  .etr_source_text_vector(result$surrogate_statistics,
    "surrogate_statistics")
  v<-.etr_multivariate_source_report_check(result$surrogate_result)
  statistic<-.etr_source_text_word(result$statistic,"statistic")
  alternative<-.etr_source_text_word(result$alternative,"alternative")
  p<-.etr_source_text_number(result$p_value,"p_value",min=0,max=1)
  state<-result$surrogate_result$random_state
  state_text<-if(is.null(state))"None" else as.character(state)
  paste0("Multivariate nonlinearity was assessed with ",
    v$n," cross-spectrum-aware MIAAFT surrogates for dimensions ",
    paste(v$dims,collapse=", ")," using ",
    .etr_python_workflow_identifier_repr(v$reference),
    " as the declared phase reference. The statistic was ",
    gsub("_"," ",statistic,fixed=TRUE)," with a ",alternative,
    " alternative and a plus-one Monte Carlo p-value (p=",
    sprintf("%.4g",p),"; random_state=",state_text,
    "). The maximum retained final relative power-spectrum mismatch was ",
    sprintf("%.4g",v$spec),
    " and the maximum retained relative cross-spectrum mismatch was ",
    sprintf("%.4g",v$cross),
    ". Rejection was interpreted as evidence against the declared ",
    "multivariate linear-stochastic surrogate null, not as proof of ",
    "deterministic chaos or a unique nonlinear mechanism.")
}
