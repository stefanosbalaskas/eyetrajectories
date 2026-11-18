# Plot original and landmark-registered functional trajectories side by side

Does not apply new registration or recompute warps. Every line is
plotted on the source grid in observed curve order with matched
original/registered panels. Frozen Python 1.2 source's `(fig,axes)`
runtime return and pixel-perfect Matplotlib rendering are deliberately
not claimed by native R.

## Usage

``` r
etr_plot_registration(
    result, dimension = NULL, max_curves = 20L,
    strict_source_record = FALSE, ...)
```

## Arguments

- result:

  Real native landmark-registration result retaining original and
  registered trajectories on their original common time grid, dimension
  names and curve identifiers.

- dimension:

  Exact named native functional dimension. If NULL, select the first
  source channel.

- max_curves:

  Positive integer maximum number of first-seen curves displayed in each
  panel.

- strict_source_record:

  Return a native R scientific artist record preserving Python's two
  source panels, per-curve data, alpha 0.25, axis titles, figure size
  intent and curve ordering. No real Python Figure or Axes objects are
  produced.

- ...:

  Native base graphics plot options.

## Value

Default invisible original and registered per-curve data frames and
metadata. Strict mode returns a native R two-panel source scientific
artist record.
