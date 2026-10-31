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
  expect_identical(as.character(reticulate::py_to_r(
    py$payload$get("curve_ids"))),x$curve_ids)
  expect_false(isTRUE(reticulate::py_to_r(py$package_version_match)))
})
