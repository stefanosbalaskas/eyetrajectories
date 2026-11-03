\name{etr_simulate_functional_process}
\alias{etr_simulate_functional_process}
\title{Simulate dense or irregular Gaussian functional trajectories with auditable latent truth}
\description{
Native R simulation of bounded dense and irregular functional domains of frozen
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
\item{observation_design}{\code{"dense"} uses the exact common truth grid;
\code{"irregular"} returns native curve-specific schedules with no interpolation.}
\item{observation_times}{For irregular simulation, an optional list
containing exactly one finite, strictly increasing numeric time vector per
curve, each with at least two samples within the truth-grid domain.}
\item{samples_per_curve}{For irregular simulation only: a positive
integer count (at least two) or a two-integer minimum/maximum range.
Provide this or \code{observation_times}, not both. Both are NULL for dense.}
\item{irregular_time_design}{Native generated irregular schedules use
\code{"uniform"} (interior uniform 0.01 to 0.99),
\code{"center_clustered"} (0.01 + 0.98 times Beta(4,4)), or
\code{"boundary_poor"} (interior uniform 0.15 to 0.85).
Endpoints are retained; generated times are sorted.}
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
MCAR masks each observation time independently; block masks one
contiguous interval of size floor(fraction times n_samples), with at least
one masked sample when fraction is positive. All channels share each
curve's mask. Dense outputs retain NA; irregular outputs remove masked
samples from the published schedule, retaining complete pre-missing truth.}
\item{phase_variation}{NULL or a source power-phase mapping
\code{list(kind="power",sd=s)} with finite nonnegative
log-exponent standard deviation. Independently for each curve,
the exponent is \code{exp(Normal(0,s))}; the latent mean and
generating modes are evaluated directly at the transformed time,
not interpolated or relabeled as new observation timestamps.}
\item{score_distribution}{Only \code{"normal"} is supported.}
\item{score_df}{Reserved for the unsupported Student-t score domain.}
\item{orthonormal_tolerance}{Positive finite numerical tolerance for
source quadrature orthonormality.}
\item{random_state}{Native R random seed; not NumPy PCG64 equivalent.}
\item{source_draws}{Optional captured source curve, participant, trial
and measurement-noise draws for exact paired Python/R value replay.
When supplied, all four source fields must match declared geometry.
Dense \code{measurement_noise} is a numeric curve-by-time-by-channel
array; irregular \code{measurement_noise} is a list of one
time-by-channel matrix per pre-missing curve. With declared missingness,
an optional \code{missingness_mask} field contains one logical vector
per curve; with declared power-phase variation, an optional
\code{phase_exponents} field contains one finite positive numeric exponent
per curve, allowing exact frozen-Python realized-mask and
realized-warp replay without matching random-number streams.}
}
\value{
An \code{etr_functional_simulation_result} with
\code{observations} as a native common-grid \code{etr_trajectory_set}
or curve-specific \code{etr_irregular_trajectory_set}, and \code{truth}
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
Irregular observation times are evaluated by the generating mean and
eigenfunction callables directly, without interpolating the truth grid.
Irregular missing samples are removed from the output curve/time lists;
the full pre-missing arrays and logical masks remain in truth.
Power-phase warps are available on both dense and irregular trajectories.
Raw observation times remain unwarped; the complete-grid
`truth$phase_warps_on_truth_grid` and the original/warped pre-
and post-missing schedules are retained separately. The
`truth$latent_on_truth_grid` and observed latent signals are
evaluated at the warped time by the generating functions.
Student-t scores, complete Python input/output dataclass types,
NumPy PCG64 streams and independent full scientific
certification remain unresolved.
}
