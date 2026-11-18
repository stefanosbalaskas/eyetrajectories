# Python-free scientific observation frames for native functional models

Source-aligned, read-only data-frame extracts of explicit R-list records
for generalized function-on-scalar regression, sparse FPCA, and sparse
multivariate FPCA. These functions do not refit, predict, or calibrate
any estimator.

## Usage

``` r
etr_generalized_function_on_scalar_prediction_frame(result)
etr_generalized_function_on_scalar_mean_difference_frame(result)
etr_generalized_function_on_scalar_coefficient_frame(result)
etr_generalized_function_on_scalar_exposure_frame(result)
etr_sparse_fpca_score_frame(result)
etr_sparse_mfpca_score_frame(result)
```

## Arguments

- result:

  An explicitly declared native R scientific record, with matching
  observation dimensions, finite arrays, and required model metadata.
  Sparse score frames preserve missing scores for retained failed fits.
  Band records must supply a nested `prediction` or `reference`.

## Value

A source-column-ordered native `data.frame`; an exposure frame also
carries an `exposure_audit` attribute describing fixed observed
exposure.

## Details

Observed-grid output uses the published Python 1.2.0 ordering of groups
then time points. Reported bands are *existing* intervals only: these
adapters never calculate inferential intervals. The native R-list and
data-frame acceptance domain is deliberately narrower than Python typed
dataclasses and pandas/NumPy coercion. It must not be presented as a
fully certified one-to-one source contract. The six published Python
counterparts are tracked in the source-contract gap register, with
opt-in exact-source schema/value comparisons.
