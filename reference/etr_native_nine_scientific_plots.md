# Native R FPCA, simultaneous-band and recurrence visualizations

Nine Python-free native R scientific plots derived from the explicitly
declared FPCA bootstrap, influence, cross-validation, outlier,
functional-band and recurrence analysis result objects.

## Plotting parameters

- result:

  Compatible native R result for the individual plot.

- metric:

  Declared influence summary, eigenspace stability or recurrence
  functional metric.

- dimension:

  Functional-band dimension name; defaults to the first.

- max_points:

  Maximum accepted recurrent cells in joint recurrence, or `NULL`.
  Exceeding it raises an error rather than subsampling.

- show_mean:

  Overlay an across-curve mean of functional RQA samples.

- max_curves:

  Maximum plotted source curves, or `NULL`.

- parameter:

  Declared varying RQA sensitivity parameter column.

- filters:

  Named list restricting the other varying RQA parameters to explicit
  fixed values.

- ...:

  Further base R graphics options.

## Value

Each routine draws on the active R graphics device and returns its
plotted numeric geometry invisibly. Native R return objects are not
Python Matplotlib Axes and thus do not satisfy full Python source-output
type and graphical backend contracts.

## Details

No estimator is recomputed, no hidden smoothing, reweighting or
hypothesis selection is performed, and no declared uncertainty coverage
is extended from the observed time grid to a continuous domain. RQA
sensitivity is descriptive, with other varying parameters required to be
held constant explicitly. Full public source contract certification
requires independent source-domain/schema review.
