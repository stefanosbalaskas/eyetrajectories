# One-pass local qualification for PR #72's opt-in joint Gaussian workflow.
# This script changes neither source files nor Git branches. Run from package
# root after checking out feat/native-source-joint-bspline-workflow-20261109.
# The source contract and independent review remain explicitly uncertified.

.etr_run_joint_source_wave_gate <- function() {
  stopifnot(file.exists("DESCRIPTION"),dir.exists("tests/testthat"))
  branch <- system2("git",c("branch","--show-current"),stdout=TRUE,
    stderr=FALSE)
  stopifnot(identical(branch,
    "feat/native-source-joint-bspline-workflow-20261109"))
  dirty <- system2("git",c("status","--porcelain",
    "--untracked-files=no"),stdout=TRUE,stderr=FALSE)
  stopifnot(length(dirty)==0L)
  head <- system2("git",c("rev-parse","HEAD"),stdout=TRUE)
  cat("NATIVE_JOINT_SOURCE_WAVE_HEAD=",head[[1L]],"\n",sep="")
  source("scripts/preflight_scientific_pr.R",encoding="UTF-8",
    local=TRUE)
  source("scripts/preflight_rd_manuals.R",encoding="UTF-8",
    local=TRUE)
  testthat::test_local(".",filter=paste(c(
    "native-joint-bspline-source-workflow",
    "native-joint-mixed-source-frames",
    "native-bounded-model-workflows",
    "native-source-audit-frames",
    "native-joint-bspline-nested-slope-batch39",
    "native-joint-bspline-nested-trial-batch38"
  ),collapse="|"),reporter="summary",
    stop_on_failure=TRUE,stop_on_warning=TRUE)
  cat("NATIVE_JOINT_SOURCE_WAVE_TARGETED_TESTS_PASS=TRUE\n")
  source("scripts/capture_native_source_qualification_evidence.R",
    encoding="UTF-8",local=TRUE)
  cat("NATIVE_JOINT_SOURCE_WAVE_FULL_DEVELOPER_QUALIFICATION_PASS=TRUE\n")
  old <- Sys.getenv("_R_CHECK_CRAN_INCOMING_REMOTE_",
    unset=NA_character_)
  on.exit({
    if(is.na(old))Sys.unsetenv("_R_CHECK_CRAN_INCOMING_REMOTE_")
    else Sys.setenv("_R_CHECK_CRAN_INCOMING_REMOTE_"=old)
  },add=TRUE)
  Sys.setenv("_R_CHECK_CRAN_INCOMING_REMOTE_"="FALSE")
  source("scripts/run_batch32_cran_gate.R",encoding="UTF-8",
    local=TRUE)
  gate <- file.path("artifacts","batch32_cran_gate",
    substr(head[[1L]],1L,12L),
    "eyetrajectories.Rcheck","00check.log")
  if(!file.exists(gate)) {
    # R CMD check is invoked from the gate working directory.
    gate <- file.path("artifacts","batch32_cran_gate",
      substr(head[[1L]],1L,12L),
      "eyetrajectories.Rcheck","00check.log")
  }
  stopifnot(file.exists(gate))
  log <- readLines(gate,warn=FALSE)
  status <- grep("^Status:",log,value=TRUE)
  stopifnot(length(status)==1L,
    status %in% c("Status: OK","Status: 1 NOTE"),
    !any(grepl("^Status:.*ERROR|^Status:.*WARNING",log)))
  cat("NATIVE_JOINT_SOURCE_WAVE_CRAN_STATUS=",status,"\n",sep="")
  cat("NATIVE_JOINT_SOURCE_WAVE_ONEPASS_PASS=TRUE\n")
  cat("NATIVE_JOINT_SOURCE_GAP_CLOSURES=0;INDEPENDENT_CERTIFICATIONS=0\n")
  invisible(list(head=head[[1L]],check_status=status))
}
.etr_run_joint_source_wave_gate()
