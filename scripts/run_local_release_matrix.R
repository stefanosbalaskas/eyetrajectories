# RStudio entrypoint. Execute from the eyetrajectories repository root:
# source("scripts/run_local_release_matrix.R")
# Optional: Sys.setenv(ET_LOCAL_TARGETS="host,wsl,docker")
# Optional: Sys.setenv(ET_LOCAL_DOCKER_IMAGE="your-prebuilt-R-image")
if (!file.exists("DESCRIPTION") || !file.exists("scripts/run_local_release_matrix.py"))
  stop("Run the local matrix entrypoint from the package root", call. = FALSE)
py <- Sys.getenv("ET_LOCAL_MATRIX_PYTHON", unset = "")
if (!nzchar(py)) py <- Sys.which("python")
if (!nzchar(py)) stop("Install Python for the stdlib-only local matrix orchestrator", call. = FALSE)
args <- c(shQuote("scripts/run_local_release_matrix.py"),
          "--targets", shQuote(Sys.getenv("ET_LOCAL_TARGETS", "host")),
          "--rscript", shQuote(file.path(R.home("bin"),
            if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")))
image <- Sys.getenv("ET_LOCAL_DOCKER_IMAGE", "")
if (nzchar(image)) args <- c(args, "--docker-image", shQuote(image))
distro <- Sys.getenv("ET_LOCAL_WSL_DISTRO", "")
if (nzchar(distro)) args <- c(args, "--wsl-distribution", shQuote(distro))
if (identical(Sys.getenv("ET_REQUIRE_PYTHON312", "false"), "true"))
  args <- c(args, "--require-python312")
code <- system2(py, args = args, stdout = "", stderr = "")
if (!identical(as.integer(code), 0L))
  stop("Local release matrix FAILED or has unexecuted requested targets; review matrix_results.json", call. = FALSE)
cat("Local release matrix completed; see sibling eyetrajectories_local_matrix directory.\n")
