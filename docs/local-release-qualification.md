# Local release qualification and staging (GitHub Actions independent)

## Verified baseline and limits

The maintainer's Windows 11 / R 4.6.1 run at
e58b0246c3e9fabb25ba68318a137322d2d6a9c8 passed an actual
R CMD check --as-cran with **0 errors / 0 warnings / 1 NOTE**, native smoke,
native offline scientific qualification and pinned Python 1.2 direct-source
scientific qualification. This baseline DOES NOT automatically apply to later
commits. Repository issue #3 still blocks hosted GitHub Actions jobs.

This tooling never merges PR #48, tags, publishes, submits to CRAN, or creates
independent 508-export certification approvals.

## Windows RStudio: exact-head host qualification

From the clean repository root:

    system("git pull --ff-only")
    source("scripts/run_local_release_matrix.R")

The RStudio entrypoint calls Python's standard-library local orchestrator with
your currently selected Rscript. The child R process runs the existing full
scripts/qualify_experimental_candidate.R, which includes a real source-build
R CMD check and BOTH scientific qualification modes. A missing or failed
process, incomplete R CMD check final Status/* DONE marker, dirty checkout,
network-aborted CRAN incoming check or mismatched commit fails closed.
Full logs, SHA256 hashes, result JSON/CSV and exact Git HEAD are written OUTSIDE
the source checkout, under sibling eyetrajectories_local_matrix/. One or more
NOTEs return PASS_WITH_NOTE_REVIEW, NOT automatic publication approval.

Direct Windows CLI (adjust R path to your installed version):

    python scripts/run_local_release_matrix.py --targets host --rscript "C:\Program Files\R\R-4.6.1\bin\Rscript.exe"

For several installed R versions repeat --rscript with distinct executables.

## Explicit Python 3.12 interpreter check

The frozen Python package version (eyetrajectoriespy 1.2.0) does not imply
Python interpreter 3.12. Set RETICULATE_PYTHON to the real Python 3.12
executable before R initializes reticulate. Then in RStudio:

    Sys.setenv(ET_REQUIRE_PYTHON312="true")
    source("scripts/run_local_release_matrix.R")

The child R process inspects reticulate::py_config() and fails if its selected
interpreter is not Python 3.12. The full scientific qualification follows.

## Optional WSL2 and Docker on your Windows machine

For WSL2, first provision Ubuntu/other WSL2 with R, needed package libraries,
Python, pinned eyetrajectoriespy and the PDF manual dependencies. Then:

    Sys.setenv(ET_LOCAL_TARGETS="host,wsl", ET_LOCAL_WSL_DISTRO="Ubuntu")
    source("scripts/run_local_release_matrix.R")

The orchestrator invokes wsl.exe, converts the checkout path with wslpath and
runs the same full qualification using Linux Rscript. The evidence is separate.
A missing WSL distribution is BLOCKED_NOT_EXECUTED, never PASS.
The precise WSL launch error is printed as LOCAL_MATRIX_BLOCKED_REASON
and preserved under matrix_results.json. Check `wsl --list --verbose`
from PowerShell or `system2("wsl.exe", c("--list", "--verbose"))`
from RStudio before configuring a Linux target. A native Linux
filesystem checkout is preferable for final filesystem-fidelity checking.

Docker requires an explicitly prebuilt image containing the needed R,
TeX/PDF, Python and R dependencies. The runner does not pull/install them and
disables container networking during qualification:

    Sys.setenv(ET_LOCAL_TARGETS="host,docker",
               ET_LOCAL_DOCKER_IMAGE="your-prebuilt-r-image:tag")
    source("scripts/run_local_release_matrix.R")

The parent directory of the checkout is mounted for CRAN logs. Missing Docker
or required dependencies must fail, not silently skip. A Windows and Linux
matrix does not establish macOS compatibility; real macOS validation remains
an external gate.

## Stage an UNVERIFIED 0.4.2 candidate from Git HEAD

**From RStudio's R console**, use R syntax (not the Python shell command):

    Sys.unsetenv(c("ET_LOCAL_TARGETS", "ET_LOCAL_WSL_DISTRO"))
    source("scripts/stage_local_release_candidate.R")

This uses the current R installation, creates the separate stage, builds
its tarball and performs actual R CMD check. A CRAN network timeout now
fails the qualification rather than producing a false CLEAN PASS. To use
Python shell commands directly, enter them in PowerShell/Terminal, not
after the R `>` prompt.



After exact-head evidence and review of the limited experimental scope:

    python scripts/stage_local_release_candidate.py --version 0.4.2 --build-check --r-command "C:\Program Files\R\R-4.6.1\bin\R.exe"

The Python 3.12+ staging helper creates an isolated sibling folder
eyetrajectories_release_staging/, sources a clean git archive, and edits
DESCRIPTION/README/NEWS in the staged copy only. With --build-check, it runs
a real R CMD build and --as-cran check on the staged source tarball and hashes
the resulting tarball; without the option, candidate checking is NOT EXECUTED. The development source branch
remains at version 0.4.1.9000. A separate STAGING_MANIFEST.json records the
original SHA and explicitly reports candidate_check=NOT EXECUTED,
candidate_release_status=HOLD. This script does NOT build or upload anything.

In the generated staging directory, using your local terminal:

    R CMD build eyetrajectories
    R CMD check --as-cran eyetrajectories_0.4.2.tar.gz

This checks the actual candidate TARBALL, not the previous development
checkout. Re-run pinned scientific suites against candidate code, review
the remaining first-submission NOTE, validate cross-platform dependencies
and licensing, and obtain maintainer approval before promotion or submission.
No 508-contract source parity or independent reviewer decision is inferred.

## Orchestration unit tests

    python -m unittest discover -s scripts/tests -p "test_local_release_*.py" -v

These unit tests check orchestration, not native R scientific algorithms or
R CMD check. External scientific certification remains explicitly unsigned.
