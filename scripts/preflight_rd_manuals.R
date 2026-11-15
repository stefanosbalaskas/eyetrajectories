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
all_aliases<-character()
alias_files<-character()
all_names<-character()
name_files<-character()
for(file in files){
  lines<-trimws(readLines(file,warn=FALSE,encoding="UTF-8"))
  key<-function(name)paste0("\\",name,"{")
  escaped<-function(name)paste0("\\\\",name,"{")
  if(sum(startsWith(lines,key("name")))!=1L)
    issues<-c(issues,paste(file,": expected one \\name{ section"))
  name_line<-grep("^\\\\name\\{[^}]+\\}$",lines,value=TRUE)
  if(length(name_line)==1L){
    all_names<-c(all_names,sub("^\\\\name\\{([^}]+)\\}$","\\1",name_line))
    name_files<-c(name_files,file)
  }
  if(sum(startsWith(lines,key("title")))!=1L)
    issues<-c(issues,paste(file,": expected one \\title{ section"))
  alias_lines<-grep("^\\\\alias\\{[^}]+\\}$",lines,value=TRUE)
  if(length(alias_lines)){
    all_aliases<-c(all_aliases,
      sub("^\\\\alias\\{([^}]+)\\}$","\\1",alias_lines))
    alias_files<-c(alias_files,rep(file,length(alias_lines)))
  }
  usage_open<-which(startsWith(lines,key("usage")))
  if(length(usage_open)){
    for(i in usage_open){
      tail_ix<-which(lines=="}" & seq_along(lines)>i)
      if(!length(tail_ix))next
      block<-seq.int(i,tail_ix[1L])
      this_aliases<-sub("^\\\\alias\\{([^}]+)\\}$","\\1",alias_lines)
      usage_functions<-sub("\\(.*$","",
        grep("^etr_[A-Za-z0-9_]+\\(",lines[block],value=TRUE))
      missing_usage_aliases<-setdiff(usage_functions,this_aliases)
      if(length(missing_usage_aliases))issues<-c(issues,
        paste(file,": \\usage functions without \\alias:",
          paste(missing_usage_aliases,collapse=", ")))
      too_long<-block[nchar(lines[block],type="width")>90L]
      if(length(too_long))issues<-c(issues,
        paste0(file,": long \\usage lines ",
          paste(too_long,collapse=",")))
    }
  }
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
if(length(all_aliases)){
  duplicated<-unique(all_aliases[duplicated(all_aliases)])
  for(alias in duplicated){
    offenders<-unique(alias_files[all_aliases==alias])
    issues<-c(issues,paste("duplicate Rd alias",alias,"in",
      paste(offenders,collapse=", ")))
  }
}
if(length(all_names)) {
  duplicated_names<-unique(all_names[duplicated(all_names)])
  for(topic in duplicated_names)
    issues<-c(issues,paste("duplicate Rd name",topic,"in",
      paste(name_files[all_names==topic],collapse=", ")))
}
if(length(issues)){
  cat("RD_MANUAL_PREFLIGHT_FAIL count=",length(issues),"\n",sep="")
  cat(paste(issues,collapse="\n"),"\n")
  stop("Rd preflight failed: repair malformed man/*.Rd source",call.=FALSE)
}
cat("RD_MANUAL_PREFLIGHT_PASS=",length(files),
  " files successfully parsed and validated\n",sep="")
invisible(TRUE)
