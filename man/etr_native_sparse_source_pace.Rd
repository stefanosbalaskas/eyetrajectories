\name{etr_native_sparse_source_pace}
\alias{etr_fit_sparse_fpca_native}
\alias{etr_sparse_fpca_score_uncertainty_native}
\alias{etr_sparse_fpca_score_uncertainty_frame_native}
\title{Native Epanechnikov sparse FPCA and conditional PACE uncertainty}
\description{
Implements a Python-free source-structured native sparse FPCA/PACE model on
irregular observations, using local-linear Epanechnikov population smoothing,
an off-diagonal covariance surface, quadrature-weighted covariance PSD handling,
positive-eigenfunction decomposition and full-covariance conditional PACE scoring.
The fitted noise variance may be explicitly fixed or estimated through the
rotated local-quadratic diagonal-difference PACE estimator on declared
noise support. Both branches require sufficient local support and preserve
fail-closed invalid-noise behavior. The uncertainty method
conditions on fitted population covariance and excludes population estimation
uncertainty. Neither implementation is independently certified against every
Python 1.2 source input and error domain.
}
\usage{
etr_fit_sparse_fpca_native(
  trajectories, dimension, n_components, evaluation_grid,
  mean_bandwidth, covariance_bandwidth,
  noise_bandwidth = NULL, noise_support = NULL,
  noise_variance_method = if (is.null(measurement_error_variance))
    "diagonal_difference" else "fixed",
  measurement_error_variance = NULL,
  noise_min_local_points = 3L,
  analysis_support_action = "error", psd_action = "error",
  psd_tolerance = 1e-8, positive_eigen_tolerance = 1e-10,
  score_ridge = 0, score_condition_limit = 1e12,
  min_score_samples = 2L, score_failure_action = "error",
  mean_min_local_points = 3L, covariance_min_local_pairs = 6L,
  mean_smoother = "local_linear", covariance_smoother = "local_linear",
  kernel = "epanechnikov"
)
etr_sparse_fpca_score_uncertainty_native(
  fit, trajectories, condition_limit = NULL, failure_action = "error"
)
etr_sparse_fpca_score_uncertainty_frame_native(result)
}
\arguments{
\item{trajectories}{Native \code{etr_irregular_trajectory_set}; sparse observations remain on their native grids.}
\item{dimension}{Name of the observed finite response channel.}
\item{n_components}{Number of strictly positive covariance operator components to retain.}
\item{evaluation_grid}{Finite strictly increasing population-evaluation grid.}
\item{mean_bandwidth}{Positive Epanechnikov local-linear mean bandwidth.}
\item{covariance_bandwidth}{Positive Epanechnikov local-planar covariance bandwidth.}
\item{noise_variance_method}{\code{"fixed"} or \code{"diagonal_difference"}.
When omitted, the method is \code{"diagonal_difference"} unless a fixed
measurement-error variance was supplied.}
\item{measurement_error_variance}{Finite nonnegative fixed noise, or NULL for diagonal-difference estimation.}
\item{noise_bandwidth}{Positive smoothing bandwidth for squared residuals in diagonal-difference mode.}
\item{noise_support}{Two finite endpoints for noise estimation within the population grid.}
\item{noise_min_local_points}{Minimum local squared-residual support.}
\item{analysis_support_action}{\code{"error"} or \code{"restrict"} outside observations.}
\item{psd_action}{\code{"error"} or \code{"project"} for the covariance operator.}
\item{psd_tolerance}{Nonnegative weighted PSD eigenvalue tolerance.}
\item{positive_eigen_tolerance}{Nonnegative component eigenvalue threshold.}
\item{score_ridge}{Finite nonnegative score-system ridge.}
\item{score_condition_limit}{Condition-number ceiling greater than one.}
\item{min_score_samples}{Positive required count per PACE score system.}
\item{score_failure_action}{\code{"error"} or \code{"retain_nan"} on score failures.}
\item{mean_min_local_points}{Minimum positive-weight points per local mean estimate.}
\item{covariance_min_local_pairs}{Minimum off-diagonal pairs per local covariance estimate.}
\item{mean_smoother,covariance_smoother}{Both must be \code{"local_linear"}.}
\item{kernel}{The \code{"epanechnikov"} kernel.}
\item{fit}{Fitted native sparse FPCA object.}
\item{condition_limit}{Optional numeric or decimal-text override of the
retained score-system limit, finite and greater than one.}
\item{failure_action}{\code{"error"} or \code{"retain_nan"} for conditional uncertainty.}
\item{result}{Native conditional sparse score-uncertainty object.}
}
\value{
The fit returns covariance, eigenfunctions, scores, fitted mean, observed-grid
quadrature weights, and diagnostic/provenance data. The uncertainty method
returns conditional score covariance and correlation arrays and standard
errors for trajectories in the fit's curve order and measurement units. The frame
method returns one row per curve and component. With the error policy,
PACE score failures raise an \code{etr_sparse_native_error} condition with
the first failure's code and the audit rows for all curves in its details.
}
