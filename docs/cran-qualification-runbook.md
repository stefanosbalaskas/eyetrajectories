# Local CRAN-style qualification (Windows RStudio)

This is a **pre-submission local audit**, not a CRAN submission, acceptance,
CRAN farm run or release. The package stays private. The existing finite-
sample coverage concerns remain unresolved independently of clean checks.

## One command

From a freshly pulled repository `main`, in RStudio with the package root
as its working directory, run:

```r
install.packages(c("rcmdcheck", "pkgload"))
source("scripts/run_cran_qualification.R")
```

The runner builds the source package, performs **R CMD check --as-cran**
without `--no-manual`, includes all Rd examples and installed tests, then
loads the exact source checkout for a native R numerical-and-plot smoke
example. It explicitly sets `ET_RUN_PYTHON_TESTS=false` and `MPLBACKEND=Agg`
in the CRAN-facing R CMD check process. The source version and Git HEAD
are recorded separately. On Windows, install TinyTeX or another functioning
TeX distribution (`pdflatex` and `makeindex` on PATH) for the PDF manual
check. If TeX is absent, the runner does **not** silently skip that stage.

The reports are stored outside the Git checkout at a timestamped path
under `../eyetrajectories_cran_qualification/`, including `SUMMARY.txt`,
`MANIFEST.txt`, `sessionInfo.txt`, an R CMD check summary and (when available)
`00check.log`, plus the example's output CSV and three-panel PDF.

## Fast example, without the full check

```r
pkgload::load_all(".", quiet = TRUE)
source("inst/examples/cran_native_smoke.R")
```

The script checks a long-format round trip, native MFPCA, distances,
recurrence quantification, shape invariants of an experimental participant
bootstrap band, and the 380-function API catalog. It writes a CSV and PDF
under `artifacts/cran_native_example/` in the repository for direct local
execution. A custom `ET_EXAMPLE_OUTPUT_DIR` takes precedence; outside the
project root the script falls back to the session's temporary directory.
The script prints both output file paths. The native example does **not** initialize Python.

## Optional Python integration, tested separately

Restart the R session before loading `reticulate` and run:

```r
Sys.setenv(ET_RUN_PYTHON_TESTS = "true", MPLBACKEND = "Agg")
testthat::test_local(".", filter = "etpy-all-functions|python-integration",
                     reporter = "summary")
library(eyetrajectories)
api_check <- etpy_verify_api(strict = TRUE)
table(api_check$available)
table(api_check$callable)
```

This optional stage may use a managed Python environment and download
dependencies; therefore it is deliberately **not** run by the CRAN-facing
stage. Passing structural Python export tests does not mean all 380 scientific
algorithms have been numerically validated independently.

## Interpretation

A **0 ERROR, 0 WARNING, 0 NOTE** local `--as-cran` result supports source-
package quality on the tested R/OS configuration. It does **not** certify
CRAN acceptance, CRAN incoming eligibility, all R versions, Linux/macOS
portability, external-service restrictions, reverse dependencies, or
scientific inference calibration. CRAN policy emphasizes quick examples
and avoiding network requirements when dependencies are unavailable.

CRAN package policy: https://cran.r-project.org/web/packages/policies.html
R CMD check documentation: https://cran.r-project.org/doc/manuals/r-release/R-exts.html

Do not publish or submit until the scientific HOLD status and cross-platform
matrix are independently reviewed.

## October 25 full-check findings and corrections

The first Windows 11 R 4.6.1 `R CMD check --as-cran` returned
0 errors, **1 warning** and **2 notes**, while Rd examples, PDF manual and
all tests passed. The native smoke generated all expected figures/CSV.
The warning arose from README Markdown conversion and nonstandard root
folders; the Rd note arose from very long \usage lines. Packaging now
excludes repository development-only `scripts/`, `docs/` and redundant
`LICENSE.md` from the built source tarball, while keeping them in GitHub.
The README thematic breaks were changed to avoid a misleading YAML
frontmatter interpretation, and the Rd function signatures were wrapped.
These fixes require a new local RStudio CRAN check; they are not yet verified.

The source GitHub repository is private, so its README links are visible to
authenticated collaborators but are **not public CRAN URLs**. Its `URL`
and `BugReports` DESCRIPTION fields were intentionally omitted from the
pre-publication source package; restore legitimate **public** destinations
before submitting to CRAN. This preserves the private repository state.
Incoming-feasibility NOTEs for a new package and the development version
`0.4.0.9000` may remain; they should not be misrepresented as resolved.
The development version is not a CRAN release candidate.

## Verified second Windows CRAN-style run: 25 October 2026

The author reran `R CMD check --as-cran` for unreleased version
`0.4.0.9000` on Windows 11 / R 4.6.1. The check reported
**0 errors, 0 warnings, 1 NOTE**. All examples, `testthat`, HTML manual,
PDF manual, namespaces, package build, installation and Rd line widths passed.
The sole remaining NOTE was CRAN incoming feasibility:

- New submission.
- Version contains large components (`0.4.0.9000`).

Those are reviewable incoming/development metadata observations, not
algorithmic test failures. They do not establish CRAN acceptance or imply
that the submitted development version would be appropriate for CRAN.
The local runner previously labeled any NOTE `FAIL / REVIEW` and stopped;
it now accurately reports **PASS WITH NOTES - REVIEW REQUIRED** when both
R CMD check errors/warnings are zero and the native example passed. It still
reports the complete NOTE count and writes all logs, never suppresses a NOTE,
and still treats any ERROR, WARNING or example failure as failure.
The changed runner is **not yet executed on the author's local R session**.

The native example was independently executed successfully and the author
uploaded the 3-page PDF and CSV. Reported metrics: 8 synthetic curves,
31 samples per curve, 2 FPCA components, recurrence rate
`0.00689655172413793` under radius `0.3` and Theiler exclusion `1`,
12 independent bootstrap participants and 380 recorded Python callables.
The sparse recurrence pattern (PDF page 3) is expected at the narrow
predeclared radius and does not imply an estimator defect. Plots are only
synthetic demonstrations, not inferential calibration. The persistent
Windows outputs were located at:

`C:/Users/Stefanos-PC/Documents/GitHub/eyetrajectories_cran_qualification/R_0.4.0.9000_20261025_232715/native_example/`

Next acceptance gates: R check on another supported platform and R version;
review CRAN incoming policies for a **release** version and real public URLs;
remove scientific inference HOLD only after independent calibration work.
