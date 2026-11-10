\name{etr_generalized_function_on_scalar_predict}
\alias{etr_generalized_function_on_scalar_predict}
\title{Native fixed-profile marginal generalized function-on-scalar prediction}
\usage{
etr_generalized_function_on_scalar_predict(
  result, profiles, profile_id_column = "profile_id",
  exposure_profiles = NULL, prediction_scale = NULL, python_boundary_mode = FALSE
)
}
\arguments{
\item{result}{Explicit native generalized function-on-scalar fitted record.}
\item{profiles}{Data frame containing exactly profile identifiers and declared predictors. Numeric-text and Boolean predictor columns are converted to finite numeric values.}
\item{profile_id_column}{Unique identifier column name.}
\item{exposure_profiles}{Optional positive exposure vector or matrix for Poisson expected counts. Numeric text and logical values are converted before validating positivity and shape.}
\item{prediction_scale}{NULL or family-compatible probability, rate or expected_count.}
\item{python_boundary_mode}{Apply pandas-style string conversion to ordinary Boolean and floating-point profile identifiers. FALSE retains the native R identifier conversion.}
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
