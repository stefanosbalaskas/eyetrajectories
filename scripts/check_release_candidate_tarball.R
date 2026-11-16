# This file runs only in release candidate GitHub Actions (scripts/ is
# excluded from the CRAN tarball); validates the exact downloaded archive.
if (!requireNamespace("rcmdcheck", quietly = TRUE)) {
  stop("rcmdcheck must be installed to qualify a CRAN source tarball.")
}
if (!requireNamespace("V8", quietly = TRUE)) {
  stop("V8 must be installed so CRAN HTML mathematics checks are executed.")
}
tarball <- file.path("candidate", "eyetrajectories_0.4.3.tar.gz")
if (!file.exists(tarball)) stop("Missing exact candidate tarball.")
expected_md5 <- trimws(readLines(file.path("candidate", "candidate.md5"), warn = FALSE))
actual_md5 <- unname(tools::md5sum(tarball))
if (length(expected_md5) != 1L || !identical(actual_md5, expected_md5)) {
  stop("Downloaded tarball failed source checksum verification.")
}

cat("RELEASE_CANDIDATE_TARBALL_MD5=", actual_md5, "\n", sep = "")
cat("RELEASE_CANDIDATE_COMMIT=", Sys.getenv("GITHUB_SHA"), "\n", sep = "")
cat("RELEASE_CANDIDATE_R=", R.version.string, "\n", sep = "")
cat("RELEASE_CANDIDATE_PLATFORM=", R.version$platform, "\n", sep = "")
dir.create("check-outputs", showWarnings = FALSE)
on.exit({
  if (dir.exists("check-outputs")) {
    ff <- list.files("check-outputs", recursive = TRUE)
    message("Checking files present: ", length(ff))
  }
}, add = TRUE)

check_start <- proc.time()[["elapsed"]]
candidate <- rcmdcheck::rcmdcheck(
  path = normalizePath(tarball, winslash = "/", mustWork = TRUE),
  args = "--as-cran", check_dir = "check-outputs",
  quiet = FALSE, error_on = "never", timeout = 45 * 60
)
check_elapsed_seconds <- unname(proc.time()[["elapsed"]] - check_start)
cat("CHECK_ELAPSED_SECONDS=", round(check_elapsed_seconds, 1), "\\n", sep = "")
summary <- c(
  paste("Candidate archive:", basename(tarball)),
  paste("SHA256: see candidate.sha256"),
  paste("MD5:", actual_md5),
  paste("Git commit:", Sys.getenv("GITHUB_SHA")),
  paste("R version:", R.version.string),
  paste("Platform:", R.version$platform),
  paste("Errors:", length(candidate$errors)),
  paste("Warnings:", length(candidate$warnings)),
  paste("Notes:", length(candidate$notes)),
  paste("Check elapsed seconds:", round(check_elapsed_seconds, 1)),
  paste("Note contents:", paste(candidate$notes, collapse = " | "))
)
writeLines(summary, file.path("check-outputs", "RELEASE-CANDIDATE-SUMMARY.txt"))
cat(paste(summary, collapse = "\n"), "\n")
if (length(candidate$errors) || length(candidate$warnings)) {
  stop("Source tarball does not pass R CMD check --as-cran without errors/warnings.")
}
unexpected_notes <- candidate$notes[!grepl("New submission", candidate$notes,
                                              fixed = TRUE)]
if (length(unexpected_notes)) {
  stop("Unexpected CRAN-style notes in exact candidate: ",
       paste(unexpected_notes, collapse = " | "))
}
if (.Platform$OS.type == "windows" &&
    check_elapsed_seconds >= 540) {
  stop("Windows CRAN pretest checktime guard failed: ",
       round(check_elapsed_seconds, 1),
       " seconds (need ample margin below CRAN 600-second threshold).")
}
cat("R_TARBALL_CRAN_CHECK_ZERO_ERROR_ZERO_WARNING_PASS\n")
