# R + frozen Python direct-source replay of changed six-domain TEST evidence.
#
# Run from repo root in a FRESH RStudio R session:
#   source("scripts/verify_qualification_managed_python_20261113.R")
#   source("scripts/replay_review_changed_tests_20261114.R")
#
# Reads the latest existing review_integrity_*.csv, chooses ONLY test-*.R
# with stale pinned hashes, checks each canonical HEAD test file against
# the audit, then runs all their testthat suites with Python 1.2 enabled.
# A PASS demonstrates test execution, not six-domain current author review,
# not unchanged original source evidence, and not independent certification.
#
.etr_replay_review_changed_tests <- function() {
  if(!file.exists("DESCRIPTION")||!dir.exists("tests/testthat"))
    stop("Run from the EyeTrajectories repository root",call.=FALSE)
  for(pkg in c("digest","pkgload","testthat","reticulate"))
    if(!requireNamespace(pkg,quietly=TRUE))
      stop("Missing required replay package: ",pkg,call.=FALSE)
  folder<-file.path("artifacts","review_sha256_checkout_audit")
  path<-Sys.getenv("ET_REVIEW_AUDIT_REPORT","")
  if(!nzchar(path)){
    matches<-list.files(folder,pattern="^review_integrity_.*\\.csv$",
                        full.names=TRUE)
    if(!length(matches))stop("No SHA256 review audit in ",folder,call.=FALSE)
    path<-matches[[which.max(file.info(matches)$mtime)]]
  }
  audit<-utils::read.csv(path,stringsAsFactors=FALSE,
    check.names=FALSE,na.strings=c("","NA"))
  needed<-c("python_name","path","verdict","git_head_blob_sha256")
  if(!all(needed%in%names(audit)))
    stop("Missing SHA256 audit columns",call.=FALSE)
  bad<-audit[audit$verdict=="FAIL_PIN_MISMATCH"&
    startsWith(audit$path,"tests/testthat/test-"),,drop=FALSE]
  files<-sort(unique(bad$path))
  if(!length(files))
    stop("No changed test evidence in selected SHA256 audit",call.=FALSE)
  if(!all(file.exists(files)))
    stop("Missing current test evidence: ",
      paste(files[!file.exists(files)],collapse=", "),call.=FALSE)
  if(any(!grepl("^tests/testthat/test-[A-Za-z0-9_-]+\\.R$",files)))
    stop("Test evidence path outside safe testthat selector",call.=FALSE)
  git<-Sys.which("git")
  if(!nzchar(git))stop("Git is required to bind replay to audited HEAD",call.=FALSE)
  # One audited canonical digest per path. Repeated references across six
  # domains and contracts must agree about the actual current Git blob.
  for(f in files){
    expected<-unique(bad$git_head_blob_sha256[bad$path==f])
    if(length(expected)!=1L || is.na(expected) ||
       !grepl("^[0-9a-f]{64}$",expected))
      stop("Conflicting current Git evidence digests: ",f,call.=FALSE)
    temp<-tempfile("et_review_replay_")
    tryCatch({
      rc<-suppressWarnings(system2(git,c("show",
        shQuote(paste0("HEAD:",f))),stdout=temp,stderr=FALSE))
      if(!identical(as.integer(rc),0L)||!file.exists(temp))
        stop("Git HEAD test source is unavailable: ",f,call.=FALSE)
      current<-unname(digest::digest(temp,algo="sha256",file=TRUE))
      if(!identical(current,expected))
        stop("Audit was generated against a different HEAD: ",f,
          "; rerun source integrity audit before replay",call.=FALSE)
    },finally=unlink(temp))
  }
  cat("STALE_REVIEW_CHANGED_TEST_FILES=",length(files),"\n",sep="")
  cat("STALE_REVIEW_AFFECTED_CONTRACTS=",
    length(unique(bad$python_name)),"\n",sep="")
  cat("STALE_REVIEW_COVERAGE=SIX_DOMAIN_TEST_EXECUTION_ONLY; ",
    "independent_certification=FALSE\n",sep="")
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    Sys.setenv(ET_RUN_PYTHON_TESTS="true")
  if(!nzchar(Sys.getenv("RETICULATE_PYTHON")))
    stop("Select managed pinned Python before running this script",call.=FALSE)
  pkgload::load_all(".",quiet=TRUE)
  version<-tryCatch(et_python_version(),error=function(e)
    stop("Pinned Python 1.2 unavailable: ",conditionMessage(e),call.=FALSE))
  if(!identical(version,"1.2.0"))
    stop("Expected frozen eyetrajectoriespy==1.2.0, found: ",
      version,call.=FALSE)
  names<-sub("^test-","",sub("\\.R$","",basename(files)))
  cat("STALE_REVIEW_FROZEN_PYTHON_VERSION=",version,"\n",sep="")
  testthat::test_local(".",filter=paste(names,collapse="|"),
    reporter="progress",stop_on_failure=TRUE,stop_on_warning=TRUE)
  cat("STALE_REVIEW_TEST_EXECUTION_PASS; FULL_DOMAIN_SOURCE_REVIEW=PENDING; ",
      "CERTIFICATION=FALSE\n",sep="")
  invisible(files)
}
.etr_replay_review_changed_tests()
