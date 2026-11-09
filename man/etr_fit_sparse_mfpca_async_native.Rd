\name{etr_fit_sparse_mfpca_async_native}
\alias{etr_fit_sparse_mfpca_async_native}
\title{Native direct asynchronous sparse multivariate FPCA and joint PACE}
\description{
Fits population directional cross-covariance and a two-channel
quadrature-weighted covariance eigensystem on irregular curves with
coordinate-specific missingness. A NaN identifies the missing coordinate
on a native union timestamp, and rows with both coordinates missing are
rejected. The common evaluation grid is used only for population functions,
not interpolation, nearest-neighbour synchronization or raw binning.
Simultaneous cross-products are excluded from latent cross-covariance and
correlated measurement error is inserted only for simultaneous x/y scalar
observations during full-covariance PACE scoring. The complete Python 1.2
source input/error contract has not yet been independently certified.
}
\usage{
etr_fit_sparse_mfpca_async_native(
  trajectories, dimensions = c("x", "y"), n_components,
  evaluation_grid, mean_bandwidth, covariance_bandwidth,
  measurement_error, measurement_error_variance = NULL,
  measurement_error_covariance = NULL,
  analysis_support_action = "error",
  same_time_tolerance = 0, psd_action = "error",
  psd_tolerance = 1e-8, positive_eigen_tolerance = 1e-10,
  score_ridge = 0, score_condition_limit = 1e12,
  min_score_observations = 2L, score_failure_action = "error",
  mean_min_local_points = 3L,
  covariance_min_local_pairs = 6L
)
}
\arguments{
\item{trajectories}{Native exact-union irregular trajectory set with possible coordinate NaNs.}
\item{dimensions}{Two distinct planar channel names.}
\item{n_components}{Positive integer retained joint operator rank.}
\item{evaluation_grid}{Strictly increasing population fitting grid.}
\item{mean_bandwidth}{Positive Epanechnikov mean smoothing bandwidth.}
\item{covariance_bandwidth}{Positive directional covariance smoothing bandwidth.}
\item{measurement_error}{Either \code{"diagonal"} or \code{"fixed_matrix"}.}
\item{measurement_error_variance}{Two nonnegative noise variances in diagonal mode.}
\item{measurement_error_covariance}{Symmetric PSD 2x2 matrix in fixed_matrix mode.}
\item{analysis_support_action}{Either \code{"error"} or \code{"restrict"}.}
\item{same_time_tolerance}{Finite nonnegative same-time tolerance.}
\item{psd_action}{Either \code{"error"} or \code{"project"}.}
\item{psd_tolerance}{Nonnegative joint operator PSD threshold.}
\item{positive_eigen_tolerance}{Positive joint component threshold.}
\item{score_ridge}{Nonnegative score covariance diagonal regularization.}
\item{score_condition_limit}{Maximum finite score covariance condition number.}
\item{min_score_observations}{Minimum scalar native observations per curve.}
\item{score_failure_action}{Either \code{"error"} or \code{"retain_nan"}.}
\item{mean_min_local_points}{Minimum locally weighted mean observations.}
\item{covariance_min_local_pairs}{Minimum locally weighted covariance pairs.}
}
\value{
Source-shaped native asynchronous MFPCA with means, covariance surfaces,
joint eigenfunctions and full-covariance PACE scores, metadata, native-time
and same-time noise diagnostics. No complete Python source-contract or
independent certification is claimed by the finite-domain implementation.
}
