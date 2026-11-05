\name{etr_generate_multivariate_iaaft_surrogates}
\alias{etr_generate_multivariate_iaaft_surrogates}
\title{Native multivariate IAAFT surrogates with shared Fourier constraints}
\usage{
etr_generate_multivariate_iaaft_surrogates(trajectories, curve, dimensions,
  reference_dimension, n_surrogates = 199L, max_iterations = 1000L,
  tolerance = 1e-8, random_state = NULL)
}
\arguments{
\item{trajectories}{Complete regular-grid native trajectory set.}
\item{curve}{Source curve ID or zero-based source index.}
\item{dimensions}{At least two selected channel names in requested order.}
\item{reference_dimension}{Explicit selected reference channel.}
\item{n_surrogates}{Number of rank-matched surrogate matrices.}
\item{max_iterations}{Maximum Fourier/rank remapping iterations.}
\item{tolerance}{Positive absolute change tolerance for combined spectral error.}
\item{random_state}{Optional base R RNG seed, with caller state restored.}
}
\value{Native multivariate IAAFT source-shaped surrogate array, exact
empirical marginals, spectral/cross-spectral residual errors,
convergence counts and scientific provenance.}
\description{Imposes the published reference-anchored multivariate Fourier
phase constraints with iterative marginal rank remapping. Cross-spectrum
agreement is approximate after rank remapping, not exact. Base R and
NumPy PCG64 random streams differ; full Python source contract parity
and independent certification are not claimed.}
