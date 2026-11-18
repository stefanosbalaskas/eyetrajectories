# Native pointwise functional Gaussian random-intercept REML

Fits Gaussian random-intercept mixed models separately at each observed
time using one-dimensional profiled restricted maximum likelihood.
Repeated curves are grouped by participant. This is a native numerical
method, not an exact port of the joint B-spline Python mixed-effects
model.

## Usage

``` r
etr_fit_functional_random_intercept_reml(trajectories, dimension,
  participant_column, design = NULL, predictors = character(),
  lambda_bounds = c(1e-08, 1e+06))
```

## Arguments

- trajectories:

  A complete finite native R trajectory set.

- dimension:

  One named measurement channel.

- participant_column:

  Metadata column identifying independent participant groups.

- design:

  Optional one-row-per-curve data frame containing unique curve_id.

- predictors:

  Character vector of declared numeric fixed-effect columns of design.

- lambda_bounds:

  Finite increasing positive bounds for the nonzero variance-ratio
  optimization. Zero is always separately evaluated.

## Value

An etr_functional_random_intercept_reml list with pointwise fixed
coefficients and standard errors, participant BLUPs, residual and
random-intercept variances, variance ratios, intraclass correlations,
fitted functions, and conditional residuals.

## Details

Model at each observed time is y_i = x_i beta + b_group(i) + error_i,
with independent Gaussian group intercepts and errors. The restricted
profile objective includes the determinant of the fixed-effects
information matrix. No across-time covariance, random slope, or
simultaneous inference is fitted. Boundary solutions are recorded.
