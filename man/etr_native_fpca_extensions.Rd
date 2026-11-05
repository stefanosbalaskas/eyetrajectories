\name{etr_native_fpca_extensions}
\alias{etr_fit_compositional_fpca}
\alias{etr_reconstruct_compositional_fpca}
\alias{etr_component_similarity_matrix}
\alias{etr_match_fpca_components}
\alias{etr_reconstruction_error_by_curve}
\alias{etr_fpca_reconstruction_curve}
\alias{etr_compare_registered_unregistered_fpca}
\alias{etr_registration_sensitivity_frame}
\alias{etr_summarise_trajectory_set}
\alias{etr_summarise_fpca}
\alias{etr_fpca_reporting_text}
\alias{etr_fpca_eigenvalue_gap_table}
\alias{etr_fpca_eigengap_reporting_text}
\alias{etr_registration_sensitivity_reporting_text}
\alias{etr_functional_mean_band_frame}
\title{Stage 10 native R compositional FPCA and scientific diagnostics}
\description{Python-free functional PCA, reconstruction, component matching, registration sensitivity, eigenvalue gaps and descriptive reporting. Implementations await independent source-equivalence qualification.}
\usage{
etr_fit_compositional_fpca(trajectories, reference_dimension = -1L,
  epsilon = 1e-8, n_components = 0.95, scaling = "none")
etr_reconstruct_compositional_fpca(result, scores = NULL, n_components = NULL)
etr_component_similarity_matrix(reference, candidate, n_components = NULL)
etr_match_fpca_components(reference, candidate, n_components = NULL)
etr_reconstruction_error_by_curve(result, trajectories, n_components = NULL)
etr_fpca_reconstruction_curve(result, trajectories)
etr_compare_registered_unregistered_fpca(registration, n_components = 3L,
  scaling = "none")
etr_registration_sensitivity_frame(result)
etr_summarise_trajectory_set(trajectories)
etr_summarise_fpca(result)
etr_fpca_reporting_text(result, digits = 1L)
etr_fpca_eigenvalue_gap_table(result, relative_gap_threshold = NULL)
etr_fpca_eigengap_reporting_text(result, relative_gap_threshold = NULL, digits = 3L)
etr_registration_sensitivity_reporting_text(result, digits = 2L)
etr_functional_mean_band_frame(result)
}
\arguments{
\item{trajectories}{A native common-grid complete trajectory set, or the fitted original sample for reconstruction diagnostics.}
\item{reference_dimension}{Zero-based Python-style ALR reference index; -1 selects the last dimension.}
\item{epsilon}{Positive probability clipping floor in the compositional log ratio.}
\item{n_components}{Fitted component count; NULL uses all available components. For compositional fitting a variance fraction is also accepted.}
\item{scaling}{Native FPCA channel scaling method.}
\item{result}{A compatible native FPCA, compositional FPCA, registration sensitivity or functional mean-band result.}
\item{scores}{Optional finite replacement FPCA score matrix.}
\item{reference}{Reference native FPCA fit.}
\item{candidate}{Candidate native FPCA fit with same grid and dimensions.}
\item{registration}{Native registered and original trajectories.}
\item{digits}{Requested reporting decimal places, integer from 0 to 15.}
\item{relative_gap_threshold}{Optional pre-specified descriptive near-tie threshold in [0,1).}
}
\value{Numeric array, matrix, component-matching list, diagnostic data frame, reporting text or native compositional FPCA result, according to the function.}
\details{Exact native maximum-weight component matching uses the historical subset dynamic program for up to 12 components and an exact cubic-time Hungarian assignment for larger fitted bases. Both optimize the absolute integrated component similarity; tied optimum permutations need not agree with SciPy tie choices. Diagnostic frames do not supply inferential guarantees. Scientific full-source and 508-export independent contract qualification remain pending.}