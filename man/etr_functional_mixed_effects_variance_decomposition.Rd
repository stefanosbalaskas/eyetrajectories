\name{etr_functional_mixed_effects_variance_decomposition}
\alias{etr_functional_mixed_effects_variance_decomposition}
\title{Functional mixed-effects variance and covariance functions}
\usage{
etr_functional_mixed_effects_variance_decomposition(
  fit, model_label = NULL
)
}
\arguments{
\item{fit}{Native restricted moments fit, explicit source-shaped Gaussian
functional mixed-effects record, or a native joint B-spline likelihood fit.
The latter is mapped from its actual participant, optional slope, and nested
trial basis-covariance blocks without a statistical refit.}
\item{model_label}{Optional nonempty model identifier.}
}
\value{Data frame with model, component, component_type, time, value.
Source-shaped fits retain participant intercept and slope variances,
signed intercept/slope cross-covariance, trial variance if applicable,
and residual variance separately.}
\description{Descriptive source-aligned numerical components only; no
percentage partition, covariance model selection or test. The restricted
moments branch is not the published Python REML/GLS estimator and is
preserved for backward compatibility. The source-shaped branch remains
independently uncertified across its entire input domain. Joint-fit
adapter results retain signed participant intercept/slope covariance and
separate nested-trial variance components, but do not assert source Python
optimizer equivalence or any percentage variance partition.}
