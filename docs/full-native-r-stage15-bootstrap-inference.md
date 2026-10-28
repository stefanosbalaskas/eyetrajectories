# Stage 15 — four numerical uncertainty estimators and an FPCA shape-band table

Exact source audited against published `eyetrajectoriespy==1.2.0`: `inference.py`, `score_uncertainty.py`, `spectrum_inference.py` and `component_inference.py`. Stage 15 adds **5 independent Python-free R implementations** (4 estimators, 1 source-shaped reporting frame).

| Python source function | Native R | Scientific role |
|---|---|---|
| `multiplier_functional_mean_band` | `etr_multiplier_functional_mean_band` | Gaussian multiplier maximum-studentized observed-grid mean band |
| `bootstrap_fpca_score_uncertainty` | `etr_bootstrap_fpca_score_uncertainty` | Fixed-target basis-resampling score percentiles, signed component alignment |
| `bootstrap_fpca_spectrum_uncertainty` | `etr_bootstrap_fpca_spectrum_uncertainty` | Matched-eigenvalue/ratio studentized spectrum intervals; descending-rank cumulative ratio |
| `bootstrap_fpca_component_bands` | `etr_bootstrap_fpca_component_bands` | Sign-aligned FPC shape studentized simultaneous bands with optional eigengap screen |
| `fpca_component_band_frame` | `etr_fpca_component_band_frame` | Long-form component-time-dimension band output |

## Explicit scientific limitations

- All estimators operate on complete, finite, common-grid data; mean-banding of probability-simplex trajectories is rejected without an explicit log-ratio transform.
- Gaussian multipliers and nonparametric bootstrap resample **whole independent units**, not individual time points. Equal-weight participant mean functions are supported; repeated participant curves are never treated as independent multiplier units.
- Target score uncertainty arises from basis re-estimation only. Targets stay fixed; neither measurement noise, latent PACE score uncertainty, future-curve sampling nor preprocessing uncertainty is included.
- Nonparametric FPCA bootstrap refits the basis and matches components by maximum absolute integrated cosine similarity, applying the implied sign. The existing exact assignment solver supports up to 12 fitted components and fails closed beyond that limit.
- For spectrum inference, individual eigenvalues and explained variance ratios are indexed by matched component **shape**. Cumulative ratios always follow descending eigenvalue **rank**, preserving their scientific meaning under FPC swaps.
- Studentized critical values use the **higher** empirical bootstrap order statistic (NumPy's quantile method='higher'); intervals are *not* clipped to parameter support. Distinct near-tied FPCs may be weakly identified; shape-band eigengap screening is optional and explicit.
- All four uncertainty estimators return observed-grid finite-replicate approximations. No exact finite-sample, conditional, simultaneous continuous-domain or full downstream inferential coverage is claimed.
- Base R RNG streams are reproducible and locally restored, but **not bitwise matched to NumPy streams** for identical seeds; pinned Python-oracle testing checks deterministic geometry, source schema and analytical quantities, not random realization equality.

## Frozen API inventory

| Measure | Stage 14 owner-verified | Stage 15 authored |
|---|---:|---:|
| Independently authored native R functions | 110 | **115** |
| Named Python callable mappings | 139 / 380 | **144 / 380** |
| Unmapped Python callable names | 241 | **236** |
| Partial nonfunction representations | 7 / 128 | **7 / 128** |
| Pending nonfunction exports | 121 | **121** |
| Fully qualified public source contracts | 0 / 508 | **0 / 508** |

Stage 14 owner-run Windows RStudio: native 69 PASS, frozen full ledger 39 PASS and pinned Python 1.2 oracle 79 PASS with zero failures. Stage 15 source/tests are **authored but not runtime-qualified**; no GitHub Actions failure should be misrepresented as numerical evidence when jobs execute zero steps.

## Local verification

```r
pkgload::load_all('.',quiet=TRUE)
testthat::test_local('.',filter='native-stage15-bootstrap-inference')
testthat::test_local('.',filter='full-native-r-parity-ledger')
stopifnot(identical(et_python_version(),'1.2.0'))
Sys.setenv(ET_RUN_PYTHON_TESTS='true')
tryCatch(testthat::test_local('.',filter='native-stage15-bootstrap-inference'),
         finally=Sys.unsetenv('ET_RUN_PYTHON_TESTS'))
```

Keep research branch/PR draft; do not merge, publish, bump versions or mark any of 508 public contracts fully certified based on these limited tests.