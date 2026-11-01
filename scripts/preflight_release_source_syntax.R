#!/usr/bin/env Rscript
# Fast RELEASE preflight: parse source, test and runner R files before starting
# long R CMD check or pinned-Python qualification. Syntax-only; NEVER reports
# scientific/CRAN/reviewer approval.
if (!file.exists("DESCRIPTION") || !dir.exists("R") ||
    !dir.exists("tests/testthat") || !dir.exists("scripts"))
  stop("Run release source syntax preflight from package root",call.=FALSE)
dirs<-c("R","tests/testthat","scripts")
files<-sort(unique(unlist(lapply(dirs,function(d)
  list.files(d,pattern="\\.R$",recursive=TRUE,full.names=TRUE)))))
if(!length(files))
  stop("Release syntax preflight: no source R files found",call.=FALSE)
issues<-character()
for(file in files) {
  err<-tryCatch({
    parse(file,encoding="UTF-8")
    NULL
  },error=function(e)conditionMessage(e))
  if(!is.null(err))
    issues<-c(issues,paste0(file,": ",err))
}
if(length(issues)){
  cat("RELEASE_R_SYNTAX_PREFLIGHT_FAIL=",length(issues),"\n",sep="")
  cat(paste(issues,collapse="\n"),"\n")
  stop("Release R source syntax preflight failed before package build",
    call.=FALSE)
}
cat("RELEASE_R_SYNTAX_PREFLIGHT_PASS=",length(files),
  " R files parsed before long-running qualification\n",sep="")
invisible(TRUE)
