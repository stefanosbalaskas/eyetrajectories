\name{etr-advanced-sparse-diagnostics}
\title{Experimental Phase 3 R methods: advanced sparse diagnostics}
\description{Native R scientific methods and diagnostics under active qualification;
these functions are not cleared for a CRAN release or calibrated inference.}
\alias{etr_sparse_design_diagnostics}
\alias{etr_sparse_pace_at_observed}
\alias{etr_fit_marginal_sparse_pace}
\alias{etr_marginal_sparse_scores}
\usage{
etr_sparse_design_diagnostics(
  x,
  bins = 10L
)

etr_sparse_pace_at_observed(
  fit,
  x
)

etr_fit_marginal_sparse_pace(
  channels,
  max_components = 3L,
  fve = 0.95,
  options = list()
)

etr_marginal_sparse_scores(
  fit
)
}
\arguments{
\item{x}{A native trajectory object, sparse collection, numeric sequence, or validated diagnostic according to the function.}
\item{bins}{Number of support bins or discrete-state bins, according to the function.}
\item{fit}{A fitted native R model result of the expected class.}
\item{channels}{Named list of per-channel sparse collections with identical curve ID ordering.}
\item{max_components}{Maximum sparse PACE principal components.}
\item{fve}{Fraction-of-variance threshold in (0,1].}
\item{options}{Named optional fdapace parameters; locked scientific design parameters cannot be changed.}
}
\details{
These methods have explicitly limited scientific scope.
Sparse estimation uses fdapace when requested; functional mixed models
use optional refund. Marginal sparse fits do not estimate joint
cross-channel covariance. Cluster bootstrap resamples participants, not
trials. Transfer entropy describes discrete predictive information,
not causality, and its diagnostic p-values are not generally calibrated.
See docs/phase3-expansion-methods.md for independent simulation contracts.
}
\value{A typed native model, diagnostic, Monte Carlo audit, or base R
plot; returned components are documented in the Phase 3 methods article.}
