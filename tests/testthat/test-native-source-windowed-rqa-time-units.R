# Source-backed native time-based recurrence radius, sliding window and
# windowed functional RQA; Python 1.2 frozen commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
.etr_timed_rqa_fixture<-function(){
  time<-seq(0,1.1,by=.1)
  v<-array(0,c(2L,length(time),2L))
  for(i in 1:2){
    v[i,,1L]<-sin(time*6+i/5)+i*time/5
    v[i,,2L]<-cos(time*4+i/7)+time*i/10
  }
  etr_trajectory_set(time,v,c("a","b"),c("x","y"),
    time_unit="s",coordinate_system="normalized")
}

test_that("source time units propagate to recurrence radius CDF and three-metric windows",{
  x<-.etr_timed_rqa_fixture()
  radii<-c(.1,.3,.6,1,2)
  for(metric in c("cityblock","euclidean","chebyshev")){
    r<-etr_recurrence_radius_profile(x,curve="a",radii=radii,
      metric=metric,theiler_window=100,
      theiler_window_units="ms",dimensions=c("x","y"))
    raw<-etr_recurrence_radius_profile(x,curve="a",radii=radii,
      metric=metric,theiler_window=1L,dimensions=c("x","y"))
    expect_identical(r$theiler_window_samples,1L)
    expect_equal(r$table,raw$table,tolerance=0)
    timed<-etr_windowed_rqa(x,curve="a",window=600,
      step=200,window_units="ms",step_units="ms",radius=.8,
      metric=metric,theiler_window=.1,theiler_window_units="s",
      dimensions=c("x","y"))
    counted<-etr_windowed_rqa(x,curve="a",window=6L,
      step=2L,radius=.8,metric=metric,theiler_window=1L,
      dimensions=c("x","y"))
    expect_identical(timed$window_samples,6L)
    expect_identical(timed$step_samples,2L)
    expect_identical(timed$provenance$theiler_window_samples,1L)
    expect_identical(timed$provenance$metric,metric)
    expect_equal(timed$table,counted$table,tolerance=0)
    func<-etr_windowed_rqa_trajectory_set(x,
      metrics="recurrence_rate",window=600,step=200,
      window_units="ms",step_units="ms",radius=.8,
      metric=metric,theiler_window=100,
      theiler_window_units="ms",dimensions=c("x","y"),
      undefined_policy="keep")
    expect_identical(func$window_samples,6L)
    expect_identical(func$step_samples,2L)
    expect_identical(func$overlap_samples,4L)
    expect_equal(func$overlap_fraction,4/6,tolerance=0)
    expect_equal(as.numeric(func$trajectories$values[1L,,1L]),
      timed$table$recurrence_rate,tolerance=0)
  }
  expect_error(etr_windowed_rqa(x,curve="a",window=550,
    step=200,window_units="ms",step_units="ms",radius=.8),
    "integer multiple")
  expect_error(etr_recurrence_radius_profile(x,curve="a",
    radii=radii,theiler_window=.15,theiler_window_units="s"),
    "integer multiple")
  expect_error(etr_windowed_rqa(x,curve="a",window=6,step=2,
    radius=.8,metric="manhattan"),"metric must be one of")
})

test_that("frozen Python 1.2 radius and windowed time-unit oracles match native R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Python 1.2 source radius/window physical time oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_timed_rqa_fixture()
  py_x<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system="normalized",time_unit="s")
  for(metric in c("cityblock","euclidean","chebyshev")){
    radii<-c(.2,.5,.8,1.2,2)
    native_profile<-etr_recurrence_radius_profile(x,curve="a",
      radii=radii,metric=metric,theiler_window=100,
      theiler_window_units="ms",dimensions=c("x","y"))
    python_profile<-reticulate::py_call(
      etpy_get_export("recurrence_radius_profile"),
      source=py_x,curve="a",radii=as.list(radii),metric=metric,
      theiler_window=100L,theiler_window_units="ms",
      dimensions=as.list(c("x","y")))
    py_table<-et_to_r(python_profile$table)
    for(field in names(native_profile$table)){
      nr<-native_profile$table[[field]]
      py<-py_table[[field]]
      expect_identical(is.na(nr),is.na(py),
        info=paste(metric,"profile NA",field))
      if(any(is.finite(py)))
        expect_equal(as.numeric(nr[is.finite(py)]),
          as.numeric(py[is.finite(py)]),tolerance=1e-10,
          info=paste(metric,"source profile",field))
    }
    native_window<-etr_windowed_rqa(x,curve="a",
      window=600,step=200,window_units="ms",step_units="ms",
      radius=.8,metric=metric,theiler_window=100,
      theiler_window_units="ms",dimensions=c("x","y"))
    py_window<-reticulate::py_call(etpy_get_export("windowed_rqa"),
      trajectories=py_x,curve="a",window=600L,step=200L,
      window_units="ms",step_units="ms",radius=.8,metric=metric,
      theiler_window=100L,theiler_window_units="ms",
      dimensions=as.list(c("x","y")))
    pwt<-et_to_r(py_window$table)
    for(field in c("start_index","stop_index","start_time",
      "end_time","center_time","recurrence_rate","determinism",
      "laminarity","center_of_recurrence_mass")){
      a<-native_window$table[[field]]; b<-pwt[[field]]
      expect_identical(is.na(a),is.na(b),
        info=paste(metric,"window undefined",field))
      if(any(is.finite(b)))
        expect_equal(as.numeric(a[is.finite(b)]),
          as.numeric(b[is.finite(b)]),tolerance=1e-10,
          info=paste(metric,"window source",field))
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
