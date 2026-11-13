# Windows-safe opt-in frozen Python 1.2 / native R differential qualification.
#
# START A FRESH R SESSION before using this launcher:
#   RStudio > Session > Restart R
#   source("scripts/verify_qualification_managed_python_20261113.R")
#
# Reticulate on Windows cannot necessarily embed the Microsoft Store copy of
# Python, even when a project venv points at its python.exe; WindowsApps
# python311.dll may be protected. This launcher explicitly forces reticulate's
# uv-managed Python 3.12 and its frozen source dependency requirements.
#
# IMPORTANT: A managed environment will download Python/packages if not cached.
# Native R tests alone were already validated separately. This remains a
# differential regression check, NOT independent scientific certification.

if(!file.exists("DESCRIPTION")||!dir.exists("tests/testthat"))
  stop("Run from the eyetrajectories repository root",call.=FALSE)
if(!requireNamespace("reticulate",quietly=TRUE))
  stop("Install reticulate >= 1.41 with install.packages('reticulate')",
    call.=FALSE)
if(utils::packageVersion("reticulate")<"1.41")
  stop("Managed Python launcher requires reticulate >= 1.41; update with install.packages('reticulate')",
    call.=FALSE)

# Do NOT set a Windows Store venv path: the managed sentinel takes precedence
# over the stale RETICULATE_PYTHON value from earlier console commands.
Sys.setenv(
  RETICULATE_PYTHON="managed",
  RETICULATE_USE_MANAGED_VENV="yes",
  ET_RUN_PYTHON_TESTS="true",
  ET_RUN_PYTHON_ELASTIC_TESTS="false",
  MPLBACKEND="Agg"
)

# py_require must precede the FIRST Python initialization in this R process.
# Use 3.12 rather than Store 3.11. Optional "all" covers FDApy, scikit-fda,
# fdasrsf and other backends used by the direct scientific source oracles.
reticulate::py_require(
  packages=c(
    "eyetrajectoriespy[all]==1.2.0",
    "numpy==1.26.4",
    "FDApy==1.0.3"
  ),
  python_version="3.12"
)

# Source checkout now includes a compiled LAPACK bridge to reproduce
# NumPy DGEEV eigenpair order. On Windows, building it requires Rtools
# matched to the running R installation (R 4.5/4.6 -> Rtools45).
if(.Platform$OS.type=="windows" && dir.exists("src") &&
   requireNamespace("pkgbuild",quietly=TRUE) &&
   !pkgbuild::has_build_tools(debug=FALSE))
  stop("EyeTrajectories now needs the compatible Windows Rtools compiler ",
    "for its native LAPACK DGEEV bridge. See ",
    "https://cran.r-project.org/bin/windows/Rtools/ ",
    "and rerun after installing Rtools.",call.=FALSE)

config<-tryCatch(reticulate::py_config(),error=function(e)
  stop("Managed Python initialization failed: ",conditionMessage(e),
    "\nIf Python was initialized before this launcher, restart R first. ",
    "Otherwise inspect corporate proxy/network/security restrictions ",
    "on uv Python and wheel downloads.",call.=FALSE))
if(grepl("windowsapps",paste(config$python,config$libpython),
    ignore.case=TRUE))
  stop("Managed Python did not replace the protected Microsoft Store interpreter. ",
    "Restart R and run this launcher before any Python/reticulate imports.",
    call.=FALSE)
cat("FROZEN_PYTHON_INTERPRETER=",config$python,"\n",sep="")
cat("FROZEN_PYTHON_LIBRARY=",config$libpython,"\n",sep="")
if(!identical(as.character(reticulate::import("eyetrajectoriespy",
    convert=FALSE)$`__version__`),"1.2.0"))
  stop("Resolved Python is not the frozen eyetrajectoriespy 1.2.0",call.=FALSE)
cat("FROZEN_PYTHON_PACKAGE=1.2.0\n")
source("scripts/verify_qualification_fixes_20261113.R")
