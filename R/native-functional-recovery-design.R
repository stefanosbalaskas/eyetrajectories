# Native descriptive qualification scenario declarations, not fitted models.
# Source: eyetrajectoriespy 1.2.0, recovery_scenarios.py pinned at
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Generates designs only; source statistical thresholds are not certified.

.etr_recovery_design_labels <- function(target,description) {
  list(matrix_role="qualification",scientific_target=target,
    description=description,automatic_thresholds=TRUE)
}

#' Frozen Python 1.2 functional recovery qualification designs
#' @param replicates Positive whole number of Monte Carlo replicates.
#' @param seed_start Base integer seed. Later scenarios use +100, +200, +300.
#' @return Ordered list of four native source-aligned S3 scenario designs.
#'   No simulation, estimator fitting or calibration is performed.
#' @details These are intended to reproduce the published scenario
#'   definitions, not to imply certified model recovery. Python source returns
#'   a tuple of frozen dataclasses, whereas R returns a list of native S3
#'   records. Full-source class identity remains an unresolved gap.
#' @export
etr_functional_recovery_qualification_scenarios <- function(
    replicates=3L,seed_start=202800L) {
  reps <- .etr_scenario_integer(replicates,"replicates",1L)
  seed <- .etr_scenario_integer(seed_start,"seed_start")
  .etr_assert(as.double(seed)+300 <= .Machine$integer.max &&
    as.double(seed)+300 >= -.Machine$integer.max,
    "seed_start and qualification offsets must fit native integer domain")
  list(
    etr_functional_simulation_scenario(
      name="dense_gaussian",truth_grid=seq(0,1,length.out=81L),
      eigenvalues=c(1,.35),n_participants=200L,
      measurement_noise_sd=.05,replicates=reps,seed_start=seed,
      labels=.etr_recovery_design_labels("fpca",
        "Dense Gaussian FPCA population/subspace/score recovery.")),
    etr_functional_simulation_scenario(
      name="dense_student_t",truth_grid=seq(0,1,length.out=81L),
      eigenvalues=c(1,.35),n_participants=200L,
      measurement_noise_sd=.05,score_distribution="student_t",score_df=6,
      replicates=reps,seed_start=seed+100L,
      labels=.etr_recovery_design_labels("fpca",
        "Dense variance-matched Student-t FPCA recovery.")),
    etr_functional_simulation_scenario(
      name="native_sparse",truth_grid=seq(0,1,length.out=31L),
      eigenvalues=c(1,.35),n_participants=64L,
      observation_design="irregular",samples_per_curve=c(8L,12L),
      irregular_time_design="uniform",measurement_noise_sd=.08,
      replicates=reps,seed_start=seed+200L,
      labels=.etr_recovery_design_labels("sparse_fpca_pace",
        paste0("Native irregular sparse FPCA/PACE recovery. ",
          "Fixed-noise and estimated-noise fits are distinct ",
          "estimator contracts over the same generating regime."))),
    etr_functional_simulation_scenario(
      name="hierarchy_sources",truth_grid=seq(0,1,length.out=31L),
      eigenvalues=c(1,.35),n_participants=300L,
      trials_per_participant=2L,participant_eigenvalues=c(.20,.08),
      trial_eigenvalues=c(.10,.04),measurement_noise_sd=0,
      replicates=reps,seed_start=seed+300L,
      labels=.etr_recovery_design_labels("hierarchy_truth",
        paste0("Finite-sample audit of separately declared curve, ",
          "participant, and trial score-source variances.")))
  )
}
