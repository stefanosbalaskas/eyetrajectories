# Synthetic input fixture exercises output schema, not independent approval.
test_that("four pilot review matrix is complete and never self-certifying",{
  root<-testthat::test_path("..","..")
  if(!nzchar(Sys.which("git")))
    skip("git is required for the exact-source-head reviewer evidence check")
  env<-new.env(parent=baseenv())
  sys.source(file.path(root,"scripts",
    "build_four_pilot_review_matrix.R"),envir=env)
  git<-Sys.which("git")
  head<-suppressWarnings(system2(git,
    c("-C",shQuote(normalizePath(root,winslash="/")),
      "rev-parse","HEAD"),stdout=TRUE,stderr=FALSE))
  expect_identical(length(head),1L)
  stopifnot(grepl("^[0-9a-f]{40}$",head))
  packet<-tempfile("synthetic_four_pilots_")
  dir.create(packet)
  on.exit(unlink(packet,recursive=TRUE),add=TRUE)
  status<-data.frame(evidence_bundle="synthetic_test_not_review",
    recorded_r_git_head=head,checkout_matches_evidence=TRUE,
    source_file_manifest_matches_checkout=TRUE,
    native_suite_pass=TRUE,pinned_python_suite_pass=TRUE,
    independent_review_approved=FALSE,
    full_source_contract_certified=FALSE)
  registry<-utils::read.csv(file.path(root,"inst","extdata",
    "native_contract_certification_pilots_v1.csv"),
    stringsAsFactors=FALSE,check.names=FALSE)
  gaps<-utils::read.csv(file.path(root,"inst","extdata",
    "native_source_contract_gaps_stage22.csv"),
    stringsAsFactors=FALSE,check.names=FALSE)
  idx<-match(registry$python_name,gaps$python_name)
  expect_false(anyNA(idx))
  pilot<-data.frame(python_name=registry$python_name,
    native_r_candidate=registry$native_r_candidate,
    frozen_python_source=registry$source_path,
    pinned_python_commit=registry$published_tag_commit,
    source_gap_kind=gaps$gap_kind[idx],
    documented_boundary_difference=gaps$known_source_difference[idx],
    required_full_domain_resolution=gaps$review_resolution[idx],
    original_numeric_fixture_pass=registry$numerical_fixture_pass,
    full_accepted_input_domain_approved=FALSE,
    complete_error_semantics_approved=FALSE,
    scientific_scope_approved=FALSE,
    independent_reviewer_approved=FALSE)
  utils::write.csv(status,file.path(packet,
    "evidence_bundle_status.csv"),row.names=FALSE)
  utils::write.csv(pilot,file.path(packet,
    "four_numerical_pilots_external_review_priority.csv"),
    row.names=FALSE)
  z<-env$etr_build_four_pilot_review_matrix(
    root=root,packet_dir=packet)
  expect_true(file.exists(z$csv))
  expect_true(file.exists(z$worksheet))
  expect_identical(nrow(z$matrix),16L)
  expect_identical(length(unique(z$matrix$python_name)),4L)
  expect_identical(sum(z$matrix$reviewer_relation==
    "documented_source_difference"),4L)
  expect_true(all(z$matrix$aggregate_suite_pass_only))
  expect_false(any(z$matrix$independently_replayed_case))
  expect_false(any(z$matrix$fully_certified))
  expect_false(any(nzchar(z$matrix$reviewer_identity)))
  status$recorded_r_git_head<-paste(rep("0",40L),collapse="")
  utils::write.csv(status,file.path(packet,
    "evidence_bundle_status.csv"),row.names=FALSE)
  expect_error(env$etr_build_four_pilot_review_matrix(
    root=root,packet_dir=packet),"Current checkout differs")
})

test_that("four-pilot capture requirements never repeat a test filename",{
  runner<-testthat::test_path("..","..","scripts",
    "capture_native_source_qualification_evidence.R")
  src<-paste(readLines(runner,warn=FALSE),collapse="\n")
  first<-regexpr("required_scientific_tests<-file.path",src,
    fixed=TRUE)[[1L]]
  next_statement<-regexpr("if(anyDuplicated(required_scientific_tests))",
    src,fixed=TRUE)[[1L]]
  expect_true(first>0L&&next_statement>first)
  if(first<=0L||next_statement<=first)
    stop("Cannot locate capture test discovery boundary",call.=FALSE)
  block<-substr(src,first,next_statement-1L)
  matches<-regmatches(block,gregexpr(
    '"native-[^"]+"',block,perl=TRUE))[[1L]]
  expect_true(length(matches)>50L)
  expect_identical(anyDuplicated(matches),0L)
  expect_identical(sum(matches=='"native-four-pilot-review-matrix"'),1L)
})

test_that("ten paired pilot source witnesses stay source-run and noncertifying",{
  root<-testthat::test_path("..","..")
  path<-file.path(root,"scripts",
    "capture_four_pilot_numeric_evidence.R")
  runner<-file.path(root,"scripts",
    "capture_native_source_qualification_evidence.R")
  expect_true(file.exists(path))
  expect_silent(parse(file=path,keep.source=FALSE))
  code<-readLines(path,warn=FALSE)
  capture<-readLines(runner,warn=FALSE)
  for(name in c("alr_transform","inverse_alr",
    "score_distance_matrix","functional_trapezoid_weights")){
    expect_true(any(grepl(paste0('etpy_get_export("',name,'")'),
      code,fixed=TRUE)),info=paste("Missing frozen-source call",name))
  }
  expect_true(any(grepl("nrow(rows)==10L",code,fixed=TRUE)))
  expect_true(any(grepl(
    "all(rows$developer_numeric_fixture_pass)",code,fixed=TRUE)))
  expect_true(any(grepl(
    "rows$independently_replayed_case|rows$fully_certified",
    code,fixed=TRUE)))
  expect_true(any(grepl(
    "source(\"scripts/capture_four_pilot_numeric_evidence.R\"",
    capture,fixed=TRUE)))
  expect_true(any(grepl(
    '"scripts/capture_four_pilot_numeric_evidence.R"',
    capture,fixed=TRUE)))
  expect_false(any(grepl(
    "independent_reviewer_approved=TRUE",code,fixed=TRUE)))
  expect_false(any(grepl(
    "fully_certified=TRUE",code,fixed=TRUE)))
})
