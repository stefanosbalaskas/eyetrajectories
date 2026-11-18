# Observed-grid simultaneous profile predictions from fixed bootstrap draws

Calibrates observed-grid inverse-link endpoints with frozen standardized
maxima and NumPy higher quantile semantics. No claim of coverage between
grid points or complete Python 1.2 public contract equivalence.

## Usage

``` r
etr_generalized_function_on_scalar_prediction_bands(
  bootstrap, confidence_level = 0.95, simultaneous_scope = "profile"
)
```

## Arguments

- bootstrap:

  Native fixed-profile prediction bootstrap result.

- confidence_level:

  Probability strictly between zero and one.

- simultaneous_scope:

  Either "profile" or "family".

## Value

Native source-shaped intervals, original maxima, and critical values.
