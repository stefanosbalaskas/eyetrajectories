# Provenance-only guard. The seven native base-R plot functions and
# Python Matplotlib Axes are deliberately distinct backends and never
# automatically marked complete-domain source equivalent.
test_that("seven frozen graphical source exports are directly replayed",{
  root<-testthat::test_path("..","..")
  env<-new.env(parent=baseenv())
  sys.source(file.path(root,"scripts",
    "source_fixture_static_attribution.R"),envir=env)
  file<-file.path(root,"tests","testthat",
    "test-native-generalized-mixed-source-graphics.R")
  found<-env$etr_source_fixture_static_inventory(file)
  expected<-c(
    "plot_generalized_function_on_scalar_predictions",
    "plot_generalized_function_on_scalar_mean_difference",
    "plot_generalized_function_on_scalar_coefficients",
    "plot_covariance_sensitivity_coefficients",
    "plot_covariance_sensitivity_band_widths",
    "plot_functional_mixed_effects_residual_acf",
    "plot_functional_mixed_effects_residual_variogram")
  expect_identical(length(expected),7L)
  expect_true(found$cases>=1L)
  expect_setequal(intersect(expected,found$export_literals),expected)
  api<-etr_native_parity_catalog()
  idx<-match(expected,api$python_name)
  expect_false(anyNA(idx))
  expect_true(all(api$is_python_function[idx]))
  expect_true(all(api$native_implementation_started[idx]))
  expect_true(all(api$source_contract_gap_unresolved[idx]))
  expect_false(any(api$one_to_one_native_contract_complete[idx]))
})

test_that("two frozen sparse plot exports carry typed direct Python oracles",{
  root<-testthat::test_path("..","..")
  env<-new.env(parent=baseenv())
  sys.source(file.path(root,"scripts",
    "source_fixture_static_attribution.R"),envir=env)
  file<-file.path(root,"tests","testthat",
    "test-native-sparse-scientific-graphics.R")
  found<-env$etr_source_fixture_static_inventory(file)
  expected<-c("plot_sparse_fpca_covariance",
    "plot_sparse_mfpca_score_diagnostics")
  expect_true(found$cases>=1L)
  expect_setequal(intersect(expected,found$export_literals),expected)
  api<-etr_native_parity_catalog()
  idx<-match(expected,api$python_name)
  expect_false(anyNA(idx))
  expect_true(all(api$source_contract_gap_unresolved[idx]))
  expect_false(any(api$one_to_one_native_contract_complete[idx]))
})
