\name{etr_functional_mixed_effects_simultaneous_bands}
\alias{etr_functional_mixed_effects_simultaneous_bands}
\title{Observed-grid mixed functional coefficient simultaneous bands}
\usage{
etr_functional_mixed_effects_simultaneous_bands(
  bootstrap, confidence_level = 0.95, simultaneous_scope = "coefficient"
)
}
\arguments{
\item{bootstrap}{Native retained coefficient bootstrap record, including
the explicit \code{bootstrap_type} ("conditional_covariance" or "full_refit").}
\item{confidence_level}{Nominal confidence probability in (0,1).}
\item{simultaneous_scope}{Coefficient or whole-family maximum statistics.}
}
\value{Source-shaped band, pointwise scales, maximum standardized
statistics and explicit retained refitting provenance.}
\description{Calibrates coefficient bands from stored participant-bootstrap
arrays without estimating model parameters, resampling participants or
selecting a model. The frozen Python 1.2 class-specific contract and full
scientific input domain remain independently uncertified.}
