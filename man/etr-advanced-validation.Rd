\name{etr-advanced-validation}
\title{Experimental Phase 3 R methods: advanced validation}
\description{Native R scientific methods and diagnostics under active qualification;
these functions are not cleared for a CRAN release or calibrated inference.}
\alias{etr_simulate_group_contrast}
\alias{etr_evaluate_group_contrast_coverage}
\alias{etr_grouped_fpca_crossval}
\usage{
etr_simulate_group_contrast(
  n_subjects = 20L,
  trials_per_subject = 3L,
  n_time = 41L,
  effect_x = 0.4,
  effect_y = -0.2,
  seed = 11L
)

etr_evaluate_group_contrast_coverage(
  simulations = 20L,
  n_subjects = 20L,
  B = 99L,
  alpha = .1,
  seed = 100L
)

etr_grouped_fpca_crossval(
  x,
  outcome,
  participant,
  folds = 5L,
  n_components = 2L,
  seed = 8L
)
}
\arguments{
\item{n_subjects}{Number of independently generated subjects.}
\item{trials_per_subject}{Repeated trials per subject.}
\item{n_time}{Number of common-grid time samples.}
\item{effect_x}{Known treatment effect coefficient for the x channel.}
\item{effect_y}{Known treatment effect coefficient for the y channel.}
\item{seed}{Deterministic random seed.}
\item{simulations}{Independent known-truth Monte Carlo dataset count.}
\item{B}{Number of participant-level bootstrap draws, at least 39.}
\item{alpha}{Target nominal miscoverage in (0,1); calibration not guaranteed.}
\item{x}{A native trajectory object, sparse collection, numeric sequence, or validated diagnostic according to the function.}
\item{outcome}{Finite numeric outcome for each curve.}
\item{participant}{Participant identifiers by curve, or a metadata-column name.}
\item{folds}{Number of participant-disjoint CV folds.}
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
