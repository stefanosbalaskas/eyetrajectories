# Plot per-specification functional windowed RQA sensitivity source artists

Present frozen eyetrajectoriespy 1.2.0 scientific plotting geometry
while retaining original native R numeric calculations, data, graphics
and estimator semantics.

## Usage

``` r
etr_plot_windowed_rqa_sensitivity(result, curve, metric, strict_source_record = FALSE,
  ...)
```

## Arguments

- result:

  Native declared windowed-RQA sensitivity result with per-specification
  analyses.

- curve:

  Zero-based curve index or exact curve ID.

- metric:

  Declared functional RQA metric.

- strict_source_record:

  If TRUE return typed source scientific artist geometry with original
  per-specification time grids and source labels.

- ...:

  Legacy R graphics options.

## Value

Invisible list of original per-specification numeric time series by
default; strict mode returns a typed native artist record with source
marker-o lines and window/step legend on the physical time grid. No
averaging across specifications occurs.

## Details

Strict artist records cover a bounded native source-scientific geometry
domain. No actual Python Matplotlib Axes, Python dataclass/pandas
protocol or exception-class identity, independent complete-domain
certification, or pixel-level rendering equivalence is asserted.
