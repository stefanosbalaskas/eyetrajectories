# Native Python 1.2 source-aligned FPCA uncertainty reporting and graphics

Seven Python-free native R API methods presenting matched-bootstrap FPCA
score, spectrum, component shape and observed-grid functional mean
uncertainty. Estimation methods are not recomputed by these functions.

## Usage

``` r
etr_fpca_score_uncertainty_reporting_text(result, digits = 3L)
etr_fpca_spectrum_uncertainty_reporting_text(result, digits = 3L)
etr_functional_mean_band_reporting_text(result, digits = 3L)
etr_fpca_component_band_reporting_text(result, digits = 2L)
```

## Arguments

- result:

  Corresponding audited native R score, spectrum, functional mean or
  component-band result class.

- digits:

  Nonnegative integer numeric reporting precision, 0 to 12.

## Value

Reporting methods return a character string. The plot methods render
base R graphics to the active device and invisibly return the exact
numeric estimate and uncertainty interval geometry used in the plot.

## Details

The published Python source returns Matplotlib Axes, accepts typed
Python FPCA results and obtains bootstrap draws with different RNGs. The
output text may be exactly reproducible for matched numerical fixtures,
while the complete source callable contract remains uncertified. These
graphics use only observed-grid values. A pointwise target score
percentile envelope is not a simultaneous uncertainty band; a
studentized observed-grid band is not a continuous-domain coverage
guarantee. Source certification is restricted pending independent
complete-domain and scientific review.
