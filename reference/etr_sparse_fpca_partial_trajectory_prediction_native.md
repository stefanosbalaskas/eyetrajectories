# Conditional future trajectory prediction with native sparse PACE

Use a fitted native sparse FPCA population mean and full covariance
surface to condition on the raw native-time history of exactly one
sparse target. Returns future conditional latent mean and covariance and
a separate observed-predictive covariance that adds the fitted
measurement noise but does not reclassify numerical history ridge as
future noise. It excludes population estimation uncertainty, bandwidth
uncertainty, and conformal coverage guarantees; all-source-domain
independent parity is not claimed.

## Usage

``` r
etr_sparse_fpca_partial_trajectory_prediction_native(
  fit, trajectory, history_cutoff, prediction_grid,
  min_history_observations = 2L,
  condition_limit = NULL, history_ridge = NULL
)
etr_sparse_fpca_partial_prediction_frame_native(result)
```

## Arguments

- fit:

  Native fitted sparse PACE covariance model.

- trajectory:

  Exactly one native irregular trajectory with matched units.

- history_cutoff:

  Finite history endpoint within the fitted support.

- prediction_grid:

  Future nonempty strictly increasing time grid.

- min_history_observations:

  Required positive history observation count.

- condition_limit:

  Optional positive conditioning number ceiling.

- history_ridge:

  Optional nonnegative numerical history-only ridge.

- result:

  A native sparse conditional future result.

## Value

A source-shaped conditional future object with latent and observed
prediction covariances, standard errors, native history, the history and
prediction counts, and numerical diagnostics. The frame method returns
one row per requested future time.
