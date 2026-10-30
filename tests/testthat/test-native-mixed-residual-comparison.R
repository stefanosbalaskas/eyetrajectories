# Restricted native mixed-moment sensitivity is descriptive and never a
# Python MixedLM/optimizer equivalence claim.
.etr_source_mixed_comparison_fit <- function(residuals) {
  structure(list(
    estimator="two_level_functional_method_of_moments",
    converged=TRUE,dimension_name="pupil",time_unit="s",
    source_curve_ids=c("c1","c2"),
    curve_participant_ids=c("p1","p2"),
    time=c(0,.5,1),
    residual_functions=residuals),
    class="etr_functional_mixed_moments")
}
test_that("native mixed residual comparison preserves source 0-based lag keys",{
  first<-.etr_source_mixed_comparison_fit(
    matrix(c(1,2,4,2,4,7),nrow=2,byrow=TRUE))
  second<-.etr_source_mixed_comparison_fit(
    matrix(c(1,3,5,2,5,7),nrow=2,byrow=TRUE))
  x<-etr_compare_functional_mixed_effects_residual_diagnostics(
    first,second,max_lag=2L,reference_label="base",
    comparison_label="expanded")
  expect_identical(x$lag_index,0:2)
  expect_identical(x$reference_label,rep("base",3L))
  expect_identical(x$comparison_label,rep("expanded",3L))
  expect_identical(x$residual_scale,rep("raw",3L))
  expect_identical(x$n_pairs,c(6L,4L,2L))
  expect_true(all(c("delta_autocovariance","delta_autocorrelation",
    "delta_semivariance")%in%names(x)))
  expect_equal(x$delta_autocovariance,
    x$autocovariance_comparison-x$autocovariance_reference)
  expect_equal(x$delta_semivariance,
    x$semivariance_comparison-x$semivariance_reference)
  expect_equal(x$delta_autocorrelation,
    x$autocorrelation_comparison-x$autocorrelation_reference)
  expect_true(all(is.finite(x$delta_semivariance)))
  expect_identical(ncol(x),20L)
})
test_that("mixed residual sensitivity never compares unmatched cohorts or grids",{
  a<-.etr_source_mixed_comparison_fit(
    matrix(c(1,2,4,2,4,7),2,3,byrow=TRUE))
  b<-a;b$residual_functions<-b$residual_functions*1.2
  b$source_curve_ids<-rev(b$source_curve_ids)
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    a,b,max_lag=1L),"source curves")
  b<-a;b$time<-c(0,.6,1)
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    a,b,max_lag=1L),"same observed time grid")
  b<-a;b$dimension_name<-"other"
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    a,b,max_lag=1L),"same response dimension")
  b<-a;b$curve_participant_ids<-rev(b$curve_participant_ids)
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    a,b,max_lag=1L),"participant mapping")
  b<-a
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    a,b,max_lag=3L),"max_lag")
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    a,b,max_lag=1L,residual_scale="unknown"),"residual_scale")
})
test_that("source mixed residual comparison remains an unsigned native subset",{
  name<-"compare_functional_mixed_effects_residual_diagnostics"
  p<-etr_native_parity_catalog()
  a<-p[p$is_python_function&p$python_name==name,,drop=FALSE]
  expect_equal(nrow(a),1L)
  expect_identical(a$native_r_candidate,paste0("etr_",name))
  expect_true(a$native_implementation_started)
  expect_true(a$source_contract_gap_unresolved)
  expect_false(a$one_to_one_native_contract_complete)
  expect_equal(sum(p$is_python_function&p$named_native_candidate),321L)
  expect_equal(sum(p$native_implementation_started),296L)
  expect_equal(sum(p$source_contract_gap_unresolved),143L)
})
