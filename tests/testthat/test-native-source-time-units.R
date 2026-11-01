# Frozen Python 1.2:
# embedding.py::_regular_step / _resolve_samples and
# workflows/_recurrence.py::run_recurrence_workflow.
# Actual native and published Python source executions, no Python in R API.
.etr_time_units_fixture<-function(time=seq(0,.24,by=.01),
    time_unit="s"){
  n<-4L;arr<-array(0,c(n,length(time),1L))
  for(i in seq_len(n))arr[i,,1]<-
    sin(2*pi*time/.25+i/5)+i*time/3
  etr_trajectory_set(time,arr,sprintf("c%02d",seq_len(n)),"x",
    coordinate_system="normalized",time_unit=time_unit)
}

test_that("source timing resolves all Python second/ms aliases with no interpolation",{
  time<-seq(0,.24,by=.01)
  for(units in c("ms","millisecond","milliseconds")){
    expect_identical(.etr_source_time_unit_samples(
      time,20,units,"s","delay"),2L)
    expect_identical(.etr_source_time_unit_samples(
      time,10,units,"s","theiler_window",TRUE),1L)
  }
  for(units in c("s","sec","second","seconds")){
    expect_identical(.etr_source_time_unit_samples(
      time,.02,units,"s","delay"),2L)
  }
  expect_identical(.etr_source_time_unit_samples(
    time,0,"samples","s","theiler_window",TRUE),0L)
  expect_identical(.etr_source_time_unit_samples(
    time,2.0,"samples","s","delay"),2L)
  expect_error(.etr_source_time_unit_samples(
    time,1.5,"samples","s","delay"),"must be integer")
  expect_error(.etr_source_time_unit_samples(
    time,.015,"s","s","delay"),"integer multiple")
  expect_error(.etr_source_time_unit_samples(
    time,1,"minutes","s","delay"),"cannot be converted")
  expect_error(.etr_source_time_unit_samples(
    time,0,"s","s","delay"),"positive sample count")
  expect_error(.etr_source_time_unit_samples(
    time,-1,"samples","s","theiler_window",TRUE),"non-negative")
  expect_error(.etr_source_time_unit_samples(
    time,TRUE,"samples","s","delay"),"not logical")
  invalid<-time;invalid[5L]<-invalid[5L]+.001
  expect_error(.etr_source_time_unit_samples(
    invalid,20,"ms","s","delay"),"approximately regular")
  expect_identical(.etr_source_time_unit_samples(
    invalid,2,"samples","s","delay"),2L)
  expect_identical(.etr_source_time_unit_samples(
    0:10,2,"tick","tick","delay"),2L)
})

test_that("native physical-time embedding and recurrence equal explicit sample workflow",{
  x<-.etr_time_units_fixture()
  physical<-etr_delay_embed_trajectory(x,embedding_dimension=2L,
    delay=20,delay_units="ms",dimensions="x")
  sample<-etr_delay_embed_trajectory(x,embedding_dimension=2L,
    delay=2L,delay_units="samples",dimensions="x")
  expect_identical(physical$delay_samples,2L)
  expect_identical(physical$values,sample$values)
  expect_identical(physical$time,sample$time)
  expect_equal(physical$delay_time,.02,tolerance=1e-12)
  for(metric in c("cityblock","euclidean","chebyshev")){
    source_cfg<-list(curve=0L,dimensions="x",
      embedding_dimension=2L,delay=20,delay_units="ms",
      radius=.6,metric=metric,theiler_window=10,
      theiler_window_units="ms")
    sample_cfg<-source_cfg
    sample_cfg$delay<-2L;sample_cfg$delay_units<-"samples"
    sample_cfg$theiler_window<-1L
    sample_cfg$theiler_window_units<-"samples"
    a<-etr_run_recurrence_workflow(x,source_cfg)
    b<-etr_run_recurrence_workflow(x,sample_cfg)
    expect_identical(a$embedding$values,b$embedding$values)
    expect_identical(a$recurrence$matrix,b$recurrence$matrix)
    expect_identical(a$embedding$delay_samples,2L)
    expect_identical(a$recurrence$theiler,1L)
    expect_true(a$provenance$physical_time_conversion_applied)
    expect_false(b$provenance$physical_time_conversion_applied)
    expect_identical(a$decisions$resolved_delay_samples$value,2L)
    expect_identical(a$decisions$resolved_theiler_window_samples$value,1L)
    expect_identical(length(a$steps),3L)
    cfg<-etr_frozen_recurrence_workflow_config(
      curve=0L,dimensions="x",embedding_dimension=2L,
      delay=20,delay_units="ms",radius=.6,metric=metric,
      theiler_window=10,theiler_window_units="ms")
    via_record<-etr_run_frozen_native_workflow(x,cfg)
    expect_identical(via_record$recurrence$matrix,a$recurrence$matrix)
  }
  expect_error(etr_run_recurrence_workflow(x,list(curve=0L,
    dimensions="x",embedding_dimension=2L,delay=15,
    delay_units="ms",radius=.6)),"integer multiple")
  expect_error(etr_run_recurrence_workflow(x,list(curve=0L,
    dimensions="x",embedding_dimension=2L,delay=20,
    delay_units="minutes",radius=.6)),"cannot be converted")
})

test_that("published frozen Python W4 physical-time grid and three metric oracles match",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python source W4 physical time numerical oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_time_units_fixture()
  reticulate::py_run_string("
import numpy as np, pandas as pd, eyetrajectoriespy as et
w4_units_t=np.linspace(0.,.24,25)
w4_units_v=np.empty((4,25,1))
for i in range(1,5):
    w4_units_v[i-1,:,0]=np.sin(2*np.pi*w4_units_t/.25+i/5)+i*w4_units_t/3
w4_units_x=et.TrajectorySet(time=w4_units_t,values=w4_units_v,
    curve_ids=tuple('c%02d'%i for i in range(1,5)),
    dimension_names=('x',),metadata=pd.DataFrame(index=range(4)),
    coordinate_system='normalized',time_unit='s')
")
  for(metric in c("cityblock","euclidean","chebyshev")){
    cfg<-etr_frozen_recurrence_workflow_config(curve=0L,
      dimensions="x",embedding_dimension=2L,
      delay=20,delay_units="ms",radius=.6,metric=metric,
      theiler_window=10,theiler_window_units="ms")
    native<-etr_run_frozen_native_workflow(x,cfg)
    py_cfg<-reticulate::py_call(
      etpy_get_export("RecurrenceWorkflowConfig",.namespace="workflows"),
      curve=0L,dimensions=reticulate::r_to_py(list("x")),
      embedding_dimension=2L,delay=20L,delay_units="ms",
      radius=.6,metric=metric,theiler_window=10L,
      theiler_window_units="ms")
    py<-reticulate::py_call(
      etpy_get_export("run_recurrence_workflow",.namespace="workflows"),
      trajectories=reticulate::py_eval("w4_units_x",convert=FALSE),
      config=py_cfg)
    expect_identical(native$embedding$delay_samples,
      as.integer(reticulate::py_to_r(py$embedding$delay_samples)))
    expect_equal(unname(native$embedding$values),
      unname(et_to_r(py$embedding$values)),
      tolerance=1e-12,info=paste(metric,"embedded states"))
    expect_equal(unname(native$recurrence$matrix),
      unname(et_to_r(py$recurrence$matrix$toarray())),
      tolerance=0,info=paste(metric,"source matrix"))
    expect_identical(native$recurrence$theiler,
      as.integer(reticulate::py_to_r(
        py$recurrence$theiler_window_samples)))
    for(field in c("recurrence_rate","determinism","laminarity",
      "mean_diagonal_length","max_diagonal_length",
      "diagonal_entropy","trapping_time","max_vertical_length",
      "center_of_recurrence_mass","n_recurrence_points",
      "n_diagonal_lines","n_vertical_lines")){
      actual<-as.numeric(native$metrics[[field]])
      source<-as.numeric(reticulate::py_to_r(
        reticulate::py_get_attr(py$metrics,field)))
      if(is.finite(actual)&&is.finite(source))
        expect_equal(actual,source,tolerance=1e-10,
          info=paste(metric,field))
      else expect_true(is.na(actual)&&is.na(source),
        info=paste(metric,field,"undefined source estimand"))
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
