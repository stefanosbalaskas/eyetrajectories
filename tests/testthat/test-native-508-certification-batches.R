# First-party QA of reviewer packet generation, NEVER independent signoff.
test_that("508-export review fast lane preserves every uncertified export",{
  if(!nzchar(Sys.which("git")))
    skip("Exact-head reviewer test requires git")
  if(!requireNamespace("digest",quietly=TRUE))
    skip("SHA256 reviewer-packet regression requires digest")
  root<-normalizePath(testthat::test_path("..",".."),
    winslash="/",mustWork=TRUE)
  e<-new.env(parent=globalenv())
  sys.source(file.path(root,"scripts",
    "build_508_certification_review_batches.R"),envir=e)
  head<-suppressWarnings(system2(Sys.which("git"),
    c("-C",shQuote(root),"rev-parse","HEAD"),
    stdout=TRUE,stderr=FALSE))
  stopifnot(length(head)==1L,nchar(head)==40L)
  api<-etr_native_certification_readiness_frame()
  stopifnot(nrow(api)==508L)
  dir<-tempfile("unsigned_508_cert_review_")
  dir.create(dir)
  on.exit(unlink(dir,recursive=TRUE),add=TRUE)
  scope<-data.frame(
    namespace=api$namespace,python_name=api$python_name,kind=api$kind,
    native_r_candidate=api$native_r_candidate,
    frozen_source_sha=api$frozen_source_sha,
    evidence_r_git_head=rep(head,nrow(api)),
    mapped_native_function=api$kind=="function"&
      api$native_mapping_present,
    backend_or_estimand_distinct=
      api$native_backend_or_estimand_differs,
    source_difference_open=api$published_source_difference_open,
    selected_oracle_candidate=rep(FALSE,nrow(api)),
    fully_certified=api$fully_certified,
    per_export_independent_reviewer_approved=rep(FALSE,nrow(api)))
  status<-data.frame(recorded_r_git_head=head,
    checkout_matches_evidence=TRUE,
    source_file_manifest_matches_checkout=TRUE,
    native_suite_pass=TRUE,pinned_python_suite_pass=TRUE,
    independent_review_approved=FALSE,
    full_source_contract_certified=FALSE)
  utils::write.csv(scope,file.path(dir,
    "all_508_public_export_independent_review_scope.csv"),
    row.names=FALSE,na="")
  utils::write.csv(status,file.path(dir,"evidence_bundle_status.csv"),
    row.names=FALSE,na="")
  z<-e$etr_build_508_certification_review_batches(
    root=root,packet_dir=dir,function_batch_size=8L,
    nonfunction_batch_size=4L)
  expect_identical(nrow(z$queue),508L)
  expect_identical(nrow(z$selection),12L)
  expect_identical(nrow(z$cases),120L)
  expect_identical(nrow(z$decisions),12L)
  expect_identical(sum(z$queue$kind=="function"),380L)
  expect_identical(sum(z$queue$kind!="function"),128L)
  expect_identical(sum(z$queue$source_gap_open),
    sum(api$published_source_difference_open))
  expect_true(all(z$selection$review_lane%in%c(
    "FUNCTION_NO_RECORDED_GAP","NONFUNCTION_NO_RECORDED_GAP")))
  expect_false(any(z$selection$source_gap_open))
  expect_false(any(z$selection$backend_or_estimand_distinct))
  expect_false(any(z$cases$reviewer_case_passed))
  expect_false(any(z$cases$independently_replayed))
  expect_false(any(z$decisions$full_domain_certification_approved))
  expect_true(all(z$decisions$scope_decision==
    "PENDING_INDEPENDENT_REVIEW"))
  expect_true(all(grepl("^[0-9a-f]{64}$",z$manifest$sha256)))
  expect_equal(nrow(z$manifest),4L)
  for(i in seq_len(nrow(z$manifest))) {
    f<-file.path(dir,z$manifest$filename[[i]])
    expect_true(file.exists(f))
    expect_identical(unname(digest::digest(f,algo="sha256",
      file=TRUE)),z$manifest$sha256[[i]])
  }
  # The owner can never synthesize approval by changing packet status.
  status$pinned_python_suite_pass<-FALSE
  utils::write.csv(status,file.path(dir,"evidence_bundle_status.csv"),
    row.names=FALSE,na="")
  expect_error(e$etr_build_508_certification_review_batches(
    root=root,packet_dir=dir),"Qualification is failed")
  status$pinned_python_suite_pass<-TRUE
  status$recorded_r_git_head<-paste(rep("0",40L),collapse="")
  utils::write.csv(status,file.path(dir,"evidence_bundle_status.csv"),
    row.names=FALSE,na="")
  expect_error(e$etr_build_508_certification_review_batches(
    root=root,packet_dir=dir),"HEAD differs")
})
