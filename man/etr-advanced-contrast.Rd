\name{etr-advanced-contrast}
\title{Experimental Phase 3 R methods: advanced contrast}
\description{Native R scientific methods and diagnostics under active qualification;
these functions are not cleared for a CRAN release or calibrated inference.}
\alias{etr_bootstrap_group_contrast}
\alias{etr_multilevel_reconstruct}
\alias{etr_multilevel_diagnostics}
\usage{
etr_bootstrap_group_contrast(
  x,
  participant,
  group,
  B = 399L,
  alpha = 0.05,
  seed = 3L
)

etr_multilevel_reconstruct(
  fit,
  n_between = NULL,
  n_within = NULL
)

etr_multilevel_diagnostics(
  fit
)
}
\arguments{
\item{x}{A native trajectory object, sparse collection, numeric sequence, or validated diagnostic according to the function.}
\item{participant}{Participant identifiers by curve, or a metadata-column name.}
\item{group}{Exactly two group labels, each constant within participant.}
\item{B}{Number of participant-level bootstrap draws, at least 39.}
\item{alpha}{Target nominal miscoverage in (0,1); calibration not guaranteed.}
\item{seed}{Deterministic random seed.}
\item{fit}{A fitted native R model result of the expected class.}
\item{n_between}{Number of between-participant components.}
\item{n_within}{Number of within-participant components.}
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
