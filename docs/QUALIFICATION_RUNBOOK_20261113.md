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

## Windows RStudio: independently observed managed-Python and embedded fdasrsf joblib issue

The initial Windows qualification resolved these specific environment failures **without modifying the native R mathematical implementation**:

1. RStudio Terminal was **Git Bash** (`MINGW64`), not PowerShell. `py -3.11` was not on `PATH`; the Windows backslash command `.\\.venv-science\\Scripts\\python.exe` was invalid in Bash. Prefer `./.venv-science/Scripts/python.exe`, or avoid local virtualenvs and use managed Python.
2. Windows Store Python 3.11 could execute Python packages but reticulate could not embed `C:/Program Files/WindowsApps/.../python311.dll` (`Access is denied`). Select `RETICULATE_PYTHON=managed` and `UV_PYTHON_PREFERENCE=only-managed` **before Python initialization**.
3. The newest unpinned Matplotlib installation failed while importing `eyetrajectoriespy` (`AttributeError: module matplotlib has no attribute get_data_path`). Actual managed Python 3.11.16, frozen `eyetrajectoriespy==1.2.0`, `fdasrsf==2.7.4`, and `matplotlib==3.10.9` successfully imported in a fresh R session.
4. The first real frozen-Python elastic test reached `fdasrsf` Karcher iteration and failed with a joblib `TerminatedWorkerError`, including `WinError 6: The handle is invalid` while spawning/cleaning up a loky subprocess. The frozen Python 1.2 code passes `parallel=False`, but upstream `fdasrsf` still uses `joblib.Parallel(n_jobs=-1)` in Karcher alignment. The **test only** now wraps the genuine `et.fit_elastic_fpca(...)` in `with joblib.parallel_config(backend='threading'):`; this keeps the same SRVF/DP/PCA algorithm and prevents loky process creation. A passing Python differential still requires a new local execution; SHA256 review hash refresh does not imply a test pass.

Run a **fresh R session** from the exact-head branch:

```r
options(error = NULL)
Sys.setenv(
  RETICULATE_PYTHON = "managed",
  UV_PYTHON_PREFERENCE = "only-managed",
  MPLBACKEND = "Agg",
  ET_RUN_PYTHON_ELASTIC_TESTS = "true",
  ET_RUN_PYTHON_TESTS = "false"
)
reticulate::py_require(
  packages = c("eyetrajectoriespy==1.2.0",
               "fdasrsf==2.7.4",
               "matplotlib==3.10.9"),
  python_version = ">=3.11,<3.12",
  action = "set"
)
reticulate::py_run_string(
  "import matplotlib; import eyetrajectoriespy; import fdasrsf; import joblib"
)
pkgload::load_all(".", quiet = TRUE)
testthat::test_local(
  ".", filter = "native-elastic-fdasrvf-karcher-pca-20261113",
  reporter = "summary", stop_on_failure = TRUE
)
```

Only the elastic public frozen-Python differential is enabled. Do **not** set `ET_RUN_PYTHON_TESTS=true` until the other source suites have their optional Python dependencies and data environments qualified. The expected completion is zero test failures, not a claim of full Python numerical equality.

## Local scientific validation result — user-reported 2026-11-13

User supplied local Windows RStudio test output on the stacked scientific branch (previous differential test head `d86dc3f`):

- `source("scripts/check_all_r_syntax.R")`: **586 files checked, zero parsing failures**.
- Targeted native FPCA artist / functional mixed W3 / sparse MFPCA paired and async W2 suites: **no failures**, with three frozen-Python test cases opt-in/skipped.
- Native R elastic `fdasrvf 2.5.1` suite: **no failures**, expected package-built-under-newer-R warning.
- Real frozen Python `eyetrajectoriespy==1.2.0`, `fdasrsf==2.7.4`, Python 3.11.16, `matplotlib==3.10.9`: **elastic cross-language structural differential executed successfully**, Python logged three Karcher update steps; no failures or skips in the relevant suite. This was **local user-provided console evidence**, not CI verification or independent numerical certification.
- Exact PR branch GitHub Actions workflows remain queued; do not extrapolate Windows local results to Linux/macOS.

### New quantitative numerical audit (awaiting local execution)

The elastic differential test now records five descriptive R/Python numerical discrepancies, each computed from the **real two backend outputs** and not from a mocked source:

1. Normalized phase-warp RMSE.
2. Maximum absolute phase-warp discrepancy.
3. Per-trajectory translation-centered aligned-curve RMSE.
4. Translation-centered Karcher mean-curve RMSE.
5. PCA score pairwise-distance RMSE, invariant to common score-sign flips, component permutations and orthogonal score rotations.

The Python warps must be finite, within normalized [0,1] and nondecreasing. These are **diagnostics**, not automatic proof of exact Python numerical parity; the medoid vs first-curve mean initialization and reconstruction policies still differ. No independent scientific contract is certified without separately reviewed tolerances/algorithms and real reference evidence.

The test logs are expected to include the heading `ELASTIC_PYTHON12_NATIVE_R_DIFFERENTIAL_NUMERICAL_AUDIT` with actual metric values. Those values have not yet been observed.

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
