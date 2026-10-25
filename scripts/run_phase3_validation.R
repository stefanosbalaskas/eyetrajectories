#!/usr/bin/env Rscript
# Source-safe experimental Phase 3 validation. All outputs remain explicitly
# simulation-based and are not empirical eye-tracking results.
if (!file.exists("DESCRIPTION")) stop("Run this script from package repository root")
suppressPackageStartupMessages(library(eyetrajectories))
cmd <- commandArgs(trailingOnly = TRUE)
out <- if (length(cmd)) cmd[[1L]] else "artifacts/phase3"
dir.create(out, showWarnings = FALSE, recursive = TRUE)
smoke <- identical(Sys.getenv("ET_PHASE3_SMOKE"), "true")
sims <- if (smoke) 5L else 40L
B <- if (smoke) 49L else 199L
results <- list()
collect <- function(name, value) {
  value$study <- name
  results[[name]] <<- value
}
write_table <- function(name, data) {
  utils::write.csv(data, file.path(out, paste0(name, ".csv")), row.names = FALSE)
}
cat("Phase 3 independent known-truth simulations (experimental)\n")
cat("Git HEAD and R package version must be recorded with archived outputs.\n")
group <- etr_evaluate_group_contrast_coverage(
  simulations = sims, n_subjects = if(smoke) 12L else 24L,
  B = B, alpha = .1, seed = 640L
)
write_table("group_contrast_trials", group$results)
collect("randomized_group_contrast",
        data.frame(metric = c("simultaneous_coverage","mc_se","mean_pointwise_coverage"),
                   value = c(group$simultaneous_coverage,group$monte_carlo_se,
                             group$mean_pointwise_coverage)))
band <- etr_evaluate_mean_band_coverage(
  simulations = sims, B = B, alpha = .1,
  n_subjects = if(smoke) 12L else 24L, seed = 740L
)
collect("participant_mean_band",
        data.frame(metric = c("simultaneous_coverage","mc_se","mean_pointwise_coverage"),
                   value = c(band$simultaneous_coverage,band$monte_carlo_se,
                             band$mean_pointwise_coverage)))
analytic <- etr_evaluate_between_variance(
 simulations = if(smoke) 5L else 40L,
 n_subjects = if(smoke) 10L else 24L,
 n_time = if(smoke) 21L else 41L, seed = 810L
)
collect("analytic_between_variance",
        data.frame(metric = c("true_integrated_variance","mean_sample_trace",
                              "bias","mc_se","rmse"),
                   value = c(analytic$analytic_truth,analytic$mean_estimate,
                             analytic$mean_bias,analytic$mc_se_of_mean,
                             analytic$rmse)))
multilevel <- etr_evaluate_multilevel_recovery(
  simulations = if(smoke) 3L else 20L,
  n_subjects = if(smoke) 10L else 24L, seed = 840L
)
write_table("multilevel_recovery", multilevel)
collect("descriptive_multilevel",
        data.frame(metric = "mean_curve_rmse",
                   value = mean(multilevel$population_mean_rmse)))
for (persist in c(.55, .80, .95)) {
  tt <- etr_evaluate_te_null(
    simulations = sims, n = if(smoke) 80L else 400L,
    persistence = persist, n_surrogates = if(smoke) 19L else 99L,
    seed = 940L + as.integer(persist*100),
    nominal = .05
  )
  label <- paste0("te_null_persistence_",persist)
  write_table(label, tt$results)
  collect(label,
          data.frame(metric = c("diagnostic_flag_rate","mc_se","mean_plugin_bits"),
                     value = c(tt$diagnostic_flag_rate,tt$monte_carlo_se,
                               mean(tt$results$plug_in_bits))))
}
if (identical(Sys.getenv("ET_PHASE3_INCLUDE_PACE"), "true")) {
  if (!requireNamespace("fdapace", quietly = TRUE))
    stop("ET_PHASE3_INCLUDE_PACE requested but fdapace is missing")
  ss <- etr_evaluate_sparse_pace_recovery(
    simulations = if(smoke) 2L else 10L,
    n_subjects = if(smoke) 35L else 60L, seed = 1040L)
  write_table("sparse_pace_recovery", ss)
  collect("sparse_univariate_pace",
          data.frame(metric = c("failed_fit_fraction","finite_curve_rmse_fraction"),
                     value = c(mean(ss$failed),mean(is.finite(ss$curve_rmse)))))
}
summary <- do.call(rbind, results)
summary <- summary[,c("study","metric","value")]
rownames(summary) <- NULL
write_table("validation_summary",summary)
if (any(!is.finite(summary$value))) stop("Validation generated non-finite report metrics")
sim <- etr_simulate_group_contrast(n_subjects = 20L, seed = 1100L)
fit <- etr_bootstrap_group_contrast(sim$trajectories,sim$participant,
                                    sim$treatment,B=B,alpha=.1,seed=1101L)
grDevices::pdf(file.path(out,"experimental_phase3_figures.pdf"),
               width = 7, height = 5)
tryCatch({
  etr_plot_functional_band(fit, dimension = 1L)
  etr_plot_functional_band(fit, dimension = 2L)
  sparse <- etr_simulate_sparse_known_truth(n_subjects = 35L, seed = 1102L)
  etr_plot_sparse_support(etr_sparse_design_diagnostics(sparse$curves))
  null <- etr_simulate_te_null(n = 300L, seed = 1103L)
  te <- etr_transfer_entropy_shift_test(null$source,null$target,
                                        n_surrogates = 99L,seed=1104L)
  etr_plot_transfer_surrogates(te)
}, finally = grDevices::dev.off())
writeLines(c(
 "Experimental synthetic Phase 3 audit",
 paste("Run date UTC:",format(Sys.time(),tz="UTC",usetz=TRUE)),
 paste("R:",R.version.string),
 paste("Package version:",as.character(utils::packageVersion("eyetrajectories"))),
 paste("Git SHA:",Sys.getenv("GITHUB_SHA",unset="local-unverified")),
 paste("Monte Carlo simulations per major design:",sims),
 paste("Bootstrap repetitions:",B),
 "All results are synthetic and not release qualification.",
 "No inferential calibration is certified by this script."
),file.path(out,"MANIFEST.txt"))
cat("Finished Phase 3 experimental simulation outputs in ",out,"\n",sep="")
