\name{etr_evaluate_sparse_mfpca_recovery}
\alias{etr_evaluate_sparse_mfpca_recovery}
\title{Known-truth sparse bivariate MFPCA recovery}
\usage{
etr_evaluate_sparse_mfpca_recovery(result, truth)
}
\arguments{
\item{result}{Source-shaped bivariate fitted sparse MFPCA/PACE result,
with four named covariance blocks, quadrature and score diagnostics.}
\item{truth}{Source-shaped generating truth with positive eigenvalues
and two ordered dimensions.}
}
\value{Source-shaped recovery metrics and provenance including separate
cxx, cxy, cyx and cyy covariance errors and the joint total.}
\description{Compares the four fitted covariance blocks and their joint
sum against truth. Fully retained tied eigenspaces use weighted principal
angles and orthogonal Procrustes score error. Retaining only part of a
tied truth group signals an error.}
