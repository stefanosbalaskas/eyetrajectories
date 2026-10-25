# Optional publication-style ggplot2 gallery, entirely R-native.
# Run from eyetrajectories source root:
# install.packages("ggplot2")
# source("scripts/run_native_ggplot_gallery.R")
#
# Outputs: artifacts/native_ggplot_gallery/
# This script is development-only; ggplot2 is NOT a required package dependency.
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION", fields = "Package")[1L]) != "eyetrajectories")
  stop("Run from the eyetrajectories repository root.", call. = FALSE)
if (!requireNamespace("ggplot2", quietly = TRUE))
  stop("Install optional plotting library: install.packages('ggplot2')",
       call. = FALSE)
if (!requireNamespace("pkgload", quietly = TRUE))
  stop("Install pkgload: install.packages('pkgload')", call. = FALSE)

# Reuse exactly the same deterministic generated datasets and estimates as
# the previously qualified base-R worked gallery. No Python is imported.
generation <- new.env(parent = globalenv())
sys.source("scripts/run_native_worked_gallery.R", envir = generation)
out <- file.path("artifacts", "native_ggplot_gallery")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
library_version <- as.character(utils::packageVersion("ggplot2"))
style <- function(p) {
  p + ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 13),
      plot.subtitle = ggplot2::element_text(size = 10),
      plot.caption = ggplot2::element_text(size = 9),
      panel.grid.minor = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(14, 20, 14, 20)
    )
}

# Figure 1: Horizontal category labels avoid the base R clipping issue.
variance <- generation$multi_var
variance$label <- factor(
  gsub("_", " ", variance$stratum, fixed = TRUE),
  levels = rev(gsub("_", " ", variance$stratum, fixed = TRUE))
)
p1 <- style(
  ggplot2::ggplot(variance,
                  ggplot2::aes(x = label, y = integrated_variance)) +
    ggplot2::geom_col(width = .55, fill = "#2C6E91") +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = "Between- and within-participant variation",
      subtitle = "Descriptive two-level FPCA; 20 simulated participants",
      x = NULL, y = "Integrated sample variance",
      caption = "This is not an inferential variance-component estimate."
    )
)

band_frame <- function(fit, kind) {
  est <- if (kind == "mean") fit$mean else fit$difference
  data.frame(
    time = fit$time,
    estimate = est[, 1L],
    lower = fit$simultaneous_lower[, 1L],
    upper = fit$simultaneous_upper[, 1L]
  )
}
band_plot <- function(dat, title, subtitle) {
  style(
    ggplot2::ggplot(dat, ggplot2::aes(x = time, y = estimate)) +
      ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper),
                           fill = "#A9D1DE", alpha = .58) +
      ggplot2::geom_line(color = "#164A70", linewidth = .8) +
      ggplot2::geom_hline(yintercept = 0, linetype = "dotted",
                          color = "grey60", linewidth = .35) +
      ggplot2::labs(title = title, subtitle = subtitle,
                     x = "Normalized time", y = "x channel",
                     caption = paste(
                       "Experimental simultaneous bootstrap band;",
                       "nominal coverage is not established."
                     ))
  )
}
p2 <- band_plot(
  band_frame(generation$mean_band, "mean"),
  "Participant-level functional mean",
  "Cluster bootstrap; 20 independent simulated participants"
)
p3 <- band_plot(
  band_frame(generation$contrast, "contrast"),
  "Between-group functional contrast",
  "Cluster bootstrap; 12 independent simulated participants per group"
)

# Figure 4: Exposure support from observed times only.
support <- generation$support$support
p4 <- style(
  ggplot2::ggplot(
    support, ggplot2::aes(x = factor(bin), y = fraction_observed)) +
    ggplot2::geom_col(fill = "#2C6E91", width = .72) +
    ggplot2::coord_cartesian(ylim = c(0, 1)) +
    ggplot2::labs(title = "Sparse sampling coverage",
                   subtitle = "35 simulated sparse curves; 10 time bins",
                   x = "Time-support bin",
                   y = "Fraction of participants observed",
                   caption = "Observed support only: no interpolation or imputation.")
)

# Figure 5: The observed TE can lie far to the right of all surrogates.
# Do NOT draw a misleading red line at the edge or silently clip it.
te <- generation$te
surrogates <- data.frame(transfer_entropy_bits = te$null_bits)
max_null <- max(te$null_bits)
observed_label <- sprintf(
  "Observed = %.4f bits | surrogate maximum = %.4f bits",
  te$observed_bits, max_null
)
p5 <- style(
  ggplot2::ggplot(surrogates,
                  ggplot2::aes(x = transfer_entropy_bits)) +
    ggplot2::geom_histogram(
      bins = 14L, fill = "#2C6E91",
      color = "white", linewidth = .2) +
    ggplot2::labs(
      title = "Transfer-entropy shift sensitivity",
      subtitle = observed_label,
      x = "Circular-shift surrogate transfer entropy (bits)",
      y = "Number of surrogates",
      caption = paste(
        "Observed statistic may be outside the histogram's x-range.",
        "The diagnostic p-value is descriptive, not causal inference."
      )
    )
)
plots <- list(
  "01_multilevel_variance" = p1,
  "02_participant_mean_band" = p2,
  "03_group_contrast_band" = p3,
  "04_sparse_support" = p4,
  "05_transfer_entropy_surrogates" = p5
)
pdf_file <- file.path(out, "native_ggplot_gallery.pdf")
grDevices::pdf(pdf_file, width = 9, height = 6.5, onefile = TRUE)
plot_error <- NULL
tryCatch({
  for (p in plots) print(p)
}, error = function(e) plot_error <<- conditionMessage(e),
finally = grDevices::dev.off())
if (!is.null(plot_error)) {
  stop("ggplot2 PDF gallery failed: ", plot_error, call. = FALSE)
}
for (name in names(plots)) {
  ggplot2::ggsave(
    filename = file.path(out, paste0(name, ".png")),
    plot = plots[[name]],
    width = 9, height = 6.5, units = "in", dpi = 200
  )
}
metrics <- generation$metrics
utils::write.csv(metrics, file.path(out, "native_ggplot_summary.csv"),
                 row.names = FALSE)
writeLines(c(
  "Native R + optional ggplot2 scientific figure gallery.",
  paste("UTC:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste("Package source version:",
        unname(read.dcf("DESCRIPTION", fields = "Version")[1L])),
  paste("ggplot2 version:", library_version),
  "Datasets and estimator fits are shared with run_native_worked_gallery.R.",
  "No Python import, no empirical gaze data.",
  "Experimental bands have known small-cluster undercoverage.",
  sprintf("Observed TE=%.9f, maximum shift surrogate=%.9f",
          te$observed_bits, max_null),
  "Observed TE outside null histogram support is printed in its subtitle.",
  "Transfer entropy shift p is descriptive, NOT causal evidence."
), file.path(out, "MANIFEST.txt"))
stopifnot(file.exists(pdf_file), file.info(pdf_file)$size > 0L,
          length(list.files(out, pattern = "\\.png$")) == 5L)
cat("ggplot2 gallery PASS; figures saved under: ",
    normalizePath(out, winslash = "/"), "\n", sep = "")
cat("PDF: ", normalizePath(pdf_file, winslash = "/"), "\n", sep = "")
