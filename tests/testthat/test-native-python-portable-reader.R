# Stage 6: native R read-only interoperability with Python 1.2 JSON + NPZ.
# These tests never call Python unless ET_RUN_PYTHON_TESTS="true".

test_that("NumPy v1 header is parsed without Python execution", {
  private <- eyetrajectories:::.etr_npy_header
  dictionary <- "{'descr': '<f8', 'fortran_order': False, 'shape': (2, 3), }"
  padding <- (16L-(10L+nchar(dictionary,type="bytes")+1L)%%16L)%%16L
  hdr <- paste0(dictionary,strrep(" ",padding),"\n")
  raw_header <- c(as.raw(c(147,78,85,77,80,89,1,0)),
                  as.raw(c(nchar(hdr,type="bytes")%%256,
                    nchar(hdr,type="bytes")%/%256)),charToRaw(hdr))
  con <- rawConnection(raw_header,open="rb")
  on.exit(close(con),add=TRUE)
  record <- private(con)
  expect_identical(record$descr,"<f8")
  expect_false(record$fortran)
  expect_equal(record$shape,c(2,3))
  expect_error(
    {bad <- rawConnection(charToRaw("not npy"),open="rb")
     on.exit(close(bad),add=TRUE)
     private(bad)},
    "magic")
})

test_that("native 64-bit NumPy integer parser preserves safe exact values", {
  fn <- eyetrajectories:::.etr_npy_decode_u64
  mk <- function(number) {
    signed <- if(number<0) number+2^64 else number
    # Simple hand-built little-endian int64 known-bit fixtures
    if(number==0)return(as.raw(rep(0,8)))
    if(number==1)return(as.raw(c(1,rep(0,7))))
    if(number==-1)return(as.raw(rep(255,8)))
    if(number==9007199254740992)return(
      as.raw(c(0,0,0,0,0,0,32,0)))
    stop("unsupported fixture")
  }
  blob <- do.call(c,lapply(c(0,1,-1,9007199254740992),mk))
  expect_equal(fn(blob),c(0,1,-1,9007199254740992))
  expect_equal(fn(as.raw(rep(0,0))),numeric(0))
  expect_error(fn(as.raw(1:3)),"truncated")
  expect_error(fn(as.raw(c(255,255,255,255,255,255,255,127))),
               "exact")
})

test_that("typed JSON portable decoding rejects unsafe markers", {
  decode <- eyetrajectories:::.etr_portable_decode
  expect_equal(decode(list('__portable_type__'="mapping",
    entries=list(list("foo",1L),list("nested",
      list('__portable_type__'="tuple",items=list(TRUE,"item")))))),
    list(foo=1L,nested=structure(list(TRUE,"item"),
                                class="etr_python_tuple")))
  expect_equal(decode(list('__portable_type__'="dataclass",
    python_type="eyetrajectoriespy.types.Example",
    fields=list(answer=42L,kind="snapshot"))),list(
    '__python_type__'="eyetrajectoriespy.types.Example",
    answer=42L,kind="snapshot"))
  expect_equal(as.vector(decode(list('__portable_type__'="object_array",
    shape=list(2L),items=list("alpha","beta")))),
    c("alpha","beta"))
  expect_error(decode(list('__portable_type__'="object_array",
    shape=list(2L),items=list(list(a=1),list(a=2)))),
    "heterogeneous|nonscalar")
  expect_error(decode(list('__portable_type__'="unknown")),
               "unsupported")
  expect_error(decode(list('__portable_type__'="ndarray",
    key="missing",shape=list(1L))),"missing NumPy")
})

test_that("portable reader rejects invalid paths and manifest formats", {
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  expect_error(etr_read_python_portable_result(tempdir()==""),"directory")
  d <- tempfile("native_python_portable_")
  dir.create(d)
  on.exit(unlink(d,recursive=TRUE),add=TRUE)
  expect_error(etr_read_python_portable_result(d),"manifest")
  jsonlite::write_json(list(format="bad",schema_version=1L),
                       file.path(d,"manifest.json"),auto_unbox=TRUE)
  expect_error(etr_read_python_portable_result(d),"format|schema")
  jsonlite::write_json(list(
    format="eyetrajectoriespy-portable-scientific-result",
    schema_version=1L,arrays_file="../escape.npz",
    arrays_sha256=paste(rep("0",64),collapse="")),
    file.path(d,"manifest.json"),auto_unbox=TRUE)
  expect_error(etr_read_python_portable_result(d),"archive path")
})

test_that("Python 1.2 exports are readable and verified without Python", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Independent Python 1.2 JSON+NPZ portable archive oracle is opt-in")
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  expect_identical(as.character(et_python_version()),"1.2.0")
  py_ctor <- etpy_get_export("TrajectorySet")
  py_export <- etpy_get_export("export_portable_result")
  py_load <- etpy_get_export("load_portable_result")
  pandas <- reticulate::import("pandas",convert=FALSE)

  for(scenario in seq_len(3L)){
    n <- if(scenario==1L)1L else 2L
    nt <- 4L+scenario
    time <- c(0,cumsum(rep(.2,nt-1L)))
    values <- array(seq_len(n*nt*2L)/10,c(n,nt,2L))
    if(scenario==3L)values[1L,3L,1L] <- NA_real_
    metadata <- data.frame(
      subject=paste0("P",seq_len(n)),trial=seq_len(n),
      stringsAsFactors=FALSE)
    ids <- paste0("gaze",seq_len(n))
    x <- etr_trajectory_set(time,values,ids,c("x","y"),
                            metadata=metadata,
                            coordinate_system="pixels",time_unit="ms",
                            provenance=list(source="stage6",
                              scenario=scenario))
    py_metadata <- pandas$DataFrame(reticulate::r_to_py(metadata))
    py <- reticulate::py_call(py_ctor,
      time=time,values=reticulate::r_to_py(values),
      curve_ids=as.list(ids),dimension_names=list("x","y"),
      metadata=py_metadata,
      coordinate_system="pixels",time_unit="ms",
      provenance=reticulate::r_to_py(x$provenance))
    folder <- tempfile(paste0("python_result_",scenario,"_"))
    on.exit(unlink(folder,recursive=TRUE),add=TRUE)
    reticulate::py_call(py_export,result=py,
      directory=folder,include_environment=FALSE)
    loaded <- etr_read_python_portable_result(folder)
    expect_s3_class(loaded,"etr_python_portable_snapshot")
    expect_true(grepl("TrajectorySet$",loaded$result_type))
    expect_identical(loaded$source_package_version,"1.2.0")
    expect_true(grepl("^[a-f0-9]{64}$",loaded$arrays_sha256))
    expect_identical(loaded$payload$'__python_type__',
                     loaded$result_type)
    expect_equal(as.vector(loaded$payload$time),time,tolerance=1e-12)
    expect_identical(dim(loaded$payload$values),dim(values))
    expect_identical(is.na(loaded$payload$values),is.na(values))
    expect_equal(as.vector(loaded$payload$values),as.vector(values),
                 tolerance=1e-12)
    expect_equal(as.character(unlist(loaded$payload$curve_ids)),ids)
    expect_equal(as.character(unlist(loaded$payload$dimension_names)),
                 c("x","y"))
    expect_identical(loaded$payload$metadata$subject,metadata$subject)
    expect_equal(loaded$payload$metadata$trial,metadata$trial)
    expect_identical(loaded$payload$provenance$source,"stage6")
    expect_equal(loaded$payload$provenance$scenario,scenario)
    expect_identical(loaded$units$time_unit,"ms")
    expect_identical(loaded$units$coordinate_system,"pixels")

    # Python's own load_portable_result() independently accepts the
    # source archive. This call is oracle-only, not in R reader code.
    python_loaded <- reticulate::py_call(py_load,directory=folder)
    expect_identical(as.character(et_to_r(
      python_loaded$source_package_version)),"1.2.0")

    # Modify the checksum metadata, not arrays.npz. An invalid digest
    # must fail closed even though the scientific data are still present.
    manifest_file <- file.path(folder,"manifest.json")
    original <- readLines(manifest_file,warn=FALSE)
    original_text <- paste(original,collapse="\n")
    wrong <- sub(loaded$arrays_sha256,
                 paste(rep("0",64),collapse=""),original_text,fixed=TRUE)
    expect_false(identical(original_text,wrong))
    writeLines(wrong,manifest_file,useBytes=TRUE)
    expect_error(etr_read_python_portable_result(folder),
                 "SHA-256 checksum mismatch")
  }
})
