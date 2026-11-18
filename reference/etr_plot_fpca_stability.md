# Native FPCA bootstrap stability with inspectable source-scientific boxplot geometry

Plots the actual native FPCA bootstrap matched similarities, not
invented effect estimates. The source-scientific geometry follows frozen
Python 1.2 NumPy linear 25th/50th/75th percentiles and 1.5-IQR whisker
boundaries. Native base graphics and Python Matplotlib render
differently; source Matplotlib class identity and pixel equality are not
provided.

## Usage

``` r
etr_plot_fpca_stability(result, strict_source_record = FALSE, ...)
```

## Arguments

- result:

  Real native bootstrap FPCA stability result with one column of finite
  absolute matched component similarities for each retained reference
  FPC.

- strict_source_record:

  Return native R source-scientific artist data, with exact raw
  replicate similarities, source quartiles and 1.5-IQR whiskers. The
  result is not a Python Matplotlib `Axes`.

- ...:

  Additional native base-R boxplot drawing arguments.

## Value

By default, the original native replicate-similarity matrix invisibly.
In strict mode, an invisible scientific artist record with one box per
reference component, original score vectors, source quartiles, whiskers,
outlier values, labels and common 0 to 1.02 y-range.
