# Plot familywise and target-wise FPCR wild-bootstrap intervals

Displays the original calibrated familywise and target-wise centered
Gaussian FPCR projections. No new wild-bootstrap draws, multiple-testing
adjustments or scientific extrapolations are introduced.

## Usage

``` r
etr_plot_fpca_wild_bootstrap_simultaneous_interval(result,
  max_targets = 30L, show_targetwise = TRUE,
  strict_source_record = FALSE)
```

## Arguments

- result:

  Already-calibrated native fixed-family wild-bootstrap simultaneous
  projection result.

- max_targets:

  Positive integer number of fixed trajectories plotted.

- show_targetwise:

  Logical flag controlling the additional per-target interval.

- strict_source_record:

  If TRUE, return a typed native R record of frozen Python 1.2
  scientific Matplotlib errorbars; otherwise return the original
  numerical frame.

## Value

Invisible numerical fixed-target interval frame by default. In strict
mode, a typed `etr_fpca_inference_artist_source_record` with asymmetric
familywise errorbar, optional target-wise errorbar, zero reference and
source axes metadata. Does not return Python Matplotlib Axes.

## Details

Strict mode covers source-scientific artist coordinates and labels only,
not Matplotlib runtime identity, backend pixels, Python error classes,
or independent full-source certification.
