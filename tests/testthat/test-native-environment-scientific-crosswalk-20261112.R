# Frozen Python 1.2 portable_results.py::capture_environment.
# Source-scientific reproducibility record for real native R runtime only.
# The source Python environment is a separate actual external attestation.

.etr_env_source_sample<-function(){
  list(
    schema_version=1L,
    captured_at_utc="2026-11-12T11:12:13.123456+00:00",
    package=list(name="eyetrajectoriespy",version="1.2.0",
      git_commit="c1cd95ad718327550f7e55393ff38582872f7a94"),
    python=list(version="3.12.6",implementation="CPython",
      executable="/usr/bin/python3.12"),
    platform=list(system="Linux",release="6.0",
      machine="x86_64",platform="Linux-6.0-x86_64",
      processor=NULL,logical_cpu_count=8L),
    dependencies=list(numpy="2.3.5",pandas="2.3.3",scipy="1.16.3",
      `scikit-learn`="1.7.2",matplotlib="3.10.7",
      statsmodels="0.14.5"),
    optional_backends=list(`scikit-fda`=NULL,FDApy=NULL,fdasrsf=NULL),
    numerical_thread_environment=list(OMP_NUM_THREADS=NULL,
      OPENBLAS_NUM_THREADS="1",MKL_NUM_THREADS=NULL,
      NUMEXPR_NUM_THREADS=NULL))
}

test_that("default native R environment remains a real measured local runtime",{
  original<-etr_capture_environment()
  expect_identical(names(original),
    c("schema_version","captured_at_utc","package","r",
      "platform","dependencies","optional_backends",
      "numerical_thread_environment"))
  expect_identical(original$schema_version,1L)
  expect_identical(original$package$name,"eyetrajectories")
  expect_identical(original$r$implementation,"GNU R")
  expect_identical(original$r$version,as.character(getRversion()))
  expect_equal(original$r$executable,R.home("bin"),tolerance=0)
  expect_identical(
    names(original$numerical_thread_environment),
    c("OMP_NUM_THREADS","OPENBLAS_NUM_THREADS","MKL_NUM_THREADS",
      "NUMEXPR_NUM_THREADS"))
  expect_false("python"%in%names(original))
  expect_false("scientific_crosswalk"%in%names(original))
})

test_that("opt-in source environment maps exact frozen fields without inventing Python dependency facts",{
  before<-reticulate::py_available(initialize=FALSE)
  got<-etr_capture_environment(strict_source_record=TRUE)
  expect_identical(reticulate::py_available(initialize=FALSE),before)
  expect_s3_class(got,"etr_native_environment_scientific_record")
  expect_s3_class(got,"etr_native_reproducibility_record")
  expect_identical(got$native_environment$schema_version,1L)
  expect_identical(got$native_environment$package$name,"eyetrajectories")
  expect_identical(got$native_environment$r$implementation,"GNU R")
  expect_identical(got$scientific_crosswalk$runtime,"native_R")
  expect_identical(got$scientific_crosswalk$source_schema_field_order,
    c("schema_version","captured_at_utc","package","python",
      "platform","dependencies","optional_backends",
      "numerical_thread_environment"))
  expect_identical(got$scientific_crosswalk$native_schema_field_order,
    c("schema_version","captured_at_utc","package","r",
      "platform","dependencies","optional_backends",
      "numerical_thread_environment"))
  expect_identical(unname(unlist(
    got$scientific_crosswalk$source_to_native_field_crosswalk)),
    got$scientific_crosswalk$native_schema_field_order)
  expect_identical(
    got$scientific_crosswalk$source_to_native_field_crosswalk$python,"r")
  expect_true(got$scientific_crosswalk$numerical_thread_keys_identical)
  expect_true(got$scientific_crosswalk$runtime_language_substituted_explicitly)
  expect_false(got$scientific_crosswalk$source_python_runtime_observed)
  expect_false(got$scientific_crosswalk$source_python_report_captured_by_R)
  expect_false(got$scientific_crosswalk$python_snapshot_is_external_attestation)
  expect_null(got$original_python_environment)
  expect_false(got$full_Python_runtime_source_parity)
  expect_false(got$independently_source_certified)
  expect_false(got$scientific_crosswalk$source_equivalent)
  expect_false(got$scientific_crosswalk$independently_source_certified)
  expect_false("numpy"%in%names(got$native_environment$dependencies))
  expect_false("FDApy"%in%names(got$native_environment$optional_backends))
  if(!is.null(got$native_R_executable_path))
    expect_true(file.exists(got$native_R_executable_path))
})

test_that("externally observed source environment is structurally validated and preserved exactly",{
  src<-.etr_env_source_sample()
  .etr_env_source_validate_python_snapshot(src)
  got<-etr_capture_environment(strict_source_record=TRUE,
    python_source_snapshot=src)
  expect_identical(got$original_python_environment,src)
  expect_identical(got$original_python_environment$python$version,
    "3.12.6")
  expect_identical(got$original_python_environment$dependencies$numpy,
    "2.3.5")
  expect_identical(got$native_environment$package$name,"eyetrajectories")
  expect_true(got$scientific_crosswalk$python_snapshot_is_external_attestation)
  expect_true(got$scientific_crosswalk$source_python_runtime_observed)
  expect_false(got$scientific_crosswalk$source_python_report_captured_by_R)
  expect_false(got$full_Python_runtime_source_parity)
  # The native capture and Python snapshot cannot be silently conflated.
  expect_false(identical(got$native_environment$package$name,
    got$original_python_environment$package$name))
})

test_that("source Python snapshot excludes missing source keys and fabricated Python interpreter facts",{
  src<-.etr_env_source_sample()
  expect_error(etr_capture_environment(strict_source_record=NA),
    "strict_source_record")
  expect_error(etr_capture_environment(strict_source_record=1L),
    "strict_source_record")
  expect_error(etr_capture_environment(python_source_snapshot=src),
    "only accepted")
  bad<-src;bad$python<-NULL
  expect_error(etr_capture_environment(strict_source_record=TRUE,
    python_source_snapshot=bad),"exact ordered")
  bad<-src;bad$package$name<-"eyetrajectories"
  expect_error(etr_capture_environment(strict_source_record=TRUE,
    python_source_snapshot=bad),"eyetrajectoriespy")
  bad<-src;bad$captured_at_utc<-"2026-11-12T11:12:13"
  expect_error(etr_capture_environment(strict_source_record=TRUE,
    python_source_snapshot=bad),"UTC ISO")
  bad<-src;bad$dependencies$numpy<-1.2
  expect_error(etr_capture_environment(strict_source_record=TRUE,
    python_source_snapshot=bad),"strings or missing")
  bad<-src;bad$optional_backends<-list(FDApy=NULL)
  expect_error(etr_capture_environment(strict_source_record=TRUE,
    python_source_snapshot=bad),"exact ordered")
  bad<-src;bad$numerical_thread_environment$OMP_NUM_THREADS<-TRUE
  expect_error(etr_capture_environment(strict_source_record=TRUE,
    python_source_snapshot=bad),"strings or missing")
  bad<-src;bad$schema_version<-2L
  expect_error(etr_capture_environment(strict_source_record=TRUE,
    python_source_snapshot=bad),"schema_version")
})

test_that("actual frozen Python 1.2 capture_environment has the exact pinned schema and is retained without Python invocation by native R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("real frozen Python 1.2 environment differential is opt-in")
  skip_if_not_installed("reticulate")
  expect_identical(et_python_version(),"1.2.0")
  # The genuine frozen source function produces this separate independent
  # actual Python runtime report; the native R scientific capture does
  # NOT cause a Python import/call, nor invent any Python version.
  reticulate::py_run_string("
import eyetrajectoriespy as et
frozen_source_environment=et.capture_environment()
assert frozen_source_environment['schema_version']==1
assert frozen_source_environment['package']['name']=='eyetrajectoriespy'
")
  src<-reticulate::py_eval("frozen_source_environment",convert=TRUE)
  expect_silent(.etr_env_source_validate_python_snapshot(src))
  got<-etr_capture_environment(strict_source_record=TRUE,
    python_source_snapshot=src)
  expect_identical(got$original_python_environment,src)
  expect_identical(got$original_python_environment$package$name,
    "eyetrajectoriespy")
  expect_identical(got$original_python_environment$package$version,
    "1.2.0")
  expect_identical(got$native_environment$package$name,
    "eyetrajectories")
  expect_false(got$full_Python_runtime_source_parity)
  expect_false(got$independently_source_certified)
})
