# First-party (NOT independent) source-interface introspection for 36
# first-wave frozen Python 1.2 exports and the native R source candidates.
# This records observed signatures, class representations and gaps. It NEVER
# approves or modifies a scientific/508-contract certification register.
etr_capture_first_wave_source_interfaces<-function(root=".",packet_dir) {
  ck<-function(ok,msg)if(!isTRUE(ok))stop(msg,call.=FALSE)
  root<-normalizePath(root,winslash="/",mustWork=TRUE)
  packet_dir<-normalizePath(packet_dir,winslash="/",mustWork=TRUE)
  selected<-file.path(packet_dir,
    "certification_first_function_and_nonfunction_batches.csv")
  status_path<-file.path(packet_dir,"evidence_bundle_status.csv")
  ck(file.exists(selected)&&file.exists(status_path),
     "First-wave interface inventory requires a qualified 36-export packet")
  scope<-utils::read.csv(selected,stringsAsFactors=FALSE,check.names=FALSE)
  status<-utils::read.csv(status_path,stringsAsFactors=FALSE,check.names=FALSE)
  ck(nrow(scope)==36L&&nrow(status)==1L&&
    all(c("python_name","namespace","kind","native_r_candidate",
      "recorded_r_git_head","frozen_python_commit","review_lane",
      "source_gap_open","backend_or_estimand_distinct")%in%names(scope))&&
    sum(scope$review_lane=="FUNCTION_NO_RECORDED_GAP")==24L&&
    sum(scope$review_lane=="NONFUNCTION_NO_RECORDED_GAP")==12L&&
    isTRUE(status$native_suite_pass)&&
    isTRUE(status$pinned_python_suite_pass),
    "The 36-export first wave is malformed or source suites have not passed")
  git<-Sys.which("git")
  ck(nzchar(git),"git required for frozen interface inventory")
  head<-suppressWarnings(system2(git,c("-C",shQuote(root),"rev-parse","HEAD"),
    stdout=TRUE,stderr=FALSE))
  ck(length(head)==1L&&grepl("^[0-9a-f]{40}$",head)&&
    all(scope$recorded_r_git_head==head)&&
    identical(status$recorded_r_git_head,head),
    "Current R git commit differs from first-wave evidence")
  ck(identical(et_python_version(),"1.2.0")&&
    all(scope$frozen_python_commit==
      "c1cd95ad718327550f7e55393ff38582872f7a94"),
    "Python source must be frozen eyetrajectoriespy 1.2.0")
  ck(requireNamespace("reticulate",quietly=TRUE)&&
    requireNamespace("digest",quietly=TRUE),
    "reticulate and digest are required")
  inspect<-reticulate::import("inspect",convert=FALSE)
  ns<-asNamespace("eyetrajectories")
  safe<-function(f){
    tryCatch(list(ok=TRUE,value=as.character(f()),error=""),
      error=function(e)list(ok=FALSE,value="",
        error=conditionMessage(e)))
  }
  native_args<-function(f){
    args<-formals(f)
    if(length(args)==0L)return("()")
    out<-vapply(seq_along(args),function(i){
      parameter<-names(args)[[i]]
      # R pairlists contain a special *missing argument* object for
      # required formals. Extract it defensively instead of treating a
      # required argument as an introspection failure for the whole API.
      value<-tryCatch(paste(
        deparse(args[[i]],width.cutoff=500L),collapse=" "),
        error=function(e)"")
      if(nzchar(value))paste0(parameter,"=",value) else parameter
    },character(1L))
    paste0("(",paste(out,collapse=", "),")")
  }
  rows<-lapply(seq_len(nrow(scope)),function(i){
    row<-scope[i,,drop=FALSE]
    name<-row$python_name[[1L]]
    is_function<-identical(row$kind[[1L]],"function")
    source_obj<-tryCatch(
      list(ok=TRUE,value=etpy_get_export(name),error=""),
      error=function(e)list(ok=FALSE,value=NULL,
        error=conditionMessage(e)))
    source_signature<-if(!source_obj$ok)
      list(ok=FALSE,value="",error=source_obj$error) else
      safe(function(){
        if(is_function)
          reticulate::py_str(inspect$signature(source_obj$value))
        else reticulate::py_str(
          reticulate::py_get_attr(source_obj$value,"__class__"))
      })
    native_name<-row$native_r_candidate[[1L]]
    native<-if(is_function&&nzchar(native_name))
      get0(native_name,envir=ns,inherits=FALSE,mode="function")
      else NULL
    native_sig<-if(!is_function)
      list(ok=TRUE,value="NOT_APPLICABLE_NONFUNCTION",error="") else
      if(is.null(native))
        list(ok=FALSE,value="",error="native R export not found as function")
      else safe(function()native_args(native))
    body_hash<-if(is.null(native))"" else
      digest::digest(body(native),algo="sha256",serialize=TRUE)
    data.frame(namespace=row$namespace,python_name=name,
      kind=row$kind,
      native_r_candidate=native_name,
      recorded_r_git_head=head,
      frozen_python_commit=row$frozen_python_commit,
      python_export_lookup_ok=source_obj$ok,
      python_interface_inspected=source_signature$ok,
      python_signature_or_object_class=source_signature$value,
      python_inspection_error=source_signature$error,
      native_r_function_present=!is.null(native),
      native_r_formals_inspected=native_sig$ok,
      native_r_formals=native_sig$value,
      native_inspection_error=native_sig$error,
      native_r_body_sha256=body_hash,
      signature_text_is_not_semantic_parity=TRUE,
      independently_reproduced=FALSE,
      source_full_domain_certified=FALSE,
      stringsAsFactors=FALSE)
  })
  out<-do.call(rbind,rows)
  ck(nrow(out)==36L&&!anyDuplicated(paste(out$namespace,out$python_name))&&
    all(out$signature_text_is_not_semantic_parity)&&
    !any(out$independently_reproduced|out$source_full_domain_certified),
    "First-wave source interface inventory has invalid review flags")
  path<-file.path(packet_dir,"first_wave_source_interface_inventory.csv")
  utils::write.csv(out,path,row.names=FALSE,na="")
  hash<-digest::digest(path,algo="sha256",file=TRUE)
  manifest<-data.frame(filename=basename(path),sha256=hash,
    recorded_r_git_head=head,
    frozen_python_commit="c1cd95ad718327550f7e55393ff38582872f7a94",
    independently_verified=FALSE,fully_certified=FALSE)
  meta_path<-file.path(packet_dir,
    "first_wave_source_interface_inventory_sha256.csv")
  utils::write.csv(manifest,meta_path,row.names=FALSE,na="")
  reread<-utils::read.csv(path,stringsAsFactors=FALSE,check.names=FALSE)
  ck(nrow(reread)==36L&&identical(hash,
    digest::digest(path,algo="sha256",file=TRUE))&&
    !any(reread$source_full_domain_certified),
    "SHA256 sidecar or first-party source interface record invalid")
  message("36-source first-party signature/class inventory written: ",path,
    ". Python exports inspected: ",sum(out$python_export_lookup_ok),
    "; native functions present: ",sum(out$native_r_function_present),
    ". These are DESCRIPTIVE evidence, not independent full-domain parity.")
  invisible(list(records=out,csv=path,manifest=meta_path))
}
