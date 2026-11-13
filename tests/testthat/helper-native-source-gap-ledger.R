# All author-scoped source gap expectations derive from the current frozen
# inventory, not historical counts from an earlier development wave.
# An author-closed difference never represents independent certification.
.etr_test_source_gap_ledger<-function() {
  path<-system.file("extdata","native_source_contract_gaps_stage22.csv",
    package="eyetrajectories")
  stopifnot(nzchar(path),file.exists(path))
  rows<-utils::read.csv(path,stringsAsFactors=FALSE,check.names=FALSE)
  stopifnot(all(c("python_name","unresolved_source_gap")%in%names(rows)),
    !anyDuplicated(rows$python_name),
    is.logical(rows$unresolved_source_gap),
    !anyNA(rows$unresolved_source_gap))
  rows
}
.etr_expect_source_gap_matches_registry<-function(rows) {
  ledger<-.etr_test_source_gap_ledger()
  idx<-match(as.character(rows$python_name),ledger$python_name)
  expected<-rep(FALSE,nrow(rows))
  present<-!is.na(idx)
  expected[present]<-ledger$unresolved_source_gap[idx[present]]
  testthat::expect_identical(as.logical(rows$source_contract_gap_unresolved),
    expected)
  testthat::expect_false(any(rows$one_to_one_native_contract_complete))
  invisible(TRUE)
}
.etr_expect_source_gap_count<-function(rows) {
  ledger<-.etr_test_source_gap_ledger()
  testthat::expect_identical(
    as.integer(sum(rows$source_contract_gap_unresolved)),
    as.integer(sum(ledger$unresolved_source_gap)))
  invisible(TRUE)
}
