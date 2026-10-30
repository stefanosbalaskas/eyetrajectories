\name{etr_fpca_wild_bootstrap_projection_reporting_text}
\alias{etr_fpca_wild_bootstrap_projection_reporting_text}
\alias{etr_fpca_regression_future_prediction_reporting_text}
\alias{etr_fpca_regression_uncertainty_reporting_text}
\alias{etr_fpca_regression_slope_band_reporting_text}
\alias{etr_fpca_nested_regression_cv_reporting_text}
\alias{etr_fpca_wild_bootstrap_family_test_reporting_text}
\alias{etr_fpca_wild_bootstrap_monte_carlo_reporting_text}
\alias{etr_fpca_wild_bootstrap_simultaneous_reporting_text}
\alias{etr_fpca_regression_cv_reporting_text}
\alias{etr_fpca_component_envelope_reporting_text}
\alias{etr_fpca_wild_bootstrap_truncation_reporting_text}
\title{Native FPCR inference and wild-bootstrap manuscript reporting}
\description{
Eight Python-free functions construct explicit scientific reporting strings
from already computed results. They never fit a model, resample, calibrate a
confidence band, or select hyperparameters.
}
\usage{
etr_fpca_wild_bootstrap_projection_reporting_text(result, digits = 3L)
etr_fpca_regression_future_prediction_reporting_text(result, digits = 3L)
etr_fpca_regression_uncertainty_reporting_text(result, digits = 3L)
etr_fpca_regression_slope_band_reporting_text(result, digits = 3L)
etr_fpca_nested_regression_cv_reporting_text(result, digits = 3L)
etr_fpca_wild_bootstrap_family_test_reporting_text(result, digits = 3L)
etr_fpca_wild_bootstrap_monte_carlo_reporting_text(result, digits = 3L)
etr_fpca_wild_bootstrap_simultaneous_reporting_text(result, digits = 3L)
etr_fpca_regression_cv_reporting_text(result, rule = "minimum", digits = 3L)
etr_fpca_component_envelope_reporting_text(result, digits = 2L)
etr_fpca_wild_bootstrap_truncation_reporting_text(result, digits = 3L)
}
\arguments{
\item{result}{An explicit named R list containing the scientifically defined
results and source-aligned fields needed by the selected reporting method.
Objects must already have been computed. No automatic coercion to a Python
dataclass is attempted.}
\item{digits}{Nonnegative integer decimal precision for the output.}
\item{rule}{Explicit minimum or one-standard-error selection rule for FPCA regression CV reporting.}
}
\value{
A character scalar containing descriptive manuscript wording. The wording
does not by itself establish an estimator's validity or interval coverage.
}
\details{
The source reference is the published eyetrajectoriespy 1.2.0 reporting.py
at commit c1cd95ad718327550f7e55393ff38582872f7a94.
The R accepted-input domain is intentionally narrower than the Python
dataclass contract. A Python 1.2 direct-text oracle is available as an
opt-in test, but full input type, return semantics and independent reviewer
certification remain pending. In particular, future-outcome prediction
intervals, conditional-mean uncertainty, pointwise slope envelopes, and
observed-grid simultaneous inference remain distinct estimands.
}
