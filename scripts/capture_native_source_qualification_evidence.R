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
    "native-mixed-model-source-text"),".R"))
missing_scientific_tests<-required_scientific_tests[
  !file.exists(required_scientific_tests)]
if(length(missing_scientific_tests))stop(
  "Missing required PR #48 scientific test files in the active checkout: ",
  paste(missing_scientific_tests,collapse=", "),
  ". Switch to the research/native-generalized-fosr-prediction-20261030 branch.",
  call.=FALSE)
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
stopifnot(nrow(queue)==69L,!anyDuplicated(queue$python_name),
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
  "native-mixed-model-source-text",
  "native-source-environment",
  "native-source-evidence-runner",
  "native-independent-source-review-packet",
  "native-private-helper-names"),collapse="|")
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
        reporter="summary",stop_on_failure=TRUE),
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
