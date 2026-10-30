\name{etr_generalized_function_on_scalar_prediction_bands}
\alias{etr_generalized_function_on_scalar_prediction_bands}
\title{Observed-grid simultaneous profile predictions from fixed bootstrap draws}
\usage{
etr_generalized_function_on_scalar_prediction_bands(
  bootstrap, confidence_level = 0.95, simultaneous_scope = "profile"
)
}
\arguments{
\item{bootstrap}{Native fixed-profile prediction bootstrap result.}
\item{confidence_level}{Probability strictly between zero and one.}
\item{simultaneous_scope}{Either "profile" or "family".}
}
\value{Native source-shaped intervals, original maxima, and critical values.}
\description{Calibrates observed-grid inverse-link endpoints with frozen
standardized maxima and NumPy higher quantile semantics. No claim of coverage
between grid points or complete Python 1.2 public contract equivalence.}
