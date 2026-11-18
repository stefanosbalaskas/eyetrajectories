# Plot pointwise Gaussian FPCR slope uncertainty with source artist geometry

Plot pointwise bootstrap percentile uncertainty for the Gaussian FPCR
slope without changing the estimator, bootstrap replicates, or
uncertainty bounds.

## Usage

``` r
etr_plot_fpca_regression_slope_uncertainty(result,
  dimension = NULL, strict_source_record = FALSE)
```

## Arguments

- result:

  Previously estimated FPCR regression uncertainty record with
  observed-grid slopes and bootstrap percentile bounds.

- dimension:

  Optional fitted functional dimension name.

- strict_source_record:

  If TRUE, return native scientific Matplotlib source geometry metadata
  as a typed R record; otherwise return the original numeric geometry.

## Value

Invisibly the original native plot geometry and provenance by default.
Strict mode returns typed source artist data for the pointwise fill band
(alpha 0.2), reference slope curve, zero line, labels, axes and legend.
No Python Matplotlib Axes is returned.

## Details

Developer-reviewed source-scientific data geometry is not independent
certification of full Python API parity, error classes, rendering pixels
or backend identity.
