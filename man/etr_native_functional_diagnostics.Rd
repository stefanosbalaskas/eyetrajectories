\name{etr_native_functional_diagnostics}
\alias{etr_alr_transform}
\alias{etr_inverse_alr}
\alias{etr_component_trajectories}
\alias{etr_select_n_components}
\alias{etr_fpca_score_frame}
\alias{etr_score_distance_matrix}
\alias{etr_pairwise_functional_distances}
\alias{etr_sparse_dimension_summary}
\alias{etr_warping_displacement}
\alias{etr_phase_summary}
\alias{etr_phase_trajectory_set}
\alias{etr_fit_phase_fpca}
\title{Stage 9 native R functional transformations and scientific diagnostics}
\description{Twelve Python-free implementations of selected eyetrajectoriespy 1.2.0 functional transformations, distance summaries and phase diagnostics. Native R implementations have been authored; comprehensive one-to-one Python contract equivalence has not been established.}
\usage{
etr_alr_transform(values, reference_dimension = -1L, epsilon = 1e-8,
  python_boundary_mode = FALSE)
etr_inverse_alr(transformed, reference_dimension, n_dimensions,
  python_boundary_mode = FALSE)
etr_component_trajectories(result, component, sd_multipliers = c(-2, -1, 0, 1, 2))
etr_select_n_components(result, threshold = 0.95)
etr_fpca_score_frame(result, prefix = "FPC")
etr_score_distance_matrix(fpca, n_components = NULL,
  python_boundary_mode = FALSE)
etr_pairwise_functional_distances(trajectories, dimension_weights = NULL)
etr_sparse_dimension_summary(trajectories, dimension)
etr_warping_displacement(result)
etr_phase_summary(result)
etr_phase_trajectory_set(registration, representation = "displacement")
etr_fit_phase_fpca(registration, representation = "displacement",
                   n_components = 0.95)
}
\arguments{
\item{values}{Three-dimensional numeric array of compositional probabilities.}
\item{reference_dimension}{Python-style zero-based reference component; -1 selects the last.}
\item{epsilon}{Strictly positive clipping floor for ALR, declared before analysis.}
\item{transformed}{Finite three-dimensional ALR values.}
\item{n_dimensions}{Original number of channels, at least two.}
\item{result}{A native FPCA fit or registration result, as appropriate.}
\item{component}{Zero-based index of a fitted FPCA component.}
\item{sd_multipliers}{Finite standard deviation multipliers for component curves.}
\item{threshold}{Cumulative explained variance threshold in (0, 1].}
\item{prefix}{Component score column prefix.}
\item{fpca}{Native fitted FPCA object.}
\item{n_components}{Number of retained FPCA components or requested variance fraction, as appropriate.}
\item{trajectories}{Native complete common-grid or irregular trajectory set, depending on the diagnostic.}
\item{dimension_weights}{Optional nonnegative spatial-channel weights.}
\item{dimension}{Name of one irregularly sampled dimension.}
\item{registration}{Native registration with original trajectories and reference-to-source warpings.}
\item{representation}{Either "displacement" or "warping".}
}
\value{A matrix, array, data frame, list, native trajectory set, or native FPCA fit according to the selected function. All paths are Python-free.}
\details{The ALR clipping threshold, target component count, registration orientation and finite-observation support must be specified and recorded. Python result dataclass identity and generalized inference are not claimed.}
