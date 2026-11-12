# Source: eyetrajectoriespy 1.2.0 portable_results.py capture_environment().
# Native R runtime capture; Python interpreter and package-version fields
# necessarily differ. This is a named native analogue, NOT a certified
# one-to-one Python environment contract.
.etr_env_scalar <- function(x){
  if(length(x)!=1L || is.na(x) || !nzchar(as.character(x)))
    return(NULL)
  as.character(x)
}

#' Capture a native R scientific reproducibility environment
#'
#' Records the R interpreter, platform, package and relevant thread settings.
#' Unlike Python capture_environment(), this does not claim a Python
#' executable or Python dependency versions when Python is unavailable.
#' @param strict_source_record FALSE (default) preserves the existing
#'   native R environment record unchanged. TRUE returns an explicitly
#'   source-mapped scientific reproducibility record with exact Python
#'   source field names, actual R interpreter/dependency measurements,
#'   and the source runtime-language differences transparently recorded.
#' @param python_source_snapshot Optional actual Python 1.2
#'   `capture_environment()` record captured EXTERNALLY; validated
#'   against exact source keys and scientific metadata without importing
#'   Python or inventing interpreter/dependency values. Requires
#'   `strict_source_record=TRUE`.
#' @return Named schema-versioned reproducibility record, or an
#'   inspectable source-scientific R/Python environment comparison. The
#'   default report captures R runtime facts, not a Python interpreter.
#' @export
etr_capture_environment <- function(strict_source_record=FALSE,
    python_source_snapshot=NULL){
  .etr_assert(is.logical(strict_source_record)&&
    length(strict_source_record)==1L&&!is.na(strict_source_record),
    "strict_source_record must be a nonmissing logical scalar")
  if(isTRUE(strict_source_record))
    return(.etr_capture_environment_source_scientific(
      python_source_snapshot=python_source_snapshot))
  .etr_assert(is.null(python_source_snapshot),
    "python_source_snapshot is only accepted with strict_source_record=TRUE")
  info<-Sys.info()
  package_version<-tryCatch(as.character(utils::packageVersion("eyetrajectories")),
    error=function(e){
      d<-tryCatch(read.dcf("DESCRIPTION",fields="Version"),
        error=function(e)NA_character_)
      .etr_env_scalar(d)
    })
  local_env<-function(x).etr_env_scalar(Sys.getenv(x,unset=NA_character_))
  dependencies<-c("stats","graphics","utils","methods","parallel")
  optional<-c("jsonlite","reticulate","ggplot2","fdapace","fda")
  version_of<-function(name){
    if(!requireNamespace(name,quietly=TRUE))return(NULL)
    as.character(utils::packageVersion(name))
  }
  named_versions<-function(names){
    out<-lapply(names,version_of);names(out)<-names;out
  }
  cpu<-suppressWarnings(parallel::detectCores(logical=TRUE))
  list(
    schema_version=1L,
    captured_at_utc=format(Sys.time(),"%Y-%m-%dT%H:%M:%OS6+00:00",tz="UTC"),
    package=list(name="eyetrajectories",version=package_version,
      git_commit=.etr_env_scalar(Sys.getenv("GITHUB_SHA",unset=NA_character_))),
    r=list(version=as.character(getRversion()),
      implementation="GNU R",executable=R.home("bin")),
    platform=list(system=.etr_env_scalar(info[["sysname"]]),
      release=.etr_env_scalar(info[["release"]]),
      machine=.etr_env_scalar(info[["machine"]]),
      platform=.etr_env_scalar(R.version$platform),
      processor=.etr_env_scalar(info[["machine"]]),
      logical_cpu_count=if(length(cpu)==1L && is.finite(cpu))as.integer(cpu) else NULL),
    dependencies=named_versions(dependencies),
    optional_backends=named_versions(optional),
    numerical_thread_environment=setNames(lapply(c(
      "OMP_NUM_THREADS","OPENBLAS_NUM_THREADS","MKL_NUM_THREADS",
      "NUMEXPR_NUM_THREADS"),local_env),
      c("OMP_NUM_THREADS","OPENBLAS_NUM_THREADS","MKL_NUM_THREADS",
        "NUMEXPR_NUM_THREADS")))
}
