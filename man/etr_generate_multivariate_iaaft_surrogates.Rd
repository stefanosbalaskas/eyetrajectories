\name{etr_generate_multivariate_iaaft_surrogates}
\alias{etr_generate_multivariate_iaaft_surrogates}
\title{Native multivariate IAAFT surrogates with shared Fourier constraints}
\usage{
etr_generate_multivariate_iaaft_surrogates(trajectories, curve, dimensions,
  reference_dimension, n_surrogates = 199L, max_iterations = 1000L,
  tolerance = 1e-8, random_state = NULL, initial_permutations = NULL)
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
}
\value{Native multivariate IAAFT source-shaped surrogate array, exact
empirical marginals, spectral/cross-spectral residual errors,
convergence counts and scientific provenance.}
\description{Imposes the published reference-anchored multivariate Fourier
phase constraints with iterative marginal rank remapping. The output
records approximate cross-spectrum agreement after rank remapping.
The seeded and supplied initialization paths run entirely in R.}
