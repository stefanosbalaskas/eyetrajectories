\name{etr-advanced-plots}
\title{Experimental Phase 3 R methods: advanced plots}
\description{Native R scientific methods and diagnostics under active qualification;
these functions are not cleared for a CRAN release or calibrated inference.}
\alias{etr_plot_functional_band}
\alias{etr_plot_sparse_support}
\alias{etr_plot_transfer_surrogates}
\usage{
etr_plot_functional_band(
  fit,
  dimension = 1L,
  interval = c("simultaneous", "pointwise"),
  ...
)

etr_plot_sparse_support(
  diagnostic,
  ...
)

etr_plot_transfer_surrogates(
  x,
  ...
)
}
\arguments{
\item{fit}{A fitted native R model result of the expected class.}
\item{dimension}{One-based functional channel index.}
\item{interval}{Whether to display pointwise or simultaneous exploratory bands.}
\item{...}{Additional base-R graphics parameters.}
\item{diagnostic}{Observed sparse-curve support diagnostic result.}
\item{x}{A native trajectory object, sparse collection, numeric sequence, or validated diagnostic according to the function.}
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
