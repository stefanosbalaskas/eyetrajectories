\name{etr-advanced-functional-regression}
\title{Experimental Phase 3 R methods: advanced functional regression}
\description{Native R scientific methods and diagnostics under active qualification;
these functions are not cleared for a CRAN release or calibrated inference.}
\alias{etr_fit_functional_mixed}
\alias{etr_functional_mixed_fitted}
\alias{etr_fit_scalar_on_fpca}
\alias{etr_predict_scalar_on_fpca}
\usage{
etr_fit_functional_mixed(
  x,
  participant = NULL,
  method = "REML",
  basis_k = 10L
)

etr_functional_mixed_fitted(
  fit
)

etr_fit_scalar_on_fpca(
  fit,
  outcome,
  n_components = NULL
)

etr_predict_scalar_on_fpca(
  fit,
  x
)
}
\arguments{
\item{x}{A native trajectory object, sparse collection, numeric sequence, or validated diagnostic according to the function.}
\item{participant}{Participant identifiers by curve, or a metadata-column name.}
\item{method}{Declared estimation, binning, or smoothing method.}
\item{basis_k}{Spline basis dimension for the smooth functional intercept.}
\item{fit}{A fitted native R model result of the expected class.}
\item{outcome}{Finite numeric outcome for each curve.}
\item{n_components}{Fixed number of native FPCA components.}
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
