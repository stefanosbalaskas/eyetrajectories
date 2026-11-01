# This gate records source-call location only, never approved full-domain parity.
test_that("three typed recovery frames have explicit Python source witnesses",{
  root<-testthat::test_path("..","..")
  helper<-new.env(parent=baseenv())
  sys.source(file.path(root,"scripts",
    "source_fixture_static_attribution.R"),envir=helper)
  path<-file.path(root,"tests","testthat",
    "test-native-functional-recovery-evidence.R")
  inv<-helper$etr_source_fixture_static_inventory(path)
  expected<-c("functional_recovery_frame",
    "functional_recovery_failure_frame",
    "functional_recovery_summary_frame")
  expect_gte(inv$cases,1L)
  expect_setequal(intersect(inv$export_literals,expected),expected)
  api<-etr_native_parity_catalog()
  at<-match(expected,api$python_name)
  expect_false(anyNA(at))
  expect_true(all(api$is_python_function[at]))
  expect_true(all(api$named_native_candidate[at]))
  expect_true(all(api$native_implementation_started[at]))
  expect_true(all(api$source_contract_gap_unresolved[at]))
  expect_false(any(api$one_to_one_native_contract_complete[at]))
})
