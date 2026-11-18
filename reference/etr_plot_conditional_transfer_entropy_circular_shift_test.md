# Plot conditional transfer entropy versus source-only circular-shift null

Present frozen eyetrajectoriespy 1.2.0 scientific plotting geometry
while retaining original native R numeric calculations, data, graphics
and estimator semantics.

## Usage

``` r
etr_plot_conditional_transfer_entropy_circular_shift_test(result, bins = "auto",
  python_boundary_mode = FALSE, numpy_auto_policy = "relaxed",
  strict_source_record = FALSE, ...)
```

## Arguments

- result:

  Native precomputed conditional TE source-only circular-shift null test
  result.

- bins:

  Positive R integer or auto NumPy bins in source mode.

- python_boundary_mode:

  Use source NumPy histogram boundaries for auto bins when TRUE.

- numpy_auto_policy:

  Modern relaxed or classic NumPy bin width policy.

- strict_source_record:

  Logical scalar for frozen-Python scientific histogram edges/counts and
  source marker as typed native R artists.

- ...:

  Legacy R graphics options.

## Value

Original numeric source-only conditional TE test histogram geometry
returned invisibly by default. Strict mode records source
Matplotlib-compatible scientific histogram and vertical observed CTE
marker, without claiming Python runtime or causality.

## Details

Strict artist records cover a bounded native source-scientific geometry
domain. No actual Python Matplotlib Axes, Python dataclass/pandas
protocol or exception-class identity, independent complete-domain
certification, or pixel-level rendering equivalence is asserted.
