# Frozen Python 1.2 simulate.py source-restricted orchestration.
# Inputs are explicit; estimator never receives realized simulation truth.
# External independent full-domain source certification remains unsigned.

#' Execute one declared native functional simulation scenario replicate
#' @param scenario Native record from etr_functional_simulation_scenario().
#' @param mean,eigenfunctions Callable generating functions.
#' @param replicate Zero-based replicate index; seed is seed_start + replicate.
#' @param source_draws Optional fixed retained source-law scores and noise.
#' @return Native simulation observations and complete truth with provenance.
#' @export
etr_simulate_functional_scenario<-function(scenario,mean,eigenfunctions,
    replicate=0L,source_draws=NULL) {
  .etr_assert(inherits(scenario,"etr_functional_simulation_scenario"),
    "scenario must be a declared native functional simulation scenario")
  index<-.etr_scenario_integer(replicate,"replicate",0L)
  .etr_assert(index<scenario$replicates,
    "replicate is outside the declared scenario range")
  seed<-scenario$seed_start+index
  .etr_assert(seed>=0L&&seed<=.Machine$integer.max,
    "derived scenario seed outside supported R random-state domain")
  result<-etr_simulate_functional_process(
    mean=mean,eigenfunctions=eigenfunctions,
    eigenvalues=scenario$eigenvalues,
    truth_grid=scenario$truth_grid,
    n_participants=scenario$n_participants,
    trials_per_participant=scenario$trials_per_participant,
    dimension_names=scenario$dimension_names,
    coordinate_system=scenario$coordinate_system,
    time_unit=scenario$time_unit,
    observation_design=scenario$observation_design,
    samples_per_curve=scenario$samples_per_curve,
    irregular_time_design=scenario$irregular_time_design,
    participant_eigenvalues=scenario$participant_eigenvalues,
    trial_eigenvalues=scenario$trial_eigenvalues,
    measurement_noise_sd=scenario$measurement_noise_sd,
    measurement_noise_covariance=scenario$measurement_noise_covariance,
    missingness=scenario$missingness,
    phase_variation=scenario$phase_variation,
    score_distribution=scenario$score_distribution,
    score_df=scenario$score_df,
    orthonormal_tolerance=scenario$orthonormal_tolerance,
    random_state=seed,source_draws=source_draws)
  result$truth$provenance$scenario_name<-scenario$name
  result$truth$provenance$scenario_replicate<-index
  result$truth$provenance$scenario_seed<-seed
  result$truth$provenance$scenario_labels<-scenario$labels
  result
}

#' Run declared functional simulation and recovery without truth leakage
#'
#' @description Fits each independent declared scenario replicate with
#'   observations alone. The recovery callback alone receives realized truth.
#'   Explicit failures are either propagated or recorded; no replacements,
#'   redrawing or silent exclusions occur. Returned metric mappings are
#'   descriptive numerical recovery scores, not confidence intervals.
#' @param scenarios Nonempty list of native functional simulation scenarios.
#' @param mean,eigenfunctions Source generating functions.
#' @param estimator Callback(observations, scenario), never receives truth.
#' @param recovery Callback(fit, truth, scenario), returns named finite metrics.
#' @param failure_action "raise" (stop) or "record" (preserve failure).
#' @return Native R result with all successful and failed replicates.
#' @export
etr_run_functional_recovery_scenarios<-function(
    scenarios,mean,eigenfunctions,estimator,recovery,
    failure_action="raise") {
  .etr_assert(is.list(scenarios)&&length(scenarios)>0L&&
    all(vapply(scenarios,function(s)
      inherits(s,"etr_functional_simulation_scenario"),logical(1L))),
    "scenarios must contain declared functional simulation scenario records")
  .etr_assert(is.function(estimator)&&is.function(recovery),
    "estimator and recovery must be callable")
  .etr_assert(is.character(failure_action)&&
    length(failure_action)==1L&&!is.na(failure_action)&&
    failure_action%in%c("raise","record"),
    "failure_action must be raise or record")
  rows<-list()
  for(scenario in scenarios)for(replicate in
      seq.int(0L,scenario$replicates-1L)){
    seed<-scenario$seed_start+replicate
    prefix<-list(scenario_name=scenario$name,
      replicate=as.integer(replicate),seed=as.integer(seed))
    run<-function() {
      simulation<-tryCatch(etr_simulate_functional_scenario(
        scenario,mean,eigenfunctions,replicate),error=function(e)
          structure(list(error=e,status="simulation_failed"),
            class="etr_recovery_attempt_error"))
      if(inherits(simulation,"etr_recovery_attempt_error"))return(simulation)
      fitted<-tryCatch(estimator(simulation$observations,scenario),
        error=function(e)structure(list(error=e,status="fit_failed"),
          class="etr_recovery_attempt_error"))
      if(inherits(fitted,"etr_recovery_attempt_error"))return(fitted)
      result<-tryCatch(recovery(fitted,simulation$truth,scenario),
        error=function(e)structure(list(error=e,status="recovery_failed"),
          class="etr_recovery_attempt_error"))
      if(inherits(result,"etr_recovery_attempt_error"))return(result)
      .etr_assert(is.numeric(result)&&is.null(dim(result))&&
        length(result)>0L&&all(is.finite(result))&&
        !is.null(names(result))&&!anyNA(names(result))&&
        all(nzchar(names(result)))&&!anyDuplicated(names(result)),
        "recovery must return named finite numeric metrics in native subset")
      structure(list(metrics=result),class="etr_recovery_attempt_success")
    }
    result<-run()
    if(inherits(result,"etr_recovery_attempt_error")){
      if(failure_action=="raise")stop(result$error)
      rows[[length(rows)+1L]]<-c(prefix,list(
        status=result$status,metrics=numeric(),
        error_type=class(result$error)[1L],
        error_message=conditionMessage(result$error)))
    }else{
      rows[[length(rows)+1L]]<-c(prefix,list(
        status="ok",metrics=result$metrics,
        error_type=NULL,error_message=NULL))
    }
  }
  structure(list(records=rows,metric_definitions=list(),
    provenance=list(truth_available_to_estimator=FALSE,
      failure_action=failure_action,redraw_on_failure=FALSE,
      native_random_engine="base_R_not_NumPy_PCG64",
      published_python_dataclass_equivalence=FALSE,
      independent_source_contract_certified=FALSE)),
    class="etr_functional_recovery_result")
}
