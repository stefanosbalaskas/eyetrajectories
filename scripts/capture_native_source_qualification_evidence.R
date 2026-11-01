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
    "native-functional-recovery-evidence",
    "native-direct-source-recovery-evidence-attribution",
    "native-generalized-fosr-coefficient-bands",
    "native-mixed-coefficient-bands-source",
    "native-mixed-known-truth-recovery",
    "native-mixed-variance-decomposition-source",
    "native-fpca-known-truth-recovery",
    "native-fpca-external-score-reconstruction",
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
    "native-recurrence-minkowski-source",
    "native-source-time-units",
    "native-source-windowed-rqa-time-units",
    "native-nonlinear-recurrence",
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
    "native-direct-source-workflow-attribution",
    "native-sparse-scientific-graphics",
    "native-fpca-inference-source-graphics",
    "native-fpcr-slope-source-calibration",
    "native-wild-simultaneous-source-calibration",
    "native-wild-monte-carlo-source-contracts",
    "native-scientific-source-frames",
    "native-source-diagnostic-frames",
    "native-generalized-mixed-source-graphics",
    "native-pilot-source-adversarial",
    "native-four-pilot-review-matrix",
    "native-four-pilot-external-attestation",
    "native-508-certification-batches",
    "native-first-wave-source-interfaces",
    "native-frozen-workflow-values",
    "native-frozen-workflow-schema",
    "native-frozen-workflow-execution",
    "native-source-trajectory-object",
    "native-nonfunction-source-gaps",
    "native-mixed-model-source-text"),".R"))
if(anyDuplicated(required_scientific_tests))stop(
  "Duplicate scientific test files in evidence capture requirements.",
  call.=FALSE)
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
  "native-functional-recovery-evidence",
  "native-direct-source-recovery-evidence-attribution",
  "native-fpca-external-score-reconstruction",
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
  "native-recurrence-minkowski-source",
  "native-source-time-units",
  "native-source-windowed-rqa-time-units",
  "native-nonlinear-recurrence",
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
  "native-direct-source-workflow-attribution",
  "native-pilot-source-adversarial",
  "native-four-pilot-review-matrix",
  "native-four-pilot-external-attestation",
  "native-508-certification-batches",
  "native-first-wave-source-interfaces",
  "native-frozen-workflow-values",
  "native-frozen-workflow-schema",
  "native-frozen-workflow-execution",
  "native-source-trajectory-object",
  "native-nonfunction-source-gaps"),collapse="|")
# Existence and inclusion are separate: all required scientific tests must
# be selected by the exact filter executed in BOTH offline and Python modes.
unselected_required<-required_scientific_tests[
  !grepl(filter,basename(required_scientific_tests))]
if(length(unselected_required))stop(
  "Evidence capture filter omits required scientific tests: ",
  paste(unselected_required,collapse=", "),call.=FALSE)
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
# These are author-side packet integrity tests, not independent scientific
# replay. Run each Python suite independently so the exact failure and
# traceback appear in RStudio, not just a hidden status file.
py_executable<-reticulate::py_config()$python
stopifnot(length(py_executable)==1L,nzchar(py_executable))
tooling_log_path<-file.path(output_dir,
  "python_unsigned_review_packet_tooling_tests.txt")
tooling_patterns<-c("test_verify_four_pilot_review_bundle.py",
  "test_verify_508_certification_batch.py",
  "test_verify_508_external_attestation.py")
tooling_checks<-lapply(tooling_patterns,function(pattern){
  message("Author-side reviewer tooling: ",pattern)
  output<-tryCatch(
    suppressWarnings(system2(py_executable,args=c("-m","unittest",
      "discover","-s","tests","-p",pattern,"-v"),
      stdout=TRUE,stderr=TRUE)),
    error=function(e)structure(paste0("PYTHON INVOCATION ERROR: ",
      conditionMessage(e)),status=1L))
  code<-attr(output,"status")
  if(is.null(code))code<-0L
  list(pattern=pattern,status=as.integer(code),
    output=as.character(output))
})
tooling_lines<-unlist(lapply(tooling_checks,function(check)
  c(paste0("===== ",check$pattern," ====="),
    check$output,
    paste0("AUTHOR_PACKET_TOOLING_EXIT_CODE: ",check$status))),
  use.names=FALSE)
writeLines(tooling_lines,tooling_log_path,useBytes=TRUE)
failed_tooling<-vapply(tooling_checks,function(check)
  !identical(check$status,0L),logical(1L))
if(any(failed_tooling)){
  message("===== Python reviewer tooling failure details =====")
  for(check in tooling_checks[failed_tooling]){
    message("FAILED: ",check$pattern," [exit ",check$status,"]")
    for(line in tail(check$output,100L))message(line)
  }
  message("===== Full Python reviewer tooling log: ",
    tooling_log_path," =====")
  stop("Unsigned reviewer packet tooling tests failed: ",
    paste(tooling_patterns[failed_tooling],collapse=", "),
    "; see traceback printed above.",call.=FALSE)
}
message("Author-side Python reviewer integrity suites PASS: ",
  tooling_log_path," (this is NOT independent scientific certification).")

results<-list(
  qualify_once(FALSE),
  qualify_once(TRUE)
)
source_files<-unique(c(
  "scripts/four_pilot_external_attestation.R",
  "tests/testthat/test-native-four-pilot-external-attestation.R",
  "scripts/capture_four_pilot_boundary_evidence.R",
  "scripts/capture_four_pilot_numeric_evidence.R",
  "scripts/build_four_pilot_review_matrix.R",
  "scripts/build_508_certification_review_batches.R",
  "scripts/capture_first_wave_source_interfaces.R",
  "tests/testthat/test-native-first-wave-source-interfaces.R",
  "tests/testthat/test-native-frozen-workflow-values.R",
  "tests/testthat/test-native-frozen-workflow-schema.R",
  "tests/testthat/test-native-frozen-workflow-execution.R",
  "R/native-frozen-workflow-execution.R",
  "R/native-frozen-workflow-values.R",
  "R/native-frozen-workflow-schema.R",
  "inst/extdata/native_workflow_28_class_field_schema_v1.csv",
  "NAMESPACE",
  "scripts/verify_508_certification_batch.py",
  "tests/test_verify_508_certification_batch.py",
  "scripts/verify_508_external_attestation.py",
  "tests/test_verify_508_external_attestation.py",
  "scripts/verify_four_pilot_review_bundle.py",
  "tests/test_verify_four_pilot_review_bundle.py",
  "tests/testthat/test-native-508-certification-batches.R",
  "tests/testthat/test-native-source-trajectory-object.R",
  "tests/testthat/test-native-nonfunction-source-gaps.R",
  "R/native-trajectory-provenance.R",
  "inst/extdata/native_nonfunction_contract_review_v1.csv",
  "inst/extdata/native_nonfunction_source_gaps_v1.csv",
  "tests/testthat/test-native-four-pilot-review-matrix.R",
  "tests/testthat/helper-frozen-python-source-symbol.R",
  "tests/testthat/test-native-functional-recovery-orchestration.R",
  "tests/testthat/test-native-bounded-model-workflows.R",
  "tests/testthat/test-native-generalized-gee-bootstrap.R",
  "tests/testthat/test-native-workflow-bundle-export.R",
  "tests/testthat/test-native-mixed-covariance-sensitivity.R",
  "tests/testthat/test-native-mixed-participant-bootstraps.R",
  "tests/testthat/test-native-thirdparty-functional-analogues.R",
  "tests/testthat/test-native-final-sparse-elastic-analogues.R",
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
  "R/native-functional-regression.R",
  "R/native-recurrence-workflow.R",
  "R/native-recurrence.R",
  "R/native-source-time-units.R",
  "R/native-nonlinear-recurrence.R",
  "R/native-divergence.R",
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
  "tests/testthat/test-native-direct-source-workflow-attribution.R",
  "tests/testthat/test-native-wild-bootstrap-projection.R",
  "tests/testthat/test-native-wild-bootstrap-truncation-scan.R",
  "tests/testthat/test-native-recurrence-workflow.R",
  "tests/testthat/test-native-recurrence-minkowski-source.R",
  "tests/testthat/test-native-source-time-units.R",
  "tests/testthat/test-native-source-windowed-rqa-time-units.R",
  "tests/testthat/test-native-nonlinear-recurrence.R",
  "tests/testthat/test-native-source-workflows.R",
  "tests/testthat/test-native-direct-source-workflow-attribution.R",
  "tests/testthat/test-native-workflow-plot-dispatch.R",
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
  "tests/testthat/test-native-functional-recovery-evidence.R",
  "tests/testthat/test-native-direct-source-recovery-evidence-attribution.R",
  "tests/testthat/test-native-generalized-fosr-coefficient-bands.R",
  "tests/testthat/test-native-mixed-coefficient-bands-source.R",
  "tests/testthat/test-native-mixed-known-truth-recovery.R",
  "tests/testthat/test-native-mixed-variance-decomposition-source.R",
  "tests/testthat/test-native-fpca-known-truth-recovery.R",
  "tests/testthat/test-native-fpca-external-score-reconstruction.R",
  "tests/testthat/test-native-pilot-source-adversarial.R",
  "man/native-api.Rd",
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
  "tests/testthat/test-native-sparse-scientific-graphics.R",
  "tests/testthat/test-native-source-diagnostic-frames.R",
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
  all(fixture_attribution$literal_etpy_get_export_call_for_this_contract),
  all(fixture_attribution$test_that_cases_declared_in_entire_fixture_file>=1L),
  all(!fixture_attribution$per_contract_test_execution_independently_attributed),
  all(!fixture_attribution$per_contract_python_oracle_independently_replayed),
  all(!fixture_attribution$fully_certified))
# Do not hide missing direct source export calls behind 111/111
# selected filenames. Emit independently reviewable row-level deficiencies
# and a lossless resolution-lane count across every recorded source gap.
missing_refs_path<-file.path(packet_root,
  "selected_111_missing_literal_python_source_references.csv")
gap_lanes_path<-file.path(packet_root,
  "source_gap_resolution_lane_counts.csv")
four_pilots_path<-file.path(packet_root,
  "four_numerical_pilots_external_review_priority.csv")
stopifnot(all(file.exists(c(missing_refs_path,gap_lanes_path,
  four_pilots_path))))
missing_refs<-utils::read.csv(missing_refs_path,
  stringsAsFactors=FALSE,check.names=FALSE)
gap_lanes<-utils::read.csv(gap_lanes_path,
  stringsAsFactors=FALSE,check.names=FALSE)
pilot_review<-utils::read.csv(four_pilots_path,
  stringsAsFactors=FALSE,check.names=FALSE)
# With 111/111 source literals the missing queue has zero rows; verify
# its schema but do not negate absent or zero-length CSV columns.
# Nonempty queues must retain correctly typed FALSE approval flags.
required_missing_columns<-c("python_name","python_source_file",
  "source_gap_kind","known_source_difference",
  "independently_verified_export_oracle","fully_certified")
stopifnot(all(required_missing_columns%in%names(missing_refs)))
if(nrow(missing_refs)>0L){
  stopifnot(
    is.logical(missing_refs$independently_verified_export_oracle),
    is.logical(missing_refs$fully_certified),
    !anyNA(missing_refs$independently_verified_export_oracle),
    !anyNA(missing_refs$fully_certified),
    all(!missing_refs$independently_verified_export_oracle),
    all(!missing_refs$fully_certified))
}
stopifnot(
  nrow(missing_refs)==sum(
    !fixture_attribution$literal_etpy_get_export_call_for_this_contract),
  !anyDuplicated(missing_refs$python_name),
  all(missing_refs$python_name%in%queue$python_name),
  sum(gap_lanes$open_source_gaps)==source_gap_count,
  nrow(pilot_review)==4L,
  all(!pilot_review$independent_reviewer_approved),
  all(!pilot_review$scientific_scope_approved))
stopifnot(nrow(triage)==508L,
  sum(triage$selected_oracle_candidate)==nrow(queue),
  nrow(gap_review)==source_gap_count,
  all(!triage$independent_source_contract_approved),
  all(!gap_review$resolved),
  !anyDuplicated(gap_review$python_name))
# The 203 function source gaps and the one native class source gap must
# remain separately reviewable; no signed reviewer decisions are inferred.
class_gap_file<-file.path(packet_root,
  "native_nonfunction_source_gap_resolution_queue.csv")
stopifnot(file.exists(class_gap_file))
class_gap_review<-utils::read.csv(class_gap_file,
  stringsAsFactors=FALSE,check.names=FALSE)
traj_triage<-triage[triage$python_name=="TrajectorySet",,drop=FALSE]
stopifnot(nrow(class_gap_review)==1L,
  identical(class_gap_review$python_name,"TrajectorySet"),
  isTRUE(class_gap_review$gap_open),
  all(!class_gap_review$independently_replayed),
  all(!class_gap_review$scientific_scope_approved),
  all(!class_gap_review$independent_reviewer_approved),
  all(!class_gap_review$fully_certified),
  nrow(traj_triage)==1L,
  isTRUE(traj_triage$unresolved_source_difference),
  identical(traj_triage$review_lane,"nonfunction_open_source_gap"),
  sum(triage$unresolved_source_difference)==source_gap_count+1L)
message("Review triage: ",nrow(triage)," public exports; ",
  nrow(gap_review)," callable source differences plus ",
  nrow(class_gap_review)," unresolved nonfunction source difference; ",
  sum(triage$backend_or_estimand_distinct),
  " alternative backends/estimands; zero independent approvals.")
stopifnot(nrow(missing_refs)==0L,
  sum(fixture_attribution$literal_etpy_get_export_call_for_this_contract)==
    nrow(queue))
message("All 111 selected Python exports have direct source references; ",
  "per-contract numerical and full-domain certification remain unsigned.")
message("Outstanding direct-literal source references: ",
  nrow(missing_refs),"; recorded source differences in triage: ",
  sum(gap_lanes$open_source_gaps),
  "; numerical pilot contracts still unsigned: ",nrow(pilot_review),".")
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


# A completed, exact-head aggregate qualification may produce a scoped
# reviewer worklist. This does not imply independent case-level replay,
# scientific source equivalence, approval, or certification.
source("scripts/build_four_pilot_review_matrix.R",local=TRUE)
four_pilot_worksheet<-etr_build_four_pilot_review_matrix(
  root=".",packet_dir=packet_root)
stopifnot(nrow(four_pilot_worksheet$matrix)==16L,
  !any(four_pilot_worksheet$matrix$independently_replayed_case),
  !any(four_pilot_worksheet$matrix$fully_certified))

# Source-controlled developer replay of 10 additional finite numeric
# Python/R fixtures (not independent review). Fail the capture on any
# paired discrepancy; preserve the unsigned 16-case reviewer matrix.
source("scripts/capture_four_pilot_numeric_evidence.R",local=TRUE)
four_pilot_numeric<-etr_capture_four_pilot_numeric_evidence(
  root=".",packet_dir=packet_root)
stopifnot(nrow(four_pilot_numeric$evidence)==10L,
  all(four_pilot_numeric$evidence$developer_numeric_fixture_pass),
  !any(four_pilot_numeric$evidence$independent_reviewer_approved),
  !any(four_pilot_numeric$evidence$fully_certified))

# Preserve deliberate source/native divergences in a separate recorded
# developer boundary audit. A finite fixture PASS is never full-source parity.
source("scripts/capture_four_pilot_boundary_evidence.R",local=TRUE)
four_pilot_boundaries<-etr_capture_four_pilot_boundary_evidence(
  root=".",packet_dir=packet_root)
stopifnot(nrow(four_pilot_boundaries$evidence)==4L,
  all(four_pilot_boundaries$evidence$observed_behavior_as_expected),
  all(four_pilot_boundaries$evidence$
    opt_in_python_boundary_mode_matches_source_category),
  !any(four_pilot_boundaries$evidence$
    opt_in_mode_full_source_parity_certified),
  !any(four_pilot_boundaries$evidence$source_domain_equivalence_established),
  !any(four_pilot_boundaries$evidence$independent_reviewer_approved),
  !any(four_pilot_boundaries$evidence$fully_certified))

# Hand off immutable source evidence to a REAL external reviewer.
# All submission flags default to FALSE; no signoff or parity promotion.
source("scripts/four_pilot_external_attestation.R",local=TRUE)
four_pilot_external<-etr_prepare_four_pilot_external_attestation(
  root=".",packet_dir=packet_root)
stopifnot(all(file.exists(unlist(four_pilot_external))))
message("External independent scientific review: ",
  "UNSIGNED; GPG-verified third-party decision required.")

# Fail closed while creating the *additional*, full-508 export worklist.
# The 508-row readiness audit already exists in the same exact-head run;
# these are priority batches and UNSIGNED case-level reviewer worksheets.
source("scripts/build_508_certification_review_batches.R",local=TRUE)
full_review_batches<-etr_build_508_certification_review_batches(
  root=".",packet_dir=packet_root,
  function_batch_size=24L,nonfunction_batch_size=12L)
stopifnot(nrow(full_review_batches$queue)==508L,
  nrow(full_review_batches$selection)==36L,
  nrow(full_review_batches$cases)==360L,
  nrow(full_review_batches$decisions)==36L,
  all(!full_review_batches$cases$independently_replayed),
  all(!full_review_batches$decisions$full_domain_certification_approved))
message("508-export no-recorded-gap fastlane prepared; ",
  "this is NOT an independent replay or a certification decision.")

# Record exact frozen Python 1.2 source signatures, exported object classes
# and native R formals for each selected first-wave export. Introspection
# failures remain visible in the CSV instead of being misreported as parity.
source("scripts/capture_first_wave_source_interfaces.R",local=TRUE)
first_wave_interfaces<-etr_capture_first_wave_source_interfaces(
  root=".",packet_dir=packet_root)
stopifnot(nrow(first_wave_interfaces$records)==36L,
  all(!first_wave_interfaces$records$source_full_domain_certified),
  all(!first_wave_interfaces$records$independently_reproduced),
  all(file.exists(c(first_wave_interfaces$csv,
    first_wave_interfaces$manifest))))

# Verify the ACTUAL newly generated packet, not only synthetic test fixtures.
# Both verifiers are read-only and distinguish author integrity from genuine
# independent reviewer scientific approval. Exact head is taken from the
# already recorded checkout, not from a field inside the untrusted packet.
packet_verifier_patterns<-c(
  "scripts/verify_four_pilot_review_bundle.py",
  "scripts/verify_508_certification_batch.py")
packet_verification_logs<-vapply(packet_verifier_patterns,function(script){
  label<-sub("^scripts/","",script)
  log_path<-file.path(packet_root,paste0(
    sub("\\.py$","",label),"_AUTHOR_INTEGRITY_CHECK.txt"))
  output<-tryCatch(
    suppressWarnings(system2(py_executable,args=c(
      script,shQuote(packet_root),"--expected-r-head",head_sha),
      stdout=TRUE,stderr=TRUE)),
    error=function(e)structure(
      paste0("PYTHON VERIFIER INVOCATION ERROR: ",conditionMessage(e)),
      status=1L))
  code<-attr(output,"status")
  if(is.null(code))code<-0L
  writeLines(c(as.character(output),
    paste0("ACTUAL_PACKET_VERIFIER_EXIT_CODE: ",as.integer(code))),
    log_path,useBytes=TRUE)
  if(!identical(as.integer(code),0L)){
    message("===== Actual reviewer packet integrity verifier FAILED: ",
      script," =====")
    for(line in tail(as.character(output),100L))message(line)
    stop("Actual reviewer packet FAILED its unsigned SHA256 validation: ",
      script,". Log: ",log_path,call.=FALSE)
  }
  message("Actual unsigned reviewer packet integrity PASS: ",
    script,". Evidence: ",log_path,
    " (NOT external scientific certification).")
  log_path
},character(1L))
stopifnot(length(packet_verification_logs)==2L,
  all(file.exists(packet_verification_logs)),
  !any(full_review_batches$decisions$full_domain_certification_approved))
