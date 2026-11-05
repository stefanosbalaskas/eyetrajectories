# A source-name fixture reference is not a per-case independent full
# Python-to-R equivalence certificate; open gaps remain independently audited.
test_that("eight numerical and recovery source exports are directly replayed",{
  .etr_require_developer_checkout()
  root<-testthat::test_path("..","..")
  env<-new.env(parent=baseenv())
  sys.source(file.path(root,"scripts",
    "source_fixture_static_attribution.R"),envir=env)
  expected<-list(
    "test-native-fpca-wild-family-test.R"=
      "fpca_wild_bootstrap_projection_family_test",
    "test-native-generalized-fosr-coefficient-bands.R"=
      "generalized_function_on_scalar_simultaneous_bands",
    "test-native-mixed-coefficient-bands-source.R"=
      "functional_mixed_effects_simultaneous_bands",
    "test-native-mixed-variance-decomposition-source.R"=
      "functional_mixed_effects_variance_decomposition",
    "test-native-recovery-source-evaluators.R"=c(
      "evaluate_hierarchy_truth_recovery",
      "evaluate_registration_recovery"),
    "test-native-mixed-known-truth-recovery.R"=
      "evaluate_functional_mixed_effects_recovery",
    "test-native-generalized-fosr-contrast-source.R"=
      "generalized_function_on_scalar_mean_difference_band")
  exports<-unlist(expected,use.names=FALSE)
  expect_identical(length(exports),8L)
  expect_false(anyDuplicated(exports)>0L)
  for(file in names(expected)){
    path<-file.path(root,"tests","testthat",file)
    inventory<-env$etr_source_fixture_static_inventory(path)
    expect_gte(inventory$cases,1L)
    expect_setequal(intersect(expected[[file]],
      inventory$export_literals),expected[[file]])
  }
  catalog<-etr_native_parity_catalog()
  idx<-match(exports,catalog$python_name)
  expect_false(anyNA(idx))
  expect_true(all(catalog$is_python_function[idx]))
  expect_true(all(catalog$named_native_candidate[idx]))
  expect_true(all(catalog$native_implementation_started[idx]))
  expect_true(all(catalog$source_contract_gap_unresolved[idx]))
  expect_false(any(catalog$one_to_one_native_contract_complete[idx]))
})
