# Native numerical law of published eyetrajectoriespy==1.2.0
# regression_inference.py::fpca_regression_future_prediction_interval
# frozen commit c1cd95ad718327550f7e55393ff38582872f7a94
#
# Source SeedSequence.spawn(1) + NumPy PCG64 random draws are NOT reproduced
# by R's RNG. Supply zero-based residual_indices for a fixed-draw comparison
# against pinned Python. Otherwise R uses its own RNG with the same
# independent empirical-residual sampling *distribution*, not bit parity.
# This is NOT a full source contract certificate.

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
#' @param random_state R RNG seed; differs from Python SeedSequence even
#'   for identical integer seeds. NULL uses the current R RNG stream.
#' @param residual_indices Optional integer matrix B by target of ZERO-BASED
#'   fixed residual indices from Python's source RNG. Enables direct
#'   numerical source-law parity without asserting cross-language RNG parity.
#' @return Source-shaped predictive draws, quantiles, sample SD and metadata.
#' @export
etr_fpca_regression_future_prediction_interval<-function(
    result,outcome,confidence_level=.95,
    residual_method="empirical_centered",random_state=0L,
    residual_indices=NULL){
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
    .etr_assert(is.null(random_state)||(
      is.numeric(random_state)&&length(random_state)==1L&&
      is.finite(random_state)&&random_state==floor(random_state)&&
      random_state>=0&&random_state<=.Machine$integer.max),
      "R random_state must be a nonnegative integer or NULL")
    if(!is.null(random_state)){
      had_rng<-exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE)
      if(had_rng)prior_rng<-get(".Random.seed",envir=.GlobalEnv)
      on.exit({
        if(had_rng)assign(".Random.seed",prior_rng,envir=.GlobalEnv)
        else if(exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE))
          rm(".Random.seed",envir=.GlobalEnv)
      },add=TRUE)
      set.seed(as.integer(random_state))
    }
    index<-matrix(sample.int(n,B*K,replace=TRUE),
      nrow=B,ncol=K)
    rng_source<-"r_native_random_draws_not_numpy_seedsequence"
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
    # Supplying external draws does not prove the producing RNG stream.
    # The frozen Python provenance is deliberately NOT copied here.
    residual_rng_stream=if(identical(rng_source,
      "externally_retained_python_source_indices"))
      "externally_supplied_indices_no_rng_identity_claim" else
      "r_native_random_stream_not_numpy_seedsequence",
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
  structure(list(
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
}
