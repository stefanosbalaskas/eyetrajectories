\name{etr_export_python_portable_result}
\alias{etr_export_python_portable_result}
\title{Export selected native R scientific records in frozen Python 1.2 portable format}
\usage{
etr_export_python_portable_result(result, directory,
    include_environment = FALSE, overwrite = FALSE)
}
\arguments{
\item{result}{Native common-grid or irregular trajectory collection, dense FPCA/MFPCA scientific fit, compositional FPCA, strict 29-field paired sparse-MFPCA fit, or fixed-bandwidth paired sparse-MFPCA W2 workflow with canonical frozen Python 1.2 scientific fields.}
\item{directory}{New or empty output directory for \code{arrays.npz} and \code{manifest.json}.}
\item{include_environment}{Must be FALSE. An R interpreter cannot honestly provide a Python interpreter environment capture.}
\item{overwrite}{Must be FALSE. Scientific evidence is not destructively overwritten.}
}
\value{Output directory, invisibly.}
\description{Writes NumPy-compatible scientific arrays, typed JSON dataclass field envelopes, metadata, diagnostics, provenance, units, a SHA256 archive digest, and an explicit R-native source-package version. Paired sparse-MFPCA serialization requires the genuine native joint covariance/PACE estimator; fixed-bandwidth W2 workflows may not request optional audited selector, score uncertainty, or observation diagnostics in this initial portable domain. The Python 1.2 \code{load_portable_result} reader can audit the output without reconstructing opaque fitted objects. It does not claim identical Python runtime objects, Python environment capture, arbitrary dataclass support, or independent scientific certification.}
