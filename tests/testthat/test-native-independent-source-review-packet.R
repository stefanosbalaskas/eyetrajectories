test_that("independent source-review packet is safe and fully unsigned",{
  path<-testthat::test_path("..","..","scripts",
    "prepare_independent_source_review.R")
  expect_true(file.exists(path))
  expect_silent(parse(file=path,keep.source=FALSE))
  source_lines<-readLines(path,warn=FALSE)
  for(term in c("source_full_domain_review=FALSE",
    "invalid_input_error_domain_review=FALSE",
    "independently_replayed_python_oracle=FALSE",
    "independently_replayed_native_r=FALSE",
    "estimand_scientific_review=FALSE",
    "reviewer_independent_of_authors=FALSE",
    'review_decision="PENDING_INDEPENDENT_REVIEW"',
    "fully_certified=FALSE",
    "file_integrity_manifest.csv",
    "native_r_offline.txt",
    "python_1_2_direct_source.txt",
    "native_source_contract_gaps_stage22.csv","head",
    "four_numerical_pilots_external_review_priority.csv",
    "nrow(pilot)==4L")){
    expect_true(any(grepl(term,source_lines,fixed=TRUE)),
      info=paste("expected independent evidence safeguard",term))
  }
  # The packet builder may never alter the authoritative approval registers.
  expect_false(any(grepl(
    "write\\.csv\\(.*native_contract_certification_pilots_v1",
    source_lines)))
  expect_false(any(grepl(
    "write\\.csv\\(.*native_nonfunction_contract_review_v1",
    source_lines)))
})
