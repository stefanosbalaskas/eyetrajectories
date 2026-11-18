# Plot fixed-target FPCR wild-bootstrap intervals with source artist data

Plots pre-calibrated wild-bootstrap FPCR projection bounds without
refitting the estimator.

## Usage

``` r
etr_plot_fpca_wild_bootstrap_projection(result,
  max_targets = 30L, strict_source_record = FALSE)
```

## Arguments

- result:

  Native FPCR wild-bootstrap fixed-target interval result.

- max_targets:

  Positive integer maximum target count.

- strict_source_record:

  Logical scalar; return source-specific Matplotlib errorbar geometry as
  typed R data when TRUE.

## Value

Invisibly, original numeric geometry and backend provenance by default;
in strict mode a typed source artist record with exact asymmetric
y-errors, zero reference, ticks and legend. No Python Axes is returned.

## Details

Matplotlib backend identity, Python exception classes and full
Python-object acceptance remain outside the bounded native
source-scientific comparison.
