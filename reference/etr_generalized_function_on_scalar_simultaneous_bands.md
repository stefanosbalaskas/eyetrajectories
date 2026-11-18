# Simultaneous generalized FoSR coefficient bands from fixed bootstrap draws

Uses the published Python 1.2.0 max-standardized deviation calibration
and empirical higher quantiles. No automatic model selection or
resampling is performed. Full public contract certification remains
pending.

## Usage

``` r
etr_generalized_function_on_scalar_simultaneous_bands(
  bootstrap, confidence_level = 0.95, simultaneous_scope = "coefficient"
)
```

## Arguments

- bootstrap:

  Explicit source-shaped coefficient-bootstrap record with retained
  whole-participant coefficient function draws.

- confidence_level:

  Nominal confidence probability strictly in (0,1).

- simultaneous_scope:

  Coefficient-wise or full coefficient family maxima.

## Value

Native source-shaped link-scale simultaneous band, retained bootstrap
maximum statistics, critical values, and explicit inference provenance.
