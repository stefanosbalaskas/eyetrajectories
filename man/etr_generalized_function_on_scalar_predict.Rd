\name{etr_generalized_function_on_scalar_predict}
\alias{etr_generalized_function_on_scalar_predict}
\title{Native fixed-profile marginal generalized function-on-scalar prediction}
\usage{
etr_generalized_function_on_scalar_predict(
  result, profiles, profile_id_column = "profile_id",
  exposure_profiles = NULL, prediction_scale = NULL
)
}
\arguments{
\item{result}{Explicit native generalized function-on-scalar fitted record.}
\item{profiles}{Data frame containing exactly profile identifiers and declared numeric predictors.}
\item{profile_id_column}{Unique identifier column name.}
\item{exposure_profiles}{Optional positive exposure vector or matrix for Poisson expected counts.}
\item{prediction_scale}{NULL or family-compatible probability, rate or expected_count.}
}
\value{
Source-shaped native prediction record containing observed-grid means,
linear predictors, covariance-based pointwise standard errors,
extrapolation flags, and exposure-dependent fields.
}
\description{
Computes fixed marginal profile predictions without fitting new models or
reselecting predictors. Python dataclass boundaries and full upstream model
estimation parity remain open source-contract differences.
}
