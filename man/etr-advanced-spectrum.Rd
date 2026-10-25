\name{etr-advanced-spectrum}
\title{Experimental FPCA eigenvalue bootstrap and analytic variance oracle}
\alias{etr_bootstrap_fpca_spectrum}
\alias{etr_analytic_between_variance}
\alias{etr_evaluate_between_variance}
\description{Participant-resampled FPCA eigenvalue uncertainty and
known-truth analytic variance audit for hierarchical functional curves.}
\usage{
etr_bootstrap_fpca_spectrum(
  x, participant, n_components = 2L, B = 199L,
  alpha = 0.10, seed = 1L
)

etr_analytic_between_variance(
  time, trials_per_subject, subject_sd = 0.35,
  trial_sd = 0.15, noise_sd = 0.05
)

etr_evaluate_between_variance(
  simulations = 20L, n_subjects = 24L,
  trials_per_subject = 3L, n_time = 41L,
  subject_sd = 0.35, trial_sd = 0.15,
  noise_sd = 0.05, seed = 123L
)
}
\arguments{
\item{x}{Complete common-grid trajectory collection.}
\item{participant}{Participant IDs per curve, or a metadata column name.}
\item{n_components}{Number of FPCA components to retain.}
\item{B}{Cluster bootstrap replicates (39-5000).}
\item{alpha}{Nominal error probability, not calibrated.}
\item{seed}{Deterministic random seed.}
\item{time}{Strictly increasing time grid.}
\item{trials_per_subject}{Number of repeated trials per participant.}
\item{subject_sd}{Participant random-effect standard deviation.}
\item{trial_sd}{Trial random-effect standard deviation.}
\item{noise_sd}{Independent pointwise measurement-noise standard deviation.}
\item{simulations}{Number of independently generated datasets.}
\item{n_subjects}{Number of independent participants per simulation.}
\item{n_time}{Number of common-grid time samples.}
}
\details{
The eigenvalue bootstrap refits the full dense FPCA after resampling
participant-average curves. Bootstrap replicate failures are retained.
The between-participant variance oracle is derived analytically from
the independent hierarchical generator's sine/cosine random effects
and observation noise. Estimator agreement with an analytic generating
target is not a general confidence-band coverage guarantee.
}
\value{A list with eigenvalue intervals and failure-inclusive replicates;
an analytic scalar integrated trace; or a Monte Carlo bias/SE audit.}
