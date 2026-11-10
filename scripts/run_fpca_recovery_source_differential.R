# Known-truth recovery and assessment outputs against frozen Python 1.2.
.etr_run_fpca_recovery_differential <- function() {
  pkgload::load_all(".", quiet = TRUE)
  stopifnot(identical(et_python_version(), "1.2.0"))
  source("tests/testthat/helper-native-recovery-modes-fixture.R", local = TRUE)
  source("scripts/sparse_workflow_source_records.R", local = TRUE)
  np <- reticulate::import("numpy", convert = FALSE)
  builtins <- reticulate::import_builtins(convert = FALSE)
  sim <- reticulate::import("eyetrajectoriespy._functional_simulation", convert = FALSE)
  reticulate::py_run_string("
from dataclasses import fields as _etr_recovery_dataclass_fields
from eyetrajectoriespy._functional_simulation import FunctionalSimulationTruth
def _etr_recovery_audit_object(cls, **fields):
    obj = object.__new__(cls)
    if cls is FunctionalSimulationTruth:
        fields = {field.name: fields.get(field.name)
                  for field in _etr_recovery_dataclass_fields(cls)}
    for key, value in fields.items():
        object.__setattr__(obj, key, value)
    return obj
")
  make <- reticulate::py_eval("_etr_recovery_audit_object", convert = FALSE)
  py_call <- reticulate::py_call
  py_attr <- reticulate::py_get_attr
  export <- etpy_get_export
  convert <- function(x) {
    if (is.numeric(x)) {
      if (is.null(dim(x))) x <- as.list(x)
      return(np$asarray(x, dtype = "float64"))
    }
    x
  }
  record_object <- function(class, fields) {
    fields <- lapply(fields, convert)
    for (key in intersect(c("dimension_names", "dimensions"), names(fields)))
      fields[[key]] <- do.call(reticulate::tuple, as.list(fields[[key]]))
    do.call(py_call, c(list(make, cls = class), fields))
  }

  rows <- list()
  record <- function(name, fixture, field, outcome, difference = NA_real_) {
    rows[[length(rows) + 1L]] <<- data.frame(python_name = name,
      scientific_family = "fpca_known_truth_recovery", source_fixture = fixture,
      field = field, outcome = outcome, max_abs_error = difference,
      independently_certified = FALSE)
  }
  schema <- function(name, fixture, field, same) {
    record(name, fixture, field, if (isTRUE(same)) "PASS_SCHEMA" else "DIVERGENT_SCHEMA")
  }
  compare_frame <- function(name, fixture, native, python) {
    shape <- identical(names(native), names(python)) && nrow(native) == nrow(python)
    schema(name, fixture, "assessment_frame.shape", shape)
    if (!shape) return(invisible(NULL))
    for (key in setdiff(names(native), "value")) {
      # Reticulate may represent a pandas nullable object column as a list.
      nullable <- function(x) vapply(as.list(x), function(v) {
        if (is.null(v) || is.na(v)) NA_character_ else as.character(v)
      }, character(1L), USE.NAMES = FALSE)
      schema(name, fixture, paste0("assessment_frame.", key),
        identical(nullable(native[[key]]), nullable(python[[key]])))
    }
    difference <- abs(native$value - python$value)
    tolerance <- ifelse(native$metric == "subspace_principal_angle_degrees",
      3e-6, 1e-10 * pmax(1, abs(python$value)))
    for (i in seq_along(difference))
      record(name, fixture, paste0(native$metric[i], ".", i),
        if (is.finite(difference[i]) && difference[i] <= tolerance[i])
          "PASS_NUMERIC" else "DIVERGENT_NUMERIC", difference[i])
    invisible(NULL)
  }
  safe <- function(expr) tryCatch(list(value = force(expr), error = NULL),
    error = function(e) list(value = NULL, error = conditionMessage(e)))

  cases <- list(
    dense = list(name = "evaluate_fpca_recovery", class = "FPCAResult",
      native = etr_evaluate_fpca_recovery,
      fixtures = c("distinct", "partial_scores", "large_grid", "grid_mismatch")),
    sparse_fpca = list(name = "evaluate_sparse_fpca_recovery", class = "SparseFPCAResult",
      native = etr_evaluate_sparse_fpca_recovery,
      fixtures = c("distinct", "partial_scores", "failed", "grid_mismatch")),
    sparse_mfpca = list(name = "evaluate_sparse_mfpca_recovery", class = "SparseMFPCAResult",
      native = etr_evaluate_sparse_mfpca_recovery,
      fixtures = c("distinct", "tied", "near_tied", "limited_pairs", "constant",
        "unretained_tie", "split_tie", "grid_mismatch")))
  for (kind in names(cases)) {
    spec <- cases[[kind]]
    for (fixture in spec$fixtures) {
      z <- .etr_recovery_modes_fixture(kind, fixture,
        grid_size = if (fixture == "large_grid") 1001L else 7L)
      if (fixture == "grid_mismatch") {
        key <- if (kind == "dense") "time" else "evaluation_grid"
        z$fit[[key]][2L] <- z$fit[[key]][2L] * 1.01
      }
      native <- safe(spec$native(z$fit, z$truth))
      source <- safe(py_call(export(spec$name),
        record_object(export(spec$class), z$fit),
        record_object(sim$FunctionalSimulationTruth, z$truth)))
      expected_error <- switch(fixture, split_tie = "split a tied truth eigenspace",
        grid_mismatch = "exact", NULL)
      if (!is.null(expected_error)) {
        match_error <- function(e) !is.null(e) && grepl(expected_error, e, fixed = TRUE)
        outcome <- if (match_error(native$error) && match_error(source$error))
          "PASS_BOTH_REJECT" else "DIVERGENT_ACCEPTANCE"
        record(spec$name, fixture, "<call>", outcome)
        next
      }
      if (!is.null(native$error) || !is.null(source$error)) {
        cat(spec$name, fixture, "R", native$error, "Python", source$error, "\n")
        record(spec$name, fixture, "<call>", "SOURCE_EXCEPTION")
        next
      }
      n <- native$value
      p <- source$value
      compare_frame(spec$name, fixture, etr_functional_recovery_assessment_frame(n),
        et_to_r(py_call(export("functional_recovery_assessment_frame"), p)))
      source_provenance <- et_to_r(builtins$dict(py_attr(p, "provenance")))
      normalize <- .etr_sparse_source_record_value
      schema(spec$name, fixture, "provenance", isTRUE(all.equal(normalize(n$provenance),
        normalize(source_provenance), check.attributes = FALSE)))
    }
  }

  warp <- .etr_recovery_repeated_warp_fixture()
  warp_name <- "evaluate_registration_recovery"
  original <- reticulate::import("types", convert = FALSE)$SimpleNamespace(
    time = convert(warp$fit$original$time))
  py_warp <- py_call(export(warp_name),
    record_object(export("RegistrationResult"),
      list(original = original, warping_functions = warp$fit$warping_functions)),
    record_object(sim$FunctionalSimulationTruth, warp$truth))
  compare_frame(warp_name, "repeated_knots_and_clamped_endpoints",
    etr_functional_recovery_assessment_frame(etr_evaluate_registration_recovery(warp$fit, warp$truth)),
    et_to_r(py_call(export("functional_recovery_assessment_frame"), py_warp)))

  custom <- .etr_recovery_custom_assessment_fixture()
  values <- lapply(custom$values, function(record) {
    metric <- do.call(py_call, c(list(export("FunctionalRecoveryMetric")), unclass(record$metric)))
    do.call(py_call, c(list(export("FunctionalRecoveryValue")), list(metric = metric),
      record[c("value", "component", "source")]))
  })
  python <- py_call(export("FunctionalRecoveryAssessment"),
    values = do.call(reticulate::tuple, values), provenance = custom$provenance)
  frame_name <- "functional_recovery_assessment_frame"
  report_name <- "functional_recovery_reporting_text"
  compare_frame(frame_name, "custom_metric", etr_functional_recovery_assessment_frame(custom),
    et_to_r(py_call(export(frame_name), python)))
  schema(report_name, "quoted_estimator", "report", identical(
    etr_functional_recovery_reporting_text(custom), et_to_r(py_call(export(report_name), python))))
  duplicate <- custom
  duplicate$values[[3L]] <- duplicate$values[[1L]]
  left <- safe(etr_functional_recovery_assessment_frame(duplicate))
  right <- safe(py_call(export("FunctionalRecoveryAssessment"),
    values = do.call(reticulate::tuple, c(values, values[1L])), provenance = custom$provenance))
  duplicate_error <- function(e) !is.null(e) && grepl("duplicate metric labels", e, fixed = TRUE)
  record(frame_name, "duplicate_metric", "<call>",
    if (duplicate_error(left$error) && duplicate_error(right$error))
      "PASS_BOTH_REJECT" else "DIVERGENT_ACCEPTANCE")

  out <- do.call(rbind, rows)
  head <- system2("git", c("rev-parse", "HEAD"), stdout = TRUE)
  stopifnot(length(head) == 1L, nchar(head) == 40L)
  out$r_git_head <- head
  out$frozen_python_commit <- "c1cd95ad718327550f7e55393ff38582872f7a94"
  folder <- file.path("artifacts", "native_batch_numeric_diff", substr(head, 1L, 12L))
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(out, file.path(folder, "fpca_recovery_source_cases_UNSIGNED.csv"),
    row.names = FALSE, na = "")
  bad <- !startsWith(out$outcome, "PASS_")
  if (any(bad)) print(out[bad, c("python_name", "source_fixture", "field", "outcome")],
    row.names = FALSE)
  cat("FPCA_RECOVERY_SOURCE_CASES=", nrow(out), ";DIFFERENCES=", sum(bad),
    ";FUNCTIONS=", length(unique(out$python_name)), "\n", sep = "")
  if (any(bad) && identical(Sys.getenv("ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE"), "true"))
    stop("FPCA recovery source discrepancies", call. = FALSE)
  invisible(out)
}
.etr_run_fpca_recovery_differential()
