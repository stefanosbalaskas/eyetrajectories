\name{etr_native_functional_models}
\alias{etr_fit_function_on_scalar_regression}
\alias{etr_bootstrap_function_on_scalar_coefficients}
\alias{etr_function_on_scalar_simultaneous_bands}
\alias{etr_function_on_scalar_coefficient_frame}
\alias{etr_embedding_delay_diagnostics}
\alias{etr_embedding_dimension_diagnostics}
\alias{etr_return_map_stability}
\alias{etr_simulate_planar_trajectories}
\alias{etr_simulate_aoi_probability_trajectories}
\alias{etr_from_irregular_long_dataframe}
\alias{etr_poincare_crossings}
\alias{etr_fit_local_return_map}
\title{Stage 13 native R functional regression, embedding and simulation}
\description{Python-free numerical function-on-scalar OLS, HC1 standard errors, fixed-design wild bootstrap, observed-grid simultaneous bands, nonlinear embedding diagnostics, empirical return-map stability, trajectory generators and explicit irregular sample projection.}
\usage{
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
}
\arguments{
\item{trajectories}{Complete native functional responses; no automatic interpolation or selection.}
\item{design}{One row per curve of finite numeric scalar predictors.}
\item{predictors}{Explicit numeric design columns; Intercept is reserved.}
\item{dimensions}{Optional named functional dimensions.}
\item{participant_column}{Participant-unit metadata name when unit is participant.}
\item{unit}{Independent unit; curve or participant.}
\item{result}{Native fitted function-on-scalar result or declared spectral stability fit.}
\item{n_bootstrap}{Wild bootstrap replicate count at least 100.}
\item{multiplier}{Rademacher or normal whole-curve weights.}
\item{random_state}{For coefficient bootstrap, a nonnegative integer seed
below \eqn{2^{53}}, or \code{NULL} for the current R RNG stream. The native
simulation methods use isolated base-R seeds.}
\item{random_engine}{Use \code{"numpy"} for NumPy-compatible seeded
bootstrap weights, or \code{"base_R"} to reproduce previous native weights.}
\item{bootstrap}{Native fixed-design functional wild bootstrap result.}
\item{confidence_level}{Band coverage nominal fraction in (0,1).}
\item{simultaneous_scope}{Coefficient-specific or all-coefficient family maximum.}
\item{band}{Optional simultaneous coefficient band for the exact fitted result.}
\item{curve}{One-based source curve index or exact ID.}
\item{dimension}{Functional channel name.}
\item{max_lag}{Maximum positive lag count.}
\item{max_lag_units}{Only samples in current native implementation.}
\item{bins}{Histogram bin count >=2.}
\item{delay}{Positive sample-index delay.}
\item{delay_units}{Only samples.}
\item{max_dimension}{Maximum explicit embedding dimension.}
\item{theiler_window}{Temporally excluded sample lag.}
\item{theiler_window_units}{Only samples.}
\item{rtol}{False-nearest-neighbor relative threshold.}
\item{atol}{False-nearest-neighbor absolute threshold.}
\item{fit}{Precomputed local empirical return-map fit with Jacobian.}
\item{tolerance}{Nonnegative eigenvalue-classification margin.}
\item{n_participants}{Simulated independent participant count.}
\item{trials_per_participant}{Repeated trials within simulated participants.}
\item{n_time}{Regular trajectory time samples.}
\item{duration}{Positive observed time horizon.}
\item{n_curves}{Number of simulated AOI simplex curves.}
\item{n_aoi}{Number of AOI probability channels.}
\item{data}{Source irregular long-format data.frame.}
\item{curve_columns}{Identifier columns of the irregular source.}
\item{time_column}{Numeric sample-time column.}
\item{value_columns}{Named functional response channels.}
\item{grid}{Explicit shared target time grid.}
\item{metadata_columns}{Optional curve-constant metadata fields.}
\item{method}{Explicit native resampling method.}
\item{max_gap}{Optional largest interpolatable source gap.}
\item{coordinate_system}{Declared trajectory coordinate semantics.}
\item{time_unit}{Declared observed time unit.}
\item{section_dimension}{Explicit Poincare section dimension.}\item{section_value}{Finite section threshold.}\item{direction}{Positive, negative or both orientations.}\item{state_dimensions}{Declared non-section functional state dimensions.}\item{crossings}{Native Poincare crossing results.}\item{reference}{Local return-map mean, median or explicit reference vector.}\item{neighborhood_radius}{Positive local radius, exclusive with n_neighbors.}\item{n_neighbors}{Number of locally selected transitions, exclusive with radius.}
}
\value{A native fit, diagnostic or band result, trajectory collection, or structured coefficient data frame according to the invoked method.}
\details{Simultaneous bands operate over the observed grid. FNN is exact
brute force with a size cap and explicit tie differences. Embedding delays
are measured in samples.}
