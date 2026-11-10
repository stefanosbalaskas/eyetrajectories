\name{etr_fit_sparse_mfpca_native}
\alias{etr_fit_sparse_mfpca_native}
\title{Native directly fitted sparse two-channel covariance and joint PACE}
\description{
A Python-free direct sparse two-coordinate PACE estimator with local-linear
Epanechnikov population means and directional off-diagonal cross-covariance,
joint quadrature-weighted PSD handling, and a full-covariance joint score
system on native observation times. It is separate from the legacy
fdapace-marginal-score PCA alternative and is not independently certified
against the complete Python 1.2 public contract.
}
\usage{
etr_fit_sparse_mfpca_native(
  trajectories, dimensions = c("x", "y"), n_components = 2L,
  evaluation_grid, mean_bandwidth, covariance_bandwidth,
  measurement_error = "diagonal",
  measurement_error_variance = NULL,
  measurement_error_covariance = NULL,
  analysis_support_action = "error", psd_action = "error",
  psd_tolerance = 1e-8, positive_eigen_tolerance = 1e-10,
  score_ridge = 0, score_condition_limit = 1e12,
  min_score_time_points = 2L, score_failure_action = "error",
  mean_min_local_points = 3L, covariance_min_local_pairs = 6L
)
}
\arguments{
\item{trajectories}{Jointly observed native irregular trajectories.}
\item{dimensions}{Two distinct planar channel names.}
\item{n_components}{Positive integer number of fitted joint eigenfunctions.}
\item{evaluation_grid}{Finite increasing population fitting grid.}
\item{mean_bandwidth}{Positive Epanechnikov mean bandwidth.}
\item{covariance_bandwidth}{Positive covariance surface bandwidth.}
\item{measurement_error}{\code{"diagonal"} or \code{"fixed_matrix"}.}
\item{measurement_error_variance}{Two declared variances in diagonal mode.}
\item{measurement_error_covariance}{Symmetric PSD 2x2 matrix in fixed_matrix mode.}
\item{analysis_support_action}{\code{"error"} or \code{"restrict"}.}
\item{psd_action}{\code{"error"} or \code{"project"}.}
\item{psd_tolerance}{Nonnegative operator PSD tolerance.}
\item{positive_eigen_tolerance}{Eigenvalue positivity threshold.}
\item{score_ridge}{Nonnegative regularizer in source score covariance.}
\item{score_condition_limit}{Condition-number ceiling greater than one.}
\item{min_score_time_points}{Positive minimum number of retained time points.}
\item{score_failure_action}{\code{"error"} or \code{"retain_nan"}.}
\item{mean_min_local_points}{Minimum positive-weight observations for local means.}
\item{covariance_min_local_pairs}{Minimum positive-weight offdiagonal pairs for covariance blocks.}
}
\value{
A source-shaped native joint sparse FPCA model, including smoothed and PSD
covariance blocks (xx, xy, yx, yy), scores, vector eigenfunctions, retained
quadrature weights, and fitted diagnostics. Structured sparse errors retain
curve and zero-based sample indices for invalid planar observations,
support counts for rejected analysis grids, and covariance eigenvalue or
rank details when the declared PSD or component controls fail.
}
