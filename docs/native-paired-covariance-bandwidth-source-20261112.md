# Paired native simultaneous covariance sensitivity (Python 1.2 source-scientific)

Frozen oracle: `eyetrajectoriespy==1.2.0`, `c1cd95ad718327550f7e55393ff38582872f7a94`, `src/eyetrajectoriespy/functional_mixed_effects_covariance_sensitivity.py`, functions `_validate_bands`, `_band_width_frame`, `plot_covariance_sensitivity_band_widths`.

## Scientific estimand

For model m, coefficient j and observed time t, the band-width sensitivity ratio is

`ratio(m,j,t) = (upper(m,j,t) - lower(m,j,t)) / (upper(reference,j,t) - lower(reference,j,t))`.

This is defined only when the reference bandwidth is strictly positive. When the denominator is zero, the Python source creates a `NaN` and Matplotlib omits that point; the native R scientific frame and graphics now do the same. The selected displayed curve is a **descriptive comparison of already-calibrated bands**, not a new calibrated interval and not a model ranking.

## Native numerical integration

The native `etr_functional_mixed_effects_covariance_sensitivity(..., bands=...)` joint Gaussian B-spline likelihood path no longer rejects legitimate paired calibrated `etr_mixed_effects_simultaneous_band` records. Its new helper `.etr_joint_source_band_width_frame` validates:

- Every band label belongs to an actually successful fitted model and the reference band exists.
- Each band uses its own matching fitted reference, the same calibrated confidence level, coefficient- or family-wise simultaneous scope, and the same declared participant-bootstrap type.
- Stored bootstrap coefficient function arrays have equal replicate counts and every participant draw index matches exactly in order and value.
- All coefficient names, observed time grids and finite lower/upper endpoint matrices agree with the comparison models.
- The six source table columns are in Python order, with rows ordered by successful model, coefficient and observed time. No missing candidate bands are manufactured.

The existing R moments sensitivity does not accept bands and retains its native descriptive behavior. With `strict_source_record=TRUE`, only actually fitted `nlme` joint-likelihood models are accepted. It emits a 13-field R scientific record with `source_paired_bootstrap_bands_validated=TRUE` in provenance after actual validation, without suggesting Python statsmodels likelihood/optimizer equivalence.

The native `etr_plot_covariance_sensitivity_band_widths(..., strict_source_record=TRUE)` verifies the stored numerator, denominator and ratio columns, respects scientific `NaN` gaps and reproduces the source order, labels, legend and unit reference at y=1. It returns typed R artist **data**, never an actual Python Matplotlib `Axes`.

## Qualification boundaries

This is a provisional developer-scoped Python 1.2 scientific result and plotting path. Native `nlme` is not Python `statsmodels`; R structure equality is not Python object `is` identity; arbitrary Python dataclass/pandas/Matplotlib object acceptability and exception types remain out of scope. Neither exact-head GitHub CI passing nor independent full-contract certification has yet been observed.

The native/opt-in frozen Python tests assert source ordered ratios, reference zeros, invalid bands, and integration via one actually fitted native `nlme` model with genuine participant bootstrap-generated calibrated bands. They provide evidence only if executed and passing.
