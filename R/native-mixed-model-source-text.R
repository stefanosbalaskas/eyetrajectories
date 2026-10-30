# Frozen Python 1.2.0 manuscript reporter:
# eyetrajectoriespy.reporting.functional_mixed_effects_reporting_text
# source c1cd95ad718327550f7e55393ff38582872f7a94
# Native R text-only subset for a declared source-shaped fit, WITHOUT a band.
# It does not fit MixedLM, certify estimator parity or claim coverage.

.etr_fmixed_report_string <- function(x,name) {
  .etr_assert(is.character(x)&&length(x)==1L&&!is.na(x)&&
    nzchar(x)&&!grepl("'",x,fixed=TRUE)&&
    !grepl("\\",x,fixed=TRUE)&&!grepl("\\n",x,fixed=TRUE)&&
    !grepl("\\r",x,fixed=TRUE),
    paste(name,"must be a source-compatible nonempty plain string"))
  x
}
.etr_fmixed_report_flag <- function(x,name) {
  .etr_assert(is.logical(x)&&length(x)==1L&&!is.na(x),
    paste(name,"must be a nonmissing logical flag"))
  x
}
.etr_fmixed_report_count <- function(x,name) {
  .etr_assert(is.numeric(x)&&length(x)==1L&&is.finite(x)&&
    x>=1&&x==floor(x),"source count must be positive integer")
  as.integer(x)
}
.etr_fmixed_report_repr <- function(x,name)paste0("'",
  .etr_fmixed_report_string(x,name),"'")

#' Manuscript wording for a declared functional mixed-effects fit
#'
#' Reproduces published Python 1.2.0 pointwise-Wald, no-band wording
#' for validated source-shaped fit records without fitting or resampling.
#' Bootstrap band reporting is explicitly not implemented and fails closed.
#' @param result Source-shaped native functional mixed-effects result record.
#' @param band Must be NULL; source bootstrap-band reporting is not ported.
#' @return Character scalar of qualified-subset manuscript wording.
#' @export
etr_functional_mixed_effects_reporting_text <- function(result,band=NULL){
  .etr_assert(is.null(band),
    "band bootstrap source contract is not implemented in native R")
  required<-c("predictor_names","boundary_fit","trial_random_effect",
    "random_effect_singular","trial_random_effect_singular",
    "random_effect_complexity_warning",
    "residual_correlation_boundary_fit",
    "residual_correlation_independence_limit_fit","backend_warnings",
    "random_slope_predictor","random_basis_size",
    "residual_correlation","dimension_name","fixed_basis_size",
    "spline_degree","n_curves","n_participants","reml","method",
    "random_effect_covariance_condition_number")
  .etr_scientific_frame_fields(result,required,"mixed fit")
  predictors<-result$predictor_names
  .etr_assert(is.character(predictors)&&length(predictors)>=1L&&
    !anyNA(predictors)&&all(nzchar(predictors)),
    "predictor_names must be nonempty character names")
  invisible(lapply(predictors,.etr_fmixed_report_string,
    name="predictor_name"))
  flags<-c("boundary_fit","random_effect_singular",
    "trial_random_effect_singular","random_effect_complexity_warning",
    "residual_correlation_boundary_fit",
    "residual_correlation_independence_limit_fit","reml")
  for(n in flags).etr_fmixed_report_flag(result[[n]],n)
  if(!is.null(result$trial_random_effect))
    .etr_assert(identical(result$trial_random_effect,
      "functional_intercept"),"unsupported trial_random_effect")
  if(!is.null(result$random_slope_predictor))
    .etr_fmixed_report_string(result$random_slope_predictor,
      "random_slope_predictor")
  count_names<-c("random_basis_size","fixed_basis_size","spline_degree",
    "n_curves","n_participants")
  for(n in count_names).etr_fmixed_report_count(result[[n]],n)
  .etr_assert(is.character(result$backend_warnings)&&
    !anyNA(result$backend_warnings),
    "backend_warnings must be a character vector")
  .etr_assert(is.numeric(result$random_effect_covariance_condition_number)&&
    length(result$random_effect_covariance_condition_number)==1L&&
    is.finite(result$random_effect_covariance_condition_number)&&
    result$random_effect_covariance_condition_number>=0,
    "random_effect_covariance_condition_number must be finite")
  predictor_text<-paste(predictors,collapse=", ")
  warning_text<-""
  if(result$boundary_fit){
    warning_text<-paste0(warning_text,if(is.null(result$trial_random_effect))
      " The participant random-effect covariance was estimated on or near the numerical boundary and should be interpreted cautiously."
      else
      " At least one fitted participant/trial random-effect covariance component was estimated on or near the numerical boundary and should be interpreted cautiously.")
  }
  if(result$random_effect_singular)
    warning_text<-paste0(warning_text,
      " The fitted participant random-effect covariance was numerically singular under the retained diagnostic tolerance.")
  if(result$trial_random_effect_singular)
    warning_text<-paste0(warning_text,
      " The fitted trial random-effect covariance was numerically singular under the retained diagnostic tolerance.")
  if(result$random_effect_complexity_warning)
    warning_text<-paste0(warning_text,
      " The number of participants did not exceed the number of free unstructured random-effect covariance parameters; this covariance-complexity warning should be reported.")
  if(result$residual_correlation_boundary_fit)
    warning_text<-paste0(warning_text,
      " The fitted residual-correlation parameter was at or near its recorded numerical optimizer bound and should be interpreted as a boundary diagnostic rather than an ordinary interior estimate.")
  if(result$residual_correlation_independence_limit_fit)
    warning_text<-paste0(warning_text,
      " The fitted exponential residual correlation is at the recorded practical independence limit on the observed grid (maximum off-diagonal correlation no greater than 0.05); phi is therefore weakly identified toward the iid boundary and should not be interpreted as a precise positive range estimate.")
  if(length(result$backend_warnings))
    warning_text<-paste0(warning_text,
      " Backend warnings were retained in the result provenance rather than suppressed.")
  random_text<-if(is.null(result$random_slope_predictor))
    paste0("the participant-specific functional random intercept used ",
      result$random_basis_size,
      " B-spline basis functions with an unstructured basis-coefficient covariance")
  else {
    .etr_scientific_frame_fields(result,c("random_effect_dimension",
      "random_effect_covariance_parameter_count"),"random-slope fit")
    paste0("the participant random-effect structure contained a functional ",
      "random intercept and exactly one functional random slope for ",
      .etr_fmixed_report_repr(result$random_slope_predictor,
        "random_slope_predictor"),", each using ",
      result$random_basis_size,
      " B-spline basis functions. Their stacked ",
      .etr_fmixed_report_count(result$random_effect_dimension,
        "random_effect_dimension"),
      "-dimensional random coefficient vector used one unstructured covariance with ",
      .etr_fmixed_report_count(
        result$random_effect_covariance_parameter_count,
        "random_effect_covariance_parameter_count"),
      " free covariance parameters")
  }
  trial_text<-""
  if(!is.null(result$trial_random_effect)){
    .etr_scientific_frame_fields(result,c("n_trials",
      "trial_random_basis_size",
      "trial_random_effect_covariance_parameter_count"),"trial fit")
    trial_text<-paste0(
      " A nested trial-specific functional random intercept was also ",
      "estimated for ",.etr_fmixed_report_count(result$n_trials,"n_trials"),
      " trials using ",
      .etr_fmixed_report_count(result$trial_random_basis_size,
        "trial_random_basis_size"),
      " B-spline basis functions and one shared unstructured trial-basis covariance with ",
      .etr_fmixed_report_count(
        result$trial_random_effect_covariance_parameter_count,
        "trial_random_effect_covariance_parameter_count"),
      " free covariance parameters. Trial identifiers were required to be ",
      "unique within participant, and every participant contributed at least two trials")
  }
  corr<-.etr_fmixed_report_string(result$residual_correlation,
    "residual_correlation")
  residual_text<-switch(corr,
    iid="Grid-level residuals were conditionally iid Gaussian within each source curve/trial.",
    exponential={
      .etr_scientific_frame_fields(result,c("residual_correlation_parameter",
        "residual_correlation_parameter_unit"),"correlated fit")
      paste0("Grid-level residuals used a within-trial continuous-time ",
        "exponential correlation with jointly estimated range phi=",
        sprintf("%.4g",result$residual_correlation_parameter)," ",
        .etr_fmixed_report_string(result$residual_correlation_parameter_unit,
          "residual_correlation_parameter_unit"),
        "; residual correlation was block diagonal across trials.")
    },
    ar1={
      .etr_scientific_frame_fields(result,
        c("residual_correlation_parameter"),"correlated fit")
      paste0("Grid-level residuals used a within-trial index-step AR(1) ",
        "correlation on the verified regular grid with jointly estimated rho=",
        sprintf("%.4g",result$residual_correlation_parameter),
        "; residual correlation was block diagonal across trials.")
    },
    stop(paste("unsupported residual_correlation",corr),call.=FALSE))
  inference_text<-paste0(
    " Reported 95% coefficient intervals are pointwise Wald intervals; ",
    "simultaneous functional coverage and variance-component uncertainty ",
    "are not claimed.")
  paste0(
    "A Gaussian functional mixed-effects regression was fitted jointly ",
    "over all curve-by-time observations for dimension ",
    .etr_fmixed_report_repr(result$dimension_name,"dimension_name"),
    ". Fixed coefficient functions for ",predictor_text,
    " and the intercept used a clamped B-spline basis with ",
    result$fixed_basis_size," functions (degree ",result$spline_degree,
    "); ",random_text,".",trial_text," ",
    "The model included ",result$n_curves," curves from ",
    result$n_participants," participants and was estimated by ",
    if(result$reml)"REML" else "ML"," using optimizer ",
    .etr_fmixed_report_repr(result$method,"method"),
    ". The fitted random-effect covariance condition number was ",
    sprintf("%.3g",result$random_effect_covariance_condition_number),
    ". Trial-varying predictors were retained at the curve level while ",
    "participant clustering was represented directly. ",residual_text,
    " No automatic categorical encoding, interaction construction, ",
    "predictor scaling, basis-size selection, random-slope selection, ",
    "trial-random-effect selection, residual-correlation-family selection, ",
    "smoothing-penalty selection, or optimizer fallback was performed.",
    inference_text,warning_text)
}
