\name{etr_native_cv_uncertainty}
\alias{etr_cross_validate_fpca_reconstruction}
\alias{etr_summarise_fpca_cross_validation}
\alias{etr_select_fpca_components_cv}
\alias{etr_summarise_fpca_regression_cv}
\alias{etr_select_fpca_regression_components}
\alias{etr_fpca_score_uncertainty_frame}
\alias{etr_fpca_spectrum_uncertainty_frame}
\alias{etr_conformal_fpca_anomaly_frame}
\alias{etr_trajectory_distance_comparison_frame}
\alias{etr_trajectory_distance_neighbor_frame}
\alias{etr_fpca_regression_slope_band_frame}
\alias{etr_fpca_regression_slope_uncertainty_frame}
\alias{etr_fpca_regression_prediction_uncertainty_frame}
\alias{etr_fpca_regression_future_prediction_frame}
\title{Stage 12 native R FPCA cross-validation and uncertainty-result frames}
\description{Python-free leakage-aware functional PCA cross-validation with explicit component selection and deterministic adapters for previously computed uncertainty and prediction results.}
\usage{
etr_cross_validate_fpca_reconstruction(trajectories, candidate_components = c(1L, 2L, 3L, 4L, 5L), n_splits = 5L, scaling = "none", cv_unit = "curve", group_column = NULL, shuffle = TRUE, random_state = 0L)
etr_summarise_fpca_cross_validation(result)
etr_select_fpca_components_cv(result, rule = "minimum")
etr_summarise_fpca_regression_cv(result)
etr_select_fpca_regression_components(result, rule = "minimum")
etr_fpca_score_uncertainty_frame(result)
etr_fpca_spectrum_uncertainty_frame(result)
etr_conformal_fpca_anomaly_frame(result)
etr_trajectory_distance_comparison_frame(result)
etr_trajectory_distance_neighbor_frame(result)
etr_fpca_regression_slope_band_frame(result)
etr_fpca_regression_slope_uncertainty_frame(result)
etr_fpca_regression_prediction_uncertainty_frame(result)
etr_fpca_regression_future_prediction_frame(result)
}
\arguments{
\item{trajectories}{Complete native common-grid curves.}
\item{candidate_components}{Positive integer counts, deduplicated and sorted.}
\item{n_splits}{Number of held-out partitions, at least two.}
\item{scaling}{Declared functional channel scaling.}
\item{cv_unit}{Use curve-level or group-level partitioning.}
\item{group_column}{Required metadata column for grouped holdouts.}
\item{shuffle}{Whether to shuffle curve order prior to fold assignment.}
\item{random_state}{Nonnegative R RNG seed, scoped and restored; does not reproduce NumPy permutations.}
\item{result}{Native FPCA CV object, declared regression CV object or a source-shaped, previously computed uncertainty structure.}
\item{rule}{Explicit minimum or one-standard-error heuristic.}
}
\value{Native FPCA cross-validation result, a component count, or an auditable R data frame, according to the function.}
\details{Functional PCA is refitted only on each fold's training sample and evaluated on held-out curves. Group folds preserve participant independence but tied group fold IDs may differ from scikit-learn. Other helpers organize preexisting uncertainty results without calculating new bootstrap intervals or certifying coverage. The 508 public Python source-contract gate remains closed.}