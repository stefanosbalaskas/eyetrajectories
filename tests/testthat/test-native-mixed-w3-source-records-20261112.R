# Frozen Python 1.2 source scientific mixed-effects result envelopes:
# types.py::FunctionalMixedEffectsBootstrapResult,
# types.py::FunctionalMixedEffectsFullRefitBootstrapResult,
# types.py::FunctionalMixedEffectsCovarianceSensitivityResult.
# Frozen commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Native nlme likelihood is not a Python statsmodels optimizer.

test_that("strict mixed coefficient bootstrap preserves 9 source fields and native Gaussian GLS",{
  skip_if_not_installed("nlme")
  fit<-.etr_joint_fixed_boot_fixture()
  original<-etr_bootstrap_functional_mixed_effects_coefficients(
    fit,n_bootstrap=100L,random_state=31L)
  strict<-etr_bootstrap_functional_mixed_effects_coefficients(
    fit,n_bootstrap=100L,random_state=31L,
    strict_source_record=TRUE)
  expect_s3_class(strict,"etr_mixed_w3_coefficient_source_record")
  expect_identical(names(strict),.etr_mixed_w3_conditional_fields)
  expect_identical(length(names(strict)),9L)
  for(field in names(strict))
    expect_identical(strict[[field]],original[[field]],
      info=paste("frozen conditional source",field))
  expect_identical(dim(strict$bootstrap_fixed_basis_coefficients),
    c(100L,2L,2L))
  expect_identical(dim(strict$bootstrap_coefficient_functions),
    c(100L,2L,7L))
  expect_identical(dim(strict$sampled_participant_indices),
    c(100L,8L))
  expect_equal(strict$bootstrap_mean,
    apply(strict$bootstrap_coefficient_functions,c(2L,3L),mean),
    tolerance=1e-13,ignore_attr=TRUE)
  expect_equal(strict$bootstrap_standard_errors,
    apply(strict$bootstrap_coefficient_functions,c(2L,3L),stats::sd),
    tolerance=1e-13,ignore_attr=TRUE)
  expect_false("bootstrap_type"%in%names(strict))
  expect_false("source_python_full_contract_certified"%in%names(strict))
  expect_identical(strict$covariance_conditioning,
    "reference_participant_and_residual_covariance_fixed")
})

test_that("strict full-refit bootstrap keeps 33 Python fields and real variance-component refits",{
  skip_if_not_installed("nlme")
  fit<-.etr_joint_full_refit_reference()
  strict<-etr_bootstrap_functional_mixed_effects_full_refit(
    fit,n_bootstrap=20L,random_state=73L,
    strict_source_record=TRUE)
  expect_s3_class(strict,"etr_mixed_w3_full_refit_source_record")
  expect_identical(names(strict),.etr_mixed_w3_full_refit_fields)
  expect_identical(dim(strict$sampled_participant_indices),c(20L,8L))
  expect_identical(dim(strict$bootstrap_fixed_basis_coefficients),
    c(20L,2L,2L))
  expect_identical(dim(strict$bootstrap_coefficient_functions),
    c(20L,2L,7L))
  expect_identical(dim(strict$random_effect_covariances),
    c(20L,2L,2L))
  expect_identical(dim(strict$random_intercept_covariances),
    c(20L,2L,2L))
  expect_identical(length(strict$bootstrap_participant_ids),20L)
  expect_identical(length(strict$sampled_source_participant_ids),20L)
  expect_true(all(strict$convergence_flags))
  expect_true(all(is.finite(strict$log_likelihoods)))
  expect_true(all(strict$residual_variances>0))
  expect_true(all(is.finite(strict$bootstrap_coefficient_functions)))
  expect_equal(strict$bootstrap_mean,
    apply(strict$bootstrap_coefficient_functions,c(2L,3L),mean),
    tolerance=1e-12,ignore_attr=TRUE)
  expect_false("bootstrap_type"%in%names(strict))
  expect_false("variance_components_refit"%in%names(strict))
  expect_false("source_python_full_contract_certified"%in%names(strict))
  expect_false(strict$provenance$
    functional_mixed_effects_full_refit_bootstrap$
    python_statsmodels_optimizer_equivalent)
})

test_that("strict likelihood covariance sensitivity emits 12 Python scientific fields",{
  skip_if_not_installed("nlme")
  fit<-.etr_joint_fixed_boot_fixture()
  models<-list(iid_reference=fit,iid_replica=fit)
  raw<-etr_functional_mixed_effects_covariance_sensitivity(
    models,"iid_reference",max_lag=2L)
  strict<-etr_functional_mixed_effects_covariance_sensitivity(
    models,"iid_reference",max_lag=2L,
    strict_source_record=TRUE)
  expect_s3_class(strict,"etr_mixed_w3_sensitivity_source_record")
  expect_identical(names(strict),.etr_mixed_w3_sensitivity_fields)
  expect_identical(strict$reference_label,"iid_reference")
  expect_identical(strict$max_lag,2L)
  expect_identical(length(strict$specifications),2L)
  expect_identical(strict$specifications[[1L]],
    list(name="iid_reference",random_slope_predictor=NULL,
      trial_random_effect=NULL,residual_correlation="iid"))
  expect_identical(strict$fits,models)
  expect_identical(strict$model_summary,raw$model_summary)
  expect_identical(strict$coefficient_frame,raw$coefficient_frame)
  expect_identical(strict$variance_decomposition,raw$variance_decomposition)
  expect_identical(strict$residual_diagnostics,raw$residual_diagnostics)
  expect_identical(strict$model_summary$status,c("success","success"))
  expect_equal(strict$model_summary$delta_aic,c(0,0),tolerance=1e-12)
  expect_equal(strict$model_summary$delta_bic,c(0,0),tolerance=1e-12)
  expect_false("information_criterion_available"%in%names(strict))
  expect_false("model_selected"%in%names(strict))
  expect_false("independent_full_source_certified"%in%names(strict))
})

test_that("strict mixed inference refuses moments and R-only fixed draw injection",{
  skip_if_not_installed("nlme")
  fit<-.etr_joint_fixed_boot_fixture()
  moment<-structure(list(),class="etr_functional_mixed_moments")
  expect_error(etr_bootstrap_functional_mixed_effects_coefficients(
    moment,n_bootstrap=100L,strict_source_record=TRUE),
    "joint spline likelihood")
  expect_error(etr_bootstrap_functional_mixed_effects_full_refit(
    moment,n_bootstrap=20L,strict_source_record=TRUE),
    "joint spline likelihood")
  expect_error(etr_bootstrap_functional_mixed_effects_coefficients(
    fit,n_bootstrap=100L,strict_source_record=1L),
    "strict_source_record")
  expect_error(etr_bootstrap_functional_mixed_effects_full_refit(
    fit,n_bootstrap=20L,strict_source_record=NA),
    "strict_source_record")
  expect_error(etr_bootstrap_functional_mixed_effects_coefficients(
    fit,n_bootstrap=100L,sampled_participant_indices=matrix(
      0L,nrow=100L,ncol=8L),strict_source_record=TRUE),
    "externally supplied participant draws")
  expect_error(etr_functional_mixed_effects_covariance_sensitivity(
    list(moments=moment),"moments",2L,
    strict_source_record=TRUE),"joint spline likelihood")
  expect_error(etr_functional_mixed_effects_covariance_sensitivity(
    list(model=fit),"model",2L,
    strict_source_record=NA),"strict_source_record")
  expect_error(etr_functional_mixed_effects_covariance_sensitivity(
    list(model=fit,moment=moment),"model",2L,
    strict_source_record=TRUE),"joint spline likelihood")
})

test_that("frozen Python 1.2 mixed scientific dataclass fields equal strict native R W3 envelopes",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 dataclass field contract requires opt-in oracle")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
from dataclasses import fields
from eyetrajectoriespy.types import (
  FunctionalMixedEffectsBootstrapResult,
  FunctionalMixedEffectsFullRefitBootstrapResult,
  FunctionalMixedEffectsCovarianceSensitivityResult,
  FunctionalMixedEffectsCovarianceSpecification,
)
def _etr_w3_dataclass_names():
    return {
      'conditional': tuple(x.name for x in fields(FunctionalMixedEffectsBootstrapResult)),
      'full_refit': tuple(x.name for x in fields(FunctionalMixedEffectsFullRefitBootstrapResult)),
      'sensitivity': tuple(x.name for x in fields(FunctionalMixedEffectsCovarianceSensitivityResult)),
      'spec': tuple(x.name for x in fields(FunctionalMixedEffectsCovarianceSpecification)),
    }
")
  fields<-et_to_r(reticulate::py_call(
    reticulate::py_eval("_etr_w3_dataclass_names",convert=FALSE)))
  expect_identical(.etr_mixed_w3_conditional_fields,
    as.character(fields$conditional))
  expect_identical(.etr_mixed_w3_full_refit_fields,
    as.character(fields$full_refit))
  expect_identical(.etr_mixed_w3_sensitivity_fields,
    as.character(fields$sensitivity))
  expect_identical(as.character(fields$spec),
    c("name","random_slope_predictor",
      "trial_random_effect","residual_correlation"))
})
