# Reproducible native R worked gallery; no Python or external services.
# source("scripts/run_native_worked_gallery.R") from repository root
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION", fields = "Package")[1L]) != "eyetrajectories")
  stop("Run from eyetrajectories root.", call. = FALSE)
if (!requireNamespace("pkgload", quietly = TRUE))
  stop("Install pkgload first.")
pkgload::load_all(".", quiet = TRUE)
out <- file.path("artifacts", "native_worked_gallery")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
hier <- eyetrajectories::etr_simulate_hierarchical(
  n_subjects = 20L, trials_per_subject = 3L, n_time = 41L, seed = 2501L)
multi <- eyetrajectories::etr_fit_multilevel_fpca(
  hier$trajectories, hier$participant, n_between = 2L, n_within = 2L)
multi_diag <- eyetrajectories::etr_multilevel_diagnostics(multi)
multi_var <- eyetrajectories::etr_multilevel_variance(multi)
stopifnot(multi_diag$n_participants == 20L,
          is.finite(multi_diag$fitted_reconstruction_rmse))
utils::write.csv(multi_var, file.path(out, "multilevel_variance.csv"),
                 row.names = FALSE)
mean_band <- eyetrajectories::etr_bootstrap_mean_band(
  hier$trajectories, hier$participant, B = 99L, alpha = .10,
  seed = 2502L)
s <- eyetrajectories::etr_simulate_group_contrast(
  n_subjects = 24L, n_time = 41L, seed = 2503L)
contrast <- eyetrajectories::etr_bootstrap_group_contrast(
  s$trajectories, s$participant, s$treatment, B = 99L,
  alpha = .10, seed = 2504L)
stopifnot(mean_band$independent_clusters == 20L,
          all(contrast$simultaneous_lower <= contrast$simultaneous_upper))
sparse <- eyetrajectories::etr_simulate_sparse_known_truth(
  n_subjects = 35L, seed = 2505L)
support <- eyetrajectories::etr_sparse_design_diagnostics(
  sparse$curves, bins = 10L)
utils::write.csv(support$support,
                 file.path(out, "sparse_observation_support.csv"),
                 row.names = FALSE)
set.seed(2506L)
source_states <- sample(0:1, 220L, replace = TRUE)
target_states <- c(0L, head(source_states, -1L))
flip <- stats::runif(220L) < .1
target_states[flip] <- 1L - target_states[flip]
te <- eyetrajectories::etr_transfer_entropy_shift_test(
  source_states, target_states, n_surrogates = 49L, seed = 2507L)
stopifnot(is.finite(te$observed_bits), length(te$null_bits) == 49L)
metrics <- data.frame(
  metric = c("multilevel_participants", "multilevel_curves",
             "multilevel_reconstruction_rmse", "mean_band_clusters",
             "group_control_participants", "group_treatment_participants",
             "sparse_independent_curves", "sparse_minimum_bin_coverage",
             "observed_te_bits", "te_shift_diagnostic_p",
             "nominal_reference_only"),
  value = c(multi_diag$n_participants, multi_diag$n_curves,
            multi_diag$fitted_reconstruction_rmse,
            mean_band$independent_clusters,
            contrast$participants_per_group,
            support$summary$n_curves,
            support$summary$minimum_bin_coverage,
            te$observed_bits, te$diagnostic_p, .90)
)
utils::write.csv(metrics, file.path(out, "native_worked_summary.csv"),
                 row.names = FALSE)
pdf_path <- file.path(out, "native_worked_figures.pdf")
grDevices::pdf(pdf_path, width = 7.2, height = 5.2)
plot_error <- NULL
tryCatch({
  graphics::barplot(multi_var$integrated_variance,
                    names.arg = multi_var$stratum, las = 2L,
                    ylab = "Integrated sample variance",
                    main = "Descriptive between / within variation")
  eyetrajectories::etr_plot_functional_band(
    mean_band, dimension = 1L, interval = "simultaneous")
  eyetrajectories::etr_plot_functional_band(
    contrast, dimension = 1L, interval = "simultaneous")
  eyetrajectories::etr_plot_sparse_support(support)
  eyetrajectories::etr_plot_transfer_surrogates(te)
}, error = function(e) plot_error <<- conditionMessage(e),
finally = grDevices::dev.off())
if (!is.null(plot_error)) stop(plot_error, call. = FALSE)
stopifnot(file.exists(pdf_path), file.info(pdf_path)$size > 0L)
writeLines(c(
  "Native worked gallery: synthetic, not independently qualified.",
  paste("Date UTC:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste("Source package version:",
        unname(read.dcf("DESCRIPTION", fields = "Version")[1L])),
  "No empirical gaze and no Python import.",
  "The functional bootstrap bands are not calibrated.",
  "Shift diagnostics do not establish causal transfer entropy."
), file.path(out, "MANIFEST.txt"))
print(metrics, row.names = FALSE)
cat("Gallery folder:", normalizePath(out, winslash = "/"), "\n")
cat("PDF:", normalizePath(pdf_path, winslash = "/"), "\n")
