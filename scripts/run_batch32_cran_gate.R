# CRAN-style check of a CLEAN, COMMITTED Git HEAD source snapshot.
# Run AFTER committing the Batch 32 files, from the package root.
# This does NOT change the working tree, push, publish, or certify parity.
.batch32_cran_gate <- function() {
  if(!file.exists("DESCRIPTION") || !file.exists("NAMESPACE"))
    stop("Run from the eyetrajectories R package root",call.=FALSE)
  if(!nzchar(Sys.which("git")))stop("git executable unavailable",call.=FALSE)
  dirty <- system2("git",c("status","--porcelain","--untracked-files=no"),
    stdout=TRUE,stderr=FALSE)
  if(length(dirty))stop("Tracked changes must be committed before CRAN gate")
  head <- system2("git",c("rev-parse","HEAD"),stdout=TRUE)
  work <- file.path("artifacts","batch32_cran_gate",substr(head[[1L]],1L,12L))
  dir.create(work,recursive=TRUE,showWarnings=FALSE)
  work <- normalizePath(work,winslash="/",mustWork=TRUE)
  srczip <- file.path(work,"committed-source.zip")
  status <- suppressWarnings(system2("git",
    c("archive","--format=zip","-o",shQuote(srczip),"HEAD")))
  if(status!=0L || !file.exists(srczip))
    stop("git archive failed, no CRAN check performed")
  src <- file.path(work,"checkout")
  if(dir.exists(src))unlink(src,recursive=TRUE)
  dir.create(src,recursive=TRUE)
  utils::unzip(srczip,exdir=src)
  if(!file.exists(file.path(src,"DESCRIPTION")))
    stop("Git archive does not contain DESCRIPTION")
  cmd <- file.path(R.home("bin"),
    if(.Platform$OS.type=="windows") "R.exe" else "R")
  if(!file.exists(cmd))stop("R executable unavailable")
  run <- function(args,logname) {
    log <- suppressWarnings(system2(cmd,args,stdout=TRUE,stderr=TRUE))
    exit <- attr(log,"status")
    if(is.null(exit))exit <- 0L
    writeLines(log,file.path(work,logname),useBytes=TRUE)
    list(exit=exit,log=log)
  }
  old <- getwd()
  on.exit(setwd(old),add=TRUE)
  setwd(work)
  build <- run(c("CMD","build",shQuote(src)),"R_CMD_BUILD.txt")
  if(build$exit!=0L) {
    cat("BATCH32_CRAN_BUILD_FAIL=",build$exit,"\n",sep="")
    stop("R CMD build failed: see ",file.path(work,"R_CMD_BUILD.txt"))
  }
  bundle <- list.files(work,pattern="^eyetrajectories_.*\\.tar\\.gz$",
    full.names=TRUE)
  if(length(bundle)!=1L)stop("Expected exactly one built R tarball")
  check <- run(c("CMD","check","--as-cran",shQuote(bundle)),
    "R_CMD_CHECK_AS_CRAN.txt")
  cat("BATCH32_CRAN_HEAD=",head[[1L]],"\n",sep="")
  cat("BATCH32_CRAN_BUILD_PASS=TRUE\n")
  cat("BATCH32_CRAN_CHECK_EXIT=",check$exit,"\n",sep="")
  cat("BATCH32_CRAN_LOGS=",work,"\n",sep="")
  if(check$exit!=0L)stop("R CMD check --as-cran failed; review logs")
  cat("BATCH32_CRAN_CHECK_COMMAND_PASS=TRUE; REVIEW_NOTES_AND_WARNINGS=REQUIRED\n")
  invisible(work)
}
.batch32_cran_gate()
