# Frozen Python 1.2.0 manuscript reporter:
# eyetrajectoriespy.reporting.functional_mixed_effects_reporting_text
# source c1cd95ad718327550f7e55393ff38582872f7a94
# Native source-shaped fit and declared bootstrap-band text.
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
    x>=1&&x==floor(x)&&x<=.Machine$integer.max,
    "source count must be a positive representable integer")
  as.integer(x)
}
.etr_fmixed_report_repr <- function(x,name)paste0("'",
  .etr_fmixed_report_string(x,name),"'")

#' Manuscript wording for a declared functional mixed-effects fit
#'
#' Reproduces Python 1.2.0 no-band pointwise-Wald wording and declared
#' conditional-covariance and full-refit participant bootstrap wording.
#' @param result Native source-shaped functional mixed-effects fit record.
#' @param band Optional native source-shaped mixed-effects simultaneous band
#'   sharing the supplied reference and declaring its bootstrap type.
#' @return Character scalar of qualified-subset manuscript wording.
#' @export
etr_functional_mixed_effects_reporting_text <- function(result,band=NULL){
  if(!is.null(band)){
    .etr_scientific_frame_fields(band,c("reference","bootstrap",
      "confidence_level","simultaneous_scope"),"mixed band")
    .etr_assert(identical(band$reference,result),
      "band.reference must be the supplied result record")
    .etr_scientific_frame_fields(band$bootstrap,
      c("bootstrap_type","bootstrap_coefficient_functions"),
      "mixed band bootstrap")
    kind<-band$bootstrap$bootstrap_type
    .etr_assert(is.character(kind)&&length(kind)==1L&&
      !is.na(kind)&&kind%in%c("conditional_covariance","full_refit"),
      "bootstrap_type must be conditional_covariance or full_refit")
    .etr_assert(is.numeric(band$confidence_level)&&
      length(band$confidence_level)==1L&&
      is.finite(band$confidence_level)&&
      band$confidence_level>0&&band$confidence_level<1,
      "band confidence_level must be in (0,1)")
    .etr_assert(is.character(band$simultaneous_scope)&&
      length(band$simultaneous_scope)==1L&&
      !is.na(band$simultaneous_scope)&&
      band$simultaneous_scope%in%c("coefficient","family"),
      "band simultaneous_scope must be coefficient or family")
    draws<-band$bootstrap$bootstrap_coefficient_functions
    .etr_assert(is.array(draws)&&is.numeric(draws)&&
      length(dim(draws))==3L&&dim(draws)[1L]>=1L&&
      all(is.finite(draws)),
      "band bootstrap requires finite coefficient draws")
  }
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
  if(corr%in%c("ar1","exponential"))
    .etr_assert(is.numeric(result$residual_correlation_parameter)&&
      length(result$residual_correlation_parameter)==1L&&
      is.finite(result$residual_correlation_parameter),
      "residual_correlation_parameter must be finite numeric")
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
  if(!is.null(band)){
    level_text<-sprintf("%.1f",100*band$confidence_level)
    scope<-band$simultaneous_scope
    n_boot<-dim(draws)[1L]
    has_trial<-!is.null(result$trial_random_effect)
    if(identical(kind,"full_refit")){
      inference_text<-paste0(
        " Full-refit participant bootstrap ",level_text,
        "% simultaneous coefficient bands used ",n_boot,
        " whole-participant resamples with ",scope,
        "-scope maxima over the observed time grid. Every sampled participant occurrence received a distinct bootstrap group identity, and each replicate refitted fixed coefficients, the participant random-effect covariance",
        if(has_trial)", the shared trial random-effect covariance" else "",
        ", residual variance",
        if(corr!="iid")paste0(", and the ",corr,
          " residual-correlation parameter") else "",
        " under the unchanged declared model specification. Basis sizes, preprocessing, predictors, random-slope structure, REML/ML choice, and optimizer were not reselected. The bands therefore include variance-component re-estimation across participant bootstrap samples but not model-selection, preprocessing, or basis-selection uncertainty, and they do not claim simultaneous coverage between unsampled grid points.")
    }else{
      inference_text<-paste0(
        " Participant-cluster bootstrap ",level_text,
        "% simultaneous coefficient bands used ",n_boot,
        " whole-participant resamples with ",scope,
        "-scope maxima over the observed time grid. Fixed coefficient functions were re-estimated by GLS in every resample while the fitted participant random-effect covariance",
        if(has_trial)", shared trial random-effect covariance" else "",
        ", residual variance",
        if(corr!="iid")paste0(", and the fitted ",corr,
          " residual correlation") else "",
        " were held fixed. Thus the bands target participant-sampling variability conditional on the declared basis and fitted covariance model; they do not include variance-component or basis-selection uncertainty and do not claim simultaneous coverage between unsampled grid points.")
    }
  }
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
