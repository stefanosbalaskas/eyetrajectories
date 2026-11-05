# Four-pilot external independent-review handoff and fail-closed verifier.
# This NEVER signs evidence, impersonates a reviewer, or edits the 508-export
# authoritative certification registry. A signature proves control of a key,
# NOT independence or scientific correctness; those require human assessment.
#
# Source via source("scripts/four_pilot_external_attestation.R",local=TRUE)
# etr_prepare_four_pilot_external_attestation()
#
# If a genuinely independent reviewer returns a completed CSV and detached
# GPG signature, use etr_check_four_pilot_external_attestation(...).
# FULL_SOURCE_PARITY is categorically ineligible while recorded gaps remain.

.etr_pilot_review_check<-function(ok,msg){
  if(!isTRUE(ok))stop(msg,call.=FALSE)
  invisible(TRUE)
}

.etr_pilot_packet_context<-function(root=".",packet_dir=NULL){
  ck<-.etr_pilot_review_check
  root<-normalizePath(root,winslash="/",mustWork=TRUE)
  ck(file.exists(file.path(root,"DESCRIPTION")),
    "Four-pilot attestation must run from the package root")
  if(is.null(packet_dir)){
    base<-file.path(root,"artifacts","native_independent_review_packets")
    dirs<-if(dir.exists(base))
      list.dirs(base,recursive=FALSE,full.names=TRUE)
    else character()
    dirs<-dirs[grepl("^qualification_[0-9]{8}T[0-9]{6}$",
      basename(dirs))]
    ck(length(dirs)>0L,"No source review packet has been captured")
    packet_dir<-sort(dirs,decreasing=TRUE)[[1L]]
  }
  packet_dir<-normalizePath(packet_dir,winslash="/",mustWork=TRUE)
  keys<-c(status="evidence_bundle_status.csv",
    priorities="four_numerical_pilots_external_review_priority.csv",
    matrix="four_pilot_boundary_review_matrix.csv",
    finite="four_pilot_developer_paired_numeric_replay.csv",
    boundaries="four_pilot_developer_source_boundary_observations.csv",
    gap_queue="known_source_gap_resolution_queue.csv")
  paths<-file.path(packet_dir,keys)
  names(paths)<-names(keys)
  ck(all(file.exists(paths)),
    paste("Missing source-review file(s):",
      paste(names(keys)[!file.exists(paths)],collapse=", ")))
  objects<-lapply(paths,utils::read.csv,
    stringsAsFactors=FALSE,check.names=FALSE)
  status<-objects$status
  ck(nrow(status)==1L&&
    all(c("evidence_bundle","recorded_r_git_head",
      "checkout_matches_evidence","source_file_manifest_matches_checkout",
      "native_suite_pass","pinned_python_suite_pass",
      "independent_review_approved","full_source_contract_certified")%in%
        names(status)),
    "Review packet has malformed exact-head evidence status")
  ck(isTRUE(status$checkout_matches_evidence)&&
    isTRUE(status$source_file_manifest_matches_checkout)&&
    isTRUE(status$native_suite_pass)&&
    isTRUE(status$pinned_python_suite_pass)&&
    identical(status$independent_review_approved,FALSE)&&
    identical(status$full_source_contract_certified,FALSE),
    "Only exact-head passing and unsigned evidence may be handed off")
  git<-Sys.which("git")
  ck(nzchar(git),"Git required to prove current source HEAD")
  head<-suppressWarnings(system2(git,
    c("-C",shQuote(root),"rev-parse","HEAD"),
    stdout=TRUE,stderr=FALSE))
  ck(length(head)==1L&&identical(as.character(head),
    status$recorded_r_git_head),
    "Source HEAD has changed since capture; regenerate evidence")
  fixed<-c("alr_transform","inverse_alr",
    "score_distance_matrix","functional_trapezoid_weights")
  pilots<-objects$priorities
  ck(nrow(pilots)==4L&&
    "python_name"%in%names(pilots)&&
    setequal(pilots$python_name,fixed)&&
    !anyDuplicated(pilots$python_name),
    "Four-pilot priority identity check failed")
  ck(all(c("pinned_python_commit",
    "independent_reviewer_approved",
    "full_accepted_input_domain_approved",
    "complete_error_semantics_approved",
    "scientific_scope_approved")%in%names(pilots))&&
    all(pilots$pinned_python_commit==
      "c1cd95ad718327550f7e55393ff38582872f7a94")&&
    !any(pilots$independent_reviewer_approved|
      pilots$full_accepted_input_domain_approved|
      pilots$complete_error_semantics_approved|
      pilots$scientific_scope_approved),
    "Pilot source contract is unsigned or source commit changed")
  ck(nrow(objects$matrix)==16L&&
    !any(objects$matrix$fully_certified|
      objects$matrix$independently_replayed_case),
    "The 16-row case matrix must not contain synthetic approvals")
  ck(nrow(objects$finite)==10L&&
    all(objects$finite$developer_numeric_fixture_pass)&&
    !any(objects$finite$fully_certified|
      objects$finite$independently_replayed_case),
    "Source finite observations missing or incorrectly certified")
  boundaries<-objects$boundaries
  ck(nrow(boundaries)==4L&&
    all(c("opt_in_python_boundary_mode_matches_source_category",
      "opt_in_mode_full_source_parity_certified")%in%names(boundaries))&&
    all(boundaries$opt_in_python_boundary_mode_matches_source_category)&&
    !any(boundaries$opt_in_mode_full_source_parity_certified)&&
    all(boundaries$observed_behavior_as_expected)&&
    sum(boundaries$relation=="documented_source_difference")==3L&&
    sum(boundaries$relation=="both_reject_error_schema_unreviewed")==1L&&
    !any(boundaries$source_domain_equivalence_established|
      boundaries$independent_reviewer_approved|
      boundaries$fully_certified),
    "Known source discrepancies must remain explicit, unsigned")
  gaps<-objects$gap_queue
  ck(nrow(gaps)==203L&&"python_name"%in%names(gaps)&&
    all(fixed%in%gaps$python_name)&&
    "resolved"%in%names(gaps)&&
    all(!gaps$resolved),
    "The full 203-gap ledger is no longer open; reassess before handoff")
  ck(requireNamespace("digest",quietly=TRUE),
    "digest is needed to hash the independent-review evidence bundle")
  list(root=root,packet_dir=packet_dir,paths=paths,
    objects=objects,pilots=pilots,head=head)
}

etr_prepare_four_pilot_external_attestation<-function(
    root=".",packet_dir=NULL){
  ctx<-.etr_pilot_packet_context(root,packet_dir)
  ck<-.etr_pilot_review_check
  files<-basename(ctx$paths)
  sha<-vapply(ctx$paths,function(path)
    digest::digest(path,algo="sha256",file=TRUE),
    character(1L),USE.NAMES=FALSE)
  manifest<-data.frame(filename=files,sha256=sha,
    recorded_r_git_head=rep(ctx$head,length(files)),
    frozen_python_commit=rep(
      "c1cd95ad718327550f7e55393ff38582872f7a94",
      length(files)),
    stringsAsFactors=FALSE)
  ck(nrow(manifest)==6L&&!anyDuplicated(manifest$filename)&&
    all(grepl("^[0-9a-f]{64}$",manifest$sha256)),
    "External review source-evidence manifest invalid")
  manifest_path<-file.path(ctx$packet_dir,
    "four_pilot_external_evidence_sha256_manifest.csv")
  utils::write.csv(manifest,manifest_path,row.names=FALSE,na="")
  manifest_sha256<-digest::digest(manifest_path,algo="sha256",file=TRUE)
  pilot_names<-ctx$pilots$python_name
  external<-data.frame(
    python_name=pilot_names,
    native_r_candidate=ctx$pilots$native_r_candidate,
    recorded_r_git_head=rep(ctx$head,4L),
    frozen_python_commit=ctx$pilots$pinned_python_commit,
    evidence_manifest_sha256=rep(manifest_sha256,4L),
    reviewer_name=rep("",4L),
    reviewer_affiliation=rep("",4L),
    reviewer_contact=rep("",4L),
    reviewer_is_independent_of_authors=rep(FALSE,4L),
    reviewer_replayed_python_separately=rep(FALSE,4L),
    reviewer_replayed_native_r_separately=rep(FALSE,4L),
    accepted_input_domain_reviewed=rep(FALSE,4L),
    error_warning_semantics_reviewed=rep(FALSE,4L),
    return_schema_dtype_reviewed=rep(FALSE,4L),
    scientific_estimand_reviewed=rep(FALSE,4L),
    documented_source_gap_resolved=rep(FALSE,4L),
    scope_decision=rep("PENDING_EXTERNAL_REVIEW",4L),
    reviewer_written_findings=rep("",4L),
    external_evidence_reference=rep("",4L),
    independent_review_signed_utc=rep("",4L),
    stringsAsFactors=FALSE)
  path<-file.path(ctx$packet_dir,
    "four_pilot_EXTERNAL_REVIEW_TEMPLATE.csv")
  utils::write.csv(external,path,row.names=FALSE,na="")
  manual<-file.path(ctx$packet_dir,
    "EXTERNAL_REVIEW_AND_SIGNATURE_INSTRUCTIONS.md")
  writeLines(c(
    "# Four pilot contracts — externally signed review",
    "",
    paste0("Pinned native R HEAD: `",ctx$head,"`"),
    "Frozen Python source: `c1cd95ad718327550f7e55393ff38582872f7a94`",
    "",
    "**This evidence is NOT an independent certification.**",
    "First-party evidence: 10 finite comparisons pass; 3 documented",
    "Python/R differences and 1 shared rejection remain unadjudicated.",
    "",
    "1. Give the source, review packet and SHA256 manifest to a reviewer",
    "   demonstrably independent of the package authors and this development.",
    "2. Reviewer obtains fresh source checkouts and independently reruns",
    "   boundary/numerical/schema/exception probes; preserve full logs.",
    "3. Reviewer completes a COPY of four_pilot_EXTERNAL_REVIEW_TEMPLATE.csv,",
    "   including attributable identity, evidence paths and findings.",
    "4. Reviewer MUST use RESTRICTED_SUBSET_MATCH or NOT_EQUIVALENT while",
    "   any source-domain gap is open; FULL_SOURCE_PARITY is prohibited.",
    "5. Reviewer signs the completed CSV with a detached GPG signature.",
    "   Example: gpg --detach-sign --armor completed_review.csv",
    "6. Validator requires a trusted public fingerprint supplied and",
    "   confirmed OUTSIDE this author-controlled repository.",
    "7. A matching GPG signature proves key control, NOT scientific",
    "   independence or correctness. Independent identity and all",
    "   scientific judgments must be separately verified by the recipient.",
    "8. Acceptance of restricted-subset external review does NOT",
    "   increment the 0/508 full-domain source-contract certification ledger.",
    "   A new qualification/review cycle is required after any source fix.",
    "",
    "The signed CSV binds the SHA256 of the six-file source-evidence manifest.",
    "Sign the completed review CSV, NOT the unsigned template or manifest."
  ),manual,useBytes=TRUE)
  message("Independent reviewer SHA256 evidence manifest: ",manifest_path)
  message("Unsigned external reviewer submission template: ",path)
  message("External review instructions: ",manual)
  message("0 independently certified; source differences remain open.")
  invisible(list(manifest=manifest_path,template=path,
    instructions=manual))
}

etr_check_four_pilot_external_attestation<-function(
    completed_csv,detached_signature,trusted_fingerprint,
    root=".",packet_dir=NULL){
  ctx<-.etr_pilot_packet_context(root,packet_dir)
  ck<-.etr_pilot_review_check
  ck(file.exists(completed_csv)&&file.exists(detached_signature),
    "Independent review CSV and detached signature are required")
  ck(is.character(trusted_fingerprint)&&
    length(trusted_fingerprint)==1L&&!is.na(trusted_fingerprint)&&
    grepl("^[A-Fa-f0-9]{40}$",trusted_fingerprint),
    "Use a separately trusted, full 40-hex GPG signing-key fingerprint")
  expected_file<-file.path(ctx$packet_dir,
    "four_pilot_external_evidence_sha256_manifest.csv")
  ck(file.exists(expected_file),
    "Independent reviewer evidence manifest not generated")
  manifest<-utils::read.csv(expected_file,
    stringsAsFactors=FALSE,check.names=FALSE)
  hashes<-vapply(ctx$paths,function(f)
    digest::digest(f,algo="sha256",file=TRUE),character(1L))
  ck(nrow(manifest)==length(ctx$paths)&&
    identical(as.character(manifest$filename),basename(ctx$paths))&&
    identical(as.character(manifest$sha256),unname(hashes)),
    "Captured source evidence modified after reviewer handoff")
  submission<-utils::read.csv(completed_csv,
    stringsAsFactors=FALSE,check.names=FALSE)
  expected<-c("python_name","native_r_candidate",
    "recorded_r_git_head","frozen_python_commit",
    "evidence_manifest_sha256","reviewer_name","reviewer_affiliation","reviewer_contact",
    "reviewer_is_independent_of_authors",
    "reviewer_replayed_python_separately",
    "reviewer_replayed_native_r_separately",
    "accepted_input_domain_reviewed","error_warning_semantics_reviewed",
    "return_schema_dtype_reviewed","scientific_estimand_reviewed",
    "documented_source_gap_resolved","scope_decision",
    "reviewer_written_findings","external_evidence_reference",
    "independent_review_signed_utc")
  ck(identical(names(submission),expected)&&nrow(submission)==4L&&
    !anyDuplicated(submission$python_name),
    "Completed signed CSV needs exactly four canonical contract rows/columns")
  idx<-match(ctx$pilots$python_name,submission$python_name)
  ck(!anyNA(idx),"External source contract names do not match four pilots")
  submission<-submission[idx,,drop=FALSE]
  manifest_sha256<-digest::digest(expected_file,
    algo="sha256",file=TRUE)
  ck(all(submission$evidence_manifest_sha256==manifest_sha256),
    "Detached reviewer submission does not bind the SHA256 evidence manifest")
  ck(identical(as.character(submission$native_r_candidate),
      as.character(ctx$pilots$native_r_candidate))&&
    all(submission$recorded_r_git_head==ctx$head)&&
    all(submission$frozen_python_commit==
      "c1cd95ad718327550f7e55393ff38582872f7a94"),
    "Reviewer must attest the exact frozen Python and native R sources")
  truth<-c("reviewer_is_independent_of_authors",
    "reviewer_replayed_python_separately",
    "reviewer_replayed_native_r_separately",
    "accepted_input_domain_reviewed","error_warning_semantics_reviewed",
    "return_schema_dtype_reviewed","scientific_estimand_reviewed")
  ck(all(vapply(submission[truth],function(x)
    is.logical(x)&&all(!is.na(x))&&all(x),logical(1L))),
    "Independent reviewer must document every required domain/replay gate")
  check_text<-c("reviewer_name","reviewer_affiliation",
    "reviewer_contact","reviewer_written_findings",
    "external_evidence_reference","independent_review_signed_utc")
  ck(all(vapply(submission[check_text],function(x)
    is.character(x)&&all(!is.na(x))&&
      all(nzchar(trimws(x))),logical(1L))),
    "Independent reviewer identity, findings, evidence and time required")
  ck(is.logical(submission$documented_source_gap_resolved)&&
    !anyNA(submission$documented_source_gap_resolved)&&
    !any(submission$documented_source_gap_resolved),
    "Source gaps are still open; a reviewer CSV cannot resolve them")
  ck(all(submission$scope_decision%in%
    c("RESTRICTED_SUBSET_MATCH","NOT_EQUIVALENT")),
    "FULL_SOURCE_PARITY prohibited with unresolved source-domain gaps")
  gpg<-Sys.which("gpg")
  ck(nzchar(gpg),"GPG required to check detached external reviewer signature")
  sig<-suppressWarnings(system2(gpg,
    c("--batch","--status-fd=1","--verify",
      shQuote(normalizePath(detached_signature,winslash="/")),
      shQuote(normalizePath(completed_csv,winslash="/"))),
    stdout=TRUE,stderr=TRUE))
  code<-attr(sig,"status")
  ck(is.null(code)||identical(as.integer(code),0L),
    "Detached GPG verification failed")
  valid<-grep("^\\[GNUPG:\\] VALIDSIG [A-Fa-f0-9]{40}( |$)",
    sig,value=TRUE)
  ck(length(valid)==1L,
    "No uniquely valid detached-signature fingerprint in GPG status")
  fields<-strsplit(valid," +")[[1L]]
  ck(length(fields)>=3L&&
    identical(toupper(fields[[3L]]),
      toupper(trusted_fingerprint)),
    "Signer fingerprint does not match trusted out-of-band review key")
  # An authentic signature is not proof that this reviewer is independent
  # of the author, nor that scientific full-domain parity exists. Never
  # write a TRUE approval to the authoritative 508-export registry.
  message("External signature and restricted-scope submission: structurally valid.")
  message("Human scientific/identity verification STILL REQUIRED; ",
    "0/508 full-domain contracts automatically certified.")
  invisible(list(signature_valid=TRUE,
    signed_subset_review_received=TRUE,
    full_source_contracts_certified=0L,
    reviewer_independence_human_verification_required=TRUE,
    signed_decisions=submission))
}
