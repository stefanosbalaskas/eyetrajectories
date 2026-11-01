# This is an author-side regression of external-review packaging and gates.
# It is NEVER a scientific independent reviewer signoff or source certificate.

test_that("four-pilot external handoff emits hashed unsigned reviewed inputs",{
  if(!nzchar(Sys.which("git")))
    skip("git required for exact-head source review checks")
  if(!requireNamespace("digest",quietly=TRUE))
    skip("digest SHA256 support required for reviewer bundle")
  root<-testthat::test_path("..","..")
  envir<-new.env(parent=baseenv())
  sys.source(file.path(root,"scripts",
    "four_pilot_external_attestation.R"),envir=envir)
  head<-suppressWarnings(system2(Sys.which("git"),
    c("-C",shQuote(normalizePath(root,winslash="/")),
      "rev-parse","HEAD"),stdout=TRUE,stderr=FALSE))
  stopifnot(length(head)==1L,nchar(head)==40L)
  packet<-tempfile("unsigned_external_pilot_")
  dir.create(packet)
  on.exit(unlink(packet,recursive=TRUE),add=TRUE)
  status<-data.frame(evidence_bundle="synthetic_not_review",
    recorded_r_git_head=head,checkout_matches_evidence=TRUE,
    source_file_manifest_matches_checkout=TRUE,native_suite_pass=TRUE,
    pinned_python_suite_pass=TRUE,
    independent_review_approved=FALSE,
    full_source_contract_certified=FALSE)
  pilots<-utils::read.csv(file.path(root,"inst","extdata",
    "native_contract_certification_pilots_v1.csv"),
    stringsAsFactors=FALSE,check.names=FALSE)
  priorities<-data.frame(python_name=pilots$python_name,
    native_r_candidate=pilots$native_r_candidate,
    pinned_python_commit=pilots$published_tag_commit,
    independent_reviewer_approved=FALSE,
    full_accepted_input_domain_approved=FALSE,
    complete_error_semantics_approved=FALSE,
    scientific_scope_approved=FALSE)
  matrix<-data.frame(python_name=rep(pilots$python_name,each=4L),
    fully_certified=FALSE,independently_replayed_case=FALSE)
  finite<-data.frame(python_name=rep(pilots$python_name,c(2L,2L,2L,4L)),
    developer_numeric_fixture_pass=TRUE,
    fully_certified=FALSE,independently_replayed_case=FALSE)
  boundaries<-data.frame(python_name=pilots$python_name,
    observed_behavior_as_expected=TRUE,
    relation=c("documented_source_difference",
      "documented_source_difference",
      "both_reject_error_schema_unreviewed",
      "documented_source_difference"),
    source_domain_equivalence_established=FALSE,
    independent_reviewer_approved=FALSE,fully_certified=FALSE)
  source_gaps<-utils::read.csv(file.path(root,"inst","extdata",
    "native_source_contract_gaps_stage22.csv"),
    stringsAsFactors=FALSE,check.names=FALSE)
  expect_identical(nrow(source_gaps),203L)
  gaps<-data.frame(python_name=source_gaps$python_name,
    resolved=FALSE)
  input<-list(
    evidence_bundle_status=status,
    four_numerical_pilots_external_review_priority=priorities,
    four_pilot_boundary_review_matrix=matrix,
    four_pilot_developer_paired_numeric_replay=finite,
    four_pilot_developer_source_boundary_observations=boundaries,
    known_source_gap_resolution_queue=gaps)
  for(name in names(input))
    utils::write.csv(input[[name]],file.path(packet,
      paste0(name,".csv")),row.names=FALSE,na="")
  prepared<-envir$etr_prepare_four_pilot_external_attestation(
    root=root,packet_dir=packet)
  expect_true(all(file.exists(unlist(prepared))))
  manifest<-utils::read.csv(prepared$manifest,
    stringsAsFactors=FALSE,check.names=FALSE)
  submission<-utils::read.csv(prepared$template,
    stringsAsFactors=FALSE,check.names=FALSE)
  expect_identical(nrow(manifest),6L)
  expect_identical(nrow(submission),4L)
  expect_true(all(grepl("^[0-9a-f]{64}$",manifest$sha256)))
  expect_true(all(submission$evidence_manifest_sha256==
    digest::digest(prepared$manifest,file=TRUE,algo="sha256")))
  expect_true(all(submission$scope_decision=="PENDING_EXTERNAL_REVIEW"))
  expect_false(any(submission$reviewer_is_independent_of_authors))
  expect_false(any(submission$documented_source_gap_resolved))
  # A self-generated template is not a completed external review.
  signature<-file.path(packet,"untrusted.asc")
  writeLines("not a valid signature",signature)
  expect_error(envir$etr_check_four_pilot_external_attestation(
    completed_csv=prepared$template,detached_signature=signature,
    trusted_fingerprint=paste(rep("A",40L),collapse=""),
    root=root,packet_dir=packet),
    "Independent reviewer must document every required domain/replay gate")
  # Even a completed, apparently self-attested and signed record must
  # be rejected when it falsely asserts full Python source equivalence.
  completed<-submission
  complete_flags<-c("reviewer_is_independent_of_authors",
    "reviewer_replayed_python_separately",
    "reviewer_replayed_native_r_separately",
    "accepted_input_domain_reviewed","error_warning_semantics_reviewed",
    "return_schema_dtype_reviewed","scientific_estimand_reviewed")
  for(name in complete_flags)completed[[name]]<-TRUE
  for(name in c("reviewer_name","reviewer_affiliation",
    "reviewer_contact","reviewer_written_findings",
    "external_evidence_reference","independent_review_signed_utc"))
    completed[[name]]<-"Synthetic evidence, NOT A REAL REVIEW"
  completed$scope_decision<-"FULL_SOURCE_PARITY"
  completed_path<-file.path(packet,"synthetic_not_signed.csv")
  utils::write.csv(completed,completed_path,row.names=FALSE)
  expect_error(envir$etr_check_four_pilot_external_attestation(
    completed_csv=completed_path,detached_signature=signature,
    trusted_fingerprint=paste(rep("A",40L),collapse=""),
    root=root,packet_dir=packet),
    "FULL_SOURCE_PARITY prohibited")
  completed$scope_decision<-"RESTRICTED_SUBSET_MATCH"
  completed$evidence_manifest_sha256<-paste(rep("0",64L),collapse="")
  utils::write.csv(completed,completed_path,row.names=FALSE)
  expect_error(envir$etr_check_four_pilot_external_attestation(
    completed_csv=completed_path,detached_signature=signature,
    trusted_fingerprint=paste(rep("A",40L),collapse=""),
    root=root,packet_dir=packet),
    "does not bind the SHA256 evidence manifest")
  # Tamper with any source evidence AFTER manifest generation, even by
  # an empty line: the SHA256 gate must reject it before reading a signature.
  cat("\n",file=file.path(packet,
    "four_pilot_boundary_review_matrix.csv"),append=TRUE)
  expect_error(envir$etr_check_four_pilot_external_attestation(
    completed_csv=prepared$template,detached_signature=signature,
    trusted_fingerprint=paste(rep("A",40L),collapse=""),
    root=root,packet_dir=packet),
    "Captured source evidence modified after reviewer handoff")
})

test_that("external review signer gate rejects full parity for open gaps",{
  path<-testthat::test_path("..","..","scripts",
    "four_pilot_external_attestation.R")
  expect_silent(parse(file=path,keep.source=FALSE))
  lines<-readLines(path,warn=FALSE)
  for(token in c("Source gaps are still open","FULL_SOURCE_PARITY",
    "RESTRICTED_SUBSET_MATCH","NOT_EQUIVALENT",
    "GPG required","VALIDSIG","trusted_fingerprint",
    "source evidence modified after reviewer handoff",
    "full_source_contracts_certified=0L")){
    expect_true(any(grepl(token,lines,fixed=TRUE)),
      info=paste("Missing independent signoff control",token))
  }
  expect_false(any(grepl("fully_certified=TRUE",lines,fixed=TRUE)))
  expect_false(any(grepl(
    "independent_reviewer_approved=TRUE",lines,fixed=TRUE)))
})
