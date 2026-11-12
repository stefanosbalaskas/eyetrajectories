# Source-scientific cross-runtime reproducibility reporting.
# Frozen Python 1.2 portable_results.py::capture_environment,
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
#
# Native R cannot truthfully report a Python interpreter, Python package
# distributions or a Python process: these values are never fabricated.
# The scientific task here is R-runtime environment capture plus validation
# and immutable retention of an OPTIONAL genuine Python source snapshot.
# No Python process, reticulate or subprocess is called.

.etr_env_source_string_or_null <- function(x) {
  is.null(x)||
    (is.character(x)&&length(x)==1L&&!is.na(x))
}

.etr_env_source_require_named_list <- function(x,keys,where) {
  .etr_assert(is.list(x)&&
    identical(names(x),keys),
    paste0(where," must have the exact ordered frozen Python 1.2 source keys"))
  invisible(TRUE)
}

.etr_env_source_validate_python_snapshot <- function(x) {
  .etr_env_source_require_named_list(x,
    c("schema_version","captured_at_utc","package",
      "python","platform","dependencies","optional_backends",
      "numerical_thread_environment"),
    "source Python environment")
  .etr_assert(is.numeric(x$schema_version)&&
    length(x$schema_version)==1L&&
    is.finite(x$schema_version)&&x$schema_version==1L,
    "source Python environment schema_version must equal 1")
  .etr_assert(is.character(x$captured_at_utc)&&
    length(x$captured_at_utc)==1L&&
    !is.na(x$captured_at_utc)&&
    grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]+)?\\+00:00$",
      x$captured_at_utc),
    "source Python environment must contain a timezone-aware UTC ISO 8601 timestamp")
  .etr_env_source_require_named_list(x$package,
    c("name","version","git_commit"),
    "source Python package")
  .etr_assert(identical(x$package$name,"eyetrajectoriespy")&&
    is.character(x$package$version)&&
    length(x$package$version)==1L&&
    !is.na(x$package$version)&&
    nzchar(x$package$version)&&
    .etr_env_source_string_or_null(x$package$git_commit),
    "source Python package must identify eyetrajectoriespy and its source version")
  .etr_env_source_require_named_list(x$python,
    c("version","implementation","executable"),
    "source Python runtime")
  .etr_assert(all(vapply(x$python,function(v)
    is.character(v)&&length(v)==1L&&
    !is.na(v)&&nzchar(v),logical(1L))),
    "source Python interpreter version, implementation and executable must be recorded")
  .etr_env_source_require_named_list(x$platform,
    c("system","release","machine","platform","processor",
      "logical_cpu_count"),
    "source Python platform")
  .etr_assert(all(vapply(x$platform[c(
    "system","release","machine","platform")],
    function(v)is.character(v)&&length(v)==1L&&!is.na(v),logical(1L)))&&
    .etr_env_source_string_or_null(x$platform$processor)&&
    (is.null(x$platform$logical_cpu_count)||
      (is.numeric(x$platform$logical_cpu_count)&&
        length(x$platform$logical_cpu_count)==1L&&
        is.finite(x$platform$logical_cpu_count)&&
        x$platform$logical_cpu_count>=1L&&
        x$platform$logical_cpu_count==floor(x$platform$logical_cpu_count))),
    "source Python platform must have valid platform and logical CPU information")
  .etr_env_source_require_named_list(x$dependencies,
    c("numpy","pandas","scipy","scikit-learn",
      "matplotlib","statsmodels"),
    "source Python core dependencies")
  .etr_env_source_require_named_list(x$optional_backends,
    c("scikit-fda","FDApy","fdasrsf"),
    "source Python optional backends")
  .etr_env_source_require_named_list(x$numerical_thread_environment,
    c("OMP_NUM_THREADS","OPENBLAS_NUM_THREADS",
      "MKL_NUM_THREADS","NUMEXPR_NUM_THREADS"),
    "source Python numerical thread environment")
  for(group in c("dependencies","optional_backends",
    "numerical_thread_environment")) {
    .etr_assert(all(vapply(x[[group]],
      .etr_env_source_string_or_null,logical(1L))),
      paste0("source Python ",group,
        " values must be strings or missing (None/NULL)"))
  }
  invisible(TRUE)
}

.etr_capture_environment_source_scientific <- function(
    python_source_snapshot=NULL) {
  # Reuse the existing native-R scientific runtime capture exactly, not
  # a fictional Python interpreter or guessed third-party distributions.
  native<-etr_capture_environment()
  source_keys<-c("schema_version","captured_at_utc","package",
    "python","platform","dependencies","optional_backends",
    "numerical_thread_environment")
  r_keys<-c("schema_version","captured_at_utc","package",
    "r","platform","dependencies","optional_backends",
    "numerical_thread_environment")
  .etr_assert(identical(names(native),r_keys)&&
    identical(native$schema_version,1L),
    "native R runtime capture is not the expected version-one reproducibility schema")
  .etr_assert(identical(
    names(native$numerical_thread_environment),
    c("OMP_NUM_THREADS","OPENBLAS_NUM_THREADS",
      "MKL_NUM_THREADS","NUMEXPR_NUM_THREADS")),
    "native R numerical thread settings cannot be aligned to Python scientific source keys")
  .etr_assert(identical(native$package$name,"eyetrajectories")&&
    identical(native$r$implementation,"GNU R")&&
    is.character(native$r$version)&&
    length(native$r$version)==1L,
    "source scientific record must capture actual R package and interpreter identity")
  if(!is.null(python_source_snapshot))
    .etr_env_source_validate_python_snapshot(python_source_snapshot)
  native_keys<-names(native)
  # R's R.home("bin") is a directory; the ordinary record remains
  # intentionally unchanged for backwards compatibility. The strict
  # scientific record separately resolves an executable candidate.
  executable_path<-file.path(R.home("bin"),
    if(.Platform$OS.type=="windows")"R.exe" else "R")
  executable_known<-file.exists(executable_path)
  if(!executable_known)
    executable_path<-NULL
  # Preserve NULL-valued Python source snapshot only when real evidence is
  # supplied. Never populate missing Python metadata from local R facts.
  provenance<-list(
    runtime="native_R",
    source_public_python_symbol="capture_environment",
    frozen_python_commit=
      "c1cd95ad718327550f7e55393ff38582872f7a94",
    source_schema_version=1L,
    source_schema_field_order=source_keys,
    native_schema_field_order=native_keys,
    source_to_native_field_crosswalk=setNames(
      as.list(r_keys),source_keys),
    numerical_thread_keys_identical=TRUE,
    runtime_language_substituted_explicitly=TRUE,
    source_python_runtime_observed=
      !is.null(python_source_snapshot),
    source_python_report_captured_by_R=FALSE,
    python_snapshot_is_external_attestation=
      !is.null(python_source_snapshot),
    source_equivalent=FALSE,
    independently_source_certified=FALSE)
  structure(list(
    native_environment=native,
    native_R_executable_path=executable_path,
    original_python_environment=python_source_snapshot,
    scientific_crosswalk=provenance,
    source_scientific_scope="native_R_reproducibility_capture_with_optional_verified_Python_source_snapshot",
    full_Python_runtime_source_parity=FALSE,
    independently_source_certified=FALSE),
    class=c("etr_native_environment_scientific_record",
      "etr_native_reproducibility_record","list"))
}
