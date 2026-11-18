# Plot Gaussian FPCR simultaneous slope bands with source artist geometry

Plot the original observed-grid simultaneous FPCR slope band without
recalibrating uncertainty or recomputing FPCR.

## Usage

``` r
etr_plot_fpca_regression_slope_band(result, dimension = NULL,
  strict_source_record = FALSE)
```

## Arguments

- result:

  Pre-calibrated Gaussian FPCR slope-band record, including regression
  uncertainty and simultaneous bands.

- dimension:

  Optional exact fitted functional dimension; defaults to the first
  dimension.

- strict_source_record:

  If TRUE, return native typed scientific artist data corresponding to
  frozen Python 1.2 Matplotlib geometry. FALSE retains the original
  base-R plot and invisible numerical return.

## Value

Invisibly a base-R plotting geometry list by default, or a typed
`etr_fpca_inference_artist_source_record` with observed-grid
`fill_between` confidence band, alpha 0.2, reference slope, zero line,
and source axes and legend metadata in strict mode. No live Python Axes
object is returned.

## Details

Strict mode records bounded source-scientific geometry and does not
provide complete Python dataclass, Axes, exception-class or pixel
parity. Independent verification remains outstanding.
