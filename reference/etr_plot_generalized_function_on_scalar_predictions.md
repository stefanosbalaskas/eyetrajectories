# Plot generalized FoSR fixed-profile source scientific mean curves

Represent scientific plotting geometry from frozen eyetrajectoriespy
1.2.0 without changing native statistical estimators, default base
graphics or native numerical outputs.

## Usage

``` r
etr_plot_generalized_function_on_scalar_predictions(result, strict_source_record = FALSE)
```

## Arguments

- result:

  Native precomputed generalized FoSR fixed-profile prediction or
  prediction-band result.

- strict_source_record:

  Logical flag returning a typed native R record of frozen Python 1.2
  Matplotlib source scientific line and optional alpha-0.2 band artists
  rather than the default numerical graphics geometry.

## Value

Default invisibly returns source mean and optional bound values for each
declared profile. Strict mode returns source-ordered line/band artists,
extrapolation labels, original axes and legend; Python Matplotlib Axes
identity is not reproduced.

## Details

Only bounded native R scientific geometry is represented, not an actual
Python Matplotlib Axes, Python dataclass/pandas acceptance,
pixel-identical rendering, Python exception-class identity or
independently certified full API parity.
