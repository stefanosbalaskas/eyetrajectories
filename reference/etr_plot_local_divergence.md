# Plot local or Kantz divergence and an optional Lyapunov fit

Native scientific geometry for the frozen Python 1.2 nonlinear plotting
contract. Scientific estimators and the default base R graphics return
are unchanged.

## Usage

``` r
etr_plot_local_divergence(result, strict_source_record = FALSE, ...)
```

## Arguments

- result:

  Native local/Kantz divergence or largest-Lyapunov result with fit
  window and physical time unit.

- strict_source_record:

  Logical scalar for typed native scientific artists in frozen Python
  source coordinates.

- ...:

  Legacy base R graphics options.

## Value

Native default invisibly returns the original divergence data and
finite-window fit estimates; strict mode records source divergence line
and optional fitted Lyapunov line using the correct physical time-unit
conversion.

## Details

The strict source record does not return a live Python Matplotlib Axes,
accept arbitrary Python dataclasses, reproduce Python exception classes,
or establish pixel parity. No independent full-contract certification is
claimed.
