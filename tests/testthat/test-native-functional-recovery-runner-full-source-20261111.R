# Frozen Python 1.2 simulate.py::run_functional_recovery_scenarios
# plus recovery.py::FunctionalRecoveryAssessment, Result and Record.
# Commit c1cd95ad718327550f7e55393ff38582872f7a94.
# The scientific R S3 result is not a Python dataclass object.

.etr_runner_source_fixture<-function(){
  scenario<-etr_functional_simulation_scenario(
    name="source_recovery",truth_grid=c(0,.25,.5,.75,1),
    eigenvalues=1,n_participants=3L,trials_per_participant=2L,
    dimension_names="x",measurement_noise_sd=.01,
    replicates=2L,seed_start=73L,labels=list(study="native"))
  list(scenario=scenario,
    mean=function(t)rep(.3,length(t)),
    modes=list(function(t)rep(1,length(t))))
}
.etr_runner_source_order<-c(
  "scenario_name","replicate","seed","metrics","metric_values",
  "status","error_type","error_message","assessment_provenance")

test_that("source recovery runner composes actual seeded simulation without truth leakage",{
  f<-.etr_runner_source_fixture()
  calls<-0L
  fitted<-function(observations,scenario){
    calls<<-calls+1L
    expect_s3_class(observations,"etr_trajectory_set")
    expect_false("truth"%in%names(observations))
    expect_identical(scenario$name,"source_recovery")
    as.numeric(mean(observations$values))
  }
  scored<-function(model,truth,scenario)
    c(error=abs(model-mean(truth$mean)))
  source<-etr_run_functional_recovery_scenarios(
    list(f$scenario),f$mean,f$modes,fitted,scored,
    random_engine="numpy",python_boundary_mode=TRUE)
  expect_s3_class(source,"etr_functional_recovery_result")
  expect_identical(calls,2L)
  expect_identical(names(source),c("records","metric_definitions"))
  expect_identical(length(source$records),2L)
  expect_identical(length(source$metric_definitions),0L)
  for(i in seq_along(source$records)){
    record<-source$records[[i]]
    expect_identical(names(record),.etr_runner_source_order)
    expect_identical(record$replicate,as.integer(i-1L))
    expect_identical(record$seed,as.integer(72L+i))
    expect_identical(record$status,"ok")
    expect_equal(length(record$metric_values),0L)
    expect_identical(record$assessment_provenance,list())
    expect_null(record$error_type)
    expect_null(record$error_message)
    expect_true(is.finite(record$metrics[["error"]]))
    simulated<-etr_simulate_functional_scenario(f$scenario,f$mean,
      f$modes,replicate=i-1L,random_engine="numpy",
      python_boundary_mode=TRUE)
    expect_equal(record$metrics[["error"]],
      abs(mean(simulated$observations$values)-
        mean(simulated$truth$mean)),tolerance=1e-12)
  }
})

test_that("source runner retains structured source definitions and failure statuses",{
  f<-.etr_runner_source_fixture()
  estimator<-function(observations,scenario)mean(observations$values)
  structured<-etr_run_functional_recovery_scenarios(
    list(f$scenario),f$mean,f$modes,estimator,
    recovery=function(model,truth,scenario)
      etr_evaluate_hierarchy_truth_recovery(truth),
    random_engine="numpy",python_boundary_mode=TRUE)
  expect_identical(names(structured),c("records","metric_definitions"))
  expect_true(length(structured$metric_definitions)>=1L)
  expect_null(names(structured$metric_definitions))
  for(record in structured$records){
    expect_identical(names(record),.etr_runner_source_order)
    expect_true(length(record$metric_values)>0L)
    expect_true(all(is.finite(unname(record$metrics))))
    expect_identical(record$status,"ok")
  }
  failed<-etr_run_functional_recovery_scenarios(
    list(f$scenario),f$mean,f$modes,
    estimator=function(observations,scenario)
      stop("deliberate fit failure"),
    recovery=function(model,truth,scenario)c(error=1),
    failure_action="record",random_engine="numpy",
    python_boundary_mode=TRUE)
  expect_identical(names(failed),c("records","metric_definitions"))
  expect_identical(length(failed$records),2L)
  for(record in failed$records){
    expect_identical(names(record),.etr_runner_source_order)
    expect_identical(record$status,"fit_failed")
    expect_identical(record$error_type,"RuntimeError")
    expect_identical(record$error_message,"deliberate fit failure")
    expect_identical(length(record$metrics),0L)
    expect_identical(length(record$metric_values),0L)
  }
})

test_that("strict recovery source mode rejects native replay and base-R streams",{
  f<-.etr_runner_source_fixture()
  args<-list(
    scenarios=list(f$scenario),mean=f$mean,eigenfunctions=f$modes,
    estimator=function(obs,sc)0,
    recovery=function(model,truth,sc)c(error=0))
  expect_error(do.call(etr_run_functional_recovery_scenarios,
    c(args,list(python_boundary_mode=TRUE))),"requires random_engine")
  expect_error(do.call(etr_run_functional_recovery_scenarios,
    c(args,list(python_boundary_mode=1))),"python_boundary_mode")
  expect_error(do.call(etr_run_functional_recovery_scenarios,
    c(args,list(random_engine="numpy",python_boundary_mode=TRUE,
      source_draws_by_replicate=list(NULL,NULL)))),"native-only")
  expect_error(do.call(etr_run_functional_recovery_scenarios,
    c(args,list(random_engine="numpy",python_boundary_mode=TRUE,
      observation_times_by_replicate=list(NULL,NULL)))),"native-only")
  expect_error(do.call(etr_run_functional_recovery_scenarios,
    c(args,list(random_engine="numpy",python_boundary_mode=TRUE,
      failure_action="wrong"))),"failure_action")
  original<-do.call(etr_run_functional_recovery_scenarios,args)
  expect_true("provenance"%in%names(original))
  expect_false(original$provenance$independent_source_contract_certified)
})

test_that("frozen Python runner verifies seeded full source records, metrics and failures",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 native recovery runner exact-science oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
_rs=et.FunctionalSimulationScenario(
  name='source_recovery',truth_grid=np.array([0.,.25,.5,.75,1.]),
  eigenvalues=(1.,),n_participants=3,trials_per_participant=2,
  dimension_names=('x',),measurement_noise_sd=.01,
  replicates=2,seed_start=73,labels={'study':'native'})
_rs_mean=lambda t: np.full_like(t,.3,dtype=float)
_rs_modes=(lambda t: np.ones_like(t,dtype=float),)
def _rs_estimator(obs,scenario):
  return float(np.mean(obs.values))
def _rs_recovery(fitted,truth,scenario):
  return {'error':abs(fitted-float(np.mean(truth.mean)))}
def _rs_failure(obs,scenario):
  raise RuntimeError('deliberate fit failure')
_rs_ok=et.run_functional_recovery_scenarios(
  (_rs,),mean=_rs_mean,eigenfunctions=_rs_modes,
  estimator=_rs_estimator,recovery=_rs_recovery)
_rs_structured=et.run_functional_recovery_scenarios(
  (_rs,),mean=_rs_mean,eigenfunctions=_rs_modes,
  estimator=_rs_estimator,recovery=lambda fit,truth,s:
    et.evaluate_hierarchy_truth_recovery(truth))
_rs_failed=et.run_functional_recovery_scenarios(
  (_rs,),mean=_rs_mean,eigenfunctions=_rs_modes,
  estimator=_rs_failure,recovery=_rs_recovery,
  failure_action='record')
")
  f<-.etr_runner_source_fixture()
  estimator<-function(obs,s)as.numeric(mean(obs$values))
  native<-etr_run_functional_recovery_scenarios(
    list(f$scenario),f$mean,f$modes,estimator,
    function(fit,truth,s)c(error=abs(fit-mean(truth$mean))),
    random_engine="numpy",python_boundary_mode=TRUE)
  structured<-etr_run_functional_recovery_scenarios(
    list(f$scenario),f$mean,f$modes,estimator,
    function(fit,truth,s)etr_evaluate_hierarchy_truth_recovery(truth),
    random_engine="numpy",python_boundary_mode=TRUE)
  failed<-etr_run_functional_recovery_scenarios(
    list(f$scenario),f$mean,f$modes,
    estimator=function(obs,s)stop("deliberate fit failure"),
    recovery=function(fit,truth,s)c(error=1),
    failure_action="record",random_engine="numpy",
    python_boundary_mode=TRUE)
  for(kind in c("ok","structured","failed")){
    a<-get(kind,environment())
    py<-reticulate::py_eval(paste0("_rs_",kind),convert=FALSE)
    expect_identical(length(a$records),length(et_to_r(py$records)))
    expect_identical(length(a$metric_definitions),
      length(et_to_r(py$metric_definitions)))
    for(i in seq_along(a$records)){
      record<-a$records[[i]]
      oracle<-reticulate::py_get_item(py$records,as.integer(i-1L))
      expect_identical(names(record),.etr_runner_source_order)
      for(field in c("scenario_name","replicate","seed","status",
                     "error_type","error_message")){
        expect_equal(record[[field]],et_to_r(reticulate::py_get_attr(oracle,field)),
          ignore_attr=TRUE,info=paste(kind,i,field))
      }
      py_metrics<-et_to_r(oracle$metrics)
      expect_identical(names(record$metrics),names(py_metrics))
      expect_equal(as.numeric(record$metrics),as.numeric(unlist(py_metrics)),
        tolerance=1e-10,ignore_attr=TRUE,info=paste(kind,i,"metrics"))
      expect_identical(length(record$metric_values),
        length(et_to_r(oracle$metric_values)))
      expect_equal(record$assessment_provenance,
        et_to_r(oracle$assessment_provenance),ignore_attr=TRUE,
        info=paste(kind,i,"assessment provenance"))
      if(kind=="structured"){
        py_values<-oracle$metric_values
        for(j in seq_along(record$metric_values)){
          expected<-reticulate::py_get_item(py_values,as.integer(j-1L))
          value<-record$metric_values[[j]]
          expect_equal(value$value,et_to_r(expected$value),tolerance=1e-10)
          expect_equal(value$component,et_to_r(expected$component))
          expect_equal(value$source,et_to_r(expected$source))
          expect_identical(value$metric$name,et_to_r(expected$metric$name))
        }
      }
    }
  }
})
