\name{etr_fit_joint_bspline_functional_random_slope}
\alias{etr_fit_joint_bspline_functional_random_slope}
\title{Joint B-spline functional Gaussian mixed-effects random slope}
\description{Fits joint participant random-intercept and one random-slope functional B-spline model in native R using nlme. Participant random B-spline coefficients share an unstructured covariance; iid Gaussian residuals are assumed.}
\usage{
etr_fit_joint_bspline_functional_random_slope(
  trajectories, design, predictors, participant_column, dimension,
  random_slope_predictor, fixed_basis_size = 6L, random_basis_size = 4L,
  spline_degree = 3L, reml = TRUE, maxiter = 500L
)
}
\arguments{
\item{trajectories}{Finite complete native trajectory collection.}
\item{design}{Data frame containing a unique curve_id per source curve and numeric predictors.}
\item{predictors}{Names of explicitly selected fixed scalar predictors.}
\item{participant_column}{Participant identifier column in trajectory metadata.}
\item{dimension}{Name of one measured response channel.}
\item{random_slope_predictor}{Exactly one member of predictors; must vary within each participant.}
\item{fixed_basis_size}{Number of clamped B-spline fixed-effect basis functions.}
\item{random_basis_size}{Number of clamped B-spline functions per random intercept and random slope.}
\item{spline_degree}{B-spline degree, from 1 to 5.}
\item{reml}{Logical. TRUE performs REML; FALSE performs ML.}
\item{maxiter}{Maximum nlme optimizer iterations.}
}
\value{S3 \code{etr_joint_bspline_mixed_slope} inheriting from \code{etr_joint_bspline_mixed}, with fixed coefficient functions, SE, participant random intercept and slope functions, joint random covariance, residual variance, fitted values, observed values and an nlme fit.}
\details{This is an explicitly bounded native R implementation of the participant-only, one-slope, independent-residual scientific model. It does not claim full equivalence with the Python 1.2 statsmodels optimizer, error domain, typed results, nested random trial effects, or structured residual correlation. The participant count must exceed the number of free unstructured random-effect covariance parameters.}
