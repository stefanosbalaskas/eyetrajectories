# Stage 18 — restricted native functional repeated-measures model and residual covariance audits

Source audited against published `eyetrajectoriespy==1.2.0` in `functional_mixed_effects.py`, `functional_mixed_effects_nested.py`, `functional_mixed_effects_diagnostics.py`, and `functional_mixed_effects_covariance_sensitivity.py`. This stage authors **seven independent Python-free R implementations** covering repeated measures, lag-based residual diagnostics and covariance variance decomposition.

## Explicit distinction from the published Python likelihood backend

The native estimator `etr_fit_functional_mixed_effects_regression()` is a **restricted two-level method-of-moments model**, **NOT** a one-to-one port of the Python spline-basis `statsmodels.MixedLM`/profiled Gaussian mixed-effects likelihood. It estimates pointwise fixed coefficient functions with OLS; estimates within-participant functional covariance from trial deviations; subtracts a declared `mean(1/m_g)` within-covariance correction from the empirical covariance of group mean residual functions; projects the resulting between-participant covariance onto the positive-semidefinite cone; adds a declared positive within-covariance ridge; and shrinks participant functional residual means by the resulting BLUP-style linear predictor.

Interpretations and limitations: covariance estimates can be ill-conditioned or sensitive to participant/sample size and ridge; the fixed regression is **not GLS**, REML, ML, or Bayesian; pointwise participant-cluster sandwich SEs are descriptive and are **not** calibrated simultaneous bands. At least three independent participants with at least two observations each are required. The function explicitly records `source_python_equivalent=FALSE`, `likelihood_optimized=FALSE`, `REML=FALSE`. This design makes a usable independent R restricted repeated-measures model without misleading parity claims.

| Python public callable | Authored native R method | Caveat |
|---|---|---|
| `fit_functional_mixed_effects_regression` | `etr_fit_functional_mixed_effects_regression` | Restricted moments estimator, NOT Python MixedLM |
| `functional_mixed_effects_whitened_residuals` | `etr_functional_mixed_effects_whitened_residuals` | Whitening on fitted native ridge covariance |
| `functional_mixed_effects_residual_diagnostics` | `etr_functional_mixed_effects_residual_diagnostics` | Python-formula lag diagnostics, but on native restricted model residuals |
| `functional_mixed_effects_residual_diagnostic_frame` | `etr_functional_mixed_effects_residual_diagnostic_frame` | Source-shaped native diagnostic/reporting subset |
| `functional_mixed_effects_residual_pair_frame` | `etr_functional_mixed_effects_residual_pair_frame` | Source-shaped native diagnostic/reporting subset |
| `functional_mixed_effects_variance_decomposition` | `etr_functional_mixed_effects_variance_decomposition` | Participant intercept + scalar residual variance only |
| `functional_mixed_effects_coefficient_frame` | `etr_functional_mixed_effects_coefficient_frame` | Source-shaped native diagnostic/reporting subset |

## Numerical method and audit details

- Conditional residual whitening uses a Cholesky factor of the fitted positive-definite within-curve covariance. This is not decorrelation of participant random effects or a posterior independence assertion.
- Trial-wise centered residual autocovariance uses **population** mean cross-products at each explicit lag. Autocorrelation is standardized by the lag-zero within-trial centered variance; zero-variance curves are retained with undefined (NaN) ACF. Semivariance uses one half of the mean squared raw pair difference.
- Physical time differences are preserved as mean, minimum and maximum for each index lag. Residual pair frames expose exact start/end indices and times—without physical-lag binning or implicit regular-grid assumptions.
- Participant and overall summaries use pair-count weighted averages and retain counts of trials with defined ACF; this is not within-person inferential uncertainty.
- Variance decomposition emits the functional participant random-intercept variance and scalar within-trial residual variance on the common time grid. The Python source's functional random slope, intercept–slope cross covariance and nested trial random effects are not implemented.
- The R-source tests check PSD covariance, fixed fitted/residual reconstruction, BLUP shrinkage inputs, exact whitening algebra, lag index/time geometry, participant summary counts, coefficient tables and explicit unsupported modes. An opt-in Python 1.2/NumPy formula oracle checks residual autocovariance, ACF and semivariance calculations on **the exact same native residual sequence**; it does **not** compare fitted native moments parameters with a Python MixedLM model.

## Cumulative source inventory

| Item | Owner-qualified Stage 17 | Stage 18 authored |
|---|---:|---:|
| Native R implementations | 133 | **140** |
| Unique mapped Python functions | 159 / 380 | **165 / 380** |
| Unmapped Python callables | 221 | **215** |
| Partially represented class/constant exports | 7 / 128 | **7 / 128** |
| Unrepresented class/constant exports | 121 | **121** |
| Fully certified Python public source contracts | 0 / 508 | **0 / 508** |

Stage 17 owner-run RStudio verification passed 68 native + 39 full frozen ledger + 81 Python 1.2 numerical-oracle assertions. Stage 18 source/tests are **authored but not yet runtime qualified**; cross-OS GitHub CI must actually execute steps before assigning scientific qualification.

## Windows RStudio instructions

```r
pkgload::load_all('.', quiet=TRUE)
testthat::test_local('.', filter='native-stage18-mixed-diagnostics')
testthat::test_local('.', filter='full-native-r-parity-ledger')
stopifnot(identical(et_python_version(), '1.2.0'))
Sys.setenv(ET_RUN_PYTHON_TESTS='true')
tryCatch(testthat::test_local('.', filter='native-stage18-mixed-diagnostics'),
  finally=Sys.unsetenv('ET_RUN_PYTHON_TESTS'))
```

No merges, publication, version bumps or one-to-one source-contract certifications permitted.