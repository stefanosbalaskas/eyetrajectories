# Frozen Python 1.2 kinematics.py::distance_to_landmark_function
# Native NumPy-landmark input-domain and derived-provenance witnesses.
# Source commit: c1cd95ad718327550f7e55393ff38582872f7a94.
# These are first-party comparisons, not full-domain certification.

.etr_landmark_distance_source_fixture<-function(with_missing=FALSE) {
  time<-c(0,.25,.55,1,1.5)
  v<-array(0,c(3L,length(time),3L))
  for(i in 1:3){
    v[i,,1L]<-i*1.5+sin(time*2+i*.4)
    v[i,,2L]<-i*.8+cos(time*3-i*.2)
    v[i,,3L]<-i+time/2
  }
  if(isTRUE(with_missing))v[2L,3L,1L]<-NA_real_
  etr_trajectory_set(time,v,curve_ids=c("a","b","c"),
    dimension_names=c("x","y","pupil"),coordinate_system="pixels",
    time_unit="s",provenance=list(source="native_landmark_distance"))
}

test_that("source-compatible landmark distance preserves native finite numerical geometry",{
  x<-.etr_landmark_distance_source_fixture()
  numeric<-etr_distance_to_landmark(x,c(1,2.5,0),c(0,1,3.5))
  compat<-etr_distance_to_landmark(x,
    list(TRUE,"2.5",0L),list(FALSE,1L,"3.5"),
    python_boundary_mode=TRUE)
  expect_equal(compat$values,numeric$values,tolerance=0)
  expect_identical(compat$curve_ids,x$curve_ids)
  expect_identical(compat$metadata,x$metadata)
  expect_identical(compat$coordinate_system,x$coordinate_system)
  expect_identical(compat$time_unit,x$time_unit)
  expect_identical(compat$dimension_names,"distance_to_landmark")
  expect_identical(compat$provenance$source,"native_landmark_distance")
  expect_identical(compat$provenance$derived_function,"distance_to_landmark")
  expect_null(numeric$provenance$derived_function)
  expect_identical(dim(compat$values),c(3L,5L,1L))
})

test_that("source landmark Boolean and string scalar broadcasting matches numeric",{
  x<-.etr_landmark_distance_source_fixture()
  expect_error(etr_distance_to_landmark(x,TRUE,0),"finite numeric")
  expect_error(etr_distance_to_landmark(x,"2","1"),"finite numeric")
  actual<-etr_distance_to_landmark(x,TRUE,"1.25",
    python_boundary_mode=TRUE)
  control<-etr_distance_to_landmark(x,1,1.25)
  expect_equal(actual$values,control$values,tolerance=0)
  expect_true(all(actual$values>=0))
  strings<-etr_distance_to_landmark(x,c("1","2","3"),
    c("3","2","1"),python_boundary_mode=TRUE)
  numeric<-etr_distance_to_landmark(x,c(1,2,3),c(3,2,1))
  expect_equal(strings$values,numeric$values,tolerance=0)
  expect_error(etr_distance_to_landmark(x,list("1"),1,
    python_boundary_mode=TRUE),"source-compatible scalar or per-curve")
  expect_error(etr_distance_to_landmark(x,c("1","2"),1,
    python_boundary_mode=TRUE),"source-compatible scalar or per-curve")
  expect_error(etr_distance_to_landmark(x,c("1","oops","3"),1,
    python_boundary_mode=TRUE),"finite numeric-compatible")
})

test_that("landmark distance source-compatible mode preserves missing gaze masks",{
  x<-.etr_landmark_distance_source_fixture(with_missing=TRUE)
  actual<-etr_distance_to_landmark(x,
    list(1L,"2",TRUE),c(TRUE,FALSE,TRUE),
    python_boundary_mode=TRUE)
  expect_true(is.na(actual$values[2L,3L,1L]))
  expect_false(anyNA(actual$values[-2L,,1L]))
  expect_equal(actual$values[2L,c(1L,2L,4L,5L),1L],
    etr_distance_to_landmark(x,c(1,2,1),c(1,0,1))$
      values[2L,c(1L,2L,4L,5L),1L],tolerance=0)
  expect_identical(actual$provenance$derived_function,"distance_to_landmark")
})

test_that("actual frozen Python landmark distance agrees on mixed source inputs",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 landmark distance source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_landmark_distance_source_fixture()
  py_x<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system="pixels",time_unit="s",
    provenance=reticulate::r_to_py(list(
      source="native_landmark_distance")))
  compare<-function(left,right){
    native<-etr_distance_to_landmark(x,left,right,
      python_boundary_mode=TRUE)
    py<-reticulate::py_call(
      etpy_get_export("distance_to_landmark_function"),
      trajectories=py_x,
      landmark_x=reticulate::r_to_py(left),
      landmark_y=reticulate::r_to_py(right))
    expect_equal(unname(native$values),unname(et_to_r(py$values)),
      tolerance=1e-12)
    expect_identical(native$dimension_names,
      as.character(unlist(et_to_r(py$dimension_names))))
    expect_identical(native$coordinate_system,
      as.character(et_to_r(py$coordinate_system)))
    expect_identical(native$provenance$derived_function,
      as.character(et_to_r(py$provenance$get("derived_function"))))
  }
  compare(list(TRUE,"2.5",0L),list(FALSE,1L,"3.5"))
  compare(c("1.25","2","3.5"),c(TRUE,FALSE,TRUE))
  compare(TRUE,"1.25")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
