\name{etr_surrogate_nonlinearity_test}
\alias{etr_surrogate_nonlinearity_test}
\title{Native IAAFT surrogate test of an explicitly declared Lyapunov statistic}
\description{Independent base-R iterative amplitude-adjusted Fourier-transform surrogates with explicit Rosenstein sample-index statistic and plus-one Monte Carlo tail probability. Published Python 1.2 is the source of the mathematical contract; random draws are not identical across R and NumPy.}
\usage{
etr_surrogate_nonlinearity_test(trajectories, curve, dimension, statistic,
  embedding_dimension, delay, theiler_window, max_horizon, fit_start, fit_end,
  delay_units = "samples", theiler_window_units = "samples",
  max_horizon_units = "samples", fit_units = "samples", method = "iaaft",
  n_surrogates = 199L, alternative = "greater", max_iterations = 1000L,
  tolerance = 1e-8, random_state = NULL)
}
\arguments{
\item{trajectories}{A complete native common-grid trajectory set.}
\item{curve}{Exact source curve ID or zero-based index.}
\item{dimension}{An explicitly declared source dimension.}
\item{statistic}{Only largest_lyapunov is supported.}
\item{embedding_dimension}{Number of delay-coordinate blocks, at least two.}
\item{delay}{Positive integer observed-sample delay.}
\item{theiler_window}{Nonnegative sample-unit neighbor exclusion.}
\item{max_horizon}{Positive integer forward sample horizon.}
\item{fit_start,fit_end}{Explicit inclusive fit horizon indices.}
\item{delay_units,theiler_window_units,max_horizon_units,fit_units}{All must be samples; time conversions are not silently approximated.}
\item{method}{Only iaaft is supported.}
\item{n_surrogates}{Positive count of independent IAAFT surrogate series.}
\item{alternative}{greater, less, or two-sided.}
\item{max_iterations}{Positive IAAFT convergence iteration limit.}
\item{tolerance}{Positive finite spectral-error-change stopping threshold.}
\item{random_state}{Optional scoped base-R nonnegative integer random seed; omitted draws use current R RNG.}
}
\value{A native structured result with observed exponent, per-surrogate exponents, p-value, convergence iterations, spectral errors and fail-closed provenance.}
\details{IAAFT preserves each observed finite sample value exactly but approximately matches Fourier amplitude spectrum. The native test uses a plus-one tail probability, doubles the smaller tail for two-sided alternatives and raises an error if a declared surrogate fails to converge. R and NumPy RNG streams are not equivalent. The test is evidence against the declared linear-stochastic null, not proof of a unique deterministic chaotic mechanism or causality. Exact source API parity and sampling calibration have not been certified.}
