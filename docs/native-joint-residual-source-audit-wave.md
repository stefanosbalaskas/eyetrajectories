# Native Gaussian mixed-effects residual diagnostics on actual joint likelihood fits

**Frozen scientific source:** eyetrajectoriespy 1.2.0 at
`c1cd95ad718327550f7e55393ff38582872f7a94`,
`functional_mixed_effects_diagnostics.py`.
**Parent:** locally qualified source-frame PR #73,
`bde2849fdfc0b418998e5d985a926f454d995f4b`.

## Source-domain implementation

The public residual-diagnostics and comparison functions historically required
the restricted `etr_functional_mixed_moments` estimator. The package now
has real joint B-spline `nlme::lme` likelihood models supporting participant
intercept, participant slope, nested trial intercept and nested trial+slope.
This wave directly connects those actual fits to **four existing public
Python-source-mapped numerical APIs**, without statistical refitting:

- `etr_functional_mixed_effects_whitened_residuals`: conditional residual
  functions whitened within source curve/trial by the fitted covariance
  Cholesky factor, `V = residual_variance * residual_correlation_matrix`.
- `etr_functional_mixed_effects_residual_diagnostics`: per-curve trial lags,
  participant and overall pair-count-weighted summaries for autocovariance,
  autocorrelation and semivariance, preserving observed physical time offsets.
- `etr_functional_mixed_effects_residual_pair_frame`: exact residual
  endpoints, physical lag and squared-difference contributions at an explicit
  index lag, including optional source curve / participant filtering.
- `etr_compare_functional_mixed_effects_residual_diagnostics`: matched
  raw or whitened source residual diagnostics across two declared models,
  with comparison-minus-reference differences. No covariance model selection.

The already public `etr_functional_mixed_effects_residual_diagnostic_frame`
continues to work with the resulting diagnostics object.

For the two basic joint intercept and joint random-slope R fit objects,
the actual source `time_unit`, `dimension_name` and
`source_curve_ids` are now returned. The nested trial fits already retained
those fields. This is source metadata retention, not an estimator change.

## Numerical boundary

The adapter requires a real native joint `nlme::lme` fit, finite strict time
grid, explicit time units, complete unique source IDs, aligned participant IDs,
finite conditional residual functions, positive residual variance, and a finite
symmetric n_time-by-n_time residual correlation matrix. Whitened mode requires
a positive-definite full covariance (via Cholesky). It rejects malformed
inputs instead of silently treating them as independent.

The legacy restricted method-of-moments results and diagnostic outputs retain
their previous numerical formulas and provenance. Joint likelihood results
use different provenance fields:
`native_joint_nlme_likelihood_not_python_optimizer`. This avoids representing
the joint likelihood fit as the older restricted moments estimator.

## What remains unqualified

R/nlme optimizer and boundary conditions are different from the frozen
statsmodels/SciPy Python likelihood backend. Python dataclass identity,
pandas error classes, exact source Python reporting text, all optimizer
settings, nonfinite coercion and complete input domains are *not* asserted
equal. No source-gap ledger entry is closed and no independent certification
is claimed. Conditional residual diagnostics alone do not determine whether
the selected residual covariance family is scientifically preferable.

## Verification

```r
Sys.setenv(ET_RUN_NATIVE_JOINT_WORKFLOW_INTEGRATION="true")
source("scripts/run_native_joint_residual_source_wave_gate.R",
       encoding="UTF-8")
```

Run from the clean PR branch root. The one-pass gate executes targeted
native R + live likelihood integration tests, repository scientific and
Rd preflights, full native / frozen Python 1.2 author qualification, and
a clean Git snapshot `R CMD build` and `R CMD check --as-cran`
with remote incoming checking disabled.

The analytical regression tests include IID and AR(1)-like Cholesky
whitening, independently calculated physical-lag autocovariance /
autocorrelation / semivariance, zero-variance trial behavior, exact pair
endpoints on an irregular grid, two-fit comparison differences,
invalid input fail-closed tests, and an actual eight-participant `nlme`
likelihood fit. The code and tests were committed to GitHub; local RStudio
qualification remains required before the PR can be merged.
