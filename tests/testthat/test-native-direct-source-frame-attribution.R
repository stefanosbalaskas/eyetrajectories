# Bounded source provenance evidence: name-to-fixture links are NOT
# independent execution, complete-domain parity or scientific certification.
test_that("eight typed source-frame exports have explicit pinned Python oracles",{
  root<-testthat::test_path("..","..")
  helper<-file.path(root,"scripts","source_fixture_static_attribution.R")
  expect_true(file.exists(helper))
  env<-new.env(parent=baseenv())
  sys.source(helper,envir=env)
  expected<-list(
    "test-native-scientific-source-frames.R"=c(
      "generalized_function_on_scalar_coefficient_frame",
      "generalized_function_on_scalar_prediction_frame",
      "generalized_function_on_scalar_mean_difference_frame",
      "generalized_function_on_scalar_exposure_frame",
      "sparse_fpca_score_frame",
      "sparse_mfpca_score_frame"),
    "test-native-source-diagnostic-frames.R"=c(
      "multivariate_iaaft_diagnostics_frame",
      "functional_mixed_effects_variance_bootstrap_frame"))
  exports<-unlist(expected,use.names=FALSE)
  expect_identical(length(exports),8L)
  expect_false(anyDuplicated(exports)>0L)
  for(file in names(expected)){
    inventory<-env$etr_source_fixture_static_inventory(
      file.path(root,"tests","testthat",file))
    expect_gte(inventory$cases,1L)
    expect_setequal(intersect(expected[[file]],
      inventory$export_literals),expected[[file]])
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
