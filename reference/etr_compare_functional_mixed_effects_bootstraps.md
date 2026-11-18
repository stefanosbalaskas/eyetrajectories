# Compare fixed-covariance and full-refit mixed functional bands

Descriptive comparison of already retained source-model bootstrap
arrays; never fits or selects a model. R value equality of source-shaped
reference objects is not Python's `is` object identity requirement and
full source contract certification remains open.

## Usage

``` r
etr_compare_functional_mixed_effects_bootstraps(
  fixed_covariance_bootstrap,
  full_refit_bootstrap,
  confidence_level = 0.95,
  simultaneous_scope = "coefficient"
)
```

## Arguments

- fixed_covariance_bootstrap:

  Source-shaped retained conditional covariance bootstrap.

- full_refit_bootstrap:

  Source-shaped retained full-refit bootstrap.

- confidence_level:

  Nominal confidence level in (0,1).

- simultaneous_scope:

  Either `"coefficient"` or `"family"`.

## Value

One data frame row per coefficient/time observation with fixed
covariance and full-refit band widths and their ratio (infinity when the
fixed-covariance band is zero-width).
