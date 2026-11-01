test_that("static Python source-fixture inventory ignores missing R call arguments",{
  helper<-testthat::test_path("..","..","scripts",
    "source_fixture_static_attribution.R")
  expect_true(file.exists(helper))
  expect_silent(parse(file=helper,keep.source=FALSE))
  env<-new.env(parent=baseenv())
  sys.source(helper,envir=env)
  fixture<-tempfile(fileext=".R")
  on.exit(unlink(fixture),add=TRUE)
  writeLines(c(
    "test_that('index holes', {",
    "  x <- matrix(1:9, 3L, 3L)",
    "  first <- x[, 1L]",
    "  last <- x[1L, ]",
    "  out <- etpy_get_export('alr_transform')",
    "  # etpy_get_export('comment_only')",
    "  literal <- 'etpy_get_export(not_a_call)'",
    "})",
    "testthat::test_that('second case', {",
    "  z <- etpy_get_export('score_distance_matrix')",
    "})"
  ),fixture,useBytes=TRUE)
  inventory<-env$etr_source_fixture_static_inventory(fixture)
  expect_identical(inventory$cases,2L)
  expect_setequal(inventory$export_literals,
    c("alr_transform","score_distance_matrix"))
  expect_false("comment_only" %in% inventory$export_literals)
  expect_false("not_a_call" %in% inventory$export_literals)
})

test_that("static inventory stays noncertifying and never executes source fixtures",{
  helper<-testthat::test_path("..","..","scripts",
    "source_fixture_static_attribution.R")
  env<-new.env(parent=baseenv())
  sys.source(helper,envir=env)
  marker<-tempfile()
  fixture<-tempfile(fileext=".R")
  on.exit(unlink(c(marker,fixture)),add=TRUE)
  writeLines(c("test_that('parse only', {",
    paste0("  writeLines('executed', '",gsub("\\\\","/",marker),"')"),
    "  etpy_get_export('inverse_alr')",
    "})"),fixture,useBytes=TRUE)
  inventory<-env$etr_source_fixture_static_inventory(fixture)
  expect_identical(inventory$cases,1L)
  expect_true("inverse_alr" %in% inventory$export_literals)
  expect_false(file.exists(marker))
  expect_error(env$etr_source_fixture_static_inventory(
    paste0(fixture,".missing")),"Missing source fixture")
})

# Full 26/26 remaining source-symbol attribution register; this is NOT
# 26 additional numerical parity oracles. Each direct export is inspected
# in Python 1.2 mode using helper-frozen-python-source-symbol.R.
test_that("all 26 previously unreferenced public Python exports are now attributed",{
  root<-testthat::test_path("..","..")
  env<-new.env(parent=baseenv())
  sys.source(file.path(root,"scripts",
    "source_fixture_static_attribution.R"),envir=env)
  required<-list(
    "test-native-mixed-residual-comparison.R"=c("compare_functional_mixed_effects_residual_diagnostics"),
    "test-native-python-portable-writer.R"=c("export_portable_result"),
    "test-native-fpca-component-envelopes.R"=c("bootstrap_fpca_component_envelopes"),
    "test-native-functional-recovery-orchestration.R"=c("simulate_functional_scenario","run_functional_recovery_scenarios"),
    "test-native-workflow-plot-dispatch.R"=c("plot_workflow_result","save_workflow_figure"),
    "test-native-bounded-model-workflows.R"=c("run_functional_mixed_effects_workflow","run_sparse_fpca_workflow"),
    "test-native-generalized-gee-fit.R"=c("run_generalized_functional_workflow"),
    "test-native-generalized-gee-bootstrap.R"=c("bootstrap_generalized_function_on_scalar_coefficients"),
    "test-native-workflow-bundle-export.R"=c("export_workflow_bundle"),
    "test-native-mixed-covariance-sensitivity.R"=c("functional_mixed_effects_covariance_sensitivity"),
    "test-native-mixed-participant-bootstraps.R"=c("bootstrap_functional_mixed_effects_coefficients","bootstrap_functional_mixed_effects_full_refit"),
    "test-native-thirdparty-functional-analogues.R"=c("to_skfda_grid","to_skfda_basis","detect_functional_outliers_skfda","to_fdapy_irregular","fit_sparse_fpca_fdapy"),
    "test-native-final-sparse-elastic-analogues.R"=c("fit_elastic_fpca","fit_sparse_mfpca","run_sparse_mfpca_async_workflow","run_sparse_mfpca_workflow","run_sparse_multilevel_workflow","run_sparse_prediction_workflow")
  )
  expect_identical(length(required),13L)
  expect_identical(sum(lengths(required)),26L)
  expect_false(anyDuplicated(unlist(required,use.names=FALSE))>0L)
  for(file in names(required)){
    target<-file.path(root,"tests","testthat",file)
    inv<-env$etr_source_fixture_static_inventory(target)
    expect_gte(inv$cases,1L,info=file)
    expect_setequal(intersect(inv$export_literals,required[[file]]),
      required[[file]],info=file)
    lines<-readLines(target,warn=FALSE)
    expect_true(any(grepl(
      ".etr_expect_frozen_python_source_symbol(",lines,fixed=TRUE)),
      info=paste("source inspection unavailable",file))
  }
  api<-etr_native_parity_catalog()
  idx<-match(unlist(required,use.names=FALSE),api$python_name)
  expect_false(anyNA(idx))
  expect_true(all(api$is_python_function[idx]))
  expect_true(all(api$source_contract_gap_unresolved[idx]))
  expect_false(any(api$one_to_one_native_contract_complete[idx]))
})
