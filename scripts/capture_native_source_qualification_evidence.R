# Read-only evidence capture for independently reviewed Python 1.2 native
# R research contracts. No field is upgraded to fully certified.
# Run from package root:
# source("scripts/capture_native_source_qualification_evidence.R")
stopifnot(file.exists("DESCRIPTION"))
required_scientific_tests<-file.path("tests","testthat",paste0(
  "test-",c("native-generalized-fosr-prediction",
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
    "native-python-portable-writer",
    "native-fpca-component-envelopes",
    "native-source-workflows",
    "native-fpcr-bootstrap-uncertainty",
    "native-recurrence-workflow",
    "native-functional-process-simulation",
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
    "native-source-contract-alignment",
    "native-source-fixture-static-attribution",
    "native-direct-source-report-attribution",
    "native-direct-source-frame-attribution",
    "native-direct-source-plot-attribution",
    "native-direct-source-advanced-attribution",
    "native-direct-numerical-source-attribution",
    "native-direct-source-estimator-attribution",
    "native-direct-source-stochastic-attribution",
    "native-sparse-scientific-graphics",
    "native-fpca-inference-source-graphics",
    "native-fpcr-slope-source-calibration",
    "native-wild-simultaneous-source-calibration",
    "native-wild-monte-carlo-source-contracts",
    "native-scientific-source-frames",
    "native-source-diagnostic-frames",
    "native-generalized-mixed-source-graphics",
    "native-pilot-source-adversarial",
    "native-mixed-model-source-text"),".R"))
missing_scientific_tests<-required_scientific_tests[
  !file.exists(required_scientific_tests)]
if(length(missing_scientific_tests))stop(
  "Missing required PR #48 scientific test files in the active checkout: ",
  paste(missing_scientific_tests,collapse=", "),
  ". Switch to the research/native-generalized-fosr-prediction-20261030 branch.",
  call.=FALSE)
if(!all(vapply(c("zip","jsonlite","digest"),
    requireNamespace,logical(1L),quietly=TRUE)))
  stop("Source portable-writer qualification needs zip, jsonlite and digest; install.packages(c('zip','jsonlite','digest')) before running.",call.=FALSE)
source("scripts/preflight_native_source_syntax.R",local=TRUE)
pkgload::load_all(".",quiet=TRUE)
stopifnot(identical(et_python_version(),"1.2.0"))
stopifnot(nrow(etr_native_parity_catalog())==508L)
stopifnot(!any(etr_native_parity_catalog()$one_to_one_native_contract_complete))
source("scripts/build_inference_contract_dossier.R",local=TRUE)
queue_path<-file.path("artifacts","native_inference_contract_review",
  "python_1_2_scientific_contract_review_queue.csv")
queue<-utils::read.csv(queue_path,stringsAsFactors=FALSE,
  check.names=FALSE)
stopifnot(nrow(queue)==111L,!anyDuplicated(queue$python_name),
  all(!queue$fully_certified),
  all(queue$source_difference_open),
  all(file.exists(queue$oracle_test)))
filter<-paste(c(
  "full-native-r-parity-ledger",
  "native-certification-readiness",
  "native-inference-reporting",
  "native-scientific-source-frames",
  "native-source-contract-gaps",
  "native-source-model-reports",
  "native-source-text-inference",
  "native-source-diagnostic-frames",
  "native-sparse-scientific-graphics",
  "native-generalized-mixed-source-graphics",
  "native-mixed-residual-comparison",
  "native-fpca-inference-source-graphics",
  "native-wild-monte-carlo-source-contracts",
  "native-wild-simultaneous-source-calibration",
  "native-fpcr-slope-source-calibration",
  "native-generalized-fosr-prediction",
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
  "native-python-portable-writer",
  "native-fpca-component-envelopes",
  "native-source-workflows",
  "native-fpcr-bootstrap-uncertainty",
  "native-recurrence-workflow",
  "native-mixed-model-source-text",
  "native-source-environment",
  "native-source-evidence-runner",
  "native-independent-source-review-packet",
  "native-private-helper-names",
  # Every newly mapped source-candidate oracle must be executed in BOTH
  # evidence modes, not merely listed as a required or hashed file.
  "native-functional-process-simulation",
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
  "native-source-contract-alignment",
  "native-source-fixture-static-attribution",
  "native-direct-source-report-attribution",
  "native-direct-source-frame-attribution",
  "native-direct-source-plot-attribution",
  "native-direct-source-advanced-attribution",
  "native-direct-numerical-source-attribution",
  "native-direct-source-estimator-attribution",
  "native-direct-source-stochastic-attribution",
  "native-pilot-source-adversarial"),collapse="|")
git_exe<-Sys.which("git")
head_sha<-if(nzchar(git_exe)){
  git_out<-suppressWarnings(system2(git_exe,c("rev-parse","HEAD"),
    stdout=TRUE,stderr=FALSE))
  if(length(git_out)==1L &&
    grepl("^[0-9a-f]{40}$",git_out))git_out else NA_character_
} else NA_character_
record_id<-format(Sys.time(),"%Y%m%dT%H%M%S")
output_dir<-file.path("artifacts","native_source_contract_evidence",
  paste0("qualification_",record_id))
dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
stopifnot(dir.exists(output_dir))
# Record exactly which test filenames the two aggregate testthat calls select.
# A source fixture listed in the 111-contract queue is not necessarily
# exercised merely because its file exists. Store the regex for audit.
selection_file<-file.path(output_dir,"test_selection_regex.txt")
writeLines(filter,selection_file,useBytes=TRUE)
stopifnot(file.exists(selection_file),length(readLines(
  selection_file,warn=FALSE))==1L)
qualify_once<-function(python=FALSE){
  label<-if(python)"python_1_2_direct_source" else "native_r_offline"
  if(python)Sys.setenv(ET_RUN_PYTHON_TESTS="true") else
    Sys.unsetenv("ET_RUN_PYTHON_TESTS")
  on.exit(Sys.unsetenv("ET_RUN_PYTHON_TESTS"),add=TRUE)
  path<-file.path(output_dir,paste0(label,".txt"))
  failed<-NULL
  tryCatch(
    capture.output(
      testthat::test_local(".",filter=filter,
        reporter="summary",stop_on_failure=TRUE,stop_on_warning=TRUE),
      file=path,type="output"),
    error=function(e){failed<<-conditionMessage(e);invisible(NULL)})
  outcome<-if(is.null(failed)) {
    "QUALIFICATION COMPLETED WITHOUT TEST FAILURES"
  } else {
    paste0("QUALIFICATION ERROR: ",failed)
  }
  cat(outcome,"\n",file=path,append=TRUE,sep="")
  message(label, ": ",outcome," (",path,")")
  if(!is.null(failed)) {
    lines<-readLines(path,warn=FALSE)
    # Print the diagnostic tail on the console as well as preserving
    # the complete per-mode artifact. No files outside artifacts change.
    diagnostic<-tail(lines,100L)
    message("===== ",label," failure details =====")
    for(line in diagnostic)message(line)
    message("===== Full failure log: ",path," =====")
  }
  list(label=label,success=is.null(failed),log_file=path,
    error=if(is.null(failed))"" else failed)
}
# Record both independently: an offline R census failure must not
# suppress direct pinned Python numerical/source witnesses. Overall status
# remains FAIL whenever either mode fails. These logs are not signoffs.
results<-list(
  qualify_once(FALSE),
  qualify_once(TRUE)
)
source_files<-unique(c(
  queue$oracle_test,
  "R/native-source-diagnostic-frames.R",
  "R/native-sparse-scientific-graphics.R",
  "R/native-generalized-mixed-source-graphics.R",
  "R/native-mixed-residual-comparison.R",
  "R/native-fpca-inference-source-graphics.R",
  "R/native-wild-monte-carlo-source-contracts.R",
  "R/native-wild-simultaneous-source-calibration.R",
  "R/native-fpcr-slope-source-calibration.R",
  "R/native-source-workflows.R",
  "R/native-recurrence-workflow.R",
  "R/native-functional-process-simulation.R",
  "R/native-functional-recovery-orchestration.R",
  "R/native-workflow-plot-dispatch.R",
  "R/native-fpca-wild-family-test.R",
  "R/native-bounded-model-workflows.R",
  "R/native-generalized-gee-fit.R",
  "R/native-generalized-gee-workflow.R",
  "R/native-generalized-gee-bootstrap.R",
  "R/native-workflow-bundle-export.R",
  "R/native-wild-bootstrap-projection.R",
  "R/native-wild-bootstrap-truncation-scan.R",
  "R/native-mixed-covariance-sensitivity.R",
  "R/native-mixed-participant-bootstraps.R",
  "R/native-thirdparty-functional-analogues.R",
  "R/native-elastic-srvf-alternative.R",
  "R/native-sparse-joint-score-workflows.R",
  "R/native-sparse-multilevel-prediction-workflows.R",
  "tests/testthat/test-native-all-function-mapping-complete.R",
  "scripts/qualify_native_current_contracts.R",
  "tests/testthat/test-native-source-evidence-runner.R",
  "tests/testthat/test-native-certification-readiness.R",
  "tests/testthat/test-native-certification.R",
  "tests/testthat/test-native-source-contract-gaps.R",
  "tests/testthat/test-native-source-contract-alignment.R",
  "tests/testthat/test-native-source-fixture-static-attribution.R",
  "tests/testthat/test-native-direct-source-report-attribution.R",
  "tests/testthat/test-native-direct-source-frame-attribution.R",
  "tests/testthat/test-native-direct-source-plot-attribution.R",
  "tests/testthat/test-native-direct-source-advanced-attribution.R",
  "tests/testthat/test-native-direct-numerical-source-attribution.R",
  "tests/testthat/test-native-direct-source-estimator-attribution.R",
  "tests/testthat/test-native-direct-source-stochastic-attribution.R",
  "tests/testthat/test-native-fpcr-future-prediction-interval.R",
  "tests/testthat/test-native-generalized-gee-fit.R",
  "tests/testthat/test-native-functional-process-simulation.R",
  "tests/testthat/test-native-multivariate-iaaft-generator.R",
  "tests/testthat/test-native-multivariate-surrogate-nonlinearity.R",
  "tests/testthat/test-native-fpcr-bootstrap-uncertainty.R",
  "tests/testthat/test-native-fpca-wild-family-test.R",
  "scripts/source_fixture_static_attribution.R",
  "R/native-fpca.R",
  "R/native-fpca-extensions.R",
  "R/native-functional-diagnostics.R",
  "tests/testthat/helper-native-generalized-gee-fixture.R",
  "tests/testthat/helper-native-wild-projection-fixture.R",
  "tests/testthat/helper-native-mixed-bootstrap-fixture.R",
  "R/native-fpcr-bootstrap-uncertainty.R",
  "R/native-fpca-component-envelopes.R",
  "R/native-python-portable-writer.R",
  "R/native-generalized-fosr-prediction.R",
  "R/native-generalized-fosr-bootstrap-source.R",
  "R/native-generalized-fosr-contrast-source.R",
  "R/native-recovery-source-evaluators.R",
  "R/native-generalized-fosr-coefficient-bands.R",
  "R/native-mixed-coefficient-bands-source.R",
  "R/native-mixed-known-truth-recovery.R",
  "R/native-fpca-known-truth-recovery.R",
  "R/native-sparse-known-truth-recovery.R",
  "R/native-mixed-bootstrap-width-comparison.R",
  "R/native-sparse-mfpca-known-truth-recovery.R",
  "R/native-fpcr-future-prediction-interval.R",
  "R/native-fpcr-regression-cross-validation.R",
  "R/native-fpcr-nested-cross-validation.R",
  "R/native-multivariate-iaaft-generator.R",
  "R/native-multivariate-surrogate-nonlinearity.R",
  "R/native-python-portable-writer.R",
  "R/native-fpca-component-envelopes.R",
  "R/native-functional-mixed-moments.R",
  "R/native-mixed-model-source-text.R",
  "R/native-source-environment.R",
  "tests/testthat/test-native-source-environment.R",
  "tests/testthat/test-native-generalized-fosr-prediction.R",
  "tests/testthat/test-native-generalized-fosr-bootstrap-source.R",
  "tests/testthat/test-native-generalized-fosr-contrast-source.R",
  "tests/testthat/test-native-recovery-source-evaluators.R",
  "tests/testthat/test-native-generalized-fosr-coefficient-bands.R",
  "tests/testthat/test-native-mixed-coefficient-bands-source.R",
  "tests/testthat/test-native-mixed-known-truth-recovery.R",
  "tests/testthat/test-native-mixed-variance-decomposition-source.R",
  "tests/testthat/test-native-fpca-known-truth-recovery.R",
  "tests/testthat/test-native-sparse-known-truth-recovery.R",
  "tests/testthat/test-native-mixed-bootstrap-width-comparison.R",
  "tests/testthat/test-native-sparse-mfpca-known-truth-recovery.R",
  "tests/testthat/test-native-fpcr-future-prediction-interval.R",
  "tests/testthat/test-native-fpcr-regression-cross-validation.R",
  "tests/testthat/test-native-fpcr-nested-cross-validation.R",
  "tests/testthat/test-native-multivariate-iaaft-generator.R",
  "tests/testthat/test-native-multivariate-surrogate-nonlinearity.R",
  "tests/testthat/test-native-python-portable-writer.R",
  "tests/testthat/test-native-fpca-component-envelopes.R",
  "tests/testthat/test-native-mixed-model-source-text.R",
  "tests/testthat/test-native-fpcr-slope-source-calibration.R",
  "tests/testthat/test-native-wild-simultaneous-source-calibration.R",
  "tests/testthat/test-native-wild-monte-carlo-source-contracts.R",
  "tests/testthat/test-native-fpca-inference-source-graphics.R",
  "tests/testthat/test-native-mixed-residual-comparison.R",
  "tests/testthat/test-native-generalized-mixed-source-graphics.R",
  "scripts/capture_native_source_qualification_evidence.R",
  "scripts/prepare_independent_source_review.R",
  "tests/testthat/test-native-independent-source-review-packet.R",
  "R/native-scientific-source-frames.R",
  "R/native-source-model-reports.R",
  "R/native-source-text-inference.R",
  "R/native-inference-reporting.R",
  "R/native-inference-reporting-extensions.R",
  "R/native-full-parity-ledger.R",
  "R/native-certification-readiness.R",
  "inst/extdata/native_source_contract_gaps_stage22.csv",
  "scripts/build_inference_contract_dossier.R",
  "scripts/qualify_native_inference_reporting.R"))
stopifnot(all(file.exists(source_files)))
hashes<-tools::md5sum(source_files)
utils::write.csv(data.frame(path=names(hashes),
  md5=unname(hashes),stringsAsFactors=FALSE),
  file.path(output_dir,"file_integrity_manifest.csv"),
  row.names=FALSE,na="")
status<-data.frame(
  python_name=queue$python_name,
  native_r_function=queue$native_r_function,
  python_source_commit=queue$source_commit,
  r_git_head=rep(head_sha,nrow(queue)),
  r_version=R.version.string,
  python_package_version="1.2.0",
  source_path=queue$source_file,
  fixture_test=queue$oracle_test,
  native_offline_fixture_pass=results[[1L]]$success,
  pinned_python_fixture_pass=results[[2L]]$success,
  # The above fields describe the aggregate suite, NOT per-contract
  # independent coverage. Keep independent case adjudication explicit.
  per_contract_oracle_reviewed=FALSE,
  per_contract_full_source_domain_verified=FALSE,
  per_contract_oracle_witness_state="not_individually_adjudicated",
  input_domain_independent_approval=FALSE,
  numerical_domain_independent_approval=FALSE,
  scientific_scope_independent_approval=FALSE,
  independent_reviewer_signoff=FALSE,
  fully_certified=FALSE,
  stringsAsFactors=FALSE)
utils::write.csv(status,file.path(output_dir,
  "unsigned_contract_fixture_evidence.csv"),
  row.names=FALSE,na="")
message("Saved pinned-source qualification evidence under ",
  normalizePath(output_dir,winslash="/",mustWork=TRUE))
message("These are test execution records, not independent full-contract certification.")
# Build an UNSIGNED per-contract reviewer hand-off against this exact run.
# The packet checks the captured git commit and all listed MD5 hashes; a
# passing suite cannot sign its own scientific contracts.
source("scripts/prepare_independent_source_review.R",local=TRUE)
# The source review packet must cover the entire immutable 508-export
# inventory; the 107 candidate fixture rows are only a selected subset.
scope_file<-file.path("artifacts","native_independent_review_packets",
  basename(output_dir),"all_508_public_export_independent_review_scope.csv")
stopifnot(file.exists(scope_file))
full_scope<-utils::read.csv(scope_file,stringsAsFactors=FALSE,
  check.names=FALSE)
stopifnot(nrow(full_scope)==508L,
  sum(full_scope$kind=="function")==380L,
  sum(full_scope$kind!="function")==128L,
  sum(full_scope$mapped_native_function)==380L,
  sum(full_scope$selected_oracle_candidate)==nrow(queue),
  all(!full_scope$fully_certified),
  all(!full_scope$per_export_independent_reviewer_approved))
message("All 508 frozen public exports inventoried for independent review;",
  " 380 function analogues, 128 nonfunctions and ",
  nrow(queue)," selected unsigned oracle candidates.")
# Verify actionable reviewer triage was also emitted and remains unsigned.
packet_root<-file.path("artifacts","native_independent_review_packets",
  basename(output_dir))
triage_path<-file.path(packet_root,"all_508_contract_review_priority.csv")
gaps_path<-file.path(packet_root,"known_source_gap_resolution_queue.csv")
lane_path<-file.path(packet_root,"review_lane_counts.csv")
stopifnot(all(file.exists(c(triage_path,gaps_path,lane_path))))
triage<-utils::read.csv(triage_path,stringsAsFactors=FALSE,
  check.names=FALSE)
gap_review<-utils::read.csv(gaps_path,stringsAsFactors=FALSE,
  check.names=FALSE)
source_gap_count<-nrow(utils::read.csv(
  file.path("inst","extdata","native_source_contract_gaps_stage22.csv"),
  stringsAsFactors=FALSE))
fixture_attribution_path<-file.path(packet_root,
  "selected_111_fixture_static_attribution.csv")
stopifnot(file.exists(fixture_attribution_path))
fixture_attribution<-utils::read.csv(fixture_attribution_path,
  stringsAsFactors=FALSE,check.names=FALSE)
stopifnot(nrow(fixture_attribution)==nrow(queue),
  !anyDuplicated(fixture_attribution$python_name),
  setequal(fixture_attribution$python_name,queue$python_name),
  all(fixture_attribution$test_selection_regex_recorded),
  all(fixture_attribution$fixture_filename_selected_in_both_suite_modes),
  all(fixture_attribution$test_that_cases_declared_in_entire_fixture_file>=1L),
  all(!fixture_attribution$per_contract_test_execution_independently_attributed),
  all(!fixture_attribution$per_contract_python_oracle_independently_replayed),
  all(!fixture_attribution$fully_certified))
stopifnot(nrow(triage)==508L,
  sum(triage$selected_oracle_candidate)==nrow(queue),
  nrow(gap_review)==source_gap_count,
  all(!triage$independent_source_contract_approved),
  all(!gap_review$resolved),
  !anyDuplicated(gap_review$python_name))
message("Review triage: ",nrow(triage)," public exports; ",
  nrow(gap_review)," recorded source differences; ",
  sum(triage$backend_or_estimand_distinct),
  " alternative backends/estimands; zero independent approvals.")
message("Static source-fixture attribution: ",
  sum(fixture_attribution$fixture_filename_selected_in_both_suite_modes),
  "/",nrow(fixture_attribution)," mapped to captured test filename filter; ",
  sum(fixture_attribution$literal_etpy_get_export_call_for_this_contract),
  " with a direct literal frozen Python export reference. ",
  "These are file-level indicators, NOT individual executed-case approvals.")

if(!all(vapply(results,function(x)isTRUE(x$success),logical(1L)))) {
  failed_labels<-vapply(results,function(x)
    if(identical(x$success,FALSE))x$label else "",character(1L))
  skipped_labels<-vapply(results,function(x)
    if(is.na(x$success))x$label else "",character(1L))
  stop("Source qualification failure: ",
    paste(failed_labels[nzchar(failed_labels)],collapse=", "),
    if(any(nzchar(skipped_labels)))
      paste0("; NOT ATTEMPTED: ",
        paste(skipped_labels[nzchar(skipped_labels)],collapse=", "))
    else "",
    ". Evidence preserved in ",output_dir,
    ". The preceding console output contains the test failures.",
    call.=FALSE)
}
