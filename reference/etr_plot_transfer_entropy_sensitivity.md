# Plot explicit transfer-entropy parameter sensitivity without hidden averaging

Inspect frozen Python 1.2 scientific plotting geometry without
recomputing any recurrence, RQA or transfer-entropy estimator. Original
native R plots and numeric outputs remain the default.

## Usage

``` r
etr_plot_transfer_entropy_sensitivity(result, parameter,
  metric = "transfer_entropy_bits", filters = NULL, strict_source_record = FALSE, ...)
```

## Arguments

- result:

  Native precomputed transfer-entropy parameter sensitivity grid.

- parameter:

  A declared numerical tuning parameter to vary.

- metric:

  Declared transfer-entropy summary metric.

- filters:

  Exact named tuning-parameter filters.

- strict_source_record:

  Return typed native scientific source line and fail closed if any
  other tuning parameters remain variable.

- ...:

  Legacy base R graphics options.

## Value

Invisibly the original sorted source tuning-parameter and statistic data
frame by default. Strict mode returns a typed native R source line and
Matplotlib-equivalent scientific labels. No causal interpretation or
Python Axes identity is implied.

## Details

Strict mode represents bounded source-scientific coordinates as native R
records; Python dataclass and pandas domain identity, exception types,
full Matplotlib Axes return, pixel rendering and independent full-source
certification are not claimed.
