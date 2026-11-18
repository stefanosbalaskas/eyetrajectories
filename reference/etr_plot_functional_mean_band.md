# Plot fitted functional mean with its simultaneous observed-grid uncertainty band

Plots the retained simultaneously calibrated functional mean uncertainty
on its original observed grid and confidence level without constructing
new bounds. Source geometry is compared to Python 1.2 Matplotlib
`fill_between` data and line artist, but Python class identity, backend
rasterization, and rendering color equality are not claimed.

## Usage

``` r
etr_plot_functional_mean_band(
    result, dimension = NULL, strict_source_record = FALSE, ...)
```

## Arguments

- result:

  Native scientifically estimated functional mean-band result, with
  source time grid, dimension-named finite mean, lower and upper
  matrices, and the actual declared simultaneous confidence level.

- dimension:

  Exact existing dimension name. If NULL, selects the first declared
  functional channel as in frozen Python 1.2.

- strict_source_record:

  If TRUE, draw the native R figure and return one source-scientific
  Matplotlib-like band artist with original time/lower/upper,
  transparency `0.2`, source confidence-level label, mean-line values
  and legend order. This is an R data record, not a Python `Axes`.

- ...:

  Additional native base R plot options.

## Value

Default invisible time, mean, lower and upper data frame for one
channel. Strict mode returns a native R source-scientific two-artist
geometry record retaining the observed-grid simultaneous band and
functional mean in the source order.
