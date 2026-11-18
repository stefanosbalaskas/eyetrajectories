# Plot function-on-scalar coefficient and optional source simultaneous-band artists

Represent scientific plotting geometry from frozen eyetrajectoriespy
1.2.0 without changing native statistical estimators, default base
graphics or native numerical outputs.

## Usage

``` r
etr_plot_function_on_scalar_coefficients(result, coefficient, dimension = NULL,
  band = NULL, strict_source_record = FALSE, ...)
```

## Arguments

- result:

  Native precomputed observed-grid FoSR fit. In strict source mode a
  native simultaneous-band result may also be supplied as the primary
  result.

- coefficient:

  Exact coefficient name or zero-based coefficient index.

- dimension:

  Optional named functional channel, defaulting to the first channel.

- band:

  Optional native simultaneous band corresponding to the exact supplied
  fitted result; default NULL. Strict mode also accepts this band as the
  primary result, but not both locations.

- strict_source_record:

  If TRUE return typed native source-scientific Matplotlib artist
  coordinates including band-before-line ordering, 1-decimal calibrated
  percentage/scope, coefficient legend and dashed zero reference.

- ...:

  Existing base R plotting options.

## Value

Default invisibly returns the original observed-grid coefficient and
optional confidence limits. Strict mode returns scientific artist
geometry with band-first plotting, original coefficient line/labels and
dashed horizontal zero reference, not a Python Matplotlib Axes.

## Details

Only bounded native R scientific geometry is represented, not an actual
Python Matplotlib Axes, Python dataclass/pandas acceptance,
pixel-identical rendering, Python exception-class identity or
independently certified full API parity.
