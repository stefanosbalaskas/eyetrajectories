# Exploratory native parity stage 1: reproducible demo, no Python.
# Run from repository root on research/native-parity-stage1:
#   source("scripts/run_native_parity_stage1_demo.R")
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION", fields = "Package")[1L]) != "eyetrajectories")
  stop("Run this script from the eyetrajectories project root.")
if (!requireNamespace("pkgload", quietly = TRUE))
  stop("Install pkgload before running the local development demo.")
pkgload::load_all(".", quiet = TRUE)
out <- file.path("artifacts", "native_parity_stage1")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
t <- seq(0, 1, length.out = 41L)
n <- 12L
offset <- seq(-.06, .06, length.out = n)
values <- array(NA_real_, c(n, length(t), 2L))
for (i in seq_len(n)) {
  values[i, , 1L] <- sin(2*pi*(t-offset[i]))
  values[i, , 2L] <- cos(2*pi*(t-offset[i]))
}
x <- etr_trajectory_set(t, values, paste0("curve_", seq_len(n)),
                         c("x", "y"), coordinate_system = "unitless",
                         time_unit = "normalized")
reg <- etr_register_landmarks(
  x, source_landmarks = matrix(.25 + offset, ncol = 1L),
  target_landmarks = .25)
warp <- etr_registration_warp_frame(reg)
utils::write.csv(warp, file.path(out, "landmark_warp.csv"), row.names = FALSE)

embedding <- etr_delay_embedding(values[1L, , 1L], 3L, 2L)
rec <- etr_recurrence_matrix(x, curve = 1L, radius = .3, theiler = 1L)
net <- etr_recurrence_network(rec)
utils::write.csv(etr_recurrence_network_nodes(net),
                 file.path(out, "network_nodes.csv"), row.names = FALSE)
return_events <- etr_poincare_return_map(
  sin(seq(0, 10*pi, length.out = 101L)), threshold = 0, direction = "up")
utils::write.csv(return_events$return_map,
                 file.path(out, "threshold_return_map.csv"), row.names = FALSE)

# A frozen model and separated curve IDs. Only per-independent-unit marginal
# conformal semantics; no true study-level false positive rate is asserted.
generate <- function(ids, added = FALSE) {
  m <- length(ids); z <- array(NA_real_, c(m, length(t), 1L))
  for (i in seq_len(m))
    z[i, , 1L] <- sin(2*pi*t) +
      (i/(m+3)) * cos(2*pi*t) +
      (if (added) 4 else 0) * sin(4*pi*t)
  etr_trajectory_set(t, z, ids, "x")
}
training <- generate(paste0("training_", seq_len(8L)))
calibration <- generate(paste0("calibration_", seq_len(10L)))
test <- generate(paste0("test_", seq_len(3L)), added = TRUE)
fit <- etr_fit_fpca(training, n_components = 1L)
screen <- etr_split_conformal_fpca_anomalies(
  fit, calibration, test, alpha = .10)
utils::write.csv(screen$test, file.path(out, "conformal_anomaly_test.csv"),
                 row.names = FALSE)

pdf_file <- file.path(out, "native_parity_stage1_demo.pdf")
grDevices::pdf(pdf_file, width = 8, height = 5.5)
tryCatch({
  graphics::matplot(t, t(x$values[, , 1L]), type = "l",
                    col = "gray50", lty = 1L,
                    xlab = "Time", ylab = "x",
                    main = "Before prespecified landmark registration")
  graphics::abline(v = .25, col = "blue", lty = 3L)
  graphics::matplot(t, t(reg$registered$values[, , 1L]),
                    type = "l", col = "gray50", lty = 1L,
                    xlab = "Target time", ylab = "Registered x",
                    main = "After explicit landmark registration")
  graphics::abline(v = .25, col = "blue", lty = 3L)
  graphics::matplot(embedding[, 1L], embedding[, 2L],
                    xlab = "x(t)", ylab = "x(t-2)",
                    main = "Delay embedding coordinates", pch = 16)
  graphics::image(net$adjacency * 1, axes = FALSE,
                  xlab = "Sample", ylab = "Sample",
                  main = "Undirected binary recurrence graph adjacency")
  graphics::hist(screen$calibration$score, breaks = 8L,
                 xlab = "Frozen-model reconstruction residual",
                 main = "Split-conformal calibration scores")
  graphics::abline(v = screen$cutoff$threshold, col = "firebrick", lwd = 2L)
}, finally = grDevices::dev.off())
summary <- data.frame(
  measure = c("n_curves", "registration_landmark_target",
              "network_edges", "network_transitivity",
              "delay_embedding_rows", "poincare_events",
              "conformal_calibration_n", "conformal_threshold",
              "number_test_anomaly_flags", "optional_R_packages_installed"),
  value = c(n, .25, net$n_edges, net$transitivity,
            nrow(embedding), length(return_events$crossing_times),
            screen$cutoff$n_calibration, screen$cutoff$threshold,
            sum(screen$test$is_anomaly),
            sum(etr_r_backend_catalog()$installed))
)
utils::write.csv(summary, file.path(out, "summary.csv"), row.names = FALSE)
writeLines(c(
  "Research-only demonstration; synthetic data, no Python.",
  paste("UTC:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  "No scientifically calibrated simultaneous functional-band inference.",
  "Conformal marginal guarantee requires independent exchangeable curves.",
  "The plotted recurrence network is based on time-sample nodes.",
  "Prespecified registration is not elastic/SRVF registration."
), file.path(out, "MANIFEST.txt"))
print(summary, row.names = FALSE)
cat("Wrote native research demo: ", normalizePath(out, winslash = "/"), "\n")
