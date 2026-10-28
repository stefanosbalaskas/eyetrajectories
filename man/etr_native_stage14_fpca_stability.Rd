\name{etr_native_stage14_fpca_stability}
\alias{etr_compare_fpca_subspaces}
\alias{etr_bootstrap_fpca_subspace_stability}
\alias{etr_summarise_fpca_subspace_stability}
\alias{etr_leave_one_group_out_fpca_influence}
\alias{etr_bootstrap_fpca_stability}
\alias{etr_summarise_fpca_stability}
\alias{etr_diagnose_fpca_outliers}
\title{Native R FPCA eigenspace stability, influence and empirical outlier diagnostics}
\description{Seven Python-free scientific implementations: weighted principal-angle subspace comparison, grouped/curve bootstrap stability, one-group-out influence, component-matched bootstrap diagnostics and explicitly selected empirical-covariance outlier screening.}
\usage{
etr_compare_fpca_subspaces(reference, candidate, start_component = 0L, n_components = 2L)
etr_bootstrap_fpca_subspace_stability(trajectories, start_component = 0L, n_components = 2L, n_bootstrap = 200L, scaling = "none", resample_unit = "curve", participant_column = NULL, random_state = 0L)
etr_summarise_fpca_subspace_stability(result, interval = c(0.025, 0.975))
etr_leave_one_group_out_fpca_influence(trajectories, group_column = NULL, n_components = 3L, scaling = "none")
etr_bootstrap_fpca_stability(trajectories, n_bootstrap = 200L, n_components = 3L, scaling = "none", resample_unit = "curve", participant_column = NULL, random_state = 0L)
etr_summarise_fpca_stability(result, similarity_threshold = 0.80, interval = c(0.025, 0.975))
etr_diagnose_fpca_outliers(result, trajectories, n_components = NULL, reconstruction_z_threshold = 3.5, score_alpha = 0.99, score_covariance = "robust", random_state = 0L)
}
\arguments{
\item{reference}{Native reference FPCA fitted result.}
\item{candidate}{Native comparison FPCA result with same observed grid and dimensions.}
\item{start_component}{Zero-based contiguous component-block start.}
\item{n_components}{Positive component count; NULL uses all fitted components in outlier diagnostics.}
\item{trajectories}{Complete native common-grid functional source trajectories.}
\item{n_bootstrap}{Nonparametric bootstrap replicate count, at least 2.}
\item{scaling}{Native FPCA scaling, none or dimension_sd.}
\item{resample_unit}{Curve or participant-level independent resampling.}
\item{participant_column}{Source trajectory participant identifier metadata field.}
\item{random_state}{Scoped base-R seed; NumPy RNG streams are not identical.}
\item{result}{Native stability, influence or FPCA fit, depending on method.}
\item{interval}{Two increasing quantile levels in [0,1].}
\item{group_column}{Optional group metadata for entire-participant leave-out.}
\item{similarity_threshold}{Predeclared descriptive absolute cosine threshold in [0,1].}
\item{reconstruction_z_threshold}{Predeclared positive robust-MAD threshold.}
\item{score_alpha}{Score-space Mahalanobis chi-square quantile in (0,1).}
\item{score_covariance}{Only explicitly requested empirical covariance is currently implemented; robust MCD fails closed.}
}
\value{Numerical native comparison, influence, stability or review-diagnostics results or their structured R summary tables.}
\details{All bootstrap and outlier results are descriptive. No automatic exclusions, continuous-domain inferential coverage, robust MCD covariance substitution, bitwise R-versus-NumPy seed matching, or completed 508-source API certification is claimed.}