# Frozen Python 1.2 descriptive covariance sensitivity, bounded native moments
# analogue (NOT the Python Gaussian spline MixedLM / REML implementation).
test_that("native mixed covariance comparison uses predeclared full compatible fits",{
  f<-.etr_mixed_sensitivity_fixture()
  model<-function(ridge)etr_fit_functional_mixed_effects_regression(
    f$tr,f$design,predictors="x",
    participant_column="participant_id",
    dimension="y",covariance_ridge=ridge)
  a<-model(1e-6)
  b<-model(.01)
  z<-etr_functional_mixed_effects_covariance_sensitivity(
    fits=list(reference=a,alternative=b),
    reference="reference",max_lag=3L)
  expect_s3_class(z,"etr_functional_mixed_effects_covariance_sensitivity")
  expect_identical(nrow(z$model_summary),2L)
  expect_equal(nrow(z$coefficient_summary),4L)
  expect_equal(nrow(z$coefficient_frame),2L*2L*9L)
  expect_equal(nrow(z$residual_diagnostics),6L)
  expect_true(all(z$coefficient_summary$
    sup_abs_difference_from_reference>=0))
  expect_equal(z$coefficient_summary$
    sup_abs_difference_from_reference[z$coefficient_summary$model=="reference"],
    c(0,0))
  expect_true(all(is.na(z$model_summary$aic)))
  expect_true(all(is.na(z$model_summary$bic)))
  expect_false(z$model_selected)
  expect_false(z$likelihood_ratio_tests_performed)
  expect_false(z$independent_full_source_certified)
  expect_false(z$source_python_equivalent)
  expect_true(all(is.finite(z$residual_diagnostics$residual_rms_global)))
  expect_true(all(is.finite(z$residual_diagnostics$lag_correlation)))
})

test_that("mixed covariance sensitivity preserves failed declarations",{
  f<-.etr_mixed_sensitivity_fixture()
  a<-etr_fit_functional_mixed_effects_regression(
    f$tr,f$design,"x","participant_id","y")
  spec<-list(
    model=list(estimator=a$estimator,covariance_ridge=1e-6),
    failed=list(estimator="two_level_functional_method_of_moments",
      covariance_ridge=.05))
  z<-etr_functional_mixed_effects_covariance_sensitivity(
    list(model=a),reference="model",max_lag=1L,
    specifications=spec,failures=list(failed="convergence failed"))
  expect_equal(nrow(z$model_summary),2L)
  expect_identical(z$model_summary$status,c("success","failed"))
  expect_error(etr_functional_mixed_effects_covariance_sensitivity(
    list(model=a),"model",1L,
    failures=list(failed="not estimated")),"specifications")
  expect_error(etr_functional_mixed_effects_covariance_sensitivity(
    list(model=a),"model",1L,bands=list(model=list())),
    "not source-equivalent")
  expect_error(etr_functional_mixed_effects_covariance_sensitivity(
    list(model=a),"model",9L),"max_lag")
  invalid<-a
  invalid$source_curve_ids<-rev(invalid$source_curve_ids)
  expect_error(etr_functional_mixed_effects_covariance_sensitivity(
    list(model=a,bad=invalid),"model",1L),"source_curve_ids")
  expect_error(etr_functional_mixed_effects_covariance_sensitivity(
    list(model=a),"model",1L,specifications=list(model=list(
      estimator=a$estimator,covariance_ridge=.1))),"ridge")
})
