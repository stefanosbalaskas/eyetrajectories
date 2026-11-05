# Pinned Python 1.2.0 generalized_function_on_scalar_prediction.py
# c1cd95ad718327550f7e55393ff38582872f7a94
# One predeclared contrast only, derived from previously retained bootstrap
# predictions. Does not bootstrap, fit, choose a pair, or adjust multiple tests.

#' Simultaneous observed-grid marginal contrast for two fixed profiles
#'
#' Source-aligned difference and rate-ratio inference from already retained
#' participant bootstrap predictions. Rate ratios are calibrated on the
#' log-ratio scale; physically impossible binomial-difference intervals are
#' flagged but never clipped.
#' @param bootstrap Fixed-profile native prediction-bootstrap result.
#' @param profile_a Identifier for the first predeclared target profile.
#' @param profile_b Identifier for the second predeclared target profile.
#' @param confidence_level Nominal confidence level strictly inside (0,1).
#' @param contrast_scale One declared source-compatible contrast type.
#' @return Native single-contrast inference record on the observed time grid.
#' @export
etr_generalized_function_on_scalar_mean_difference_band <- function(
    bootstrap,profile_a,profile_b,confidence_level=.95,
    contrast_scale=NULL){
  .etr_scientific_frame_fields(bootstrap,c("prediction",
    "bootstrap_mean_functions"),"prediction bootstrap")
  pred<-bootstrap$prediction
  .etr_scientific_frame_fields(pred,c("profile_ids","reference",
    "mean_functions","extrapolation_flags","prediction_scale"),
    "prediction")
  .etr_assert(is.character(profile_a)&&length(profile_a)==1L&&
    !is.na(profile_a)&&nzchar(profile_a),
    "profile_a must be a nonempty string")
  .etr_assert(is.character(profile_b)&&length(profile_b)==1L&&
    !is.na(profile_b)&&nzchar(profile_b),
    "profile_b must be a nonempty string")
  .etr_assert(!identical(profile_a,profile_b),
    "profile_a and profile_b must be different")
  .etr_assert(is.numeric(confidence_level)&&
    length(confidence_level)==1L&&!is.logical(confidence_level)&&
    is.finite(confidence_level)&&confidence_level>0&&
    confidence_level<1,"confidence_level must lie in (0,1)")
  ids<-.etr_scientific_frame_ids(pred$profile_ids,"profile_ids")
  a<-match(profile_a,ids);b<-match(profile_b,ids)
  .etr_assert(!is.na(a)&&!is.na(b),
    "Unknown profile identifier(s) in declared contrast")
  .etr_scientific_frame_fields(pred$reference,c("time","family"),
    "source fit")
  time<-.etr_scientific_frame_time(pred$reference$time)
  np<-length(ids);nt<-length(time)
  family<-pred$reference$family
  exposure<-!is.null(pred$reference$exposure)
  .etr_assert(identical(family,"binomial")||identical(family,"poisson"),
    "unsupported generalized FoSR family")
  allowed<-if(identical(family,"binomial"))"probability_difference"
    else if(exposure)c("rate_difference","rate_ratio",
      "expected_count_difference") else "expected_count_difference"
  selected<-if(is.null(contrast_scale)){
    if(identical(family,"binomial"))"probability_difference"
    else if(exposure)"rate_difference" else "expected_count_difference"
  }else{
    .etr_assert(is.character(contrast_scale)&&
      length(contrast_scale)==1L&&!is.na(contrast_scale),
      "contrast_scale must be a single string or NULL")
    contrast_scale
  }
  .etr_assert(selected%in%allowed,
    paste("contrast_scale must be one of",paste(allowed,collapse=", ")))
  if(selected=="expected_count_difference")
    .etr_assert(!is.null(pred$expected_count_functions),
      "expected_count_difference requires prediction_scale='expected_count' and explicit target exposure for adjusted fits")
  mean<-.etr_gfosr_predict_numeric_matrix(pred$mean_functions,np,nt,
    "mean_functions")
  flags<-pred$extrapolation_flags
  .etr_assert(is.logical(flags)&&length(flags)==np&&!anyNA(flags),
    "extrapolation_flags must have one nonmissing logical value per profile")
  mean_draws<-bootstrap$bootstrap_mean_functions
  .etr_assert(is.array(mean_draws)&&is.numeric(mean_draws)&&
    length(dim(mean_draws))==3L&&
    identical(dim(mean_draws)[2:3],c(np,nt))&&
    dim(mean_draws)[1L]>=2L&&all(is.finite(mean_draws)),
    "bootstrap_mean_functions must contain finite B-by-profile-by-time draws with B >= 2")
  B<-dim(mean_draws)[1L]
  source_matrix<-function(x,label){
    .etr_gfosr_predict_numeric_matrix(x,np,nt,label)
  }
  source_draws<-function(x,label){
    .etr_assert(is.array(x)&&is.numeric(x)&&
      identical(dim(x),c(B,np,nt))&&all(is.finite(x)),
      paste(label,"must match the B-by-profile-by-time source shape"))
    x
  }
  if(selected%in%c("rate_difference","rate_ratio")){
    base<-source_matrix(pred$rate_functions,"rate_functions")
    draws<-source_draws(bootstrap$bootstrap_rate_functions,
      "bootstrap_rate_functions")
  }else if(selected=="expected_count_difference"){
    base<-source_matrix(pred$expected_count_functions,
      "expected_count_functions")
    draws<-source_draws(bootstrap$bootstrap_expected_count_functions,
      "bootstrap_expected_count_functions")
  }else {
    base<-mean
    draws<-mean_draws
  }
  d_a<-matrix(draws[,a,],nrow=B,ncol=nt)
  d_b<-matrix(draws[,b,],nrow=B,ncol=nt)
  if(selected=="rate_ratio"){
    .etr_assert(all(base[b,]>0)&&all(d_b>0)&&
      all(base[a,]>0)&&all(d_a>0),
      "rate ratio requires strictly positive finite rate functions")
    estimate<-as.numeric(base[a,]/base[b,])
    bootstrap_estimates<-d_a/d_b
    inference_estimate<-log(estimate)
    inference_draws<-log(bootstrap_estimates)
    inference_scale<-"log_rate_ratio"
  }else {
    estimate<-as.numeric(base[a,]-base[b,])
    bootstrap_estimates<-d_a-d_b
    inference_estimate<-estimate
    inference_draws<-bootstrap_estimates
    inference_scale<-selected
  }
  .etr_assert(all(is.finite(estimate))&&
    all(is.finite(bootstrap_estimates))&&
    all(is.finite(inference_draws)),
    "contrast inference must have finite source estimates")
  se<-apply(inference_draws,2L,stats::sd)
  .etr_assert(all(is.finite(se))&&all(se>.Machine$double.eps),
    "contrast simultaneous band requires strictly positive finite bootstrap standard errors")
  centered<-sweep(inference_draws,2L,inference_estimate,"-")
  standardized<-abs(sweep(centered,2L,se,"/"))
  maxima<-apply(standardized,1L,max)
  critical<-.etr_gfosr_numpy_higher(maxima,confidence_level)
  inferred_lower<-inference_estimate-critical*se
  inferred_upper<-inference_estimate+critical*se
  lower<-if(selected=="rate_ratio")exp(inferred_lower) else inferred_lower
  upper<-if(selected=="rate_ratio")exp(inferred_upper) else inferred_upper
  .etr_assert(all(is.finite(lower))&&all(is.finite(upper)),
    "contrast interval endpoints must remain finite")
  physical_lower<-if(selected=="probability_difference")-1 else NULL
  physical_upper<-if(selected=="probability_difference")1 else NULL
  exceeds<-if(selected=="probability_difference")
    any(lower< -1|upper>1) else FALSE
  provenance<-.etr_gfosr_source_provenance(bootstrap,
    "generalized_function_on_scalar_mean_difference_band",list(
      contrast=paste0(profile_a," - ",profile_b),
      response_scale=selected,inference_scale=inference_scale,
      rate_ratio_band_calibrated_on_log_scale=selected=="rate_ratio",
      profiles_fixed=TRUE,profile_pair_predeclared=TRUE,
      profile_pair_extrapolated=isTRUE(flags[a])||isTRUE(flags[b]),
      standard_error="participant_bootstrap_standard_deviation",
      calibration="observed_grid_max_standardized_bootstrap_deviation",
      confidence_level=confidence_level,physical_bounds_clipped=FALSE,
      interval_exceeds_physical_bounds=exceeds,
      multiple_contrast_family_adjustment=FALSE,
      automatic_contrast_selection=FALSE))
  structure(list(prediction_bootstrap=bootstrap,profile_a=profile_a,
    profile_b=profile_b,estimate=estimate,standard_error=as.numeric(se),
    lower=as.numeric(lower),upper=as.numeric(upper),
    bootstrap_estimates=bootstrap_estimates,
    max_statistics=as.numeric(maxima),critical_value=as.numeric(critical),
    confidence_level=confidence_level,
    physical_lower_bound=physical_lower,
    physical_upper_bound=physical_upper,
    interval_exceeds_physical_bounds=exceeds,contrast_scale=selected,
    inference_scale=inference_scale,provenance=provenance),
    class="etr_generalized_fosr_mean_difference_band")
}
