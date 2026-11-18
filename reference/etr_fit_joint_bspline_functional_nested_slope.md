# Joint native B-spline mixed model with participant random slope and nested trial effects

Fits one native Gaussian functional mixed-effects model with an
unstructured participant random intercept/slope B-spline coefficient
covariance, separate unstructured trial random coefficient covariance,
and optional per-trial AR(1) or physical-time exponential residual
correlation.

## Usage

``` r
etr_fit_joint_bspline_functional_nested_slope(
  trajectories, design, predictors, participant_column, trial_column,
  dimension, random_slope_predictor, residual_correlation = "iid",
  fixed_basis_size = 6L, random_basis_size = 4L,
  trial_random_basis_size = 4L, spline_degree = 3L,
  reml = TRUE, maxiter = 500L
)
```

## Arguments

- trajectories:

  Finite complete native trajectory collection on a common strictly
  increasing time grid.

- design:

  Data frame with one unique `curve_id` per source curve.

- predictors:

  Names of numeric fixed predictors including the random-slope
  predictor.

- participant_column:

  Existing participant identifier in trajectory metadata.

- trial_column:

  Distinct trial identifier in metadata: one curve per participant/trial
  pair.

- dimension:

  Name of one response channel.

- random_slope_predictor:

  Named numeric predictor that varies within every participant.

- residual_correlation:

  One of `"iid"`, `"ar1"`, or `"exponential"`. AR(1) requires regular
  spacing.

- fixed_basis_size:

  Fixed-effect B-spline basis size (integer).

- random_basis_size:

  Participant intercept/slope B-spline basis size (integer).

- trial_random_basis_size:

  Nested trial B-spline basis size (integer).

- spline_degree:

  Common B-spline degree, integer 1 through 5.

- reml:

  If `TRUE`, restricted likelihood; otherwise maximum likelihood.

- maxiter:

  At least 10 optimizer iterations.

## Value

Also includes Python-shaped coefficient, participant/trial covariance,
residual-correlation, conditional residual-whitening, and nested trial
ID fields; the original native names remain available. The source
optimizer bounds are diagnostic only and are not enforced by the native
optimizer. The result also includes residual-correlation eigenvalues,
condition number, source optimizer-bound diagnostics, grid regularity
and interval, conditional whitened residual functions, and source-style
trial ID aliases. These are diagnostic/representation additions, not
revised fits. The returned object also includes source-aligned
covariance eigenvalues, condition numbers, near-boundary and singularity
flags for both random levels.

An `etr_joint_bspline_mixed_nested_slope` object inheriting
`etr_joint_bspline_mixed` with coefficient functions and pointwise
standard errors, participant and trial coefficient covariances, BLUP
functions, conditional fitted and residual trajectories, within-trial
serial covariance, and the
[`nlme::lme`](https://rdrr.io/pkg/nlme/man/lme.html) fit.

## Details

This is an additive bounded scientific native-R estimator with a
preliminary participant-only identifiability fit. It does not claim
Python 1.2 optimizer, result representation, error-contract, or complete
scientific source parity. No new frozen Python source gap is closed by
this implementation alone.
