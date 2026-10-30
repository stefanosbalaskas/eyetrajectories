# A syntax regression in the evidence runner must be caught before
# users invoke a full native/Python qualification cycle.
test_that("native source qualification evidence runner parses", {
  runner <- testthat::test_path(
    "..", "..", "scripts",
    "capture_native_source_qualification_evidence.R"
  )
  expect_true(file.exists(runner))
  expect_silent(parse(file = runner, keep.source = FALSE))
  syntax_preflight<-testthat::test_path("..","..","scripts",
    "preflight_native_source_syntax.R")
  expect_true(file.exists(syntax_preflight))
  expect_silent(parse(file=syntax_preflight,keep.source=FALSE))
  for(name in c("qualify_native_current_contracts.R",
    "capture_native_source_qualification_evidence.R")){
    script<-readLines(testthat::test_path("..","..","scripts",name),
      warn=FALSE)
    expect_true(any(grepl(
      'source("scripts/preflight_native_source_syntax.R",local=TRUE)',
      script,fixed=TRUE)))
  }
  lines <- readLines(runner, warn = FALSE)
  expect_false(any(trimws(lines) == "else"))
  expect_true(any(grepl("qualify_once(FALSE)",lines,fixed=TRUE)))
  expect_true(any(grepl("qualify_once(TRUE)",lines,fixed=TRUE)))
  current<-readLines(testthat::test_path("..","..","scripts",
    "qualify_native_current_contracts.R"),warn=FALSE)
  expect_true(any(grepl(".etr_qualify_current_once(FALSE)",
    current,fixed=TRUE)))
  expect_true(any(grepl(".etr_qualify_current_once(TRUE)",
    current,fixed=TRUE)))
  expect_true(any(grepl("no source contracts certified",
    current,fixed=TRUE)))
  expect_false(any(grepl(
    "NOT ATTEMPTED: offline qualification failed",lines,fixed=TRUE)))
})

test_that("new scientific source oracles are included in both qualification modes",{
  root<-testthat::test_path("..","..")
  runner<-readLines(file.path(root,"scripts",
    "capture_native_source_qualification_evidence.R"),warn=FALSE)
  dossier<-readLines(file.path(root,"scripts",
    "build_inference_contract_dossier.R"),warn=FALSE)
  for(name in c("native-generalized-fosr-prediction",
    "native-generalized-fosr-bootstrap-source",
    "native-generalized-fosr-contrast-source",
    "native-recovery-source-evaluators",
    "native-generalized-fosr-coefficient-bands",
    "native-mixed-coefficient-bands-source",
    "native-mixed-known-truth-recovery",
    "native-mixed-variance-decomposition-source",
    "native-fpca-known-truth-recovery",
    "native-sparse-known-truth-recovery",
    "native-mixed-bootstrap-width-comparison",
    "native-sparse-mfpca-known-truth-recovery",
    "native-fpcr-future-prediction-interval",
    "native-mixed-model-source-text","native-source-environment")){
    expect_true(any(grepl(name,runner,fixed=TRUE)))
  }
  for(name in c("generalized_function_on_scalar_predict",
    "functional_mixed_effects_reporting_text",
    "bootstrap_generalized_function_on_scalar_predictions",
    "generalized_function_on_scalar_prediction_bands",
    "generalized_function_on_scalar_mean_difference_band",
    "evaluate_hierarchy_truth_recovery",
    "evaluate_registration_recovery",
    "generalized_function_on_scalar_simultaneous_bands",
    "functional_mixed_effects_simultaneous_bands",
    "evaluate_functional_mixed_effects_recovery",
    "functional_mixed_effects_variance_decomposition",
    "evaluate_fpca_recovery",
    "evaluate_sparse_fpca_recovery",
    "compare_functional_mixed_effects_bootstraps",
    "evaluate_sparse_mfpca_recovery",
    "fpca_regression_future_prediction_interval")){
    expect_true(any(grepl(name,dossier,fixed=TRUE)))
  }
  expect_true(any(grepl("nrow(queue)==69L",runner,fixed=TRUE)))
})
