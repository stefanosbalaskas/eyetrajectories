# Build an UNSIGNED, exact-head, 508-export certification review worklist.
# This does not perform or impersonate independent scientific review.
# Run from package root after a successful full evidence capture:
# source("scripts/build_508_certification_review_batches.R")
# etr_build_508_certification_review_batches()

etr_build_508_certification_review_batches <- function(
    root=".",packet_dir=NULL,function_batch_size=24L,
    nonfunction_batch_size=12L) {
  ck <- function(ok,msg) if(!isTRUE(ok))stop(msg,call.=FALSE)
  ck(requireNamespace("digest",quietly=TRUE),
    "digest is required to SHA256-hash reviewer worklists")
  for(x in list(function_batch_size,nonfunction_batch_size))
    ck(is.numeric(x)&&length(x)==1L&&!is.na(x)&&is.finite(x)&&
      x>=1L&&x==as.integer(x),
      "Each review batch size must be a positive integer")
  root<-normalizePath(root,winslash="/",mustWork=TRUE)
  ck(file.exists(file.path(root,"DESCRIPTION")),"Run from package root")
  if(is.null(packet_dir)) {
    base<-file.path(root,"artifacts","native_independent_review_packets")
    dirs<-if(dir.exists(base))
      list.dirs(base,recursive=FALSE,full.names=TRUE) else character()
    dirs<-dirs[grepl("^qualification_[0-9]{8}T[0-9]{6}$",
      basename(dirs))]
    ck(length(dirs)>=1L,"No captured reviewer packet")
    packet_dir<-sort(dirs,decreasing=TRUE)[[1L]]
  }
  packet_dir<-normalizePath(packet_dir,winslash="/",mustWork=TRUE)
  source_path<-file.path(packet_dir,
    "all_508_public_export_independent_review_scope.csv")
  status_path<-file.path(packet_dir,"evidence_bundle_status.csv")
  ck(file.exists(source_path)&&file.exists(status_path),
    "Run full qualification and reviewer scope capture first")
  scope<-utils::read.csv(source_path,stringsAsFactors=FALSE,
    check.names=FALSE)
  status<-utils::read.csv(status_path,stringsAsFactors=FALSE,
    check.names=FALSE)
  required<-c("namespace","python_name","kind","native_r_candidate",
    "frozen_source_sha","evidence_r_git_head",
    "mapped_native_function","backend_or_estimand_distinct",
    "source_difference_open","selected_oracle_candidate",
    "fully_certified","per_export_independent_reviewer_approved")
  ck(nrow(scope)==508L&&all(required%in%names(scope))&&
    !anyDuplicated(paste(scope$namespace,scope$python_name,sep="::"))&&
    sum(scope$kind=="function")==380L&&
    sum(scope$kind!="function")==128L&&
    sum(scope$mapped_native_function)==380L,
    "Frozen 508-export scope is missing, duplicated or incomplete")
  status_req<-c("recorded_r_git_head","checkout_matches_evidence",
    "source_file_manifest_matches_checkout","native_suite_pass",
    "pinned_python_suite_pass","independent_review_approved",
    "full_source_contract_certified")
  ck(nrow(status)==1L&&all(status_req%in%names(status)),
    "Missing exact-head qualification status")
  ck(isTRUE(status$checkout_matches_evidence)&&
    isTRUE(status$source_file_manifest_matches_checkout)&&
    isTRUE(status$native_suite_pass)&&
    isTRUE(status$pinned_python_suite_pass)&&
    identical(status$independent_review_approved,FALSE)&&
    identical(status$full_source_contract_certified,FALSE),
    "Qualification is failed, changed or independently approved")
  git<-Sys.which("git")
  ck(nzchar(git),"git is required for exact-head reviewer packets")
  head<-suppressWarnings(system2(git,c("-C",shQuote(root),
    "rev-parse","HEAD"),stdout=TRUE,stderr=FALSE))
  ck(length(head)==1L&&grepl("^[0-9a-f]{40}$",head)&&
    identical(as.character(head),as.character(status$recorded_r_git_head))&&
    all(scope$evidence_r_git_head==head),
    "Current R git HEAD differs from captured qualification evidence")
  frozen_python<-"c1cd95ad718327550f7e55393ff38582872f7a94"
  ck(all(grepl("^[0-9a-f]{40}$",scope$frozen_source_sha)),
    "Frozen source inventory SHA malformed")
  if(!exists("etr_native_certification_readiness_frame",
      mode="function",inherits=TRUE)){
    ck(requireNamespace("pkgload",quietly=TRUE),"pkgload required")
    pkgload::load_all(root,quiet=TRUE)
  }
  ready<-etr_native_certification_readiness_frame()
  ck(nrow(ready)==508L,"Missing 508-row source readiness audit")
  key<-paste(scope$namespace,scope$python_name,sep="::")
  idx<-match(key,paste(ready$namespace,ready$python_name,sep="::"))
  ck(!anyNA(idx)&&!anyDuplicated(idx),"Scope/readiness key mismatch")
  ready<-ready[idx,,drop=FALSE]
  ck(all((ready$published_source_difference_open |
      ready$nonfunction_source_difference_open)==
    scope$source_difference_open)&&
    all(ready$native_backend_or_estimand_differs==
      scope$backend_or_estimand_distinct)&&
    all(ready$fully_certified==scope$fully_certified),
    "Reviewer scope and current authoritative readiness disagree")
  # Callable and nonfunction source differences are separately registered.
  # Do not classify TrajectorySet as an error-free first-wave review
  # candidate merely because the 203-row function gap registry omits it.
  nonfunction_gap<-ready$nonfunction_source_difference_open
  ck(is.logical(nonfunction_gap)&&!anyNA(nonfunction_gap)&&
    sum(nonfunction_gap)==1L,
    "Expected one explicit unresolved Python nonfunction source contract")
  gap<-scope$source_difference_open | nonfunction_gap
  backend<-scope$backend_or_estimand_distinct
  fn<-scope$kind=="function"
  impl<-ready$native_implementation_started
  # Absence of a *documented* gap is not proof of full source equivalence.
  lane<-ifelse(ready$fully_certified,"ALREADY_FULLY_CERTIFIED",
    ifelse(backend,"DIFFERENT_BACKEND_OR_ESTIMAND",
    ifelse(gap,"RECORDED_SOURCE_DIFFERENCE",
    ifelse(fn&(!impl|!scope$mapped_native_function),
      "MISSING_NATIVE_FUNCTION",
    ifelse(fn,"FUNCTION_NO_RECORDED_GAP",
      "NONFUNCTION_NO_RECORDED_GAP")))))
  priority<-match(lane,c("FUNCTION_NO_RECORDED_GAP",
    "NONFUNCTION_NO_RECORDED_GAP","RECORDED_SOURCE_DIFFERENCE",
    "DIFFERENT_BACKEND_OR_ESTIMAND","MISSING_NATIVE_FUNCTION",
    "ALREADY_FULLY_CERTIFIED"))
  ck(!anyNA(priority),"Unclassified export in certification queue")
  full<-data.frame(
    review_priority=as.integer(priority),
    review_lane=lane,
    namespace=scope$namespace,
    python_name=scope$python_name,
    kind=scope$kind,
    native_r_candidate=scope$native_r_candidate,
    native_nonfunction_representation=
      ready$native_nonfunction_representation,
    recorded_r_git_head=rep(head,nrow(scope)),
    frozen_python_commit=rep(frozen_python,nrow(scope)),
    frozen_catalog_source_sha=scope$frozen_source_sha,
    native_implementation_started=impl,
    mapped_native_function=scope$mapped_native_function,
    source_gap_open=gap,
    native_nonfunction_source_gap_open=nonfunction_gap,
    backend_or_estimand_distinct=backend,
    source_fixture_attributed=scope$selected_oracle_candidate,
    first_unresolved_requirement=ready$first_unresolved_requirement,
    all_unresolved_requirements=ready$all_unresolved_requirements,
    currently_authoritatively_certified=ready$fully_certified,
    developer_queue_is_not_scientific_certification=TRUE,
    stringsAsFactors=FALSE)
  full<-full[order(full$review_priority,
    nchar(full$python_name),full$python_name),,drop=FALSE]
  rownames(full)<-NULL
  ck(nrow(full)==508L&&
    sum(full$review_lane=="FUNCTION_NO_RECORDED_GAP")>0L&&
    sum(full$review_lane=="NONFUNCTION_NO_RECORDED_GAP")>0L,
    "No initially gap-free review candidates")
  functions<-full[full$review_lane=="FUNCTION_NO_RECORDED_GAP",,
    drop=FALSE]
  others<-full[full$review_lane=="NONFUNCTION_NO_RECORDED_GAP",,
    drop=FALSE]
  selection<-rbind(
    utils::head(functions,as.integer(function_batch_size)),
    utils::head(others,as.integer(nonfunction_batch_size)))
  rownames(selection)<-NULL
  ck(nrow(selection)>=2L&&!any(selection$currently_authoritatively_certified)&&
    !any(selection$source_gap_open|selection$backend_or_estimand_distinct),
    "Review batch contains an open difference or already-approved export")
  criteria<-c("frozen_python_and_native_source_identity",
    "source_signature_parameters_and_defaults",
    "complete_accepted_input_and_coercion_domain",
    "numerical_reference_randomized_precision",
    "boundary_nan_inf_overflow_missing_and_empty",
    "return_dimension_order_dtype_and_metadata",
    "exception_warning_and_side_effect_semantics",
    "scientific_estimand_and_backend_equivalence",
    "independently_created_case_and_replay_logs",
    "independent_reviewer_identity_evidence_and_signature")
  cases<-selection[rep(seq_len(nrow(selection)),each=length(criteria)),
    c("namespace","python_name","kind","native_r_candidate",
      "recorded_r_git_head","frozen_python_commit"),drop=FALSE]
  cases$criterion<-rep(criteria,nrow(selection))
  cases$reviewer_case_passed<-FALSE
  cases$reviewer_created_evidence_reference<-""
  cases$reviewer_written_findings<-""
  cases$independently_replayed<-FALSE
  cases$full_domain_approved<-FALSE
  rownames(cases)<-NULL
  decision<-selection[,c("namespace","python_name","kind",
    "native_r_candidate","recorded_r_git_head","frozen_python_commit"),
    drop=FALSE]
  decision$reviewer_name<-""
  decision$reviewer_affiliation<-""
  decision$reviewer_contact<-""
  decision$reviewer_independent_of_implementation_team<-FALSE
  decision$reviewer_python_replay_pass<-FALSE
  decision$reviewer_r_replay_pass<-FALSE
  decision$complete_input_error_schema_review_pass<-FALSE
  decision$scientific_estimand_review_pass<-FALSE
  decision$all_source_gaps_resolved_after_review<-FALSE
  decision$reviewer_signed_evidence_reference<-""
  decision$reviewer_signed_utc<-""
  decision$scope_decision<-"PENDING_INDEPENDENT_REVIEW"
  decision$full_domain_certification_approved<-FALSE
  review_files<-c("certification_508_prioritized_work_queue.csv",
    "certification_first_function_and_nonfunction_batches.csv",
    "certification_first_batch_reviewer_checklist.csv",
    "certification_first_batch_UNSIGNED_decisions.csv")
  payload<-list(full,selection,cases,decision)
  for(i in seq_along(payload))
    utils::write.csv(payload[[i]],file.path(packet_dir,review_files[[i]]),
      row.names=FALSE,na="")
  hashes<-vapply(review_files,function(n)
    digest::digest(file.path(packet_dir,n),algo="sha256",file=TRUE),
    character(1L))
  manifest<-data.frame(filename=review_files,sha256=unname(hashes),
    recorded_r_git_head=head,frozen_python_commit=frozen_python,
    independent_review_signoff_present=FALSE,
    stringsAsFactors=FALSE)
  manifest_path<-file.path(packet_dir,
    "certification_first_batch_sha256_manifest.csv")
  utils::write.csv(manifest,manifest_path,row.names=FALSE,na="")
  ck(nrow(full)==508L&&
    identical(sum(cases$reviewer_case_passed),0L)&&
    !any(decision$full_domain_certification_approved)&&
    all(vapply(seq_along(review_files),function(i)
      identical(digest::digest(file.path(packet_dir,review_files[[i]]),
        algo="sha256",file=TRUE),hashes[[i]]),logical(1L))),
    "Unsigned certification worklist fails evidence integrity")
  message("508 export certification queue generated at ",packet_dir,
    ": ",nrow(functions)," candidate functions and ",
    nrow(others)," candidate nonfunctions without RECORDED source gaps; ",
    sum(scope$source_difference_open & scope$kind=="function"),
    " callable source gaps, ",
    sum(nonfunction_gap)," nonfunction source gap; ",
    sum(gap)," total documented source-gap exports; ",
    sum(backend)," alternative backends/estimands (overlap permitted).")
  message("First unsigned reviewer batch: ",nrow(selection),
    " exports, ",nrow(cases)," case criteria; 0 new independent approvals.")
  invisible(list(queue=full,selection=selection,cases=cases,
    decisions=decision,manifest=manifest,output_dir=packet_dir))
}
