# Native R delay embedding, divergence, explicit Lyapunov fits and RQA population bootstrap

Six independent Python-free scientific implementations for complete
multivariate delay embedding, Rosenstein and Kantz local divergence,
explicit Lyapunov linear segments and fixed-radius population-average
RQA bootstrap.

## Usage

``` r
etr_delay_embed_trajectory(trajectories, embedding_dimension, delay,
  delay_units = "samples", dimensions = NULL)
etr_local_divergence_curve(embedding, curve, theiler_window, max_horizon,
  theiler_window_units = "samples", max_horizon_units = "samples")
etr_kantz_divergence_curve(embedding, curve, radius, theiler_window,
  max_horizon, min_neighbors = 2L, theiler_window_units = "samples",
  max_horizon_units = "samples")
etr_estimate_largest_lyapunov_rosenstein(divergence, fit_start, fit_end,
  fit_units = "samples")
etr_estimate_largest_lyapunov_kantz(divergence, fit_start, fit_end,
  fit_units = "samples")
etr_bootstrap_rqa_metric_means(trajectories, dimensions, metrics, radius = NULL,
  target_recurrence_rate = NULL, distance_metric = "euclidean",
  theiler_window = 0L, theiler_window_units = "samples",
  min_diagonal_length = 2L, min_vertical_length = 2L,
  embedding_dimension = NULL, delay = NULL, delay_units = "samples",
  unit = "curve", participant_column = NULL, confidence_level = 0.95,
  n_bootstrap = 2000L, random_state = 0L)
```

## Arguments

- trajectories:

  Complete native trajectory collection, no implicit interpolation or
  smoothing.

- embedding_dimension:

  Explicit number of delay-coordinate blocks; reconstruction with at
  least two states.

- delay:

  Positive observed-sample lag or physical-time lag.

- delay_units:

  `samples`, seconds/milliseconds source aliases or matching trajectory
  time units; physical-time lag requires a regular grid and exact
  integer sample multiple.

- dimensions:

  Nonempty unique named source channels.

- embedding:

  Native etr_delay_embedding_set from the explicit stage-17 constructor.

- curve:

  Zero-based source index or exact curve ID.

- theiler_window:

  Nonnegative sample exclusion around each state.

- max_horizon:

  Positive number of forward observed-sample horizons.

- theiler_window_units:

  Sample or convertible physical time units, resolved on the embedded
  grid.

- max_horizon_units:

  Sample or convertible physical time units, resolved on the embedded
  grid.

- radius:

  Declared nonnegative recurrence radius or positive Kantz neighborhood
  radius.

- min_neighbors:

  Minimum fixed-radius Kantz neighbors per reference state.

- divergence:

  Native local or Kantz divergence curve, as appropriate.

- fit_start:

  Explicit inclusive first horizon in samples.

- fit_end:

  Explicit inclusive last horizon in samples, with at least three finite
  points.

- fit_units:

  Only samples.

- metrics:

  Explicit supported RQA metrics; unknown or undefined metrics error.

- target_recurrence_rate:

  Unsupported source adaptive-threshold option; errors rather than
  silently substituting a fixed radius.

- distance_metric:

  Euclidean only.

- min_diagonal_length:

  Positive RQA diagonal-line threshold.

- min_vertical_length:

  Positive RQA vertical-line threshold.

- unit:

  Independent curve or participant unit for population-average RQA
  bootstrap.

- participant_column:

  Required participant metadata field for independent participant
  averages.

- confidence_level:

  Nominal percentile interval level in (0,1).

- n_bootstrap:

  At least 100 whole-unit resampling replicates.

- random_state:

  Scoped base-R random seed; does not reproduce NumPy random streams.

## Value

A native delayed trajectory embedding, divergence trace, explicit slope
estimate, or curve/participant-level RQA bootstrap result.

## Details

No chaos or causal interpretation follows solely from positive Lyapunov
slope estimates. Divergence nearest-neighbor ties can differ from SciPy
KDTree tie policies; source comparisons avoid tied fixture states.
Unsupported adaptive thresholds and non-convertible time-unit lags fail
explicitly; valid time-unit lags resolve only to existing samples
without interpolation. The RQA bootstrap estimates the mean of per-curve
summaries across independent curves or equal-weight participant
averages, not uncertainty within one recurrence plot. Bootstrap RNG
differs from NumPy. Mapped public names are not 508-contract
certification.
