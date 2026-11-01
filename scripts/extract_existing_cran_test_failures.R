#!/usr/bin/env Rscript
# Recover the complete installed-package testthat errors from an EXISTING
# R CMD check. Does not run tests, alter package code or waive any failures.
# From repository root: source("scripts/extract_existing_cran_test_failures.R")
if(!file.exists("DESCRIPTION") ||
   !identical(unname(read.dcf("DESCRIPTION","Package")[1L]),
     "eyetrajectories"))
  stop("Run from eyetrajectories repository root",call.=FALSE)
root<-normalizePath(".",winslash="/",mustWork=TRUE)
reports<-file.path(dirname(root),"eyetrajectories_cran_qualification")
if(!dir.exists(reports))
  stop("No existing CRAN qualification reports were found",call.=FALSE)
folders<-list.dirs(reports,recursive=FALSE,full.names=TRUE)
if(!length(folders))
  stop("No CRAN check reports exist",call.=FALSE)
# Prefer the most recent report that ACTUALLY contains an installed test log.
folders<-folders[order(file.info(folders)$mtime,decreasing=TRUE)]
source_log<-NULL
source_report<-NULL
for(folder in folders){
  matches<-list.files(file.path(folder,"check"),
    pattern="^testthat\\.Rout(\\.fail)?$",
    recursive=TRUE,full.names=TRUE)
  if(length(matches)){
    source_log<-matches[[1L]]
    source_report<-folder
    break
  }
}
if(is.null(source_log))
  stop("No installed-package testthat.Rout was found in existing checks",
    call.=FALSE)
lines<-readLines(source_log,warn=FALSE,encoding="UTF-8")
failure_paths<-grep("test-[A-Za-z0-9_.-]+\\.R:[0-9]+:[0-9]+",
  lines,perl=TRUE)
failure_headers<-grep("^[[:space:]]*(?:──|--|\\*\\*)",
  lines,perl=TRUE)
indices<-sort(unique(c(failure_paths,failure_headers)))
selected<-integer()
for(i in indices)selected<-c(selected,seq.int(
  max(1L,i-2L),min(length(lines),i+10L)))
if(!length(selected))selected<-seq_len(min(length(lines),100L))
selected<-sort(unique(selected))
out<-file.path(source_report,"EXISTING_INSTALLED_TEST_FAILURE_DETAILS.txt")
writeLines(c(
  paste0("Exact existing source: ",normalizePath(source_log,
    winslash="/",mustWork=TRUE)),
  paste0("Full test transcript lines: ",length(lines)),
  paste0("Candidate failure locations: ",length(indices)),
  "Unedited exact source extracts with line numbers (no tests rerun):",
  "",
  sprintf("%05d: %s",selected,lines[selected])
),out,useBytes=TRUE)
cat("EXISTING_CRAN_TEST_LOG=",normalizePath(source_log,
  winslash="/",mustWork=TRUE),"\n",sep="")
cat("EXISTING_CRAN_FAILURE_INDEX=",normalizePath(out,
  winslash="/",mustWork=TRUE),"\n",sep="")
cat("FAILURE_LOCATION_COUNT=",length(indices),"\n",sep="")
cat("The R CMD check result is unchanged; upload the index or full Rout",
  " for exact scientific/test debugging.\n")
invisible(out)
