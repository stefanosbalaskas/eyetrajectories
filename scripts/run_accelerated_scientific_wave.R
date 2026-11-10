# Single consolidated local gate for one scientific implementation wave.
#    ET_SCIENTIFIC_WAVE_MODE=fast: targeted R + live Python differential only
#    ET_SCIENTIFIC_WAVE_MODE=full: fast + full frozen source qualification
#                                  + ONE clean Git-snapshot CRAN-style check
#    ET_SCIENTIFIC_WAVE_MODE=cran: clean Git-snapshot CRAN check only
#    ET_RUN_SPARSE_SOURCE_DIFF=true: additionally compare fitted source
#       univariate sparse FPCA/PACE and direct joint sparse MFPCA
#       covariance, eigenfunctions and scores with frozen Python 1.2
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
    # Structural inventory and queue preparation remain strict. Ordinary
    # Python unit failures are accumulated so one fixture failure does not
    # waste the rest of the native/Python differential evidence run.
    python_test_failures<-character()
    runpy_test<-function(path){
      tryCatch(runpy(path),error=function(e){
        python_test_failures<<-c(python_test_failures,path)
        cat("ACCELERATED_WAVE_PYTHON_TEST_FAILURE=",
          path,";MESSAGE=",conditionMessage(e),"\n",sep="")
      })
      invisible(NULL)
    }
    runpy("scripts/source_gap_inventory.py")
    runpy("scripts/build_accelerated_scientific_wave.py")
    runpy_test("tests/test_source_gap_inventory.py")
    runpy_test("tests/test_build_accelerated_scientific_wave.py")
    runpy_test("tests/test_summarize_scientific_source_evidence.py")
    runpy_test("tests/test_build_independent_scientific_review_packet.py")
    cat("ACCELERATED_WAVE_PYTHON_UNIT_TEST_FAILURES=",
      length(python_test_failures),"\n",sep="")
    targeted_failure<-NULL
    tryCatch(testthat::test_local(".",filter=paste(c(
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
      "native-numpy-pcg64",
      "native-miaaft-fixed-permutation-source",
      "native-fpcr-bootstrap-uncertainty",
      "native-fpca-component-envelopes",
      "native-generalized-gee-fit",
      "native-generalized-gee-bootstrap",
      "native-generalized-fosr-prediction",
      "native-generalized-fosr-bootstrap-source",
      "native-generalized-fosr-coefficient-bands",
      "native-generalized-fosr-contrast-source",
      "native-joint-likelihood-covariance-sensitivity",
      "native-joint-fixed-covariance-bootstrap",
      "native-joint-structured-full-refit",
      "native-sparse-source-pace",
      "native-observation-process",
      "native-sparse-mfpca-source",
      "native-sparse-mfpca-score-uncertainty",
      "native-sparse-partial-trajectory-prediction",
      "native-sparse-partial-conformal",
      "native-sparse-multilevel-source",
      "native-sparse-mfpca-async-source",
      "native-functional-rqa-recovery",
      "native-functional-diagnostics"
    ),collapse="|"),reporter="summary",
      stop_on_failure=TRUE,stop_on_warning=TRUE),
    error=function(e){
      targeted_failure<<-conditionMessage(e)
      cat("ACCELERATED_WAVE_TARGETED_R_FAILURE_RECORDED=",
        targeted_failure,"\n",sep="")
      NULL
    })
    if(is.null(targeted_failure))
      cat("ACCELERATED_WAVE_TARGETED_R_PASS=TRUE\n")
    else cat("ACCELERATED_WAVE_TARGETED_R_PASS=FALSE\n")
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
    sparse_disagreements<-0L
    sparse_runner_errors<-character()
    if(identical(Sys.getenv("ET_RUN_SPARSE_SOURCE_DIFF"),"true")){
      # Run both expensive sparse scientific source families in the same
      # local wave even if the first finds numerical differences. This
      # preserves strict fail-on-divergence at the final consolidated gate
      # without wasting another RStudio round trip. Never change the
      # saved strict environment setting permanently.
      sparse_runner<-function(path,tag){
        previous<-Sys.getenv("ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE",
          unset=NA_character_)
        on.exit({
          if(is.na(previous))
            Sys.unsetenv("ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE")
          else Sys.setenv(
            ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE=previous)
        },add=TRUE)
        Sys.setenv(ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE="false")
        report<-tryCatch(
          source(path,encoding="UTF-8",local=TRUE)$value,
          error=function(e){
            sparse_runner_errors<<-c(sparse_runner_errors,paste0(
              tag,": ",conditionMessage(e)))
            cat("ACCELERATED_WAVE_SPARSE_RUNNER_ERROR=",tag,
              ";MESSAGE=",conditionMessage(e),"\n",sep="")
            NULL
          })
        if(is.null(report))return(invisible(NULL))
        stopifnot(is.data.frame(report),
          "outcome"%in%names(report))
        differences<-grepl(
          "^(DIVERGENT|SOURCE_EXCEPTION|INVALID_FIXTURE)",
          report$outcome)
        sparse_disagreements<<-sparse_disagreements+
          sum(differences)
        cat("ACCELERATED_WAVE_SPARSE_",tag,"_CASES=",
          nrow(report),";DIFFERENCES=",sum(differences),
          "\n",sep="")
        invisible(report)
      }
      sparse_runner("scripts/run_sparse_fpca_source_differential.R",
        "FPCA")
      sparse_runner("scripts/run_sparse_mfpca_source_differential.R",
        "MFPCA")
      sparse_runner("scripts/run_sparse_prediction_source_differential.R",
        "PREDICTION")
      sparse_runner("scripts/run_sparse_multilevel_source_differential.R",
        "MULTILEVEL")
      sparse_runner("scripts/run_sparse_mfpca_async_source_differential.R",
        "ASYNC")
      sparse_runner("scripts/run_sparse_workflow_source_differential.R",
        "WORKFLOW")
      sparse_runner("scripts/run_sparse_observation_source_differential.R",
        "OBSERVATION")
      sparse_runner("scripts/run_functional_core_source_differential.R",
        "FUNCTIONAL_CORE")
      cat("ACCELERATED_WAVE_SPARSE_FPCA_SOURCE_DIFF_ATTEMPTED=TRUE\n")
      cat("ACCELERATED_WAVE_SPARSE_MFPCA_SOURCE_DIFF_ATTEMPTED=TRUE\n")
      cat("ACCELERATED_WAVE_SPARSE_PREDICTION_SOURCE_DIFF_ATTEMPTED=TRUE\n")
      cat("ACCELERATED_WAVE_SPARSE_MULTILEVEL_SOURCE_DIFF_ATTEMPTED=TRUE\n")
      cat("ACCELERATED_WAVE_SPARSE_ASYNC_SOURCE_DIFF_ATTEMPTED=TRUE\n")
      cat("ACCELERATED_WAVE_SPARSE_WORKFLOW_SOURCE_DIFF_ATTEMPTED=TRUE\n")
      cat("ACCELERATED_WAVE_SPARSE_OBSERVATION_SOURCE_DIFF_ATTEMPTED=TRUE\n")
      cat("ACCELERATED_WAVE_FUNCTIONAL_CORE_SOURCE_DIFF_ATTEMPTED=TRUE\n")
    }
    runpy("scripts/summarize_scientific_source_evidence.py")
    # Refresh the algorithmic work queue *after* recorded frozen-source
    # comparisons, not only from the pre-differential snapshot.
    runpy("scripts/build_accelerated_scientific_wave.py")
    runpy("scripts/build_independent_scientific_review_packet.py")
    cat("ACCELERATED_WAVE_BOUNDED_PYTHON_DIFF_RECORDED=TRUE\n")
    if(length(sparse_runner_errors)>0L)
      stop(paste("Sparse source runner execution failure:",
        paste(sparse_runner_errors,collapse=" | ")),call.=FALSE)
    if(sparse_disagreements>0L&&identical(
      Sys.getenv("ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE"),"true"))
      stop(sprintf(
        "Sparse source differential remains divergent: %d recorded cases across sparse families; see unsigned reports",
        sparse_disagreements),call.=FALSE)
    # All Python unit test failures remain release-blocking, but the full
    # source differential suite has now had its chance to produce evidence.
    if(length(python_test_failures)>0L)
      stop(paste("Python source-wave tests failed:",
        paste(python_test_failures,collapse=" | "),
        "; review full logs and unsigned source reports"),call.=FALSE)
    # The native test gate stays strict even though we now collect the
    # numerical differential evidence in the same user RStudio run.
    if(!is.null(targeted_failure))
      stop(paste(
        "Targeted scientific R tests failed; source comparisons were attempted and evidence recorded:",
        targeted_failure),call.=FALSE)
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
