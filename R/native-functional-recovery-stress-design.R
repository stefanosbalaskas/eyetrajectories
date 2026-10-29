# Frozen source: eyetrajectoriespy 1.2.0 recovery_scenarios.py at
# c1cd95ad718327550f7e55393ff38582872f7a94.
# These functions DECLARE designs; they never simulate or certify recovery.

.etr_recovery_stress_labels <- function(target,description) {
  list(matrix_role="stress",scientific_target=target,
    description=description,automatic_thresholds=FALSE)
}

#' Declare published Python 1.2 deterministic recovery stress designs
#' @param replicates Positive integer descriptive simulation repetitions.
#' @param seed_start Base integer seed; source cases allocate offsets through 1200.
#' @return Ordered native list of fourteen source-defined S3 scenarios.
#' @details This declares stress regimes only. No estimator, threshold,
#'   statistical test or simulation runs automatically. Python returns a
#'   frozen dataclass tuple; the native S3 class difference is unresolved.
#' @export
etr_functional_recovery_stress_scenarios <- function(
    replicates=10L,seed_start=204000L) {
  reps<-.etr_scenario_integer(replicates,"replicates",1L)
  seed<-.etr_scenario_integer(seed_start,"seed_start")
  .etr_assert(as.double(seed)+1200<=.Machine$integer.max &&
    as.double(seed)+1200>=-.Machine$integer.max,
    "seed_start and stress scenario offsets must fit the native integer domain")
  grid<-seq(0,1,length.out=41L)
  make <- function(name,offset,target,description,...) {
    overrides<-list(...)
    args<-list(name=name,truth_grid=grid,eigenvalues=c(1,.35),
      n_participants=100L,measurement_noise_sd=0,
      replicates=reps,seed_start=seed+as.integer(offset),
      labels=.etr_recovery_stress_labels(target,description))
    for(nm in names(overrides))args[nm]<-overrides[nm]
    do.call(etr_functional_simulation_scenario,args)
  }
  list(
    make("stress_very_sparse",0L,"sparse_fpca_pace",
      "Very sparse native curves with only 3-5 samples.",
      observation_design="irregular",samples_per_curve=c(3L,5L),
      measurement_noise_sd=.08),
    make("stress_unequal_sample_counts",100L,"sparse_fpca_pace",
      "Strongly unequal per-curve sample counts.",
      observation_design="irregular",samples_per_curve=c(3L,20L),
      measurement_noise_sd=.08),
    make("stress_center_clustered_times",200L,"sparse_fpca_pace",
      "Nonuniform observation times concentrated centrally.",
      observation_design="irregular",samples_per_curve=c(8L,12L),
      irregular_time_design="center_clustered",measurement_noise_sd=.08),
    make("stress_boundary_poor_times",300L,"sparse_fpca_pace",
      "Observation schedules with weak boundary coverage.",
      observation_design="irregular",samples_per_curve=c(8L,12L),
      irregular_time_design="boundary_poor",measurement_noise_sd=.08),
    make("stress_estimated_noise_diagonal_difference",350L,
      "sparse_fpca_pace_estimated_noise",
      paste0("Diagonal-difference measurement-noise estimation. ",
        "The initial seeded qualification probe retained strong ",
        "subspace/score recovery but showed very large noise-",
        "variance error, so this regime is descriptive rather ",
        "than CI-qualified."),
      n_participants=120L,observation_design="irregular",
      samples_per_curve=c(10L,14L),
      irregular_time_design="uniform",measurement_noise_sd=.10),
    make("stress_high_measurement_noise",400L,"sparse_fpca_pace",
      "High measurement noise relative to latent variation.",
      n_participants=120L,observation_design="irregular",
      samples_per_curve=c(8L,12L),measurement_noise_sd=.20),
    make("stress_nearly_tied_eigenvalues",500L,"fpca_subspace",
      paste0("Nearly tied leading eigenvalues; subspace metrics are ",
        "primary and individual eigenfunctions are unstable."),
      eigenvalues=c(1,.90),n_participants=160L,measurement_noise_sd=.05),
    make("stress_heavy_tailed_scores",600L,"fpca",
      "Variance-matched heavy-tailed functional scores.",
      n_participants=160L,measurement_noise_sd=.05,
      score_distribution="student_t",score_df=4),
    make("stress_participant_heavy_hierarchy",700L,
      "functional_mixed_effects",
      "Participant-dominant hierarchical variation.",
      n_participants=120L,trials_per_participant=4L,
      participant_eigenvalues=c(.60,.20),
      trial_eigenvalues=c(.05,.02),measurement_noise_sd=.03),
    make("stress_trial_heavy_hierarchy",800L,"functional_mixed_effects",
      "Trial-dominant hierarchical variation.",
      n_participants=120L,trials_per_participant=4L,
      participant_eigenvalues=c(.05,.02),
      trial_eigenvalues=c(.60,.20),measurement_noise_sd=.03),
    make("stress_phase_variation",900L,"registration_phase",
      "Substantial endpoint-preserving phase variation.",
      n_participants=120L,measurement_noise_sd=.03,
      phase_variation=list(kind="power",sd=.20)),
    make("stress_mcar_missingness",1000L,"missing_data_workflow",
      "MCAR sample missingness.",
      n_participants=120L,measurement_noise_sd=.05,
      missingness=list(kind="mcar",probability=.20)),
    make("stress_block_missingness",1100L,"missing_data_workflow",
      "Structured contiguous-block missingness.",
      n_participants=120L,measurement_noise_sd=.05,
      missingness=list(kind="block",fraction=.20)),
    make("stress_correlated_multichannel_noise",1200L,"mfpca",
      "Correlated two-channel measurement noise.",
      n_participants=160L,dimension_names=c("x","y"),
      measurement_noise_sd=NULL,
      measurement_noise_covariance=matrix(
        c(.04,.018,.018,.09),nrow=2L,byrow=TRUE))
  )
}

#' Audit the published qualification and stress design catalogue
#' @param qualification_replicates Positive qualification replicate count.
#' @param stress_replicates Positive stress replicate count.
#' @return Ordered 18-row R data frame with three leading role/target/description
#'   columns inserted into the source-aligned simulation design frame.
#' @export
etr_functional_recovery_scenario_catalog_frame <- function(
    qualification_replicates=3L,stress_replicates=10L) {
  scenarios<-c(etr_functional_recovery_qualification_scenarios(
      replicates=qualification_replicates),
    etr_functional_recovery_stress_scenarios(
      replicates=stress_replicates))
  frame<-etr_functional_simulation_scenario_frame(scenarios)
  info<-data.frame(
    matrix_role=vapply(scenarios,function(x)x$labels$matrix_role,
      character(1L)),
    scientific_target=vapply(scenarios,function(x)x$labels$scientific_target,
      character(1L)),
    description=vapply(scenarios,function(x)x$labels$description,
      character(1L)),stringsAsFactors=FALSE)
  out<-data.frame(frame["scenario"],info,
    frame[setdiff(names(frame),"scenario")],check.names=FALSE)
  rownames(out)<-NULL
  out
}
