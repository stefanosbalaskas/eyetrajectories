\name{etr_native_stage17_divergence} 
\alias{etr_delay_embed_trajectory}
\alias{etr_local_divergence_curve}
\alias{etr_kantz_divergence_curve}
\alias{etr_estimate_largest_lyapunov_rosenstein}
\alias{etr_estimate_largest_lyapunov_kantz}
\alias{etr_bootstrap_rqa_metric_means}
\title{Native R delay embedding, divergence, explicit Lyapunov fits and RQA population bootstrap}
\description{Six independent Python-free scientific implementations for complete multivariate delay embedding, Rosenstein and Kantz local divergence, explicit Lyapunov linear segments and fixed-radius population-average RQA bootstrap.}
\usage{
etr_delay_embed_trajectory(trajectories, embedding_dimension, delay, delay_units = "samples", dimensions = NULL)
etr_local_divergence_curve(embedding, curve, theiler_window, max_horizon, theiler_window_units = "samples", max_horizon_units = "samples")
etr_kantz_divergence_curve(embedding, curve, radius, theiler_window, max_horizon, min_neighbors = 2L, theiler_window_units = "samples", max_horizon_units = "samples")
etr_estimate_largest_lyapunov_rosenstein(divergence, fit_start, fit_end, fit_units = "samples")
etr_estimate_largest_lyapunov_kantz(divergence, fit_start, fit_end, fit_units = "samples")
etr_bootstrap_rqa_metric_means(trajectories, dimensions, metrics, radius = NULL, target_recurrence_rate = NULL, distance_metric = "euclidean", theiler_window = 0L, theiler_window_units = "samples", min_diagonal_length = 2L, min_vertical_length = 2L, embedding_dimension = NULL, delay = NULL, delay_units = "samples", unit = "curve", participant_column = NULL, confidence_level = 0.95, n_bootstrap = 2000L, random_state = 0L)
}
\arguments{
\item{trajectories}{Complete native trajectory collection, no implicit interpolation or smoothing.}
\item{embedding_dimension}{Explicit number of delay-coordinate blocks; reconstruction with at least two states.}
\item{delay}{Positive integer observed-sample lag, required for embedding.}
\item{delay_units}{Only samples; time-unit requests error explicitly.}
\item{dimensions}{Nonempty unique named source channels.}
\item{embedding}{Native etr_delay_embedding_set from the explicit stage-17 constructor.}
\item{curve}{Zero-based source index or exact curve ID.}
\item{theiler_window}{Nonnegative sample exclusion around each state.}
\item{max_horizon}{Positive number of forward observed-sample horizons.}
\item{theiler_window_units}{Only samples are currently supported.}
\item{max_horizon_units}{Only samples are currently supported.}
\item{radius}{Declared nonnegative recurrence radius or positive Kantz neighborhood radius.}
\item{min_neighbors}{Minimum fixed-radius Kantz neighbors per reference state.}
\item{divergence}{Native local or Kantz divergence curve, as appropriate.}
\item{fit_start}{Explicit inclusive first horizon in samples.}
\item{fit_end}{Explicit inclusive last horizon in samples, with at least three finite points.}
\item{fit_units}{Only samples.}
\item{metrics}{Explicit supported RQA metrics; unknown or undefined metrics error.}
\item{target_recurrence_rate}{Unsupported source adaptive-threshold option; errors rather than silently substituting a fixed radius.}
\item{distance_metric}{Euclidean only.}
\item{min_diagonal_length}{Positive RQA diagonal-line threshold.}
\item{min_vertical_length}{Positive RQA vertical-line threshold.}
\item{unit}{Independent curve or participant unit for population-average RQA bootstrap.}
\item{participant_column}{Required participant metadata field for independent participant averages.}
\item{confidence_level}{Nominal percentile interval level in (0,1).}
\item{n_bootstrap}{At least 100 whole-unit resampling replicates.}
\item{random_state}{Scoped base-R random seed; does not reproduce NumPy random streams.}
}
\value{A native delayed trajectory embedding, divergence trace, explicit slope estimate, or curve/participant-level RQA bootstrap result.}
\details{No chaos or causal interpretation follows solely from positive Lyapunov slope estimates. Divergence nearest-neighbor ties can differ from SciPy KDTree tie policies; source comparisons avoid tied fixture states. Unsupported adaptive thresholds and time-unit lags fail explicitly. The RQA bootstrap estimates the mean of per-curve summaries across independent curves or equal-weight participant averages, not uncertainty within one recurrence plot. Bootstrap RNG differs from NumPy. Mapped public names are not 508-contract certification.}