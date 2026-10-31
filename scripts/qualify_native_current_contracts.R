# Execute from the package root, after checkout of PR #48's branch.
# Unlike a regex-only test call, this fails clearly on missing test files.
if(!file.exists("DESCRIPTION")||!dir.exists("tests/testthat"))
  stop("Run from the eyetrajectories package root (DESCRIPTION and tests/testthat).",
       call.=FALSE)
required<-c("native-generalized-fosr-prediction",
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
  "native-certification-readiness",
  "full-native-r-parity-ledger",
  "native-private-helper-names",
  "native-mixed-model-source-text","native-source-environment")
test_files<-file.path("tests","testthat",paste0("test-",required,".R"))
git<-Sys.which("git")
branch<-if(nzchar(git)){
  b<-suppressWarnings(system2(git,c("branch","--show-current"),
    stdout=TRUE,stderr=FALSE))
  if(length(b)==1L&&nzchar(b))b else "<unknown>"
} else "<git unavailable>"
head<-if(nzchar(git)){
  h<-suppressWarnings(system2(git,c("rev-parse","--short","HEAD"),
    stdout=TRUE,stderr=FALSE))
  if(length(h)==1L&&nzchar(h))h else "<unknown>"
} else "<git unavailable>"
message("Checkout: ",normalizePath(".",winslash="/"),
  " | branch: ",branch," | commit: ",head)
missing<-test_files[!file.exists(test_files)]
if(length(missing))
  stop("Test discovery failed: absent files: ",
    paste(missing,collapse=", "),
    ". Fetch and check out the PR #48 branch ",
    "'research/native-generalized-fosr-prediction-20261030'.",call.=FALSE)
if(!all(vapply(c("zip","jsonlite","digest"),
    requireNamespace,logical(1L),quietly=TRUE)))
  stop("Source portable-writer qualification needs zip, jsonlite and digest; install.packages(c('zip','jsonlite','digest')) before running.",call.=FALSE)
for(path in test_files)parse(file=path,keep.source=FALSE)
source("scripts/preflight_native_source_syntax.R",local=TRUE)
pkgload::load_all(".",quiet=TRUE)
filter<-paste(required,collapse="|")
# Run both evidence modes even when one fails. Merely skipping a Python
# oracle cannot be reported as a Python parity pass.
.etr_qualify_current_once<-function(python=FALSE){
  original<-Sys.getenv("ET_RUN_PYTHON_TESTS",unset=NA_character_)
  on.exit({
    if(is.na(original))Sys.unsetenv("ET_RUN_PYTHON_TESTS")
    else Sys.setenv(ET_RUN_PYTHON_TESTS=original)
  },add=TRUE)
  if(python)Sys.setenv(ET_RUN_PYTHON_TESTS="true")
  else Sys.unsetenv("ET_RUN_PYTHON_TESTS")
  mode<-if(python)"pinned Python 1.2 direct-source" else "offline native R"
  message("Qualifying ",mode," (candidate contracts remain unsigned).")
  tryCatch({
    testthat::test_local(".",filter=filter,reporter="summary",
      stop_on_failure=TRUE,stop_on_warning=TRUE)
    message(mode,": PASS")
    TRUE
  },error=function(e){
    message(mode,": FAIL: ",conditionMessage(e))
    FALSE
  })
}
native_pass<-.etr_qualify_current_once(FALSE)
python_version<-tryCatch(et_python_version(),error=function(e){
  message("Pinned Python 1.2 availability error: ",conditionMessage(e))
  NA_character_
})
python_pass<-if(identical(python_version,"1.2.0")){
  .etr_qualify_current_once(TRUE)
}else{
  message("pinned Python 1.2 direct-source: NOT QUALIFIED; detected version: ",
    if(length(python_version)==1L&&!is.na(python_version))
      python_version else "<unavailable>")
  FALSE
}
if(!native_pass||!python_pass){
  stop("Source candidate qualification failed: native_r=",
    if(native_pass)"PASS" else "FAIL",
    "; pinned_python_1_2=",
    if(python_pass)"PASS" else "FAIL_OR_UNAVAILABLE",
    "; no source contracts certified.",call.=FALSE)
}
message("Both candidate source modes passed; this does not establish full-domain independent certification.")
