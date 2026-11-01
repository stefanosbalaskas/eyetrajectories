# Frozen Python 1.2 source: types.py TrajectorySet.
# Native R constructor already preserves data and provenance. These checks
# expand a real native partial contract, NOT independent full-domain parity.
test_that("native TrajectorySet with_values preserves IDs, metadata and provenance",{
  values<-array(seq_len(12L)/10,c(2L,3L,2L))
  x<-etr_trajectory_set(c(0,1,2),values,
    c("subject_a","subject_b"),c("x","y"),
    metadata=data.frame(group=c("A","B")),
    provenance=list(source="initial",nested=list(version=1L)))
  replacement<-values+1
  y<-etr_with_values(x,replacement,
    provenance_update=list(source="updated",new_note="native-test"),
    coordinate_system="normalized")
  expect_s3_class(y,"etr_trajectory_set")
  expect_equal(y$values,replacement,tolerance=0)
  expect_equal(y$time,c(0,1,2),tolerance=0)
  expect_identical(y$curve_ids,x$curve_ids)
  expect_identical(y$dimension_names,x$dimension_names)
  expect_identical(y$metadata,x$metadata)
  expect_identical(y$time_unit,x$time_unit)
  expect_identical(y$coordinate_system,"normalized")
  expect_identical(y$provenance$source,"updated")
  expect_identical(y$provenance$nested,list(version=1L))
  expect_identical(y$provenance$new_note,"native-test")
  expect_identical(x$provenance$source,"initial")
  expect_equal(x$values,values,tolerance=0)
  expect_identical(x$coordinate_system,"unknown")
})

test_that("native TrajectorySet with_values supports explicit new time grid",{
  initial<-array(c(1,2,3),c(1L,3L,1L))
  x<-etr_trajectory_set(c(0,1,2),initial,
    curve_ids="a",dimension_names="x")
  values<-array(c(1,2,3,4),c(1L,4L,1L))
  y<-etr_with_values(x,values,
    time=c(0,.5,1.5,2),time_unit="seconds")
  expect_identical(dim(y$values),c(1L,4L,1L))
  expect_equal(y$time,c(0,.5,1.5,2),tolerance=0)
  expect_equal(y$values,values,tolerance=0)
  expect_identical(y$time_unit,"seconds")
  expect_identical(y$curve_ids,x$curve_ids)
  expect_identical(y$metadata,x$metadata)
  expect_identical(y$provenance,list())
})

test_that("native TrajectorySet with_values rejects incompatible shapes and missing scientific metadata",{
  x<-etr_trajectory_set(c(0,1,2),array(1:6,c(2L,3L,1L)),
    c("a","b"),"x")
  expect_error(etr_with_values(x,matrix(1:6,2,3)),
    "numeric 3D array")
  expect_error(etr_with_values(x,array(1:3,c(1L,3L,1L))),
    "values dimensions must agree")
  expect_error(etr_with_values(x,array(1:12,c(2L,3L,2L))),
    "values dimensions must agree")
  expect_error(etr_with_values(x,array(1:8,c(2L,4L,1L))),
    "values dimensions must agree")
  expect_error(etr_with_values(x,array(1:8,c(2L,4L,1L)),
    time=c(0,1,1,3)),"strictly increasing")
  expect_error(etr_with_values(x,array(1:6,c(2L,3L,1L)),
    provenance_update="wrong"),"JSON-like named")
  expect_error(etr_with_values(x,array(1:6,c(2L,3L,1L)),
    time_unit=""),"time_unit")
  # IMPORTANT: native R rejects NaN while Python source class permits NaN
  # to mark missing gaze. Full-domain parity remains scientifically BLOCKED.
  bad<-array(as.double(1:6),c(2L,3L,1L))
  bad[1L,2L,1L]<-NaN
  expect_error(etr_with_values(x,bad),"NaN or infinity")
  expect_false(any(etr_native_parity_catalog()$one_to_one_native_contract_complete))
})

test_that("pinned frozen Python 1.2 TrajectorySet.with_values agrees on finite copy case",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Source TrajectorySet class oracle requires pinned Python 1.2")
  expect_identical(et_python_version(),"1.2.0")
  values<-array(as.double(seq_len(12L))/10,c(2L,3L,2L))
  x<-etr_trajectory_set(c(0,1,2),values,
    c("a","b"),c("x","y"),
    provenance=list(source="initial"))
  updated<-values+1
  native<-etr_with_values(x,updated,
    provenance_update=list(source="updated",method="copy"),
    coordinate_system="normalized")
  py_ctor<-etpy_get_export("TrajectorySet",.namespace="root")
  py_x<-reticulate::py_call(py_ctor,
    time=reticulate::r_to_py(c(0,1,2)),
    values=reticulate::r_to_py(values),
    curve_ids=reticulate::r_to_py(c("a","b")),
    dimension_names=reticulate::r_to_py(c("x","y")),
    provenance=reticulate::r_to_py(list(source="initial")))
  py_y<-py_x$with_values(reticulate::r_to_py(updated),
    provenance_update=reticulate::r_to_py(
      list(source="updated",method="copy")),
    coordinate_system="normalized")
  expect_equal(as.array(reticulate::py_to_r(py_y$values)),
    native$values,tolerance=0)
  expect_equal(as.numeric(reticulate::py_to_r(py_y$time)),
    native$time,tolerance=0)
  expect_identical(as.character(reticulate::py_to_r(py_y$curve_ids)),
    native$curve_ids)
  expect_identical(as.character(reticulate::py_to_r(py_y$dimension_names)),
    native$dimension_names)
  expect_identical(as.character(reticulate::py_to_r(py_y$coordinate_system)),
    native$coordinate_system)
  expect_identical(as.character(reticulate::py_to_r(py_y$provenance$get("source"))),
    native$provenance$source)
  expect_false(any(etr_native_parity_catalog()$one_to_one_native_contract_complete))
})
