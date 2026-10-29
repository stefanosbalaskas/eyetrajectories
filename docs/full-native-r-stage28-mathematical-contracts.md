# Stage 28 — 41 published mathematical contracts, 88 source API entries, native nonlinear plots

**Research-only stacked branch on Stage 27 PR #38. No merge, release or version bump.**

Published source: `eyetrajectoriespy==1.2.0` at
`c1cd95ad718327550f7e55393ff38582872f7a94`.
Frozen Python public root inventory:
`7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed`.

## New source API integrations

Three **deterministic metadata** native R public functions:

- `etr_list_mathematical_contracts`: 41 ordered source contract records,
  preserving key, title, ordered public API, original LaTeX equations,
  documentation anchor and scientific limitation/scope.
- `etr_get_mathematical_contract`: exact key / public API function lookup,
  with strict invalid-name handling.
- `etr_mathematical_contract_frame`: exact 88-row, six-column published
  source registry, preserving all LaTeX equation strings, site anchors
  and scientific scopes without executing estimators.

The entire source registry is pinned in
`inst/extdata/native_mathematical_contract_frame_py120.csv` from the
published `src/eyetrajectoriespy/_mathematical_contracts_base.py`
plus the appended joint sparse MFPCA contract in
`src/eyetrajectoriespy/mathematical_contracts.py`. Source ordering and
Python's implicit adjacent-string concatenation in LaTeX are retained,
including the sparse joint-PACE insertion after univariate sparse
PACE.

Three further independent, Python-free source-aligned plots:

- `etr_plot_kantz_sensitivity` — one predeclared Kantz parameter slice;
- `etr_plot_lyapunov_sensitivity` — one Rosenstein/LLE parameter slice;
- `etr_plot_windowed_rqa_sensitivity` — overlay exact per-specification
  source window-center grids and RQA functional responses.

The Kantz and Rosenstein plots fail if more than one row remains at
any selected x parameter, rather than silently averaging over other
sensitivity settings. Declared scalar filters can resolve ambiguity.
The multiscale RQA plot retains per-specification source time grids and
sample window/step information without interpolation or forced
common-grid data handling.

## Fully source-audited metadata evidence — but no false certification

The pinned Python 1.2 direct-source oracle is **exhaustive for the
committed metadata records**, not an illustrative 3-row subset:

1. Compare all **88 rows and six public columns** of the Python pandas
   `mathematical_contract_frame()` with the native R source frame.
2. Compare all **41** source mathematical contracts in documentation
   order, checking every key, title, public API tuple, exact LaTeX
   equation tuple, site anchor and scope string individually.
3. Compare key/public function lookup on `fit_sparse_mfpca` and fail
   closed on invalid local names.
4. Retain 508-export frozen inventory, source-verified count and full
   independent review gate.

No runtime test has yet run on Stage 28. All **three** mathematical
source APIs are type-different from Python:
Python's tuple/frozen dataclass/pandas public return classes are not
R's named S3 lists and data frames. The three plot APIs likewise
return Matplotlib Axes in Python and numeric geometry/base graphics
in R. Therefore six known differences are recorded as
`source_contract_gap_unresolved=TRUE`, and these six are *not*
fully source-contract certified simply by the metadata comparison.

## Frozen Python 1.2 census

| Quantity | Owner-verified Stage 27 | Stage 28 authored (not runtime-qualified) |
|---|---:|---:|
| Native R mapped scientific functions | 188 | **194** |
| Public Python callable names mapped | 213 / 380 | **219 / 380** |
| Unmapped public Python functions | 167 | **161** |
| Other classes/configuration exports | 128 | 128 |
| Explicit unresolved published-source gaps | 34 | **40** |
| Previously numerically fixture-qualified candidates | 4 | 4 |
| Fully independently certified public source contracts | 0 / 508 | **0 / 508** |

Numerical fixture candidates remain `alr_transform`,
`inverse_alr`, `score_distance_matrix`,
`functional_trapezoid_weights` with all full-source review approval
flags still FALSE. Source metadata equivalence cannot authorize
complete return type compatibility or infer independent scientific
signoff. [Full source review issue #34](https://github.com/stefanosbalaskas/eyetrajectories/issues/34).
Actions remains independently blocked by zero-step runner admission
errors tracked in [CI issue #39](https://github.com/stefanosbalaskas/eyetrajectories/issues/39).

## Windows RStudio exact-head qualification

```r
pkgload::load_all(".",quiet=TRUE)
testthat::test_local(".",filter="native-stage28-math-contracts-diagnostics")
testthat::test_local(".",filter="native-stage22-source-contract-gaps")
testthat::test_local(".",filter="full-native-r-parity-ledger")

stopifnot(identical(et_python_version(),"1.2.0"))
Sys.setenv(ET_RUN_PYTHON_TESTS="true")
tryCatch(
  testthat::test_local(".",filter="native-stage28-math-contracts-diagnostics"),
  finally=Sys.unsetenv("ET_RUN_PYTHON_TESTS"))
```

**No code or results have been approved for CRAN/PyPI release or merged.**
