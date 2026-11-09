# One-pass source-family residual audit qualification for native R/nlme fits.
# Read-only; no branch changes, file mutations or false source certification.
.etr_run_joint_residual_wave_gate <- function() {
  stopifnot(file.exists("DESCRIPTION"),dir.exists("tests/testthat"))
  branch <- system2("git",c("branch","--show-current"),
    stdout=TRUE,stderr=FALSE)
  stopifnot(identical(branch,"feat/native-joint-residual-source-audit-20261109"))
  tracked <- system2("git",c("status","--porcelain","--untracked-files=no"),
    stdout=TRUE,stderr=FALSE)
  stopifnot(length(tracked)==0L)
  stopifnot(identical(
    Sys.getenv("ET_RUN_NATIVE_JOINT_WORKFLOW_INTEGRATION"),"true"))
  head <- system2("git",c("rev-parse","HEAD"),
    stdout=TRUE,stderr=FALSE)
  cat("JOINT_RESIDUAL_SOURCE_HEAD=",head[[1L]],"\n",sep="")
  source("scripts/preflight_scientific_pr.R",
    encoding="UTF-8",local=TRUE)
  source("scripts/preflight_rd_manuals.R",
    encoding="UTF-8",local=TRUE)
  testthat::test_local(".",filter=paste(c(
    "native-joint-residual-source-audit",
    "native-mixed-diagnostics",
    "native-mixed-residual-comparison",
    "native-joint-bspline-mixed-batch35",
    "native-joint-source-variance-coefficient",
    "native-joint-bspline-source-workflow",
    "native-joint-bspline-nested-slope-batch39",
    "native-joint-bspline-nested-trial-batch38"
  ),collapse="|"),reporter="summary",
    stop_on_failure=TRUE,stop_on_warning=TRUE)
  cat("JOINT_RESIDUAL_SOURCE_TARGETED_TESTS_PASS=TRUE\n")
  source("scripts/capture_native_source_qualification_evidence.R",
    encoding="UTF-8",local=TRUE)
  cat("JOINT_RESIDUAL_SOURCE_DEVELOPER_QUALIFICATION_PASS=TRUE\n")
  remote <- Sys.getenv("_R_CHECK_CRAN_INCOMING_REMOTE_",
    unset=NA_character_)
  on.exit({
    if(is.na(remote))Sys.unsetenv("_R_CHECK_CRAN_INCOMING_REMOTE_")
    else Sys.setenv("_R_CHECK_CRAN_INCOMING_REMOTE_"=remote)
  },add=TRUE)
  Sys.setenv("_R_CHECK_CRAN_INCOMING_REMOTE_"="FALSE")
  source("scripts/run_batch32_cran_gate.R",encoding="UTF-8",
    local=TRUE)
  checklog <- file.path("artifacts","batch32_cran_gate",
    substr(head[[1L]],1L,12L),
    "eyetrajectories.Rcheck","00check.log")
  stopifnot(file.exists(checklog))
  status <- grep("^Status:",readLines(checklog,warn=FALSE),value=TRUE)
  stopifnot(length(status)==1L,status%in%c("Status: OK","Status: 1 NOTE"))
  cat("JOINT_RESIDUAL_SOURCE_CRAN_STATUS=",status,"\n",sep="")
  cat("JOINT_RESIDUAL_SOURCE_ONEPASS_PASS=TRUE\n")
  cat("JOINT_RESIDUAL_SOURCE_GAP_CLOSURES=0;INDEPENDENT_CERTIFICATIONS=0\n")
  invisible(list(head=head[[1L]],cran_status=status))
}
.etr_run_joint_residual_wave_gate()
