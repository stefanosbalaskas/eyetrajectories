# Native CRAN smoke example; uses no Python or online services.
# From package repository root after pkgload::load_all():
#   source("inst/examples/cran_native_smoke.R")
# Outputs default to project/artifacts/cran_native_example for local usage.
# Set ET_EXAMPLE_OUTPUT_DIR to override; use tempdir() outside a repo root.
if (!requireNamespace("eyetrajectories", quietly = TRUE))
  stop("Load eyetrajectories from the checkout before running this example.")
library(eyetrajectories)
out <- Sys.getenv("ET_EXAMPLE_OUTPUT_DIR", unset = "")
if (!nzchar(out)) {
  if (file.exists("DESCRIPTION") &&
      identical(unname(read.dcf("DESCRIPTION", fields = "Package")[1L]),
                "eyetrajectories")) {
    out <- file.path(getwd(), "artifacts", "cran_native_example")
  } else {
    out <- file.path(tempdir(), "eyetrajectories_native_example")
  }
}
dir.create(out, recursive = TRUE, showWarnings = FALSE)
stopifnot(dir.exists(out))
out <- normalizePath(out, winslash = "/", mustWork = TRUE)

# Reproducible mathematical paths with no empirical gaze observations.
time <- seq(0, 1, length.out = 31L)
n <- 8L
values <- array(0, c(n, length(time), 2L))
for (i in seq_len(n)) {
  phase <- i / 7
  values[i, , 1L] <- (1 + i/20) * sin(2*pi*time + phase)
  values[i, , 2L] <- (1 - i/30) * cos(2*pi*time + phase)
}
x <- etr_trajectory_set(
  time = time, values = values,
  curve_ids = paste0("example_", seq_len(n)),
  dimension_names = c("x", "y"),
  coordinate_system = "normalized", time_unit = "s"
)
stopifnot(isTRUE(etr_validate(x, require_complete = TRUE)))
long <- etr_as_long(x)
back <- etr_from_long(long, "curve_id", "time", c("x", "y"))
stopifnot(identical(back$time, x$time),
          isTRUE(all.equal(back$values, x$values)))

# Independently native functions: distances, weighted FPCA, recurrence.
fit <- etr_fit_mfpca(x, n_components = 2L)
scores <- etr_fpca_scores(fit)
distance <- etr_pairwise_l2(x)
rec <- etr_recurrence_matrix(x, curve = "example_1",
                             radius = 0.3, theiler = 1L)
rqa <- etr_rqa_metrics(rec)
stopifnot(nrow(scores) == n, nrow(distance) == n,
          all(is.finite(distance)), is.finite(rqa$recurrence_rate),
          all(dim(etr_reconstruct_fpca(fit)$values) == dim(x$values)))

# Experimental participant mean band: shape/invariants ONLY; no calibration.
sim <- etr_simulate_hierarchical(n_subjects = 12L,
                                  trials_per_subject = 2L,
                                  n_time = 21L, seed = 2026L)
band <- etr_bootstrap_mean_band(sim$trajectories, sim$participant,
                                B = 49L, alpha = 0.10, seed = 2027L)
stopifnot(identical(dim(band$mean), c(21L, 2L)),
          band$independent_clusters == 12L,
          all(band$simultaneous_lower <= band$simultaneous_upper))

# Lightweight API census without initializing Python.
catalog <- etpy_catalog()
stopifnot(nrow(catalog) == 380L)

pdf_file <- file.path(out, "cran_native_example_plots.pdf")
grDevices::pdf(pdf_file, width = 7, height = 5)
tryCatch({
  etr_plot_trajectories(x)
  etr_plot_fpca_variance(fit)
  etr_plot_recurrence(rec)
}, finally = grDevices::dev.off())
stopifnot(file.exists(pdf_file), file.info(pdf_file)$size > 0)

results <- data.frame(
  metric = c("curves", "observations_per_curve", "fpca_components",
             "recurrence_rate", "independent_bootstrap_clusters",
             "python_callable_catalog_count"),
  value = c(n, length(time), fit$n_components, rqa$recurrence_rate,
            band$independent_clusters, nrow(catalog))
)
utils::write.csv(results, file.path(out, "cran_native_example_summary.csv"),
                 row.names = FALSE)
print(results, row.names = FALSE)
cat("Native example passed; outputs saved to: ", out, "\n", sep = "")
cat("Summary CSV: ", file.path(out, "cran_native_example_summary.csv"), "\n", sep = "")
cat("Plots PDF: ", pdf_file, "\n", sep = "")
