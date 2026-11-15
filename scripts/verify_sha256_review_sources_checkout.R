# Verify author-pinned six-domain source reviews on Windows, Linux or macOS.
# From the repo root: source("scripts/verify_sha256_review_sources_checkout.R")
# IMPORTANT: This is *integrity only*, not independent source certification.
# It never updates expected hashes, review records, code or reviewer statuses.
#
# Windows git autocrlf may materialize CRLF checkouts of canonical LF git
# blobs. A byte mismatch is accepted ONLY if the Git HEAD blob matches the
# pinned SHA256, the working tree is clean, and CRLF->LF is its sole change.
# Every other mismatch remains a hard failure, with per-file diagnostics.

.etr_sha256_verify_checkout <- function() {
  if(!file.exists("DESCRIPTION") || !identical(
      unname(read.dcf("DESCRIPTION","Package")[1L]),"eyetrajectories"))
    stop("Run from eyetrajectories package root",call.=FALSE)
  if(!requireNamespace("jsonlite",quietly=TRUE) ||
      !requireNamespace("digest",quietly=TRUE))
    stop("Install jsonlite and digest",call.=FALSE)
  git<-Sys.which("git")
  if(!nzchar(git))stop("git is required for canonical blob checks",call.=FALSE)
  # Git porcelain status may mark Windows CRLF-only worktree files as
  # modified even when the canonical Git content is unchanged. Compare
  # HEAD against the full staged+working tracked tree instead; --quiet
  # checks substantive content without losing the SHA256 Git-blob gate.
  diff_rc<-suppressWarnings(system2(git,
    c("diff","--quiet","HEAD","--"),
    stdout=FALSE,stderr=FALSE))
  if(!identical(as.integer(diff_rc),0L))
    stop("Tracked Git content differs from HEAD; commit or stash the ",
      "substantive changes before source-review integrity audit. ",
      "No expected hashes were modified.",call.=FALSE)
  register<-"inst/extdata/reviewed_source_contract_closures_v1.csv"
  rows<-utils::read.csv(register,stringsAsFactors=FALSE,
    check.names=FALSE)
  stopifnot(nrow(rows)>=1L,
    !anyDuplicated(rows$python_name),
    all(c("review_record_path","review_record_sha256",
      "independently_certified")%in%names(rows)))
  refs<-data.frame(
    python_name=rows$python_name,
    path=rows$review_record_path,
    pinned_sha256=rows$review_record_sha256,
    source="review_json",stringsAsFactors=FALSE)
  for(i in seq_len(nrow(rows))){
    p<-rows$review_record_path[[i]]
    if(!file.exists(p))next
    doc<-tryCatch(jsonlite::fromJSON(p,simplifyVector=FALSE),
      error=function(e)NULL)
    if(is.null(doc))next
    evidence<-c(doc$native_files,doc$case_evidence,
      doc$additional_regression_evidence)
    for(e in evidence){
      if(is.null(e$path)||is.null(e$sha256))next
      refs<-rbind(refs,data.frame(python_name=rows$python_name[[i]],
        path=as.character(e$path),pinned_sha256=as.character(e$sha256),
        source=as.character(e$kind %||% "native_file"),
        stringsAsFactors=FALSE))
    }
  }
  sha_file<-function(p)unname(digest::digest(p,
    algo="sha256",file=TRUE))
  # Raw normalization ONLY removes a carriage return directly before LF.
  eol_normalized_sha<-function(p){
    n<-file.info(p)$size
    b<-readBin(p,what="raw",n=n)
    if(length(b)<2L)return(unname(digest::digest(b,
      algo="sha256",serialize=FALSE)))
    v<-as.integer(b)
    drop<-which(v[-length(v)]==13L & v[-1L]==10L)
    if(length(drop))b<-b[-drop]
    unname(digest::digest(b,algo="sha256",serialize=FALSE))
  }
  # Cache Git blob hashes to avoid re-running Git for every reviewer record.
  blob_hashes<-new.env(parent=emptyenv())
  blob_sha<-function(p){
    key<-p  # exact repository path is a valid environment key; no collisions
    if(exists(key,envir=blob_hashes,inherits=FALSE))
      return(get(key,envir=blob_hashes,inherits=FALSE))
    tmp<-tempfile("et_review_blob_")
    err<-tempfile("et_review_git_err_")
    on.exit(unlink(c(tmp,err)),add=TRUE)
    rc<-suppressWarnings(system2(git,
      c("show",shQuote(paste0("HEAD:",p))),stdout=tmp,stderr=err))
    val<-if(identical(as.integer(rc),0L)&&file.exists(tmp))
      sha_file(tmp) else NA_character_
    assign(key,val,envir=blob_hashes)
    val
  }
  result<-vector("list",nrow(refs))
  for(i in seq_len(nrow(refs))){
    p<-refs$path[[i]]
    pin<-refs$pinned_sha256[[i]]
    if(!file.exists(p)){
      raw<-eol<-git_sha<-NA_character_
      verdict<-"FAIL_MISSING"
    }else{
      raw<-sha_file(p)
      if(identical(raw,pin)){
        eol<-git_sha<-NA_character_
        verdict<-"PASS_EXACT_CHECKOUT_BYTES"
      }else{
        eol<-eol_normalized_sha(p)
        git_sha<-blob_sha(p)
        verdict<-if(!is.na(git_sha)&&
          identical(git_sha,pin)&&identical(eol,pin))
          "PASS_CANONICAL_GIT_BLOB_EOL_ONLY"
        else "FAIL_PIN_MISMATCH"
      }
    }
    result[[i]]<-data.frame(
      python_name=refs$python_name[[i]],
      path=p,source=refs$source[[i]],pinned_sha256=pin,
      working_file_sha256=raw,lf_normalized_sha256=eol,
      git_head_blob_sha256=git_sha,verdict=verdict,
      stringsAsFactors=FALSE)
  }
  output<-do.call(rbind,result)
  outdir<-file.path("artifacts","review_sha256_checkout_audit")
  dir.create(outdir,recursive=TRUE,showWarnings=FALSE)
  name<-paste0("review_integrity_",format(Sys.time(),"%Y%m%d_%H%M%S"),
    "_",Sys.getpid(),".csv")
  dest<-file.path(outdir,name)
  utils::write.csv(output,dest,row.names=FALSE,na="")
  print(as.data.frame(table(output$verdict)),row.names=FALSE)
  cat("SHA256_CHECKOUT_DIAGNOSTICS=",normalizePath(dest,
    winslash="/",mustWork=TRUE),"\n",sep="")
  if(any(startsWith(output$verdict,"FAIL_")))
    stop("Review SHA256 integrity has real/missing-source mismatches; ",
      "inspect the CSV. No certification granted.",call.=FALSE)
  cat("SHA256_CANONICAL_SOURCE_VERIFIED; ",
    "independent_scientific_certification=FALSE\n",sep="")
  invisible(output)
}
`%||%`<-function(x,y)if(is.null(x)||!length(x))y else x
.etr_sha256_verify_checkout()
