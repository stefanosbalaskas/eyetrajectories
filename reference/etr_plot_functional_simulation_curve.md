# Plot real native simulated latent functional truth and sparse observations

Uses the actual native simulated latent truth rather than an
interpolation of observed measurements. Missingness and curve
identifiers are preserved. Supports the frozen Python zero-based
scalar-selection semantics in strict mode while retaining the R-native
one-based default. No Python plotting runtime object or pixel-equivalent
rendering is claimed.

## Usage

``` r
etr_plot_functional_simulation_curve(
    result, curve = 1L, dimension = 1L,
    show_pre_missing = FALSE, strict_source_record = FALSE)
```

## Arguments

- result:

  Actual native `etr_functional_simulation_result`, including latent
  truth on a declared grid, original observation times and recorded
  missingness. Strict mode requires this native result class.

- curve:

  Curve ID or index. Default R mode accepts a one-based integer; strict
  scientific source mode accepts a zero-based integer, matching frozen
  Python 1.2. Curve IDs are valid in either mode.

- dimension:

  Declared channel identifier or index. Default R mode is one-based;
  strict scientific source mode is zero-based for numeric indices.

- show_pre_missing:

  Whether to show original observations subsequently removed by the
  experiment's missingness design.

- strict_source_record:

  Return native source-scientific Matplotlib line and scatter data for
  exact latent, observed, and optionally removed observations; not a
  Python `Axes`.

## Value

By default, original numeric latent, observed and removed coordinates;
in strict mode, a one-panel source-scientific artist record with exact
line and scatter coordinate arrays.
