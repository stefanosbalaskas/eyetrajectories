# Restricted functional repeated-measures moments and residual dependence diagnostics

Seven Python-free numerical R implementations covering a restricted
two-level functional method-of-moments fixed-effects model,
covariance-conditional participant random functions, within-curve
whitening, exact residual lag diagnostics, residual pairs and
source-shaped coefficient/variance auditing.

## Usage

``` r
etr_fit_functional_mixed_effects_regression(trajectories, design, predictors,
  participant_column, dimension, covariance_ridge = 1e-6)
etr_functional_mixed_effects_whitened_residuals(result)
etr_functional_mixed_effects_residual_diagnostics(result, max_lag,
  residual_scale = "raw")
etr_functional_mixed_effects_residual_diagnostic_frame(result, level = "trial",
  curve_id = NULL, participant_id = NULL)
etr_functional_mixed_effects_residual_pair_frame(result, lag_index,
  curve_id = NULL, participant_id = NULL)
etr_functional_mixed_effects_coefficient_frame(result, band = NULL)
```

## Arguments

- trajectories:

  Complete native common-grid trajectory set with a selected non-simplex
  outcome channel.

- design:

  One complete numeric predictor row per source curve, aligned by unique
  curve_id.

- predictors:

  Unique names of finite numeric scalar fixed predictors; may be empty
  for intercept-only.

- participant_column:

  Metadata field supplying complete participant identities; requires at
  least 3 participants with at least 2 curves each.

- dimension:

  One explicit response dimension name.

- covariance_ridge:

  Positive covariance regularization proportion in (0,1).

- result:

  Restricted two-level moments fit or its residual diagnostic object as
  appropriate. Native joint B-spline Gaussian likelihood fits are also
  accepted by whitening, lag diagnostics, residual pair, and coefficient
  frame functions. The joint models retain observed time units, source
  curve IDs, and their fitted conditional covariance without model
  refitting.

- max_lag:

  Explicit positive index lag strictly less than the number of time
  points.

- residual_scale:

  Raw or within-trial covariance-whitened conditional residuals.

- level:

  Trial, participant or overall audit-frame aggregation.

- curve_id:

  Optional trial/curve filter where supported.

- participant_id:

  Optional participant filter where supported.

- lag_index:

  Explicit integer lag within the declared maximum.

- band:

  Not supported; only NULL is accepted. No simultaneous mixed-model
  bands are qualified.

## Value

A restricted two-level functional model object, whitened residual
matrix, diagnostic result, physical-lag residual pair data frame,
variance decomposition, or coefficient table.

## Details

Critical restriction: this model is NOT the spline-based statsmodels
MixedLM, Gaussian profiled GLS or REML backend in eyetrajectoriespy
1.2.0. Fixed coefficient functions are independently estimated pointwise
with participant-cluster sandwich standard errors. Participant random
functions use PSD-projected two-level covariance method-of-moments
shrinkage with a declared ridge. Participant covariance and interval
calibration are not certified. Random slopes, nested trial effects,
residual AR1/exponential correlation likelihood optimization, and
simultaneous bands are not provided. The source-ordered
coefficient-frame adapter accepts fitted native joint B-spline
likelihood objects without a refit. The new likelihood-residual adapter
computes physical-lag audit frames from conditional residual functions
and covariance-based whitening; it does not change the restricted moment
model's estimator or numerical formulas. This distinction is retained in
the residual diagnostic provenance. The public name mapping is partial
source-contract support, never one-to-one equivalence.
