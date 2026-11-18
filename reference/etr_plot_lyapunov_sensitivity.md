# Plot source scientific Rosenstein Lyapunov parameter sensitivity

Present frozen eyetrajectoriespy 1.2.0 scientific plotting geometry
while retaining original native R numeric calculations, data, graphics
and estimator semantics.

## Usage

``` r
etr_plot_lyapunov_sensitivity(result, parameter, response = "exponent", filters = NULL,
  strict_source_record = FALSE, ...)
```

## Arguments

- result:

  Native precomputed Lyapunov sensitivity grid.

- parameter:

  Exact parameter of the source sensitivity slice.

- response:

  A supported LLE exponent, standard-error, fit-quality, or pair-count
  output.

- filters:

  Optional fixed tuning parameter values.

- strict_source_record:

  Logical scalar yielding native source-scientific plotting artist data
  when TRUE.

- ...:

  Legacy base R plotting options.

## Value

Invisible original numerical sensitivity table by default. Strict mode
returns typed native R line artist geometry with source title and
physical unit, and zero-exponent reference only for exponent response.

## Details

Strict artist records cover a bounded native source-scientific geometry
domain. No actual Python Matplotlib Axes, Python dataclass/pandas
protocol or exception-class identity, independent complete-domain
certification, or pixel-level rendering equivalence is asserted.
