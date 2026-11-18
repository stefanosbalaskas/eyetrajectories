# Plot empirical one-dimensional Poincare return map scientific source artists

Native scientific geometry for the frozen Python 1.2 nonlinear plotting
contract. Scientific estimators and the default base R graphics return
are unchanged.

## Usage

``` r
etr_plot_poincare_return_map(crossings, fit = NULL, strict_source_record = FALSE, ...)
```

## Arguments

- crossings:

  Native one-dimensional Poincare crossing states with at least two
  crossings.

- fit:

  Optional native one-dimensional local affine return map.

- strict_source_record:

  Logical scalar selecting typed native scientific Matplotlib artist
  geometry.

- ...:

  Legacy base R graphics options.

## Value

Native default invisibly returns consecutive states and optional
100-point affine fit. Strict mode records source successive-crossing
scatter, identity diagonal and optional dashed affine return map with
exact source axes labels and legend.

## Details

The strict source record does not return a live Python Matplotlib Axes,
accept arbitrary Python dataclasses, reproduce Python exception classes,
or establish pixel parity. No independent full-contract certification is
claimed.
