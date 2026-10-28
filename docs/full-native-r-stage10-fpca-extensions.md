# Stage 10: fifteen native R compositional FPCA and functional diagnostics

Source reference: pinned eyetrajectoriespy 1.2.0. This is a **draft research port**, not a source-API certification.

## Python public function → native R counterpart

- `fit_compositional_fpca` → `etr_fit_compositional_fpca`
- `reconstruct_compositional_fpca` → `etr_reconstruct_compositional_fpca`
- `component_similarity_matrix` → `etr_component_similarity_matrix`
- `match_fpca_components` → `etr_match_fpca_components`
- `reconstruction_error_by_curve` → `etr_reconstruction_error_by_curve`
- `fpca_reconstruction_curve` → `etr_fpca_reconstruction_curve`
- `compare_registered_unregistered_fpca` → `etr_compare_registered_unregistered_fpca`
- `registration_sensitivity_frame` → `etr_registration_sensitivity_frame`
- `summarise_trajectory_set` → `etr_summarise_trajectory_set`
- `summarise_fpca` → `etr_summarise_fpca`
- `fpca_reporting_text` → `etr_fpca_reporting_text`
- `fpca_eigenvalue_gap_table` → `etr_fpca_eigenvalue_gap_table`
- `fpca_eigengap_reporting_text` → `etr_fpca_eigengap_reporting_text`
- `registration_sensitivity_reporting_text` → `etr_registration_sensitivity_reporting_text`
- `functional_mean_band_frame` → `etr_functional_mean_band_frame`

Implementations are Python-free; Python is imported only by explicitly opted-in testing. Source modules inspected: compositional.py, fpca.py, stability.py, phase.py, subspace.py, reporting.py and inference.py.

## Research restrictions

- Compositional ALR + multivariate FPCA requires at least **three original AOI dimensions** because the Python 1.2 multivariate input requires two ALR dimensions. Output simplex normalization is explicit.
- Component matching uses exact subset dynamic programming maximizing total absolute integrated functional cosine similarity, not a greedy algorithm. It fails closed above **12 fitted components** until large-scale assignment is implemented and qualified. Tie assignment may differ from SciPy but optimal weight is preserved.
- Component axis orientation is sign-indeterminate. Signed matching is returned explicitly. Python and R score/reconstruction parity is compared without assuming equal eigenvector signs.
- Reconstruction error is quadrature weighted, divided by total quadrature weight and channel count. This is an in-sample description and not predictive-validation evidence.
- Registration sensitivity uses original and registered common grids and exact source-oriented forward warps. No alignment is hidden.
- Reporting helpers do not prove inferential coverage, calibration or uncertainty validity. Existing native fitted FPCA scaling is reported explicitly.
- Functional-mean band frames require source-shaped matrices and finite inputs, with no synthetic uncertainty estimation or silent repair.

## Frozen inventory and qualification

| Measure | Stage 9 | Stage 10 authored |
|---|---:|---:|
| Python root/workflow callable mappings | 77 | **92** |
| Unmapped Python callable names | 303 | **288** |
| Independently authored native R implementations | 47 | **62** |
| Partial native representations of 128 other exports | 7 | **7** |
| Fully one-to-one certified public contracts | 0 / 508 | **0 / 508** |

Static checks of the Stage 10 code, exports and frozen source manifest passed: 15 new functions, no unknown source names, no Python calls in production code. **The Stage 10 R and Python tests are authored but have not yet run**, so the Stage 10 scientific parity and cross-platform CI are unqualified.

## Local reproduction (from Stage 10 branch)

```r
pkgload::load_all('.',quiet=TRUE)
testthat::test_local('.',filter='native-stage10-fpca-extensions')
testthat::test_local('.',filter='full-native-r-parity-ledger')
stopifnot(identical(et_python_version(),'1.2.0'))
Sys.setenv(ET_RUN_PYTHON_TESTS='true')
tryCatch(testthat::test_local('.',filter='native-stage10-fpca-extensions'),
  finally=Sys.unsetenv('ET_RUN_PYTHON_TESTS'))
```

Do not merge, version-bump, submit to CRAN or release until new tests pass and the wider contract qualification policy authorizes it.