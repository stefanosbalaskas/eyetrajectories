# Plot selected time-varying RQA metrics using source scientific artists

Native scientific geometry for the frozen Python 1.2 nonlinear plotting
contract. Scientific estimators and the default base R graphics return
are unchanged.

## Usage

``` r
etr_plot_windowed_rqa(result, metrics = c("recurrence_rate", "determinism",
  "laminarity"), strict_source_record = FALSE, ...)
```

## Arguments

- result:

  Native windowed recurrence quantification result on its physical time
  grid.

- metrics:

  Character vector of selected, distinct existing metric columns in
  source order.

- strict_source_record:

  Logical scalar for native source scientific artist geometry.

- ...:

  Legacy base R graphics options.

## Value

Native default invisibly returns the original center-time and selected
RQA metric values. Strict mode gives each source-ordered metric a line
with marker o and source labels and legend.

## Details

The strict source record does not return a live Python Matplotlib Axes,
accept arbitrary Python dataclasses, reproduce Python exception classes,
or establish pixel parity. No independent full-contract certification is
claimed.
