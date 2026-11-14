\name{etr_multivariate_surrogate_nonlinearity_test}
\alias{etr_multivariate_surrogate_nonlinearity_test}
\title{Native multivariate MIAAFT Lyapunov surrogate hypothesis test}
\usage{
etr_multivariate_surrogate_nonlinearity_test(trajectories, curve,
  dimensions, reference_dimension, statistic,
  embedding_dimension, delay, theiler_window, max_horizon,
  fit_start, fit_end, delay_units = "samples",
  theiler_window_units = "samples", max_horizon_units = "samples",
  fit_units = "samples", n_surrogates = 199L,
  alternative = "greater", max_iterations = 1000L,
  tolerance = 1e-8, random_state = NULL,
  initial_permutations = NULL, phase_replay = NULL,
  python_boundary_mode = FALSE)
}
\arguments{
\item{trajectories}{Native complete regular common-grid trajectory set.}
\item{curve}{Source curve ID or zero-based index.}
\item{dimensions}{At least two explicitly selected channel names.}
\item{reference_dimension}{Explicit selected reference channel.}
\item{statistic}{Only largest_lyapunov.}
\item{embedding_dimension}{Embedding dimension.}
\item{delay,theiler_window,max_horizon,fit_start,fit_end}{Integer sample units.}
\item{delay_units,theiler_window_units,max_horizon_units,fit_units}{Must equal samples.}
\item{n_surrogates}{Positive number of generated null surrogates.}
\item{alternative}{greater, less or two-sided.}
\item{max_iterations,tolerance}{MIAAFT convergence controls.}
\item{random_state}{Integer seed for NumPy-compatible PCG64
initialization or NULL for unseeded native R draws.}
\item{initial_permutations}{Optional zero-based (n_surrogates, n_time,
n_selected_dimensions) complete per-channel initialization permutations,
forwarded to the MIAAFT generator.}
\item{phase_replay}{Optional Fourier phases for unresolved bins, forwarded to
\code{\link{etr_generate_multivariate_iaaft_surrogates}}.}
\item{python_boundary_mode}{If TRUE, use the declared source boundary
semantics; FALSE preserves native validation defaults.}
}
\value{Native multivariate Lyapunov statistic, surrogate distribution,
source-defined plus-one tail p-value and complete surrogate diagnostics.}
\description{Tests the declared largest-Lyapunov statistic under
reference-anchored multivariate IAAFT surrogates. Rejecting the null
does not establish deterministic chaos or a unique nonlinear mechanism.
Uses sample units and preserves native Fourier phases by default.
Numerically unresolved phases may be replayed from a comparison backend.}
