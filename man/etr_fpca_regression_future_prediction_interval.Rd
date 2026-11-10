\name{etr_fpca_regression_future_prediction_interval}
\alias{etr_fpca_regression_future_prediction_interval}
\title{Marginal future-outcome prediction intervals for Gaussian FPCR}
\usage{
etr_fpca_regression_future_prediction_interval(
  result, outcome, confidence_level = 0.95,
  residual_method = "empirical_centered", random_state = 0L,
  residual_indices = NULL
)
}
\arguments{
\item{result}{Retained Gaussian FPCR paired-bootstrap uncertainty record.}
\item{outcome}{Training outcomes matching the reference fitted responses.}
\item{confidence_level}{Marginal predictive interval coverage probability.}
\item{residual_method}{Must equal \code{"empirical_centered"}.}
\item{random_state}{Nonnegative integer seed below 2^53 for a spawned
NumPy-compatible PCG64 stream. NULL uses the current R RNG stream.}
\item{residual_indices}{Optional zero-based B-by-target source index matrix
allowing exact numerical replay of pinned Python residual draws.}
}
\value{Source-shaped marginal future-outcome predictive draws, limits,
medians, pointwise sample standard deviations and scientific provenance.}
\description{Applies the published Python 1.2 centered empirical residual
resampling and percentile-calibration law to retained paired-bootstrap
conditional-mean predictions. It assumes exchangeable response residuals
and reports marginal intervals for individual targets. An integer seed
reproduces NumPy's first spawned SeedSequence stream for the residual indices.}
