# Plot native sparse bivariate PACE component mean and modal deviations

Native sparse principal-component visualization uses the direct joint
PACE eigenvalue/eigenfunction and exact fitted population mean without
interpolation. Strict geometry is directly testable against Matplotlib
source artists, but the rendered R device is not a Python Matplotlib
figure.

## Usage

``` r
etr_plot_sparse_mfpca_component(result, component = 0L,
    sd_multiplier = 2, strict_source_record = FALSE)
```

## Arguments

- result:

  Native sparse bivariate PACE fit with two measured coordinates,
  eigenvalues, joint eigenfunctions and an evaluation grid. Strict
  scientific-record mode requires a real native fitted sparse-MFPCA
  result class.

- component:

  Zero-based component identifier, as in frozen Python 1.2.

- sd_multiplier:

  Finite positive multiple of each principal-component standard
  deviation.

- strict_source_record:

  If TRUE, draw natively and return a
  `etr_sparse_mfpca_artist_source_record` with two source-scientific
  axes, exact mean and plus/minus mode curve coordinates, source titles,
  labels and legend declarations. This is not a Python Matplotlib `Axes`
  array.

## Value

In default mode, invisible coordinate-wise time, mean and
modal-perturbation data frames. In strict mode, an invisible
source-scientific artist geometry record with two panels and six
scientific line artists.
