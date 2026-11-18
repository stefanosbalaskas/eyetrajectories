# Display directional cross-covariance of paired sparse functional coordinates

Preserves independent directional Cxy and Cyx scientific surfaces rather
than silently symmetrizing xy before covariance projection. Native R
graphics rendering is not Python Matplotlib `Axes`, and exact rendered
color palette is not asserted.

## Usage

``` r
etr_plot_sparse_mfpca_cross_covariance(result, source = "used",
    stage = NULL, strict_source_record = FALSE)
```

## Arguments

- result:

  Native genuine paired sparse multivariate PACE fitted covariance.

- source:

  Native `"used"` or `"smoothed"` covariance stage.

- stage:

  Optional frozen Python 1.2 stage alias; must match explicitly
  specified source.

- strict_source_record:

  Return a native source-scientific 1-by-2 heatmap artist geometry
  record for Cxy and Cyx, including exact matrix values, source imshow
  extent and shared symmetric signed limits.

## Value

Invisible pair of native directional covariance matrices; strict mode
returns native R source-scientific plot geometry.
