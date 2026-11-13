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
  # Four published numerical pilot records remain pinned. A fifth,
  # TrajectorySet, is a bounded author-scoped nonfunction candidate,
  # NOT a passed numerical fixture or independent certificate.
  pilots<-api[api$python_name%in%register$python_name,,drop=FALSE]
  expect_identical(nrow(pilots),nrow(register))
  expect_true(all(pilots$contract_certification_candidate))
  expect_true(all(pilots$contract_numerical_fixture_pass))
  expect_identical(sum(api$contract_numerical_fixture_pass),4L)
  extra<-api[api$contract_certification_candidate &
    !api$python_name%in%register$python_name,,drop=FALSE]
  expect_setequal(extra$python_name,"TrajectorySet")
  expect_false(any(extra$contract_numerical_fixture_pass))
  expect_false(any(api$one_to_one_native_contract_complete))
  # A numerical pilot can be promoted after a SHA256-pinned
  # full-source author review; keep unsigned independent gates closed.
  receipts<-utils::read.csv(system.file("extdata",
    "reviewed_source_contract_closures_v1.csv",
    package="eyetrajectories"),stringsAsFactors=FALSE)
  closed_candidates<-api$python_name[
    api$contract_certification_candidate &
    !api$source_contract_gap_unresolved]
  expect_true(all(closed_candidates %in% receipts$python_name))
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
  # Source gaps close via the audited 508-export ledger; an unresolved
  # independent reviewer approval remains mandatory even when source closes.
  ledger<-utils::read.csv(system.file("extdata",
    "native_source_contract_gaps_stage22.csv",
    package="eyetrajectories"),stringsAsFactors=FALSE)
  witness<-ledger[match(actual$python_name,ledger$python_name),,drop=FALSE]
  expect_false(anyNA(witness$python_name))
  expect_identical(as.logical(actual$published_source_difference_open),
    as.logical(witness$unresolved_source_gap))
  expect_false(any(actual$fully_certified))
  expect_true(all(grepl("independent_review_approval_missing",
    actual$all_unresolved_requirements,fixed=TRUE)))
})
