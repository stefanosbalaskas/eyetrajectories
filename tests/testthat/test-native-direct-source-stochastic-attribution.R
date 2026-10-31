# These are executable fixed-source comparisons, not independence or
# whole-domain numerical/scientific certification. R and NumPy RNGs differ.
test_that("six stochastic source functions have direct frozen Python witnesses",{
  root<-testthat::test_path("..","..")
  env<-new.env(parent=baseenv())
  sys.source(file.path(root,"scripts",
    "source_fixture_static_attribution.R"),envir=env)
  expected<-list(
    "test-native-fpcr-future-prediction-interval.R"=
      "fpca_regression_future_prediction_interval",
    "test-native-generalized-gee-fit.R"=
      "fit_generalized_function_on_scalar_regression",
    "test-native-functional-process-simulation.R"=
      "simulate_functional_process",
    "test-native-multivariate-iaaft-generator.R"=
      "generate_multivariate_iaaft_surrogates",
    "test-native-multivariate-surrogate-nonlinearity.R"=
      "multivariate_surrogate_nonlinearity_test",
    "test-native-fpcr-bootstrap-uncertainty.R"=
      "bootstrap_fpca_regression_uncertainty")
  exports<-unlist(expected,use.names=FALSE)
  expect_identical(length(exports),6L)
  expect_false(anyDuplicated(exports)>0L)
  for(file in names(expected)){
    p<-file.path(root,"tests","testthat",file)
    x<-env$etr_source_fixture_static_inventory(p)
    expect_gte(x$cases,1L)
    expect_setequal(intersect(expected[[file]],x$export_literals),
      expected[[file]])
  }
  api<-etr_native_parity_catalog()
  idx<-match(exports,api$python_name)
  expect_false(anyNA(idx))
  expect_true(all(api$is_python_function[idx]))
  expect_true(all(api$named_native_candidate[idx]))
  expect_true(all(api$native_implementation_started[idx]))
  expect_true(all(api$source_contract_gap_unresolved[idx]))
  expect_false(any(api$one_to_one_native_contract_complete[idx]))
})
