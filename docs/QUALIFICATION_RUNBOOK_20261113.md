# EyeTrajectories — qualification runbook (provisional 508/508 scientific source contracts)

## Current **recorded**, not certified baseline

- Frozen Python `eyetrajectoriespy==1.2.0`, commit `c1cd95ad718327550f7e55393ff38582872f7a94`.
- Current provisional author-scoped export ledger: **508/508** after the native R fdasrvf scientific Karcher-DP/shape-PCA review.
- Full independently certified Python contracts: **0**. The provisional ledger must **NOT** be published as 100% full Python parity.
- Final stacked branch: `feat/native-fdasrvf-elastic-karcher-shape-pca-20261113`, PR #177, source-scientific head at creation `01e2b00e3a35b97d7d80092a7691b850665b8e94`.
- Parent stacked PRs #176 → #175 → #174 → #173 and their ancestors must not be assumed merged.
- Workflow `.github/workflows/native-elastic-karcher-shape-pca-20261113.yml`: SHA256 ledger audit; actual R fdasrvf method tests on Linux/macOS/Windows; genuine frozen Python 1.2 + fdasrsf differential. Initially five jobs queued without completion. **Check current statuses; do not claim green until the exact-head jobs conclude successfully**.

## Stage 0: Unblock GitHub-hosted Actions before debugging any scientific method

1. Open https://github.com/stefanosbalaskas/eyetrajectories/actions/runs/43327914326 and click job `exact-source-sha256-inventory`. If even this Python-stdlib-only job is queued, the block is **before** package-specific R and fdasrvf execution.
2. Check https://github.com/stefanosbalaskas/eyetrajectories/settings/actions (Actions General/runner permissions), and https://github.com/stefanosbalaskas/eyetrajectories/settings/actions/runners (GitHub-hosted runner pool and active vs queued jobs). Review any spending/billing warnings shown by GitHub. The repository is public; ordinary GitHub-hosted runners on public repositories are ordinarily free.
3. Check whether all workflows on the same PR are queued because of concurrency or an upstream blocked run. More than 90 workflows on the same head may be redundant. **Do not automatically delete all workflow runs**; identify and preserve the exact-head scientific SHA256 audit, elastic R 3-OS tests, frozen Python differential, and full R CMD check. Cancel *confirmed superseded/redundant* runs through the Actions UI when needed to reduce backlog.
4. When a job starts, gather the job's exact error log if it fails, and fix that error only. If nothing can start and GitHub shows a stuck-run error, follow GitHub Actions troubleshooting/support.

## Stage 1: Native R functional smoke from the exact source branch (Windows RStudio)

Precondition: Git installed, R >= 4.3.0 (required by `fdasrvf==2.5.1`), working directory set to your **local EyeTrajectories repository** (not the fisheries project), and no uncommitted work you would lose by changing refs. To check status in a terminal:

```powershell
git status --short
git fetch origin
git switch --detach origin/feat/native-fdasrvf-elastic-karcher-shape-pca-20261113
git rev-parse HEAD
```

The detached checkout keeps existing local named branches untouched but will refuse to switch if local edits would be overwritten. Stop rather than discarding edits.

In RStudio console at repository root:

```r
stopifnot(getRversion() >= "4.3.0")
install.packages(c("testthat", "pkgload", "fdasrvf", "reticulate"))
stopifnot(utils::packageVersion("fdasrvf") >= package_version("2.5.1"))
pkgload::load_all(".", quiet = TRUE)

# Real native R elastic Karcher/DP and shape-PCA with non-identity warp.
# The Python comparison is opt-in and is NOT enabled by this command.
Sys.setenv(ET_RUN_PYTHON_ELASTIC_TESTS = "false",
           ET_RUN_PYTHON_TESTS = "false")
testthat::test_local(
  ".", filter = "native-elastic-fdasrvf-karcher-pca-20261113",
  reporter = "summary", stop_on_failure = TRUE
)
```

If this fails, preserve **the complete R test output, sessionInfo(), and the exact Git commit SHA**. Do not interpret a passing R smoke test as Python numerical equivalence.

## Stage 2: Test source numerical matching on true frozen Python 1.2

Use a fresh isolated Python 3.11 virtual environment; install the true Python oracle and the optional compiled Python backend:

```powershell
py -3.11 -m venv .venv-science
.venv-science\Scripts\python.exe -m pip install --upgrade pip
.venv-science\Scripts\python.exe -m pip install "eyetrajectoriespy==1.2.0" "fdasrsf>=2.7,<2.8" "FDApy==1.0.3" "numpy==1.26.4"
```

Set `RETICULATE_PYTHON` to the absolute path of the venv's `python.exe` **before** loading `reticulate`. In R:

```r
Sys.setenv(RETICULATE_PYTHON = normalizePath(".venv-science/Scripts/python.exe",
                                             winslash = "/", mustWork = TRUE),
           ET_RUN_PYTHON_ELASTIC_TESTS = "true",
           ET_RUN_PYTHON_TESTS = "true")
pkgload::load_all(".", quiet = TRUE)
testthat::test_local(
  ".", filter = "native-elastic-fdasrvf-karcher-pca-20261113|native-fdapy-ufpca-ps-lp-source-20261112",
  reporter = "summary", stop_on_failure = TRUE
)
```

The elastic Python test intentionally assesses scientific output layout, real phase warping and metadata; it **does not yet certify numerical equality**, as the R and Python solvers use different initialization and alignment code. FDApy tests attempt score/eigenspectrum matching and need careful review of numeric tolerances, component signs and permutations.

## Stage 3: Extend to three-OS CI, full check and independent scientific qualification

1. Source-contract audit: all 198 reviewed record SHA256 pins and 508-row inventory, while explicitly retaining unqualified subcontracts in `native_scoped_fdapy_submethod_gaps_20261112.csv`, `native_scoped_elastic_submethod_gaps_20261113.csv`, and `native_scoped_environment_subcontracts_20261112.csv`.
2. R platform matrix: Linux, Windows and macOS; source parser, testthat, `R CMD check --as-cran`; preserve exact workflow URL and conclusion for each.
3. Frozen Python/R numerical invariants: independent simulation test suite (known phase warps, eigenvalue spectra/eigenspaces, covariance operator, mean/score reconstruction); compare actual source semantics rather than easy synthetic identity cases. Declare tolerances before independent certification.
4. Independent reviewer signs each of the six-domain contracts. No full certification is granted merely because the provisional 508/508 ledger's `unresolved_source_gap` column is `FALSE`.
5. Merge **in dependency order** (oldest first), check consolidated main commit, prepare a clean release candidate with R CMD check results. Stop rather than submitting to CRAN on unverified queued checks.

## Immediate operational priorities

**Priority A:** determine why even `exact-source-sha256-inventory` is queued. This cannot be diagnosed from R code or a passing local test.

**Priority B:** run Stage 1 native elastic and FDApy tests in RStudio from the exact branch; capture real failures.

**Priority C:** resolve actual source differences and perform independent numeric qualification before promising complete Python parity.
