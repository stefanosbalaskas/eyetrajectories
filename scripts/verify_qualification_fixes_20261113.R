# Targeted regression smoke for the 13 November 2026 qualification repairs.
# From the package root:
#   source("scripts/verify_qualification_fixes_20261113.R")
# To also run frozen Python oracles, set ET_RUN_PYTHON_TESTS=true and configure
# RETICULATE_PYTHON to a Python with eyetrajectoriespy==1.2.0 first.
#
# This is a test runner only, NOT an independent scientific certification.
if (!file.exists("DESCRIPTION") || !dir.exists("tests/testthat"))
  stop("Run from eyetrajectories package root", call. = FALSE)

source("scripts/preflight_native_source_syntax.R")
source("scripts/preflight_rd_manuals.R")

if (!requireNamespace("pkgload", quietly = TRUE) ||
    !requireNamespace("testthat", quietly = TRUE))
  stop("Install pkgload and testthat before running the patch smoke",
       call. = FALSE)

python_mode <- identical(Sys.getenv("ET_RUN_PYTHON_TESTS"), "true")
if (python_mode) {
  if (!requireNamespace("reticulate", quietly = TRUE))
    stop("Frozen Python mode requires reticulate", call. = FALSE)
  if (!nzchar(Sys.getenv("RETICULATE_PYTHON")))
    stop("Pin RETICULATE_PYTHON to the frozen Python 1.2 environment",
         call. = FALSE)
  Sys.setenv(MPLBACKEND = "Agg")
}
pkgload::load_all(".", quiet = TRUE)
if (python_mode)
  stopifnot(identical(et_python_version(), "1.2.0"))

filters <- c(
  "native-fpca-three-uncertainty-artists-20261112",
  "native-fpcr-two-prediction-artists-20261112",
  "native-mixed-residual-comparison",
  "native-sparse-fpca-w2-workflow-strict-20261112",
  "native-fpcr-two-cv-strict-source-20261112",
  "native-five-nonlinear-te-sensitivity-artists-20261112",
  "native-three-fpcr-cv-truncation-artists-20261112",
  "native-simulation-three-artist-source-20261112",
  "native-wild-two-scientific-artists-20261112",
  "native-fpca-three-source-artists-20261112",
  "native-environment-scientific-crosswalk-20261112",
  "native-source-contract-gaps",
  "native-nine-scientific-plots",
  "native-fdapy-ufpca-ps-lp-source-20261112"
)
cat("PATCH_SMOKE_MODE=", if (python_mode) "PYTHON_1_2" else "NATIVE_R",
    "\n", sep = "")
cat("PATCH_SMOKE_FILTER=", paste(filters, collapse = "|"), "\n", sep = "")
if(python_mode) {
  # SummaryReporter reports only the first ten failures. Use a reporter
  # honoring the configurable failure limit for scientific diagnostics.
  options(testthat.progress.max_fails=200L)
  Sys.setenv(TESTTHAT_MAX_FAILS="200")
  cat("PATCH_SMOKE_FAILURE_CAP=200; reporter=progress\n")
}
testthat::test_local(
  ".",
  filter = paste(filters, collapse = "|"),
  reporter = if(python_mode) "progress" else "summary",
  stop_on_failure = TRUE
)
cat("PATCH_SMOKE_PASS; independent_scientific_certification=FALSE\n")
