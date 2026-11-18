# Stage 13 native R functional regression, embedding and simulation

Python-free numerical function-on-scalar OLS, HC1 standard errors,
fixed-design wild bootstrap, observed-grid simultaneous bands, nonlinear
embedding diagnostics, empirical return-map stability, trajectory
generators and explicit irregular sample projection.

## Usage

``` r
etr_fit_function_on_scalar_regression(trajectories, design, predictors,
  dimensions = NULL, participant_column = NULL, unit = "curve")
etr_bootstrap_function_on_scalar_coefficients(result, n_bootstrap = 1000L,
  multiplier = "rademacher", random_state = 0L, random_engine = "numpy")
etr_function_on_scalar_simultaneous_bands(bootstrap, confidence_level = 0.95,
  simultaneous_scope = "coefficient")
etr_function_on_scalar_coefficient_frame(result, band = NULL)
etr_embedding_delay_diagnostics(trajectories, curve, dimension, max_lag,
  max_lag_units = "samples", bins = 16L)
etr_embedding_dimension_diagnostics(trajectories, curve, dimension, delay,
  delay_units = "samples", max_dimension = 10L, theiler_window = 0L,
  theiler_window_units = "samples", rtol = 10, atol = 2)
etr_return_map_stability(fit, tolerance = 1e-6)
etr_simulate_planar_trajectories(n_participants = 20L,
  trials_per_participant = 6L, n_time = 121L, duration = 2, random_state = 42L)
etr_simulate_aoi_probability_trajectories(n_curves = 80L, n_time = 101L,
  n_aoi = 4L, duration = 2, random_state = 17L)
etr_from_irregular_long_dataframe(data, curve_columns, time_column,
  value_columns = c("x", "y"), grid, metadata_columns = NULL, method = "linear",
  max_gap = NULL, coordinate_system = "unknown", time_unit = "unknown")
etr_poincare_crossings(trajectories, curve, section_dimension, section_value,
  direction, state_dimensions = NULL)
etr_fit_local_return_map(crossings, reference, neighborhood_radius = NULL,
  n_neighbors = NULL)
```

## Arguments

- trajectories:

  Complete native functional responses; no automatic interpolation or
  selection.

- design:

  One row per curve of finite numeric scalar predictors.

- predictors:

  Explicit numeric design columns; Intercept is reserved.

- dimensions:

  Optional named functional dimensions.

- participant_column:

  Participant-unit metadata name when unit is participant.

- unit:

  Independent unit; curve or participant.

- result:

  Native fitted function-on-scalar result or declared spectral stability
  fit.

- n_bootstrap:

  Wild bootstrap replicate count at least 100.

- multiplier:

  Rademacher or normal whole-curve weights.

- random_state:

  For coefficient bootstrap, a nonnegative integer seed below
  \\2^{53}\\, or `NULL` for the current R RNG stream. The native
  simulation methods use isolated base-R seeds.

- random_engine:

  Use `"numpy"` for NumPy-compatible seeded bootstrap weights, or
  `"base_R"` to reproduce previous native weights.

- bootstrap:

  Native fixed-design functional wild bootstrap result.

- confidence_level:

  Band coverage nominal fraction in (0,1).

- simultaneous_scope:

  Coefficient-specific or all-coefficient family maximum.

- band:

  Optional simultaneous coefficient band for the exact fitted result.

- curve:

  One-based source curve index or exact ID.

- dimension:

  Functional channel name.

- max_lag:

  Maximum positive lag count.

- max_lag_units:

  Only samples in current native implementation.

- bins:

  Histogram bin count \>=2.

- delay:

  Positive sample-index delay.

- delay_units:

  Only samples.

- max_dimension:

  Maximum explicit embedding dimension.

- theiler_window:

  Temporally excluded sample lag.

- theiler_window_units:

  Only samples.

- rtol:

  False-nearest-neighbor relative threshold.

- atol:

  False-nearest-neighbor absolute threshold.

- fit:

  Precomputed local empirical return-map fit with Jacobian.

- tolerance:

  Nonnegative eigenvalue-classification margin.

- n_participants:

  Simulated independent participant count.

- trials_per_participant:

  Repeated trials within simulated participants.

- n_time:

  Regular trajectory time samples.

- duration:

  Positive observed time horizon.

- n_curves:

  Number of simulated AOI simplex curves.

- n_aoi:

  Number of AOI probability channels.

- data:

  Source irregular long-format data.frame.

- curve_columns:

  Identifier columns of the irregular source.

- time_column:

  Numeric sample-time column.

- value_columns:

  Named functional response channels.

- grid:

  Explicit shared target time grid.

- metadata_columns:

  Optional curve-constant metadata fields.

- method:

  Explicit native resampling method.

- max_gap:

  Optional largest interpolatable source gap.

- coordinate_system:

  Declared trajectory coordinate semantics.

- time_unit:

  Declared observed time unit.

- section_dimension:

  Explicit Poincare section dimension.

- section_value:

  Finite section threshold.

- direction:

  Positive, negative or both orientations.

- state_dimensions:

  Declared non-section functional state dimensions.

- crossings:

  Native Poincare crossing results.

- reference:

  Local return-map mean, median or explicit reference vector.

- neighborhood_radius:

  Positive local radius, exclusive with n_neighbors.

- n_neighbors:

  Number of locally selected transitions, exclusive with radius.

## Value

A native fit, diagnostic or band result, trajectory collection, or
structured coefficient data frame according to the invoked method.

## Details

Simultaneous bands operate over the observed grid. FNN is exact brute
force with a size cap and explicit tie differences. Embedding delays are
measured in samples.
