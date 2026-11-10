# Native, Python-free workflow audit tables. Frozen source: eyetrajectoriespy
# 1.2.0, src/eyetrajectoriespy/workflows/_core.py at c1cd95ad718327550f7e55393ff38582872f7a94.
# Cross-language dataclass, pandas and JSON serialization differences remain
# EXPLICIT source-contract gaps; no complete source equivalence is asserted.

.etr_workflow_json <- function(value, path="value", empty_mapping=FALSE,
    validate_only=FALSE) {
  check <- function(x, p) {
    if (is.null(x)) return(invisible(TRUE))
    if (is.data.frame(x) || is.factor(x) || is.complex(x))
      stop(p, " is not a supported workflow JSON value", call.=FALSE)
    if (is.array(x) && !is.numeric(x) && !is.logical(x))
      stop(p, " must be a numeric or logical array", call.=FALSE)
    if (is.atomic(x)) {
      if (!is.numeric(x) && !is.character(x) && !is.logical(x))
        stop(p, " has unsupported atomic type", call.=FALSE)
      if (anyNA(x) || (is.numeric(x) && any(!is.finite(x))))
        stop(p, " contains nonfinite or missing values", call.=FALSE)
      return(invisible(TRUE))
    }
    if (!is.list(x))
      stop(p, " is not a supported workflow JSON value", call.=FALSE)
    nm <- names(x)
    if (!is.null(nm) && (anyNA(nm) || anyDuplicated(nm)))
      stop(p, " has invalid mapping keys", call.=FALSE)
    for (i in seq_along(x))
      check(x[[i]], paste0(p,".",if(is.null(nm))i else nm[[i]]))
    invisible(TRUE)
  }
  check(value,path)
  if (validate_only) return(invisible(TRUE))
  if (empty_mapping && is.list(value) && !length(value)) return("{}")
  if (!requireNamespace("jsonlite",quietly=TRUE))
    stop("jsonlite is required to serialize workflow JSON",call.=FALSE)
  # Frozen Python workflows/_core.py calls json.dumps(sort_keys=True),
  # including nested mappings. Preserve sequence order but lexically sort
  # every mapping, while retaining the documented class/float-type gaps.
  source_sorted <- function(x) {
    if (!is.list(x)) return(x)
    nm <- names(x)
    if (!is.null(nm)) x <- x[order(nm,method="radix")]
    lapply(x,source_sorted)
  }
  .etr_python_json_encode(source_sorted(value),compact=TRUE,
    empty_mapping=empty_mapping)
}

.etr_workflow_validate_steps <- function(steps) {
  .etr_assert(is.list(steps),"steps must be a list")
  for (step in steps) {
    .etr_assert(is.list(step) &&
      is.character(step$name) && length(step$name)==1L &&
      !is.na(step$name) && nzchar(step$name) &&
      is.character(step[["function"]]) && length(step[["function"]])==1L &&
      !is.na(step[["function"]]) && nzchar(step[["function"]]) &&
      is.character(step$status) && length(step$status)==1L &&
      !is.na(step$status) && step$status %in%
        c("completed","failed","skipped") &&
      is.list(step$parameters) &&
      is.numeric(step$elapsed_seconds) &&
      length(step$elapsed_seconds)==1L &&
      !is.na(step$elapsed_seconds) &&
      is.finite(step$elapsed_seconds) && step$elapsed_seconds>=0 &&
      (is.null(step$warnings) ||
        (is.character(step$warnings) && !anyNA(step$warnings))),
      "each step requires a name, function, status, parameters, time and warnings")
    .etr_workflow_named_fields(step$parameters,"step.parameters")
  }
  invisible(TRUE)
}

.etr_workflow_validate_decisions <- function(decisions) {
  .etr_assert(is.list(decisions) &&
    (length(decisions)==0L ||
       (!is.null(names(decisions)) && !anyNA(names(decisions)) &&
        !anyDuplicated(names(decisions)))),
    "decisions must be a uniquely named list")
  for (rec in decisions) {
    .etr_assert(is.list(rec) && "value" %in% names(rec) &&
      is.character(rec$source) && length(rec$source)==1L &&
      !is.na(rec$source) && rec$source %in%
        c("analyst","audited_selector","workflow_contract","derived") &&
      (is.null(rec$criterion) ||
        (is.character(rec$criterion) && length(rec$criterion)==1L &&
         !is.na(rec$criterion))) &&
      (rec$source!="audited_selector" ||
        (!is.null(rec$criterion) && nzchar(rec$criterion))),
      "decision requires a value, accepted source and selector criterion")
    .etr_workflow_json(rec$value,"decision.value",validate_only=TRUE)
  }
  invisible(TRUE)
}

#' Auditable workflow steps without a Python runtime
#' @param steps Ordered list of step records with the source fields.
#' @return Source-column-ordered data frame. Python dataclass and pandas
#'   class identity is NOT claimed; see the unresolved source gap register.
#' @export
etr_workflow_steps_frame <- function(steps) {
  .etr_workflow_validate_steps(steps)
  empty <- data.frame(order=integer(),name=character(),
    function_name=character(),status=character(),
    elapsed_seconds=numeric(),parameters_json=character(),
    warning_count=integer(),warnings=character(),
    stringsAsFactors=FALSE)
  names(empty)[3L] <- "function"
  if (!length(steps)) return(empty)
  rows <- lapply(seq_along(steps),function(i) {
    s <- steps[[i]]
    w <- if(is.null(s$warnings)) character() else s$warnings
    data.frame(order=as.integer(i),name=s$name,
      function_name=s[["function"]],status=s$status,
      elapsed_seconds=as.numeric(s$elapsed_seconds),
      parameters_json=.etr_workflow_json(s$parameters,
        "step.parameters",empty_mapping=TRUE),
      warning_count=as.integer(length(w)),warnings=paste(w,collapse="\n"),
      stringsAsFactors=FALSE,check.names=FALSE)
  })
  out <- do.call(rbind,rows)
  names(out)[3L] <- "function"
  rownames(out) <- NULL
  out
}

#' Auditable workflow decisions without a Python runtime
#' @param decisions Named list of source-aligned decision records.
#' @return Source-column-ordered data frame; JSON formatting differences
#'   and class boundaries remain explicitly uncertified.
#' @export
etr_workflow_decisions_frame <- function(decisions) {
  .etr_workflow_validate_decisions(decisions)
  empty <- data.frame(name=character(),value_json=character(),
    source=character(),criterion=character(),
    stringsAsFactors=FALSE)
  if (!length(decisions)) return(empty)
  rows <- lapply(seq_along(decisions),function(i) {
    d <- decisions[[i]]
    data.frame(name=names(decisions)[[i]],
      value_json=.etr_workflow_json(d$value,"decision.value"),
      source=d$source,
      criterion=if(is.null(d$criterion)) NA_character_ else d$criterion,
      stringsAsFactors=FALSE)
  })
  out <- do.call(rbind,rows)
  rownames(out) <- NULL
  out
}

#' Build a native workflow audit record without executing any estimator
#' @param workflow_contract Nonempty scientific workflow identifier.
#' @param steps Ordered workflow step records.
#' @param decisions Named scientific decision records.
#' @param config Analyst-declared configuration (native list).
#' @param provenance Source and scientific provenance (native list).
#' @return Native S3 audit record; not a published Python result dataclass.
#' @export
etr_workflow_audit_result <- function(workflow_contract,steps=list(),
    decisions=list(),config=list(),provenance=list()) {
  .etr_assert(is.character(workflow_contract) &&
    length(workflow_contract)==1L && !is.na(workflow_contract) &&
    nzchar(workflow_contract), "workflow_contract must be nonempty")
  .etr_assert(is.list(config) && is.list(provenance),
    "config and provenance must be native JSON-compatible lists")
  .etr_workflow_validate_steps(steps)
  .etr_workflow_validate_decisions(decisions)
  .etr_workflow_json(config,"config",empty_mapping=TRUE,
    validate_only=TRUE)
  .etr_workflow_json(provenance,"provenance",empty_mapping=TRUE,
    validate_only=TRUE)
  structure(list(workflow_schema_version=1L,
    workflow_contract=workflow_contract,config=config,steps=steps,
    decisions=decisions,provenance=provenance),
    class="etr_workflow_audit_result")
}

.etr_workflow_check_result <- function(result) {
  .etr_assert(inherits(result,"etr_workflow_audit_result") &&
    identical(result$workflow_schema_version,1L),
    "result must have the native workflow audit schema version 1")
  .etr_assert(is.character(result$workflow_contract) &&
    length(result$workflow_contract)==1L &&
    !is.na(result$workflow_contract) &&
    nzchar(result$workflow_contract),"workflow_contract must be nonempty")
  .etr_workflow_validate_steps(result$steps)
  .etr_workflow_validate_decisions(result$decisions)
  .etr_assert(is.list(result$config)&&is.list(result$provenance),
    "result config and provenance must be native JSON-compatible lists")
  .etr_workflow_json(result$config,"config",empty_mapping=TRUE,validate_only=TRUE)
  .etr_workflow_json(result$provenance,"provenance",empty_mapping=TRUE,
    validate_only=TRUE)
  invisible(TRUE)
}

#' One-row audit summary for a native workflow result
#' @param result Native workflow audit record.
#' @return Data frame with published Python 1.2 source column order.
#' @export
etr_workflow_summary_frame <- function(result) {
  .etr_workflow_check_result(result)
  statuses <- vapply(result$steps,function(s)s$status,character(1L))
  sources <- vapply(result$decisions,function(d)d$source,character(1L))
  data.frame(
    workflow_schema_version=1L,
    workflow_contract=result$workflow_contract,
    step_count=length(result$steps),
    completed_steps=sum(statuses=="completed"),
    failed_steps=sum(statuses=="failed"),
    skipped_steps=sum(statuses=="skipped"),
    warning_count=sum(vapply(result$steps,function(s)
      if(is.null(s$warnings)) 0L else length(s$warnings),integer(1L))),
    decision_count=length(result$decisions),
    analyst_decisions=sum(sources=="analyst"),
    audited_selector_decisions=sum(sources=="audited_selector"),
    workflow_contract_decisions=sum(sources=="workflow_contract"),
    derived_decisions=sum(sources=="derived"),
    stringsAsFactors=FALSE)
}

# CPython repr escapes Other and Separator categories except ASCII space.
# PCRE and CPython may use different Unicode data for recent code points.
.etr_python_workflow_identifier_repr <- function(x) {
  .etr_assert(is.character(x)&&length(x)==1L&&!is.na(x),
    "workflow identifier must be one string")
  quote <- if(grepl("'",x,fixed=TRUE)&&!grepl('"',x,fixed=TRUE)) '"' else "'"
  points <- utf8ToInt(enc2utf8(x))
  characters <- intToUtf8(points,multiple=TRUE)
  escape <- (points != 32L) & grepl("[\\p{C}\\p{Z}]",characters,perl=TRUE)
  chars <- vapply(seq_along(points),function(i){
    p <- points[[i]]
    if(p==92L) return("\\\\")
    if(p==utf8ToInt(quote)) return(paste0("\\",quote))
    if(p==10L) return("\\n")
    if(p==13L) return("\\r")
    if(p==9L) return("\\t")
    if(!escape[[i]]) return(characters[[i]])
    if(p<=0xffL) return(sprintf("\\x%02x",p))
    if(p<=0xffffL) return(sprintf("\\u%04x",p))
    sprintf("\\U%08x",p)
  },character(1L),USE.NAMES=FALSE)
  paste0(quote,paste(chars,collapse=""),quote)
}

#' Compact native workflow provenance reporting text
#' @param result Native workflow audit record.
#' @return Descriptive text without automated scientific approval.
#' @export
etr_workflow_reporting_text <- function(result) {
  z <- etr_workflow_summary_frame(result)
  quoted <- .etr_python_workflow_identifier_repr(result$workflow_contract)
  paste0("Workflow ",quoted," used schema ",
    z$workflow_schema_version," and retained ",z$step_count,
    " ordered steps (",z$completed_steps," completed, ",z$failed_steps,
    " failed, ",z$skipped_steps," skipped). It retained ",
    z$decision_count," scientific decisions (",z$analyst_decisions,
    " analyst-declared and ",z$audited_selector_decisions,
    " from audited selectors). Workflow orchestration does not itself ",
    "authorize hidden preprocessing, diagnostic expansion, or automatic ",
    "scientific model selection.")
}

#' Source-contract review queue across every frozen Python 1.2 public export
#' @return 508-row fail-closed review register, including class/constant rows.
#' @export
etr_native_source_contract_review_queue <- function() {
  z <- etr_native_parity_catalog()
  next_action <- ifelse(!z$is_python_function,
    "review native class/constant schema and representation",
    ifelse(!z$named_native_candidate,
      "implement native R callable and its full source contract",
      ifelse(!z$native_implementation_started,
        "implement mapped native candidate before qualification",
        ifelse(z$source_contract_gap_unresolved,
          "resolve source discrepancy; compare numeric, type, error, boundary and obtain independent signoff",
          ifelse(z$one_to_one_native_contract_complete,
            "independently certified",
            "complete numeric, schema, scientific and independent review")))))
  data.frame(namespace=z$namespace,python_name=z$python_name,
    kind=z$kind,native_r_candidate=z$native_r_candidate,
    mapped=z$named_native_candidate,
    native_implementation_started=z$native_implementation_started,
    source_sha=z$source_git_sha,
    source_gap_unresolved=z$source_contract_gap_unresolved,
    source_gap_kind=z$source_contract_gap_kind,
    targeted_numerical_fixture_pass=z$contract_numerical_fixture_pass,
    full_numeric_approved=z$independent_numeric_parity_pass,
    schema_boundary_approved=z$behavioral_schema_parity_pass,
    scientific_scope_approved=z$scientific_inference_qualified,
    independent_reviewer_approved=z$independent_contract_review_pass,
    evidence_state=z$contract_certification_evidence_state,
    fully_certified=z$one_to_one_native_contract_complete,
    next_action=next_action,stringsAsFactors=FALSE)
}
