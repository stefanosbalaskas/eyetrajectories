# Recheck every installed-test file implicated by the November 13 full
# R CMD check, before paying the cost of another package-wide source build.
# This is an AUTHOR diagnostic gate, not independent 508-export certification.
# Run in the repository root: source("scripts/verify_installed_failure_repairs_20261113.R")
# For the frozen Python 1.2 oracles:
#   Restart R
#   source("scripts/verify_qualification_managed_python_20261113.R")
#   Sys.setenv(ET_RUN_INSTALLED_REPAIRS_PYTHON="true")
#   source("scripts/verify_installed_failure_repairs_20261113.R")
# The separate mode flag avoids inadvertently enabling Python tests during
# a CRAN-safe native-only regression check.
if(!file.exists("DESCRIPTION")||!dir.exists("tests/testthat"))
  stop("Run this qualification script from the EyeTrajectories repository root",
    call.=FALSE)
python_mode<-identical(Sys.getenv("ET_RUN_INSTALLED_REPAIRS_PYTHON"),"true")
Sys.setenv(
  ET_RUN_PYTHON_TESTS=if(python_mode)"true" else "false",
  ET_RUN_PYTHON_ELASTIC_TESTS="false",
  ET_RUN_SCIENTIFIC_SLOW="false",
  TESTTHAT_MAX_FAILS="200")
options(testthat.progress.max_fails=200L)
source("scripts/preflight_rd_manuals.R")
if(!requireNamespace("pkgload",quietly=TRUE)||
   !requireNamespace("testthat",quietly=TRUE))
  stop("Install pkgload and testthat before source qualification",call.=FALSE)
pkgload::load_all(".",quiet=TRUE)
if(python_mode){
  if(!requireNamespace("reticulate",quietly=TRUE)||
     !nzchar(Sys.getenv("RETICULATE_PYTHON")))
    stop("Python-mode repair qualification requires reticulate and the ",
      "managed frozen Python launcher in a fresh R session",call.=FALSE)
  version<-tryCatch(et_python_version(),error=function(e)
    stop("Cannot access frozen Python 1.2: ",conditionMessage(e),
      call.=FALSE))
  if(!identical(version,"1.2.0"))
    stop("Refuse differential qualification with Python version: ",
      version,call.=FALSE)
  cat("INSTALLED_REPAIR_FROZEN_PYTHON=1.2.0\n")
}
# Exact test-file names from the 53-failure installed-package transcript.
implicated<-c(
  "native-certification",
  "native-first-wave-source-interfaces",
  "native-fixed-multiplier-replay-source",
  "native-four-multivar-rqa-recovery-artists-20261112",
  "native-fpca-fixed-bootstrap-source",
  "native-fpca-inference-source-graphics",
  "native-fpcr-bootstrap-full-source-20261111",
  "native-fpcr-future-full-source-20261111",
  "native-fpcr-slope-pace-three-artists-20261112",
  "native-functional-registration-plots",
  "native-functional-rqa-recovery",
  "native-generalized-gee-bootstrap-full-source-20261112",
  "native-generalized-gee-fit-workflow-full-source-20261112",
  "native-math-contracts-diagnostics",
  "native-miaaft-pair-full-source-20261111",
  "native-mixed-four-diagnostic-artists-20261112",
  "native-mixed-w3-source-records-20261112",
  "native-paired-mixed-band-sensitivity-20261112",
  "native-score-numeric-source",
  "native-score-overdeclared-source",
  "native-source-audit-frames",
  "native-source-contract-alignment",
  "native-source-environment",
  "native-source-model-reports",
  "native-source-text-inference",
  "native-sparse-mfpca-python-portable-bundles-20261112",
  "native-sparse-multilevel-prediction-w2-source-20261112",
  "native-visual-diagnostics",
  "native-workflow-source-audit")
files<-file.path("tests","testthat",paste0("test-",implicated,".R"))
if(!all(file.exists(files)))
  stop("Missing implicated source tests: ",
    paste(files[!file.exists(files)],collapse=", "),call.=FALSE)
cat("INSTALLED_REPAIR_TEST_FILES=",length(files),"\n",sep="")
cat("INSTALLED_REPAIR_SCOPE=",if(python_mode)
  "FROZEN_PYTHON_1_2_DIFFERENTIAL" else "NO_PYTHON_NATIVE_SOURCE_FIRST",
  "\n",sep="")
testthat::test_local(".",
  filter=paste(implicated,collapse="|"),
  reporter="progress",stop_on_failure=TRUE,stop_on_warning=TRUE)
cat("INSTALLED_REPAIR_REGRESSION_PASS; python_mode=",python_mode,
  "; certification=FALSE\n",sep="")
