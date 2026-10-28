\name{etr_native_stage19_multiverse_clustering}
\alias{etr_lyapunov_parameter_sensitivity}
\alias{etr_kantz_parameter_sensitivity}
\alias{etr_rqa_parameter_sensitivity}
\alias{etr_cluster_fpca_scores}
\alias{etr_trajectory_distance_sensitivity}
\title{Native R nonlinear parameter multiverses, FPCA clustering and distance-contract sensitivity}
\description{Five independent Python-free numerical functions evaluating complete analyst-declared sensitivity grids, K-means over fitted FPCA scores, and comparisons of raw distance rankings and nearest-neighbor structures.}
\usage{
etr_lyapunov_parameter_sensitivity(trajectories, curve, dimensions, embedding_dimensions, delays, theiler_windows, fit_intervals, max_horizon, delay_units = "samples", theiler_window_units = "samples", fit_units = "samples", max_horizon_units = "samples")
etr_kantz_parameter_sensitivity(trajectories, curve, dimensions, embedding_dimensions, delays, radii, min_neighbors, theiler_windows, fit_intervals, max_horizon, delay_units = "samples", theiler_window_units = "samples", fit_units = "samples", max_horizon_units = "samples")
etr_rqa_parameter_sensitivity(trajectories, curve, dimensions, embedding_dimensions, delays, theiler_windows, min_diagonal_lengths, min_vertical_lengths, radii = NULL, target_recurrence_rates = NULL, delay_units = "samples", theiler_window_units = "samples", distance_metric = "euclidean")
etr_cluster_fpca_scores(fpca, n_clusters, n_components = NULL, random_state = 0L, n_init = "auto")
etr_trajectory_distance_sensitivity(trajectories, specifications, dimensions = NULL, dimension_weights = NULL, neighbor_k = 3L)
}
\arguments{
\item{trajectories}{Complete native common-grid trajectories; no preprocessing is applied.}
\item{curve}{Source zero-based curve index or exact curve identifier.}
\item{dimensions}{Nonempty explicit list of source dimension names; NULL uses all for distance sensitivity only.}
\item{embedding_dimensions}{Nonempty distinct integer grid, all >=2.}
\item{delays}{Nonempty distinct positive sample-delay grid.}
\item{theiler_windows}{Nonempty distinct nonnegative sample exclusion grid.}
\item{fit_intervals}{Nonempty list of distinct inclusive integer (start,end) sample-index fitting horizons.}
\item{max_horizon}{Maximum positive integer forward divergence horizon in samples.}
\item{delay_units}{Samples only; other physical-time units are not implemented in this restricted native stage.}
\item{theiler_window_units}{Samples only.}
\item{fit_units}{Samples only.}
\item{max_horizon_units}{Samples only.}
\item{radii}{Finite distinct positive radius grid for fixed-threshold recurrence or Kantz neighborhoods.}
\item{min_neighbors}{Nonempty distinct positive integer minimum-neighbor grid for Kantz.}
\item{min_diagonal_lengths}{Nonempty distinct positive integer RQA diagonal-line length grid.}
\item{min_vertical_lengths}{Nonempty distinct positive integer RQA vertical-line length grid.}
\item{target_recurrence_rates}{Not implemented: must remain NULL; no adaptive threshold substitution.}
\item{distance_metric}{Euclidean only in RQA sensitivity.}
\item{fpca}{Native finite FPCA fit with complete retained score matrix.}
\item{n_clusters}{Number of K-means groups, >=2 and no greater than number of scores.}
\item{n_components}{Number of retained fitted FPCA score columns, NULL uses all.}
\item{random_state}{Isolated base-R RNG seed, not scikit-learn/NumPy-identical.}
\item{n_init}{Positive number of independent K-means starts or auto (one R start).}
\item{specifications}{At least two unique named distance specifications with method functional_l2, discrete_frechet or dtw and explicit compatible DTW options.}
\item{dimension_weights}{Finite nonnegative weights on selected channels, with at least one positive.}
\item{neighbor_k}{Declared number of nearest other curves in each metric, between 1 and n_curves - 1.}
}
\value{A native numerical sensitivity result containing complete specification and descriptive summary tables, a labeled FPCA K-means partition, or complete unstandardized distance matrices and neighbor comparisons.}
\details{All sensitivity summaries describe variation over the declared specifications, not sampling intervals, automatic selection, or chaos probabilities. The RQA estimator is currently fixed-radius Euclidean and omits the Python center-of-recurrence-mass metric; target-recurrence-rate thresholding fails closed. Only sample-unit divergence parameterization is qualified. R's Hartigan-Wong K-means initializer and random streams differ from scikit-learn. Unstandardized pairwise distance correlations are descriptive because distances are not independent observations. The source-name register is not full API contract certification.}