# Native numerical law of published eyetrajectoriespy==1.2.0
# regression_inference.py::fpca_regression_future_prediction_interval
# frozen commit c1cd95ad718327550f7e55393ff38582872f7a94
#
# Integer seeds select the first NumPy-compatible SeedSequence child.
# Explicit zero-based residual indices replay a retained draw matrix.

#' Marginal future-outcome intervals from paired-bootstrap FPCR predictions
#'
#' Reuses retained conditional-mean predictions and resamples centered
#' Gaussian FPCR training residuals. These intervals target the future
#' noisy outcome under exchangeable errors, not uncertainty in the mean,
#' joint targets or simultaneous coverage. No refit is performed.
#' @param result Source-shaped Gaussian FPCR bootstrap uncertainty record.
#' @param outcome One finite training outcome per reference fitted value.
#' @param confidence_level Marginal interval nominal coverage in (0,1).
#' @param residual_method Must be \code{"empirical_centered"}.
#' @param random_state Nonnegative integer seed below 2^53 for a spawned
#'   NumPy-compatible PCG64 stream. NULL uses the current R RNG stream.
#' @param residual_indices Optional integer matrix B by target of ZERO-BASED
#'   fixed residual indices. These take precedence over the seed.
#' @param random_engine Seeded residual RNG. Use `"base_R"` for the
#'   previous native residual draws, or `"numpy"` for source draws.
#' @return Source-shaped predictive draws, quantiles, sample SD and metadata.
#' @param python_boundary_mode TRUE requires a native source-scientific
#'   FPCARegressionUncertaintyResult analogue and returns exactly the twelve
#'   Python FPCARegressionPredictionIntervalResult scientific fields with
#'   source provenance. Native fixed residual replay and base-R generator
#'   remain available only when FALSE (the default).
#' @export
etr_fpca_regression_future_prediction_interval<-function(
    result,outcome,confidence_level=.95,
    residual_method="empirical_centered",random_state=0L,
    residual_indices=NULL,random_engine="numpy",
    python_boundary_mode=FALSE){
  .etr_assert(is.logical(python_boundary_mode)&&
    length(python_boundary_mode)==1L&&!is.na(python_boundary_mode),
    "python_boundary_mode must be TRUE or FALSE")
  if(isTRUE(python_boundary_mode)){
    .etr_assert(inherits(result,"etr_fpcr_bootstrap_uncertainty"),
      "source mode requires a native FPCARegressionUncertaintyResult analogue")
    .etr_assert(is.null(residual_indices),
      "Python source mode does not accept fixed residual_indices")
    .etr_assert(identical(random_engine,"numpy"),
      "Python source mode requires the NumPy SeedSequence engine")
  }
  .etr_recovery_source_fields(result,c("reference_regression",
    "bootstrap_slopes","bootstrap_mean_predictions",
    "target_curve_ids","target_source","provenance"),
    "FPCR bootstrap uncertainty")
  .etr_recovery_source_fields(result$reference_regression,
    c("family","predictions"),"reference FPCR regression")
  .etr_assert(identical(result$reference_regression$family,"gaussian"),
    "future prediction intervals require a Gaussian FPCR fit")
  .etr_assert(is.numeric(confidence_level)&&
    length(confidence_level)==1L&&!is.na(confidence_level)&&
    is.finite(confidence_level)&&confidence_level>0&&
    confidence_level<1,"confidence_level must lie in (0, 1)")
  .etr_assert(identical(residual_method,"empirical_centered"),
    "residual_method must be 'empirical_centered'")
  fitted<-result$reference_regression$predictions
  .etr_assert(is.numeric(outcome)&&is.null(dim(outcome))&&
    is.numeric(fitted)&&is.null(dim(fitted))&&
    length(outcome)==length(fitted)&&length(outcome)>=2L,
    "outcome must contain exactly one value per training trajectory")
  .etr_assert(all(is.finite(outcome))&&all(is.finite(fitted)),
    "outcome and reference fitted values must be finite")
  draws<-result$bootstrap_mean_predictions
  .etr_assert(is.matrix(draws)&&is.numeric(draws)&&
    all(is.finite(draws)),
    "bootstrap mean predictions must be a finite two-dimensional array")
  slopes<-result$bootstrap_slopes
  .etr_assert(is.array(slopes)&&length(dim(slopes))==3L&&
    is.numeric(slopes),"bootstrap slopes must declare source resample count")
  B<-dim(slopes)[1L];K<-ncol(draws)
  .etr_assert(B>=2L&&nrow(draws)==B&&K>=1L,
    "bootstrap mean prediction count is inconsistent")
  .etr_assert(is.character(result$target_curve_ids)&&
    length(result$target_curve_ids)==K&&!anyNA(result$target_curve_ids),
    "bootstrap target prediction count is inconsistent")
  .etr_assert(is.character(result$target_source)&&
    length(result$target_source)==1L&&
    !is.na(result$target_source),"target_source must be declared")
  .etr_assert(is.list(result$provenance),
    "FPCR uncertainty provenance must be a source-shaped record")
  residuals<-as.numeric(outcome-fitted)
  centered<-residuals-mean(residuals)
  .etr_assert(all(is.finite(centered)),
    "centered FPCR residuals contain non-finite values")
  n<-length(centered)
  if(is.null(residual_indices)){
    random_engine<-match.arg(random_engine,c("numpy","base_R"))
    if(is.null(random_state)||random_engine=="base_R"){
      if(!is.null(random_state)){
        restore<-.etr_simulation_rng(random_state)
        on.exit(restore(),add=TRUE)
      }
      index<-matrix(sample.int(n,as.double(B)*K,replace=TRUE),
        nrow=B,ncol=K)
      rng_source<-"r_native_random_draws_not_numpy_seedsequence"
      rng_stream<-"r_native_random_stream_not_numpy_seedsequence"
    }else{
      child<-.etr_numpy_pcg64(random_state)$spawn(1L)[[1L]]
      index<-matrix(child$integers(as.double(B)*K,n)+1L,
        nrow=B,ncol=K,byrow=TRUE)
      rng_source<-"numpy_seedsequence_spawned_pcg64"
      rng_stream<-"spawned_domain_separated_stream"
    }
  }else{
    .etr_assert(is.matrix(residual_indices)&&
      is.numeric(residual_indices)&&
      identical(dim(residual_indices),c(B,K))&&
      all(is.finite(residual_indices))&&
      all(residual_indices==floor(residual_indices))&&
      all(residual_indices>=0)&&all(residual_indices<n),
      "residual_indices must be a zero-based integer B-by-target matrix")
    index<-matrix(as.integer(residual_indices)+1L,B,K)
    rng_source<-"externally_retained_python_source_indices"
    rng_stream<-"externally_supplied_indices_no_rng_identity_claim"
  }
  sampled<-matrix(centered[index],nrow=B,ncol=K)
  predictive<-draws+sampled
  alpha<-(1-as.numeric(confidence_level))/2
  quantify<-function(prob)as.numeric(apply(predictive,2L,
    stats::quantile,probs=prob,names=FALSE,type=7))
  lower<-quantify(alpha);median<-quantify(.5)
  upper<-quantify(1-alpha)
  se<-as.numeric(apply(predictive,2L,stats::sd))
  .etr_assert(all(is.finite(c(lower,median,upper,se))),
    "future prediction summaries must be finite")
  prov<-result$provenance
  prov[["fpca_regression_future_prediction_interval"]]<-list(
    method="paired_bootstrap_mean_plus_independent_centered_empirical_residual",
    family="gaussian",
    confidence_level=as.numeric(confidence_level),
    residual_method=residual_method,
    residual_source="full_sample_reference_fpcr_fit",
    residuals_centered=TRUE,
    residual_rng_stream=rng_stream,
    residual_exchangeability_assumed=TRUE,
    heteroscedasticity_robust=FALSE,
    future_outcome_prediction_interval=TRUE,
    marginal_per_target=TRUE,
    simultaneous_across_targets=FALSE,
    joint_target_distribution_claimed=FALSE,
    bootstrap_mean_predictions_reused=TRUE,
    n_bootstrap=B,n_training_residuals=n,
    target_source=result$target_source,
    random_state=random_state)
  result_record<-structure(list(
    regression_uncertainty=result,
    centered_residuals=centered,
    sampled_residuals=sampled,
    predictive_draws=predictive,
    lower=lower,median=median,upper=upper,
    predictive_se=se,
    confidence_level=as.numeric(confidence_level),
    residual_method=residual_method,
    random_state=random_state,
    native_rng_source=rng_source,
    provenance=prov),
    class="etr_fpcr_future_prediction_interval")
  if(isTRUE(python_boundary_mode))
    result_record$native_rng_source<-NULL
  result_record
}
