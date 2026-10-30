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
for(path in test_files)parse(file=path,keep.source=FALSE)
pkgload::load_all(".",quiet=TRUE)
filter<-paste(required,collapse="|")
Sys.unsetenv("ET_RUN_PYTHON_TESTS")
testthat::test_local(".",filter=filter,reporter="summary",
  stop_on_failure=TRUE)
stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(testthat::test_local(".",filter=filter,
    reporter="summary",stop_on_failure=TRUE),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))
message("Candidate source oracles passed; no full-contract certification was inferred.")
