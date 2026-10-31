# Explicit source oracle names improve audit attribution but never sign an
# export or prove identical Matplotlib versus base-R graphics return values.
test_that("thirteen advanced sparse and bootstrap source exports are explicit",{
  root<-testthat::test_path("..","..")
  env<-new.env(parent=baseenv())
  sys.source(file.path(root,"scripts",
    "source_fixture_static_attribution.R"),envir=env)
  expected<-list(
    "test-native-sparse-scientific-graphics.R"=c(
      "plot_sparse_fpca_component",
      "plot_sparse_mfpca_component",
      "plot_sparse_mfpca_covariance_blocks",
      "plot_sparse_mfpca_cross_covariance",
      "plot_sparse_irregular_dimension"),
    "test-native-fpca-inference-source-graphics.R"=c(
      "plot_fpca_component_envelope",
      "plot_sparse_fpca_score_diagnostics",
      "plot_fpca_wild_bootstrap_family_test"),
    "test-native-fpcr-slope-source-calibration.R"=
      "fpca_regression_slope_simultaneous_band",
    "test-native-wild-simultaneous-source-calibration.R"=
      "fpca_wild_bootstrap_projection_simultaneous_interval",
    "test-native-wild-monte-carlo-source-contracts.R"=c(
      "fpca_wild_bootstrap_family_test_monte_carlo_diagnostics",
      "plot_fpca_wild_bootstrap_monte_carlo_diagnostics",
      "plot_fpca_wild_bootstrap_simultaneous_interval"))
  exports<-unlist(expected,use.names=FALSE)
  expect_identical(length(exports),13L)
  expect_false(anyDuplicated(exports)>0L)
  for(file in names(expected)){
    path<-file.path(root,"tests","testthat",file)
    inv<-env$etr_source_fixture_static_inventory(path)
    expect_gte(inv$cases,1L)
    expect_setequal(intersect(inv$export_literals,expected[[file]]),
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
