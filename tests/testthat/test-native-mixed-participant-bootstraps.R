# Bounded native mixed-method-of-moments bootstrap source contract:
# neither estimator is the Python 1.2 spline MixedLM likelihood engine.

.etr_native_mixed_deterministic_draws<-function(B=100L,np=6L){
  out<-matrix(0L,B,np)
  for(i in seq_len(B))out[i,]<-(0:(np-1L)+i-1L)%%np
  out[1L,]<-c(0L,0L,0L,1L,2L,3L)
  out
}

test_that("conditional native mixed bootstrap keeps covariance fixed",{
  f<-.etr_mixed_sensitivity_fixture()
  ref<-etr_fit_functional_mixed_effects_regression(f$tr,f$design,
    "x","participant_id","y")
  draw<-.etr_native_mixed_deterministic_draws()
  z<-etr_bootstrap_functional_mixed_effects_coefficients(
    ref,n_bootstrap=100L,sampled_participant_indices=draw)
  expect_s3_class(z,"etr_mixed_moments_conditional_bootstrap")
  expect_identical(dim(z$bootstrap_coefficient_functions),
    c(100L,2L,9L))
  expect_identical(z$sampled_participant_indices,draw)
  expect_equal(dim(z$bootstrap_standard_errors),c(2L,9L))
  expect_true(all(is.finite(z$bootstrap_coefficient_functions)))
  expect_true(all(z$bootstrap_standard_errors>=0))
  expect_false(z$provenance$covariance_components_refit)
  expect_false(z$provenance$full_source_contract_certified)
  expect_false(z$provenance$full_python_source_contract_equivalent)
})

test_that("native full participant bootstrap refits covariance for each draw",{
  f<-.etr_mixed_sensitivity_fixture()
  ref<-etr_fit_functional_mixed_effects_regression(f$tr,f$design,
    "x","participant_id","y")
  draw<-.etr_native_mixed_deterministic_draws()
  z<-etr_bootstrap_functional_mixed_effects_full_refit(
    ref,n_bootstrap=100L,sampled_participant_indices=draw)
  expect_s3_class(z,"etr_mixed_moments_full_refit_bootstrap")
  expect_identical(dim(z$bootstrap_coefficient_functions),
    c(100L,2L,9L))
  expect_identical(dim(z$random_intercept_covariances),
    c(100L,9L,9L))
  expect_length(z$residual_variances,100L)
  expect_true(all(z$residual_variances>0))
  expect_true(all(is.finite(z$bootstrap_coefficient_functions)))
  expect_identical(z$sampled_source_participant_ids[[1L]],
    ref$participant_ids[draw[1L,]+1L])
  expect_identical(length(unique(
    z$sampled_bootstrap_participant_ids[[1L]])),6L)
  expect_true(z$provenance$covariance_components_refit)
  expect_false(z$provenance$full_python_source_contract_equivalent)
  expect_false(z$provenance$full_source_contract_certified)
  expect_error(etr_bootstrap_functional_mixed_effects_full_refit(
    ref,n_bootstrap=99L),"at least 100")
  expect_error(etr_bootstrap_functional_mixed_effects_coefficients(
    ref,n_bootstrap=100L,
    sampled_participant_indices=matrix(6,100,6)),
    "zero-based")
})

# Actual frozen-Python 1.2 source-symbol inspection on published exports.
# For alternate R estimands/backends this is NOT numerical source parity.
test_that("unreviewed Python 1.2 source symbols are inspectable: bootstrap_functional_mixed_effects_coefficients, bootstrap_functional_mixed_effects_full_refit",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python source-symbol audit requires source runtime")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("bootstrap_functional_mixed_effects_coefficients"),"bootstrap_functional_mixed_effects_coefficients")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("bootstrap_functional_mixed_effects_full_refit"),"bootstrap_functional_mixed_effects_full_refit")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
