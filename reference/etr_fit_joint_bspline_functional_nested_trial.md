# Joint functional mixed effects with nested trial B-spline random functions

Fits a native Gaussian joint functional mixed-effects regression with
separate unstructured participant-level and nested-trial-level B-spline
random-function covariances, optionally with serial correlation confined
to each trial. Requires nlme. Each participant-trial pair must identify
exactly one curve. This is a bounded scientific analogue, not full
Python 1.2 source-contract parity.

## Usage

``` r
etr_fit_joint_bspline_functional_nested_trial(
  trajectories, design, predictors, participant_column, trial_column, dimension,
  residual_correlation = "iid", fixed_basis_size = 6L,
  random_basis_size = 4L, trial_random_basis_size = 3L,
  spline_degree = 3L, reml = TRUE, maxiter = 500L
)
```

## Arguments

- trajectories:

  Complete finite common-grid native trajectory set.

- design:

  Data frame containing one row per curve and a unique `curve_id`.

- predictors:

  Character vector of numeric fixed predictors; may be empty.

- participant_column:

  Participant grouping column in trajectory metadata.

- trial_column:

  Distinct within-participant trial identifier in metadata.

- dimension:

  One response channel name.

- residual_correlation:

  `"iid"`, `"ar1"` on a regular grid, or `"exponential"` using time
  distances.

- fixed_basis_size:

  Positive integer number of fixed spline functions.

- random_basis_size:

  Positive integer participant random basis size.

- trial_random_basis_size:

  Positive integer nested trial random basis size.

- spline_degree:

  Spline degree, 1 through 5.

- reml:

  Fit by restricted maximum likelihood if TRUE, ML otherwise.

- maxiter:

  Maximum optimizer iterations, at least 10.

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
flags for both random levels. An `etr_joint_bspline_mixed_nested_trial`
S3 object inheriting `etr_joint_bspline_mixed`. Includes fitted and
residual trajectories, fixed coefficient functions and standard errors,
random-function BLUPs, participant and trial coefficient covariances,
residual covariance parameters, and the fitted
[`nlme::lme`](https://rdrr.io/pkg/nlme/man/lme.html) model.
