# Fail closed if historical certification evidence points to stale test names.
# Pilot evidence must remain resolvable after stage-free R/test refactors.
test_that("every pinned numerical pilot oracle resolves to an actual test",{
  register<-utils::read.csv(system.file("extdata",
    "native_contract_certification_pilots_v1.csv",
    package="eyetrajectories"),stringsAsFactors=FALSE)
  expect_equal(nrow(register),4L)
  expect_true(all(grepl("^tests/testthat/test-native-.*\\.R$",
    register$independent_oracle_suite)))
  expect_false(any(grepl("stage",basename(
    register$independent_oracle_suite),ignore.case=TRUE)))
  # testthat may execute from the package root or tests/testthat.
  roots<-c(".","../..","../../..")
  paths_resolve<-vapply(register$independent_oracle_suite,
    function(path)any(file.exists(file.path(roots,path))),
    logical(1L))
  expect_true(all(paths_resolve),
    info=paste("stale pinned oracle paths:",
      paste(register$independent_oracle_suite[!paths_resolve],
        collapse=", ")))
  api<-etr_native_parity_catalog()
  expect_equal(sum(api$contract_certification_candidate),4L)
  expect_equal(sum(api$contract_numerical_fixture_pass),4L)
  expect_false(any(api$one_to_one_native_contract_complete))
  expect_true(all(api$source_contract_gap_unresolved[
    api$contract_certification_candidate]))
})

test_that("new frozen inference source witnesses cannot self-approve",{
  z<-etr_native_certification_readiness_frame()
  names<-c("select_fpca_wild_bootstrap_truncation",
    "fpca_wild_bootstrap_projection_frame",
    "fpca_wild_bootstrap_simultaneous_frame",
    "fpca_wild_bootstrap_family_test_frame",
    "fpca_wild_bootstrap_monte_carlo_diagnostic_frame")
  actual<-z[z$python_name%in%names,,drop=FALSE]
  expect_equal(nrow(actual),5L)
  expect_true(all(actual$native_mapping_present))
  expect_true(all(actual$native_implementation_started))
  expect_true(all(actual$published_source_difference_open))
  expect_false(any(actual$fully_certified))
  expect_true(all(grepl("independent_review_approval_missing",
    actual$all_unresolved_requirements,fixed=TRUE)))
})
