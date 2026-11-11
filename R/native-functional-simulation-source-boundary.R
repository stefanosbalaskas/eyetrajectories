# Frozen Python 1.2 source boundary for a genuinely simulated process.
# eyetrajectoriespy==1.2.0 commit c1cd95ad718327550f7e55393ff38582872f7a94.
# _functional_simulation.py::simulate_functional_process_core:
# provenance order, all truth fields, and preserved native scientific data.
#
# Never construct synthetic truth after simulation, change the PCG64 draw
# chronology, or call Python at package runtime. This is an explicit native
# scientific representation analogue, not a Python frozen dataclass identity.

.etr_functional_simulation_python_boundary<-function(
    result,observation_times=NULL,irregular_time_design="uniform") {
  .etr_assert(inherits(result,"etr_functional_simulation_result")&&
    is.list(result$truth)&&is.list(result$observations),
    "source simulation boundary requires a native simulation result")
  tr<-result$truth
  .etr_assert(is.list(tr$provenance)&&
    is.numeric(tr$truth_grid)&&length(tr$truth_grid)>=3L&&
    tr$observation_design%in%c("dense","irregular"),
    "source simulation boundary requires a declared observation design")
  prov<-tr$provenance
  nd<-length(tr$dimension_names);n<-nrow(tr$scores)
  .etr_assert(is.numeric(prov$measurement_noise_sd)&&
    length(prov$measurement_noise_sd)==nd&&
    is.matrix(tr$measurement_noise_covariance)&&
    identical(dim(tr$measurement_noise_covariance),c(as.integer(nd),as.integer(nd))),
    "source simulation boundary requires a complete noise specification")
  .etr_assert(is.numeric(prov$phase_exponents)&&
    length(prov$phase_exponents)==n&&
    all(is.finite(prov$phase_exponents))&&
    is.list(tr$score_distribution_parameters),
    "source simulation boundary requires realized phases and score specification")
  source_provenance<-list(
    source="simulate_functional_process_core",
    synthetic=TRUE,
    private_0_11_simulation_core=TRUE,
    random_state=tr$random_state,
    observation_design=tr$observation_design,
    irregular_time_design=if(identical(tr$observation_design,"irregular")&&
      is.null(observation_times))irregular_time_design else NULL,
    measurement_noise_sd=as.numeric(prov$measurement_noise_sd),
    measurement_noise_covariance=lapply(seq_len(nd),function(j)
      as.numeric(tr$measurement_noise_covariance[j,])),
    participant_eigenvalues=as.numeric(tr$participant_eigenvalues),
    trial_eigenvalues=as.numeric(tr$trial_eigenvalues),
    phase_variation_kind=as.character(prov$phase_variation_kind),
    phase_exponents=as.numeric(prov$phase_exponents),
    missingness_kind=as.character(prov$missingness_kind),
    missingness_specification=prov$missingness_specification,
    n_components=as.integer(length(tr$eigenvalues)),
    score_distribution=as.character(tr$score_distribution),
    score_distribution_parameters=tr$score_distribution_parameters,
    truth_grid=as.numeric(tr$truth_grid),
    raw_dense_to_irregular_interpolation_performed=FALSE
  )
  result$truth$provenance<-source_provenance
  result$observations$provenance<-source_provenance
  result
}
