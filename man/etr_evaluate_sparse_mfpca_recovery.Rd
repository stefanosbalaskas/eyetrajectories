\name{etr_evaluate_sparse_mfpca_recovery}
\alias{etr_evaluate_sparse_mfpca_recovery}
\title{Known-truth one-component sparse bivariate MFPCA recovery}
\usage{
etr_evaluate_sparse_mfpca_recovery(result, truth)
}
\arguments{
\item{result}{Source-shaped bivariate fitted sparse MFPCA/PACE result,
with four named covariance blocks, quadrature and score diagnostics.}
\item{truth}{Source-shaped frozen generating truth with exactly one
positive eigenvalue and two named dimensions.}
}
\value{Source-shaped recovery metrics and provenance including separate
cxx, cxy, cyx and cyy covariance errors and the joint total.}
\description{An explicitly bounded one-component source numerical audit.
It does not refit sparse MFPCA, infer tied eigenvalue subspaces or certify
Python full-domain class and error behavior.}
