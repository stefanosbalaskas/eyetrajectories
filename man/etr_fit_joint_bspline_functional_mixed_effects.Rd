\name{etr_fit_joint_bspline_functional_mixed_effects}
\alias{etr_fit_joint_bspline_functional_mixed_effects}
\title{Joint native B-spline functional mixed-effects model}
\description{Fits a Gaussian joint functional mixed model with B-spline fixed
coefficient functions and participant random B-spline intercept functions.
Uses the native R package \pkg{nlme}; never invokes Python.}
\usage{
etr_fit_joint_bspline_functional_mixed_effects(
  trajectories, design, predictors, participant_column, dimension,
  fixed_basis_size = 6L, random_basis_size = 4L,
  spline_degree = 3L, reml = TRUE, maxiter = 500L
)
}
\arguments{
\item{trajectories}{Finite complete native trajectory set on one grid.}
\item{design}{Data frame containing unique \code{curve_id} and numeric predictors.}
\item{predictors}{Character vector of unique fixed predictor column names; can be empty.}
\item{participant_column}{Participant grouping column in trajectory metadata.}
\item{dimension}{Response dimension name.}
\item{fixed_basis_size}{Number of clamped fixed-effect B-spline basis functions.}
\item{random_basis_size}{Number of random-intercept B-spline basis functions.}
\item{spline_degree}{B-spline degree (1 through 5), requiring basis size at least degree+1.}
\item{reml}{Whether to use REML rather than ordinary maximum likelihood.}
\item{maxiter}{Maximum number of \pkg{nlme} optimizer iterations.}
}
\value{S3 \code{etr_joint_bspline_mixed} list containing functional coefficients,
pointwise standard errors, random-effect coefficient covariance, participant
random functions, variance components, fitted and residual trajectories,
a \code{residual_correlation_matrix} equal to the time-grid identity matrix,
and an \code{nlme::lme} fitted model.}
\details{This estimator implements the basic participant random-intercept,
independent Gaussian error model with an unstructured B-spline random effect
covariance. It does not fit random slopes, nested trials, or structured
residual correlation. The returned object is an R S3 object, not the Python
\code{FunctionalMixedEffectsResult}; full Python 1.2 source parity is not claimed.}
