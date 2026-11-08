\name{etr_fit_joint_bspline_functional_nested_slope}
\alias{etr_fit_joint_bspline_functional_nested_slope}
\title{Joint native B-spline mixed model with participant random slope and nested trial effects}
\usage{
etr_fit_joint_bspline_functional_nested_slope(
  trajectories, design, predictors, participant_column, trial_column,
  dimension, random_slope_predictor, residual_correlation = "iid",
  fixed_basis_size = 6L, random_basis_size = 4L,
  trial_random_basis_size = 4L, spline_degree = 3L,
  reml = TRUE, maxiter = 500L
)
}
\arguments{
  \item{trajectories}{Finite complete native trajectory collection on a common strictly increasing time grid.}
  \item{design}{Data frame with one unique \code{curve_id} per source curve.}
  \item{predictors}{Names of numeric fixed predictors including the random-slope predictor.}
  \item{participant_column}{Existing participant identifier in trajectory metadata.}
  \item{trial_column}{Distinct trial identifier in metadata: one curve per participant/trial pair.}
  \item{dimension}{Name of one response channel.}
  \item{random_slope_predictor}{Named numeric predictor that varies within every participant.}
  \item{residual_correlation}{One of \code{"iid"}, \code{"ar1"}, or \code{"exponential"}. AR(1) requires regular spacing.}
  \item{fixed_basis_size}{Fixed-effect B-spline basis size (integer).}
  \item{random_basis_size}{Participant intercept/slope B-spline basis size (integer).}
  \item{trial_random_basis_size}{Nested trial B-spline basis size (integer).}
  \item{spline_degree}{Common B-spline degree, integer 1 through 5.}
  \item{reml}{If \code{TRUE}, restricted likelihood; otherwise maximum likelihood.}
  \item{maxiter}{At least 10 optimizer iterations.}
}
\description{
Fits one native Gaussian functional mixed-effects model with an unstructured
participant random intercept/slope B-spline coefficient covariance, separate
unstructured trial random coefficient covariance, and optional per-trial AR(1)
or physical-time exponential residual correlation.
}
\value{
An \code{etr_joint_bspline_mixed_nested_slope} object inheriting
\code{etr_joint_bspline_mixed} with coefficient functions and pointwise
standard errors, participant and trial coefficient covariances, BLUP functions,
conditional fitted and residual trajectories, within-trial serial covariance,
and the \code{nlme::lme} fit.
}
\details{
This is an additive bounded scientific native-R estimator with a preliminary
participant-only identifiability fit. It does not claim Python 1.2 optimizer,
result representation, error-contract, or complete scientific source parity.
No new frozen Python source gap is closed by this implementation alone.
}
