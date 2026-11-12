\name{etr_export_workflow_bundle}
\alias{etr_export_workflow_bundle}
\title{Export a native workflow audit and optional frozen Python 1.2 scientific bundle}
\usage{
etr_export_workflow_bundle(result, directory,
    overwrite = FALSE, format = c("native_r", "python_1_2"))
}
\arguments{
\item{result}{Native scientific workflow. Python format supports measured dense FPCA and strict fixed-bandwidth paired sparse-MFPCA W2 source-scientific records.}
\item{directory}{New output directory for audit files, typed portable result and checksums.}
\item{overwrite}{Must be FALSE; never delete previous scientific audit files.}
\item{format}{\code{"native_r"} writes RDS; \code{"python_1_2"} writes a portable Python 1.2 schema JSON+NPZ result, source config/decisions/steps/provenance, reports and tables with SHA256SUMS.}
}
\value{Exported bundle directory, invisibly.}
\description{Writes an auditable native workflow package. In Python 1.2 format, the portable scientific payload is compatible with the Python portable reader while the environment is explicitly recorded as R, never falsely represented as Python. The paired sparse-MFPCA portable workflow domain currently requires a real native covariance/PACE fit, one genuinely measured fit step and no optional selection, score-uncertainty or observation-process records. Source-exact runtime objects, arbitrary workflow types, overwrite semantics and independent source-contract certification are outside the current scope.}
