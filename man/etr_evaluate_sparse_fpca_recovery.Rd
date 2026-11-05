\name{etr_evaluate_sparse_fpca_recovery}
\alias{etr_evaluate_sparse_fpca_recovery}
\title{Source known-truth univariate sparse FPCA recovery}
\usage{
etr_evaluate_sparse_fpca_recovery(result, truth)
}
\arguments{
\item{result}{Source-shaped fitted univariate sparse FPCA/PACE with exactly
one retained functional component and an estimated covariance matrix.}
\item{truth}{Frozen functional simulator truth including latent source curves
and measurement-noise covariance.}
}
\value{Source-shaped population recovery values, optional score diagnostics,
PSD repair metrics, measurement-noise error and explicit provenance.}
\description{Numerical one-component observed-grid source subset of
published Python 1.2.0. Preserves fitted covariance rather than silently
replacing it with the eigensystem covariance. No sparse estimator is fitted,
no truth interpolation occurs, and full multicomponent and typed source
contract certification remains pending.}
