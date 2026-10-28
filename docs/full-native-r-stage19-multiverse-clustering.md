# Stage 19 — five independent numerical sensitivity and clustering methods

Audited against the published `eyetrajectoriespy==1.2.0` Python source: `nonlinear_sensitivity.py`, `similarity_sensitivity.py` and `analysis.py`. Five independently authored native R numerical methods, no Python/reticulate production bridge.

| Python callable | Native R function | Quantitative capability |
|---|---|---|
| `lyapunov_parameter_sensitivity` | `etr_lyapunov_parameter_sensitivity` | Full declared Rosenstein divergence/horizon-fit grid |
| `kantz_parameter_sensitivity` | `etr_kantz_parameter_sensitivity` | Full declared Kantz radius/min-neighbor/reconstruction and fit grid |
| `rqa_parameter_sensitivity` | `etr_rqa_parameter_sensitivity` | Full fixed-radius Euclidean recurrence/line-cutoff grid |
| `cluster_fpca_scores` | `etr_cluster_fpca_scores` | Native finite fitted-FPC-score K-means |
| `trajectory_distance_sensitivity` | `etr_trajectory_distance_sensitivity` | Complete unscaled pairwise distance, rank-correlation and nearest-neighbor overlap multiverse |

## Statistical and algorithmic boundaries

- Sensitivity grids evaluate **every declared Cartesian-product specification**; invalid estimators or fit intervals error with specification information. No automatic parameter tuning, winner, rejected-row filtering or multiple-testing adjustment.
- Rosenstein and Kantz inputs support **integer sample-unit lags/horizons only**. Physical-time conversion variants are not silently approximated. Fitted exponents are descriptions of explicitly chosen divergence segments, **not** standalone evidence of deterministic chaos.
- RQA sensitivity supports an explicit **Euclidean fixed-radius** contract. Python source adaptive target-rate thresholds and `center_of_recurrence_mass` are **not implemented**. Supported RQA metrics retain the previously source-tested native recurrence and line-length conventions.
- K-means uses R's **Hartigan–Wong** routine, explicit finite retained score columns, and isolated reproducible base-R RNG. It **does not reproduce scikit-learn's KMeans++ initialization, numerical-label permutations, or NumPy random draws**. Cluster labels begin at zero to match source indexing, but group numbers carry no intrinsic meaning.
- Distance sensitivity keeps original distance matrices and does **not** standardize, rescale or form any consensus metric. It uses average midranks for ties; nearest neighbors use stable original-curve ordering with explicit cutoff-tie flags. Pearson/Spearman agreement and neighbor Jaccards are descriptive, not p-values from independent curve-pair samples.
- Three distance contracts are supported by pre-existing native R algorithms: trapezoid-weighted functional L2, discrete Frechet and explicitly parameterized DTW. All curves and selected dimensions must be exactly aligned on a shared grid.
- No new scientific coverage/calibration guarantee arises from the new methods; the Stage 19 pinned Python 1.2 oracle compares deterministic distance matrices/neighbor orders and a direct Rosenstein slope. Full grid-parity for every feature, stochastic K-means equivalence, and cross-OS CI remain unqualified.

## Frozen source census

| Measure | Stage 18 owner-tested | Stage 19 authored |
|---|---:|---:|
| Authored native R implementations | 140 | **145** |
| Unique mapped Python callable names | 165 / 380 | **170 / 380** |
| Unmapped Python callable names | 215 | **210** |
| Partial other public exports | 7 / 128 | **7 / 128** |
| Pending other public exports | 121 | **121** |
| Fully certified public source contracts | 0 / 508 | **0 / 508** |

Stage 18 owner-run Windows RStudio checks were green: 68 native assertions, 39 full frozen ledger, 72 opt-in Python 1.2 residual formula assertions; zero failures/warnings. Stage 19 tests are **authored but not runtime-verified**.

## RStudio

```r
pkgload::load_all('.',quiet=TRUE)
testthat::test_local('.',filter='native-stage19-multiverse-clustering')
testthat::test_local('.',filter='full-native-r-parity-ledger')
stopifnot(identical(et_python_version(),'1.2.0'))
Sys.setenv(ET_RUN_PYTHON_TESTS='true')
tryCatch(testthat::test_local('.',filter='native-stage19-multiverse-clustering'),
  finally=Sys.unsetenv('ET_RUN_PYTHON_TESTS'))
```

Draft research stack only: no merges, release/version bump, Python or R public package publication, or 508-contract certification.