# Build reproducible native R synthetic figures for the pkgdown website.
# Uses existing package-owned data/estimators; Python is not imported.
# Run from eyetrajectories repository root with pkgload and ggplot2 installed.
if (!file.exists("DESCRIPTION") ||
    unname(read.dcf("DESCRIPTION", fields = "Package")[1L]) != "eyetrajectories") {
  stop("Run from eyetrajectories package root.", call. = FALSE)
}
if (!requireNamespace("pkgload", quietly = TRUE) ||
    !requireNamespace("ggplot2", quietly = TRUE)) {
  stop("Install optional pkgload and ggplot2 to generate the website gallery.")
}
source("scripts/run_native_ggplot_gallery.R", local = new.env(parent = globalenv()))
stems <- c("01_multilevel_variance", "02_participant_mean_band",
           "03_group_contrast_band", "04_sparse_support",
           "05_transfer_entropy_surrogates")
input <- file.path("artifacts/native_ggplot_gallery", paste0(stems, ".png"))
if (!all(file.exists(input)) || !all(file.info(input)$size > 1024)) {
  stop("Five native R figures must exist and contain non-empty PNG data.")
}
dest <- "pkgdown/assets/gallery"
dir.create(dest, recursive = TRUE, showWarnings = FALSE)
if (!all(file.copy(input, file.path(dest, basename(input)), overwrite = TRUE))) {
  stop("Cannot copy the scientific figures into pkgdown/assets/gallery.")
}
stopifnot(all(file.exists(file.path(dest, basename(input)))))
message("PKGDOWN_SYNTHETIC_GALLERY_PASS: five native R figures.")
