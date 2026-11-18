# Native directly fitted sparse two-channel covariance and joint PACE

A Python-free direct sparse two-coordinate PACE estimator with
local-linear Epanechnikov population means and directional off-diagonal
cross-covariance, joint quadrature-weighted PSD handling, and a
full-covariance joint score system on native observation times. It is
separate from the legacy fdapace-marginal-score PCA alternative and is
not independently certified against the complete Python 1.2 public
contract.

## Usage

``` r
etr_fit_sparse_mfpca_native(
  trajectories, dimensions = c("x", "y"), n_components = 2L,
  evaluation_grid, mean_bandwidth, covariance_bandwidth,
  measurement_error = "diagonal",
  measurement_error_variance = NULL,
  measurement_error_covariance = NULL,
  analysis_support_action = "error", psd_action = "error",
  psd_tolerance = 1e-8, positive_eigen_tolerance = 1e-10,
  score_ridge = 0, score_condition_limit = 1e12,
  min_score_time_points = 2L, score_failure_action = "error",
  mean_min_local_points = 3L, covariance_min_local_pairs = 6L
)
```

## Arguments

- trajectories:

  Jointly observed native irregular trajectories.

- dimensions:

  Two distinct planar channel names.

- n_components:

  Positive integer number of fitted joint eigenfunctions.

- evaluation_grid:

  Finite increasing population fitting grid.

- mean_bandwidth:

  Positive Epanechnikov mean bandwidth.

- covariance_bandwidth:

  Positive covariance surface bandwidth.

- measurement_error:

  `"diagonal"` or `"fixed_matrix"`.

- measurement_error_variance:

  Two declared variances in diagonal mode.

- measurement_error_covariance:

  Symmetric PSD 2x2 matrix in fixed_matrix mode.

- analysis_support_action:

  `"error"` or `"restrict"`.

- psd_action:

  `"error"` or `"project"`.

- psd_tolerance:

  Nonnegative operator PSD tolerance.

- positive_eigen_tolerance:

  Eigenvalue positivity threshold.

- score_ridge:

  Nonnegative regularizer in source score covariance.

- score_condition_limit:

  Condition-number ceiling greater than one.

- min_score_time_points:

  Positive minimum number of retained time points.

- score_failure_action:

  `"error"` or `"retain_nan"`.

- mean_min_local_points:

  Minimum positive-weight observations for local means.

- covariance_min_local_pairs:

  Minimum positive-weight offdiagonal pairs for covariance blocks.

## Value

A source-shaped native joint sparse FPCA model, including smoothed and
PSD covariance blocks (xx, xy, yx, yy), scores, vector eigenfunctions,
retained quadrature weights, and fitted diagnostics. Structured sparse
errors retain curve and zero-based sample indices for invalid planar
observations, support counts for rejected analysis grids, and covariance
eigenvalue or rank details when the declared PSD or component controls
fail.
