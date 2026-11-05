\name{etr_generalized_function_on_scalar_mean_difference_band}
\alias{etr_generalized_function_on_scalar_mean_difference_band}
\title{Observed-grid simultaneous contrast between two fixed generalized FoSR profiles}
\usage{
etr_generalized_function_on_scalar_mean_difference_band(
  bootstrap, profile_a, profile_b, confidence_level = 0.95,
  contrast_scale = NULL
)
}
\arguments{
\item{bootstrap}{Retained fixed-profile native prediction bootstrap record.}
\item{profile_a}{First predeclared profile identifier.}
\item{profile_b}{Second distinct predeclared profile identifier.}
\item{confidence_level}{Nominal confidence probability strictly inside zero and one.}
\item{contrast_scale}{Family-compatible probability, rate, ratio or expected-count contrast.}
}
\value{A native fixed-contrast inference record of estimates, intervals,
bootstrap statistics, scope and explicit scientific limitations.}
\description{Calibrates one fixed predeclared observed-grid marginal contrast,
using retained participant bootstrap predictions. Rate-ratio inference is
calibrated on the log-ratio scale. Physical bounds are audited but never
silently clipped. This is not a certified complete Python source contract.}
