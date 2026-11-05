\name{etr_evaluate_fpca_recovery}
\alias{etr_evaluate_fpca_recovery}
\title{Known-truth one- or multi-component FPCA recovery on the exact grid}
\usage{
etr_evaluate_fpca_recovery(result, truth)
}
\arguments{
\item{result}{Explicit source-shaped FPCA result with unscaled functional
components, finite score matrix, positive quadrature weights and an exact
source truth grid.}
\item{truth}{Source-shaped simulator truth containing at least as many
positive generating components as the number of fitted modes; source
scores, latent curves and exact time/dimension geometry must agree.}
}
\value{Native scientific assessment with ordered source recovery metrics,
including weighted mean and covariance integrated squared errors,
component-matched eigenvalue errors and signed score metrics, weighted
principal cosines/angles and mean latent reconstruction error.
\code{provenance$matched_truth_components} contains the zero-based
assignment of each fitted mode to one true mode; the companion
\code{alignment_signs} gives the chosen sign orientation.}
\description{Pure native R counterpart for a bounded finite complete-grid
domain of frozen Python 1.2 \code{evaluate_fpca_recovery}. One-component
cases retain their previously qualified implementation. Multi-component
cases use exact rectangular Hungarian alignment followed by signed
score comparisons and QR/SVD weighted subspace geometry. No estimator,
interpolation, smoothing, automatic scaling or Python execution occurs.}
\details{The dense population covariance requires quadratic storage in
time times dimension; the multi-component path explicitly bounds the
flattened functional coordinate count to 2000. Constant score columns
are rejected rather than silently returning nonfinite correlations.
Full-domain Python input and exception behavior, scientific type schemas
and independently reviewed exact source certification remain open.
See \code{docs/native-multicomponent-fpca-recovery-source.md}.}
