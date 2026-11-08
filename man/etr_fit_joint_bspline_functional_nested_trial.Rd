\name{etr_fit_joint_bspline_functional_nested_trial}
\alias{etr_fit_joint_bspline_functional_nested_trial}
\title{Joint functional mixed effects with nested trial B-spline random functions}
\usage{
etr_fit_joint_bspline_functional_nested_trial(
  trajectories, design, predictors, participant_column, trial_column, dimension,
  residual_correlation = "iid", fixed_basis_size = 6L,
  random_basis_size = 4L, trial_random_basis_size = 3L,
  spline_degree = 3L, reml = TRUE, maxiter = 500L
)
}
\arguments{
  \item{trajectories}{Complete finite common-grid native trajectory set.}
  \item{design}{Data frame containing one row per curve and a unique \code{curve_id}.}
  \item{predictors}{Character vector of numeric fixed predictors; may be empty.}
  \item{participant_column}{Participant grouping column in trajectory metadata.}
  \item{trial_column}{Distinct within-participant trial identifier in metadata.}
  \item{dimension}{One response channel name.}
  \item{residual_correlation}{\code{"iid"}, \code{"ar1"} on a regular grid, or \code{"exponential"} using time distances.}
  \item{fixed_basis_size}{Positive integer number of fixed spline functions.}
  \item{random_basis_size}{Positive integer participant random basis size.}
  \item{trial_random_basis_size}{Positive integer nested trial random basis size.}
  \item{spline_degree}{Spline degree, 1 through 5.}
  \item{reml}{Fit by restricted maximum likelihood if TRUE, ML otherwise.}
  \item{maxiter}{Maximum optimizer iterations, at least 10.}
}
\description{
Fits a native Gaussian joint functional mixed-effects regression with separate
unstructured participant-level and nested-trial-level B-spline random-function
covariances, optionally with serial correlation confined to each trial.
Requires \pkg{nlme}. Each participant-trial pair must identify exactly one curve.
This is a bounded scientific analogue, not full Python 1.2 source-contract parity.
}
\value{Also includes Python-shaped coefficient, participant/trial covariance,
residual-correlation, conditional residual-whitening, and nested trial ID
fields; the original native names remain available. The source optimizer
bounds are diagnostic only and are not enforced by the native optimizer.
The result also includes residual-correlation eigenvalues,
condition number, source optimizer-bound diagnostics, grid regularity and
interval, conditional whitened residual functions, and source-style trial ID
aliases. These are diagnostic/representation additions, not revised fits.
The returned object also includes source-aligned covariance eigenvalues,
condition numbers, near-boundary and singularity flags for both random levels.
An \code{etr_joint_bspline_mixed_nested_trial} S3 object inheriting
\code{etr_joint_bspline_mixed}. Includes fitted and residual trajectories,
fixed coefficient functions and standard errors, random-function BLUPs,
participant and trial coefficient covariances, residual covariance parameters,
and the fitted \code{nlme::lme} model.}
