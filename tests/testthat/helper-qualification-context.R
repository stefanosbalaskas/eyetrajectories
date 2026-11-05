# Data fixtures live under inst/extdata in the source tree, and extdata
# in an installed package. Never silently skip missing packaged fixtures.
.etr_test_extdata <- function(filename) {
  if (!is.character(filename) || length(filename) != 1L ||
      is.na(filename) || !nzchar(filename) ||
      basename(filename) != filename)
    stop("Expected a single extdata fixture basename", call. = FALSE)
  root <- testthat::test_path("..", "..")
  source_path <- file.path(root, "inst", "extdata", filename)
  if (file.exists(file.path(root, "DESCRIPTION")) &&
      file.exists(source_path)) return(source_path)
  installed <- system.file("extdata", filename,
    package = "eyetrajectories", mustWork = FALSE)
  if (!nzchar(installed) || !file.exists(installed))
    stop("Missing required installed extdata fixture: ", filename,
         call. = FALSE)
  installed
}

# Repository-script regressions are mandatory in BOTH source checkout
# qualification modes. Installed R CMD check cannot access excluded scripts.
.etr_require_developer_checkout <- function() {
  root <- testthat::test_path("..", "..")
  required <- c(file.path(root, "DESCRIPTION"),
    file.path(root, "scripts",
      "capture_native_source_qualification_evidence.R"))
  if (!all(file.exists(required)))
    testthat::skip(paste(
      "SOURCE_CHECKOUT_ONLY: mandatory developer-script regression is run",
      "in both native/Python scientific qualification modes;",
      "the installed CRAN package excludes repository scripts"))
  invisible(root)
}
