# Native sparse multilevel FPCA covariance and hierarchical BLUP

Direct irregular functional two-level covariance estimation for repeated
participant trials. The mean and covariance surfaces are fitted by
Epanechnikov local-linear smoothers without interpolating the
observations. Same-participant distinct-trial products identify between
covariance. Smoothed total minus smoothed between identifies trial
covariance. The two weighted PSD-repaired operators yield component
eigenfunctions and full-covariance Gaussian participant/trial BLUP
scores.

## Usage

``` r
etr_fit_sparse_multilevel_fpca_native(
  trajectories, dimension, participant_column,
  participant_components, trial_components, evaluation_grid,
  mean_bandwidth, total_covariance_bandwidth,
  between_covariance_bandwidth,
  noise_bandwidth = NULL, noise_support = NULL,
  analysis_support_action = "error", weighting = "observation",
  mean_smoother = "local_linear",
  covariance_smoother = "local_linear",
  kernel = "epanechnikov",
  noise_variance_method = "diagonal_difference",
  measurement_error_variance = NULL, psd_action = "error",
  psd_tolerance = 1e-8, positive_eigen_tolerance = 1e-10,
  score_ridge = 0, score_condition_limit = 1e12,
  min_participant_score_samples = 2L,
  score_failure_action = "error", mean_min_local_points = 3L,
  total_covariance_min_local_pairs = 6L,
  between_covariance_min_local_pairs = 6L,
  noise_min_local_points = 3L
)
```

## Arguments

- trajectories:

  Source native irregular trial collection with participant metadata.

- dimension:

  Observed functional response column.

- participant_column:

  Metadata identifier for repeated participant trials.

- participant_components:

  Retained between-participant eigensystem rank.

- trial_components:

  Retained within-participant eigensystem rank.

- evaluation_grid:

  Strictly increasing population evaluation grid.

- mean_bandwidth:

  Mean local-linear bandwidth.

- total_covariance_bandwidth:

  Within-trial total covariance smoothing bandwidth.

- between_covariance_bandwidth:

  Distinct-trial covariance smoothing bandwidth.

- noise_bandwidth:

  Diagonal-difference noise bandwidth when estimated.

- noise_support:

  Noise interval within population evaluation grid.

- analysis_support_action:

  Either `"error"` or `"restrict"`.

- weighting:

  Observation/pair weighting; must be `"observation"`.

- mean_smoother:

  Must be `"local_linear"`.

- covariance_smoother:

  Must be `"local_linear"`.

- kernel:

  Must be `"epanechnikov"`.

- noise_variance_method:

  Either `"fixed"` or `"diagonal_difference"`.

- measurement_error_variance:

  Known nonnegative noise in fixed mode.

- psd_action:

  Either `"error"` or `"project"`.

- psd_tolerance:

  Nonnegative operator PSD tolerance.

- positive_eigen_tolerance:

  Nonnegative eigenvalue threshold.

- score_ridge:

  Nonnegative BLUP covariance regularizer.

- score_condition_limit:

  Finite upper bound on condition number.

- min_participant_score_samples:

  Minimum pooled native participant samples.

- score_failure_action:

  Either `"error"` or `"retain_nan"`.

- mean_min_local_points:

  Minimum locally weighted mean observations.

- total_covariance_min_local_pairs:

  Minimum locally weighted same-trial pairs.

- between_covariance_min_local_pairs:

  Minimum locally weighted different-trial pairs.

- noise_min_local_points:

  Minimum locally weighted noise observations.

## Value

Source-structured irregular multilevel FPCA population and score object.
Includes participant/trial eigensystems, within/between covariance
audit, full-covariance BLUP score diagnostics, and support provenance.
No independent scientific or full Python 1.2 source-domain certification
is claimed by this experimental native implementation.
