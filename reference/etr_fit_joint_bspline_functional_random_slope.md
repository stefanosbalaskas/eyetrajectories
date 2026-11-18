# Joint B-spline functional Gaussian mixed-effects random slope

Fits joint participant random-intercept and one random-slope functional
B-spline model in native R using nlme. Participant random B-spline
coefficients share an unstructured covariance; iid Gaussian residuals
are assumed.

## Usage

``` r
etr_fit_joint_bspline_functional_random_slope(
  trajectories, design, predictors, participant_column, dimension,
  random_slope_predictor, fixed_basis_size = 6L, random_basis_size = 4L,
  spline_degree = 3L, reml = TRUE, maxiter = 500L
)
```

## Arguments

- trajectories:

  Finite complete native trajectory collection.

- design:

  Data frame containing a unique curve_id per source curve and numeric
  predictors.

- predictors:

  Names of explicitly selected fixed scalar predictors.

- participant_column:

  Participant identifier column in trajectory metadata.

- dimension:

  Name of one measured response channel.

- random_slope_predictor:

  Exactly one member of predictors; must vary within each participant.

- fixed_basis_size:

  Number of clamped B-spline fixed-effect basis functions.

- random_basis_size:

  Number of clamped B-spline functions per random intercept and random
  slope.

- spline_degree:

  B-spline degree, from 1 to 5.

- reml:

  Logical. TRUE performs REML; FALSE performs ML.

- maxiter:

  Maximum nlme optimizer iterations.

## Value

S3 `etr_joint_bspline_mixed_slope` inheriting from
`etr_joint_bspline_mixed`, with fixed coefficient functions, SE,
participant random intercept and slope functions, joint random
covariance, residual variance, an IID `residual_correlation_matrix`
equal to the time-grid identity matrix, fitted values, observed values
and an nlme fit.

## Details

This is an explicitly bounded native R implementation of the
participant-only, one-slope, independent-residual scientific model. It
does not claim full equivalence with the Python 1.2 statsmodels
optimizer, error domain, typed results, nested random trial effects, or
structured residual correlation. The participant count must exceed the
number of free unstructured random-effect covariance parameters.
