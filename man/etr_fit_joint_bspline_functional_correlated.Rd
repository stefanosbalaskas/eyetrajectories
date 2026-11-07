\name{etr_fit_joint_bspline_functional_correlated}
\alias{etr_fit_joint_bspline_functional_correlated}
\title{Joint functional B-spline mixed effects with within-curve serial residual correlation}
\usage{
etr_fit_joint_bspline_functional_correlated(
  trajectories, design, predictors, participant_column, dimension,
  residual_correlation = "ar1", fixed_basis_size = 6L,
  random_basis_size = 4L, spline_degree = 3L,
  reml = TRUE, maxiter = 500L
)
}
\arguments{
\item{trajectories}{A complete, finite native trajectory set.}
\item{design}{Data frame with one unique \code{curve_id} row per trajectory.}
\item{predictors}{Unique numeric fixed-effect predictors in \code{design}.}
\item{participant_column}{Metadata field identifying participant groups.}
\item{dimension}{Name of one functional response dimension.}
\item{residual_correlation}{\code{"ar1"} for index-step AR(1) on equally spaced grids; \code{"exponential"} for continuous-time exponential decay on increasing grids.}
\item{fixed_basis_size}{Number of clamped fixed-effect B-spline basis functions.}
\item{random_basis_size}{Number of clamped participant random-intercept B-spline basis functions.}
\item{spline_degree}{Spline degree 1 to 5.}
\item{reml}{Use restricted ML if \code{TRUE}; otherwise ML.}
\item{maxiter}{Maximum optimizer iterations (at least 10).}
}
\description{Fits a single Gaussian mixed model with smooth functional fixed effects and unstructured participant B-spline random intercepts, with estimated within-trajectory serial residual correlation. The correlation is blocked by source curve and never crosses distinct trials. Uses optional R package \pkg{nlme}; no Python installation is needed.}
\details{The exponential correlation is \eqn{\exp(-|t-s|/\phi)} on the original time-unit scale. AR(1) uses \eqn{\rho^{|i-j|}} and requires a nearly regular grid. The implementation internally rescales time for numerical conditioning and reports \eqn{\phi} in original time units. It fits an additional joint likelihood rather than only correcting standard errors. Nested trial random effects and participant random slopes are not fitted by this particular method. Python 1.2 full-domain parity is not claimed.}
\value{An \code{etr_joint_bspline_mixed_correlated} object inheriting from \code{etr_joint_bspline_mixed}, with coefficient curves, SEs, Gaussian variance components, estimated residual correlation family/parameter and matrix, fitted curves, residuals, provenance and the underlying \code{nlme} fit.}
