# Native R preprocessing source-domain witnesses against frozen Python 1.2.
# Source: eyetrajectoriespy@c1cd95ad718327550f7e55393ff38582872f7a94
# preprocessing.py: normalize_coordinates, center_on_landmark, normalize_time.
# First-party source tests only; these do not independently certify the API.

.etr_preprocessing_boundary_fixture <- function(){
  time<-c(0,.1,.3,.6,1)
  v<-array(0,c(3L,length(time),3L))
  for(i in 1:3){
    v[i,,1L]<-i*2+time
    v[i,,2L]<-i*3-time/2
    v[i,,3L]<-4+i+time/5
  }
  etr_trajectory_set(time,v,curve_ids=c("a","b","c"),
    dimension_names=c("x","y","pupil"),coordinate_system="pixels",
    time_unit="s",provenance=list(source="preprocessing_boundary"))
}

test_that("native Boolean coordinate extents have exact Python arithmetic",{
  x<-.etr_preprocessing_boundary_fixture()
  expect_error(etr_normalize_coordinates(x,width=TRUE,height=2),
    "finite numeric scalar")
  actual<-etr_normalize_coordinates(x,width=TRUE,height=2,
    python_boundary_mode=TRUE)
  baseline<-etr_normalize_coordinates(x,width=1,height=2)
  expect_equal(actual$values,baseline$values,tolerance=0)
  expect_identical(actual$dimension_names,x$dimension_names)
  expect_identical(actual$metadata,x$metadata)
  expect_identical(actual$coordinate_system,"normalized")
  expect_equal(actual$values[,,3L],x$values[,,3L],tolerance=0)
  expect_error(etr_normalize_coordinates(x,width=FALSE,height=2,
    python_boundary_mode=TRUE),"finite numeric scalar")
  expect_error(etr_normalize_coordinates(x,width=TRUE,height=0,
    python_boundary_mode=TRUE),"finite numeric scalar")
})

test_that("native center_on_landmark converts named numeric-like source landmarks",{
  x<-.etr_preprocessing_boundary_fixture()
  left<-c("1.5","2.0","3.25")
  right<-c(TRUE,FALSE,TRUE)
  expect_error(etr_center_on_landmark(x,left,right),"finite scalar")
  native<-etr_center_on_landmark(x,left,right,
    python_boundary_mode=TRUE)
  expected<-etr_center_on_landmark(x,
    as.numeric(left),as.numeric(right))
  expect_equal(native$values,expected$values,tolerance=0)
  expect_identical(native$coordinate_system,"landmark_relative")
  expect_identical(native$provenance$landmark_centering$per_curve,TRUE)
  expect_equal(native$values[,,3L],x$values[,,3L],tolerance=0)
  scalar<-etr_center_on_landmark(x,"2","3.5",
    python_boundary_mode=TRUE)
  expected_scalar<-etr_center_on_landmark(x,2,3.5)
  expect_equal(scalar$values,expected_scalar$values,tolerance=0)
  explicit_list<-etr_center_on_landmark(x,
    list("1.5",2,TRUE),list(0L,"1.25",FALSE),
    python_boundary_mode=TRUE)
  explicit_numeric<-etr_center_on_landmark(x,
    c(1.5,2,1),c(0,1.25,0))
  expect_equal(explicit_list$values,explicit_numeric$values,tolerance=0)
  expect_error(etr_center_on_landmark(x,c("1","broken","3"),1,
    python_boundary_mode=TRUE),"finite numeric-compatible")
  expect_error(etr_center_on_landmark(x,list("1"),1,
    python_boundary_mode=TRUE),"source-compatible scalar or per-curve")
  expect_error(etr_center_on_landmark(x,c("1","2"),1,
    python_boundary_mode=TRUE),"source-compatible scalar or per-curve")
})

test_that("native Boolean time endpoints match frozen source linear transformation",{
  x<-.etr_preprocessing_boundary_fixture()
  expect_error(etr_normalize_time_interval(x,start=TRUE,end=2),
    "finite numeric scalar")
  actual<-etr_normalize_time_interval(x,start=TRUE,end=2,
    python_boundary_mode=TRUE)
  baseline<-etr_normalize_time_interval(x,start=1,end=2)
  expect_equal(actual$time,baseline$time,tolerance=0)
  expect_equal(actual$values,x$values,tolerance=0)
  expect_identical(actual$time_unit,"normalized")
  expect_error(etr_normalize_time_interval(x,start=TRUE,end=FALSE,
    python_boundary_mode=TRUE),"end must be greater")
  expect_equal(etr_normalize_time_interval(x,start=FALSE,end=TRUE,
    python_boundary_mode=TRUE)$time,
    etr_normalize_time_interval(x)$time,tolerance=0)
})

test_that("all three preprocessing boundary oracles replay frozen Python 1.2",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 preprocessing boundary source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_preprocessing_boundary_fixture()
  py_x<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system="pixels",time_unit="s")
  # Direct source invocation, not an R->Python fallback implementation.
  py_coord<-reticulate::py_call(
    etpy_get_export("normalize_coordinates"),
    trajectories=py_x,width=TRUE,height=as.integer(2L))
  native_coord<-etr_normalize_coordinates(x,TRUE,2L,
    python_boundary_mode=TRUE)
  expect_equal(unname(native_coord$values),
    unname(et_to_r(py_coord$values)),tolerance=1e-12)
  expect_identical(native_coord$coordinate_system,
    as.character(et_to_r(py_coord$coordinate_system)))
  py_landmark<-reticulate::py_call(
    etpy_get_export("center_on_landmark"),trajectories=py_x,
    landmark_x=reticulate::r_to_py(c("1.5","2","3.25")),
    landmark_y=reticulate::r_to_py(c(TRUE,FALSE,TRUE)))
  native_landmark<-etr_center_on_landmark(x,c("1.5","2","3.25"),
    c(TRUE,FALSE,TRUE),python_boundary_mode=TRUE)
  expect_equal(unname(native_landmark$values),
    unname(et_to_r(py_landmark$values)),tolerance=1e-12)
  expect_identical(native_landmark$coordinate_system,
    as.character(et_to_r(py_landmark$coordinate_system)))
  py_time<-reticulate::py_call(
    etpy_get_export("normalize_time"),trajectories=py_x,
    start=TRUE,end=as.integer(2L))
  native_time<-etr_normalize_time_interval(x,start=TRUE,end=2L,
    python_boundary_mode=TRUE)
  expect_equal(native_time$time,as.numeric(et_to_r(py_time$time)),
    tolerance=1e-12)
  expect_equal(native_time$values,et_to_r(py_time$values),
    tolerance=1e-12)
  expect_identical(native_time$time_unit,
    as.character(et_to_r(py_time$time_unit)))
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
