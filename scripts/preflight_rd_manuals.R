#!/usr/bin/env Rscript
# Fast read-only preflight for ALL hand-written Rd manuals.
# Catch doubled command escapes and malformed Rd before costly R CMD build.
# Call from package root: source("scripts/preflight_rd_manuals.R")
if(!file.exists("DESCRIPTION")||!dir.exists("man"))
  stop("Rd preflight must run from the source package root",call.=FALSE)
files<-sort(list.files("man",pattern="\\.Rd$",full.names=TRUE))
if(!length(files))
  stop("Rd preflight: no man/*.Rd manuals found",call.=FALSE)
issues<-character()
for(file in files){
  lines<-trimws(readLines(file,warn=FALSE,encoding="UTF-8"))
  key<-function(name)paste0("\\",name,"{")
  escaped<-function(name)paste0("\\\\",name,"{")
  if(sum(startsWith(lines,key("name")))!=1L)
    issues<-c(issues,paste(file,": expected one \\name{ section"))
  if(sum(startsWith(lines,key("title")))!=1L)
    issues<-c(issues,paste(file,": expected one \\title{ section"))
  double_directives<-c("name","alias","title","usage","value",
    "description","details","arguments","examples")
  wrong<-double_directives[vapply(double_directives,
    function(x)any(startsWith(lines,escaped(x))),logical(1L))]
  if(length(wrong))issues<-c(issues,
    paste(file,": doubled backslash on",paste(wrong,collapse=", ")))
  parse_errors<-tryCatch({
    tools::parse_Rd(file,encoding="UTF-8")
    character()
  },error=function(e)conditionMessage(e))
  if(length(parse_errors))issues<-c(issues,
    paste(file,":",paste(parse_errors,collapse="; ")))
}
if(length(issues)){
  cat("RD_MANUAL_PREFLIGHT_FAIL count=",length(issues),"\n",sep="")
  cat(paste(issues,collapse="\n"),"\n")
  stop("Rd preflight failed: repair malformed man/*.Rd source",call.=FALSE)
}
cat("RD_MANUAL_PREFLIGHT_PASS=",length(files),
  " files successfully parsed and validated\n",sep="")
invisible(TRUE)
