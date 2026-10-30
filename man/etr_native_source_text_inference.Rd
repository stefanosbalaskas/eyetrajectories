\name{etr_generalized_function_on_scalar_prediction_reporting_text}
\alias{etr_generalized_function_on_scalar_prediction_reporting_text}
\alias{etr_generalized_function_on_scalar_mean_difference_reporting_text}
\alias{etr_functional_mixed_effects_covariance_sensitivity_reporting_text}
\alias{etr_multivariate_iaaft_reporting_text}
\alias{etr_multivariate_surrogate_nonlinearity_reporting_text}
\title{Scientific interpretation reports aligned to frozen Python 1.2.0}
\description{
Five Python-free, strictly descriptive reporting functions for generalized
function-on-scalar regression predictions and profile contrasts, functional
mixed-effects covariance sensitivity, multivariate IAAFT generation, and
surrogate-based multivariate nonlinearity inference.
}
\usage{
etr_generalized_function_on_scalar_prediction_reporting_text(result)
etr_generalized_function_on_scalar_mean_difference_reporting_text(result)
etr_functional_mixed_effects_covariance_sensitivity_reporting_text(result)
etr_multivariate_iaaft_reporting_text(result)
etr_multivariate_surrogate_nonlinearity_reporting_text(result)
}
\arguments{
\item{result}{A validated native R list representing the relevant source
result, containing explicit scalar identifiers, scientific metadata and
inference diagnostics.}
}
\value{
A manuscript-oriented character scalar; no statistical estimator, bootstrap,
interval or model selection is recalculated.
}
\details{
Scientific limitations are preserved: no between-grid simultaneous coverage
claims, no automatic covariance model selection, and rejection of a declared
surrogate null is not proof of deterministic chaos. Input acceptance is a
conservative native R record subset rather than the full Python frozen
dataclass and NumPy domain. Source-contract differences remain unresolved
and no full certification is inferred from matching example text.
}
