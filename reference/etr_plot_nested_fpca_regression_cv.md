# Plot nested FPCR outer-fold losses with source scientific line geometry

Read-only plot of outer-fold held-out prediction loss from nested
cross-validation, without rerunning FPCR or changing the model-selection
rule.

## Usage

``` r
etr_plot_nested_fpca_regression_cv(result, strict_source_record = FALSE)
```

## Arguments

- result:

  Completed nested FPCR cross-validation record with outer_folds and a
  loss identifier.

- strict_source_record:

  If TRUE, return native R source-scientific artist geometry for frozen
  Python 1.2. FALSE keeps the existing R plot and invisible numeric
  return.

## Value

Invisibly original outer-fold numeric line and provenance by default. In
strict mode, a typed `etr_predictive_scientific_artist_record` with
1-based outer-fold x positions, observed loss y positions, marker, line
style, source labels and title. Never returns Python Matplotlib Axes.

## Details

Python data-class acceptance, Matplotlib return identity and exception
classes remain outside scoped native scientific artist parity; no
independent certification is claimed.
