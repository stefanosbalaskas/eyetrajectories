\name{etr_sparse_fpca_partial_trajectory_prediction_native}
\alias{etr_sparse_fpca_partial_trajectory_prediction_native}
\alias{etr_sparse_fpca_partial_prediction_frame_native}
\title{Conditional future trajectory prediction with native sparse PACE}
\description{
Use a fitted native sparse FPCA population mean and full covariance surface
to condition on the raw native-time history of exactly one sparse target.
Returns future conditional latent mean and covariance and a separate
observed-predictive covariance that adds the fitted measurement noise but
does not reclassify numerical history ridge as future noise. It excludes
population estimation uncertainty, bandwidth uncertainty, and conformal
coverage guarantees; all-source-domain independent parity is not claimed.
}
\usage{
etr_sparse_fpca_partial_trajectory_prediction_native(
  fit, trajectory, history_cutoff, prediction_grid,
  min_history_observations = 2L,
  condition_limit = NULL, history_ridge = NULL
)
etr_sparse_fpca_partial_prediction_frame_native(result)
}
\arguments{
\item{fit}{Native fitted sparse PACE covariance model.}
\item{trajectory}{Exactly one native irregular trajectory with matched units.}
\item{history_cutoff}{Finite history endpoint within the fitted support.}
\item{prediction_grid}{Future nonempty strictly increasing time grid.}
\item{min_history_observations}{Required positive history observation count.}
\item{condition_limit}{Optional positive conditioning number ceiling.}
\item{history_ridge}{Optional nonnegative numerical history-only ridge.}
\item{result}{A native sparse conditional future result.}
}
\value{
A source-shaped conditional future object with latent and observed prediction
covariances, standard errors, native history, the history and prediction
counts, and numerical diagnostics.
The frame method returns one row per requested future time.
}
