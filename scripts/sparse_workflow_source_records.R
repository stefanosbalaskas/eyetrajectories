# Compare source fields while allowing the additional native audit fields.
.etr_sparse_source_record_value <- function(x) {
  if (is.null(x)) return(NULL)
  if (length(dim(x)) == 1L) return(as.vector(x))
  if (is.matrix(x))
    return(lapply(seq_len(nrow(x)), function(i) x[i, ]))
  if (!is.list(x)) return(if (length(x)) x else list())
  if (!is.null(names(x))) return(lapply(x[sort(names(x))], .etr_sparse_source_record_value))
  scalar <- function(y) is.atomic(y) && length(y) == 1L
  if (length(x) && all(vapply(x, scalar, logical(1L))))
    return(unlist(x, use.names = FALSE))
  lapply(x, .etr_sparse_source_record_value)
}

.etr_sparse_source_record_equal <- function(native, source, tolerance=3e-6) {
  isTRUE(all.equal(.etr_sparse_source_record_value(native),
    .etr_sparse_source_record_value(source), tolerance=tolerance,
    check.attributes=FALSE))
}

.etr_sparse_source_error_contract <- function(native_call, source_call, record) {
  native<-tryCatch(native_call(),error=identity)
  source<-tryCatch(source_call(),error=identity)
  if(!inherits(native,"etr_sparse_native_error")||
      !inherits(source,"python.builtin.BaseException")||
      !reticulate::py_has_attr(source,"code")||
      !reticulate::py_has_attr(source,"details")){
    record("error.condition",FALSE)
    return(invisible(FALSE))
  }
  record("error.code",identical(native$code,
    et_to_r(reticulate::py_get_attr(source,"code"))))
  details<-et_to_r(reticulate::py_get_attr(source,"details"))
  record("error.detail_fields",setequal(names(native$details),names(details)))
  for(key in names(details))
    record(paste0("error.details.",key),
      .etr_sparse_source_record_equal(native$details[[key]],details[[key]]))
  invisible(TRUE)
}

.etr_compare_sparse_workflow_records <- function(native, source, record) {
  attr <- reticulate::py_get_attr
  item <- reticulate::py_get_item
  builtins <- reticulate::import_builtins(convert = FALSE)
  read <- function(object, key) et_to_r(attr(object, key))
  equal <- function(x, y)
    isTRUE(all.equal(.etr_sparse_source_record_value(x),
      .etr_sparse_source_record_value(y), check.attributes = FALSE))
  mapping <- function(native, source) {
    all(names(source) %in% names(native)) && equal(native[names(source)], source)
  }
  check <- function(field, ok) record(paste0("workflow_records.", field), isTRUE(ok))
  check("contract", equal(native$workflow_schema_version, read(source, "workflow_schema_version")) &&
    equal(if (is.null(native$source_workflow_contract)) native$workflow_contract else
      native$source_workflow_contract, read(source, "workflow_contract")))
  check("provenance", mapping(native$provenance, read(source, "provenance")))
  source_steps <- attr(source, "steps")
  count <- reticulate::py_len(source_steps)
  check("step_count", length(native$steps) == count)
  if (length(native$steps) == count) {
    for (i in seq_len(count)) {
      a <- native$steps[[i]]
      b <- item(source_steps, i - 1L)
      check(paste0("step.", i, ".identity"),
        all(vapply(c("name", "function", "status", "warnings"),
          function(key) equal(a[[key]], read(b, key)), logical(1L))))
      parameters <- et_to_r(builtins$dict(attr(b, "parameters")))
      check(paste0("step.", i, ".parameters"), mapping(a$parameters, parameters))
    }
  }
  steps_frame <- tryCatch(etr_workflow_steps_frame(native$steps), error = function(e) NULL)
  check("native_step_audit", !is.null(steps_frame) && nrow(steps_frame) == count &&
    all(vapply(native$steps, function(x) identical(x$duration_seconds, x$elapsed_seconds) &&
      isTRUE(x$duration_measured), logical(1L))))
  source_decisions <- attr(source, "decisions")
  decision_names <- names(et_to_r(source_decisions))
  for (key in decision_names) {
    a <- native$decisions[[key]]
    b <- item(source_decisions, key)
    check(paste0("decisions.", key), !is.null(a) &&
      all(vapply(c("value", "source", "criterion"),
        function(field) equal(a[[field]], read(b, field)), logical(1L))))
  }
  check("table_fields", all(names(read(source, "tables")) %in% names(native$tables)))
  check("report_fields", all(names(read(source, "reports")) %in% names(native$reports)))
}
