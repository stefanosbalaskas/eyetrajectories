# Read-only triage of the last source-review SHA256 checkout audit.
# Run from repo root: source("scripts/triage_sha256_review_failures.R")
# Optional: Sys.setenv(ET_REVIEW_AUDIT_REPORT="path/to/review_integrity_....csv")
# This does NOT repair any pinned review, test proof, implementation or gate.
# A mismatched proof is never accepted or counted as independently certified.

.etr_triage_review_sha256 <- function() {
  if(!file.exists("DESCRIPTION") ||
     !identical(unname(read.dcf("DESCRIPTION","Package")[1L]),
                "eyetrajectories"))
    stop("Run from the eyetrajectories repository root.",call.=FALSE)

  dir <- file.path("artifacts","review_sha256_checkout_audit")
  selected <- Sys.getenv("ET_REVIEW_AUDIT_REPORT","")
  if(!nzchar(selected)) {
    candidates <- list.files(dir,pattern="^review_integrity_.*\\.csv$",
                             full.names=TRUE)
    if(!length(candidates))
      stop("No integrity audit found; first run ",
           "source('scripts/verify_sha256_review_sources_checkout.R').",
           call.=FALSE)
    selected <- candidates[[which.max(file.info(candidates)$mtime)]]
  }
  if(!file.exists(selected))
    stop("SHA256 integrity audit not found: ",selected,call.=FALSE)
  audit <- utils::read.csv(selected,stringsAsFactors=FALSE,
                           check.names=FALSE,na.strings=c("","NA"))
  needed <- c("python_name","path","source","pinned_sha256",
              "working_file_sha256","lf_normalized_sha256",
              "git_head_blob_sha256","verdict")
  if(!all(needed %in% names(audit)))
    stop("Incomplete or incompatible review SHA256 audit CSV",call.=FALSE)
  if(!nrow(audit) || anyNA(audit$path) || anyNA(audit$python_name) ||
     anyNA(audit$verdict))
    stop("Malformed SHA256 audit rows",call.=FALSE)
  bad <- audit[grepl("^FAIL_",audit$verdict),,drop=FALSE]
  cat("SOURCE_REVIEW_AUDIT_REFERENCES=",nrow(audit),"\n",sep="")
  cat("SOURCE_REVIEW_FAILED_REFERENCES=",nrow(bad),"\n",sep="")
  cat("SOURCE_REVIEW_FAILED_DISTINCT_PATHS=",
      length(unique(bad$path)),"\n",sep="")
  if(!nrow(bad)){
    cat("SOURCE_REVIEW_TRIAGE_NO_FAILURES; certification=FALSE\n")
    return(invisible(NULL))
  }

  git <- Sys.which("git")
  tree_paths <- if(nzchar(git)) {
    tryCatch(suppressWarnings(system2(
      git,c("ls-tree","-r","--name-only","HEAD"),
      stdout=TRUE,stderr=FALSE)),error=function(e)character())
  } else character()
  if(is.null(attr(tree_paths,"status")) ||
     identical(as.integer(attr(tree_paths,"status")),0L)) {
    tree_paths <- gsub("\\\\","/",tree_paths,fixed=TRUE)
  } else tree_paths <- character()
  closest_path <- function(p) {
    if(!length(tree_paths))return("")
    same_area <- tree_paths[dirname(tree_paths)==dirname(p)]
    if(!length(same_area))same_area<-tree_paths
    d <- as.integer(utils::adist(basename(p),basename(same_area)))
    ranked <- order(d,nchar(same_area))
    if(!length(ranked))return("")
    candidate <- same_area[[ranked[[1L]]]]
    if(d[[ranked[[1L]]]]>max(8L,nchar(basename(p))%/%3L))
      return("")
    candidate
  }
  one <- function(path) {
    x <- bad[bad$path==path,,drop=FALSE]
    pins <- unique(x$pinned_sha256[!is.na(x$pinned_sha256)])
    git_sha <- unique(x$git_head_blob_sha256[
      !is.na(x$git_head_blob_sha256)])
    normalized <- unique(x$lf_normalized_sha256[
      !is.na(x$lf_normalized_sha256)])
    missing <- any(x$verdict=="FAIL_MISSING")
    conflict <- length(pins)>1L
    actual <- length(git_sha)==1L && length(pins)==1L &&
              identical(git_sha,pins)
    label <- if(missing) "MISSING_FILE_OR_RENAMED_PROOF"
      else if(conflict) "CONFLICTING_PINNED_HASHES_FOR_SAME_PATH"
      else if(!length(git_sha)) "GIT_HEAD_PROOF_UNAVAILABLE"
      else if(!actual) "PINNED_REVIEW_STALE_VERSUS_GIT_HEAD"
      else if(!any(normalized %in% pins))
        "LOCAL_CONTENT_DIFFERS_BEYOND_CRLF"
      else "AUDIT_VERDICT_NEEDS_RECHECK"
    data.frame(path=path,triage_class=label,
      failed_references=nrow(x),
      affected_contracts=length(unique(x$python_name)),
      pinned_hash_versions=length(pins),
      git_blob_matches_single_pin=actual,
      git_head_contains_path=path %in% tree_paths,
      suggested_rename_candidate=if(missing)closest_path(path)else"",
      contracts=paste(sort(unique(x$python_name)),collapse=" | "),
      stringsAsFactors=FALSE)
  }
  by_path <- do.call(rbind,lapply(unique(bad$path),one))
  by_path <- by_path[order(-by_path$affected_contracts,
                           -by_path$failed_references,
                           by_path$path),,drop=FALSE]
  bad$triage_class <- by_path$triage_class[match(bad$path,by_path$path)]
  contracts <- split(bad,bad$python_name)
  by_contract <- do.call(rbind,lapply(names(contracts),function(name){
    x <- contracts[[name]]
    data.frame(python_name=name,failed_references=nrow(x),
      unique_bad_files=length(unique(x$path)),
      missing_references=sum(x$verdict=="FAIL_MISSING"),
      mismatch_references=sum(x$verdict=="FAIL_PIN_MISMATCH"),
      failed_paths=paste(sort(unique(x$path)),collapse=" | "),
      stringsAsFactors=FALSE)
  }))
  by_contract <- by_contract[order(-by_contract$failed_references,
                                    by_contract$python_name),,drop=FALSE]
  stamp <- format(Sys.time(),"%Y%m%d_%H%M%S")
  base <- file.path(dir,paste0("triage_",stamp,"_",Sys.getpid()))
  files <- c(failed_references=paste0(base,"_references.csv"),
             distinct_paths=paste0(base,"_paths.csv"),
             affected_contracts=paste0(base,"_contracts.csv"))
  utils::write.csv(bad,files[["failed_references"]],row.names=FALSE,na="")
  utils::write.csv(by_path,files[["distinct_paths"]],row.names=FALSE,na="")
  utils::write.csv(by_contract,files[["affected_contracts"]],row.names=FALSE,na="")
  cat("SOURCE_REVIEW_FAILED_CONTRACTS=",nrow(by_contract),"\n",sep="")
  cat("SOURCE_REVIEW_TRIAGE_BY_CLASS:\n")
  print(as.data.frame(table(by_path$triage_class)),row.names=FALSE)
  cat("SOURCE_REVIEW_TOP_DISTINCT_PATHS:\n")
  print(utils::head(by_path[,c("path","triage_class",
                              "affected_contracts","failed_references")],12L),
        row.names=FALSE,right=FALSE)
  for (nm in names(files))
    cat("SOURCE_REVIEW_TRIAGE_",toupper(nm),"=",
        normalizePath(files[[nm]],winslash="/",mustWork=TRUE),
        "\n",sep="")
  cat("SOURCE_REVIEW_TRIAGE_BLOCKED; no pins, evidence, or certification changed\n")
  invisible(list(failures=bad,by_path=by_path,by_contract=by_contract))
}
.etr_triage_review_sha256()
