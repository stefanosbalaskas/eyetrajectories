\name{etr_sparse_mfpca_score_uncertainty_native}
\alias{etr_sparse_mfpca_score_uncertainty_native}
\alias{etr_sparse_mfpca_score_uncertainty_frame_native}
\title{Conditional Gaussian score uncertainty for direct joint sparse PACE}
\description{
Computes the full-covariance conditional score posterior
\eqn{\Lambda-\Lambda\Phi_i^T\Sigma_i^{-1}\Phi_i\Lambda}
for a native two-channel sparse joint PACE population fit. Native observation
times, directional cross-covariance, both measured channels, fitted score ridge
and full fitted covariance are retained. The resulting covariances exclude
population mean, covariance, eigensystem, measurement-noise specification and
bandwidth estimation uncertainty. This method is not independently certified
against all frozen Python 1.2 source input/error domains.
}
\usage{
etr_sparse_mfpca_score_uncertainty_native(
  fit, trajectories, condition_limit = NULL, failure_action = "error"
)
etr_sparse_mfpca_score_uncertainty_frame_native(result)
}
\arguments{
\item{fit}{A native direct joint sparse \code{etr_sparse_mfpca_source} fit.}
\item{trajectories}{The matched jointly observed irregular trajectories.}
\item{condition_limit}{Optional numeric or decimal-text source covariance
condition-number limit, finite and greater than one.}
\item{failure_action}{Either \code{"error"} or \code{"retain_nan"}.}
\item{result}{A native conditional joint PACE score uncertainty result.}
}
\value{
The first function returns per-curve posterior covariance and correlation
matrices, standard errors and source-status diagnostics. The second returns one row per curve
and retained joint component, with scores, conditional standard errors,
variance, status, condition number and method.
}
