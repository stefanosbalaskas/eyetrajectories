# Native sparse PACE future split conformal prediction

From a fully separated proper-training fit and calibration set, compute
the maximum standardized absolute future residual at an exact finite
grid of observed future measurements, aggregate curves within a declared
participant/group if required, then take the exact conservative order
statistic \\\lceil(n+1)(1-\alpha)\rceil\\. Apply it to a single disjoint
target curve's conditional full-covariance Gaussian prediction. No raw
interpolation, latent-function or continuous-domain coverage claim is
made. Coverage requires independent exchangeable calibration units.
Complete frozen Python 1.2 source-domain parity is not certified.

## Usage

``` r
etr_calibrate_sparse_fpca_partial_conformal_native(
  fit, calibration, history_cutoff, prediction_grid,
  alpha = 0.05, group_column = NULL,
  min_history_observations = 2L,
  condition_limit = NULL, history_ridge = NULL
)
etr_sparse_fpca_conformal_prediction_band_native(
  calibration, trajectory
)
etr_sparse_fpca_conformal_band_frame_native(result)
```

## Arguments

- fit:

  A native source-model sparse FPCA population fit.

- calibration:

  Independent irregular calibration trajectories, or a fitted
  calibration object in the second method.

- history_cutoff:

  Finite history endpoint used by each curve's conditional prediction.

- prediction_grid:

  Finite future timestamps exactly observed on each calibration curve.

- alpha:

  Conformal miscoverage level strictly inside (0,1).

- group_column:

  Optional named exchangeability group in both training and calibration
  metadata. Scalar labels use source-style text. Missing character
  labels represent `None` and missing double or factor labels represent
  `nan`.

- min_history_observations:

  Positive minimum native history observation count.

- condition_limit:

  Optional upper bound on history-covariance condition number.

- history_ridge:

  Optional nonnegative numerical history covariance ridge.

- trajectory:

  Single target trajectory disjoint from training and calibration units.

- result:

  A native sparse finite-grid conformal band object.

## Value

The calibration function returns per-curve scores, per-unit maximum
scores, the corresponding curve and unit counts, the exact finite-sample
rank and its critical value. The band function returns upper/lower
target observed-measurement bands. The frame method provides one row per
declared future time.
