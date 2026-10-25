\name{advanced-phase3}
\title{Experimental advanced functional trajectory methods in native R}
\description{Selective experimental R implementations for univariate sparse PACE
through the optional fdapace R package, descriptive multilevel FPCA,
participant-cluster bootstrap functional mean bands, discrete transfer
entropy, and independent known-truth simulation and workflows.}
\alias{etr_sparse_curves}
\alias{etr_fit_sparse_pace}
\alias{etr_sparse_pace_scores}
\alias{etr_sparse_pace_fitted}
\alias{etr_fit_multilevel_fpca}
\alias{etr_multilevel_scores}
\alias{etr_multilevel_variance}
\alias{etr_bootstrap_mean_band}
\alias{etr_simulate_hierarchical}
\alias{etr_evaluate_mean_band_coverage}
\alias{etr_transfer_entropy}
\alias{etr_transfer_entropy_shift_test}
\alias{etr_transfer_entropy_directions}
\alias{etr_simulate_sparse_known_truth}
\alias{etr_evaluate_sparse_pace_recovery}
\alias{etr_evaluate_multilevel_recovery}
\alias{etr_run_sparse_pace_workflow}
\alias{etr_run_multilevel_workflow}
\alias{etr_run_mean_band_workflow}
\alias{etr_run_transfer_entropy_workflow}
\usage{
etr_sparse_curves(times, values, curve_ids = NULL, time_unit = "unknown")

etr_fit_sparse_pace(x, max_components = 3L, fve = 0.95, options = list())

etr_sparse_pace_scores(fit)

etr_sparse_pace_fitted(fit)

etr_fit_multilevel_fpca(x, participant, n_between = 2L, n_within = 2L)

etr_multilevel_scores(fit)

etr_multilevel_variance(fit)

etr_bootstrap_mean_band(x, participant, B = 399L, alpha = 0.05, seed = 1L)

etr_simulate_hierarchical(n_subjects = 20L, trials_per_subject = 3L, n_time = 41L, subject_sd = 0.35, trial_sd = 0.15, noise_sd = 0.05, seed = 7L)

etr_evaluate_mean_band_coverage(simulations = 20L, B = 99L, alpha = 0.10, n_subjects = 20L, seed = 100L)

etr_transfer_entropy(source, target, k_target = 1L, k_source = 1L, lag = 1L, conditioning = NULL)

etr_transfer_entropy_shift_test(source, target, k_target = 1L, k_source = 1L, lag = 1L, conditioning = NULL, n_surrogates = 99L, seed = 1L)

etr_transfer_entropy_directions(source, target, k_target = 1L, k_source = 1L, lag = 1L)

etr_simulate_sparse_known_truth(n_subjects = 45L, min_observations = 5L, max_observations = 10L, noise_sd = 0.10, score_sd = 0.60, seed = 22L)

etr_evaluate_sparse_pace_recovery(simulations = 5L, n_subjects = 45L, seed = 100L, max_components = 2L)

etr_evaluate_multilevel_recovery(simulations = 10L, n_subjects = 20L, seed = 200L)

etr_run_sparse_pace_workflow(x, max_components = 3L, fve = 0.95, options = list())

etr_run_multilevel_workflow(x, participant, n_between = 2L, n_within = 2L)

etr_run_mean_band_workflow(x, participant, B = 399L, alpha = 0.05, seed = 1L)

etr_run_transfer_entropy_workflow(source, target, k_target = 1L, k_source = 1L, lag = 1L, conditioning = NULL, n_surrogates = 99L, seed = 1L)
}
\arguments{
\item{times}{A list of strictly increasing, finite observation-time vectors.}
\item{values}{A matching list of complete numeric observation vectors.}
\item{curve_ids}{Optional unique curve identifiers.}
\item{time_unit}{Declared observation time unit.}
\item{x}{A native trajectory collection, or a sparse collection for PACE.}
\item{max_components}{Maximum positive integer number of sparse components.}
\item{fve}{Fraction-of-variance threshold in (0,1].}
\item{options}{Optional named fdapace options; required design settings are locked.}
\item{fit}{A native advanced fit object of the appropriate class.}
\item{participant}{Participant labels per curve, or a metadata column name.}
\item{n_between}{Retained between-participant FPCA component count.}
\item{n_within}{Retained within-participant FPCA component count.}
\item{B}{Number of cluster bootstrap draws, at least 39.}
\item{alpha}{Target miscoverage level strictly in (0,1); calibration is not established.}
\item{seed}{Integer random seed. The global R random state is restored.}
\item{n_subjects}{Number of independent subjects.}
\item{trials_per_subject}{Repeated trials per subject.}
\item{n_time}{Common-grid time points in the synthetic generator.}
\item{subject_sd}{Standard deviation of participant effects.}
\item{trial_sd}{Standard deviation of trial-specific effects.}
\item{noise_sd}{Independent observation-noise standard deviation.}
\item{simulations}{Number of independently generated Monte Carlo datasets.}
\item{source}{Pre-discretized driving-state vector.}
\item{target}{Pre-discretized receiving-state vector of the same length.}
\item{k_target}{Number of historical target states.}
\item{k_source}{Number of historical source states.}
\item{lag}{Declared source delay in samples, at least 1.}
\item{conditioning}{Optional aligned discretized conditioning-state vector.}
\item{n_surrogates}{Number of circular-shift surrogate realizations.}
\item{min_observations}{Minimum observed samples in each simulated sparse curve.}
\item{max_observations}{Maximum observed samples in each simulated sparse curve.}
\item{score_sd}{Standard deviation of latent functional scores.}
}
\details{
These functions are experimental and not independently qualified.
The sparse PACE estimator delegates to fdapace; the native R package
does not reimplement the PACE smoother. The two-level FPCA separates
participant means from within-participant residuals and is descriptive,
not a REML functional mixed-effects model.

The cluster mean-band resampling unit is the independent participant.
The max-studentized simultaneous band has no demonstrated nominal
coverage under general designs. The transfer-entropy estimator uses
plug-in discrete conditional mutual information; circular-shift results
are descriptive and do not establish causal direction or universally
valid randomization p-values. All synthetic methods use known-truth
data distinct from the estimator implementation.

The methods are documented further in docs/phase3-scientific-qualification.md.
}
\value{
Depending on the function, an etr_sparse_curves or etr_sparse_pace
object, a two-level etr_multilevel_fpca object, an etr_mean_band object,
a list of transfer-entropy estimates and diagnostics, an independent
simulation result, or an auditable etr_advanced_workflow object.
}
\seealso{\code{\link{etr_fit_fpca}}, \code{\link{etr_trajectory_set}}}
