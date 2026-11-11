\name{etr_run_sparse_multilevel_workflow}
\alias{etr_run_sparse_multilevel_workflow}
\title{Native sparse multilevel workflow with optional frozen Python W2 scientific record}
\usage{
etr_run_sparse_multilevel_workflow(trajectories, config,
    observation_process = NULL, strict_source_record = FALSE)
}
\arguments{
\item{trajectories}{Native irregular trajectory collection with participant grouping metadata.}
\item{config}{Explicit named workflow configuration. \code{backend="native_covariance"} retains the native sparse hierarchical covariance and joint BLUP model; the alternative \code{explicit_linear_interpolation_dense_multilevel} changes the estimand and is never accepted in strict source mode.}
\item{observation_process}{Optional candidate-sample observation process supplied with explicit diagnostic configuration.}
\item{strict_source_record}{If TRUE, emit the ten canonical frozen Python 1.2 multilevel W2 source-scientific fields, 30 ordered configuration entries, eight scientific decisions, five provenance keys, and measured workflow steps. Python dataclass or exception identity is not implied.}
}
\value{A native R workflow including the real sparse multilevel fit, scientific decisions, provenance, reports, participant/trial scores, and score diagnostics. Strict source mode retains the Python W2 scientific field layout.}
\description{Fits participant and trial covariance components from irregular observations without raw interpolation. The R-native hierarchical BLUP fit is not a Python dataclass. Source-scientific parity remains provisional pending frozen Python 1.2 differential tests and independent review.}
