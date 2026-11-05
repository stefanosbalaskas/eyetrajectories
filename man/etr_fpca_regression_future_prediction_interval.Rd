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
\item{random_state}{Native R seed or NULL. Not NumPy SeedSequence equivalent.}
\item{residual_indices}{Optional zero-based B-by-target source index matrix
allowing exact numerical replay of pinned Python residual draws.}
}
\value{Source-shaped marginal future-outcome predictive draws, limits,
medians, pointwise sample standard deviations and scientific provenance.}
\description{Applies the published Python 1.2 centered empirical residual
resampling and percentile-calibration law to retained paired-bootstrap
conditional-mean predictions. It assumes exchangeable response residuals
and is not heteroscedasticity-robust. This does not provide simultaneous
prediction intervals across targets, does not refit FPCR, and R's native
random-number stream is not identical to NumPy's spawned SeedSequence.}
