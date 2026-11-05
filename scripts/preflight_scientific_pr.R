#!/usr/bin/env Rscript
# Source-only fast PR gate. Fail on R syntax, missing scientific suite
# selection, and newly edited reticulate py_call argument collisions.
# No Python, pkgload, network, CRAN or independent reviewer approval.
.etr_fast_pycall_x_sites <- function(expr) {
  hits <- 0L
  walk <- function(node) {
    if (is.call(node)) {
      head <- paste(deparse(node[[1L]]),collapse="")
      if (head %in% c("reticulate::py_call","py_call")) {
        argnames <- names(as.list(node))
        if (!is.null(argnames) &&
            "x" %in% argnames[-1L]) hits <<- hits + 1L
      }
      # Empty arguments (e.g. x[, 1L]) are R_MissingArg objects.
      # Binding one to a for-loop variable and evaluating it errors.
      # Inspect directly by indexed call access before descending.
      if (length(node) > 1L) {
        for (i in seq_along(node)[-1L]) {
          if (!identical(node[[i]], quote(expr = )))
            walk(node[[i]])
        }
      }
    } else if (is.expression(node) || is.list(node)) {
      for (i in seq_along(node)) {
        if (!identical(node[[i]], quote(expr = )))
          walk(node[[i]])
      }
    }
  }
  walk(expr)
  hits
}

.etr_fast_complex_setter_sites <- function(lines) {
  # Re()/Im() are accessors, not R replacement functions. Keep this
  # deliberately narrow; assignment to a variable named Im is allowed.
  # Strip quoted test fixtures so a literal example such as
  # "Im(y) <- 0" does not count as an executed replacement assignment.
  clean <- gsub("\"[^\"]*\"|'[^']*'","",lines,perl=TRUE)
  clean <- sub("#.*$","",clean)
  which(grepl(
    "(^|[^[:alnum:]_.])(Im|Re)[[:space:]]*\\([^\\n]*\\)[[:space:]]*<-",
    clean,perl=TRUE))
}

.etr_fast_scientific_pr_preflight <- function() {
  if (!file.exists("DESCRIPTION") ||
      !file.exists("scripts/capture_native_source_qualification_evidence.R") ||
      !dir.exists("tests/testthat"))
    stop("Run scientific PR preflight from the repository root",call.=FALSE)

  # This preexisting R-only gate catches syntax errors before expensive
  # reticulate loading, Python or scientific model execution.
  source("scripts/preflight_native_source_syntax.R",local=TRUE)

  runner <- "scripts/capture_native_source_qualification_evidence.R"
  expressions <- parse(file=runner,keep.source=FALSE)
  rhs <- function(symbol) {
    indices <- which(vapply(expressions,function(expr)
      is.call(expr) && identical(expr[[1L]],as.name("<-")) &&
      identical(expr[[2L]],as.name(symbol)),logical(1L)))
    if(length(indices)!=1L)
      stop("Scientific runner must define exactly one top-level ",
        symbol," assignment",call.=FALSE)
    expressions[[indices[[1L]]]][[3L]]
  }
  required <- eval(rhs("required_scientific_tests"),envir=baseenv())
  selector <- eval(rhs("filter"),envir=baseenv())
  if(!is.character(required) || !length(required) ||
     anyDuplicated(required) || !all(file.exists(required)))
    stop("Scientific runner has missing or duplicate required tests",
      call.=FALSE)
  if(!is.character(selector)||length(selector)!=1L||
     is.na(selector)||!nzchar(selector))
    stop("Scientific runner selection regex is invalid",call.=FALSE)
  missing <- required[!grepl(selector,basename(required))]
  if(length(missing))
    stop("Scientific runner filter does not select: ",
      paste(missing,collapse=", "),call.=FALSE)

  # Use merge-base on a feature branch, so unchanged legacy source is
  # not retrospectively blocked by newly introduced static lint rules.
  # ET_SCIENTIFIC_PREFLIGHT_FILES can explicitly select changed files.
  explicit <- Sys.getenv("ET_SCIENTIFIC_PREFLIGHT_FILES",unset="")
  changed <- character()
  if(nzchar(explicit)) {
    # Use semicolons so Windows paths keep their backslashes intact.
    changed <- unlist(strsplit(explicit,";",fixed=TRUE),use.names=FALSE)
  } else {
    git <- Sys.which("git")
    base <- Sys.getenv("ET_SCIENTIFIC_PREFLIGHT_BASE_REF",
      unset="origin/research/native-generalized-fosr-prediction-20261030")
    if(nzchar(git)) {
      changed_try <- suppressWarnings(tryCatch(system2(git,
        c("diff","--name-only","--diff-filter=ACMR",
          paste0(base,"...HEAD")),stdout=TRUE,stderr=FALSE),
        error=function(e)structure(character(),status=1L)))
      status <- attr(changed_try,"status")
      if(is.null(status) || identical(as.integer(status),0L))
        changed <- as.character(changed_try)
    }
  }
  changed <- unique(trimws(changed))
  changed <- changed[nzchar(changed)&grepl("\\.[Rr]$",changed)&
    file.exists(changed)]
  unsafe <- character()
  for(path in changed) {
    parsed <- parse(file=path,keep.source=FALSE)
    n <- .etr_fast_pycall_x_sites(parsed)
    if(n>0L) unsafe <- c(unsafe,paste0(path,
      ": reticulate::py_call(..., x=...) shadows callable (",n,")"))
    at <- .etr_fast_complex_setter_sites(readLines(path,warn=FALSE))
    if(length(at)) unsafe <- c(unsafe,paste0(path,
      ": nonexistent Re()/Im() replacement assignment at lines ",
      paste(at,collapse=",")))
  }
  if(length(unsafe))
    stop("Scientific PR input/call preflight failed:\n",
      paste(unsafe,collapse="\n"),call.=FALSE)
  cat("SCIENTIFIC_PR_FAST_PREFLIGHT_PASS=required_",
    length(required),"_changed_R_",length(changed),
    " no erroneous py_call(x=) or complex setters; ",
    "no scientific certification\n",sep="")
  invisible(TRUE)
}

if(!identical(Sys.getenv("ET_SCIENTIFIC_PREFLIGHT_DEFINITIONS_ONLY"),
              "true")) .etr_fast_scientific_pr_preflight()
