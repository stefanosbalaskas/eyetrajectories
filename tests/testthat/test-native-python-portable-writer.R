# Python 1.2 JSON and NPZ interoperability for native scientific results.
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

.etr_portable_functional_fixtures <- function() {
  time <- c(0,.11,.34,.56,.83,1)
  ids <- paste0("curve-",1:5)
  values <- array(0,c(length(ids),length(time),3L))
  for(i in seq_along(ids)) {
    values[i,,1L] <- sin(pi*time+i*.43)+i*.17
    values[i,,2L] <- cos(2*pi*time+i*.26)-i*.07
    values[i,,3L] <- sin(pi*time*i/2)+i*.09
  }
  metadata <- data.frame(group=c("a","b","b","c","c"),
    trial=seq_along(ids),valid=c(TRUE,NA,TRUE,FALSE,TRUE))
  dense <- etr_trajectory_set(time,values,ids,c("x","y","z"),metadata,
    coordinate_system="pixels",time_unit="ms")
  probabilities <- exp(values)
  probabilities <- sweep(probabilities,c(1L,2L),
    apply(probabilities,c(1L,2L),sum),"/")
  simplex <- etr_trajectory_set(time,probabilities,ids,c("a","b","c"),
    metadata,coordinate_system="probability_simplex",time_unit="ms")
  irregular <- etr_irregular_trajectory_set(
    time=list(c(0,.25,1),c(0,.1,.8,1)),
    values=list(matrix(c(1,NA,3,4,NaN,6),3L),matrix(1:8,4L)),
    curve_ids=ids[1:2],dimension_names=c("x","y"),metadata=metadata[1:2,],
    coordinate_system="pixels",time_unit="ms",provenance=list(
      instrument="native",settings=list(filtered=FALSE,reason=NULL)))
  list(IrregularTrajectorySet=irregular,
    FPCAResult=etr_fit_mfpca(dense,n_components=2L,scaling="dimension_sd"),
    CompositionalFPCAResult=etr_fit_compositional_fpca(simplex,
      reference_dimension=1L,epsilon=1e-6,n_components=2L))
}

.etr_expect_portable_fpca <- function(payload,fit) {
  expect_setequal(names(payload),c("__python_type__","mean","components",
    "scores","explained_variance","explained_variance_ratio","time",
    "dimension_names","coordinate_system","time_unit","curve_ids",
    "weights","scale","provenance","model"))
  for(name in c("mean","components","scores"))
    expect_equal(payload[[name]],unname(fit[[name]]),tolerance=0)
  for(name in c("time","explained_variance","explained_variance_ratio",
    "weights","scale"))
    expect_equal(as.vector(payload[[name]]),unname(fit[[name]]),tolerance=0)
  expect_identical(unlist(payload$curve_ids,use.names=FALSE),fit$curve_ids)
  expect_identical(unlist(payload$dimension_names,use.names=FALSE),
    fit$dimension_names)
  expect_identical(payload$coordinate_system,fit$coordinate_system)
  expect_identical(payload$time_unit,fit$time_unit)
  expect_identical(payload$provenance$native_r_fpca$n_components,fit$n_components)
  expect_identical(payload$provenance$native_r_fpca$scaling,fit$scaling)
  expect_equal(payload$provenance$native_r_fpca$total_variance,
    fit$total_variance,tolerance=1e-15)
  expect_null(payload$model)
}

.etr_expect_portable_functional <- function(snapshot,result,type) {
  payload <- snapshot$payload
  expect_identical(snapshot$result_type,paste0("eyetrajectoriespy.types.",type))
  expect_identical(payload[["__python_type__"]],snapshot$result_type)
  expect_null(snapshot$environment)
  expect_length(snapshot$nonportable_fields,0L)
  if(type=="IrregularTrajectorySet") {
    expect_setequal(names(payload),c("__python_type__","time","values",
      "curve_ids","dimension_names","metadata","coordinate_system",
      "time_unit","provenance"))
    expect_s3_class(payload$time,"etr_python_tuple")
    expect_s3_class(payload$values,"etr_python_tuple")
    expect_identical(lapply(payload$time,as.vector),result$time)
    expect_equal(unclass(payload$values),result$values,tolerance=0)
    expect_identical(lapply(payload$values,is.nan),lapply(result$values,is.nan))
    expect_identical(unlist(payload$curve_ids,use.names=FALSE),result$curve_ids)
    expect_identical(unlist(payload$dimension_names,use.names=FALSE),
      result$dimension_names)
    expect_identical(names(payload$metadata),names(result$metadata))
    expect_identical(unlist(attr(payload$metadata,"python_index")),result$curve_ids)
    for(name in names(result$metadata))
      expect_equal(payload$metadata[[name]],result$metadata[[name]],tolerance=0)
    expect_identical(payload$provenance,result$provenance)
  } else if(type=="FPCAResult") {
    .etr_expect_portable_fpca(payload,result)
  } else {
    expect_setequal(names(payload),c("__python_type__","fpca",
      "reference_dimension","original_dimension_names","epsilon","provenance"))
    .etr_expect_portable_fpca(payload$fpca,result$fpca)
    expect_identical(payload$reference_dimension,result$reference_dimension)
    expect_identical(unlist(payload$original_dimension_names,use.names=FALSE),
      result$original_dimension_names)
    expect_equal(payload$epsilon,result$epsilon,tolerance=0)
    expect_identical(payload$provenance,result$provenance)
    expect_length(snapshot$units,0L)
  }
  if(type!="CompositionalFPCAResult") {
    expect_identical(snapshot$units$coordinate_system,result$coordinate_system)
    expect_identical(snapshot$units$time_unit,result$time_unit)
  }
}

test_that("native portable functional results retain shapes, labels and fitted state",{
  skip_if_not_installed("zip")
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  root <- tempfile("native_functional_portable_")
  on.exit(unlink(root,recursive=TRUE),add=TRUE)
  fixtures <- .etr_portable_functional_fixtures()
  for(type in names(fixtures)) {
    dest <- file.path(root,type)
    etr_export_python_portable_result(fixtures[[type]],dest)
    .etr_expect_portable_functional(etr_read_python_portable_result(dest),
      fixtures[[type]],type)
  }
  empty <- file.path(root,"empty_destination")
  dir.create(empty)
  etr_export_python_portable_result(fixtures$FPCAResult,empty)
  expect_identical(list.files(empty,all.files=TRUE,no..=TRUE),
    c("arrays.npz","manifest.json"))
  invalid <- fixtures$FPCAResult
  invalid$scores <- invalid$scores[-1L,]
  failed <- file.path(root,"rejected")
  expect_error(etr_export_python_portable_result(invalid,failed),"FPCA array scores")
  expect_false(file.exists(failed))
  invalid <- fixtures$CompositionalFPCAResult
  invalid$reference_dimension <- 3L
  expect_error(etr_export_python_portable_result(invalid,failed),
    "compositional FPCA dimensions")
  expect_false(file.exists(failed))
})

test_that("the native binary writer preserves Python boundary nonfinite values",{
  skip_if_not_installed("zip")
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  values <- array(c(0,NaN,Inf,-Inf),c(1L,4L,1L))
  trajectories <- etr_trajectory_set(0:3,values,"a","x",python_boundary_mode=TRUE)
  dest <- tempfile("native_nonfinite_portable_")
  on.exit(unlink(dest,recursive=TRUE),add=TRUE)
  etr_export_python_portable_result(trajectories,dest)
  expect_identical(etr_read_python_portable_result(dest)$payload$values,values)
  if(identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true")) {
    loaded <- reticulate::py_call(etpy_get_export("load_portable_result"),
      directory=dest)
    expect_identical(reticulate::py_to_r(loaded$payload$get("values")),values)
  }
})

test_that("frozen Python loads and re-exports native functional result schemas",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python functional result portability oracle is opt-in")
  skip_if_not_installed("zip")
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  expect_identical(et_python_version(),"1.2.0")
  oracle <- reticulate::py_run_string(paste(c(
    "from dataclasses import fields",
    "import eyetrajectoriespy as et",
    "import numpy as np",
    "def reexport(native_path, source_path, et=et, np=np, fields=fields):",
    "    def typed_result(payload):",
    "        name = payload['__python_type__'].rsplit('.', 1)[-1]",
    "        cls = getattr(et, name)",
    "        args = {k: v for k, v in payload.items() if k != '__python_type__'}",
    "        assert list(args) == [f.name for f in fields(cls)]",
    "        if name == 'IrregularTrajectorySet':",
    "            assert isinstance(args['time'], tuple) and isinstance(args['values'], tuple)",
    "            assert [x.shape for x in args['time']] == [(3,), (4,)]",
    "            assert [x.shape for x in args['values']] == [(3, 2), (4, 2)]",
    "            assert all(x.dtype == np.float64 for x in args['values'])",
    "            assert list(args['metadata'].index) == list(args['curve_ids'])",
    "        if name == 'FPCAResult':",
    "            assert args['model'] is None",
    "            assert isinstance(args['curve_ids'], tuple)",
    "            assert isinstance(args['dimension_names'], tuple)",
    "            assert args['scores'].dtype == np.float64",
    "        if name == 'CompositionalFPCAResult':",
    "            args['fpca'] = typed_result(args['fpca'])",
    "        return cls(**args)",
    "    snapshot = et.load_portable_result(native_path)",
    "    result = typed_result(snapshot.payload)",
    "    assert not snapshot.package_version_match",
    "    assert snapshot.environment is None and not snapshot.nonportable_fields",
    "    et.export_portable_result(result, source_path, include_environment=False)"
  ),collapse="\n"),local=TRUE,convert=FALSE)
  root <- tempfile("two_way_portable_")
  on.exit(unlink(root,recursive=TRUE),add=TRUE)
  fixtures <- .etr_portable_functional_fixtures()
  for(type in names(fixtures)) {
    native <- file.path(root,paste0(type,"-native"))
    source <- file.path(root,paste0(type,"-source"))
    etr_export_python_portable_result(fixtures[[type]],native)
    oracle$reexport(native,source)
    snapshot <- etr_read_python_portable_result(source)
    expect_identical(snapshot$source_package_version,"1.2.0")
    .etr_expect_portable_functional(snapshot,fixtures[[type]],type)
  }
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
