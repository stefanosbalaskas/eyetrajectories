# Native R graphics for generalized function-on-scalar and mixed-effects scientific inference

Plot fitted generalized function-on-scalar predictions, contrast bands,
coefficient functions, covariance sensitivity and mixed-effects residual
dependence with explicit observed-grid numerical geometry.

## Usage

``` r
etr_plot_covariance_sensitivity_band_widths(
  result, coefficient, strict_source_record = FALSE)
```

## Arguments

- result:

  An explicitly declared scientific fitted R record or pre-calibrated
  band/sensitivity/residual diagnostics R record.

- coefficient:

  Exact declared source regression coefficient name.

- strict_source_record:

  If TRUE, return explicitly typed native source-scientific artist
  geometry rather than default base R plot output.

## Value

Base-R graphics on the active device and invisible numeric plot geometry
on the declared time grid. Python Matplotlib Axes output is not returned
and one-to-one backend object equivalence is not claimed.

## Details

The source's link or response scale, covariance sensitivity reference,
simultaneous observed-grid interval labels, zero lines for differences
or ACF and one line for rate ratios are preserved. No inference,
bootstrap refitting, model selection, or calibration is performed.
Physical lag means are not mistaken for regular index lags. All seven
independent source-contract approvals remain unresolved.
