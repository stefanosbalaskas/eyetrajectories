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
    per_contract_oracle_coverage_adjudicated=FALSE,
    all_source_differences_resolved=FALSE,
    independent_replay_pass=FALSE,
    independent_review_approved=FALSE,
    full_source_contract_certified=FALSE,
    source_contract_count=nrow(records),
    stringsAsFactors=FALSE)
  # Evidence attribution stops at what is actually observable: which
  # fixture files the testthat filter selected, their declared test-case
  # count, and a static literal etpy_get_export("...") reference. It
  # never infers per-contract case execution from a global PASS.
  selector_file<-file.path(evidence_dir,"test_selection_regex.txt")
  selector_recorded<-file.exists(selector_file)
  selector<-if(selector_recorded)
    readLines(selector_file,warn=FALSE) else character()
  if(selector_recorded)
    .checked(length(selector)==1L&&!is.na(selector)&&nzchar(selector),
      "Source qualification test-selection regex is malformed")
  helper_path<-file.path(root,"scripts",
    "source_fixture_static_attribution.R")
  .checked(file.exists(helper_path),
    "Missing nonexecuting source-fixture attribution helper")
  source(helper_path,local=TRUE)
  .inspect_fixture<-function(relative_path)
    etr_source_fixture_static_inventory(file.path(root,relative_path))
  fixture_files<-unique(records$fixture_test)
  fixture_info<-lapply(fixture_files,.inspect_fixture)
  fixture_idx<-match(records$fixture_test,fixture_files)
  fixture_case_counts<-vapply(fixture_info,function(x)
    x$cases,integer(1L))
  .checked(all(fixture_case_counts>=1L),
    "One or more source fixture files define no test_that test cases")
  selector_md5<-if(selector_recorded)
    unname(tools::md5sum(selector_file)) else ""
  fixture_selected<-if(selector_recorded)
    grepl(selector,basename(records$fixture_test)) else
      rep(FALSE,nrow(records))
  if(selector_recorded)
    .checked(all(fixture_selected),
      paste("Selected source fixture files omitted by testthat filter:",
        paste(unique(records$fixture_test[!fixture_selected]),
          collapse=", ")))
  literal_reference<-vapply(seq_len(nrow(records)),function(i)
    records$python_name[[i]]%in%
      fixture_info[[fixture_idx[[i]]]]$export_literals,logical(1L))
  attribution<-data.frame(
    python_name=records$python_name,
    native_r_function=records$native_r_function,
    fixture_test=records$fixture_test,
    fixture_file_md5=unname(tools::md5sum(
      file.path(root,records$fixture_test))),
    test_selection_regex_recorded=rep(selector_recorded,nrow(records)),
    test_selection_regex_md5=rep(selector_md5,nrow(records)),
    fixture_filename_selected_in_both_suite_modes=fixture_selected,
    test_that_cases_declared_in_entire_fixture_file=
      fixture_case_counts[fixture_idx],
    literal_etpy_get_export_call_for_this_contract=literal_reference,
    # Each file may contain multiple tests, skips, and many contracts.
    # Static AST references and filename selection are NOT case results.
    per_contract_test_execution_independently_attributed=FALSE,
    per_contract_python_oracle_independently_replayed=FALSE,
    fully_certified=FALSE,
    stringsAsFactors=FALSE)
  .checked(nrow(attribution)==nrow(records)&&
    !anyDuplicated(attribution$python_name)&&
    all(attribution$test_that_cases_declared_in_entire_fixture_file>0L)&&
    !any(attribution$fully_certified)&&
    !any(attribution$per_contract_test_execution_independently_attributed),
    "Fixture attribution must preserve every unsigned selected contract")
  utils::write.csv(attribution,file.path(output_dir,
    "selected_111_fixture_static_attribution.csv"),
    row.names=FALSE,na="")
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
    # Source fixtures have not been independently attributed one by one.
    aggregate_suite_is_not_individual_contract_approval=TRUE,
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
  # Scope the independent-review undertaking across ALL 508 frozen
  # public exports (380 functions + 128 classes/configs/constants).
  # The 111-row source fixture packet is a SELECTED subset, never a
  # claim that other exports were reviewed or even fully exercised.
  if(!exists("etr_native_certification_readiness_frame",
      mode="function",inherits=TRUE)){
    .checked(requireNamespace("pkgload",quietly=TRUE),
      "Review scope requires pkgload to inspect the checked-out R package")
    pkgload::load_all(root,quiet=TRUE)
  }
  readiness<-etr_native_certification_readiness_frame()
  .checked(nrow(readiness)==508L&&
    sum(readiness$kind=="function")==380L&&
    sum(readiness$kind!="function")==128L&&
    !anyDuplicated(paste(readiness$namespace,readiness$python_name,
      sep="::"))&&
    !any(readiness$fully_certified),
    "Full source review scope must remain 508 distinct unsigned exports")
  gidx<-match(readiness$python_name,gaps$python_name)
  queued_idx<-match(readiness$python_name,records$python_name)
  .checked(all(records$python_name%in%readiness$python_name)&&
    all(!is.na(queued_idx[match(records$python_name,
      readiness$python_name)])),
    "Selected review queue could not be mapped to the full source registry")
  review_scope<-data.frame(
    namespace=readiness$namespace,
    python_name=readiness$python_name,
    kind=readiness$kind,
    native_r_candidate=readiness$native_r_candidate,
    frozen_source_sha=readiness$frozen_source_sha,
    evidence_r_git_head=rep(recorded_heads,nrow(readiness)),
    mapped_native_function=readiness$kind=="function"&
      readiness$native_mapping_present,
    backend_or_estimand_distinct=readiness$native_backend_or_estimand_differs,
    source_difference_open=readiness$published_source_difference_open,
    source_gap_kind=ifelse(is.na(gidx),"",
      gaps$gap_kind[gidx]),
    selected_oracle_candidate=!is.na(queued_idx),
    selected_oracle_file=ifelse(is.na(queued_idx),"",
      records$fixture_test[queued_idx]),
    selected_suite_native_pass=ifelse(is.na(queued_idx),FALSE,
      passed[[1L]]),
    selected_suite_python_pass=ifelse(is.na(queued_idx),FALSE,
      passed[[2L]]),
    selected_fixture_file_in_capture_filter=ifelse(
      is.na(queued_idx),FALSE,
      attribution$fixture_filename_selected_in_both_suite_modes[queued_idx]),
    selected_fixture_literal_python_export_call=ifelse(
      is.na(queued_idx),FALSE,
      attribution$literal_etpy_get_export_call_for_this_contract[queued_idx]),
    selected_fixture_file_declared_test_cases=ifelse(
      is.na(queued_idx),0L,
      attribution$test_that_cases_declared_in_entire_fixture_file[queued_idx]),
    per_export_complete_domain_review=FALSE,
    per_export_independent_oracle_replay=FALSE,
    per_export_schema_error_review=FALSE,
    per_export_scientific_scope_review=FALSE,
    per_export_independent_reviewer_approved=FALSE,
    open_evidence_requirements=readiness$all_unresolved_requirements,
    fully_certified=FALSE,
    stringsAsFactors=FALSE)
  .checked(nrow(review_scope)==508L&&
    sum(review_scope$selected_oracle_candidate)==nrow(records)&&
    sum(review_scope$mapped_native_function)==380L&&
    !any(review_scope$fully_certified)&&
    !any(review_scope$per_export_independent_reviewer_approved),
    "Full 508-contract reviewer scope must fail closed before signoff")
  utils::write.csv(review_scope,file.path(output_dir,
    "all_508_public_export_independent_review_scope.csv"),
    row.names=FALSE,na="")

  # Deterministic, machine-readable triage over the complete 508-export
  # frozen public surface. A selected suite witness is not a per-export
  # approval, and a different R estimator cannot be described as parity.
  is_function<-review_scope$kind=="function"
  is_selected<-review_scope$selected_oracle_candidate
  different_estimand<-review_scope$backend_or_estimand_distinct
  has_gap<-review_scope$source_difference_open
  lane<-ifelse(!is_function,"nonfunction_contract_review",
    ifelse(different_estimand,"alternative_backend_or_estimand",
    ifelse(is_selected,"selected_source_oracle_review",
    ifelse(has_gap,"unselected_open_source_gap",
      "unselected_function_contract_review"))))
  rank<-ifelse(!is_function,5L,
    ifelse(different_estimand,2L,
    ifelse(is_selected,1L,ifelse(has_gap,3L,4L))))
  review_triage<-data.frame(
    review_priority=as.integer(rank),
    review_lane=lane,
    namespace=review_scope$namespace,
    python_name=review_scope$python_name,
    kind=review_scope$kind,
    native_r_candidate=review_scope$native_r_candidate,
    selected_oracle_candidate=is_selected,
    backend_or_estimand_distinct=different_estimand,
    unresolved_source_difference=has_gap,
    source_gap_kind=review_scope$source_gap_kind,
    source_oracle_test=review_scope$selected_oracle_file,
    fixture_file_selected_in_capture_filter=
      review_scope$selected_fixture_file_in_capture_filter,
    fixture_literal_python_export_call_found=
      review_scope$selected_fixture_literal_python_export_call,
    recorded_r_commit=rep(recorded_heads,nrow(review_scope)),
    developer_suite_native_pass=review_scope$selected_suite_native_pass,
    developer_suite_python_pass=review_scope$selected_suite_python_pass,
    independent_source_contract_approved=FALSE,
    stringsAsFactors=FALSE)
  review_triage<-review_triage[
    order(review_triage$review_priority,review_triage$python_name),
    ,drop=FALSE]
  rownames(review_triage)<-NULL
  .checked(nrow(review_triage)==508L&&
    sum(review_triage$kind=="function")==380L&&
    sum(review_triage$selected_oracle_candidate)==nrow(records)&&
    !any(review_triage$independent_source_contract_approved),
    "Full-surface source triage must preserve all unsigned exports")
  utils::write.csv(review_triage,file.path(output_dir,
    "all_508_contract_review_priority.csv"),
    row.names=FALSE,na="")
  # Every declared source discrepancy remains visible, including known
  # alternative estimators that cannot be resolved by numeric tolerances.
  queued_gap<-match(gaps$python_name,review_triage$python_name)
  .checked(!anyNA(queued_gap)&&
    all(gaps$native_r_candidate==
      review_triage$native_r_candidate[queued_gap]),
    "Unmatched source gaps in independent reviewer triage")
  gap_resolution<-data.frame(
    review_priority=review_triage$review_priority[queued_gap],
    review_lane=review_triage$review_lane[queued_gap],
    python_name=gaps$python_name,
    native_r_candidate=gaps$native_r_candidate,
    gap_kind=gaps$gap_kind,
    recorded_source_difference=gaps$known_source_difference,
    source_witness=gaps$source_witness,
    required_resolution=gaps$review_resolution,
    gap_open=gaps$unresolved_source_gap,
    selected_oracle_candidate=review_triage$
      selected_oracle_candidate[queued_gap],
    alternative_backend_or_estimand=review_triage$
      backend_or_estimand_distinct[queued_gap],
    reviewer_decision="PENDING_INDEPENDENT_REVIEW",
    independently_replayed=FALSE,
    resolved=FALSE,
    stringsAsFactors=FALSE)
  gap_resolution<-gap_resolution[
    order(gap_resolution$review_priority,gap_resolution$python_name),
    ,drop=FALSE]
  rownames(gap_resolution)<-NULL
  .checked(nrow(gap_resolution)==nrow(gaps)&&
    !anyDuplicated(gap_resolution$python_name)&&
    !any(gap_resolution$resolved),
    "Gap resolution queue must preserve every unapproved source difference")
  utils::write.csv(gap_resolution,file.path(output_dir,
    "known_source_gap_resolution_queue.csv"),row.names=FALSE,na="")
  lane_counts<-as.data.frame(table(review_triage$review_lane),
    stringsAsFactors=FALSE)
  names(lane_counts)<-c("review_lane","exports")
  utils::write.csv(lane_counts,file.path(output_dir,
    "review_lane_counts.csv"),row.names=FALSE,na="")

  # Four simpler pilot contracts already have user-reported fixture
  # evidence in the authoritative register, but still lack independent
  # numerical/schema/scientific/reviewer approvals. Surface them separately,
  # not as additional certified members of the selected source-review queue.
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
    paste0("Captured R commit: `",recorded_heads,"`"),
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
    "The all_508_public_export_independent_review_scope.csv includes every",
    "public function and nonfunction export, with mapping distinguished from",
    "scientific equivalence, verified boundaries, and third-party signoff.",
    "",
    "## Contract-level triage files",
    "",
    "- all_508_contract_review_priority.csv: complete sorted 508-export",
    "  queue. Rank 1 is selected-source-oracle review; rank 2 denotes",
    "  distinct native backend/estimand, NOT source parity; rank 3 is",
    "  unselected known source gaps; rank 4 other unreviewed functions;",
    "  rank 5 nonfunction source exports.",
    "- known_source_gap_resolution_queue.csv: each declared source gap",
    "  with the source witness, required scientific resolution and",
    "  selected-oracle/alternative-backend flags.",
    "- review_lane_counts.csv: noncertifying inventory totals by lane.",
    "- selected_111_fixture_static_attribution.csv: matched fixture test",
    "  filenames from the captured testthat filter, number of declared",
    "  test_that cases in each file and literal etpy_get_export calls.",
    "  This is a STATIC file-level attribution, not an executed per-case",
    "  pass, an independent replay, or a full-source-domain approval.",
    "  Missing test_selection_regex.txt in an older bundle is reported",
    "  as selector not recorded rather than inventing test coverage.",
    "All rows default to unsigned, unresolved and pending independent review.",
    "Do not treat a passing aggregate suite as per-contract approval.",
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
    full_export_scope=review_scope,
    file_integrity=integrity,output_dir=output_dir))
}

etr_prepare_independent_source_review()
