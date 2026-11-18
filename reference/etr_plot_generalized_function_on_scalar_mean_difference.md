# Plot generalized FoSR response-scale contrast with source band geometry

Represent scientific plotting geometry from frozen eyetrajectoriespy
1.2.0 without changing native statistical estimators, default base
graphics or native numerical outputs.

## Usage

``` r
etr_plot_generalized_function_on_scalar_mean_difference(result,
  strict_source_record = FALSE)
```

## Arguments

- result:

  A native precomputed pairwise response-scale difference or ratio and
  simultaneous interval.

- strict_source_record:

  If TRUE, return typed native R scientific source artist geometry
  containing the estimated difference line, 0.2-alpha source interval,
  contrast-appropriate zero/one reference line and source legend.

## Value

Default invisibly returns the original numeric contrast grid and
endpoints. Strict mode returns source ordered estimate, simultaneous
band and horizontal reference artists with preserved confidence level,
scientific labels and declared contrast scale.

## Details

Only bounded native R scientific geometry is represented, not an actual
Python Matplotlib Axes, Python dataclass/pandas acceptance,
pixel-identical rendering, Python exception-class identity or
independently certified full API parity.
