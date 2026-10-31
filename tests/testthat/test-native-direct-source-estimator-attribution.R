# Provenance guard: executable fixed-input Python source comparisons are
# not comprehensive contract parity or third-party independent signoff.
test_that("nine estimator and CV Python public exports are explicitly replayed",{
  root<-testthat::test_path("..","..")
  env<-new.env(parent=baseenv())
  sys.source(file.path(root,"scripts",
    "source_fixture_static_attribution.R"),envir=env)
  expected<-list(
    "test-native-generalized-fosr-bootstrap-source.R"=c(
      "bootstrap_generalized_function_on_scalar_predictions",
      "generalized_function_on_scalar_prediction_bands"),
    "test-native-generalized-fosr-prediction.R"=
      "generalized_function_on_scalar_predict",
    "test-native-mixed-bootstrap-width-comparison.R"=
      "compare_functional_mixed_effects_bootstraps",
    "test-native-sparse-known-truth-recovery.R"=
      "evaluate_sparse_fpca_recovery",
    "test-native-sparse-mfpca-known-truth-recovery.R"=
      "evaluate_sparse_mfpca_recovery",
    "test-native-fpca-known-truth-recovery.R"=
      "evaluate_fpca_recovery",
    "test-native-fpcr-regression-cross-validation.R"=
      "cross_validate_fpca_regression",
    "test-native-fpcr-nested-cross-validation.R"=
      "nested_cross_validate_fpca_regression")
  exports<-unlist(expected,use.names=FALSE)
  expect_identical(length(exports),9L)
  expect_false(anyDuplicated(exports)>0L)
  for(file in names(expected)){
    source_file<-file.path(root,"tests","testthat",file)
    record<-env$etr_source_fixture_static_inventory(source_file)
    expect_gte(record$cases,1L)
    expect_setequal(
      intersect(expected[[file]],record$export_literals),
      expected[[file]])
  }
  catalog<-etr_native_parity_catalog()
  i<-match(exports,catalog$python_name)
  expect_false(anyNA(i))
  expect_true(all(catalog$is_python_function[i]))
  expect_true(all(catalog$named_native_candidate[i]))
  expect_true(all(catalog$native_implementation_started[i]))
  expect_true(all(catalog$source_contract_gap_unresolved[i]))
  expect_false(any(catalog$one_to_one_native_contract_complete[i]))
})
