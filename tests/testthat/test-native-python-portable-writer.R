# Python 1.2 JSON+NPZ interoperability: bounded native R writer.
.etr_portable_writer_fixture <- function() {
  a<-array(seq_len(24L)/7,c(2L,6L,2L))
  a[2L,3L,2L]<-NA_real_
  etr_trajectory_set(seq(0,1,length.out=6L),a,c("A","B"),
    c("x","y"),data.frame(group=c("alpha","beta"),
      trial=c(1,2)),coordinate_system="pixels",
    time_unit="s",provenance=list(origin="native R",audit=list(pass=TRUE)))
}
test_that("native writer uses the source manifest and roundtrips R arrays",{
  skip_if_not_installed("zip")
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  x<-.etr_portable_writer_fixture()
  dest<-tempfile("native_portable_")
  on.exit(unlink(dest,recursive=TRUE),add=TRUE)
  expect_invisible(etr_export_python_portable_result(x,dest))
  y<-etr_read_python_portable_result(dest)
  expect_s3_class(y,"etr_python_portable_snapshot")
  expect_identical(y$result_type,"eyetrajectoriespy.types.TrajectorySet")
  expect_match(y$source_package_version,"^R-native-eyetrajectories-")
  expect_equal(as.vector(y$payload$time),x$time,tolerance=0)
  expect_identical(dim(y$payload$values),dim(x$values))
  expect_identical(is.na(y$payload$values),is.na(x$values))
  expect_equal(y$payload$values,x$values,tolerance=0)
  expect_identical(y$payload$metadata$group,x$metadata$group)
  expect_equal(y$payload$metadata$trial,x$metadata$trial,tolerance=0)
  expect_identical(as.character(unlist(y$payload$curve_ids)),x$curve_ids)
  expect_identical(y$payload$provenance$origin,"native R")
  expect_true(y$payload$provenance$audit$pass)
  expect_error(etr_export_python_portable_result(x,dest),
    "not empty")
  expect_error(etr_export_python_portable_result(x,dest,overwrite=TRUE),
    "overwrite")
  expect_error(etr_export_python_portable_result(x,dest,
    include_environment=TRUE),"environment")
  expect_error(etr_export_python_portable_result(list(),tempfile()),
    "etr_trajectory_set")
})
test_that("Python 1.2 directly reads native R exported result",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 native portable writer oracle opt-in")
  skip_if_not_installed("zip")
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_portable_writer_fixture()
  dest<-tempfile("native_to_python_")
  on.exit(unlink(dest,recursive=TRUE),add=TRUE)
  etr_export_python_portable_result(x,dest)
  py<-reticulate::py_call(etpy_get_export("load_portable_result"),
    directory=dest)
  expect_equal(as.numeric(reticulate::py_to_r(py$payload$get("time"))),
    x$time,tolerance=1e-12)
  got<-reticulate::py_to_r(py$payload$get("values"))
  expect_identical(dim(got),dim(x$values))
  expect_identical(is.na(got),is.na(x$values))
  expect_equal(got,x$values,tolerance=1e-12)
  got_metadata<-reticulate::py_to_r(py$payload$get("metadata"))
  expect_identical(got_metadata$group,x$metadata$group)
  expect_equal(got_metadata$trial,x$metadata$trial,tolerance=0)
  expect_identical(as.character(reticulate::py_to_r(
    py$payload$get("curve_ids"))),x$curve_ids)
  expect_false(isTRUE(reticulate::py_to_r(py$package_version_match)))
})

test_that("typed and empty portable metadata preserve cells and source order",{
  skip_if_not_installed("zip")
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  x<-.etr_portable_writer_fixture()
  x$metadata<-data.frame(
    label=c("\u03ac\u03bb\u03c6\u03b1","\u03b2"),
    flag=c(TRUE,FALSE), trial=c(-1L,2L), value=c(1,NA_real_),
    nullable_text=c("\u03b2",NA_character_), nullable_flag=c(NA,FALSE),
    all_missing=rep(NA,2L))
  dest<-tempfile("native_typed_portable_")
  empty<-tempfile("native_empty_portable_")
  on.exit(unlink(c(dest,empty),recursive=TRUE),add=TRUE)
  etr_export_python_portable_result(x,dest)
  y<-etr_read_python_portable_result(dest)
  metadata<-y$payload$metadata
  expect_identical(names(metadata),names(x$metadata))
  expect_identical(unname(unlist(attr(metadata,"python_index"))),x$curve_ids)
  for(column in names(x$metadata))
    expect_equal(metadata[[column]],x$metadata[[column]],tolerance=0)
  manifest_metadata<-y$manifest$payload$fields$metadata
  expect_null(names(manifest_metadata$data))
  expect_identical(vapply(manifest_metadata$data,function(column)
    column[["__portable_type__"]],character(1L)),
    c(rep("ndarray",4L),rep("object_array",3L)))
  expect_identical(vapply(manifest_metadata$data[1:4],function(column)
    column$dtype,character(1L)),c("<U4","bool","int32","float64"))
  bad<-x
  bad$metadata$matrix<-I(matrix(1:4,nrow=2L))
  expect_error(etr_export_python_portable_result(bad,tempfile()),
    "unsupported metadata column")

  x$metadata<-data.frame(row.names=seq_along(x$curve_ids))
  etr_export_python_portable_result(x,empty)
  expect_identical(dim(etr_read_python_portable_result(empty)$payload$metadata),
    c(2L,0L))

  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 typed portable metadata oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  np<-reticulate::import("numpy",convert=FALSE)
  pd<-reticulate::import("pandas",convert=FALSE)
  index<-as.list(x$curve_ids)
  reference<-pd$DataFrame(list(
    label=np$array(list("\u03ac\u03bb\u03c6\u03b1","\u03b2"),dtype="<U4"),
    flag=np$array(list(TRUE,FALSE),dtype="bool"),
    trial=np$array(list(-1L,2L),dtype="int32"),
    value=np$array(list(1,np$nan),dtype="float64"),
    nullable_text=np$array(list("\u03b2",NULL),dtype="object"),
    nullable_flag=np$array(list(NULL,FALSE),dtype="object"),
    all_missing=np$array(list(NULL,NULL),dtype="object")),index=index)
  py_load<-etpy_get_export("load_portable_result")
  source<-reticulate::py_call(py_load,directory=dest)
  expect_null(reticulate::py_to_r(
    pd$testing$assert_frame_equal(source$payload$get("metadata"),reference)))
  source_empty<-reticulate::py_call(py_load,directory=empty)
  expect_null(reticulate::py_to_r(pd$testing$assert_frame_equal(
    source_empty$payload$get("metadata"),pd$DataFrame(index=index))))
})

# Actual pinned-Python 1.2 public export and source-signature witness.
# This verifies callable/source availability, NOT native scientific parity.
test_that("unreviewed Python 1.2 source symbols are inspectable: export_portable_result",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python source-symbol audit requires source runtime")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("export_portable_result"),"export_portable_result")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
