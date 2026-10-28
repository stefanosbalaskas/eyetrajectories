# Stage 14 — native FPCA influence, subspace stability, and explicit outlier screening

Source: published `eyetrajectoriespy==1.2.0`, direct inspection of `subspace.py`, `stability.py`, and `outliers.py`. **Seven Python-free R implementations** are authored, with three substantial numerical diagnostic estimators (bootstrap component stability, bootstrap subspace stability, leave-group-out influence), principal-angle comparison, empirical outlier diagnostics, and two result summaries. All scientific qualification pending actual Stage 14 R/Oracle test execution.

| Python callable | Native R implementation |
|---|---|
| `compare_fpca_subspaces` | `etr_compare_fpca_subspaces` |
| `bootstrap_fpca_subspace_stability` | `etr_bootstrap_fpca_subspace_stability` |
| `summarise_fpca_subspace_stability` | `etr_summarise_fpca_subspace_stability` |
| `leave_one_group_out_fpca_influence` | `etr_leave_one_group_out_fpca_influence` |
| `bootstrap_fpca_stability` | `etr_bootstrap_fpca_stability` |
| `summarise_fpca_stability` | `etr_summarise_fpca_stability` |
| `diagnose_fpca_outliers` | `etr_diagnose_fpca_outliers` |

## Method constraints

- FPCA principal-angle comparisons calculate weighted, dimension-standardized functional eigenspaces. Reported cosines, angles and normalized projector distances are invariant to FPC sign flips and rotations within the declared selected block. Both results must share exact time grid, functional dimensions, weights, coordinate semantics and time units; nonorthonormal blocks fail closed.
- Nonparametric bootstraps refit native FPCA for each replicate. Curve-level resampling repeats whole functional observations. Participant-level resampling repeats **whole participant groups** and updates participant labels to avoid accidentally pooling different resampled copies. All RNG state is restored. Seed-matched NumPy draws are not asserted identical to R's RNG, so only method/geometry, not replicate-by-replicate numerical identity, can be directly qualified.
- Individual FPC stability uses globally optimal absolute cosine component matching; matching is capped at 12 fitted components by the qualified Stage 10 algorithm.
- Leave-one-group-out influence omits all curves belonging to one declared participant/group before refitting, rather than excluding repeated trials individually. No outlier or influence diagnostic automatically removes curves.
- **Robust MinCovDet score covariance is not yet ported.** `etr_diagnose_fpca_outliers()` defaults to a clear error in this unsupported mode; callers must explicitly choose `score_covariance='empirical'` to use the exact population-normalized empirical score covariance and chi-squared threshold. The reconstruction component uses weighted RMSE and robust MAD z. It is *review screening*, not an exclusion rule or validated false-discovery guarantee.
- Bootstrap percentiles are descriptive finite-sample summaries, not automatically calibrated population confidence bands or proofs of stable individual FPC labels. None of these methods claims causal, screening accuracy, or inference validity.

## Frozen source inventory

| Measure | Stage 13 owner-verified | Stage 14 authored, unverified |
|---|---:|---:|
| Independently authored native R implementations | 103 | **110** |
| Source-name mappings for 380 Python callable exports | 132 | **139** |
| Remaining unmapped Python callables | 248 | **241** |
| Partially represented nonfunction exports | 7 / 128 | **7 / 128** |
| Pending nonfunction exports | 121 | **121** |
| Fully certified public source contracts | 0 / 508 | **0 / 508** |

Stage 13 owner-run RStudio results: 229 Stage 5–8 and full ledger assertions, 171 native Stage 13 assertions, 186 Stage 13 pinned Python 1.2 oracle assertions—all zero failures and warnings. These **do not** qualify Stage 14. Stage 14 static source/manifest checks and authored tests are not runtime tests.

## RStudio verification

```r
pkgload::load_all('.',quiet=TRUE)
testthat::test_local('.',filter='native-stage14-fpca-stability')
testthat::test_local('.',filter='full-native-r-parity-ledger')
stopifnot(identical(et_python_version(),'1.2.0'))
Sys.setenv(ET_RUN_PYTHON_TESTS='true')
tryCatch(testthat::test_local('.',filter='native-stage14-fpca-stability'),
         finally=Sys.unsetenv('ET_RUN_PYTHON_TESTS'))
```

Stage 14 is a **stacked DRAFT**, not production code. Do not merge, release, version bump, publish to CRAN/PyPI or change 508-contract certification based on source name mapping or limited validation.