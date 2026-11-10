# One-shot source-semantic table closure qualification: developer review only.
# Frozen Python 1.2.0 c1cd95ad718327550f7e55393ff38582872f7a94.
# No fabricated independent certificate; no estimator or branch modification.
.etr_verify_two_zeroarg_frames <- function(){
  stopifnot(file.exists("DESCRIPTION"),file.exists("NAMESPACE"))
  branch <- system2("git",c("branch","--show-current"),
    stdout=TRUE,stderr=FALSE)
  stopifnot(identical(branch,
    "feat/native-zeroarg-source-semantic-closures-20261109") ||
    identical(branch,"feat/native-zeroarg-catalog-contract-closures-20261110"))
  dirty <- system2("git",c("status","--porcelain","--untracked-files=no"),
    stdout=TRUE,stderr=FALSE)
  stopifnot(length(dirty)==0L)
  head <- system2("git",c("rev-parse","HEAD"),
    stdout=TRUE,stderr=FALSE)
  cat("ZEROARG_SEMANTIC_CLOSURE_HEAD=",head[[1L]],"\n",sep="")
  oldpy <- Sys.getenv("ET_RUN_PYTHON_TESTS",unset=NA_character_)
  oldcran <- Sys.getenv("_R_CHECK_CRAN_INCOMING_REMOTE_",unset=NA_character_)
  on.exit({
    if(is.na(oldpy))Sys.unsetenv("ET_RUN_PYTHON_TESTS")
    else Sys.setenv(ET_RUN_PYTHON_TESTS=oldpy)
    if(is.na(oldcran))Sys.unsetenv("_R_CHECK_CRAN_INCOMING_REMOTE_")
    else Sys.setenv("_R_CHECK_CRAN_INCOMING_REMOTE_"=oldcran)
  },add=TRUE)
  Sys.setenv(ET_RUN_PYTHON_TESTS="true")
  stopifnot(identical(et_python_version(),"1.2.0"))
  source("scripts/preflight_scientific_pr.R",encoding="UTF-8",local=TRUE)
  source("scripts/preflight_rd_manuals.R",encoding="UTF-8",local=TRUE)
  testthat::test_local(".",filter=paste(c(
    "native-zeroarg-metadata-source-semantic-closure",
    "native-zeroarg-catalog-source-semantic-closures",
    "native-math-contracts-diagnostics",
    "native-functional-rqa-recovery",
    "native-nonfunction-source-gaps",
    "native-source-contract-gaps",
    "full-native-r-parity-ledger"
  ),collapse="|"),reporter="summary",
    stop_on_failure=TRUE,stop_on_warning=TRUE)
  cat("ZEROARG_SEMANTIC_CLOSURE_FROZEN_SOURCE_TEST_PASS=TRUE\n")
  source("scripts/capture_native_source_qualification_evidence.R",
    encoding="UTF-8",local=TRUE)
  cat("ZEROARG_SEMANTIC_CLOSURE_DEVELOPER_QUALIFICATION_PASS=TRUE\n")
  catalog <- etr_native_parity_catalog()
  stopifnot(sum(catalog$is_python_function &
      catalog$source_contract_gap_unresolved)==199L,
    sum(catalog$nonfunction_source_gap_unresolved)==1L,
    !any(catalog$one_to_one_native_contract_complete))
  cat("ZEROARG_SEMANTIC_CLOSURE_CALLABLE_GAPS=199;NONFUNCTION_GAPS=1\n")
  Sys.setenv("_R_CHECK_CRAN_INCOMING_REMOTE_"="FALSE")
  source("scripts/run_batch32_cran_gate.R",
    encoding="UTF-8",local=TRUE)
  checklog <- file.path("artifacts","batch32_cran_gate",
    substr(head[[1L]],1L,12L),
    "eyetrajectories.Rcheck","00check.log")
  stopifnot(file.exists(checklog))
  stat <- grep("^Status:",readLines(checklog,warn=FALSE),value=TRUE)
  stopifnot(length(stat)==1L,stat %in% c("Status: OK","Status: 1 NOTE"))
  cat("ZEROARG_SEMANTIC_CLOSURE_CRAN_STATUS=",stat,"\n",sep="")
  cat("ZEROARG_SEMANTIC_CLOSURE_ONEPASS_PASS=TRUE\n")
  cat("ZEROARG_SEMANTIC_CLOSURE_INDEPENDENT_CERTIFICATIONS=0\n")
  invisible(list(head=head[[1L]],status=stat))
}
.etr_verify_two_zeroarg_frames()
