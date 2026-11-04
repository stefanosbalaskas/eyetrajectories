# Stage and R CMD build/check the proposed release directly from RStudio.
# Run at the root of the eyetrajectories checkout:
# source("scripts/stage_local_release_candidate.R")
# The candidate stays in a sibling folder, NOT in the Git checkout.
# Never tags, uploads, merges, certifies contracts, or publishes the package.
if (!file.exists("DESCRIPTION") ||
    !file.exists("scripts/stage_local_release_candidate.py"))
  stop("Run this entrypoint from eyetrajectories repository root.",
       call. = FALSE)
# Fail before a costly staged tarball build if any tracked Rd manual is
# malformed or two pages advertise the same alias. Do not suppress warnings.
source("scripts/preflight_rd_manuals.R", local = TRUE)
py <- Sys.getenv("ET_LOCAL_MATRIX_PYTHON", unset = "")
if (!nzchar(py)) py <- Sys.which("python")
if (!nzchar(py))
  stop("Python 3.12+ executable not found.", call. = FALSE)
r_command <- file.path(R.home(), "bin",
  if (.Platform$OS.type == "windows") "R.exe" else "R")
if (!file.exists(r_command))
  r_command <- Sys.which("R")
if (!nzchar(r_command) || !file.exists(r_command))
  stop("Cannot locate the running R installation's R executable.",
       call. = FALSE)
version <- Sys.getenv("ET_CANDIDATE_VERSION", unset = "0.4.2")
args <- c(shQuote("scripts/stage_local_release_candidate.py"),
          "--version", shQuote(version), "--build-check",
          "--r-command", shQuote(r_command))
stage_dir <- Sys.getenv("ET_CANDIDATE_OUTPUT_DIR", unset = "")
if (nzchar(stage_dir))
  args <- c(args, "--output-dir", shQuote(stage_dir))
cat("STAGING_VERSION=", version, "\nR_EXECUTABLE=", r_command,
    "\n", sep = "")
exit_code <- system2(py, args = args, stdout = "", stderr = "")
if (!identical(as.integer(exit_code), 0L))
  stop("Candidate staging or its R CMD build/check FAILED; inspect the",
       " sibling eyetrajectories_release_staging log. No release occurred.",
       call. = FALSE)
cat("LOCAL_RELEASE_CANDIDATE_BUILD_CHECK_COMPLETED;",
    " candidate still on manual HOLD, no publication.\n")
