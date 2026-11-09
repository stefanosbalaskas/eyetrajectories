# Inspect the LAST saved clean-snapshot R CMD check without re-running it.
# source("scripts/report_latest_cran_failure.R", encoding="UTF-8")
.etr_report_latest_cran_failure<-function(root="artifacts/batch32_cran_gate"){
  if(!dir.exists(root))stop("CRAN check artifact directory is missing")
  checks<-list.dirs(root,recursive=FALSE,full.names=TRUE)
  logs<-c(file.path(checks,"eyetrajectories.Rcheck","00check.log"),
    file.path(checks,"R_CMD_CHECK_AS_CRAN.txt"))
  logs<-logs[file.exists(logs)]
  if(!length(logs))stop("No saved R CMD check log in ",root)
  log<-logs[[which.max(file.info(logs)$mtime)]]
  lines<-readLines(log,warn=FALSE,encoding="UTF-8")
  cat("LATEST_CRAN_LOG=",normalizePath(log,winslash="/"),"\n",sep="")
  # Include the final status, failing check names and nearby diagnostics;
  # omit thousands of unrelated successful checks.
  markers<-grep("(^Status:|\\.\\.\\. (ERROR|WARNING|NOTE)|^\\* (ERROR|WARNING|NOTE)|^Error( in|:)|^Warning( in|:))",
    lines,value=FALSE)
  if(!length(markers))markers<-tail(seq_along(lines),25L)
  indices<-sort(unique(unlist(lapply(markers,function(i)
    seq.int(max(1L,i-2L),min(length(lines),i+8L))))))
  for(i in indices)cat(sprintf("%5d %s\n",i,lines[[i]]))
  status<-grep("^Status:",lines,value=TRUE)
  if(length(status))cat("CRAN_STATUS=",tail(status,1L),"\n",sep="")
  if(!length(status))cat("CRAN_STATUS=NOT_RECORDED; see log above\n")
  invisible(log)
}
.etr_report_latest_cran_failure()
