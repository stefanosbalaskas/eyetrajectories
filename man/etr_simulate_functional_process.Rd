\name{etr_simulate_functional_process}
\alias{etr_simulate_functional_process}
\title{Simulate dense Gaussian functional trajectories with auditable latent truth}
\description{
Native R simulation of a bounded finite complete-grid subdomain of frozen
eyetrajectoriespy 1.2.0 \code{simulate_functional_process}.
Declares curve, participant and trial random scores independently,
retains latent trajectories and measurement-noise realizations, and
supports either independent channel noise SDs or a symmetric
positive-semidefinite cross-channel covariance matrix. No Python is
required for native simulation.
}
\usage{
etr_simulate_functional_process(
  mean, eigenfunctions, eigenvalues, truth_grid, n_participants,
  trials_per_participant = 1L, dimension_names = "value",
  coordinate_system = "unknown", time_unit = "normalized",
  observation_design = "dense", observation_times = NULL,
  samples_per_curve = NULL, irregular_time_design = "uniform",
  participant_eigenvalues = NULL, trial_eigenvalues = NULL,
  measurement_noise_sd = 0, measurement_noise_covariance = NULL,
  missingness = NULL, phase_variation = NULL,
  score_distribution = "normal", score_df = 5,
  orthonormal_tolerance = 1e-6, random_state = 42L,
  source_draws = NULL
)
}
\arguments{
\item{mean}{Callable returning a source-compatible function of time.}
\item{eigenfunctions}{List of source component evaluation callables.}
\item{eigenvalues}{Positive, nonincreasing component variances.}
\item{truth_grid}{Finite, strictly increasing common grid of at least three times.}
\item{n_participants}{Number of independent participants.}
\item{trials_per_participant}{Number of trials per participant.}
\item{dimension_names}{Unique functional channel names.}
\item{coordinate_system,time_unit}{Explicit trajectory coordinate and time units.}
\item{observation_design}{Currently only \code{"dense"} is supported.}
\item{observation_times,samples_per_curve}{Must be NULL in the dense subset.}
\item{irregular_time_design}{Reserved for future irregular scheduling support.}
\item{participant_eigenvalues,trial_eigenvalues}{Optional nonnegative
participant-level and trial-level component variances.}
\item{measurement_noise_sd}{Nonnegative scalar or one independent
measurement-noise standard deviation per channel. Must be zero when
\code{measurement_noise_covariance} is supplied.}
\item{measurement_noise_covariance}{Optional finite symmetric
positive-semidefinite channel-by-channel covariance. If supplied,
the simulator draws correlated Gaussian noise using an eigenvalue-based
symmetric square root. The declared matrix is preserved in source truth
and provenance. Cannot be combined with positive noise SD.}
\item{missingness}{Optional named mapping \code{list(kind="mcar",probability=p)}
or \code{list(kind="block",fraction=f)} with finite p/f in [0,1).
MCAR masks each common-grid sample independently; block masks one
contiguous interval of size floor(fraction times n_time), with at least
one masked sample when fraction is positive. All channels share each
curve's mask, represented as NA in observations but retained in truth.}
\item{phase_variation}{Must be NULL in the supported dense subset.}
\item{score_distribution}{Only \code{"normal"} is supported.}
\item{score_df}{Reserved for the unsupported Student-t score domain.}
\item{orthonormal_tolerance}{Positive finite numerical tolerance for
source quadrature orthonormality.}
\item{random_state}{Native R random seed; not NumPy PCG64 equivalent.}
\item{source_draws}{Optional captured source curve, participant, trial
and measurement-noise draws for exact paired Python/R value replay.
When supplied, all four arrays must have matching declared geometry.
When missingness is declared, an optional fifth source field
\code{missingness_mask} may contain a list of one logical vector per
curve to replay the frozen Python truth masks without matching RNG streams.}
}
\value{
An \code{etr_functional_simulation_result} with
\code{observations} as a native trajectory set and \code{truth}
containing latent values, separated scores, Gaussian noise, named
covariance, metadata, and provenance.
}
\details{
The preexisting independent Gaussian channel SD path retains its
native sampling behavior. A supplied PSD covariance activates
correlated cross-channel Gaussian sampling. Native base-R and NumPy
random-number streams are different; source comparisons require
paired retained draws and must not claim identical raw draws for a
common seed. Dense MCAR and contiguous-block missingness are now available.
The returned observation values use the native missing-data sentinel NA
at masked samples, while \code{truth$observed_pre_missing} retains
the complete noisy signal and \code{truth$missingness_mask} retains
one logical vector per curve. No silent zero-imputation occurs.
Irregular, phase and Student-t simulation, complete Python input/output
types and independent full scientific certification remain unresolved.
}
