# Native joint fit → Python-source numerical variance and coefficient frames

Pinned Python source: `eyetrajectoriespy==1.2.0`,
`c1cd95ad718327550f7e55393ff38582872f7a94`.
Builds on the locally qualified PR #72 commit
`d1312e5e07575701a912d380b2645b62aaec0846`.

## Implemented numerical interface

The existing public `etr_functional_mixed_effects_variance_decomposition()`
and `etr_functional_mixed_effects_coefficient_frame()` previously handled
either explicit typed-source-shaped list records or the restricted
method-of-moments result. The actual native joint `nlme::lme` fits could not
be supplied directly.

Both functions now dispatch on `inherits(fit,"etr_joint_bspline_mixed")`,
preserve their prior moments and manually assembled record paths, and
expose the established source-level descriptive calculations on the
**already estimated** covariance and coefficient arrays.

The variance decomposition computes on each observed time-grid point:

- participant-intercept variance: `diag(B G_intercept B^T)`;
- optional participant-slope variance: `diag(B G_slope B^T)`;
- optional *signed* intercept/slope cross-covariance:
  `diag(B G_intercept,slope B^T)` (not doubled or recast as a variance);
- optional nested-trial variance:
  `diag(B_trial G_trial B_trial^T)`;
- grid-level residual variance, from the fitted `sigma^2` scalar.

Rows retain the Python source naming/order, including separate
`component_type="covariance"` for the signed cross component.
The source's descriptive decomposition **does not** use the term
`2 * covariance` to represent the covariance row. Nor does it
imply that components form percentage contributions at all predictor
settings. No predictor-specific random-effect variance curve or
stochastic band is fabricated.

The coefficient function retains the seven source-ordered columns,
95% pointwise normal Wald intervals, and source coefficient/time row order.
Simultaneous bootstrap `band` inputs remain explicitly unsupported for
this native joint-fit adapter.

## Scientific scope and limits

This is a real functional addition: it makes the public Python-mapped
**numerical reporting APIs work directly with native joint likelihood
models**, including all four source-family combinations introduced in PR #72.
The workflow estimator is not changed; no fit is rerun or optimizer
replaced.

Differences remain in R vs Python optimizer, convergence boundaries,
input classes, errors, source dataclass identity, and complete domains.
Therefore no 508-export ledger gap is closed, and independent
certifications remain 0/508. This is implementation evidence, not a
full-domain source equivalence certificate.

## Tests

Deterministic R regression tests cover all four native covariance
structures and check matrix-quadratic values independently for each
component; signed cross-covariance is kept distinct from variances.
Malformed covariance shapes, invalid residual variance, invalid basis
and unsupported band arguments must fail.

The previously exercised eight-participant Gaussian likelihood fixture
is run **only with explicit opt-in** `ET_RUN_NATIVE_JOINT_WORKFLOW_INTEGRATION=true`.
It then calls both public numerical functions directly on the actual
`nlme` fit and checks the returned coefficients against the workflow
coefficient table. The full Python 1.2 developer qualification and
clean Git HEAD CRAN-style build/check remain mandatory before merge.

## RStudio verification

```r
Sys.setenv(ET_RUN_NATIVE_JOINT_WORKFLOW_INTEGRATION="true")
source("scripts/run_native_joint_source_variance_wave_gate.R",encoding="UTF-8")
```

This requires the current PR branch and runs the changed tests,
preflights, full developer source qualification, and clean snapshot
CRAN-style check. Hosted GitHub CI failures with zero executed steps
do not count as a local scientific test failure or a PASS.
