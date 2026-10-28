# Stage 12 — leakage-aware native FPCA validation and result-frame integrations

Source: published eyetrajectoriespy==1.2.0 `selection.py`, `prediction.py`, `score_uncertainty.py`, `spectrum_inference.py`, `conformal.py`, `regression_inference.py`, `similarity_sensitivity.py`. Direct source contracts were inspected before authoring these Python-free R functions.

## Independently authored public R implementations

| Python callable | Native R counterpart | Status |
|---|---|---|
| `cross_validate_fpca_reconstruction` | `etr_cross_validate_fpca_reconstruction` | New held-out CV numerical estimator |
| `summarise_fpca_cross_validation` | `etr_summarise_fpca_cross_validation` | CV aggregation / selection algorithm |
| `select_fpca_components_cv` | `etr_select_fpca_components_cv` | CV aggregation / selection algorithm |
| `summarise_fpca_regression_cv` | `etr_summarise_fpca_regression_cv` | CV aggregation / selection algorithm |
| `select_fpca_regression_components` | `etr_select_fpca_regression_components` | CV aggregation / selection algorithm |
| `fpca_score_uncertainty_frame` | `etr_fpca_score_uncertainty_frame` | Validated result-frame adapter |
| `fpca_spectrum_uncertainty_frame` | `etr_fpca_spectrum_uncertainty_frame` | Validated result-frame adapter |
| `conformal_fpca_anomaly_frame` | `etr_conformal_fpca_anomaly_frame` | Validated result-frame adapter |
| `trajectory_distance_comparison_frame` | `etr_trajectory_distance_comparison_frame` | Validated result-frame adapter |
| `trajectory_distance_neighbor_frame` | `etr_trajectory_distance_neighbor_frame` | Validated result-frame adapter |
| `fpca_regression_slope_band_frame` | `etr_fpca_regression_slope_band_frame` | Validated result-frame adapter |
| `fpca_regression_slope_uncertainty_frame` | `etr_fpca_regression_slope_uncertainty_frame` | Validated result-frame adapter |
| `fpca_regression_prediction_uncertainty_frame` | `etr_fpca_regression_prediction_uncertainty_frame` | Validated result-frame adapter |
| `fpca_regression_future_prediction_frame` | `etr_fpca_regression_future_prediction_frame` | Validated result-frame adapter |

The cross-validation method **refits weighted FPCA exclusively on training curves inside each fold**, projects only the held-out curves, reconstructs with each prespecified component count, and reports held-out integrated RMSE. Curves are unique test observations; group folds protect full participant IDs. Fold IDs are zero-based, as in Python. Trapezoidal quadrature weights match the fitted functional geometry. Nonfinite input fails closed.

### Explicit source differences

- Native R `shuffle=FALSE` uses consecutive balanced KFold partitions, matching scikit-learn's deterministic index fold semantics.
- Native R `shuffle=TRUE` uses isolated base-R `sample()` with a seed while restoring the caller's RNG state. **Its shuffled sample order is not asserted equal to NumPy/scikit-learn for the same seed.** This is recorded in the returned provenance.
- Group-fold assignment is deterministic, balances participant-unit sizes and blocks group overlap. Scikit-learn GroupKFold may choose different fold IDs when multiple group counts tie; leak prevention, not tie-specific fold labeling, is the contract presently covered.
- The one-standard-error component selection heuristic is explicitly descriptive and not an inferential guarantee.
- The uncertainty and conformal frame methods only validate and organize **declared upstream results**; these functions do not calculate new intervals, run a bootstrap, or establish conditional conformal coverage. They are not full upstream result class implementations.

### Authored counts, not certified equivalence

| Measure | Stage 11 | Stage 12 authored |
|---|---:|---:|
| Native R implementations, including table adapters | 77 | **91** |
| Mapped Python root callables | 107 / 380 | **121 / 380** |
| Unmapped Python root callables | 273 | **259** |
| Partial representations of 128 other exports | 7 | **7** |
| Full one-to-one public contract certifications | 0 / 508 | **0 / 508** |

Stage 10 and Stage 11 Windows RStudio native and Python 1.2 tests were reported passed (**64 / 84** and **59 / 61**, respectively). Stage 12 numerical/edge and opt-in Python 1.2 tests are authored and **have not executed**; the counts above reflect code and source mappings, not a runtime-qualified release.

### Owner-run Stage 12 RStudio

```r
pkgload::load_all('.',quiet=TRUE)
testthat::test_local('.',filter='native-stage12-cv-uncertainty')
testthat::test_local('.',filter='full-native-r-parity-ledger')
stopifnot(identical(et_python_version(),'1.2.0'))
Sys.setenv(ET_RUN_PYTHON_TESTS='true')
tryCatch(testthat::test_local('.',filter='native-stage12-cv-uncertainty'),
         finally=Sys.unsetenv('ET_RUN_PYTHON_TESTS'))
```

Strict frozen 508-source `require_complete=TRUE` must remain failing until independently verified. No main merge, version bump, CRAN or PyPI publication.