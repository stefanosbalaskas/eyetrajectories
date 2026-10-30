# Independent-review hand-off for frozen Python 1.2 native source contracts.
# Run FROM the package root after capture_native_source_qualification_evidence:
# source("scripts/prepare_independent_source_review.R")
#
# Does not alter the 508-export authoritative certification ledger, certify
# an R implementation, auto-sign a reviewer, or treat test PASS as full parity.
# Works without Python, reticulate, digest, or active network access.

etr_prepare_independent_source_review<-function(
    root=".",evidence_dir=NULL,output_dir=NULL){
  .checked<-function(condition,message){
    if(!isTRUE(condition))stop(message,call.=FALSE)
  }
  root<-normalizePath(root,winslash="/",mustWork=TRUE)
  .checked(file.exists(file.path(root,"DESCRIPTION")),
    "Run the independent review packet script from the package root")
  evidence_root<-file.path(root,"artifacts","native_source_contract_evidence")
  if(is.null(evidence_dir)){
    candidates<-if(dir.exists(evidence_root))
      list.dirs(evidence_root,recursive=FALSE,full.names=TRUE) else
        character()
    candidates<-candidates[grepl("^qualification_[0-9]{8}T[0-9]{6}$",
      basename(candidates))]
    .checked(length(candidates)>0L,
      "No qualification evidence directory exists; capture both modes first")
    evidence_dir<-sort(candidates,decreasing=TRUE)[[1L]]
  }
  evidence_dir<-normalizePath(evidence_dir,winslash="/",mustWork=TRUE)
  base<-c("native_r_offline.txt","python_1_2_direct_source.txt",
    "unsigned_contract_fixture_evidence.csv","file_integrity_manifest.csv")
  paths<-file.path(evidence_dir,base)
  .checked(all(file.exists(paths)),
    paste("Incomplete qualification record. Missing:",
      paste(base[!file.exists(paths)],collapse=", ")))
  logs<-lapply(paths[1:2],readLines,warn=FALSE)
  # Capture appends one exact verdict after each testthat summary. A global
  # pass establishes only the *suite* result, not per-contract source parity.
  passed<-vapply(logs,function(lines){
    any(lines=="QUALIFICATION COMPLETED WITHOUT TEST FAILURES")&&
      !any(grepl("QUALIFICATION ERROR:",lines,fixed=TRUE))
  },logical(1L))
  records<-utils::read.csv(paths[[3L]],stringsAsFactors=FALSE,
    check.names=FALSE)
  required<-c("python_name","native_r_function","python_source_commit",
    "r_git_head","source_path","fixture_test",
    "native_offline_fixture_pass","pinned_python_fixture_pass",
    "independent_reviewer_signoff","fully_certified")
  .checked(all(required%in%names(records))&&
    !anyDuplicated(records$python_name)&&nrow(records)>=1L,
    "Qualification status CSV malformed or duplicate")
  .checked(all(!records$fully_certified)&&
    all(!records$independent_reviewer_signoff),
    "This hand-off does not accept preapproved self-certified records")
  .checked(all(records$python_source_commit==
    "c1cd95ad718327550f7e55393ff38582872f7a94"),
    "Qualification evidence does not refer to frozen Python 1.2 source")
  .checked(all(records$native_offline_fixture_pass==passed[[1L]])&&
    all(records$pinned_python_fixture_pass==passed[[2L]]),
    "Captured suite verdict and per-row suite-result flags disagree")
  recorded_heads<-unique(records$r_git_head)
  .checked(length(recorded_heads)==1L&&!is.na(recorded_heads)&&
    grepl("^[0-9a-f]{40}$",recorded_heads),
    "Qualification evidence does not specify a single complete R commit")
  head<-NA_character_
  git<-Sys.which("git")
  if(nzchar(git)){
    observed<-suppressWarnings(system2(git,
      c("-C",shQuote(root),"rev-parse","HEAD"),
      stdout=TRUE,stderr=FALSE))
    if(length(observed)==1L&&grepl("^[0-9a-f]{40}$",observed))
      head<-observed
  }
  exact_head<-identical(head,recorded_heads)
  manifest<-utils::read.csv(paths[[4L]],stringsAsFactors=FALSE,
    check.names=FALSE)
  .checked(identical(names(manifest),c("path","md5"))&&
    nrow(manifest)>0L&&!anyDuplicated(manifest$path)&&
    all(nzchar(manifest$md5)),
    "Integrity manifest missing required paths or hashes")
  local_files<-file.path(root,manifest$path)
  exists<-file.exists(local_files)
  actual_hash<-rep(NA_character_,length(local_files))
  if(any(exists))actual_hash[exists]<-unname(
    tools::md5sum(local_files[exists]))
  identical_hash<-exists&!is.na(actual_hash)&
    actual_hash==manifest$md5
  if(exact_head){
    .checked(all(identical_hash),
      paste("Same-head evidence has altered or absent files:",
        paste(manifest$path[!identical_hash],collapse=", ")))
  }
  gaps_path<-file.path(root,
    "inst/extdata/native_source_contract_gaps_stage22.csv")
  .checked(file.exists(gaps_path),"Missing source gap register")
  gaps<-utils::read.csv(gaps_path,stringsAsFactors=FALSE,
    check.names=FALSE)
  .checked(all(c("python_name","gap_kind","known_source_difference",
    "source_witness","review_resolution","unresolved_source_gap")%in%
      names(gaps))&&!anyDuplicated(gaps$python_name),
    "Source-gap register malformed")
  gap_idx<-match(records$python_name,gaps$python_name)
  .checked(!anyNA(gap_idx)&&all(gaps$unresolved_source_gap[gap_idx]),
    "Every queued source contract needs an explicit unresolved difference")
  .checked(all(file.exists(file.path(root,records$fixture_test))),
    "A queued contract has no corresponding checked-in source oracle test")

  id<-basename(evidence_dir)
  if(is.null(output_dir))output_dir<-file.path(root,
    "artifacts","native_independent_review_packets",id)
  dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
  .checked(dir.exists(output_dir),"Could not create independent-review packet")
  status<-data.frame(
    evidence_bundle=id,recorded_r_git_head=recorded_heads,
    current_r_git_head=if(is.na(head))"" else head,
    checkout_matches_evidence=exact_head,
    source_file_manifest_matches_checkout=all(identical_hash),
    native_suite_pass=passed[[1L]],
    pinned_python_suite_pass=passed[[2L]],
    all_source_differences_resolved=FALSE,
    independent_replay_pass=FALSE,
    independent_review_approved=FALSE,
    full_source_contract_certified=FALSE,
    source_contract_count=nrow(records),
    stringsAsFactors=FALSE)
  submission<-data.frame(
    python_name=records$python_name,
    native_r_function=records$native_r_function,
    frozen_python_commit=records$python_source_commit,
    tested_r_commit=records$r_git_head,
    python_source_file=records$source_path,
    source_oracle_test=records$fixture_test,
    unresolved_gap_kind=gaps$gap_kind[gap_idx],
    unresolved_source_difference=gaps$known_source_difference[gap_idx],
    required_resolution=gaps$review_resolution[gap_idx],
    native_suite_pass_observed=passed[[1L]],
    pinned_python_suite_pass_observed=passed[[2L]],
    same_commit_evidence_valid=exact_head&&all(identical_hash),
    source_full_domain_review=FALSE,
    invalid_input_error_domain_review=FALSE,
    independently_replayed_python_oracle=FALSE,
    independently_replayed_native_r=FALSE,
    estimand_scientific_review=FALSE,
    reviewer_independent_of_authors=FALSE,
    reviewer_identity="",
    reviewer_affiliation="",
    reviewer_signed_commit="",
    reviewer_signed_utc="",
    review_decision="PENDING_INDEPENDENT_REVIEW",
    fully_certified=FALSE,
    stringsAsFactors=FALSE)
  integrity<-data.frame(
    path=manifest$path,recorded_md5=manifest$md5,
    checkout_md5=actual_hash,present=exists,
    unchanged_from_captured_evidence=identical_hash,
    stringsAsFactors=FALSE)
  utils::write.csv(status,file.path(output_dir,
    "evidence_bundle_status.csv"),row.names=FALSE,na="")
  utils::write.csv(submission,file.path(output_dir,
    "independent_contract_review_queue.csv"),row.names=FALSE,na="")
  utils::write.csv(integrity,file.path(output_dir,
    "file_integrity_recheck.csv"),row.names=FALSE,na="")
  # Four simpler pilot contracts already have user-reported fixture
  # evidence in the authoritative register, but still lack independent
  # numerical/schema/scientific/reviewer approvals. Surface them separately,
  # not as additional fully qualified members of the 70-contract queue.
  pilot_path<-file.path(root,"inst","extdata",
    "native_contract_certification_pilots_v1.csv")
  .checked(file.exists(pilot_path),"Missing four-contract pilot register")
  pilot<-utils::read.csv(pilot_path,stringsAsFactors=FALSE,
    check.names=FALSE)
  .checked(nrow(pilot)==4L&&
    all(c("python_name","source_path","native_r_candidate",
      "numerical_fixture_pass","numerical_oracle_approved",
      "schema_boundary_approved","scientific_scope_approved",
      "independent_reviewer_approved")%in%names(pilot)),
    "Expected four original numerical pilot source contracts")
  .checked(all(pilot$numerical_fixture_pass)&&
    !any(pilot$numerical_oracle_approved)&&
    !any(pilot$schema_boundary_approved)&&
    !any(pilot$scientific_scope_approved)&&
    !any(pilot$independent_reviewer_approved),
    "Pilot contracts must not be silently auto-promoted")
  pilot_packet<-data.frame(
    priority=seq_len(nrow(pilot)),
    python_name=pilot$python_name,
    native_r_candidate=pilot$native_r_candidate,
    frozen_python_source=pilot$source_path,
    original_numeric_fixture_pass=pilot$numerical_fixture_pass,
    full_accepted_input_domain_approved=FALSE,
    complete_error_semantics_approved=FALSE,
    scientific_scope_approved=FALSE,
    independent_reviewer_approved=FALSE,
    independent_review_decision="PENDING_INDEPENDENT_REVIEW",
    stringsAsFactors=FALSE)
  utils::write.csv(pilot_packet,file.path(output_dir,
    "four_numerical_pilots_external_review_priority.csv"),
    row.names=FALSE,na="")
  instructions<-c(
    "# Frozen Python 1.2: independent scientific contract review",
    "",
    paste0("Captured R commit: \`",recorded_heads,"\`"),
    paste0("Checkout matches captured evidence: **",
      if(exact_head)"yes" else "NO — historical evidence", "**"),
    paste0("Native suite: **",if(passed[[1L]])"PASS" else "FAIL","**"),
    paste0("Pinned Python suite: **",
      if(passed[[2L]])"PASS" else "FAIL","**"),
    paste0("Recorded integrity manifest matches current checkout: **",
      if(all(identical_hash))"yes" else "NO","**"),
    "",
    "## Suggested first independent reviews",
    "",
    "Start with the four previously fixture-tested source contracts:",
    "alr_transform, inverse_alr, score_distance_matrix and",
    "functional_trapezoid_weights (separate priority CSV). The original",
    "fixture PASS does not imply full-domain source correctness or approval.",
    "",
    "## Reviewer requirements",
    "",
    "1. Independently fetch the frozen Python v1.2.0 source and exact R commit;",
    "   do not rely solely on developer-supplied fixture results.",
    "2. Independently rerun both R and frozen Python tests; capture the exact",
    "   source and R commit IDs, environment, logs and SHA256 evidence.",
    "3. Examine accepted and rejected source input shapes, data types,",
    "   numeric boundaries, randomness, scientific estimands and errors.",
    "4. Resolve each declared source difference before a full contract",
    "   can be considered; restricted-subset numerical agreement is not",
    "   full-domain parity.",
    "5. A reviewer independent of the authors must sign each contract",
    "   against a full immutable commit and link replayable evidence.",
    "6. Amend the authoritative source-gap and 508-export certification",
    "   ledgers only following review and reproducible approval.",
    "",
    "**This packet is not a scientific certification or independent signoff.**",
    "Review decisions default to PENDING_INDEPENDENT_REVIEW.",
    "The test suites are aggregated; suite PASS does not prove that each",
    "contract has a complete source-domain witness.",
    "")
  writeLines(instructions,file.path(output_dir,"REVIEW_INSTRUCTIONS.md"),
    useBytes=TRUE)
  message("Independent review packet created: ",
    normalizePath(output_dir,winslash="/",mustWork=TRUE))
  message("Checkout evidence match: ",exact_head,
    " | file integrity: ",all(identical_hash),
    " | native suite: ",passed[[1L]],
    " | Python suite: ",passed[[2L]])
  message("Contracts awaiting truly independent full-domain review: ",
    nrow(submission),". No certifications changed.")
  invisible(list(status=status,review=submission,
    file_integrity=integrity,output_dir=output_dir))
}

etr_prepare_independent_source_review()
