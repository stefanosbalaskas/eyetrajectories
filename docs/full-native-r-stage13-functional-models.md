# Stage 13 — native functional OLS, bootstrap, nonlinear diagnostics and simulation

Published source reference: `eyetrajectoriespy==1.2.0` (`function_on_scalar.py`, `embedding.py`, `return_maps.py`, `simulate.py`, `io.py`). Ten **genuine Python-free R numerical operations** were authored; none calls a Python bridge.

| Python public source callable | Native R counterpart | Method |
|---|---|---|
| `fit_function_on_scalar_regression` | `etr_fit_function_on_scalar_regression` | Observed-grid OLS and HC1 sandwich |
| `bootstrap_function_on_scalar_coefficients` | `etr_bootstrap_function_on_scalar_coefficients` | Fixed-design wild functional-residual bootstrap |
| `function_on_scalar_simultaneous_bands` | `etr_function_on_scalar_simultaneous_bands` | Studentized maximum simultaneous bands |
| `function_on_scalar_coefficient_frame` | `etr_function_on_scalar_coefficient_frame` | Coefficient/band long-form grid values |
| `embedding_delay_diagnostics` | `etr_embedding_delay_diagnostics` | Delay ACF + histogram AMI diagnostics |
| `embedding_dimension_diagnostics` | `etr_embedding_dimension_diagnostics` | Exact brute-force FNN dimensions |
| `return_map_stability` | `etr_return_map_stability` | Empirical return-map Jacobian eigenvalue stability |
| `simulate_planar_trajectories` | `etr_simulate_planar_trajectories` | Repeat-participant planar gaze simulator |
| `simulate_aoi_probability_trajectories` | `etr_simulate_aoi_probability_trajectories` | AOI probability simplex simulator |
| `from_irregular_long_dataframe` | `etr_from_irregular_long_dataframe` | Explicit irregular-to-grid resampling |

## Numerical boundaries and independent-unit design

- Function-on-scalar OLS computes a common scalar design regression at every observed time×channel grid cell. The coefficient index includes `Intercept`. Pointwise HC1 standard errors use the exact sample-size/residual-df correction. No basis smoothing, regularization, hidden categorical encoding, scaling, or model selection.
- `unit='participant'` takes one **equal-weight participant mean function** per independent participant; all specified scalar predictors must be identical within that participant. Trial-varying predictors are rejected rather than silently misrepresented as between-participant effects.
- Wild bootstrap multiplies **whole functional residuals** by one weight per independent unit and replicate (Rademacher or Gaussian), refitting coefficients under a fixed design. NumPy RNG and base-R RNG sequences differ and no seed-to-seed equality is claimed. All methods preserve the caller's R RNG state.
- Simultaneous bands use the empirical **higher** order statistic of maximum absolute studentized deviations, either coefficient-wise or over the coefficient family. Zero-SE cells receive zero-width bands. These are **observed-grid finite-replicate approximations**, not continuous-domain or prequalified frequentist coverage guarantees.
- Embedding delay uses a global signal range, common histogram edges, autocorrelation with common denominator, and a strictly interior AMI local-minimum **diagnostic without automatically selecting a lag**. The current native R API supports sample lags with approximately regular physical-time grids only; time-unit delay resolution remains unsupported.
- FNN checks explicit positive-distance temporally separated nearest neighbors with exact brute-force search, capped at 2,500 samples. Ties may be resolved differently than SciPy `cKDTree`. No automatic dimension selection.
- Empirical return-map stability uses Jacobian eigenvalues and declared tolerance; contraction/expansion is **not** interpreted as deterministic orbital stability.
- Functional simulators follow the Python model equations and generate complete auditable R trajectory containers. The random engine is base R, **not** NumPy. Consequently same seed does not imply cross-language bitwise equivalence; reproducibility is tested independently in each language.
- Irregular long-to-grid conversion composes earlier native construction and explicit resampling; no extrapolation or hidden interpolation on malformed inputs.

## Frozen inventory (authored code, not contract certification)

| Measure | Stage 12 | Stage 13 authored |
|---|---:|---:|
| Independently authored native R functions | 91 | **101** |
| Mapped Python source function names | 121 / 380 | **131 / 380** |
| Unmapped Python callable names | 259 | **249** |
| Partial representations of other exported objects | 7 / 128 | **7 / 128** |
| Fully qualified public Python source contracts | 0 / 508 | **0 / 508** |

Stage 12 owner-run Windows RStudio verification: 69 native assertions pass with one expected Python skip; 39 strict ledger assertions pass; 79 pinned Python 1.2 oracle assertions pass, zero failures. Stage 13 tests and direct pinned Python OLS oracle are **authored, not yet executed**. GitHub Actions may fail job admission before any test step, in which case the conclusion is infrastructure-related and does not qualify Stage 13.

## RStudio qualification

From `research/native-r-stage13-functional-models-20261028`:

```r
pkgload::load_all('.',quiet=TRUE)
testthat::test_local('.',filter='native-stage13-functional-models')
testthat::test_local('.',filter='full-native-r-parity-ledger')
stopifnot(identical(et_python_version(),'1.2.0'))
Sys.setenv(ET_RUN_PYTHON_TESTS='true')
tryCatch(testthat::test_local('.',filter='native-stage13-functional-models'),
         finally=Sys.unsetenv('ET_RUN_PYTHON_TESTS'))
```

All code remains on a stacked research draft; no merge, release, version bump, CRAN/PyPI publication, inferential coverage declaration, or 508/508 parity certification is authorized.