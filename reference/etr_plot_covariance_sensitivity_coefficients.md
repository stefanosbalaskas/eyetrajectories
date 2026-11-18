# Plot Gaussian functional mixed-effects coefficient sensitivity against a reference model

Plots true fitted native Gaussian fixed coefficient differences under
explicitly predeclared covariance sensitivity models without ranking,
selecting, or refitting models. Native `nlme` and Python `statsmodels`
optimizer equality, Matplotlib runtime type and exact rendered pixels
remain outside this scoped scientific plotting contract.

## Usage

``` r
etr_plot_covariance_sensitivity_coefficients(
    result, coefficient, strict_source_record = FALSE)
```

## Arguments

- result:

  Named fitted covariance-sensitivity scientific record. Strict mode
  requires a source-ordered W3 native R result based exclusively on
  actual Gaussian B-spline `nlme` likelihood fits.

- coefficient:

  An exact named fixed functional coefficient to plot.

- strict_source_record:

  If true, preserve frozen Python 1.2 Matplotlib source scientific
  artist data in a typed native R record. This is not a Python `Axes`
  object.

## Value

The default returns an invisible model/time/coefficient-difference data
frame, while strict mode returns source-ordered plot lines, labels, axes
and horizontal zero-reference geometry.

## Native simultaneous band-width sensitivity

Call
`etr_plot_covariance_sensitivity_band_widths(result, coefficient, strict_source_record=TRUE)`
with a real strict native joint-likelihood sensitivity result containing
paired calibrated participant-bootstrap bands. The plotted values are
the exact stored upper-minus-lower band widths divided by the
corresponding reference band width, with an explicit reference line at
one. All supplied model bands must share the original participant
resampling draw indices, coefficient/time support, bootstrap class,
nominal confidence level and simultaneous calibration scope. A zero
reference width results in `NaN`, never a fabricated finite ratio. The
result is a native R source-scientific Matplotlib artist-geometry
record, not an actual Python `Axes` object. Native `nlme` optimizer
equivalence and independently certified complete source parity remain
unproven.
