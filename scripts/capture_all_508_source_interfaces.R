# OBSERVATIONAL author-side frozen Python 1.2 + R 508-export interfaces.
# This inventory does not run independent numerical/scientific tests.
etr_capture_all_508_source_interfaces <- function(
    root=".",packet_dir) {
  ck<-function(x,msg) if(!isTRUE(x))stop(msg,call.=FALSE)
  root<-normalizePath(root,winslash="/",mustWork=TRUE)
  packet_dir<-normalizePath(packet_dir,winslash="/",mustWork=TRUE)
  queue_file<-file.path(packet_dir,
    "certification_508_prioritized_work_queue.csv")
  status_file<-file.path(packet_dir,"evidence_bundle_status.csv")
  ck(file.exists(queue_file)&&file.exists(status_file),
    "Complete 508 source queue and qualification status required")
  q<-utils::read.csv(queue_file,check.names=FALSE,
    stringsAsFactors=FALSE)
  status<-utils::read.csv(status_file,check.names=FALSE,
    stringsAsFactors=FALSE)
  required<-c("namespace","python_name","kind","native_r_candidate",
    "recorded_r_git_head","frozen_python_commit","source_gap_open",
    "backend_or_estimand_distinct","native_nonfunction_representation",
    "native_implementation_started")
  ck(nrow(q)==508L&&all(required%in%names(q))&&
    sum(q$kind=="function")==380L&&sum(q$kind!="function")==128L&&
    !anyDuplicated(paste(q$namespace,q$python_name,sep="::")),
    "All 508 frozen export contracts required without duplicates")
  ck(nrow(status)==1L&&
    isTRUE(status$checkout_matches_evidence)&&
    isTRUE(status$source_file_manifest_matches_checkout)&&
    isTRUE(status$native_suite_pass)&&
    isTRUE(status$pinned_python_suite_pass),
    "Both exact-head source scientific suites must pass")
  git<-Sys.which("git")
  ck(nzchar(git),"git required")
  current<-suppressWarnings(system2(git,
    c("-C",shQuote(root),"rev-parse","HEAD"),
    stdout=TRUE,stderr=FALSE))
  ck(length(current)==1L&&grepl("^[a-f0-9]{40}$",current)&&
    all(q$recorded_r_git_head==current)&&
    identical(as.character(status$recorded_r_git_head),
      as.character(current)),
    "Cross-commit source inventory rejected")
  ck(all(q$frozen_python_commit==
    "c1cd95ad718327550f7e55393ff38582872f7a94")&&
    identical(et_python_version(),"1.2.0"),
    "Frozen Python 1.2 distribution mismatch")
  ck(requireNamespace("reticulate",quietly=TRUE)&&
    requireNamespace("digest",quietly=TRUE),
    "reticulate and digest required for 508 source census")
  inspect<-reticulate::import("inspect",convert=FALSE)
  ns<-asNamespace("eyetrajectories")
  observe<-function(action){
    tryCatch(list(ok=TRUE,value=as.character(action()),error=""),
      error=function(e)list(ok=FALSE,value="",
        error=conditionMessage(e)))
  }
  cases<-lapply(seq_len(nrow(q)),function(i) {
    item<-q[i,,drop=FALSE]
    name<-as.character(item$python_name)
    namespace<-as.character(item$namespace)
    function_kind<-identical(as.character(item$kind),"function")
    source<-tryCatch(list(ok=TRUE,
      value=etpy_get_export(name,.namespace=namespace),error=""),
      error=function(e)list(ok=FALSE,value=NULL,
        error=conditionMessage(e)))
    signature<-if(!source$ok)
      list(ok=FALSE,value="",error=source$error) else
      observe(function(){
        if(function_kind)
          reticulate::py_str(inspect$signature(source$value))
        else
          reticulate::py_str(
            reticulate::py_get_attr(source$value,"__class__"))
      })
    r_name<-as.character(item$native_r_candidate)
    native<-if(function_kind&&nzchar(r_name))
      get0(r_name,envir=ns,inherits=FALSE,mode="function") else NULL
    r_sig<-if(is.null(native))
      list(ok=FALSE,value="",error="No exported native R function") else
      observe(function()paste(deparse(formals(native)),collapse=" "))
    r_body_sha<-if(is.null(native))"" else
      digest::digest(body(native),algo="sha256",serialize=TRUE)
    representation<-as.character(item$native_nonfunction_representation)
    if(is.na(representation))representation<-""
    blocker<-if(!source$ok)
      "FROZEN_PYTHON_EXPORT_UNAVAILABLE" else
      if(!signature$ok)
        "FROZEN_PYTHON_INTERFACE_UNOBSERVED" else
        if(function_kind&&is.null(native))
          "NATIVE_R_FUNCTION_MISSING" else
          if(!function_kind&&!nzchar(representation))
            "NATIVE_R_NONFUNCTION_REPRESENTATION_MISSING" else
            if(isTRUE(item$source_gap_open))
              "DOCUMENTED_SOURCE_DOMAIN_DIFFERENCE" else
              if(isTRUE(item$backend_or_estimand_distinct))
                "ALTERNATIVE_BACKEND_OR_ESTIMAND" else
                "FULL_DOMAIN_INDEPENDENT_SCIENTIFIC_REVIEW_REQUIRED"
    data.frame(
      namespace=namespace,python_name=name,kind=item$kind,
      native_r_candidate=r_name,recorded_r_git_head=current,
      frozen_python_commit=item$frozen_python_commit,
      python_export_lookup_ok=source$ok,
      python_interface_inspected=signature$ok,
      python_signature_or_class=signature$value,
      python_inspection_error=signature$error,
      native_r_function_present=!is.null(native),
      native_r_formals_observed=r_sig$ok,
      native_r_formals=r_sig$value,
      native_r_inspection_error=r_sig$error,
      native_r_body_sha256=r_body_sha,
      native_nonfunction_representation=representation,
      documented_source_gap_open=item$source_gap_open,
      backend_or_estimand_distinct=item$backend_or_estimand_distinct,
      first_scientific_review_blocker=blocker,
      signature_text_is_not_scientific_equivalence=TRUE,
      independently_replayed=FALSE,
      fully_source_certified=FALSE,
      stringsAsFactors=FALSE)
  })
  observed<-do.call(rbind,cases)
  ck(nrow(observed)==508L&&
    !anyDuplicated(paste(observed$namespace,observed$python_name,sep="::"))&&
    !any(observed$independently_replayed|observed$fully_source_certified)&&
    all(observed$signature_text_is_not_scientific_equivalence),
    "Census cannot pre-approve independent scientific contracts")
  path<-file.path(packet_dir,"all_508_source_interface_inventory.csv")
  utils::write.csv(observed,path,row.names=FALSE,na="")
  checksum<-digest::digest(path,algo="sha256",file=TRUE)
  sidecar<-file.path(packet_dir,
    "all_508_source_interface_inventory_sha256.csv")
  utils::write.csv(data.frame(
    filename=basename(path),sha256=checksum,
    recorded_r_git_head=current,
    frozen_python_commit=
      "c1cd95ad718327550f7e55393ff38582872f7a94",
    independently_approved=FALSE,fully_source_certified=FALSE),
    sidecar,row.names=FALSE,na="")
  ck(identical(digest::digest(path,algo="sha256",file=TRUE),
    checksum),"508 observed interface inventory hash changed")
  message("508 descriptive frozen-source interface observations recorded: ",
    sum(observed$python_export_lookup_ok),"/508 Python exports accessed; ",
    sum(observed$python_interface_inspected),
    "/508 signatures/classes inspected; ",
    sum(observed$native_r_function_present),
    "/380 native R function candidates found. Independent scientific ",
    "certificates: 0/508. Evidence: ",path)
  invisible(list(records=observed,csv=path,manifest=sidecar))
}
