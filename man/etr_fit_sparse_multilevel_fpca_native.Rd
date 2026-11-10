\name{etr_fit_sparse_multilevel_fpca_native}
\alias{etr_fit_sparse_multilevel_fpca_native}
\title{Native sparse multilevel FPCA covariance and hierarchical BLUP}
\description{
Direct irregular functional two-level covariance estimation for repeated
participant trials. The mean and covariance surfaces are fitted by
Epanechnikov local-linear smoothers without interpolating the observations.
Same-participant distinct-trial products identify between covariance.
Smoothed total minus smoothed between identifies trial covariance. The
two weighted PSD-repaired operators yield component eigenfunctions and
full-covariance Gaussian participant/trial BLUP scores.
}
\usage{
etr_fit_sparse_multilevel_fpca_native(
  trajectories, dimension, participant_column,
  participant_components, trial_components, evaluation_grid,
  mean_bandwidth, total_covariance_bandwidth,
  between_covariance_bandwidth,
  noise_bandwidth = NULL, noise_support = NULL,
  analysis_support_action = "error", weighting = "observation",
  mean_smoother = "local_linear",
  covariance_smoother = "local_linear",
  kernel = "epanechnikov",
  noise_variance_method = "diagonal_difference",
  measurement_error_variance = NULL, psd_action = "error",
  psd_tolerance = 1e-8, positive_eigen_tolerance = 1e-10,
  score_ridge = 0, score_condition_limit = 1e12,
  min_participant_score_samples = 2L,
  score_failure_action = "error", mean_min_local_points = 3L,
  total_covariance_min_local_pairs = 6L,
  between_covariance_min_local_pairs = 6L,
  noise_min_local_points = 3L
)
}
\arguments{
\item{trajectories}{Source native irregular trial collection with participant metadata.}
\item{dimension}{Observed functional response column.}
\item{participant_column}{Metadata identifier for repeated participant trials.}
\item{participant_components}{Retained between-participant eigensystem rank.}
\item{trial_components}{Retained within-participant eigensystem rank.}
\item{evaluation_grid}{Strictly increasing population evaluation grid.}
\item{mean_bandwidth}{Mean local-linear bandwidth.}
\item{total_covariance_bandwidth}{Within-trial total covariance smoothing bandwidth.}
\item{between_covariance_bandwidth}{Distinct-trial covariance smoothing bandwidth.}
\item{noise_bandwidth}{Diagonal-difference noise bandwidth when estimated.}
\item{noise_support}{Noise interval within population evaluation grid.}
\item{analysis_support_action}{Either \code{"error"} or \code{"restrict"}.}
\item{weighting}{Observation/pair weighting; must be \code{"observation"}.}
\item{mean_smoother}{Must be \code{"local_linear"}.}
\item{covariance_smoother}{Must be \code{"local_linear"}.}
\item{kernel}{Must be \code{"epanechnikov"}.}
\item{noise_variance_method}{Either \code{"fixed"} or \code{"diagonal_difference"}.}
\item{measurement_error_variance}{Known nonnegative noise in fixed mode.}
\item{psd_action}{Either \code{"error"} or \code{"project"}.}
\item{psd_tolerance}{Nonnegative operator PSD tolerance.}
\item{positive_eigen_tolerance}{Nonnegative eigenvalue threshold.}
\item{score_ridge}{Nonnegative BLUP covariance regularizer.}
\item{score_condition_limit}{Finite upper bound on condition number.}
\item{min_participant_score_samples}{Minimum pooled native participant samples.}
\item{score_failure_action}{Either \code{"error"} or \code{"retain_nan"}.}
\item{mean_min_local_points}{Minimum locally weighted mean observations.}
\item{total_covariance_min_local_pairs}{Minimum locally weighted same-trial pairs.}
\item{between_covariance_min_local_pairs}{Minimum locally weighted different-trial pairs.}
\item{noise_min_local_points}{Minimum locally weighted noise observations.}
}
\value{
Source-structured irregular multilevel FPCA population and score object.
Includes participant/trial eigensystems, within/between covariance audit,
full-covariance BLUP score diagnostics, and support provenance. No
independent scientific or full Python 1.2 source-domain certification is
claimed by this experimental native implementation.
}
