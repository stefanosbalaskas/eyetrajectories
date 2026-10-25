# Native eyetrajectories Phase 2 demonstration. No Python import.
# Deterministic synthetic math examples only (not recorded human gaze).
library(eyetrajectories)

time <- seq(0, 1, length.out = 81L)
values <- array(0, c(10L, length(time), 2L))
for (i in seq_len(10L)) {
  values[i, , 1] <- sin(2 * pi * time + i / 10) + .03 * i
  values[i, , 2] <- cos(2 * pi * time + i / 10) + .02 * i
}
gaze <- etr_trajectory_set(
  time, values, curve_ids = paste0("synthetic_", seq_len(10L)),
  dimension_names = c("x", "y"),
  coordinate_system = "normalized", time_unit = "s"
)
fit <- etr_fit_mfpca(gaze, n_components = 0.95,
                     scaling = "dimension_sd")
print(etr_summary(gaze))
print(etr_fpca_variance_frame(fit))
print(head(etr_fpca_scores(fit)))
print(etr_path_length(gaze))
print(etr_pairwise_l2(gaze)[1:4, 1:4])
rec <- etr_recurrence_matrix(gaze, curve = "synthetic_1",
                             radius = .2, theiler = 2L)
print(etr_rqa_metrics(rec))
grDevices::pdf("native_phase2_figures.pdf", width = 7, height = 5)
etr_plot_trajectories(gaze)
etr_plot_fpca_variance(fit)
etr_plot_recurrence(rec)
grDevices::dev.off()
message("Wrote native_phase2_figures.pdf (three synthetic R figures)")
