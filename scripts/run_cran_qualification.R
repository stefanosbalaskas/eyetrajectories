#!/usr/bin/env Rscript
# Full local CRAN-style check, including help examples and PDF manual.
# From the cloned repository root:
#   source("scripts/run_cran_qualification.R")
#
# Does not submit to CRAN, release, access GitHub Actions, or invoke Python.
# CRAN farms and reverse-dependency checks are NOT reproduced locally.
if (!file.exists("DESCRIPTION") ||
    !identical(unname(read.dcf("DESCRIPTION", fields = "Package")[1L]),
               "eyetrajectories")) {
  stop("Run from the root of the eyetrajectories source checkout.",
       call. = FALSE)
}
required <- c("rcmdcheck", "pkgload")
missing <- required[!vapply(required, requireNamespace,
                            logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Install the developer tools first: install.packages(c(",
       paste(sprintf('"%s"', missing), collapse = ", "), "))",
       call. = FALSE)
}
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
version <- unname(read.dcf("DESCRIPTION", fields = "Version")[1L])
run_id <- format(Sys.time(), "%Y%m%d_%H%M%S")
report_root <- file.path(dirname(root), "eyetrajectories_cran_qualification")
report <- file.path(report_root, paste0("R_", version, "_", run_id))
dir.create(report, recursive = TRUE, showWarnings = FALSE)
if (!dir.exists(report)) stop("Cannot create report directory.")
writeLines(c(
  "Local CRAN-style qualification, NOT a CRAN submission or pretest",
  paste("Run UTC:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste("Repository source:", root),
  paste("Source version:", version),
  paste("R:", R.version.string),
  paste("OS:", paste(Sys.info()[c("sysname", "release", "machine")],
                     collapse = " ")),
  paste("pdflatex:", if (nzchar(Sys.which("pdflatex")))
    Sys.which("pdflatex") else "NOT FOUND (full manual check may fail)"),
  paste("makeindex:", if (nzchar(Sys.which("makeindex")))
    Sys.which("makeindex") else "NOT FOUND (manual may fail)"),
  "Full R CMD check --as-cran; PDF manual is NOT skipped",
  "ET_RUN_PYTHON_TESTS=false (CRAN-safe; separate Python integration)",
  "DEV_SCRIPT_TESTS=SOURCE_CHECKOUT_ONLY; mandatory two-mode source qualification",
  "No source publication, no GitHub Actions and no CRAN upload"
), file.path(report, "MANIFEST.txt"))
capture.output(sessionInfo(), file = file.path(report, "sessionInfo.txt"))
sha <- tryCatch(
  system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE),
  error = function(e) "unknown"
)
if (!length(sha)) sha <- "unknown"
write(paste("Git HEAD:", sha[1L]), file = file.path(report, "MANIFEST.txt"),
      append = TRUE)

# CRAN-facing checks must never depend on optional Python installation,
# GUI plotting backends or online services. Opt-in Python tests are separate.
check_env <- c(ET_RUN_PYTHON_TESTS = "false",
               MPLBACKEND = "Agg",
               NOT_CRAN = "false")
cat("\n=== Fail-closed source-only test coverage ===\n")
source("scripts/preflight_source_checkout_coverage.R",local=TRUE)
cat("\n=== Fast full Rd-manual syntax preflight ===\n")
rd_preflight_error <- tryCatch({
  source("scripts/preflight_rd_manuals.R", local=TRUE)
  NULL
},error=function(e)conditionMessage(e))
cat("\n=== Packaged research test fixture integrity preflight ===\n")
fixture_preflight_error <- tryCatch({
  source("scripts/preflight_packaged_test_fixtures.R",local=TRUE)
  NULL
},error=function(e)conditionMessage(e))
check_error <- if (!is.null(rd_preflight_error)) {
  paste("Rd manual preflight failed:", rd_preflight_error)
} else if (!is.null(fixture_preflight_error)) {
  paste("Research fixture preflight failed:", fixture_preflight_error)
} else {
  NULL
}
cat("\n=== Full source-build R CMD check --as-cran ===\n")
check <- if(!is.null(check_error)) NULL else tryCatch(
  rcmdcheck::rcmdcheck(
    path = root,
    args = "--as-cran",
    quiet = FALSE,
    error_on = "never",
    env = check_env,
    check_dir = file.path(report, "check")
  ),
  error = function(e) {
    check_error <<- conditionMessage(e)
    NULL
  }
)
errors <- warnings <- notes <- NA_integer_
if (is.null(check)) {
  writeLines(if (is.null(check_error)) "Could not run R CMD check"
             else check_error, file.path(report, "RCMD-check-summary.txt"))
} else {
  errors <- length(check$errors)
  warnings <- length(check$warnings)
  notes <- length(check$notes)
  capture.output(print(check), file = file.path(report, "RCMD-check-summary.txt"))
  if (length(check$errors))
    writeLines(check$errors, file.path(report, "RCMD-errors.txt"))
  if (length(check$warnings))
    writeLines(check$warnings, file.path(report, "RCMD-warnings.txt"))
  if (length(check$notes))
    writeLines(check$notes, file.path(report, "RCMD-notes.txt"))
}
# Preserve logs even when rcmdcheck nests them beneath its check directory.
logs <- list.files(file.path(report, "check"), pattern = "^00check\\.log$",
                   recursive = TRUE, full.names = TRUE)
if (length(logs))
  file.copy(logs[1L], file.path(report, "00check.log"), overwrite = TRUE)

# rcmdcheck's parsed $errors/$warnings/$notes can be EMPTY even when
# R CMD check aborted (e.g., CRAN archive.rds network timeout). A zero count
# alone is never a successful completed check.
final_check_log_error <- NULL
final_check_log_status <- NA_character_
if (!is.null(check)) {
  if (length(logs) != 1L) {
    final_check_log_error <- paste0(
      "Expected exactly one 00check.log, found ", length(logs))
  } else {
    completed_log <- readLines(logs[[1L]], warn = FALSE,
                               encoding = "UTF-8")
    completed_marker <- any(grepl(
      "^\\* DONE[[:space:]]*$", completed_log))
    statuses <- grep("^Status:[[:space:]]*", completed_log, value = TRUE)
    required_phases <- c(
      "^\\* checking tests[[:space:]]",
      "^\\* checking examples[[:space:]]",
      "^\\* checking PDF version of manual[[:space:]]")
    missing_phases <- required_phases[!vapply(
      required_phases, function(pattern)
        any(grepl(pattern, completed_log)), logical(1L))]
    if (!completed_marker || length(statuses) != 1L ||
        length(missing_phases) ||
        !any(grepl("Running 'testthat.R'", completed_log,
                   fixed = TRUE))) {
      final_check_log_error <- paste(
        "R CMD check did NOT complete all mandatory phases:",
        paste(c(
          if (!completed_marker) "missing * DONE" else NULL,
          if (length(statuses) != 1L) "missing/ambiguous Status" else NULL,
          missing_phases,
          if (!any(grepl("Running 'testthat.R'", completed_log,
                         fixed = TRUE))) "testthat.R not executed" else NULL),
          collapse = "; "))
    } else {
      final_check_log_status <- sub(
        "^Status:[[:space:]]*", "", statuses[[1L]])
      if (!(identical(final_check_log_status, "OK") ||
            grepl("^[0-9]+ (ERROR|WARNING|NOTE)",
                  final_check_log_status)) ||
          !identical(grepl("ERROR", final_check_log_status, fixed = TRUE),
                     errors > 0L) ||
          !identical(grepl("WARNING", final_check_log_status, fixed = TRUE),
                     warnings > 0L) ||
          !identical(grepl("NOTE", final_check_log_status, fixed = TRUE),
                     notes > 0L))
        final_check_log_error <- paste(
          "Inconsistent R CMD check final status and rcmdcheck counts:",
          final_check_log_status,
          sprintf("E/W/N=%s/%s/%s", errors, warnings, notes))
    }
  }
}
if (!is.null(final_check_log_error)) {
  writeLines(final_check_log_error,
             file.path(report, "INCOMPLETE_R_CMD_CHECK.txt"))
  cat("R_CMD_CHECK_FINALITY=FAIL: ", final_check_log_error, "\n", sep = "")
} else if (!is.null(check)) {
  cat("R_CMD_CHECK_FINALITY=VERIFIED: ",
      final_check_log_status, "\n", sep = "")
}

# R CMD check prints only the final handful of testthat failures. Preserve
# the complete installed-package transcript, and write an exact diagnostic
# index with source filename/line for every failed expectation. Do not skip
# tests or change the R CMD check verdict.
test_logs <- list.files(file.path(report,"check"),
  pattern="^testthat\\.Rout(\\.fail)?$",
  recursive=TRUE,full.names=TRUE)
if(length(test_logs)){
  for(source_log in test_logs){
    dest<-file.path(report,paste0("INSTALLED_",basename(source_log)))
    file.copy(source_log,dest,overwrite=TRUE)
  }
  primary <- test_logs[!grepl("\\.fail$",test_logs)]
  if(!length(primary))primary<-test_logs
  test_lines<-readLines(primary[[1L]],warn=FALSE,encoding="UTF-8")
  failure_idx<-grep(
    "^[[:space:]]*(?:──|--|\\*\\*)[[:space:]]*(?:[0-9]+\\.|Failure|Error|Warning)",
    test_lines,perl=TRUE)
  # The source-path form also covers older testthat reporters.
  path_idx<-grep(
    "(test-[A-Za-z0-9_.-]+\\.R:[0-9]+:[0-9]+)",
    test_lines,perl=TRUE)
  locations<-sort(unique(c(failure_idx,path_idx)))
  window<-integer()
  for(i in locations)window<-c(window,seq.int(
    max(1L,i-1L),min(length(test_lines),i+8L)))
  if(!length(locations))
    window<-seq_len(min(length(test_lines),100L))
  file<-file.path(report,"INSTALLED_TEST_FAILURE_DETAILS.txt")
  writeLines(c("Exact R CMD check installed-package test log excerpts.",
    "Complete unedited transcript: INSTALLED_testthat.Rout",
    paste0("Test transcript lines: ",length(test_lines)),
    paste0("Diagnostic locations found: ",length(locations)),
    "",
    sprintf("%05d: %s",sort(unique(window)),test_lines[sort(unique(window))])),
    file,useBytes=TRUE)
  cat("R CMD check test transcript: ",normalizePath(
    file.path(report,paste0("INSTALLED_",basename(primary[[1L]]))),
    winslash="/",mustWork=FALSE),"\n",sep="")
  cat("R CMD check failure detail index: ",normalizePath(
    file,winslash="/",mustWork=TRUE),"\n",sep="")
}

# Run a separate real-native-use example on the source package.
# pkgload::load_all() gives the current checkout, not a stale installed version.
cat("\n=== Native R smoke example with figures ===\n")
example_error <- NULL
example_output <- file.path(report, "native_example")
dir.create(example_output, recursive = TRUE, showWarnings = FALSE)
old_example_dir <- Sys.getenv("ET_EXAMPLE_OUTPUT_DIR", unset = NA_character_)
Sys.setenv(ET_EXAMPLE_OUTPUT_DIR = example_output)
tryCatch({
  pkgload::load_all(root, quiet = TRUE)
  example_file <- file.path(root, "inst", "examples", "cran_native_smoke.R")
  sys.source(example_file, envir = new.env(parent = globalenv()))
}, error = function(e) {
  example_error <<- conditionMessage(e)
})
if (is.na(old_example_dir)) {
  Sys.unsetenv("ET_EXAMPLE_OUTPUT_DIR")
} else {
  Sys.setenv(ET_EXAMPLE_OUTPUT_DIR = old_example_dir)
}
if (!is.null(example_error))
  writeLines(example_error, file.path(report, "native_example_ERROR.txt"))

check_without_errors_or_warnings <- is.null(check_error) &&
  is.null(final_check_log_error) &&
  !is.na(errors) && errors == 0L && warnings == 0L
example_pass <- is.null(example_error)
check_status <- if (!is.null(rd_preflight_error)) {
  "FAIL - RD MANUAL PREFLIGHT"
} else if (!is.null(fixture_preflight_error)) {
  "FAIL - PACKAGED RESEARCH FIXTURE PREFLIGHT"
} else if (is.null(check)) {
  "FAIL - SOURCE BUILD (R CMD CHECK NOT RUN)"
} else if (!is.null(final_check_log_error)) {
  "FAIL - R CMD CHECK ABORTED OR INCOMPLETE"
} else if (!check_without_errors_or_warnings || !example_pass) {
  "FAIL"
} else if (!is.na(notes) && notes > 0L) {
  "PASS WITH NOTES - REVIEW REQUIRED"
} else {
  "CLEAN PASS"
}
summary <- c(
  paste("Package:", version),
  paste("CRAN-style check:", check_status),
  paste("R CMD check errors:", errors),
  paste("R CMD check warnings:", warnings),
  paste("R CMD check notes:", notes),
  paste("R CMD check finality:", if (is.null(final_check_log_error))
    final_check_log_status else paste("INVALID:", final_check_log_error)),
  paste("Native source example:",
        if (example_pass) "PASS" else paste("FAIL:", example_error)),
  paste("Report directory:", report),
  if (is.na(notes)) {
    "R CMD check was NOT COMPLETED; E/W/NOTE counts unavailable. This is NOT a clean check."
  } else if (notes > 0L) {
    "NOTE(s) require manual review. A clean package check is not CRAN acceptance."
  } else {
    "R CMD check completed with zero NOTES; this is not CRAN acceptance."
  },
  "Python integration intentionally disabled for CRAN-style stage.",
  "Cross-platform and scientific coverage qualification remain open."
)
writeLines(summary, file.path(report, "SUMMARY.txt"))
cat("\n", paste(summary, collapse = "\n"), "\n", sep = "")
if (!check_without_errors_or_warnings || !example_pass)
  stop("CRAN-style qualification incomplete or failed (Rd preflight, source build, check, or smoke). Review report files.",
       call. = FALSE)
cat("CRAN_VERDICT_CONFIRMED=PASS\n")
if (!is.na(notes) && notes > 0L) {
  cat("Local R CMD check completed without errors/warnings. NOTE(s) require manual review.\n")
} else {
  cat("Local CRAN-style R check and example passed without NOTES; not CRAN acceptance.\n")
}
