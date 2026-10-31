# Static, noncertifying source-fixture inventory.
# Parse token metadata instead of recursively traversing R language calls:
# matrix slices (x[, 1]), empty arguments and function formals contain
# R_MissingArg nodes, which break naive for(item in as.list(call)) walkers.
# No R test is executed and no Python interpreter is initialized.
etr_source_fixture_static_inventory<-function(path){
  if(!file.exists(path))stop("Missing source fixture: ",path,call.=FALSE)
  parsed<-parse(file=path,keep.source=TRUE)
  tokens<-utils::getParseData(parsed,includeText=TRUE)
  if(is.null(tokens)||!all(c("token","text")%in%names(tokens)))
    stop("Source fixture parse tokens unavailable: ",path,call.=FALSE)
  n_cases<-sum(tokens$token=="SYMBOL_FUNCTION_CALL"&
    tokens$text=="test_that",na.rm=TRUE)
  # Work from deparsed, comment-free valid source so whitespace/newlines
  # cannot hide literal references. A textual signature remains only
  # STATIC file-level evidence; it is never recorded as a test outcome.
  rendered<-paste(deparse(parsed,width.cutoff=500L),collapse="\n")
  # R deparse() canonicalizes a literal string argument to double quotes.
  literal_pattern<-
    'etpy_get_export[[:space:]]*\\\\([[:space:]]*"([A-Za-z_][A-Za-z0-9_]*)"'
  hits<-regmatches(rendered,gregexpr(
    literal_pattern,rendered,perl=TRUE))[[1L]]
  literals<-unique(sub(literal_pattern,"\\1",hits,perl=TRUE))
  list(cases=as.integer(n_cases),export_literals=literals)
}
