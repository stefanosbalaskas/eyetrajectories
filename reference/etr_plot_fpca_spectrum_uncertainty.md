# Plot matched-bootstrap FPCA eigenvalue and variance-ratio uncertainty

Displays original bootstrap-calibrated FPC spectrum uncertainty for a
declared metric on the native fitted scale. Component-wise and
familywise calibration refer to original native estimator output. The
plot never invents new coverage guarantees or clips endpoints to
mathematical support. Matplotlib runtime object identity and pixel
matching remain outside this source-scientific contract.

## Usage

``` r
etr_plot_fpca_spectrum_uncertainty(
    result, metric = "explained_variance_ratio",
    strict_source_record = FALSE, ...)
```

## Arguments

- result:

  Actual native FPCA spectrum uncertainty result with aligned component
  eigenvalues and bootstrap intervals for eigenvalue, explained-variance
  ratio and cumulative ratio.

- metric:

  Exactly one of `"eigenvalue"`, `"explained_variance_ratio"` or
  `"cumulative_variance_ratio"`.

- strict_source_record:

  Return a typed native R scientific record preserving Python source
  errorbar arrays, marker `"o"`, capsize 3, variance-ratio source ylabel
  and familywise versus component-wise title; not Python `Axes`.

- ...:

  Native base graphics options.

## Value

Default invisible retained-component source point and interval data
frame, or strict source scientific errorbar artist metadata with
component positions and asymmetric lower/upper uncertainty.
