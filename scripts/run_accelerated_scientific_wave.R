# Single consolidated local gate for one scientific implementation wave.
#    ET_SCIENTIFIC_WAVE_MODE=fast: targeted R + live Python differential only
#    ET_SCIENTIFIC_WAVE_MODE=full: fast + full frozen source qualification
#                                  + ONE clean Git-snapshot CRAN-style check
#    ET_SCIENTIFIC_WAVE_MODE=cran: clean Git-snapshot CRAN check only
#    ET_RUN_SPARSE_SOURCE_DIFF=true: additionally compare fitted source
#       sparse FPCA/PACE covariance, eigenfunctions and scores with Python 1.2
#    ET_RUN_BOOTSTRAP_SOURCE_DIFF=true: additionally run 100 whole-participant
#       source/native GEE refits per Poisson, grouped binomial and exposure
#       family; write unsigned scientific comparison evidence separately.
# Never increments the 508 certification ledger, publishes to CRAN, or
# claims full Python source equivalence from bounded numerical probes.
#
# Sys.setenv(ET_SCIENTIFIC_WAVE_MODE="fast")
# source("scripts/run_accelerated_scientific_wave.R")

.etr_run_accelerated_scientific_wave <- function() {
  stopifnot(file.exists("DESCRIPTION"),dir.exists("tests/testthat"))
  mode <- Sys.getenv("ET_SCIENTIFIC_WAVE_MODE","fast")
  stopifnot(mode %in% c("fast","full","cran"))
  head <- system2("git",c("rev-parse","HEAD"),
    stdout=TRUE,stderr=FALSE)
  stopifnot(length(head)==1L,nchar(head[[1L]])==40L)
  dirty <- system2("git",c("status","--porcelain",
    "--untracked-files=no"),stdout=TRUE,stderr=FALSE)
  stopifnot(length(dirty)==0L)
  cat("ACCELERATED_WAVE_MODE=",mode,
    ";HEAD=",head[[1L]],"\n",sep="")
  oldpy <- Sys.getenv("ET_RUN_PYTHON_TESTS",unset=NA_character_)
  oldcran <- Sys.getenv("_R_CHECK_CRAN_INCOMING_REMOTE_",
    unset=NA_character_)
  on.exit({
    if(is.na(oldpy))Sys.unsetenv("ET_RUN_PYTHON_TESTS")
    else Sys.setenv(ET_RUN_PYTHON_TESTS=oldpy)
    if(is.na(oldcran))Sys.unsetenv("_R_CHECK_CRAN_INCOMING_REMOTE_")
    else Sys.setenv("_R_CHECK_CRAN_INCOMING_REMOTE_"=oldcran)
  },add=TRUE)

  # Run target-family checks often. Do not rebuild/check CRAN for every
  # local function edit; CRAN is the single final gate in full/cran mode.
  if(mode != "cran") {
    stopifnot(requireNamespace("testthat",quietly=TRUE),
      requireNamespace("reticulate",quietly=TRUE))
    Sys.setenv(ET_RUN_PYTHON_TESTS="true",MPLBACKEND="Agg")
    source("scripts/preflight_scientific_pr.R",
      encoding="UTF-8",local=TRUE)
    source("scripts/preflight_rd_manuals.R",
      encoding="UTF-8",local=TRUE)
    py <- reticulate::py_config()$python
    runpy <- function(path) {
      out <- suppressWarnings(system2(py,path,
        stdout=TRUE,stderr=TRUE))
      cat(paste(out,collapse="\n"),"\n")
      status <- attr(out,"status")
      if(is.null(status)) status <- 0L
      if(status!=0L)stop("Python source-wave program failed: ",path,
        call.=FALSE)
    }
    runpy("scripts/source_gap_inventory.py")
    runpy("scripts/build_accelerated_scientific_wave.py")
    runpy("tests/test_source_gap_inventory.py")
    runpy("tests/test_build_accelerated_scientific_wave.py")
    runpy("tests/test_summarize_scientific_source_evidence.py")
    testthat::test_local(".",filter=paste(c(
      "native-zeroarg-metadata-source-semantic-closure",
      "native-independent-source-review-packet",
      "native-508-certification-batches",
      "native-all-function-mapping-complete",
      "native-nonfunction-source-gaps",
      "native-source-contract-gaps",
      # Actual scientific estimators, not only mapping and metadata tests.
      "native-wild-bootstrap-projection",
      "native-wild-bootstrap-truncation-scan",
      "native-multivariate-iaaft-generator",
      "native-multivariate-surrogate-nonlinearity",
      "native-generalized-gee-fit",
      "native-generalized-gee-bootstrap",
      "native-generalized-fosr-prediction",
      "native-generalized-fosr-bootstrap-source",
      "native-generalized-fosr-coefficient-bands",
      "native-generalized-fosr-contrast-source",
      "native-joint-likelihood-covariance-sensitivity",
      "native-joint-fixed-covariance-bootstrap",
      "native-joint-structured-full-refit",
      "native-sparse-source-pace"
    ),collapse="|"),reporter="summary",
      stop_on_failure=TRUE,stop_on_warning=TRUE)
    cat("ACCELERATED_WAVE_TARGETED_R_PASS=TRUE\n")
    source("scripts/run_batched_numeric_source_differential.R",
      encoding="UTF-8",local=TRUE)
    source("scripts/run_generalized_gee_source_differential.R",
      encoding="UTF-8",local=TRUE)
    cat("ACCELERATED_WAVE_GENERALIZED_GEE_DIFF_RECORDED=TRUE\n")
    if(identical(Sys.getenv("ET_RUN_BOOTSTRAP_SOURCE_DIFF"),"true")){
      source("scripts/run_generalized_gee_bootstrap_source_differential.R",
        encoding="UTF-8",local=TRUE)
      cat("ACCELERATED_WAVE_GEE_BOOTSTRAP_SOURCE_DIFF_RECORDED=TRUE\n")
    }
    if(identical(Sys.getenv("ET_RUN_SPARSE_SOURCE_DIFF"),"true")){
      source("scripts/run_sparse_fpca_source_differential.R",
        encoding="UTF-8",local=TRUE)
      cat("ACCELERATED_WAVE_SPARSE_FPCA_SOURCE_DIFF_RECORDED=TRUE\n")
    }
    runpy("scripts/summarize_scientific_source_evidence.py")
    cat("ACCELERATED_WAVE_BOUNDED_PYTHON_DIFF_RECORDED=TRUE\n")
  }

  if(mode == "full") {
    source("scripts/capture_native_source_qualification_evidence.R",
      encoding="UTF-8",local=TRUE)
    cat("ACCELERATED_WAVE_FULL_AUTHOR_QUALIFICATION_PASS=TRUE\n")
  }

  if(mode %in% c("full","cran")) {
    Sys.setenv("_R_CHECK_CRAN_INCOMING_REMOTE_"="FALSE")
    source("scripts/run_batch32_cran_gate.R",
      encoding="UTF-8",local=TRUE)
    checklog <- file.path("artifacts","batch32_cran_gate",
      substr(head[[1L]],1L,12L),
      "eyetrajectories.Rcheck","00check.log")
    stopifnot(file.exists(checklog))
    status <- grep("^Status:",
      readLines(checklog,warn=FALSE),value=TRUE)
    stopifnot(length(status)==1L,
      status %in% c("Status: OK","Status: 1 NOTE"))
    cat("ACCELERATED_WAVE_CRAN_STATUS=",status,"\n",sep="")
  }
  cat("ACCELERATED_WAVE_MODE_PASS=",mode,"\n",sep="")
  cat("ACCELERATED_WAVE_INDEPENDENT_CERTIFICATIONS=0\n")
  invisible(list(head=head[[1L]],mode=mode))
}
.etr_run_accelerated_scientific_wave()
