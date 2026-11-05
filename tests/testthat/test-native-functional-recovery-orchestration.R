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
