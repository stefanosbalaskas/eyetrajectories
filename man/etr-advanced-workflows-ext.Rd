\name{etr-advanced-workflows-ext}
\title{Experimental Phase 3 R methods: advanced workflows ext}
\description{Native R scientific methods and diagnostics under active qualification;
these functions are not cleared for a CRAN release or calibrated inference.}
\alias{etr_validate_advanced_workflow}
\alias{etr_run_group_contrast_workflow}
\alias{etr_run_scalar_fpca_workflow}
\alias{etr_run_marginal_sparse_workflow}
\alias{etr_run_functional_mixed_workflow}
\alias{etr_workflow_summary}
\usage{
etr_validate_advanced_workflow(
  x
)

etr_run_group_contrast_workflow(
  x,
  participant,
  group,
  B = 399L,
  alpha = 0.05,
  seed = 3L
)

etr_run_scalar_fpca_workflow(
  x,
  outcome,
  n_components = 2L
)

etr_run_marginal_sparse_workflow(
  channels,
  max_components = 3L,
  fve = 0.95,
  options = list()
)

etr_run_functional_mixed_workflow(
  x,
  participant = NULL,
  method = "REML",
  basis_k = 10L
)

etr_workflow_summary(
  x
)
}
\arguments{
\item{x}{A native trajectory object, sparse collection, numeric sequence, or validated diagnostic according to the function.}
\item{participant}{Participant identifiers by curve, or a metadata-column name.}
\item{group}{Exactly two group labels, each constant within participant.}
\item{B}{Number of participant-level bootstrap draws, at least 39.}
\item{alpha}{Target nominal miscoverage in (0,1); calibration not guaranteed.}
\item{seed}{Deterministic random seed.}
\item{outcome}{Finite numeric outcome for each curve.}
\item{n_components}{Fixed number of native FPCA components.}
\item{channels}{Named list of per-channel sparse collections with identical curve ID ordering.}
\item{max_components}{Maximum sparse PACE principal components.}
\item{fve}{Fraction-of-variance threshold in (0,1].}
\item{options}{Named optional fdapace parameters; locked scientific design parameters cannot be changed.}
\item{method}{Declared estimation, binning, or smoothing method.}
\item{basis_k}{Spline basis dimension for the smooth functional intercept.}
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
