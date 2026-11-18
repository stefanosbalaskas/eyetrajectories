# Plot FPCR conditional-mean bootstrap uncertainty with source scientific artists

Displays pre-estimated paired-bootstrap conditional-mean prediction
uncertainty with source-identical scientific plotting coordinates,
without refitting any estimation procedure.

## Usage

``` r
etr_plot_fpca_regression_mean_prediction_uncertainty(result,
  max_targets = 30L, strict_source_record = FALSE)
```

## Arguments

- result:

  Native paired-bootstrap FPCR conditional-mean uncertainty result and
  full-sample reference predictions.

- max_targets:

  Positive integer number of fixed targets plotted.

- strict_source_record:

  If TRUE, record frozen Python 1.2 scientific Matplotlib errorbar and
  scatter geometry as a typed R record.

## Value

Invisible original base-R numeric interval geometry and provenance by
default. A strict native source artist record contains asymmetric
bootstrap-mean errorbar and full-sample conditional-mean scatter
geometry, source labels and legend. No Matplotlib Axes instance is
created.

## Details

Source coordinates and labels are developer-scoped and distinct from
full Python runtime parity, backend pixels, exception classes and
independent certification.
