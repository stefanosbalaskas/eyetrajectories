# Audit the exact exported interfaces without claiming estimator equivalence.
# Run from repo root:
# source("scripts/report_python_r_capabilities.R")
#
# Optional runtime verification, imports installed Python:
# Sys.setenv(ET_CAPABILITY_CHECK_PYTHON = "true")
# source("scripts/report_python_r_capabilities.R")
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION", fields = "Package")[1L]) != "eyetrajectories")
  stop("Run from eyetrajectories repository root.", call. = FALSE)
if (!requireNamespace("pkgload", quietly = TRUE))
  stop("Install pkgload to inspect the exact source package namespace.",
       call. = FALSE)
pkgload::load_all(".", quiet = TRUE)
api <- eyetrajectories::etpy_catalog(include_nonfunctions = TRUE)
stopifnot(nrow(api) == 508L)
functions <- api[api$kind == "function", , drop = FALSE]
stopifnot(nrow(functions) == 380L,
          sum(functions$namespace == "root") == 362L,
          sum(functions$namespace == "workflows") == 18L)
ns <- getNamespaceExports("eyetrajectories")
native <- sort(grep("^etr_", ns, value = TRUE))
bridge <- sort(grep("^etpy_", ns, value = TRUE))
legacy <- sort(grep("^et_", ns, value = TRUE))
stopifnot(length(native) == 88L,
          length(bridge) == 383L, # 380 wrappers + 3 catalog utilities
          length(legacy) == 14L)
stopifnot(all(functions$r_wrapper %in% ns))

# A hand-reviewed list of related native entry points. These are name-level
# candidates for parity testing: NOT automatically equivalent algorithms.
analog <- c(
  from_long_dataframe = "etr_from_long",
  validate_trajectory_set = "etr_validate",
  resample_to_grid = "etr_resample",
  interpolate_short_gaps = "etr_interpolate_gaps",
  smooth_trajectories = "etr_smooth",
  normalize_time = "etr_normalize_time",
  center_on_landmark = "etr_center",
  differentiate_trajectories = "etr_velocity",
  speed_function = "etr_speed",
  heading_function = "etr_heading",
  cumulative_path_length = "etr_cumulative_path_length",
  trajectory_tortuosity = "etr_tortuosity",
  functional_l2_distance = "etr_l2_distance",
  discrete_frechet_distance = "etr_frechet",
  dynamic_time_warping_distance = "etr_dtw",
  functional_trapezoid_weights = "etr_trapezoid_weights",
  fit_fpca = "etr_fit_fpca",
  fit_mfpca = "etr_fit_mfpca",
  transform_fpca = "etr_transform_fpca",
  reconstruct_fpca = "etr_reconstruct_fpca",
  recurrence_matrix = "etr_recurrence_matrix",
  cross_recurrence_matrix = "etr_cross_recurrence_matrix",
  rqa_metrics = "etr_rqa_metrics",
  plot_trajectory_overlay = "etr_plot_trajectories",
  plot_fpca_variance = "etr_plot_fpca_variance",
  plot_recurrence = "etr_plot_recurrence",
  fit_sparse_fpca = "etr_fit_sparse_pace",
  fit_multilevel_fpca = "etr_fit_multilevel_fpca",
  fit_functional_mixed_effects_regression = "etr_fit_functional_mixed",
  discrete_transfer_entropy = "etr_transfer_entropy",
  transfer_entropy_circular_shift_test = "etr_transfer_entropy_shift_test",
  fit_scalar_on_function_regression = "etr_fit_scalar_on_fpca"
)
if (!all(unname(analog) %in% native))
  stop("Native analogy catalog contains nonexistent R function(s).")
if (!all(names(analog) %in% functions$python_name))
  stop("Analog mapping contains nonexistent Python function(s).")
functions$native_analog <- unname(analog[functions$python_name])
functions$native_analog[is.na(functions$native_analog)] <- ""
functions$native_analogy_status <- ifelse(nzchar(functions$native_analog),
  "candidate_for_numerical_parity_testing",
  "not_mapped_to_a_specific_native_R_entry")
# No automated equivalence, callability, scientific readiness or implementation
# coverage should ever be inferred from the analog name map.
functions$numeric_parity_qualified <- FALSE

# Class and constant imports can be accessed through etpy_get_export; not
# all are callable or directly expressible as native R classes.
out <- file.path("artifacts", "capability_parity")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
utils::write.csv(functions, file.path(out, "python_function_bridge_inventory.csv"),
                 row.names = FALSE)
utils::write.csv(api[api$kind != "function", , drop = FALSE],
                 file.path(out, "python_class_constant_inventory.csv"),
                 row.names = FALSE)
utils::write.csv(data.frame(native_r_export = native),
                 file.path(out, "native_r_functions.csv"), row.names = FALSE)
table <- data.frame(
  measure = c("Python root callable exports",
              "Python workflow callable exports",
              "Total Python callable exports",
              "Python nonfunction public exports",
              "Explicit Python-backed R callable wrappers",
              "Native R exports (not 1:1 parity count)",
              "Original Python bridge exports",
              "Catalog/verification utilities",
              "Named candidate native analogs, not qualified parity",
              "Qualified cross-language estimator contracts"),
  value = c(362L, 18L, 380L, 128L, 380L, length(native),
            length(legacy), 3L, sum(nzchar(functions$native_analog)), 0L)
)
utils::write.csv(table, file.path(out, "capability_counts.csv"),
                 row.names = FALSE)
if (identical(Sys.getenv("ET_CAPABILITY_CHECK_PYTHON"), "true")) {
  availability <- eyetrajectories::etpy_verify_api(
    include_nonfunctions = TRUE, strict = FALSE)
  utils::write.csv(availability,
                   file.path(out, "installed_python_export_availability.csv"),
                   row.names = FALSE)
  if (any(!availability$available) ||
      any(availability$kind == "function" & availability$callable %in% FALSE))
    warning("Installed Python does not match the API snapshot. Check CSV.")
}
sha <- tryCatch(system2("git", c("rev-parse", "HEAD"),
                        stdout = TRUE, stderr = FALSE),
                error = function(e) "unavailable")
if (!length(sha)) sha <- "unavailable"
writeLines(c(
  "Structural capability/bridge inventory, NOT estimator equivalence.",
  paste("UTC:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste("Source R version:",
        unname(read.dcf("DESCRIPTION", fields = "Version")[1L])),
  paste("Source Git SHA:", sha[1L]),
  paste("Python main API source SHA:", unique(api$source_git_sha)),
  "380 Python functions are exposed as wrappers, but runtime optional",
  "dependencies and numerical/behavioral parity require separate tests.",
  "88 native exports are not 88 equivalents of 380 Python callables.",
  "Native analogs are manually reviewed name candidates, not parity claims.",
  "Nonfunction exports are retrievable through etpy_get_export().",
  "Scientific inferential calibration is still on HOLD."
), file.path(out, "MANIFEST.txt"))
print(table, row.names = FALSE)
cat("Capability audit saved in ",
    normalizePath(out, winslash = "/"), "\n", sep = "")
