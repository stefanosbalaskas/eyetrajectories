\name{etr_native_stage21_multivariate_iaaft}
\alias{etr_generate_multivariate_iaaft_surrogates}
\alias{etr_multivariate_iaaft_diagnostics_frame}
\title{Native reference-anchored multivariate IAAFT and spectral diagnostics}
\description{Two independently implemented Python-free R numerical methods for generating multivariate rank-remapped Fourier surrogates with a source-specified reference channel and evaluating retained auto-/cross-spectral approximation errors.}
\usage{
etr_generate_multivariate_iaaft_surrogates(trajectories, curve, dimensions, reference_dimension, n_surrogates = 199L, max_iterations = 1000L, tolerance = 1e-8, random_state = NULL)

etr_multivariate_iaaft_diagnostics_frame(result)
}
\arguments{
\item{trajectories}{Complete native R common-grid trajectory collection.}
\item{curve}{Exact curve ID or zero-based source index.}
\item{dimensions}{At least two explicitly selected distinct source channels.}
\item{reference_dimension}{One of the selected channels, specified in advance.}
\item{n_surrogates}{Positive integer number of independent rank-remapped Fourier surrogates.}
\item{max_iterations}{Positive integer limit for each Fourier adjustment loop.}
\item{tolerance}{Strictly positive finite change in combined relative spectral error convergence threshold.}
\item{random_state}{NULL (current R RNG stream) or scoped nonnegative base R RNG seed; NumPy draws are not reproduced.}
\item{result}{Native multivariate IAAFT result from this implementation.}
}
\value{The generator returns a native multivariate surrogate result with a 3D array of surrogate-by-time-by-channel observations, source data, all selected source channel names, explicit reference channel, per-surrogate iterations, and per-channel/per-channel-pair approximation errors. The diagnostics function returns a data frame with zero-based surrogate indexes and auto/cross-spectral summaries.}
\details{The reference channel anchors original interchannel Fourier phase offsets. Every channel's observed sorted marginal is restored exactly after each Fourier update, and relative auto-/cross-spectrum errors record deviations after the final rank remapping. Original means and Nyquist coefficients are imposed at their real-valued Fourier bins. The procedure is descriptive under a declared multivariate linear-stochastic surrogate null; it does not preserve nonlinear coupling or establish chaos/causation. The Python 1.2 source contract inspired the algorithm, but R's RNG streams do not match NumPy's, and exact stochastic source-parity certification remains pending. Invalid inputs and failed convergence raise errors.}
