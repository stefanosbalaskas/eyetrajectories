# One-pass qualification for direct native joint mixed-model variance and
# fixed-coefficient source numerical reporting functions.
# Requires an opt-in real nlme likelihood fit; it never changes tracked files,
# the Git branch, or the 508-export evidence ledger.

.etr_run_joint_variance_wave_gate <- function(){
  stopifnot(file.exists("DESCRIPTION"),dir.exists("tests/testthat"))
  current <- system2("git",c("branch","--show-current"),
    stdout=TRUE,stderr=FALSE)
  stopifnot(identical(current,
    "feat/native-joint-source-variance-coefficient-20261109"))
  changed <- system2("git",
    c("status","--porcelain","--untracked-files=no"),
    stdout=TRUE,stderr=FALSE)
  stopifnot(!length(changed))
  .etr_assert(identical(
    Sys.getenv("ET_RUN_NATIVE_JOINT_WORKFLOW_INTEGRATION"),"true"),
    "live Gaussian nlme likelihood test must be explicitly enabled")
  head <- system2("git",c("rev-parse","HEAD"),
    stdout=TRUE,stderr=FALSE)
  cat("JOINT_SOURCE_VARIANCE_HEAD=",head[[1L]],"\n",sep="")
  source("scripts/preflight_scientific_pr.R",
    encoding="UTF-8",local=TRUE)
  source("scripts/preflight_rd_manuals.R",
    encoding="UTF-8",local=TRUE)
  testthat::test_local(".",filter=paste(c(
    "native-joint-source-variance-coefficient",
    "native-joint-bspline-source-workflow",
    "native-joint-mixed-source-frames",
    "native-bounded-model-workflows",
    "native-joint-bspline-nested-slope-batch39",
    "native-joint-bspline-nested-trial-batch38"
  ),collapse="|"),reporter="summary",
    stop_on_failure=TRUE,stop_on_warning=TRUE)
  cat("JOINT_SOURCE_VARIANCE_TARGETED_TESTS_PASS=TRUE\n")
  source("scripts/capture_native_source_qualification_evidence.R",
    encoding="UTF-8",local=TRUE)
  cat("JOINT_SOURCE_VARIANCE_DEVELOPER_QUALIFICATION_PASS=TRUE\n")
  original <- Sys.getenv("_R_CHECK_CRAN_INCOMING_REMOTE_",
    unset=NA_character_)
  on.exit({
    if(is.na(original))Sys.unsetenv("_R_CHECK_CRAN_INCOMING_REMOTE_")
    else Sys.setenv("_R_CHECK_CRAN_INCOMING_REMOTE_"=original)
  },add=TRUE)
  Sys.setenv("_R_CHECK_CRAN_INCOMING_REMOTE_"="FALSE")
  source("scripts/run_batch32_cran_gate.R",
    encoding="UTF-8",local=TRUE)
  checklog <- file.path("artifacts","batch32_cran_gate",
    substr(head[[1L]],1L,12L),
    "eyetrajectories.Rcheck","00check.log")
  stopifnot(file.exists(checklog))
  status <- grep("^Status:",readLines(checklog,warn=FALSE),value=TRUE)
  stopifnot(length(status)==1L,
    status %in% c("Status: OK","Status: 1 NOTE"))
  cat("JOINT_SOURCE_VARIANCE_CRAN_STATUS=",status,"\n",sep="")
  cat("JOINT_SOURCE_VARIANCE_ONEPASS_PASS=TRUE\n")
  cat("JOINT_SOURCE_VARIANCE_GAP_CLOSURES=0;INDEPENDENT_CERTIFICATIONS=0\n")
  invisible(list(head=head[[1L]],cran_status=status))
}
.etr_run_joint_variance_wave_gate()
