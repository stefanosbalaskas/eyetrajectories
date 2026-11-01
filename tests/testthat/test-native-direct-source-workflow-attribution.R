# Replayed source branch boundaries are not full-domain R/Python
# equivalence certificates and never grant independent approval.
test_that("two root wild exports and two subpackage workflows retain separate attribution",{
  root<-testthat::test_path("..","..")
  env<-new.env(parent=baseenv())
  sys.source(file.path(root,"scripts",
    "source_fixture_static_attribution.R"),envir=env)
  expected<-list(
    "test-native-wild-bootstrap-projection.R"=
      "wild_bootstrap_fpca_projection",
    "test-native-wild-bootstrap-truncation-scan.R"=c(
      "scan_wild_bootstrap_fpca_truncations",
      "fpca_wild_bootstrap_truncation_scan_frame",
      "select_fpca_wild_bootstrap_truncation",
      "fpca_wild_bootstrap_truncation_selection_frame"))
  exports<-unlist(expected,use.names=FALSE)
  expect_identical(length(exports),5L)
  expect_false(anyDuplicated(exports)>0L)
  for(file in names(expected)){
    file_path<-file.path(root,"tests","testthat",file)
    inv<-env$etr_source_fixture_static_inventory(file_path)
    expect_gte(inv$cases,1L)
    expect_setequal(intersect(expected[[file]],inv$export_literals),
      expected[[file]])
  }
  # Workflow functions are public under eyetrajectoriespy.workflows,
  # which supplies 18 of the 380 callable exports in the frozen
  # combined root/workflows inventory. The workflow namespace matters.
  modules<-c("test-native-recurrence-workflow.R",
    "test-native-workflow-plot-dispatch.R")
  module_names<-c("run_recurrence_workflow","plot_workflow_result")
  for(k in seq_along(modules)){
    source<-readLines(file.path(root,"tests","testthat",
      modules[[k]]),warn=FALSE)
    expect_true(any(grepl("eyetrajectoriespy.workflows",
      source,fixed=TRUE)))
    expect_true(any(grepl(paste0('"',module_names[[k]],'"'),
      source,fixed=TRUE)))
    if(k==1L){
      expect_true(any(grepl(
        'etpy_get_export("run_recurrence_workflow",.namespace="workflows")',
        source,fixed=TRUE)))
    } else {
      # Other workflows may still use direct imported subpackage calls.
      expect_false(any(grepl(paste0('etpy_get_export("',
        module_names[[k]],'")'),source,fixed=TRUE)))
    }
  }
  w3<-env$etr_source_fixture_static_inventory(file.path(
    root,"tests","testthat","test-native-source-workflows.R"))
  expect_true("run_fpca_workflow"%in%w3$export_literals)
  expect_true("run_recurrence_workflow"%in%
    env$etr_source_fixture_static_inventory(file.path(
      root,"tests","testthat",
      "test-native-recurrence-workflow.R"))$export_literals)
  api<-etr_native_parity_catalog()
  i<-match(exports,api$python_name)
  expect_false(anyNA(i))
  expect_true(all(api$is_python_function[i]))
  expect_true(all(api$named_native_candidate[i]))
  expect_true(all(api$native_implementation_started[i]))
  expect_true(all(api$source_contract_gap_unresolved[i]))
  expect_false(any(api$one_to_one_native_contract_complete[i]))
})
