# Replayed source branch boundaries are not full-domain R/Python
# equivalence certificates and never grant independent approval.
test_that("four public wild and workflow exports have explicit direct source calls",{
  root<-testthat::test_path("..","..")
  env<-new.env(parent=baseenv())
  sys.source(file.path(root,"scripts",
    "source_fixture_static_attribution.R"),envir=env)
  expected<-list(
    "test-native-wild-bootstrap-projection.R"=
      "wild_bootstrap_fpca_projection",
    "test-native-wild-bootstrap-truncation-scan.R"=
      "scan_wild_bootstrap_fpca_truncations",
    "test-native-recurrence-workflow.R"=
      "run_recurrence_workflow",
    "test-native-workflow-plot-dispatch.R"=
      "plot_workflow_result")
  exports<-unlist(expected,use.names=FALSE)
  expect_identical(length(exports),4L)
  expect_false(anyDuplicated(exports)>0L)
  for(file in names(expected)){
    file_path<-file.path(root,"tests","testthat",file)
    inv<-env$etr_source_fixture_static_inventory(file_path)
    expect_gte(inv$cases,1L)
    expect_setequal(intersect(expected[[file]],inv$export_literals),
      expected[[file]])
  }
  api<-etr_native_parity_catalog()
  i<-match(exports,api$python_name)
  expect_false(anyNA(i))
  expect_true(all(api$is_python_function[i]))
  expect_true(all(api$named_native_candidate[i]))
  expect_true(all(api$native_implementation_started[i]))
  expect_true(all(api$source_contract_gap_unresolved[i]))
  expect_false(any(api$one_to_one_native_contract_complete[i]))
})
