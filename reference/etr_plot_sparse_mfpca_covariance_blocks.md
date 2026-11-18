# Plot four native paired sparse covariance operator blocks

Displays direct sparse planar covariance surfaces on the declared
evaluation grid without changing source arrays or discarding directional
xy/yx information. Source-scientific geometry and symmetric color-range
semantics are compared directly to frozen Python 1.2 Matplotlib imshow
artists. Exact backend pixel colors, Figure and Axes runtime identity,
and Python exception classes are not claimed.

## Usage

``` r
etr_plot_sparse_mfpca_covariance_blocks(result, source = "used",
    stage = NULL, strict_source_record = FALSE)
```

## Arguments

- result:

  Native paired sparse joint-covariance/PACE fitted scientific record.

- source:

  Legacy native R choice `"used"` (PSD-qualified fitted covariance) or
  `"smoothed"` (pre-PSD-repair covariance).

- stage:

  Optional exact frozen Python stage name, `"used"` or `"smoothed"`.
  Cannot disagree with an explicitly supplied `source`.

- strict_source_record:

  If TRUE, return source-scientific four-panel imshow metadata (ordered
  Cxx, Cxy, Cyx, Cyy; source grid extent, signed symmetric shared color
  limits, per-panel titles/labels and declared colorbar), not actual
  Python `Axes`.

## Value

Invisible native covariance matrices in default mode; strict mode
returns native R scientific four-panel artist geometry.
