# Plot sparse joint recurrence with frozen Python source-scientific markers

Inspect frozen Python 1.2 scientific plotting geometry without
recomputing any recurrence, RQA or transfer-entropy estimator. Original
native R plots and numeric outputs remain the default.

## Usage

``` r
etr_plot_joint_recurrence(result, max_points = 200000L, strict_source_record = FALSE, ...)
```

## Arguments

- result:

  Native precomputed logical joint recurrence matrix and component
  labels.

- max_points:

  Positive integer safety cap on explicit recurrent pairs, or NULL for
  no cap.

- strict_source_record:

  If TRUE, produce a typed native scientific source artist record in
  Python CSR/COO row-major order. FALSE preserves legacy R numeric
  geometry.

- ...:

  Legacy base R graphics options.

## Value

Invisibly the original zero-based recurrence cell data frame by default,
or a typed R scientific source artist with 4-point square sparse
markers, equal aspect, inverted y axis, and source title. No live Python
Matplotlib Axes.

## Details

Strict mode represents bounded source-scientific coordinates as native R
records; Python dataclass and pandas domain identity, exception types,
full Matplotlib Axes return, pixel rendering and independent full-source
certification are not claimed.
