# Guard the complete evidence capture selector before running either long
# qualification mode. The selector, requirements and source manifest are
# separate and must not drift when new scientific suites are registered.
test_that("all source-evidence required tests match the real capture filter",{
  .etr_require_developer_checkout()
  root<-testthat::test_path("..","..")
  capture<-file.path(root,"scripts",
    "capture_native_source_qualification_evidence.R")
  expressions<-parse(file=capture,keep.source=FALSE)
  rhs<-function(symbol) {
    indices<-which(vapply(expressions,function(expr)
      is.call(expr)&&identical(expr[[1L]],as.name("<-"))&&
        identical(expr[[2L]],as.name(symbol)),logical(1L)))
    expect_true(length(indices)==1L,
      info=paste("exactly one top-level assignment required for",symbol))
    expressions[[indices[[1L]]]][[3L]]
  }
  required<-eval(rhs("required_scientific_tests"),envir=baseenv())
  selector<-eval(rhs("filter"),envir=baseenv())
  expect_identical(length(required),length(unique(required)))
  expect_true(all(file.exists(file.path(root,required))))
  unmatched<-required[!grepl(selector,basename(required))]
  expect_true(length(unmatched)==0L,
    info=paste("capture omits required scientific suites:",
      paste(unmatched,collapse=", ")))
  for(suite in c("native-numpy-input-coercion",
                 "native-pairwise-numpy-weights",
                 "native-trapezoid-complex-source",
                 "native-functional-l2-complex-source",
                 "native-alr-numpy-complex-source",
                 "native-windowed-rqa-python-pair-sequence")){
    filename<-paste0("test-",suite,".R")
    expect_true(filename%in%basename(required))
    expect_true(grepl(selector,filename))
    expect_true(file.exists(file.path(root,"tests","testthat",filename)))
    script<-readLines(capture,warn=FALSE)
    expect_true(any(grepl(
      paste0('"tests/testthat/',filename,'"'),script,fixed=TRUE)),
      info=paste("source manifest missing",filename))
    helper<-readLines(file.path(root,"scripts",
      "qualify_native_current_contracts.R"),warn=FALSE)
    expect_true(any(grepl(paste0('"',suite,'"'),helper,fixed=TRUE)),
      info=paste("second qualification entrypoint missing",suite))
  }
})

# A syntax regression in the evidence runner must be caught before
# users invoke a full native/Python qualification cycle.
test_that("native source qualification evidence runner parses", {
  .etr_require_developer_checkout()
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
    "selected_111_missing_literal_python_source_references.csv",
    "source_gap_resolution_lane_counts.csv",
    "four_numerical_pilots_external_review_priority.csv",
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
  for(name in c("tests/testthat/test-native-pilot-source-adversarial.R",
    "tests/testthat/test-native-mixed-model-source-text.R",
    "tests/testthat/test-native-sparse-scientific-graphics.R",
    "tests/testthat/test-native-source-diagnostic-frames.R",
    "tests/testthat/test-native-direct-source-plot-attribution.R",
    "tests/testthat/test-native-direct-source-report-attribution.R",
    "man/native-api.Rd")){
    expect_true(any(grepl(paste0('"',name,'"'),
      lines,fixed=TRUE)),
      info=paste("source evidence manifest omitted",name))
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
    "native-direct-source-estimator-attribution",
    "native-direct-source-stochastic-attribution",
    "native-direct-source-workflow-attribution",
    "native-recurrence-workflow",
    "native-functional-recovery-evidence",
    "native-direct-source-recovery-evidence-attribution",
    "native-fpcr-future-prediction-interval",
    "native-generalized-gee-fit",
    "native-functional-process-simulation",
    "native-multivariate-iaaft-generator",
    "native-multivariate-surrogate-nonlinearity",
    "native-fpcr-bootstrap-uncertainty",
    "native-sparse-scientific-graphics",
    "native-fpca-external-score-reconstruction",
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
  .etr_require_developer_checkout()
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
  # A name in a prerequisite list or hashed manifest is not evidence
  # that testthat actually executed that suite in either capture mode.
  for(name in c("native-fpca-external-score-reconstruction",
    "native-functional-recovery-evidence",
    "native-direct-source-recovery-evidence-attribution")){
    expect_true(any(grepl(paste0('"',name,'"'),
      filter_lines,fixed=TRUE)),
      info=paste("required scientific suite not selected:",name))
  }
  for(guard in c("if(anyDuplicated(required_scientific_tests))stop(",
    "unselected_required<-required_scientific_tests[",
    "!grepl(filter,basename(required_scientific_tests))]")){
    expect_true(any(grepl(guard,runner,fixed=TRUE)),
      info=paste("missing fail-closed capture guard:",guard))
  }
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

test_that("111 selected Python exports require exact-head literal source evidence",{
  .etr_require_developer_checkout()
  runner<-testthat::test_path("..","..","scripts",
    "capture_native_source_qualification_evidence.R")
  lines<-readLines(runner,warn=FALSE)
  required<-c(
    "tests/testthat/helper-frozen-python-source-symbol.R",
    "tests/testthat/test-native-source-fixture-static-attribution.R",
    "tests/testthat/test-native-mixed-residual-comparison.R",
    "tests/testthat/test-native-python-portable-writer.R",
    "tests/testthat/test-native-fpca-component-envelopes.R",
    "tests/testthat/test-native-functional-recovery-orchestration.R",
    "tests/testthat/test-native-workflow-plot-dispatch.R",
    "tests/testthat/test-native-bounded-model-workflows.R",
    "tests/testthat/test-native-generalized-gee-fit.R",
    "tests/testthat/test-native-generalized-gee-bootstrap.R",
    "tests/testthat/test-native-workflow-bundle-export.R",
    "tests/testthat/test-native-mixed-covariance-sensitivity.R",
    "tests/testthat/test-native-mixed-participant-bootstraps.R",
    "tests/testthat/test-native-thirdparty-functional-analogues.R",
    "tests/testthat/test-native-final-sparse-elastic-analogues.R")
  for(name in required){
    expect_true(any(grepl(paste0('"',name,'"'),lines,fixed=TRUE)),
      info=paste("evidence manifest must hash source witness",name))
  }
  expect_true(any(grepl(
    "all(fixture_attribution$literal_etpy_get_export_call_for_this_contract)",
    lines,fixed=TRUE)))
  expect_true(any(grepl("nrow(missing_refs)==0L",lines,fixed=TRUE)))
  expect_true(any(grepl("No certifications changed",lines,fixed=TRUE))||
    any(grepl("certification remain unsigned",lines,fixed=TRUE)))
})
