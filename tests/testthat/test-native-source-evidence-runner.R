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
  for(required_triage in c(
    "all_508_contract_review_priority.csv",
    "known_source_gap_resolution_queue.csv",
    "review_lane_counts.csv",
    "test_selection_regex.txt",
    "selected_111_fixture_static_attribution.csv",
    "scripts/source_fixture_static_attribution.R",
    "tests/testthat/test-native-source-fixture-static-attribution.R",
    "native-source-fixture-static-attribution",
    "native-direct-source-report-attribution",
    "tests/testthat/test-native-direct-source-report-attribution.R",
    "fixture_filename_selected_in_both_suite_modes",
    "source_gap_count",
    "native-source-contract-alignment")){
    expect_true(any(grepl(required_triage,
      readLines(runner,warn=FALSE),fixed=TRUE)),
      info=paste("source evidence runner omits",required_triage))
  }
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
  # Both the quick qualification and full evidence capture must execute
  # the direct-source reporter fixtures, not just test static file names.
  for(name in c("native-inference-reporting",
    "native-source-text-inference","native-source-model-reports",
    "native-direct-source-report-attribution",
    "native-scientific-source-frames","native-source-diagnostic-frames",
    "native-generalized-mixed-source-graphics",
    "native-direct-source-frame-attribution",
    "native-direct-source-plot-attribution",
    "native-direct-source-advanced-attribution",
    "native-direct-numerical-source-attribution",
    "native-sparse-scientific-graphics",
    "native-fpca-inference-source-graphics",
    "native-fpcr-slope-source-calibration",
    "native-wild-simultaneous-source-calibration",
    "native-wild-monte-carlo-source-contracts")){
    expect_true(any(grepl(paste0('"',name,'"'),
      current,fixed=TRUE)),
      info=paste("qualification omitted executed source witnesses",name))
    expect_true(any(grepl(paste0('"',name,'"'),
      lines,fixed=TRUE)),
      info=paste("evidence capture omitted source witnesses",name))
  }
  # The owner's direct source qualification must not omit mapping,
  # 508-export readiness or stage-free namespace gates. Requiring a
  # newly unmapped function was previously a hidden false-fail after 380/380.
  for(name in c("native-all-function-mapping-complete",
    "native-certification-readiness",
    "full-native-r-parity-ledger",
    "native-private-helper-names")){
    expect_true(any(grepl(paste0('"',name,'"'),
      current,fixed=TRUE)),
      info=paste("qualify_native_current_contracts omits",name))
  }
  packet<-testthat::test_path("..","..","scripts",
    "prepare_independent_source_review.R")
  expect_true(file.exists(packet))
  expect_silent(parse(file=packet,keep.source=FALSE))
  expect_true(any(grepl("native-independent-source-review-packet",
    lines,fixed=TRUE)))
  expect_true(any(grepl("scripts/prepare_independent_source_review.R",
    lines,fixed=TRUE)))
  expect_true(any(grepl(
    'source("scripts/prepare_independent_source_review.R",local=TRUE)',
    lines,fixed=TRUE)))
  # Selected 107 source-oracle rows must not hide missing non-function
  # contracts from the immutable 508-export independent-review scope.
  for(term in c("all_508_public_export_independent_review_scope.csv",
    "nrow(full_scope)==508L",
    'sum(full_scope$kind=="function")==380L',
    'sum(full_scope$kind!="function")==128L',
    "sum(full_scope$selected_oracle_candidate)==nrow(queue)",
    "all(!full_scope$fully_certified)")){
    expect_true(any(grepl(term,lines,fixed=TRUE)),
      info=paste("evidence runner scope check missing",term))
  }

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
    "native-fpcr-regression-cross-validation",
    "native-fpcr-nested-cross-validation",
    "native-multivariate-iaaft-generator",
    "native-multivariate-surrogate-nonlinearity",
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
    "fpca_regression_future_prediction_interval",
    "cross_validate_fpca_regression",
    "nested_cross_validate_fpca_regression",
    "generate_multivariate_iaaft_surrogates",
    "multivariate_surrogate_nonlinearity_test")){
    expect_true(any(grepl(name,dossier,fixed=TRUE)))
  }
  expect_true(any(grepl("nrow(queue)==111L",runner,fixed=TRUE)))
  begin<-grep('^filter<-paste\\(c\\(',runner)
  finish<-which(grepl('collapse="|"',runner,fixed=TRUE))
  expect_identical(length(begin),1L)
  expect_true(any(finish>begin))
  filter_lines<-runner[begin:min(finish[finish>begin])]
  for(name in c("native-functional-process-simulation",
    "native-functional-recovery-orchestration",
    "native-workflow-plot-dispatch",
    "native-fpca-wild-family-test",
    "native-bounded-model-workflows",
    "native-generalized-gee-fit",
    "native-generalized-gee-bootstrap",
    "native-workflow-bundle-export",
    "native-wild-bootstrap-projection",
    "native-wild-bootstrap-truncation-scan",
    "native-mixed-covariance-sensitivity",
    "native-mixed-participant-bootstraps",
    "native-thirdparty-functional-analogues",
    "native-final-sparse-elastic-analogues",
    "native-all-function-mapping-complete",
    "native-certification",
    "native-source-contract-gaps",
    "native-pilot-source-adversarial")){
    expect_true(any(grepl(paste0('"',name,'"'),
      filter_lines,fixed=TRUE)),
      info=paste("source evidence capture does not execute",name))
  }
  expect_true(any(grepl(
    '"tests/testthat/helper-native-generalized-gee-fixture.R"',
    runner,fixed=TRUE)))
  expect_true(any(grepl(
    '"tests/testthat/helper-native-wild-projection-fixture.R"',
    runner,fixed=TRUE)))
  expect_true(any(grepl(
    '"tests/testthat/helper-native-mixed-bootstrap-fixture.R"',
    runner,fixed=TRUE)))
  # Scientific source audit must hash the production implementations
  # associated with all four pilot functions and retain their pinned
  # Python oracle records within the growing selected candidate queue.
  expect_true(any(grepl(
    '"R/native-functional-diagnostics.R"',runner,fixed=TRUE)))
  expect_true(any(grepl(
    '"R/native-fpca.R"',runner,fixed=TRUE)))
  expect_true(any(grepl(
    '"tests/testthat/test-native-certification.R"',
    runner,fixed=TRUE)))
  expect_true(any(grepl(
    '"tests/testthat/test-native-source-contract-gaps.R"',
    runner,fixed=TRUE)))
  for(name in c("alr_transform","inverse_alr",
    "score_distance_matrix","functional_trapezoid_weights")){
    expect_true(any(grepl(paste0('"',name,'"'),
      dossier,fixed=TRUE)),info=paste("pilot missing from selected queue",name))
  }

})
