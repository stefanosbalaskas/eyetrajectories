\name{etr_compare_functional_mixed_effects_residual_diagnostics}
\alias{etr_compare_functional_mixed_effects_residual_diagnostics}
\title{Descriptive comparison of matched native functional mixed-model residual diagnostics}
\description{
Compare observed time-lag residual dependence of two explicitly matched,
converged native functional mixed-moments or R/nlme joint B-spline likelihood
models, preserving the frozen
Python 1.2 source's diagnostic column keys and difference definitions.
}
\usage{
etr_compare_functional_mixed_effects_residual_diagnostics(
  reference, comparison, max_lag,
  reference_label = "reference", comparison_label = "comparison",
  residual_scale = "raw"
)
}
\arguments{
\item{reference}{Restricted native converged functional mixed-moments fit or
native joint B-spline Gaussian likelihood fit.}
\item{comparison}{Matched native converged mixed-moments or joint Gaussian
likelihood fit with identical time grid, source curves, participants, observed
time unit and response channel.}
\item{max_lag}{Positive maximum index lag, smaller than grid length.}
\item{reference_label}{Nonempty reference model label.}
\item{comparison_label}{Nonempty comparison model label.}
\item{residual_scale}{One of \code{"raw"} or \code{"whitened"}.}
}
\value{
A descriptive data frame containing 0-based index lags and retained
physical lag times, pair counts, source metrics from each model, and the
comparison-minus-reference autocovariance, autocorrelation and semivariance.
}
\details{
This supports either restricted native two-level functional moments or
native R/nlme joint B-spline Gaussian fits without refitting them. The R
joint estimator is not the full Python statsmodels mixed-effects
maximum-likelihood/restricted-likelihood implementation. Input-domain,
source result-type and underlying estimator differences are open.
No automatic covariance model choice, hypothesis test, inferential
calibration, one-to-one certification or source-equivalent MixedLM fit
is claimed. Unmatched source curves, participants, time grids and
lag support are rejected rather than silently dropped.
}
