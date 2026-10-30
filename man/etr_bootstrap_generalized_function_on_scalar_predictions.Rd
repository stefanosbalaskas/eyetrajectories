\name{etr_bootstrap_generalized_function_on_scalar_predictions}
\alias{etr_bootstrap_generalized_function_on_scalar_predictions}
\title{Project retained generalized FoSR bootstrap coefficients to fixed profiles}
\usage{
etr_bootstrap_generalized_function_on_scalar_predictions(
  bootstrap, profiles, profile_id_column = "profile_id",
  exposure_profiles = NULL, prediction_scale = NULL
)
}
\arguments{
\item{bootstrap}{Native retained participant coefficient-bootstrap record.}
\item{profiles}{Fixed target-profile data frame.}
\item{profile_id_column}{Unique target identifier column.}
\item{exposure_profiles}{Explicit positive Poisson target exposures, when needed.}
\item{prediction_scale}{Optional family-compatible prediction scale.}
}
\value{Source-shaped native record of precomputed B by target by time bootstrap predictions.}
\description{Projects retained whole-participant bootstrap coefficient draws
without additional resampling, fitting, selection or scientific coverage claims.
Full Python dataclass parity remains uncertified.}
