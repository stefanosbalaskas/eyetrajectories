\name{etr_dynamic_time_warping_reporting_text}
\alias{etr_dynamic_time_warping_reporting_text}
\alias{etr_trajectory_distance_sensitivity_reporting_text}
\alias{etr_fpca_stability_reporting_text}
\alias{etr_fpca_outlier_reporting_text}
\alias{etr_fpca_influence_reporting_text}
\alias{etr_fpca_subspace_stability_reporting_text}
\alias{etr_fpca_cross_validation_reporting_text}
\alias{etr_multilevel_fpca_reporting_text}
\title{Native source-aligned manuscript descriptions of functional trajectory analyses}
\description{
Eight Python-free descriptive text reporting functions for audited
native R distance, FPCA, resampling and multilevel outputs.
}
\usage{
etr_dynamic_time_warping_reporting_text(result, digits = 3L)
etr_trajectory_distance_sensitivity_reporting_text(result, digits = 3L)
etr_fpca_stability_reporting_text(result,
  similarity_threshold = 0.80, digits = 2L)
etr_fpca_outlier_reporting_text(result)
etr_fpca_influence_reporting_text(result, digits = 2L)
etr_fpca_subspace_stability_reporting_text(result, digits = 3L)
etr_fpca_cross_validation_reporting_text(result,
  rule = "minimum", digits = 3L)
etr_multilevel_fpca_reporting_text(result, digits = 1L)
}
\arguments{
\item{result}{A compatible, independently computed native R result
of the type corresponding to the reporting function.}
\item{digits}{Finite, nonnegative integer display precision.}
\item{similarity_threshold}{Absolute matched-FPC similarity cutoff
in the closed interval [0,1].}
\item{rule}{Held-out cross-validation component selection:
\code{"minimum"} or \code{"one_se"}.}
}
\value{A single descriptive character string for manuscript drafting.}
\details{
Texts are source-aligned with published eyetrajectoriespy 1.2.0,
but derive values from native R scientific estimators and containers,
which are not always behaviorally identical to the source estimators.
A successful text-oracle comparison is not independent numerical
validation of the underlying estimator, nor a signed full public
source contract. R and Python formatting/validation boundary cases
require independent review. Bootstrap stability, influence, anomaly
flags and multiverse distances are descriptive: they are not
automatically calibrated probabilities or reasons for exclusion.
}
