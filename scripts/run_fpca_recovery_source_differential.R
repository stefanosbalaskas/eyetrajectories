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
import numpy as _etr_recovery_numpy
import pandas as _etr_recovery_pandas
from eyetrajectoriespy._functional_simulation import FunctionalSimulationTruth
def _etr_recovery_audit_object(cls, **fields):
    obj = object.__new__(cls)
    if cls is FunctionalSimulationTruth:
        fields = {field.name: fields.get(field.name)
                  for field in _etr_recovery_dataclass_fields(cls)}
    for key, value in fields.items():
        object.__setattr__(obj, key, value)
    return obj
def _etr_recovery_source_table(fn, result):
    with _etr_recovery_numpy.errstate(over='ignore', invalid='ignore'):
        return fn(result)
def _etr_recovery_source_column(table, name, numeric):
    values = table[name]
    if numeric:
        return values.to_numpy(dtype=float)
    return [None if _etr_recovery_pandas.isna(x) else x for x in values]
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
      fixtures = c("distinct", "partial_scores", "large_grid", "grid_mismatch",
        "equal_cost", "constant")),
    sparse_fpca = list(name = "evaluate_sparse_fpca_recovery", class = "SparseFPCAResult",
      native = etr_evaluate_sparse_fpca_recovery,
      fixtures = c("distinct", "partial_scores", "failed", "grid_mismatch",
        "diagnostic_numeric_text", "diagnostic_invalid_text")),
    sparse_mfpca = list(name = "evaluate_sparse_mfpca_recovery", class = "SparseMFPCAResult",
      native = etr_evaluate_sparse_mfpca_recovery,
      fixtures = c("distinct", "tied", "near_tied", "limited_pairs", "constant",
        "unretained_tie", "split_tie", "grid_mismatch", "diagnostic_numeric_text",
        "diagnostic_invalid_text")))
  for (kind in names(cases)) {
    spec <- cases[[kind]]
    for (fixture in spec$fixtures) {
      z <- .etr_recovery_modes_fixture(kind, fixture,
        grid_size = switch(fixture, large_grid = 1001L, equal_cost = 9L, 7L))
      if (fixture == "grid_mismatch") {
        key <- if (kind == "dense") "time" else "evaluation_grid"
        z$fit[[key]][2L] <- z$fit[[key]][2L] * 1.01
      }
      if (fixture %in% c("diagnostic_numeric_text", "diagnostic_invalid_text")) {
        z$fit$covariance_diagnostics <- list(applied_action = "project",
          relative_operator_correction_frobenius_norm =
            if (fixture == "diagnostic_numeric_text") " 0.125 " else "unknown")
      }
      native <- safe(spec$native(z$fit, z$truth))
      source <- safe(py_call(export(spec$name),
        record_object(export(spec$class), z$fit),
        record_object(sim$FunctionalSimulationTruth, z$truth)))
      expected_error <- switch(fixture, split_tie = "split a tied truth eigenspace",
        grid_mismatch = "exact",
        constant = if (kind == "dense") "finite" else NULL,
        diagnostic_invalid_text = c("must be numeric", "could not convert"), NULL)
      if (!is.null(expected_error)) {
        patterns <- rep_len(expected_error, 2L)
        match_error <- function(e, pattern) !is.null(e) && grepl(pattern, e, fixed = TRUE)
        outcome <- if (match_error(native$error, patterns[1L]) &&
            match_error(source$error, patterns[2L]))
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

  py_integer <- function(x) py_call(builtins$int, sprintf("%.0f", x))
  py_metric <- function(x) do.call(py_call,
    c(list(export("FunctionalRecoveryMetric")), unclass(x)))
  py_value <- function(x, component = x$component) py_call(
    export("FunctionalRecoveryValue"), metric = py_metric(x$metric),
    value = x$value, component = component, source = x$source)
  source_result <- function(records, definitions = list()) {
    native <- etr_functional_recovery_result(records, definitions)
    source_records <- lapply(records, function(z) {
      metric_values <- lapply(z$metric_values, function(v)
        py_value(v, if (is.null(v$component)) NULL else py_integer(v$component)))
      mapping <- reticulate::dict()
      for (key in names(z$metrics)) mapping[[key]] <- z$metrics[[key]]
      py_call(export("FunctionalRecoveryRecord"), scenario_name = z$scenario_name,
        replicate = py_integer(z$replicate), seed = py_integer(z$seed), metrics = mapping,
        metric_values = do.call(reticulate::tuple, metric_values), status = z$status,
        error_type = z$error_type, error_message = z$error_message)
    })
    python <- py_call(export("FunctionalRecoveryResult"),
      records = do.call(reticulate::tuple, source_records),
      metric_definitions = do.call(reticulate::tuple, lapply(definitions, py_metric)))
    list(native = native, python = python)
  }
  source_table <- reticulate::py_eval("_etr_recovery_source_table", convert = FALSE)
  source_column <- reticulate::py_eval("_etr_recovery_source_column", convert = FALSE)
  compare_reporting <- function(name, fixture, native, expected) {
    expected_names <- as.character(unlist(et_to_r(expected$columns$tolist()),
      use.names = FALSE))
    shape <- identical(names(native), expected_names) &&
      nrow(native) == et_to_r(py_call(builtins$len, expected))
    schema(name, fixture, "shape", shape)
    if (!shape) return(invisible(NULL))
    nullable <- function(x) vapply(as.list(x), function(v) {
      if (is.null(v) || is.na(v)) NA_character_ else enc2utf8(as.character(v))
    }, character(1L), USE.NAMES = FALSE)
    for (field in names(native)) {
      lhs <- native[[field]]
      numeric <- is.numeric(lhs)
      rhs <- et_to_r(py_call(source_column, expected, field, numeric))
      if (!numeric) {
        schema(name, fixture, field, identical(nullable(lhs), nullable(rhs)))
      } else {
        lhs <- as.numeric(lhs)
        rhs <- as.numeric(rhs)
        finite <- is.finite(lhs) & is.finite(rhs)
        tolerance <- if (field %in% c("replicate", "seed", "component", "n",
          "n_total", "n_success", "n_failed")) 0 else 1e-12 * pmax(1, abs(rhs[finite]))
        matching <- identical(is.na(lhs), is.na(rhs)) &&
          identical(is.finite(lhs), is.finite(rhs)) &&
          identical(lhs[!is.finite(lhs) & !is.na(lhs)],
            rhs[!is.finite(rhs) & !is.na(rhs)]) &&
          all(abs(lhs[finite] - rhs[finite]) <= tolerance)
        difference <- if (any(finite)) max(abs(lhs[finite] - rhs[finite])) else 0
        record(name, fixture, field,
          if (matching) "PASS_NUMERIC" else "DIVERGENT_NUMERIC", difference)
      }
    }
    invisible(NULL)
  }
  def <- etr_functional_recovery_metric_catalog()[["mean_ise"]]
  structured <- list(metric = def, value = .375, component = 2^53-1, source = "x")
  flat <- function(scenario, index, metric) list(scenario_name = scenario,
    replicate = index, seed = 2^53-1, status = "ok", metrics = metric)
  failed <- function(scenario, status) list(scenario_name = scenario,
    replicate = 2L, seed = -2^53+1, status = status, metrics = numeric(),
    error_type = "ValueError", error_message = "explicit failure")
  successful <- flat("\u00e9", 2^31 + 2, setNames(.375,
    etr_functional_recovery_value_key(structured)))
  successful$metric_values <- list(structured)
  mixed <- list(successful,
    flat("a", 1L, c(mean_ise = .25, undeclared = -1.2)),
    flat("\u00e9", 0L, c(mean_ise = .125)), flat("Z", 0L, c(mean_ise = .5)),
    failed("a", "fit_failed"), failed("\u03b1", "simulation_failed"),
    failed("\u00e9", "recovery_failed"))
  extreme <- list(
    cancellation = c(1e16, 1, -1e16),
    opposite = c(-1e308, 1e308),
    positive = c(1e308, 1e308),
    pairwise = rep(c(1e16, 2, -1e16, 1, 1, 1, 1), length.out = 259L))
  extreme <- unlist(lapply(names(extreme), function(scenario)
    lapply(seq_along(extreme[[scenario]]), function(i)
      flat(scenario, i - 1L, c(mean_ise = extreme[[scenario]][i])))),
    recursive = FALSE, use.names = FALSE)
  results <- list(
    mixed_order_missing_and_wide = source_result(mixed, list(def)),
    all_failed = source_result(list(failed("\u00e9", "simulation_failed"),
      failed("a", "fit_failed"), failed("Z", "recovery_failed"))),
    extreme_reductions = source_result(extreme, list(def)))
  funcs <- list(
    functional_recovery_frame = etr_functional_recovery_frame,
    functional_recovery_failure_frame = etr_functional_recovery_failure_frame,
    functional_recovery_summary_frame = function(x)
      etr_functional_recovery_summary_frame(x, python_boundary_mode = TRUE))
  for (fixture in names(results)) {
    result <- results[[fixture]]
    for (name in names(funcs)) compare_reporting(name, fixture,
      funcs[[name]](result$native),
      py_call(source_table, export(name), result$python))
  }
  for (name in names(funcs)) {
    native_error <- safe(funcs[[name]](list()))$error
    source_error <- safe(py_call(export(name), reticulate::dict()))$error
    matches <- !is.null(native_error) &&
      grepl("native functional recovery result", native_error, fixed = TRUE) &&
      !is.null(source_error) && grepl("FunctionalRecoveryResult", source_error, fixed = TRUE)
    record(name, "invalid_result_type", "<call>",
      if (matches) "PASS_BOTH_REJECT" else "DIVERGENT_ACCEPTANCE")
  }

  mapped <- list(values = list(
    list(metric = unclass(def), value = " 1_2.5 ", component = "2_147_483_648",
      source = "\u2003x\u00a0"),
    list(metric = unclass(def), value = TRUE, component = NULL, source = NULL)))
  mapped$values[[1L]]$metric$description <- "\u2003A custom definition\u00a0"
  mapped$values[[1L]]$metric$direction <- "higher_is_better"
  mapped_values <- do.call(reticulate::tuple, lapply(mapped$values, py_value))
  mapped_source <- py_call(export("FunctionalRecoveryAssessment"), values = mapped_values)
  compare_reporting(frame_name, "mapped_same_name_and_nullable",
    etr_functional_recovery_assessment_frame(mapped, python_boundary_mode = TRUE),
    py_call(export(frame_name), mapped_source))
  for (fixture in c("missing", "explicit_none", "bool", "float", "mapping")) {
    estimator <- switch(fixture, bool = TRUE, float = -.125,
      mapping = list(name = "quote's\nline", flags = list(TRUE, NULL, 2L)), NULL)
    mapped$provenance <- if (fixture == "missing") list() else list(estimator = estimator)
    provenance <- if (fixture == "missing") reticulate::dict()
      else reticulate::dict(estimator = estimator)
    source <- py_call(export("FunctionalRecoveryAssessment"), values = mapped_values,
      provenance = provenance)
    schema(report_name, paste0("mapped_estimator_", fixture), "report",
      identical(etr_functional_recovery_reporting_text(mapped, python_boundary_mode = TRUE),
        et_to_r(py_call(export(report_name), source))))
  }
  invalid <- mapped
  invalid$values[[1L]]$value <- "Inf"
  left <- safe(etr_functional_recovery_assessment_frame(invalid,
    python_boundary_mode = TRUE))$error
  right <- safe(py_value(invalid$values[[1L]]))$error
  record(frame_name, "nonfinite_value", "<call>",
    if (!is.null(left) && grepl("must be finite", left, fixed = TRUE) &&
        !is.null(right) && grepl("must be finite", right, fixed = TRUE))
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
