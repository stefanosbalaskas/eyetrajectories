# Complete one-to-one Python 1.2.0 → native R implementation programme

**Target: Python-free execution of every public scientific capability**, not merely calling Python functions from R. The existing `reticulate` bridge stays optional for compatibility and as an external numerical oracle; a function cannot be classified as complete unless its native R implementation itself executes without Python.

**Reference:** published `eyetrajectoriespy==1.2.0`, Python `__all__` snapshot pinned in `inst/extdata/python_api_2026-10-25.csv`. The public API comprises **380 functions** (362 root + 18 workflow) and **128 other symbols** (Python classes, configuration objects and constants). Not all symbols are independently meaningful algorithms; nevertheless, *each* must receive an explicit native-R representation or documented compatibility boundary. No automatic mechanical one-to-one equivalence is presumed.

## Baseline — structural, not scientific parity

- R research branch `0.4.1.9000` has **98** native `etr_*` exports and **380** optional Python-backed `etpy_*` wrappers before this native stage. Counts are not comparable algorithm-for-algorithm.
- Existing R code reports **37 named native-function analogues**, but their names alone do not demonstrate mathematical/behavioral parity.
- This stage adds **4 genuine Python-free R algorithms**: `etr_acceleration_magnitude` (`acceleration_magnitude_function`), `etr_distance_to_landmark` (`distance_to_landmark_function`), `etr_signed_curvature` (`signed_curvature_function`) and `etr_turning_rate` (`turning_rate_function`). These follow the published Python finite-difference definitions and missing-value policies. Dedicated analytic irregular-grid tests and *opt-in* independent R–Python numerical oracle tests have been committed; execution has not yet been confirmed.
- The initial conservative full register therefore has **41 named native analogues/candidates, including 4 new implementations**, **339 Python function names without a specified native counterpart**, and **128 additional Python symbols whose native representation is not yet reviewed**. **Zero claims of fully independently qualified one-to-one contracts** are automatically granted by the register. The register is a gap inventory, not a measure of algorithm correctness.

Run from the updated native research checkout:

```r
pkgload::load_all(".", quiet = TRUE)
testthat::test_local(".", filter = "native-planar-geometry-parity")
testthat::test_local(".", filter = "full-native-r-parity-ledger")
source("scripts/report_full_native_r_parity.R")

# Optional independent Python numerical oracles (NOT required for native use):
Sys.setenv(ET_RUN_PYTHON_TESTS = "true", MPLBACKEND = "Agg")
testthat::test_local(".", filter = "native-planar-geometry-parity")
Sys.unsetenv(c("ET_RUN_PYTHON_TESTS", "MPLBACKEND"))
```

Native functions work without Python; only the optional cross-language oracle test imports Python. The report writes a **508-row machine-readable audit**, grouped statuses and a non-overwriting manifest to `artifacts/full_native_r_parity/audit_.../`.

## Workstreams required for full parity

| Family | Required native-R work and qualification |
|---|---|
| Data contracts / preprocessing / coordinate metadata | Reproduce Python `TrajectorySet` fields, validation, provenance, reversible R serialization, missing-data policies, smoothing, phase transforms |
| Continuous dense functional analysis | Weighted FPCA/MFPCA, score reconstruction, eigenvector subspace invariance, numerical quadrature and advanced uncertainty |
| Sparse and irregular functional data | PACE, joint asynchronous multivariate covariance, irregular channels, bandwidth selection, sparse multilevel and sparse predictions |
| Hierarchical inference | Full functional mixed effects, covariance variants, nested random effects, bootstrap refits, prediction and residual diagnostics |
| Functional regression | Function-on-scalar and scalar-on-function, generalized models, wild/bootstrap inference, model selection and prediction |
| Alignment / elastic geometry | Registration, phase FPCA, elastic square-root velocity, compositional/phase-aware geometry |
| Nonlinear methods | Recurrence, joint/cross recurrence, RQA, networks, Lyapunov/embedding, transfer entropy, multivariate surrogates and sensitivity |
| Anomaly / uncertainty | Conformal validity, outliers, score/spectrum inference and split/partial conformal conditions |
| Public workflow layer | Every declared Python workflow entry, configuration object, result class, reporting/plotting, export/portability schema |
| Scientific qualification | Independent known-truth Monte Carlo, robustness, coverage, conditional observation support, failure-inclusive auditing |

Develop functions in small reviewable native groups, but maintain the 508-symbol inventory across every group. A source-name count or a bare R wrapper will never qualify a missing estimator.

## Acceptance rules for each Python function

A native function must satisfy **all** of the following before it is marked one-to-one equivalent:

1. **Python-free runtime:** the R method does not invoke `reticulate`, Python or shell-out Python, including inside optional branches.
2. **Contract equivalence:** supported inputs, dimensions, defaults, missingness behavior, exceptions, numerical assumptions, metadata and output schema are documented against the exact pinned Python code.
3. **Independent numeric oracle:** tests compare R results with Python reference outputs on **independent** fixed and randomized cases, using appropriate invariant subspace/phase comparisons where raw coefficients are non-unique.
4. **Failure and edge cases:** small `n`, irregular time, incomplete observations, singular operators, degenerate eigenvalues and unavailable optional backends fail or recover as specified.
5. **Reproducibility:** deterministic seeds, provenance, pinned dependencies, artifacts, cross-platform R CI and exact-head review pass.
6. **Inference claims separated:** coverage/power/identifiability must be demonstrated separately, not inferred from implementation or computational equivalence.

The fail-closed `etr_native_parity_catalog(require_complete=TRUE)` must remain an error until the entire inventory genuinely meets the required contracts. It intentionally does **not** grant a pass merely because all `etr_*` functions are present.

## Product and merge boundary

The Python-backed integration PR #7 remains a separate user-convenience path, not fulfillment of native parity. This native project is independently staged against `research/native-parity-stage1`. It does not modify or promote known-failing 90% simultaneous confidence bands or unresolved MNAR identification. No main merge, public release or CRAN submission is implied.


## Owner-executed Stage 2 qualification — 27 October 2026

On the native branch in RStudio, both expected test files were present, and
the owner completed these independent local tests:

- `testthat::test_local(".", filter="native-planar-geometry-parity")`:
  **40 PASS, 1 SKIP, 0 FAIL, 0 WARN**. The sole skip was the
  explicitly opt-in Python-vs-R numerical oracle; all native analytical
  and boundary checks executed successfully.
- `testthat::test_local(".", filter="full-native-r-parity-ledger")`:
  **35 PASS, 0 SKIP, 0 FAIL, 0 WARN**.
- `source("scripts/report_full_native_r_parity.R")`:
  generated the full 508-symbol catalog; **380 function contracts,
  128 nonfunction contracts, 41 name candidates, 4 newly implemented native
  algorithms, 37 existing but unqualified analogues, 339 unmapped Python
  functions and zero independently certified one-to-one contracts**.

Owner-local output:
`artifacts/full_native_r_parity/audit_20261027_182923_pid51684/`.
The source CSV was not uploaded/independently read; counts above are from
the owner's console transcript.

**Next required test:** In a separately verified managed Python 3.12
environment containing stable `eyetrajectoriespy==1.2.0`:

```r
pkgload::load_all(".", quiet = TRUE)
stopifnot(identical(et_python_version(), "1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS = "true")
testthat::test_local(".", filter = "native-planar-geometry-parity")
Sys.unsetenv("ET_RUN_PYTHON_TESTS")
```

This runs the independent numeric Python-reference test as well. It is
only a **four-method fixture comparison**, not exhaustive parity on all
input distributions or all Python functions.

These findings validate native R analytic behavior and the gap inventory,
but do not establish native R/Python numerical parity or qualify any
scientific inference contracts. Keep PR #9 draft and the full release gate
closed. GitHub Actions CI has not executed a single job step.
