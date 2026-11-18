# Plot an explicit one-parameter recurrence quantification sensitivity slice

Inspect frozen Python 1.2 scientific plotting geometry without
recomputing any recurrence, RQA or transfer-entropy estimator. Original
native R plots and numeric outputs remain the default.

## Usage

``` r
etr_plot_rqa_sensitivity(result, parameter, metric, filters = NULL,
  strict_source_record = FALSE, ...)
```

## Arguments

- result:

  Native precomputed RQA parameter sensitivity grid with declared
  parameter and metric columns.

- parameter:

  One numerical parameter varied in the source slice.

- metric:

  Existing RQA summary metric.

- filters:

  Optional named exact values holding remaining declared parameters
  fixed.

- strict_source_record:

  Return native Matplotlib scientific source artist data, requiring
  distinct plotted-parameter values, when TRUE.

- ...:

  Legacy base R graphics options.

## Value

Invisibly the original ordered parameter/metric data frame by default.
Strict mode returns a typed R source line with original source title, o
marker, axes and no legend.

## Details

Strict mode represents bounded source-scientific coordinates as native R
records; Python dataclass and pandas domain identity, exception types,
full Matplotlib Axes return, pixel rendering and independent full-source
certification are not claimed.
