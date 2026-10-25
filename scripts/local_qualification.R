# Run from the cloned eyetrajectories repository root:
# Rscript scripts/local_qualification.R
#
# Executes real R tests and R CMD check on the user's local R installation.
# It does NOT install packages, execute Python automatically, publish, or
# claim any scientific calibration.
if (!file.exists("DESCRIPTION") ||
    !grepl("^Package: eyetrajectories$", readLines("DESCRIPTION")[1L])) {
  stop("Run from the eyetrajectories repository root.", call. = FALSE)
}
needed <- c("testthat", "pkgload", "rcmdcheck", "reticulate")
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Missing packages: ", paste(missing, collapse = ", "),
       ". Install locally using install.packages(c(",
       paste(sprintf('"%s"', missing), collapse = ", "), ")).",
       call. = FALSE)
}
root <- normalizePath(".")
report_dir <- file.path(dirname(root), "eyetrajectories_local_qualification")
dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)
stamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
writeLines(c(
  "eyetrajectories local qualification — real R execution",
  paste("Started:", stamp),
  paste("Source:", root),
  paste("R:", R.version.string),
  paste("Version:", read.dcf("DESCRIPTION", fields = "Version")[1L]),
  paste("OS:", paste(Sys.info()[c("sysname", "release", "machine")], collapse = " ")),
  paste("fdapace installed:", requireNamespace("fdapace", quietly = TRUE)),
  paste("refund installed:", requireNamespace("refund", quietly = TRUE)),
  "No GitHub Actions or CRAN publication is performed."
), file.path(report_dir, "manifest.txt"))
capture.output(sessionInfo(), file = file.path(report_dir, "sessionInfo.txt"))

# Keep test and check stages separate so failures are not hidden.
cat("\n== testthat tests (offline R native plus any installed optional R packages) ==\n")
prior_sinks <- sink.number()
test_error <- tryCatch({
  sink(file.path(report_dir, "testthat.txt"), split = TRUE)
  testthat::test_local(".", reporter = "summary", stop_on_failure = TRUE)
  NULL
}, error = function(e) conditionMessage(e),
   finally = {
     while (sink.number() > prior_sinks) sink()
   })
cat("\n== R CMD check (build package, no PDF manual) ==\n")
check_error <- NULL
check <- tryCatch(
  rcmdcheck::rcmdcheck(path = root, args = "--no-manual",
                      error_on = "never", quiet = FALSE),
  error = function(e) {
    check_error <<- conditionMessage(e)
    NULL
  }
)
if (!is.null(check)) {
  capture.output(print(check), file = file.path(report_dir, "R-CMD-check.txt"))
  check_errors <- length(check$errors)
  check_warnings <- length(check$warnings)
  check_notes <- length(check$notes)
} else {
  check_errors <- NA_integer_; check_warnings <- NA_integer_
  check_notes <- NA_integer_
  writeLines(check_error, file.path(report_dir, "R-CMD-check.txt"))
}
result <- c(
  paste("testthat:", if (is.null(test_error)) "PASS" else paste("FAIL:", test_error)),
  paste("R CMD check errors:", check_errors),
  paste("R CMD check warnings:", check_warnings),
  paste("R CMD check notes:", check_notes),
  paste("R CMD check launch error:", if (is.null(check_error)) "none" else check_error),
  paste("Output directory:", report_dir)
)
writeLines(result, file.path(report_dir, "SUMMARY.txt"))
cat("\n", paste(result, collapse = "\n"), "\n", sep = "")
if (!is.null(test_error) || !is.null(check_error) ||
    is.na(check_errors) || check_errors > 0L || check_warnings > 0L) {
  stop("Local qualification did not pass. Inspect and share SUMMARY.txt, ",
       "testthat.txt and R-CMD-check.txt for fixes.", call. = FALSE)
}
cat("Local R test/check stages completed without errors or warnings.\n",
    "Check NOTES and scientific validation separately before release.\n", sep = "")
