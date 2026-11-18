# Native paired-bootstrap simultaneous FPCR slope bands on the observed grid

Pure native R postcalibration of an existing paired-bootstrap Gaussian
FPCR slope array. Uses studentized maximum absolute bootstrap deviations
with a global time-by-dimension maximum or separate per-dimension time
maxima.

## Usage

``` r
etr_fpca_regression_slope_simultaneous_band(
  result, confidence_level = 0.95, simultaneous_scope = "global")
```

## Arguments

- result:

  Native scientific fit record with finite reference slope matrix,
  finite B-by-time-by-dimension bootstrap slope array, and source FPCA
  dimension identifiers.

- confidence_level:

  Numeric probability strictly between zero and one.

- simultaneous_scope:

  One of `"global"` or `"dimension"`.

## Value

A scientific R record with reference-grid lower and upper bounds,
pointwise bootstrap standard errors, source-calibrated maximum absolute
studentized statistics, and critical values. Return class is not
equivalent to Python's dataclass.

## Details

The postcalibration matches the frozen Python 1.2.0
`fpca_regression_slope_simultaneous_band` observed-grid procedure.
Sample bootstrap standard deviations (ddof=1) and NumPy
`method="higher"` quantiles are retained. Material nonzero reference
discrepancies with effectively zero bootstrap standard error are
rejected. No regression fit, basis, or bootstrap data are recomputed.
Continuous-domain coverage, operator-scaled FPCR significance tests, and
full source-contract equivalence are not claimed or independently
certified.
