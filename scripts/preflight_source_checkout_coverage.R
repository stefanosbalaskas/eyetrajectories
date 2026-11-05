#!/usr/bin/env Rscript
# Fail-closed: checkout-only regressions are REQUIRED in both native and
# pinned-Python author qualifications, never claims of independent review.
if(!file.exists("DESCRIPTION") ||
   !identical(unname(read.dcf("DESCRIPTION","Package")[1L]),
     "eyetrajectories"))
  stop("Run source-checkout coverage preflight from repository root",
    call.=FALSE)
required <- c(
  "native-508-certification-batches",
  "native-direct-numerical-source-attribution",
  "native-direct-source-advanced-attribution",
  "native-direct-source-estimator-attribution",
  "native-direct-source-frame-attribution",
  "native-direct-source-plot-attribution",
  "native-direct-source-recovery-evidence-attribution",
  "native-direct-source-report-attribution",
  "native-direct-source-stochastic-attribution",
  "native-direct-source-workflow-attribution",
  "native-first-wave-source-interfaces",
  "native-four-pilot-external-attestation",
  "native-four-pilot-review-matrix",
  "native-independent-source-review-packet",
  "native-source-evidence-runner",
  "native-source-fixture-static-attribution"
)
runner <- "scripts/capture_native_source_qualification_evidence.R"
if(!file.exists(runner))
  stop("Required scientific runner missing",call.=FALSE)
lines <- readLines(runner,warn=FALSE)
begin <- grep("^filter<-paste\\(c\\(",lines)
finish <- which(grepl('collapse="|"',lines,fixed=TRUE))
if(length(begin)!=1L || !any(finish>begin))
  stop("Cannot verify the two-mode scientific test selection",call.=FALSE)
selection <- lines[begin:min(finish[finish>begin])]
for(name in required) {
  p <- file.path("tests","testthat",paste0("test-",name,".R"))
  if(!file.exists(p))
    stop("Required developer regression missing: ",p,call.=FALSE)
  content <- readLines(p,warn=FALSE)
  if(!any(grepl('.etr_require_developer_checkout()',content,fixed=TRUE)))
    stop("Missing explicit checkout guard for: ",p,call.=FALSE)
  if(!any(grepl(paste0('"',name,'"'),selection,fixed=TRUE)))
    stop("Required source test missing from two-mode science filter: ",
      name,call.=FALSE)
  if(name!="native-first-wave-source-interfaces") {
    n_tests <- sum(grepl("^[[:space:]]*test_that\\(",content))
    n_guards <- sum(grepl('.etr_require_developer_checkout()',content,
      fixed=TRUE))
    if(n_tests!=n_guards || n_tests<1L)
      stop("Not every source-only block has a checkout guard: ",p,
        call.=FALSE)
  }
}
helper <- "tests/testthat/helper-qualification-context.R"
if(!file.exists(helper))
  stop("Missing mandatory context helpers",call.=FALSE)
helper_text <- readLines(helper,warn=FALSE)
for(token in c("SOURCE_CHECKOUT_ONLY", "system.file(",
    "Missing required installed extdata fixture"))
  if(!any(grepl(token,helper_text,fixed=TRUE)))
    stop("Missing installed/source qualification policy: ",token,
      call.=FALSE)
cat("SOURCE_CHECKOUT_TEST_COVERAGE_PASS=",length(required),
  " required regression files retained in two-mode scientific qualification;",
  " installed-only skips explicit; no certification approval\n",sep="")
