# Joint functional B-spline mixed effects with within-curve serial residual correlation

Fits a single Gaussian mixed model with smooth functional fixed effects
and unstructured participant B-spline random intercepts, with estimated
within-trajectory serial residual correlation. The correlation is
blocked by source curve and never crosses distinct trials. Uses optional
R package nlme; no Python installation is needed.

## Usage

``` r
etr_fit_joint_bspline_functional_correlated(
  trajectories, design, predictors, participant_column, dimension,
  residual_correlation = "ar1", fixed_basis_size = 6L,
  random_basis_size = 4L, spline_degree = 3L,
  reml = TRUE, maxiter = 500L
)
```

## Arguments

- trajectories:

  A complete, finite native trajectory set.

- design:

  Data frame with one unique `curve_id` row per trajectory.

- predictors:

  Unique numeric fixed-effect predictors in `design`.

- participant_column:

  Metadata field identifying participant groups.

- dimension:

  Name of one functional response dimension.

- residual_correlation:

  `"ar1"` for index-step AR(1) on equally spaced grids; `"exponential"`
  for continuous-time exponential decay on increasing grids.

- fixed_basis_size:

  Number of clamped fixed-effect B-spline basis functions.

- random_basis_size:

  Number of clamped participant random-intercept B-spline basis
  functions.

- spline_degree:

  Spline degree 1 to 5.

- reml:

  Use restricted ML if `TRUE`; otherwise ML.

- maxiter:

  Maximum optimizer iterations (at least 10).

## Details

The exponential correlation is \\\exp(-\|t-s\|/\phi)\\ on the original
time-unit scale. AR(1) uses \\\rho^{\|i-j\|}\\ and requires a nearly
regular grid. The implementation internally rescales time for numerical
conditioning and reports \\\phi\\ in original time units. It fits an
additional joint likelihood rather than only correcting standard errors.
Nested trial random effects and participant random slopes are not fitted
by this particular method. Python 1.2 full-domain parity is not claimed.

## Value

An `etr_joint_bspline_mixed_correlated` object inheriting from
`etr_joint_bspline_mixed`, with coefficient curves, SEs, Gaussian
variance components, estimated residual correlation family/parameter and
matrix, fitted curves, residuals, provenance and the underlying `nlme`
fit.
