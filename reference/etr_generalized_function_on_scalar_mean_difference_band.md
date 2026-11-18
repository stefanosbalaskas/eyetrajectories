# Observed-grid simultaneous contrast between two fixed generalized FoSR profiles

Calibrates one fixed predeclared observed-grid marginal contrast, using
retained participant bootstrap predictions. Rate-ratio inference is
calibrated on the log-ratio scale. Physical bounds are audited but never
silently clipped. This is not a certified complete Python source
contract.

## Usage

``` r
etr_generalized_function_on_scalar_mean_difference_band(
  bootstrap, profile_a, profile_b, confidence_level = 0.95,
  contrast_scale = NULL
)
```

## Arguments

- bootstrap:

  Retained fixed-profile native prediction bootstrap record.

- profile_a:

  First predeclared profile identifier.

- profile_b:

  Second distinct predeclared profile identifier.

- confidence_level:

  Nominal confidence probability strictly inside zero and one.

- contrast_scale:

  Family-compatible probability, rate, ratio or expected-count contrast.

## Value

A native fixed-contrast inference record of estimates, intervals,
bootstrap statistics, scope and explicit scientific limitations.
