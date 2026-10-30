\name{etr_fpca_regression_slope_simultaneous_band}
\alias{etr_fpca_regression_slope_simultaneous_band}
\title{Native paired-bootstrap simultaneous FPCR slope bands on the observed grid}
\description{Pure native R postcalibration of an existing paired-bootstrap
Gaussian FPCR slope array. Uses studentized maximum absolute bootstrap
deviations with a global time-by-dimension maximum or separate
per-dimension time maxima.}
\usage{
etr_fpca_regression_slope_simultaneous_band(
  result, confidence_level = 0.95, simultaneous_scope = "global")
}
\arguments{
\item{result}{Native scientific fit record with finite reference slope
matrix, finite B-by-time-by-dimension bootstrap slope array,
and source FPCA dimension identifiers.}
\item{confidence_level}{Numeric probability strictly between zero and one.}
\item{simultaneous_scope}{One of \code{"global"} or \code{"dimension"}.}
}
\value{A scientific R record with reference-grid lower and upper bounds,
pointwise bootstrap standard errors, source-calibrated maximum
absolute studentized statistics, and critical values. Return class
is not equivalent to Python's dataclass.}
\details{The postcalibration matches the frozen Python 1.2.0
\code{fpca_regression_slope_simultaneous_band} observed-grid procedure.
Sample bootstrap standard deviations (ddof=1) and NumPy
\code{method="higher"} quantiles are retained. Material nonzero
reference discrepancies with effectively zero bootstrap standard
error are rejected. No regression fit, basis, or bootstrap
data are recomputed. Continuous-domain coverage, operator-scaled
FPCR significance tests, and full source-contract equivalence
are not claimed or independently certified.}
