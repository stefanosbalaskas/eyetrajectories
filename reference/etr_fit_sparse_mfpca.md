# Fit native sparse multivariate FPCA with an optional frozen-source scientific record

Estimates direct paired sparse planar mean and covariance surfaces and
joint PACE scores with full fitted covariance plus measurement error and
optional ridge. No raw trajectory interpolation is introduced.
Source-scientific parity on declared domains remains provisional until
direct frozen Python tests and independent scientific review succeed.

## Usage

``` r
etr_fit_sparse_mfpca(trajectories, dimensions = c("x", "y"),
    n_components = 2L, backend = NULL, max_marginal_components = 3L,
    fve = 0.95, options = list(), observation_process = NULL,
    evaluation_grid = NULL, mean_bandwidth = NULL,
    covariance_bandwidth = NULL, measurement_error = "diagonal",
    measurement_error_variance = NULL,
    measurement_error_covariance = NULL,
    analysis_support_action = "error", psd_action = "error",
    psd_tolerance = 1e-8, positive_eigen_tolerance = 1e-10,
    score_ridge = 0, score_condition_limit = 1e12,
    min_score_time_points = 2L, score_failure_action = "error",
    mean_min_local_points = 3L, covariance_min_local_pairs = 6L,
    strict_source_record = FALSE)
```

## Arguments

- trajectories:

  Native irregular paired planar observations.

- dimensions:

  Distinct observed coordinate names (two coordinates).

- n_components:

  Retained number of joint PACE components. Must be supplied explicitly
  in strict source mode.

- backend:

  Explicit native covariance/PACE estimator `"native_covariance"`, or
  distinct R marginal `"fdapace_joint_score_pca"` alternative.

- max_marginal_components, fve, options:

  Controls for the distinct marginal fdapace estimator. Their R defaults
  must remain unchanged in strict source mode.

- observation_process:

  Reserved native observation-process input, required to be NULL for
  this fit.

- evaluation_grid:

  Evaluation times for population mean/covariance, distinct from the
  original raw observations.

- mean_bandwidth, covariance_bandwidth:

  Explicit positive local smoothing bandwidths.

- measurement_error:

  `"diagonal"` or `"fixed_matrix"`; must be explicit in strict source
  mode.

- measurement_error_variance:

  Two nonnegative variance components for diagonal measurement error.

- measurement_error_covariance:

  Explicit positive-semidefinite 2-by-2 noise matrix for correlated
  measurement error.

- analysis_support_action, psd_action:

  Observed-support and latent-covariance PSD policies.

- psd_tolerance, positive_eigen_tolerance:

  Finite nonnegative PSD and eigenvalue cutoffs.

- score_ridge, score_condition_limit:

  Joint PACE score-system ridge and conditioning limits.

- min_score_time_points, score_failure_action:

  Per-curve score support and retained-failure policy.

- mean_min_local_points, covariance_min_local_pairs:

  Minimum local observed support for mean and covariance smoothers.

- strict_source_record:

  If TRUE, return the frozen Python 1.2 `SparseMFPCAResult` scientific
  fields in their exact declared order, without extra R backend fields
  or Python dataclass impersonation. Default FALSE retains the native R
  fit and extra diagnostics.

## Value

A native sparse multivariate PACE result, or in strict mode a 29-field
native R source-scientific result for regression against frozen Python
1.2. This record is not a Python dataclass.
