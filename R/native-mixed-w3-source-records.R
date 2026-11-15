# Frozen Python 1.2 public source scientific dataclasses for mixed-effects
# inference. Scientific record shape only: R spline/nlme fit != Python
# statsmodels fitted runtime identity. Both native algorithms operate on
# genuine fitted random-effect covariance and observed functional data.
# Frozen commit c1cd95ad718327550f7e55393ff38582872f7a94,
# source: types.py, functional_mixed_effects_inference.py,
# functional_mixed_effects_full_refit.py,
# functional_mixed_effects_covariance_sensitivity.py.

.etr_mixed_w3_conditional_fields<-c(
  "reference","bootstrap_fixed_basis_coefficients",
  "bootstrap_coefficient_functions","sampled_participant_indices",
  "bootstrap_mean","bootstrap_standard_errors","random_state",
  "covariance_conditioning","provenance")

.etr_mixed_w3_full_refit_fields<-c(
  "reference","bootstrap_fixed_basis_coefficients",
  "bootstrap_coefficient_functions","sampled_participant_indices",
  "sampled_source_participant_ids","bootstrap_participant_ids",
  "bootstrap_mean","bootstrap_standard_errors",
  "random_effect_covariances","random_intercept_covariances",
  "random_slope_covariances","random_intercept_slope_covariances",
  "random_effect_covariance_eigenvalues",
  "random_effect_covariance_condition_numbers",
  "random_effect_boundary_flags","random_effect_singular_flags",
  "random_slope_boundary_flags","residual_variances",
  "log_likelihoods","convergence_flags","backend_warnings",
  "random_state","provenance",
  "trial_random_effect_covariances",
  "trial_random_effect_covariance_eigenvalues",
  "trial_random_effect_covariance_condition_numbers",
  "trial_random_effect_boundary_flags",
  "trial_random_effect_singular_flags","bootstrap_trial_audit",
  "residual_correlation_parameters",
  "residual_correlation_boundary_flags",
  "residual_correlation_independence_flags",
  "residual_correlation_condition_numbers")

.etr_mixed_w3_sensitivity_fields<-c(
  "specifications","reference_label","fits","failures",
  "model_summary","coefficient_frame","coefficient_summary",
  "band_width_frame","variance_decomposition",
  "residual_diagnostics","max_lag","provenance")

.etr_mixed_w3_source_mode<-function(strict,result,
    sampled_participant_indices){
  .etr_assert(is.logical(strict)&&length(strict)==1L&&!is.na(strict),
    "strict_source_record must be a nonmissing logical scalar")
  if(isTRUE(strict)){
    .etr_assert(inherits(result,"etr_joint_bspline_mixed")&&
      inherits(result$fitted_model,"lme"),
      "strict mixed W3 source requires genuine native joint spline likelihood model")
    .etr_assert(is.null(sampled_participant_indices),
      "strict Python source API does not accept externally supplied participant draws")
  }
  invisible(TRUE)
}

.etr_mixed_w3_coefficients_record<-function(out){
  .etr_assert(inherits(out,"etr_joint_mixed_fixed_covariance_bootstrap")&&
    identical(out$bootstrap_type,"conditional_covariance"),
    "strict source coefficient bootstrap requires genuine participant GLS")
  .etr_assert(all(.etr_mixed_w3_conditional_fields%in%names(out)),
    "strict source coefficient bootstrap result has missing scientific fields")
  result<-out[.etr_mixed_w3_conditional_fields]
  .etr_assert(is.array(result$bootstrap_coefficient_functions)&&
    length(dim(result$bootstrap_coefficient_functions))==3L,
    "source coefficient bootstrap must retain 3-dimensional coefficient curves")
  .etr_assert(is.matrix(result$sampled_participant_indices)&&
    identical(dim(result$bootstrap_coefficient_functions)[1L],
      nrow(result$sampled_participant_indices)),
    "source conditional participant draw dimensions are inconsistent")
  .etr_assert(all(is.finite(result$bootstrap_coefficient_functions))&&
    all(is.finite(result$bootstrap_standard_errors)),
    "source conditional coefficient bootstrap returned nonfinite estimates")
  structure(result,class=c("etr_mixed_w3_coefficient_source_record","list"))
}

.etr_mixed_w3_full_refit_record<-function(out){
  .etr_assert(inherits(out,
      "etr_joint_mixed_likelihood_full_refit_bootstrap")&&
      identical(out$bootstrap_type,"full_refit")&&
      isTRUE(out$variance_components_refit),
    "strict full-refit source requires fitted Gaussian covariance re-estimation")
  .etr_assert(all(.etr_mixed_w3_full_refit_fields%in%names(out)),
    "strict source full-refit bootstrap missing scientific result fields")
  result<-out[.etr_mixed_w3_full_refit_fields]
  B<-nrow(result$sampled_participant_indices)
  .etr_assert(is.array(result$bootstrap_coefficient_functions)&&
    length(dim(result$bootstrap_coefficient_functions))==3L&&
    dim(result$bootstrap_coefficient_functions)[1L]==B&&
    dim(result$bootstrap_fixed_basis_coefficients)[1L]==B&&
    length(result$residual_variances)==B&&
    length(result$log_likelihoods)==B&&
    all(result$convergence_flags)&&
    all(is.finite(result$residual_variances))&&
    all(result$residual_variances>0)&&
    all(is.finite(result$log_likelihoods)),
    "strict full-refit bootstrap has missing or incomplete likelihood refits")
  structure(result,class=c("etr_mixed_w3_full_refit_source_record","list"))
}

.etr_mixed_w3_sensitivity_record<-function(out,fits,max_lag){
  .etr_assert(inherits(out,
      "etr_joint_likelihood_covariance_sensitivity")&&
      !isTRUE(out$model_selected)&&!isTRUE(out$ranking_performed)&&
      !isTRUE(out$likelihood_ratio_tests_performed),
    "strict covariance sensitivity cannot rank, select or test models")
  .etr_assert(is.list(fits)&&length(fits)>=1L&&
    !is.null(names(fits))&&!anyDuplicated(names(fits)),
    "strict covariance sensitivity must preserve named fitted likelihood models")
  specs<-lapply(names(out$specifications),function(name){
    spec<-out$specifications[[name]]
    list(
      name=name,
      random_slope_predictor=spec$random_slope_predictor,
      trial_random_effect=spec$trial_random_effect,
      residual_correlation=if(is.null(spec$residual_correlation))
        "iid" else spec$residual_correlation)
  })
  names(specs)<-NULL
  result<-list(
    specifications=specs,
    reference_label=out$reference,
    fits=fits,failures=out$failures,
    model_summary=out$model_summary,
    coefficient_frame=out$coefficient_frame,
    coefficient_summary=out$coefficient_summary,
    band_width_frame=out$band_width_frame,
    variance_decomposition=out$variance_decomposition,
    residual_diagnostics=out$residual_diagnostics,
    max_lag=as.integer(max_lag),
    provenance=out$provenance)
  .etr_assert(identical(names(result),.etr_mixed_w3_sensitivity_fields)&&
    all(vapply(result[c("model_summary","coefficient_frame",
      "coefficient_summary","band_width_frame","variance_decomposition",
      "residual_diagnostics")],is.data.frame,logical(1L))),
    "strict sensitivity scientific result violates frozen source field structure")
  structure(result,class=c("etr_mixed_w3_sensitivity_source_record","list"))
}
