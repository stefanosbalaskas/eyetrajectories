# Static evidence guard only: a literal etpy_get_export call is NOT a
# passed per-case Python oracle, full-domain parity or independent approval.
test_that("twenty additional source reporting exports have direct pinned oracle calls",{
  .etr_require_developer_checkout()
  root<-testthat::test_path("..","..")
  helper<-file.path(root,"scripts","source_fixture_static_attribution.R")
  expect_true(file.exists(helper))
  env<-new.env(parent=baseenv())
  sys.source(helper,envir=env)
  expected<-list(
    "test-native-inference-reporting.R"=c(
      "fpca_wild_bootstrap_projection_reporting_text",
      "fpca_regression_future_prediction_reporting_text",
      "fpca_regression_uncertainty_reporting_text",
      "fpca_regression_slope_band_reporting_text",
      "fpca_nested_regression_cv_reporting_text",
      "fpca_wild_bootstrap_family_test_reporting_text",
      "fpca_wild_bootstrap_monte_carlo_reporting_text",
      "fpca_wild_bootstrap_simultaneous_reporting_text"),
    "test-native-inference-reporting-extensions.R"=c(
      "fpca_regression_cv_reporting_text",
      "fpca_component_envelope_reporting_text",
      "fpca_wild_bootstrap_truncation_reporting_text"),
    "test-native-source-text-inference.R"=c(
      "generalized_function_on_scalar_prediction_reporting_text",
      "generalized_function_on_scalar_mean_difference_reporting_text",
      "functional_mixed_effects_covariance_sensitivity_reporting_text",
      "multivariate_iaaft_reporting_text",
      "multivariate_surrogate_nonlinearity_reporting_text"),
    "test-native-source-model-reports.R"=c(
      "generalized_function_on_scalar_reporting_text",
      "functional_mixed_effects_residual_reporting_text",
      "sparse_mfpca_reporting_text",
      "sparse_fpca_reporting_text"))
  expect_identical(sum(lengths(expected)),20L)
  expect_false(anyDuplicated(unlist(expected,use.names=FALSE))>0L)
  for(file in names(expected)){
    path<-file.path(root,"tests","testthat",file)
    inventory<-env$etr_source_fixture_static_inventory(path)
    expect_true(inventory$cases>=1L)
    expect_setequal(intersect(expected[[file]],inventory$export_literals),
      expected[[file]])
  }
  catalog<-etr_native_parity_catalog()
  idx<-match(unlist(expected,use.names=FALSE),catalog$python_name)
  expect_false(anyNA(idx))
  expect_true(all(catalog$is_python_function[idx]))
  # Static source attribution is not an independent certification gate.
  # Complete six-domain source gaps may close with SHA256 reviews without
  # changing one_to_one_native_contract_complete or independent approval.
  ledger<-utils::read.csv(system.file("extdata",
    "native_source_contract_gaps_stage22.csv",package="eyetrajectories"),
    stringsAsFactors=FALSE)
  witnesses<-ledger[match(catalog$python_name[idx],ledger$python_name),,drop=FALSE]
  expect_false(anyNA(witnesses$python_name))
  expect_identical(as.logical(catalog$source_contract_gap_unresolved[idx]),
    as.logical(witnesses$unresolved_source_gap))
  expect_false(any(catalog$one_to_one_native_contract_complete[idx]))
})

test_that("mixed-effects report has an exact direct frozen Python export oracle",{
  .etr_require_developer_checkout()
  root<-testthat::test_path("..","..")
  env<-new.env(parent=baseenv())
  sys.source(file.path(root,"scripts",
    "source_fixture_static_attribution.R"),envir=env)
  found<-env$etr_source_fixture_static_inventory(file.path(
    root,"tests","testthat","test-native-mixed-model-source-text.R"))
  expect_true(found$cases>=1L)
  expect_true("functional_mixed_effects_reporting_text"%in%
    found$export_literals)
  api<-etr_native_parity_catalog()
  idx<-match("functional_mixed_effects_reporting_text",api$python_name)
  expect_false(is.na(idx))
  expect_false(api$source_contract_gap_unresolved[idx])
  expect_false(api$one_to_one_native_contract_complete[idx])
})
