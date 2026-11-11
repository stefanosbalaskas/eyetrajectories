\name{etr_generate_multivariate_iaaft_surrogates}
\alias{etr_generate_multivariate_iaaft_surrogates}
\title{Native multivariate IAAFT surrogates with shared Fourier constraints}
\usage{
etr_generate_multivariate_iaaft_surrogates(trajectories, curve, dimensions,
  reference_dimension, n_surrogates = 199L, max_iterations = 1000L,
  tolerance = 1e-8, random_state = NULL, initial_permutations = NULL,
  phase_replay = NULL)
}
\arguments{
\item{trajectories}{Complete regular-grid native trajectory set.}
\item{curve}{Source curve ID or zero-based source index.}
\item{dimensions}{At least two selected channel names in requested order.}
\item{reference_dimension}{Explicit selected reference channel.}
\item{n_surrogates}{Number of rank-matched surrogate matrices.}
\item{max_iterations}{Maximum Fourier/rank remapping iterations.}
\item{tolerance}{Positive absolute change tolerance for combined spectral error.}
\item{random_state}{Integer seed for NumPy-compatible PCG64 permutations,
or NULL for unseeded native R draws.}
\item{initial_permutations}{Optional integer-valued zero-based three-dimensional
array of shape (n_surrogates, n_time, n_selected_dimensions), containing
complete initial time-index permutations for every surrogate and channel.}
\item{phase_replay}{Optional named list with \code{target}, a
\code{(floor(n_time/2) + 1, n_selected_dimensions)} matrix, and/or
\code{reference}, a list with one entry per surrogate. Each reference entry
is NULL or a matrix with one row per iteration and one column per Fourier
bin. Entries are radians in \eqn{[-\pi, \pi]} or NA to keep the native phase.
Channel and bin order match the selected dimensions and the real half
spectrum. The first row of a reference matrix is the phase during the
first iteration. Supplied values after convergence cause an error.}
}
\value{Native multivariate IAAFT source-shaped surrogate array, exact
empirical marginals, spectral/cross-spectral residual errors,
convergence counts and scientific provenance.}
\description{Imposes the published reference-anchored multivariate Fourier
phase constraints with iterative marginal rank remapping. The output
records approximate cross-spectrum agreement after rank remapping.
The seeded and supplied initialization paths run entirely in R.}
\details{Phase replay supports reproducible comparison at Fourier bins
where the phase is numerically unresolved. In each channel the allowed
amplitude is at most eight times the ceiling of the base-two logarithm of
the sample count times double machine epsilon times the largest Fourier
amplitude. DC and the even-length Nyquist bin retain their original real
coefficients. With no replay, the algorithm uses native Fourier phases.
Replay leaves amplitudes, stable rank remapping, spectral diagnostics and
convergence evaluation native. Near-zero cross-spectrum norms can make
relative errors sensitive to the Fourier backend even with phase replay.
Provenance records the affected zero-based target reference bins and the
number of replayed target and reference phases.}
