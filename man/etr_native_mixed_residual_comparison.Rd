\name{etr_compare_functional_mixed_effects_residual_diagnostics}
\alias{etr_compare_functional_mixed_effects_residual_diagnostics}
\title{Descriptive comparison of matched native functional mixed-moments residual diagnostics}
\description{
Compare observed time-lag residual dependence of two explicitly matched,
converged native functional method-of-moments models, preserving the frozen
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
\item{reference}{Restricted native converged functional mixed-moments fit.}
\item{comparison}{Restricted native converged functional mixed-moments fit
with identical time grid, source curves, participants and response channel.}
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
This uses the native two-level functional method-of-moments estimator,
not the full Python mixed-effects maximum-likelihood model. Input-domain,
source result-type and underlying estimator differences are open.
No automatic covariance model choice, hypothesis test, inferential
calibration, one-to-one certification or source-equivalent MixedLM fit
is claimed. Unmatched source curves, participants, time grids and
lag support are rejected rather than silently dropped.
}
