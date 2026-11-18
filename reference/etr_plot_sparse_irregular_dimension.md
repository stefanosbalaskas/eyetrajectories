# Plot unchanged irregular functional samples for one named dimension

Draws original, noninterpolated observations on their actual irregular
time grids. The source Matplotlib plot shows a legend when at most
twelve curves are present; the strict native R record retains the same
rule and per-line scientific artist settings. Native graphics device
rendering remains R-specific and is not a Python runtime plotting
object.

## Usage

``` r
etr_plot_sparse_irregular_dimension(
    trajectories, dimension, strict_source_record = FALSE)
```

## Arguments

- trajectories:

  Real native irregular trajectory collection, with per-curve original
  times, dimension-labelled observed values and stable curve
  identifiers.

- dimension:

  A declared dimension name, with no implicit coordinate selection.

- strict_source_record:

  Return an inspectable source-scientific native R record containing all
  Matplotlib-equivalent per-curve line coordinates, curve labels, marker
  `"o"`, line width one, transparency 0.55, axes and legend visibility.
  Do not interpret the record as a real Python Matplotlib Axes.

## Value

By default, invisible original curve IDs, observed times, observed
values and dimension name. In strict mode, source-scientific one-panel
artist geometry with full per-curve scientific trace data.
