# Plot generalized FoSR link-scale coefficient scientific source geometry

Represent scientific plotting geometry from frozen eyetrajectoriespy
1.2.0 without changing native statistical estimators, default base
graphics or native numerical outputs.

## Usage

``` r
etr_plot_generalized_function_on_scalar_coefficients(result, coefficient,
  strict_source_record = FALSE)
```

## Arguments

- result:

  A precomputed generalized function-on-scalar coefficient fit or
  simultaneous coefficient-band record.

- coefficient:

  Exact name of the fitted link-scale coefficient.

- strict_source_record:

  If TRUE, return typed R source scientific artists for the coefficient
  line, conditional simultaneous band, link-scale label and horizontal
  zero reference.

## Value

Default invisibly returns original fitted link-scale values and any
available interval. Strict mode returns the source line/optional
alpha-0.2 fill and reference line with labels and declaration of the
original link scale.

## Details

Only bounded native R scientific geometry is represented, not an actual
Python Matplotlib Axes, Python dataclass/pandas acceptance,
pixel-identical rendering, Python exception-class identity or
independently certified full API parity.
