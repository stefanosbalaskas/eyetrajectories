# Published Python source: eyetrajectoriespy==1.2.0
# src/eyetrajectoriespy/generalized_function_on_scalar_prediction.py
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
# These ports operate only on retained, fixed bootstrap coefficient draws.
# No fresh participant sampling, estimator fitting, or coverage guarantees.
# Python dataclass type identity and Pandas coercion remain unresolved.

.etr_gfosr_source_bootstrap <- function(bootstrap) {
  .etr_scientific_frame_fields(bootstrap,
    c("reference","bootstrap_coefficient_functions"),"coefficient bootstrap")
  fit<-bootstrap$reference
  .etr_scientific_frame_fields(fit,c("time","family","predictor_names"),
    "coefficient bootstrap reference")
  time<-.etr_scientific_frame_time(fit$time)
  n_coeff<-length(fit$predictor_names)+1L
  values<-bootstrap$bootstrap_coefficient_functions
  .etr_assert(is.array(values)&&is.numeric(values)&&
    length(dim(values))==3L&&dim(values)[1L]>=1L&&
    dim(values)[2L]==n_coeff&&dim(values)[3L]==length(time)&&
    all(is.finite(values)),
    "bootstrap_coefficient_functions must be a finite B-by-coefficient-by-time array")
  invisible(TRUE)
}

.etr_gfosr_source_provenance <- function(source,name,record) {
  previous<-source$provenance
  if(is.null(previous))previous<-list()
  .etr_assert(is.list(previous)&&
    (length(previous)==0L||(!is.null(names(previous))&&
      !anyNA(names(previous))&&all(nzchar(names(previous))))),
    "provenance must be a named source record")
  previous[[name]]<-record
  previous
}

#' Project retained participant-bootstrap coefficient functions to fixed profiles
#'
#' Retains previously generated whole-participant bootstrap coefficient draws;
#' never resamples or refits the model.
#' @param bootstrap Explicit native coefficient-bootstrap result record.
#' @param profiles Data frame of fixed profile identifiers and scalar predictors.
#' @param profile_id_column Target identifier column.
#' @param exposure_profiles Positive Poisson exposure vector or matrix, if
#'   expected-count predictions are requested.
#' @param prediction_scale Explicit rate, expected_count or probability scale.
#' @param python_boundary_mode Use pandas-style text conversion for
#'   Boolean and floating-point profile identifiers.
#' @return Native prediction-bootstrap record with B-by-profile-by-time arrays.
#' @export
etr_bootstrap_generalized_function_on_scalar_predictions <- function(
    bootstrap,profiles,profile_id_column="profile_id",
    exposure_profiles=NULL,prediction_scale=NULL,python_boundary_mode=FALSE) {
  .etr_gfosr_source_bootstrap(bootstrap)
  prediction<-etr_generalized_function_on_scalar_predict(
    bootstrap$reference,profiles,profile_id_column=profile_id_column,
    exposure_profiles=exposure_profiles,prediction_scale=prediction_scale,
    python_boundary_mode=python_boundary_mode)
  design<-prediction$profile_design_matrix
  coefficient_draws<-bootstrap$bootstrap_coefficient_functions
  shape<-dim(coefficient_draws)
  B<-shape[1L];np<-nrow(design);nt<-shape[3L]
  linear_rate_draws<-array(NA_real_,c(B,np,nt))
  for(b in seq_len(B)) {
    coef<-matrix(coefficient_draws[b,,],nrow=shape[2L],ncol=nt)
    linear_rate_draws[b,,]<-design%*%coef
  }
  family<-bootstrap$reference$family
  exposed<-!is.null(bootstrap$reference$exposure)
  rate_draws<-if(identical(family,"poisson")&&exposed)
    .etr_gfosr_predict_inverse_link(linear_rate_draws,"poisson")
    else NULL
  if(identical(prediction$prediction_scale,"expected_count")&&
     !is.null(prediction$log_exposure_profiles)){
    linear_draws<-sweep(linear_rate_draws,c(2L,3L),
      prediction$log_exposure_profiles,"+")
  } else linear_draws<-linear_rate_draws
  .etr_assert(all(is.finite(linear_draws)),
    "bootstrap fixed-profile linear predictors contain non-finite values")
  mean_draws<-.etr_gfosr_predict_inverse_link(linear_draws,family)
  .etr_assert(all(is.finite(mean_draws)),
    "bootstrap fixed-profile marginal means contain non-finite values")
  count_draws<-if(identical(family,"poisson")&&
     identical(prediction$prediction_scale,"expected_count"))
    mean_draws else NULL
  provenance<-.etr_gfosr_source_provenance(bootstrap,
    "generalized_function_on_scalar_prediction_bootstrap",list(
      method="fixed_profile_projection_of_whole_participant_coefficient_bootstrap",
      n_bootstrap=B,profile_ids=prediction$profile_ids,
      profile_values_fixed_across_bootstrap=TRUE,
      profile_values_resampled=FALSE,
      same_participant_draws_as_coefficient_bootstrap=TRUE,
      response_transformation=if(identical(family,"binomial"))
        "inverse_logit" else "exponential",
      prediction_scale=prediction$prediction_scale,
      target_exposure_supplied=!is.null(prediction$exposure_profiles),
      automatic_profile_selection=FALSE))
  structure(list(prediction=prediction,coefficient_bootstrap=bootstrap,
    bootstrap_linear_predictor_functions=linear_draws,
    bootstrap_mean_functions=mean_draws,
    bootstrap_rate_functions=rate_draws,
    bootstrap_expected_count_functions=count_draws,
    provenance=provenance),
    class="etr_generalized_fosr_prediction_bootstrap")
}

.etr_gfosr_numpy_higher <- function(x,level) {
  .etr_assert(is.numeric(x)&&length(x)>=1L&&all(is.finite(x)),
    "higher quantile requires finite bootstrap statistics")
  sort(x,method="radix")[[as.integer(ceiling((length(x)-1)*level)+1L)]]
}

#' Calibrate observed-grid simultaneous fixed-profile prediction bands
#'
#' Uses NumPy higher empirical quantiles of fixed participant-bootstrap
#' standardized maxima on the declared linear-predictor scale. The output
#' does not claim between-grid coverage or re-estimate bootstrap coefficients.
#' @param bootstrap Native fixed-profile prediction-bootstrap record.
#' @param confidence_level Nominal confidence level strictly between 0 and 1.
#' @param simultaneous_scope Profile-specific or complete fixed-family maxima.
#' @return Source-shaped native band with criticals, bootstrap maxima,
#'   and monotone inverse-link interval endpoints.
#' @export
etr_generalized_function_on_scalar_prediction_bands <- function(
    bootstrap,confidence_level=.95,simultaneous_scope="profile") {
  .etr_scientific_frame_fields(bootstrap,c("prediction",
    "bootstrap_linear_predictor_functions"),"prediction bootstrap")
  pred<-bootstrap$prediction
  .etr_scientific_frame_fields(pred,c("profile_ids","reference",
    "linear_predictor_functions",
    "linear_predictor_standard_errors"),"prediction")
  .etr_assert(is.numeric(confidence_level)&&length(confidence_level)==1L&&
    !is.logical(confidence_level)&&is.finite(confidence_level)&&
    confidence_level>0&&confidence_level<1,
    "confidence_level must be numeric inside (0,1)")
  .etr_assert(is.character(simultaneous_scope)&&
    length(simultaneous_scope)==1L&&!is.na(simultaneous_scope)&&
    simultaneous_scope%in%c("profile","family"),
    "simultaneous_scope must be profile or family")
  np<-length(.etr_scientific_frame_ids(pred$profile_ids,"profile_ids"))
  nt<-length(.etr_scientific_frame_time(pred$reference$time))
  center<-.etr_gfosr_predict_numeric_matrix(
    pred$linear_predictor_functions,np,nt,"linear_predictor_functions")
  se<-.etr_gfosr_predict_numeric_matrix(
    pred$linear_predictor_standard_errors,np,nt,
    "linear_predictor_standard_errors")
  .etr_assert(all(se>.Machine$double.eps),
    "prediction simultaneous bands require strictly positive finite linear-predictor standard errors")
  draws<-bootstrap$bootstrap_linear_predictor_functions
  .etr_assert(is.array(draws)&&is.numeric(draws)&&
    length(dim(draws))==3L&&dim(draws)[1L]>=1L&&
    identical(dim(draws)[2:3],c(np,nt))&&all(is.finite(draws)),
    "bootstrap_linear_predictor_functions must be a finite B-by-profile-by-time array")
  B<-dim(draws)[1L]
  maxima<-matrix(NA_real_,B,np)
  for(b in seq_len(B)){
    value<-matrix(draws[b,,],nrow=np,ncol=nt)
    maxima[b,]<-apply(abs((value-center)/se),1L,max)
  }
  if(identical(simultaneous_scope,"profile")){
    max_statistics<-maxima
    critical_values<-vapply(seq_len(np),function(j)
      .etr_gfosr_numpy_higher(maxima[,j],confidence_level),numeric(1L))
  }else{
    family_max<-apply(maxima,1L,max)
    max_statistics<-matrix(family_max,ncol=1L)
    critical_values<-rep(.etr_gfosr_numpy_higher(
      family_max,confidence_level),np)
  }
  spread<-matrix(rep(critical_values,each=nt),nrow=np,byrow=TRUE)*se
  lower<-center-spread
  upper<-center+spread
  family<-pred$reference$family
  mean_lower<-.etr_gfosr_predict_inverse_link(lower,family)
  mean_upper<-.etr_gfosr_predict_inverse_link(upper,family)
  provenance<-.etr_gfosr_source_provenance(bootstrap,
    "generalized_function_on_scalar_prediction_band",list(
      confidence_level=confidence_level,
      simultaneous_scope=simultaneous_scope,
      calibration_scale="linear_predictor",
      calibration="whole_participant_bootstrap_max_standardized_deviation",
      linear_predictor_standard_error="gee_robust_delta_method",
      mean_band_transformation="strictly_monotone_inverse_link_endpoints",
      observed_grid_only=TRUE,between_grid_coverage_claim=FALSE,
      profiles_fixed=TRUE,extrapolated_profiles_retained=TRUE,
      automatic_profile_selection=FALSE))
  structure(list(prediction=pred,linear_lower=lower,linear_upper=upper,
    mean_lower=mean_lower,mean_upper=mean_upper,
    critical_values=as.numeric(critical_values),
    max_statistics=max_statistics,confidence_level=confidence_level,
    simultaneous_scope=simultaneous_scope,bootstrap=bootstrap,
    provenance=provenance),class="etr_generalized_fosr_prediction_band")
}
