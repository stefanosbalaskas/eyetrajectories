# Frozen Python 1.2 simulate.py declared scenario and recovery policy.
.etr_recovery_scenario_fixture<-function(replicates=2L){
  etr_functional_simulation_scenario(
    name="recovery_pilot",truth_grid=c(0,.25,.5,.75,1),
    eigenvalues=1,n_participants=3L,trials_per_participant=2L,
    dimension_names="x",measurement_noise_sd=.01,
    replicates=replicates,seed_start=73L,
    labels=list(study="fixed"))
}
.etr_recovery_mean<-function(t)rep(.3,length(t))
.etr_recovery_modes<-function()list(function(t)rep(1,length(t)))

test_that("declared scenario seeds, truth and provenance remain separate",{
  scenario<-.etr_recovery_scenario_fixture()
  a<-etr_simulate_functional_scenario(scenario,
    mean=.etr_recovery_mean,eigenfunctions=.etr_recovery_modes(),
    replicate=0L)
  b<-etr_simulate_functional_scenario(scenario,
    mean=.etr_recovery_mean,eigenfunctions=.etr_recovery_modes(),
    replicate=1L)
  expect_identical(a$truth$provenance$scenario_name,"recovery_pilot")
  expect_identical(a$truth$provenance$scenario_replicate,0L)
  expect_identical(b$truth$provenance$scenario_seed,74L)
  expect_identical(a$truth$provenance$scenario_labels$study,"fixed")
  expect_false(identical(a$truth$scores,b$truth$scores))
  expect_identical(dim(a$observations$values),c(6L,5L,1L))
  expect_error(etr_simulate_functional_scenario(scenario,
    .etr_recovery_mean,.etr_recovery_modes(),replicate=2L),
    "outside")
  expect_error(etr_simulate_functional_scenario(list(),
    .etr_recovery_mean,.etr_recovery_modes()),
    "scenario")
})

test_that("recovery estimator only receives observations and declared scenario",{
  scenario<-.etr_recovery_scenario_fixture()
  calls<-0L
  estimator<-function(observations,design){
    calls<<-calls+1L
    expect_s3_class(observations,"etr_trajectory_set")
    expect_s3_class(design,"etr_functional_simulation_scenario")
    expect_false("truth"%in%names(observations))
    list(average=mean(observations$values))
  }
  scorer<-function(fitted,truth,design){
    expect_true(is.matrix(truth$mean))
    c(mean_absolute_error=abs(fitted$average-mean(truth$mean)))
  }
  result<-etr_run_functional_recovery_scenarios(
    list(scenario),.etr_recovery_mean,.etr_recovery_modes(),
    estimator,scorer)
  expect_s3_class(result,"etr_functional_recovery_result")
  expect_identical(length(result$records),2L)
  expect_identical(calls,2L)
  expect_true(all(vapply(result$records,
    function(r)identical(r$status,"ok"),logical(1L))))
  expect_true(all(vapply(result$records,
    function(r)is.finite(r$metrics[["mean_absolute_error"]]),logical(1L))))
  expect_false(result$provenance$truth_available_to_estimator)
  expect_false(result$provenance$redraw_on_failure)
  expect_false(result$provenance$independent_source_contract_certified)
})

test_that("recovery driver records distinct failures without redrawing",{
  scenario<-.etr_recovery_scenario_fixture(1L)
  failing<-function(observations,scenario)stop("deliberate fit failure")
  scorer<-function(fitted,truth,scenario)c(error=0)
  expect_error(etr_run_functional_recovery_scenarios(
    list(scenario),.etr_recovery_mean,.etr_recovery_modes(),
    failing,scorer,failure_action="raise"),"deliberate")
  z<-etr_run_functional_recovery_scenarios(
    list(scenario),.etr_recovery_mean,.etr_recovery_modes(),
    failing,scorer,failure_action="record")
  expect_identical(length(z$records),1L)
  expect_identical(z$records[[1L]]$status,"fit_failed")
  expect_identical(z$records[[1L]]$error_message,
    "deliberate fit failure")
  expect_identical(z$records[[1L]]$seed,73L)
  expect_identical(length(z$records[[1L]]$metrics),0L)
  expect_error(etr_run_functional_recovery_scenarios(list(),
    .etr_recovery_mean,.etr_recovery_modes(),failing,scorer),
    "scenarios")
})

test_that("pinned Python 1.2 scenario seed and label semantics agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 scenario seed oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
from eyetrajectoriespy.simulate import FunctionalSimulationScenario
sc=FunctionalSimulationScenario(name='recovery_pilot',
 truth_grid=[0,.25,.5,.75,1],eigenvalues=[1],
 n_participants=3,trials_per_participant=2,
 dimension_names=('x',),measurement_noise_sd=.01,
 replicates=2,seed_start=73,labels={'study':'fixed'})
_scenario_source=list(sc.seeds())
")
  source<-reticulate::py_to_r(reticulate::py_eval(
    "_scenario_source",convert=FALSE))
  expect_identical(as.integer(source),c(73L,74L))
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

# Actual pinned-Python 1.2 public export and source-signature witness.
# This verifies callable/source availability, NOT native scientific parity.
test_that("unreviewed Python 1.2 source symbols are inspectable: simulate_functional_scenario, run_functional_recovery_scenarios",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python source-symbol audit requires source runtime")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("simulate_functional_scenario"),"simulate_functional_scenario")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("run_functional_recovery_scenarios"),"run_functional_recovery_scenarios")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})


# Batch 20: replay the complete declared simulation/recovery pipeline from
# source-retained random score, noise, and irregular schedule realizations.
# This never allows the estimator callback to inspect simulator truth.
test_that("whole-scenario irregular replay preserves observations and assessment truth",{
  scenario<-etr_functional_simulation_scenario(
    name="irregular_replay",truth_grid=c(0,.25,.5,.75,1),
    eigenvalues=1,n_participants=3L,trials_per_participant=1L,
    observation_design="irregular",samples_per_curve=c(3L,5L),
    measurement_noise_sd=.04,participant_eigenvalues=.2,
    trial_eigenvalues=.1,replicates=2L,seed_start=123L)
  mean_fn<-function(t)rep(.3,length(t))
  modes<-list(function(t)rep(1,length(t)))
  reference<-lapply(0:1,function(rep)etr_simulate_functional_scenario(
    scenario,mean_fn,modes,replicate=rep))
  replay<-lapply(reference,function(x)list(
    curve_scores=x$truth$curve_scores,
    participant_scores=x$truth$participant_scores,
    trial_scores=x$truth$trial_scores,
    measurement_noise=x$truth$measurement_noise))
  schedules<-lapply(reference,function(x)x$truth$pre_missing_observation_times)
  for(i in seq_along(reference)){
    z<-etr_simulate_functional_scenario(scenario,mean_fn,modes,
      replicate=i-1L,source_draws=replay[[i]],
      observation_times=schedules[[i]])
    expect_identical(z$observations$time,reference[[i]]$observations$time)
    expect_equal(z$observations$values,reference[[i]]$observations$values,
      tolerance=0)
    expect_equal(z$truth$scores,reference[[i]]$truth$scores,tolerance=0)
    expect_identical(z$truth$provenance$scenario_replicate,as.integer(i-1L))
  }
  calls<-0L
  estimator<-function(observations,design){
    calls<<-calls+1L
    expect_identical(design$name,"irregular_replay")
    expect_false("truth"%in%names(observations))
    expect_equal(observations$values,reference[[calls]]$observations$values,
      tolerance=0)
    list(observed_mean=mean(unlist(observations$values)))
  }
  scorer<-function(fit,truth,design){
    expect_equal(truth$scores,reference[[calls]]$truth$scores,tolerance=0)
    c(observed_mean=fit$observed_mean,
      truth_score_mean=mean(truth$scores))
  }
  result<-etr_run_functional_recovery_scenarios(
    list(scenario),mean_fn,modes,estimator,scorer,
    source_draws_by_replicate=replay,
    observation_times_by_replicate=schedules)
  expect_identical(calls,2L)
  expect_equal(length(result$records),2L)
  expect_true(result$provenance$fixed_source_draw_replay)
  expect_true(result$provenance$fixed_irregular_schedule_replay)
  expect_false(result$provenance$truth_available_to_estimator)
  for(i in seq_along(result$records)){
    expect_identical(result$records[[i]]$status,"ok")
    expect_equal(result$records[[i]]$metrics[["truth_score_mean"]],
      mean(reference[[i]]$truth$scores),tolerance=0)
    expect_identical(result$records[[i]]$replicate,as.integer(i-1L))
  }
  expect_error(etr_run_functional_recovery_scenarios(
    list(scenario),mean_fn,modes,estimator,scorer,
    source_draws_by_replicate=list(replay[[1L]])),
    "one NULL or source record")
  expect_error(etr_run_functional_recovery_scenarios(
    list(scenario),mean_fn,modes,estimator,scorer,
    observation_times_by_replicate=list("not-a-schedule",NULL)),
    "one NULL or source record")
  expect_error(etr_simulate_functional_scenario(
    etr_functional_simulation_scenario("dense",c(0,.5,1),1,2L),
    mean_fn,modes,observation_times=list(c(0,1),c(0,1))),
    "requires an irregular scenario")
})

test_that("frozen Python 1.2 irregular scenario can be fully replayed",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python scenario irregular source replay is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  np<-reticulate::import("numpy",convert=FALSE)
  reticulate::py_run_string("
import numpy as np
def _etr_scenario_mean(t):
    return np.full_like(t,.3,dtype=float)
def _etr_scenario_mode(t):
    return np.ones_like(t,dtype=float)
")
  py_scenario<-reticulate::py_call(
    etpy_get_export("FunctionalSimulationScenario"),
    name="irregular_replay",truth_grid=np$asarray(
      reticulate::r_to_py(c(0,.25,.5,.75,1)),dtype="float64"),
    eigenvalues=reticulate::py_eval("(1.,)",convert=FALSE),
    n_participants=as.integer(3L),trials_per_participant=as.integer(1L),
    observation_design="irregular",
    samples_per_curve=reticulate::tuple(3L,5L),
    measurement_noise_sd=.04,
    participant_eigenvalues=reticulate::py_eval("(.2,)",convert=FALSE),
    trial_eigenvalues=reticulate::py_eval("(.1,)",convert=FALSE),
    replicates=as.integer(2L),seed_start=as.integer(123L))
  source<-reticulate::py_call(
    etpy_get_export("simulate_functional_scenario"),
    scenario=py_scenario,
    mean=reticulate::py_eval("_etr_scenario_mean",convert=FALSE),
    eigenfunctions=reticulate::py_eval("(_etr_scenario_mode,)",convert=FALSE),
    replicate=as.integer(0L))
  truth<-source$truth
  scenario<-etr_functional_simulation_scenario(
    "irregular_replay",c(0,.25,.5,.75,1),1,3L,
    observation_design="irregular",samples_per_curve=c(3L,5L),
    measurement_noise_sd=.04,participant_eigenvalues=.2,
    trial_eigenvalues=.1,replicates=2L,seed_start=123L)
  samples<-list(curve_scores=et_to_r(truth$curve_scores),
    participant_scores=et_to_r(truth$participant_scores),
    trial_scores=et_to_r(truth$trial_scores),
    measurement_noise=et_to_r(truth$measurement_noise))
  source_times<-lapply(et_to_r(truth$pre_missing_observation_times),as.numeric)
  native<-etr_simulate_functional_scenario(
    scenario,function(t)rep(.3,length(t)),
    list(function(t)rep(1,length(t))),
    replicate=0L,source_draws=samples,observation_times=source_times)
  py_values<-et_to_r(source$observations$values)
  py_times<-et_to_r(source$observations$time)
  expect_equal(native$truth$scores,et_to_r(truth$scores),
    tolerance=1e-12,ignore_attr=TRUE)
  expect_equal(native$truth$latent_on_truth_grid,
    et_to_r(truth$latent_on_truth_grid),
    tolerance=1e-12,ignore_attr=TRUE)
  for(i in seq_along(py_times)){
    expect_equal(native$observations$time[[i]],as.numeric(py_times[[i]]),
      tolerance=0)
    expect_equal(unname(native$observations$values[[i]]),
      unname(py_values[[i]]),tolerance=1e-12)
  }
  expect_identical(native$truth$provenance$scenario_name,
    as.character(reticulate::py_to_r(truth$provenance[["scenario_name"]])))
  expect_false(any(etr_native_parity_catalog()$one_to_one_native_contract_complete))
})
