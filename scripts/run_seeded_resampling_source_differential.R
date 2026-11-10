# Frozen Python 1.2 seeded workflow and separate NumPy stream evidence.
# Set ET_PINNED_PYTHON_SOURCE_ROOT to verify the imported package source
# against the pinned checkout. The default looks beside this repository.
.etr_run_seeded_resampling_source_differential <- function() {
  pkgload::load_all(".", quiet = TRUE)
  stopifnot(identical(et_python_version(), "1.2.0"))
  source("tests/testthat/helper-native-wild-projection-fixture.R", local = TRUE)
  pin <- "c1cd95ad718327550f7e55393ff38582872f7a94"
  head <- system2("git", c("rev-parse", "HEAD"), stdout = TRUE)
  stopifnot(length(head) == 1L, nchar(head) == 40L,
    length(system2("git", c("status", "--porcelain", "--untracked-files=no"),
      stdout = TRUE)) == 0L)
  oracle <- Sys.getenv("ET_PINNED_PYTHON_SOURCE_ROOT", unset = "../eyetrajectoriespy")
  verified_source_files <- dir.exists(oracle)
  if (verified_source_files) {
    stopifnot(identical(system2("git", c("-C", shQuote(oracle),
      "rev-parse", "HEAD"), stdout = TRUE), pin),
      system2("git", c("-C", shQuote(oracle), "diff", "--quiet", pin, "--", "src")) == 0L)
    frozen <- file.path(oracle, "src", "eyetrajectoriespy")
    imported <- dirname(et_to_r(reticulate::py_get_attr(et_python(), "__file__")))
    sources <- list.files(frozen, pattern = "\\.py$", recursive = TRUE)
    stopifnot(length(sources) > 0L, identical(
      unname(tools::md5sum(file.path(frozen, sources))),
      unname(tools::md5sum(file.path(imported, sources)))))
  }
  np <- reticulate::import("numpy", convert = FALSE)
  pd <- reticulate::import("pandas", convert = FALSE)
  builtins <- reticulate::import_builtins(convert = FALSE)
  numpy_version <- et_to_r(reticulate::py_get_attr(np, "__version__"))
  ints <- function(seed) builtins$int(seed)
  tuple <- function(x) do.call(reticulate::tuple, as.list(x))
  array_py <- function(x) np$asarray(
    if (is.null(dim(x))) as.list(x) else x, dtype = "float64")
  trajectory <- function(x) et_call("TrajectorySet",
    time = array_py(x$time), values = array_py(x$values),
    curve_ids = tuple(x$curve_ids), dimension_names = tuple(x$dimension_names),
    metadata = pd$DataFrame(reticulate::r_to_py(x$metadata)),
    time_unit = x$time_unit, coordinate_system = x$coordinate_system)

  workflow_rows <- list()
  stream_rows <- list()
  measured <- function(name, fixture, field, native, source, tolerance) {
    shape <- function(x) if (is.null(dim(x))) length(x) else dim(x)
    schema <- identical(shape(native), shape(source))
    a <- as.numeric(native)
    b <- as.numeric(source)
    finite <- schema && all(is.finite(a)) && all(is.finite(b))
    error <- if (finite) max(abs(a - b), 0) else NA_real_
    outcome <- if (!schema) "DIVERGENT_SCHEMA" else
      if (finite && all(abs(a - b) <= tolerance * (1 + abs(b))))
        "PASS_NUMERIC" else "DIVERGENT_NUMERIC"
    data.frame(python_name = name, scientific_family = "seeded_resampling",
      source_fixture = fixture, field = field, outcome = outcome,
      max_abs_error = error, compared_values = length(a),
      unequal_values = if (finite) sum(a != b) else NA_integer_,
      tolerance = tolerance, r_git_head = head, frozen_python_commit = pin,
      python_source_files_verified = verified_source_files,
      numpy_version = numpy_version, independently_certified = FALSE)
  }
  compare <- function(name, fixture, native, source, fields, tolerance) {
    for (field in fields)
      workflow_rows[[length(workflow_rows) + 1L]] <<- measured(name,
        fixture, field, native[[field]], et_to_r(reticulate::py_get_attr(source, field)),
        tolerance)
  }
  compare_stream <- function(fixture, field, native, source, tolerance = 0) {
    stream_rows[[length(stream_rows) + 1L]] <<- measured("NumPy PCG64",
      fixture, field, as.numeric(native), as.numeric(et_to_r(source)), tolerance)
  }
  for (seed in c(0, 1, 12345, 2^32, 2^53 - 1)) {
    fixture <- paste0("seed_", format(seed, scientific = FALSE, trim = TRUE))
    rng <- .etr_numpy_pcg64(seed)
    ref <- np$random$default_rng(ints(seed))
    compare_stream(fixture, "normal_4096", rng$normal(4096L), ref$standard_normal(4096L),
      2 * .Machine$double.eps)
    compare_stream(fixture, "following_uniform_10", rng$uniform(10L), ref$random(10L))
    for (key in list(0, c(3, 7), c(0, 0), 2^32 - 1)) {
      sequence <- np$random$SeedSequence(ints(seed), spawn_key = tuple(lapply(key, ints)))
      ref_child <- np$random$default_rng(sequence)
      child <- .etr_numpy_pcg64(seed, spawn_key = key)
      compare_stream(fixture, paste0("child_uniform_", paste(key, collapse = "_")),
        child$uniform(9L), ref_child$random(9L))
    }
  }

  f <- .etr_wild_projection_fixture()
  py_x <- trajectory(f$x)
  py_y <- array_py(f$y)
  for (seed in c(89, 2^32 + 89)) for (law in c("normal", "mammen")) {
    b <- if (seed == 89) 20L else 25L
    fixture <- paste(law, b, format(seed, scientific = FALSE), sep = "_")
    n <- etr_wild_bootstrap_fpca_projection(f$x, f$y, n_bootstrap = b,
      residual_components = 2L, inference_components = 3L,
      multiplier = law, random_state = seed)
    name <- "wild_bootstrap_fpca_projection"
    p <- et_call(name, py_x, py_y, n_bootstrap = b, residual_components = 2L,
      inference_components = 3L, multiplier = law, random_state = ints(seed))
    compare(name, fixture, n, p, c("reference_projection", "reference_se",
      "bootstrap_projections", "studentized_roots", "critical_values", "lower", "upper"),
      1e-5)
    n <- etr_scan_wild_bootstrap_fpca_truncations(f$x, f$y,
      candidate_components = 2:3, n_bootstrap = b, residual_components = 2L,
      multiplier = law, random_state = seed)
    name <- "scan_wild_bootstrap_fpca_truncations"
    p <- et_call(name, py_x, py_y, candidate_components = reticulate::tuple(2L, 3L),
      n_bootstrap = b, residual_components = 2L, multiplier = law, random_state = ints(seed))
    compare(name, fixture, n, p, c("reference_projections", "reference_se",
      "studentized_roots", "critical_values", "lower", "upper", "widths", "centers"), 1e-5)
  }

  f$x$metadata$participant <- rep(sprintf("p%02d", 1:12), each = 2L)
  py_x <- trajectory(f$x)
  design <- data.frame(curve_id = f$x$curve_ids, z = rep(seq(-1, 1, length.out = 12L), each = 2L))
  py_design <- pd$DataFrame(reticulate::r_to_py(design))
  targets <- .etr_cv_subset(f$x, c(2L, 9L, 16L))
  py_targets <- trajectory(targets)
  mean_fields <- c("mean", "lower", "upper", "pointwise_se", "critical_value", "max_statistics")
  for (unit in c("curve", "participant")) {
    group <- if (unit == "participant") "participant" else NULL
    b <- if (unit == "curve") 100L else 257L
    seed <- if (unit == "curve") 81L else 914L
    name <- "multiplier_functional_mean_band"
    n <- etr_multiplier_functional_mean_band(f$x, n_multiplier = b,
      unit = unit, participant_column = group, random_state = seed)
    p <- et_call(name, py_x, n_multiplier = b, unit = unit,
      participant_column = group, random_state = seed)
    compare(name, unit, n, p, mean_fields, 1e-10)
    name <- "windowed_rqa_functional_mean_band"
    n <- etr_windowed_rqa_functional_mean_band(f$x, metrics = "recurrence_rate",
      window = 5L, step = 2L, radius = .14, unit = unit, participant_column = group,
      dimensions = "x", n_multiplier = b, random_state = seed)
    p <- et_call(name, py_x, metrics = list("recurrence_rate"),
      window = 5L, step = 2L, radius = .14, unit = unit, participant_column = group,
      dimensions = list("x"), n_multiplier = b, random_state = seed)
    compare(name, unit, n$band, p$band, mean_fields, 1e-10)

    nfit <- etr_fit_function_on_scalar_regression(f$x, design, "z",
      unit = unit, participant_column = group)
    pfit <- et_call("fit_function_on_scalar_regression", py_x, py_design, list("z"),
      unit = unit, participant_column = group)
    for (law in c("normal", "rademacher")) {
      name <- "bootstrap_function_on_scalar_coefficients"
      n <- etr_bootstrap_function_on_scalar_coefficients(nfit,
        n_bootstrap = b, multiplier = law, random_state = seed)
      p <- et_call(name, pfit, n_bootstrap = b, multiplier = law, random_state = seed)
      fixture <- paste(unit, law, sep = "_")
      compare(name, fixture, n, p, "multipliers",
        if (law == "normal") 2 * .Machine$double.eps else 0)
      compare(name, fixture, n, p, "bootstrap_coefficients", 1e-10)
    }

    name <- "bootstrap_fpca_regression_uncertainty"
    nboot <- etr_bootstrap_fpca_regression_uncertainty(f$x, f$y, targets = targets,
      n_bootstrap = 25L, n_components = 2L, resample_unit = unit,
      participant_column = group, random_state = seed)
    pboot <- et_call(name, py_x, py_y, targets = py_targets, n_bootstrap = 25L,
      n_components = 2L, resample_unit = unit, participant_column = group, random_state = seed)
    compare(name, unit, nboot, pboot, c("bootstrap_mean_predictions",
      "bootstrap_slopes", "bootstrap_intercepts", "prediction_se", "slope_se"), 1e-6)
    name <- "fpca_regression_future_prediction_interval"
    n <- etr_fpca_regression_future_prediction_interval(nboot, f$y, random_state = seed)
    p <- et_call(name, pboot, py_y, random_state = seed)
    compare(name, unit, n, p, c("centered_residuals", "sampled_residuals", "predictive_draws",
      "lower", "median", "upper", "predictive_se"), 1e-6)
    ref_child <- np$random$default_rng(np$random$SeedSequence(seed)$spawn(1L)[[0L]])
    native_child <- .etr_numpy_pcg64(seed)$spawn(1L)[[1L]]
    compare_stream(paste0("fpcr_", unit), "spawned_residual_indices",
      matrix(native_child$integers(75L, 24L), 25L, 3L, byrow = TRUE),
      ref_child$integers(0L, 24L, size = reticulate::tuple(25L, 3L)))
  }

  folder <- file.path("artifacts", "native_batch_numeric_diff", substr(head, 1L, 12L))
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  workflow <- do.call(rbind, workflow_rows)
  streams <- do.call(rbind, stream_rows)
  utils::write.csv(workflow, file.path(folder, "seeded_resampling_source_cases_UNSIGNED.csv"),
    row.names = FALSE, na = "")
  utils::write.csv(streams, file.path(folder, "seeded_rng_streams_UNSIGNED.csv"),
    row.names = FALSE, na = "")
  bad <- rbind(workflow[workflow$outcome != "PASS_NUMERIC", ],
    streams[streams$outcome != "PASS_NUMERIC", ])
  if (nrow(bad)) print(bad[c("python_name", "source_fixture", "field", "outcome",
    "max_abs_error")], row.names = FALSE)
  cat("SEEDED_RESAMPLING_SOURCE_CASES=", nrow(workflow), ";FUNCTIONS=",
    length(unique(workflow$python_name)), ";RNG_STREAM_CASES=", nrow(streams),
    ";RNG_VALUES=", sum(streams$compared_values), ";RNG_VALUES_UNEQUAL=",
    sum(streams$unequal_values), ";DIFFERENCES=", nrow(bad), "\n", sep = "")
  if (nrow(bad) && identical(Sys.getenv("ET_SOURCE_DIFF_FAIL_ON_DIVERGENCE"), "true"))
    stop("Seeded resampling source discrepancies", call. = FALSE)
  invisible(workflow)
}
.etr_run_seeded_resampling_source_differential()
