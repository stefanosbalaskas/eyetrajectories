\name{native-scientific-design-contracts}
\alias{etr_workflow_config}
\alias{etr_preprocessing_step_config}
\alias{etr_preprocessing_plan}
\alias{etr_workflow_config_to_dict}
\alias{etr_functional_simulation_scenario}
\alias{etr_functional_simulation_scenario_frame}
\alias{etr_expand_functional_simulation_scenarios}
\alias{etr_functional_recovery_qualification_scenarios}
\title{Explicit native workflow and functional simulation design contracts}
\description{
Python-free native R design declarations, scientific decision provenance and
source-oriented audit tables. These functions create design objects; they do not
execute a scientific estimator, run a Monte Carlo simulation, select a model,
or certify parity against the Python package.
}
\usage{
etr_workflow_config(fields = list())
etr_preprocessing_step_config(function_name, parameters = list(), scientific_effect)
etr_preprocessing_plan(steps = list())
etr_workflow_config_to_dict(config)
etr_functional_simulation_scenario(
  name, truth_grid, eigenvalues, n_participants,
  trials_per_participant = 1L, dimension_names = "value",
  coordinate_system = "unknown", time_unit = "normalized",
  observation_design = "dense", samples_per_curve = NULL,
  irregular_time_design = "uniform", participant_eigenvalues = NULL,
  trial_eigenvalues = NULL, measurement_noise_sd = 0,
  measurement_noise_covariance = NULL, missingness = NULL,
  phase_variation = NULL, score_distribution = "normal", score_df = 5,
  orthonormal_tolerance = 1e-6, replicates = 1L,
  seed_start = 42L, labels = list()
)
etr_functional_simulation_scenario_frame(scenarios)
etr_expand_functional_simulation_scenarios(
  base, factors, seed_policy = c("shared", "disjoint")
)
etr_functional_recovery_qualification_scenarios(
  replicates = 3L, seed_start = 202800L
)
}
\arguments{
\item{fields}{Named JSON-compatible native workflow configuration.}
\item{function_name}{Nonempty explicitly declared preprocessing operation.}
\item{parameters}{Named JSON-compatible preprocessing arguments.}
\item{scientific_effect}{Nonempty scientific effect description.}
\item{steps}{Ordered list of explicitly declared preprocessing steps.}
\item{config}{Native workflow S3 configuration, step or plan.}
\item{name}{Scenario identifier.}
\item{truth_grid}{Strictly increasing finite grid with at least three values.}
\item{eigenvalues}{Positive nonincreasing component variances.}
\item{n_participants}{Positive number of independent participants.}
\item{trials_per_participant}{Number of repeated curves per participant.}
\item{dimension_names}{Unique native channel names.}
\item{coordinate_system}{Declared trajectory coordinate system.}
\item{time_unit}{Declared time-unit label.}
\item{observation_design}{Dense or irregular source design.}
\item{samples_per_curve}{Irregular sample count, or minimum/maximum count.}
\item{irregular_time_design}{Declared irregular sampling process.}
\item{participant_eigenvalues}{Nonnegative hierarchical participant variances.}
\item{trial_eigenvalues}{Nonnegative hierarchical trial variances.}
\item{measurement_noise_sd}{Finite nonnegative scalar or vector SD.}
\item{measurement_noise_covariance}{Unsupported covariance specification; fails closed in this native subset.}
\item{missingness}{Explicit JSON-compatible missing-data mechanism.}
\item{phase_variation}{Explicit JSON-compatible phase-variation mechanism.}
\item{score_distribution}{Normal or Student-t score source.}
\item{score_df}{Student-t degrees of freedom; must exceed two for Student-t.}
\item{orthonormal_tolerance}{Positive orthonormality tolerance.}
\item{replicates}{Positive number of declared simulation replicates.}
\item{seed_start}{Initial integer seed for the declared replicate design.}
\item{labels}{Named JSON-compatible provenance labels.}
\item{scenarios}{Ordered list of native simulation scenario records.}
\item{base}{One native scenario used for explicit factor expansion.}
\item{factors}{Named nonempty list of supported scalar factor levels.}
\item{seed_policy}{Shared replicate seeds or disjoint scenario blocks.}
}
\value{
\code{etr_workflow_config()}, \code{etr_preprocessing_step_config()} and
\code{etr_preprocessing_plan()} return native S3 configuration records.
\code{etr_workflow_config_to_dict()} returns an R list.
\code{etr_functional_simulation_scenario()} returns a native S3 scenario.
\code{etr_functional_simulation_scenario_frame()} returns a data frame.
The two expansion/catalogue functions return ordered lists of native scenarios.
}
\details{
The reference source is published \code{eyetrajectoriespy} 1.2.0 at commit
\code{c1cd95ad718327550f7e55393ff38582872f7a94}. Source classes,
Python dataclass identity, all accepted input coercions, stochastic RNG
identity, nested JSON serialization, and every invalid-domain boundary are
not qualified as fully equivalent. Consult \code{etr_native_parity_catalog()}
and \code{etr_native_source_contract_review_queue()} for source-contract gaps.
An empty preprocessing plan performs no implicit scientific operation.
The four recovery qualification scenarios declare source-data-generating
conditions only; they do not automatically execute any test or calibrate
coverage.
}
\keyword{models}
