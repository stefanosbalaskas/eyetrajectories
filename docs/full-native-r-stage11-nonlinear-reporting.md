# Stage 11 — 15 native R nonlinear scientific reporting methods

These are **reporting and structured-result adapter functions**, not 15 new nonlinear estimators. Published source inspected: eyetrajectoriespy==1.2.0, `nonlinear_reporting.py`. The implementation file has no Python/reticulate calls. No report computes, tunes or validates an estimator.

## Source mappings

| Python 1.2 public callable | Python-free native R counterpart |
|---|---|
| `joint_recurrence_reporting_text` | `etr_joint_recurrence_reporting_text` |
| `recurrence_network_reporting_text` | `etr_recurrence_network_reporting_text` |
| `recurrence_radius_profile_reporting_text` | `etr_recurrence_radius_profile_reporting_text` |
| `rqa_reporting_text` | `etr_rqa_reporting_text` |
| `rqa_metric_mean_bootstrap_reporting_text` | `etr_rqa_metric_mean_bootstrap_reporting_text` |
| `windowed_rqa_reporting_text` | `etr_windowed_rqa_reporting_text` |
| `windowed_rqa_functional_reporting_text` | `etr_windowed_rqa_functional_reporting_text` |
| `windowed_rqa_sensitivity_reporting_text` | `etr_windowed_rqa_sensitivity_reporting_text` |
| `windowed_rqa_mean_band_reporting_text` | `etr_windowed_rqa_mean_band_reporting_text` |
| `rqa_parameter_sensitivity_reporting_text` | `etr_rqa_parameter_sensitivity_reporting_text` |
| `kantz_parameter_sensitivity_reporting_text` | `etr_kantz_parameter_sensitivity_reporting_text` |
| `lyapunov_parameter_sensitivity_reporting_text` | `etr_lyapunov_parameter_sensitivity_reporting_text` |
| `largest_lyapunov_reporting_text` | `etr_largest_lyapunov_reporting_text` |
| `surrogate_nonlinearity_reporting_text` | `etr_surrogate_nonlinearity_reporting_text` |
| `return_map_stability_reporting_text` | `etr_return_map_stability_reporting_text` |

The recurrence network, joint recurrence, radius-profile, RQA, and windowed-RQA report functions accept pre-existing native R result objects. Bootstrap/sensitivity, Lyapunov, surrogate and return-map report functions accept **explicit, validated R result schemas** supplied by upstream analysis; complete native estimators for several of those schemas are still unimplemented. Their presence must not be counted as a new estimator or a certified one-to-one dataclass.

Reporting is descriptive, distinguishes unqualified nonlinear measures from causal claims, retains Theiler and temporal-support specifications where present, and does not assign uncertainty to overlapping windows. The native network text deliberately avoids Python's claim of sparse graph storage because the current R implementation is dense.

## Frozen inventory

| Metric | Stage 10 | Stage 11 code inventory |
|---|---:|---:|
| New native R functions authored cumulatively (including reporting) | 62 | **77** |
| Named Python callable mappings | 92 / 380 | **107 / 380** |
| Unmapped callable names | 288 | **273** |
| Partially represented other public objects | 7 / 128 | **7 / 128** |
| Fully qualified public source contracts | 0 / 508 | **0 / 508** |

Stage 9 local Windows test qualification passed; Stage 10 native R passed **64** assertions with one expected Python skip. The Stage 10 Python reference produced 81 passing assertions and one tuple-indexing fixture failure, corrected by `182f4dbe` but still awaiting a fresh owner-run pass. Stage 11 has authored tests only; no executed Stage 11 R or Python oracle is claimed. The strict 508-source gate remains CLOSED.

## Local RStudio qualification

Switch to branch `research/native-r-stage11-nonlinear-reporting-20261028`, restart R, then:

```r
pkgload::load_all('.',quiet=TRUE)
testthat::test_local('.',filter='native-stage11-nonlinear-reporting')
testthat::test_local('.',filter='full-native-r-parity-ledger')
stopifnot(identical(et_python_version(),'1.2.0'))
Sys.setenv(ET_RUN_PYTHON_TESTS='true')
tryCatch(testthat::test_local('.',filter='native-stage11-nonlinear-reporting'),
         finally=Sys.unsetenv('ET_RUN_PYTHON_TESTS'))
```

Stage 10 Python oracle should also be rerun on this branch. No merge, release, 508-contract certification or unreviewed inference claim is allowed.