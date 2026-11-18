# Joint native B-spline functional mixed-effects model

Fits a Gaussian joint functional mixed model with B-spline fixed
coefficient functions and participant random B-spline intercept
functions. Uses the native R package nlme; never invokes Python.

## Usage

``` r
etr_fit_joint_bspline_functional_mixed_effects(
  trajectories, design, predictors, participant_column, dimension,
  fixed_basis_size = 6L, random_basis_size = 4L,
  spline_degree = 3L, reml = TRUE, maxiter = 500L
)
```

## Arguments

- trajectories:

  Finite complete native trajectory set on one grid.

- design:

  Data frame containing unique `curve_id` and numeric predictors.

- predictors:

  Character vector of unique fixed predictor column names; can be empty.

- participant_column:

  Participant grouping column in trajectory metadata.

- dimension:

  Response dimension name.

- fixed_basis_size:

  Number of clamped fixed-effect B-spline basis functions.

- random_basis_size:

  Number of random-intercept B-spline basis functions.

- spline_degree:

  B-spline degree (1 through 5), requiring basis size at least degree+1.

- reml:

  Whether to use REML rather than ordinary maximum likelihood.

- maxiter:

  Maximum number of nlme optimizer iterations.

## Value

S3 `etr_joint_bspline_mixed` list containing functional coefficients,
pointwise standard errors, random-effect coefficient covariance,
participant random functions, variance components, fitted and residual
trajectories, a `residual_correlation_matrix` equal to the time-grid
identity matrix, and an
[`nlme::lme`](https://rdrr.io/pkg/nlme/man/lme.html) fitted model.

## Details

This estimator implements the basic participant random-intercept,
independent Gaussian error model with an unstructured B-spline random
effect covariance. It does not fit random slopes, nested trials, or
structured residual correlation. The returned object is an R S3 object,
not the Python `FunctionalMixedEffectsResult`; full Python 1.2 source
parity is not claimed.
