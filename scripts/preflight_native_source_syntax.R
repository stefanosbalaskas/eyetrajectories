# Fail before package loading if any checked-in R source, test or runner
# contains a syntactic parse error. Base R only; no Python or pkgload needed.
if(!file.exists("DESCRIPTION")||!dir.exists("R")||
   !dir.exists(file.path("tests","testthat"))){
  stop("Run the native R syntax preflight from the package root.",
    call.=FALSE)
}
syntax_paths<-unlist(lapply(c("R",file.path("tests","testthat"),
    "scripts"),function(folder){
  if(!dir.exists(folder))return(character())
  list.files(folder,pattern="\\.[rR]$",recursive=TRUE,
    full.names=TRUE)
}),use.names=FALSE)
syntax_paths<-sort(unique(syntax_paths))
if(!length(syntax_paths))stop(
  "No R files discovered for native syntax preflight",call.=FALSE)
parse_failures<-character()
for(syntax_path in syntax_paths){
  error<-tryCatch({
    parse(file=syntax_path,keep.source=FALSE)
    NULL
  },error=function(e)conditionMessage(e))
  if(!is.null(error))parse_failures<-c(parse_failures,
    paste0(syntax_path,": ",error))
}
if(length(parse_failures)){
  stop("Native source syntax preflight failed (",
    length(parse_failures)," of ",length(syntax_paths),
    " R files):\n",paste(parse_failures,collapse="\n"),
    call.=FALSE)
}
message("Native R syntax preflight PASS: ",length(syntax_paths),
  " files parsed before package loading.")
