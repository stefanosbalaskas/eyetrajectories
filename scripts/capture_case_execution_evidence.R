# Exact-head, first-party testthat case execution census.
# This records actual test_that case results, not per-contract source parity.
# A literal Python export reference in a test case does not prove the
# referenced call executed; conditional paths and opt-in oracle skips exist.

.etr_source_literals_in_case <- function(expr) {
  x<-paste(deparse(expr,width.cutoff=500L),collapse="\n")
  pattern<-'etpy_get_export[[:space:]]*\\([[:space:]]*"([A-Za-z_][A-Za-z0-9_]*)"'
  hits<-regmatches(x,gregexpr(pattern,x,perl=TRUE))[[1L]]
  if(!length(hits))return(character())
  unique(sub(pattern,"\\1",hits,perl=TRUE))
}

.etr_test_case_literal_map <- function(path) {
  expressions<-parse(file=path,keep.source=FALSE)
  out<-list()
  for(expr in expressions) {
    if(!is.call(expr)||length(expr)<3L)next
    name<-expr[[1L]]
    if(!is.symbol(name)||!identical(as.character(name),"test_that"))next
    description<-expr[[2L]]
    if(!is.character(description)||length(description)!=1L||
        is.na(description))next
    literals<-.etr_source_literals_in_case(expr[[3L]])
    out[[as.character(description)]]<-literals
  }
  out
}

etr_capture_case_execution_evidence<-function(results,mode,head,
    output_dir,root=".") {
  check<-function(ok,what)if(!isTRUE(ok))stop(what,call.=FALSE)
  check(identical(mode,"native_r_offline")||
        identical(mode,"python_1_2_direct_source"),
    "Unknown case execution mode")
  check(is.character(head)&&length(head)==1L&&
      grepl("^[a-f0-9]{40}$",head),
    "Case execution must use exact 40-hex R source pin")
  check(inherits(results,"testthat_results"),
    "testthat must return structured per-case results")
  df<-as.data.frame(results)
  required<-c("file","test","passed","failed","skipped",
    "error","warning")
  check(nrow(df)>0L&&all(required%in%names(df)),
    "No structured testthat case results or required fields")
  check(all(!is.na(df$file))&&
      all(!is.na(df$passed))&&
      all(!is.na(df$failed))&&
      all(!is.na(df$skipped))&&
      all(!is.na(df$error))&&
      all(!is.na(df$warning)),
    "Missing required testthat case status")
  check(all(df$passed>=0L)&&all(df$failed>=0L)&&
      all(df$warning>=0L),
    "Negative testthat result counts")
  files<-basename(as.character(df$file))
  check(all(grepl("^test-[A-Za-z0-9_-]+\\.R$",files)),
    "testthat results contain unexpected source file identifiers")
  mapping<-new.env(parent=emptyenv())
  get_map<-function(file) {
    if(!exists(file,envir=mapping,inherits=FALSE)){
      full<-file.path(root,"tests","testthat",file)
      check(file.exists(full),"Executed test file missing from checkout")
      assign(file,.etr_test_case_literal_map(full),envir=mapping)
    }
    get(file,envir=mapping,inherits=FALSE)
  }
  cases<-data.frame(
    recorded_r_git_head=rep(head,nrow(df)),
    frozen_python_commit=rep(
      "c1cd95ad718327550f7e55393ff38582872f7a94",nrow(df)),
    mode=rep(mode,nrow(df)),
    file=files,
    test=as.character(df$test),
    passed_expectations=as.integer(df$passed),
    failed_expectations=as.integer(df$failed),
    warning_count=as.integer(df$warning),
    skipped=as.logical(df$skipped),
    error=as.logical(df$error),
    stringsAsFactors=FALSE)
  cases$case_executed_without_skip<-
    !is.na(cases$test)&cases$passed_expectations>0L&
    cases$failed_expectations==0L&cases$warning_count==0L&
    !cases$skipped&!cases$error
  literals<-lapply(seq_len(nrow(cases)),function(i) {
    if(is.na(cases$test[i]))return(character())
    m<-get_map(cases$file[i])
    value<-m[[cases$test[i]]]
    if(is.null(value))character() else value
  })
  cases$static_source_literal_count<-as.integer(lengths(literals))
  cases$static_source_literals<-vapply(literals,paste,collapse=";",
    FUN.VALUE=character(1L))
  check(!any(cases$failed_expectations>0L|cases$error|
       cases$warning_count>0L),
    "Case census cannot report a PASS with failed/error/warning cases")
  path<-file.path(output_dir,paste0(mode,"_executed_test_cases.csv"))
  utils::write.csv(cases,path,row.names=FALSE,na="")
  check(file.exists(path),"Testthat case execution census not written")
  message("Per-test-case developer evidence captured: ",nrow(cases),
    " case rows for ",mode,"; ",
    sum(cases$case_executed_without_skip),
    " completed without skip; ",
    sum(cases$case_executed_without_skip&
      cases$static_source_literal_count>0L),
    " completed cases have STATIC Python export literals (not proof of",
    " executing those particular calls). Evidence: ",path)
  invisible(list(path=path,cases=cases))
}
