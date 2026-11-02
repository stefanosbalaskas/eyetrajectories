# Frozen Python eyetrajectoriespy 1.2.0 recurrence.py::_state_from_source.
# Numeric and missing-data domain checks are native R; Python oracle is opt-in.
# Source pin: c1cd95ad718327550f7e55393ff38582872f7a94.

.etr_partial_recurrence_source_fixture <- function(){
  time<-as.numeric(0:8)
  values<-array(NA_real_,c(3L,length(time),2L))
  values[1L,,1L]<-c(0,1,2,4,5,6,7,9,10)
  values[2L,,1L]<-c(1,3,3,5,6,8,9,10,12)
  # Deliberately: unused channel y of selected curves and all channels of
  # unrelated curve c are missing. Python selects before finite checking.
  etr_trajectory_set(time,values,c("a","b","c"),c("x","y"),
    coordinate_system="arbitrary",time_unit="s",
    provenance=list(source="source_selected_state_scope"))
}

.etr_partial_recurrence_clean_curve <- function(x,i){
  etr_trajectory_set(x$time,
    x$values[i,,1L,drop=FALSE],curve_ids=x$curve_ids[i],
    dimension_names="x",coordinate_system=x$coordinate_system,
    time_unit=x$time_unit,provenance=x$provenance)
}

test_that("native recurrence checks only selected curve and selected channels",{
  x<-.etr_partial_recurrence_source_fixture()
  clean_a<-.etr_partial_recurrence_clean_curve(x,1L)
  for(metric in c("cityblock","euclidean","chebyshev")){
    for(policy in c("fixed","target")){
      arguments<-if(policy=="fixed")list(radius=2.5) else
        list(target_recurrence_rate=.4)
      partial<-do.call(etr_recurrence_matrix,c(list(
        x=x,curve="a",dimensions="x",theiler=1L,metric=metric),
        arguments))
      clean<-do.call(etr_recurrence_matrix,c(list(
        x=clean_a,curve=1L,theiler=1L,metric=metric),arguments))
      expect_equal(partial$matrix,clean$matrix,tolerance=0,
        info=paste(metric,policy,"native masked auto states"))
      expect_equal(partial$radius,clean$radius,tolerance=1e-12,
        info=paste(metric,policy,"native radius"))
      expect_equal(partial$recurrence_rate,clean$recurrence_rate,
        tolerance=0,info=paste(metric,policy,"native density"))
      expect_identical(partial$curve_ids,"a")
      expect_identical(partial$state_dimension,1L)
      expect_identical(partial$provenance$source_info$dimensions,"x")
    }
  }
  expect_error(etr_recurrence_matrix(x,curve="c",dimensions="x",
    radius=2.5),"complete finite selected")
  expect_error(etr_recurrence_matrix(x,curve="a",dimensions="y",
    radius=2.5),"complete finite selected")
  expect_error(etr_recurrence_matrix(x,curve="missing",dimensions="x",
    radius=2.5),"existing 1-based")
  # Legacy all-channel native behavior stays deliberately strict.
  expect_error(etr_recurrence_matrix(x,curve="a",radius=2.5),
    "complete observations required")
})

test_that("native cross recurrence selects one curve/channel on each side",{
  x<-.etr_partial_recurrence_source_fixture()
  a<-.etr_partial_recurrence_clean_curve(x,1L)
  b<-.etr_partial_recurrence_clean_curve(x,2L)
  for(metric in c("cityblock","euclidean","chebyshev")){
    for(policy in c("fixed","target")){
      arguments<-if(policy=="fixed")list(radius=2.5) else
        list(target_recurrence_rate=.4)
      partial<-do.call(etr_cross_recurrence_matrix,c(list(
        a=x,b=x,curve_a="a",curve_b="b",dimensions_a="x",
        dimensions_b="x",metric=metric),arguments))
      clean<-do.call(etr_cross_recurrence_matrix,c(list(
        a=a,b=b,curve_a="a",curve_b="b",dimensions_a="x",
        dimensions_b="x",metric=metric),arguments))
      expect_equal(partial$matrix,clean$matrix,tolerance=0,
        info=paste(metric,policy,"cross masked states"))
      expect_equal(partial$radius,clean$radius,tolerance=1e-12)
      expect_equal(partial$recurrence_rate,clean$recurrence_rate,
        tolerance=0)
      expect_identical(partial$curve_ids,c("a","b"))
      expect_identical(partial$state_dimension,1L)
      expect_identical(partial$provenance$source_a$dimensions,"x")
    }
  }
  expect_error(etr_cross_recurrence_matrix(x,x,radius=2.5,
    curve_a="c",curve_b="b",dimensions_a="x",dimensions_b="x"),
    "complete finite selected")
  expect_error(etr_cross_recurrence_matrix(x,x,radius=2.5,
    curve_a="a",curve_b="b",dimensions_a="y",dimensions_b="y"),
    "complete finite selected")
})

test_that("frozen Python 1.2 selected-state recurrence oracles agree for three metrics",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 recurrence source selected-state oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_partial_recurrence_source_fixture()
  pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system=x$coordinate_system,time_unit=x$time_unit)
  for(metric in c("cityblock","euclidean","chebyshev")){
    for(policy in c("fixed","target")){
      native_args<-if(policy=="fixed")list(radius=2.5) else
        list(target_recurrence_rate=.4)
      python_args<-if(policy=="fixed")list(radius=2.5) else
        list(target_recurrence_rate=.4)
      na<-do.call(etr_recurrence_matrix,c(list(
        x=x,curve="a",dimensions="x",theiler=1L,metric=metric),
        native_args))
      pa<-do.call(reticulate::py_call,c(list(
        etpy_get_export("recurrence_matrix"),
        source=pyx,curve=as.integer(0L),dimensions=as.list("x"),
        theiler_window=as.integer(1L),metric=metric),python_args))
      expect_equal(unname(na$matrix),
        unname(et_to_r(pa$matrix$toarray())),tolerance=0,
        info=paste("auto",metric,policy))
      expect_equal(na$radius,as.numeric(et_to_r(pa$radius)),
        tolerance=1e-9,info=paste("auto radius",metric,policy))
      expect_equal(na$recurrence_rate,
        as.numeric(et_to_r(pa$achieved_recurrence_rate)),
        tolerance=1e-12,info=paste("auto rate",metric,policy))
      nc<-do.call(etr_cross_recurrence_matrix,c(list(
        a=x,b=x,curve_a="a",curve_b="b",dimensions_a="x",
        dimensions_b="x",metric=metric),native_args))
      pc<-do.call(reticulate::py_call,c(list(
        etpy_get_export("cross_recurrence_matrix"),source_a=pyx,
        source_b=pyx,curve_a=as.integer(0L),curve_b=as.integer(1L),
        dimensions_a=as.list("x"),dimensions_b=as.list("x"),
        metric=metric),python_args))
      expect_equal(unname(nc$matrix),
        unname(et_to_r(pc$matrix$toarray())),tolerance=0,
        info=paste("cross",metric,policy))
      expect_equal(nc$radius,as.numeric(et_to_r(pc$radius)),
        tolerance=1e-9,info=paste("cross radius",metric,policy))
      expect_equal(nc$recurrence_rate,
        as.numeric(et_to_r(pc$achieved_recurrence_rate)),
        tolerance=1e-12,info=paste("cross rate",metric,policy))
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
