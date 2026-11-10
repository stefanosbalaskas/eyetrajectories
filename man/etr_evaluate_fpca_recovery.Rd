\name{etr_evaluate_fpca_recovery}
\alias{etr_evaluate_fpca_recovery}
\title{Known-truth one- or multi-component FPCA recovery on the exact grid}
\usage{
etr_evaluate_fpca_recovery(result, truth)
}
\arguments{
\item{result}{Explicit source-shaped FPCA result with unscaled functional
components, a curve-by-mode score matrix, positive quadrature weights and an exact
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
\description{Evaluates the frozen Python 1.2 recovery estimands using a
native fit and the generating truth on the same grid. Weighted assignment
matches modes before signed score comparisons and principal angles.}
\details{Covariance differences are evaluated in column blocks to bound
memory. Score comparisons use finite paired values and reconstruction
error uses finite whole curves. A constant score column with enough finite
pairs to calculate correlation signals an error.}
