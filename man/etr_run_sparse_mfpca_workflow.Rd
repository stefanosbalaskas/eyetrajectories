\name{etr_run_sparse_mfpca_workflow}
\alias{etr_run_sparse_mfpca_workflow}
\title{Native sparse multivariate FPCA workflow with optional Python W2 scientific contract}
\usage{
etr_run_sparse_mfpca_workflow(trajectories, config,
    observation_process = NULL, strict_source_record = FALSE)
}
\arguments{
\item{trajectories}{Native irregular two-coordinate trajectory set with paired source observations.}
\item{config}{Named configuration with explicit backend. For strict source mode use \code{backend="native_covariance"}, \code{n_components}, \code{evaluation_grid}, \code{measurement_error}, and fixed \code{mean_bandwidth}/\code{covariance_bandwidth} or \code{bandwidth_selection}; optional \code{score_uncertainty}, \code{observation_diagnostics} and empty \code{preprocessing}. The separate fdapace marginal-score alternative is not Python source parity.}
\item{observation_process}{Optional explicit candidate-sample denominator for observation-process diagnostics.}
\item{strict_source_record}{When TRUE, emit the 12-field Python 1.2 W2 source-scientific workflow analogue with 22 ordered configuration fields, seven decisions, four provenance fields and genuinely measured R steps. Reject R-only explicit selector fold assignments and fdapace, and require a declared NumPy group sort profile for group bandwidth selection. No Python runtime type identity is claimed. Default FALSE retains native R diagnostic records.}
}
\value{A native sparse MFPCA workflow record; if strict, a canonical source-scientific result including the native covariance/PACE fit, optional bandwidth selection, score uncertainty, observation diagnostics, steps, decisions, reports and tables.}
\description{Performs paired sparse multivariate covariance/PACE in native R without a Python dependency. In the strict source-scientific representation, Python W2 schema and scientific numerical quantities are separated from Python dataclass/Matplotlib/runtime identity. Exact source parity and independent certification require a passing frozen Python 1.2 differential run.}
