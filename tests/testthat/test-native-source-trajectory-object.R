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
  # Constructor checks time/channel shape first and then ID counts.
  # A one-curve replacement keeps the time/channel dimensions but
  # violates the preserved two-element curve ID collection.
  expect_error(etr_with_values(x,array(1:3,c(1L,3L,1L))),
    "curve_ids must be unique nonempty strings")
  # A second channel violates the preserved one-element dimension list.
  expect_error(etr_with_values(x,array(1:12,c(2L,3L,2L))),
    "dimension_names must be unique strings")
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


test_that("opt-in Python TrajectorySet constructor keeps NaN and empty curves",{
  vals<-array(c(1,NaN,Inf,4,5,6),c(2L,3L,1L))
  expect_error(etr_trajectory_set(c(0,1,2),vals,c("a","b"),"x"),
    "NaN or infinity")
  x<-etr_trajectory_set(c("0","1","2"),vals,c("a","b"),"x",
    python_boundary_mode=TRUE)
  expect_s3_class(x,"etr_trajectory_set")
  expect_true(is.nan(x$values[2L,1L,1L]))
  expect_true(any(is.infinite(x$values)))
  expect_true(isTRUE(attr(x,"python_boundary_mode")))
  expect_true(etr_validate(x))
  y<-etr_with_values(x,x$values,provenance_update=list(method="source"))
  expect_true(isTRUE(attr(y,"python_boundary_mode")))
  expect_identical(is.nan(y$values),is.nan(x$values))
  expect_identical(y$provenance$method,"source")

  empty<-etr_subset(x,integer(),python_boundary_mode=TRUE)
  expect_identical(dim(empty$values),c(0L,3L,1L))
  expect_length(empty$curve_ids,0L)
  expect_true(etr_validate(empty))
  expect_error(etr_subset(x,integer()),"unique valid 1-based")
  expect_error(etr_subset(x,c(0L,0L),python_boundary_mode=TRUE),
    "curve_ids must be unique")
  expect_error(etr_subset(x,2L,python_boundary_mode=TRUE),"out of range")
  expect_error(etr_subset(x,-3L,python_boundary_mode=TRUE),"out of range")
  expect_identical(etr_subset(x,0L,python_boundary_mode=TRUE)$curve_ids,"a")
  expect_identical(etr_subset(x,-1L,python_boundary_mode=TRUE)$curve_ids,"b")
  expect_identical(etr_subset(x,c(0L,-1L),
    python_boundary_mode=TRUE)$curve_ids,c("a","b"))
  expect_identical(etr_subset(x,1L)$curve_ids,"a")
  expect_true(isTRUE(attr(etr_subset(x,1L),"python_boundary_mode")))
  expect_identical(etr_subset(x,1L)$values[1L,,1L],
    x$values[1L,,1L])
  expect_false(any(etr_native_parity_catalog()$one_to_one_native_contract_complete))
})

test_that("pinned Python 1.2 TrajectorySet NaN and zero-based subset oracle",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python TrajectorySet zero-curve source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  vals<-array(c(1,NaN,Inf,4,5,6),c(2L,3L,1L))
  x<-etr_trajectory_set(c(0,1,2),vals,c("a","b"),"x",
    python_boundary_mode=TRUE)
  py_ctor<-etpy_get_export("TrajectorySet",.namespace="root")
  py_x<-reticulate::py_call(py_ctor,
    time=reticulate::r_to_py(c(0,1,2)),
    values=reticulate::r_to_py(vals),
    curve_ids=reticulate::r_to_py(c("a","b")),
    dimension_names=reticulate::r_to_py("x"))
  python_values<-reticulate::py_to_r(py_x$values)
  expect_identical(dim(python_values),dim(x$values))
  expect_identical(is.nan(python_values),is.nan(x$values))
  expect_identical(is.infinite(python_values),is.infinite(x$values))
  py_sub<-py_x$subset(reticulate::r_to_py(c(0L,-1L)))
  native_sub<-etr_subset(x,c(0L,-1L),python_boundary_mode=TRUE)
  expect_identical(as.character(reticulate::py_to_r(py_sub$curve_ids)),
    native_sub$curve_ids)
  expect_equal(unname(reticulate::py_to_r(py_sub$values)),
    unname(native_sub$values),tolerance=0)
  py_empty<-py_x$subset(reticulate::r_to_py(integer()))
  native_empty<-etr_subset(x,integer(),python_boundary_mode=TRUE)
  expect_identical(as.integer(reticulate::py_to_r(py_empty$n_curves)),0L)
  expect_identical(dim(native_empty$values),c(0L,3L,1L))
  expect_false(any(etr_native_parity_catalog()$one_to_one_native_contract_complete))
})


test_that("Python mode accepts nested values, mixed scalar time and ID metadata index", {
  nested <- list(
    list(c("1", "2"), c("3", "4"), c("5", "6")),
    list(c("7", "8"), c("9", "10"), c("11", "12"))
  )
  time <- list("0", TRUE, "2")
  native <- etr_trajectory_set(time, nested,
    curve_ids=c("a","b"), dimension_names=c("x","y"),
    metadata=data.frame(group=c("A","B")),
    python_boundary_mode=TRUE)
  expect_identical(dim(native$values),c(2L,3L,2L))
  expect_equal(native$time,c(0,1,2),tolerance=0)
  expect_identical(rownames(native$metadata),c("a","b"))
  expect_equal(native$values[1L,1L,],c(1,2),tolerance=0)
  expect_identical(rownames(etr_subset(native,c("1","0"),
    python_boundary_mode=TRUE)$metadata),c("b","a"))
  expect_error(etr_subset(native,"1.0",python_boundary_mode=TRUE),
    "integer literals")
  expect_error(etr_trajectory_set(time,
    list(list(c("1","2")),list(c("1","2"),c("3","4"))),
    c("a","b"),c("x","y"),python_boundary_mode=TRUE),"rectangular")
  expect_error(etr_trajectory_set(time,
    list(list(c("oops","2"),c("3","4"),c("5","6")),
      nested[[2L]]),c("a","b"),c("x","y"),
    python_boundary_mode=TRUE),"nonnumeric string")
  # The strict scientific constructor must not silently accept nested data.
  expect_error(etr_trajectory_set(c(0,1,2),nested,c("a","b"),c("x","y")),
    "numeric 3D array")
})

test_that("frozen Python 1.2 TrajectorySet nested source and metadata agree", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 array-like TrajectorySet oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  nested <- list(
    list(c("1", "2"), c("3", "4"), c("5", "6")),
    list(c("7", "8"), c("9", "10"), c("11", "12"))
  )
  time <- list("0", TRUE, "2")
  native <- etr_trajectory_set(time,nested,
    c("a","b"),c("x","y"),python_boundary_mode=TRUE)
  ctor <- etpy_get_export("TrajectorySet",.namespace="root")
  py_x <- reticulate::py_call(ctor,
    time=reticulate::r_to_py(time),
    values=reticulate::r_to_py(nested),
    curve_ids=reticulate::r_to_py(c("a","b")),
    dimension_names=reticulate::r_to_py(c("x","y")))
  expect_equal(unname(reticulate::py_to_r(py_x$values)),
    unname(native$values),tolerance=0)
  expect_equal(as.numeric(reticulate::py_to_r(py_x$time)),
    native$time,tolerance=0)
  expect_identical(
    as.character(reticulate::py_to_r(py_x$metadata$index$tolist())),
    rownames(native$metadata))
  py_subset <- py_x$subset(reticulate::r_to_py(c("1","0")))
  native_subset <- etr_subset(native,c("1","0"),
    python_boundary_mode=TRUE)
  expect_identical(as.character(reticulate::py_to_r(py_subset$curve_ids)),
    native_subset$curve_ids)
  expect_identical(
    as.character(reticulate::py_to_r(py_subset$metadata$index$tolist())),
    rownames(native_subset$metadata))
  expect_false(any(etr_native_parity_catalog()$one_to_one_native_contract_complete))
})

test_that("Python array complex casting is opt-in for TrajectorySet", {
  vals <- array(as.complex(c(1,2,3,4,5,6)),c(2L,3L,1L))
  vals <- array(
    complex(real=Re(vals), imaginary=rep(100,length(vals))),
    dim=c(2L,3L,1L))
  expect_error(etr_trajectory_set(c(0,1,2),vals,c("a","b"),"x"),
    "numeric 3D array")
  native <- etr_trajectory_set(c(0+4i,1+4i,2+4i),vals,
    c("a","b"),"x",python_boundary_mode=TRUE)
  expect_equal(native$values,Re(vals),tolerance=0)
  expect_equal(native$time,c(0,1,2),tolerance=0)
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 complex ndarray oracle opt-in")
  ctor <- etpy_get_export("TrajectorySet",.namespace="root")
  py_x <- reticulate::py_call(ctor,
    time=reticulate::r_to_py(c(0+4i,1+4i,2+4i)),
    values=reticulate::r_to_py(vals),
    curve_ids=reticulate::r_to_py(c("a","b")),
    dimension_names=reticulate::r_to_py("x"))
  expect_equal(unname(reticulate::py_to_r(py_x$values)),
    unname(native$values),tolerance=0)
  expect_equal(as.numeric(reticulate::py_to_r(py_x$time)),
    native$time,tolerance=0)
})
