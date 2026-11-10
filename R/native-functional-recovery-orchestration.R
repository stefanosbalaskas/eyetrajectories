# Frozen Python 1.2 simulate.py source-restricted orchestration.
# Inputs are explicit; estimator never receives realized simulation truth.
# External independent full-domain source certification remains unsigned.

#' Execute one declared native functional simulation scenario replicate
#' @param scenario Native record from etr_functional_simulation_scenario().
#' @param mean,eigenfunctions Callable generating functions.
#' @param replicate Zero-based replicate index; seed is seed_start + replicate.
#' @param source_draws Optional fixed retained source-law scores and noise.
#' @param observation_times Optional explicitly retained irregular source
#'   schedules (one numeric time vector per curve), overriding only the
#'   random sampling policy during deterministic review.
#' @param random_engine Native simulation stream, "base_R" or "numpy".
#' @return Native simulation observations and complete truth with provenance.
#' @export
etr_simulate_functional_scenario<-function(scenario,mean,eigenfunctions,
    replicate=0L,source_draws=NULL,observation_times=NULL,
    random_engine="base_R") {
  .etr_assert(inherits(scenario,"etr_functional_simulation_scenario"),
    "scenario must be a declared native functional simulation scenario")
  index<-.etr_scenario_integer(replicate,"replicate",0L)
  .etr_assert(index<scenario$replicates,
    "replicate is outside the declared scenario range")
  seed<-scenario$seed_start+index
  .etr_assert(seed>=0L&&seed<=.Machine$integer.max,
    "derived scenario seed outside supported R random-state domain")
  # Exact replay of source-created irregular schedules. The scenario
  # specifies its stochastic sampling policy; explicit times replace only
  # that draw, without changing the scientific observation model.
  if(!is.null(observation_times))
    .etr_assert(identical(scenario$observation_design,"irregular")&&
      is.list(observation_times),
      "observation_times replay requires an irregular scenario and a list of per-curve schedules")
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
    observation_times=observation_times,
    samples_per_curve=if(is.null(observation_times))
      scenario$samples_per_curve else NULL,
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
    random_state=seed,source_draws=source_draws,random_engine=random_engine)
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
#' @param recovery Callback(fit, truth, scenario), returns named finite
#'   numeric metrics or a structured etr_functional_recovery_assessment
#'   carrying source metric definitions, components and provenance.
#' @param failure_action "raise" (stop) or "record" (preserve failure).
#' @param source_draws_by_replicate Optional ordered list with one slot for
#'   every scenario replicate; each is NULL or the four-source-draw record
#'   accepted by etr_simulate_functional_process(). The order is scenarios
#'   first, then zero-based replicate. This is a native source-replay option,
#'   not a claim of NumPy PCG64 equivalence.
#' @param observation_times_by_replicate Optional ordered list with one slot
#'   per replicate; each NULL or a list of per-curve irregular schedules.
#'   For exact irregular replay, pass the source's pre-missing schedules.
#' @param random_engine Native simulation stream, "base_R" or "numpy".
#' @return Native R result with all successful and failed replicates.
#' @export
etr_run_functional_recovery_scenarios<-function(
    scenarios,mean,eigenfunctions,estimator,recovery,
    failure_action="raise",source_draws_by_replicate=NULL,
    observation_times_by_replicate=NULL,random_engine="base_R") {
  random_engine<-match.arg(random_engine,c("base_R","numpy"))
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
  n_runs<-sum(vapply(scenarios,function(x)as.double(x$replicates),numeric(1L)))
  .etr_assert(n_runs<=.Machine$integer.max,
    "too many simulation replicates to enumerate")
  validate_replay<-function(x,label,element_check){
    if(is.null(x))return(invisible(NULL))
    .etr_assert(is.list(x)&&length(x)==n_runs&&
      all(vapply(x,element_check,logical(1L))),
      paste0(label," must contain one NULL or source record for each declared scenario replicate"))
  }
  validate_replay(source_draws_by_replicate,
    "source_draws_by_replicate",function(x)is.null(x)||is.list(x))
  .etr_assert(identical(random_engine,"base_R")||
    all(vapply(source_draws_by_replicate,is.null,logical(1L))),
    "source_draws_by_replicate must use random_engine='base_R'")
  validate_replay(observation_times_by_replicate,
    "observation_times_by_replicate",function(x)is.null(x)||is.list(x))
  rows<-list()
  definitions<-list()
  replay_index<-0L
  for(scenario in scenarios)for(replicate in
      seq.int(0L,scenario$replicates-1L)){
    replay_index<-replay_index+1L
    replay_draws<-if(is.null(source_draws_by_replicate))NULL else
      source_draws_by_replicate[[replay_index]]
    replay_times<-if(is.null(observation_times_by_replicate))NULL else
      observation_times_by_replicate[[replay_index]]
    seed<-scenario$seed_start+replicate
    prefix<-list(scenario_name=scenario$name,
      replicate=as.integer(replicate),seed=as.integer(seed))
    run<-function() {
      simulation<-tryCatch(etr_simulate_functional_scenario(
        scenario,mean,eigenfunctions,replicate,
        source_draws=replay_draws,observation_times=replay_times,
        random_engine=random_engine),error=function(e)
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
      # Frozen simulate.py catches recovery callback exceptions only.
      # Invalid metrics or assessment records are checked after the callback
      # and must raise even when failure_action="record".
      payload<-.etr_recovery_runner_metrics(result)
      structure(payload,class="etr_recovery_attempt_success")
    }
    result<-run()
    if(inherits(result,"etr_recovery_attempt_error")){
      if(failure_action=="raise")stop(result$error)
      rows[[length(rows)+1L]]<-c(prefix,list(
        status=result$status,metrics=numeric(),
        metric_values=list(),assessment_provenance=list(),
        error_type=class(result$error)[1L],
        error_message=conditionMessage(result$error)))
    }else{
      # Python's inconsistent definition rejection is outside its
      # estimator/recovery failure_action handling: never silently
      # classify an incompatible scientific metric as a failed run.
      for(definition in result$definitions){
        name<-definition$name
        if(name%in%names(definitions))
          .etr_assert(identical(definitions[[name]],definition),
            paste0("recovery metric definitions are inconsistent for ",name))
        else definitions[[name]]<-definition
      }
      rows[[length(rows)+1L]]<-c(prefix,list(
        status="ok",metrics=result$metrics,
        metric_values=result$metric_values,
        assessment_provenance=result$assessment_provenance,
        error_type=NULL,error_message=NULL))
    }
  }
  structure(list(records=rows,metric_definitions=definitions,
    provenance=list(truth_available_to_estimator=FALSE,
      failure_action=failure_action,redraw_on_failure=FALSE,
      native_random_engine=.etr_functional_simulation_engine_label(random_engine),
      fixed_source_draw_replay=if(is.null(source_draws_by_replicate))FALSE
        else any(!vapply(source_draws_by_replicate,is.null,logical(1L))),
      fixed_irregular_schedule_replay=if(is.null(observation_times_by_replicate))FALSE
        else any(!vapply(observation_times_by_replicate,is.null,logical(1L))),
      published_python_dataclass_equivalence=FALSE,
      independent_source_contract_certified=FALSE)),
    class="etr_functional_recovery_result")
}
