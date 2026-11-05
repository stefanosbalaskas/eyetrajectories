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
  n_components = NULL,
  family = "gaussian",
  covariates = NULL,
  python_boundary_mode = FALSE
)

etr_predict_scalar_on_fpca(
  fit,
  x,
  covariates = NULL
)
}
\arguments{
\item{x}{A native trajectory object, sparse collection, numeric sequence, or validated diagnostic according to the function.}
\item{participant}{Participant identifiers by curve, or a metadata-column name.}
\item{method}{Declared estimation, binning, or smoothing method.}
\item{basis_k}{Spline basis dimension for the smooth functional intercept.}
\item{fit}{A fitted native R model result of the expected class.}
\item{outcome}{Finite numeric outcome for each curve.}
\item{n_components}{Fixed number of native FPCA components. In Python source mode, Boolean TRUE may select one score, while floating-point slice indices are deliberately disallowed.}
\item{family}{Gaussian linear or binomial logistic family. The binomial source analogue requires explicit Python source-compatibility mode.}
\item{covariates}{Optional curve-aligned finite numeric data.frame. Accepted only in explicit source mode and required for external predictions from a model fitted with covariates.}
\item{python_boundary_mode}{Logical, FALSE preserves the previous Gaussian-only native fit. TRUE enables the bounded Python 1.2 Gaussian/binomial and covariate source contract without invoking Python or certifying whole-domain equivalence.}
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
