# Developer-only full-domain semantic closure checks for the TWO
# zero-argument immutable metadata frames in frozen eyetrajectoriespy 1.2.0.
# Source commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Python pandas.DataFrame <-> native R data.frame is an explicitly documented
# cross-language representation equivalence, NOT Python class identity.
# No independent full-contract certification is asserted.

.etr_verify_zeroarg_semantic_frame <- function(native_fun,python_name,
    expected_rows,expected_columns) {
  frame <- native_fun()
  expect_s3_class(frame,"data.frame")
  expect_identical(nrow(frame),expected_rows)
  expect_identical(names(frame),expected_columns)
  expect_true(all(vapply(frame,is.character,logical(1L))))
  expect_true(all(vapply(frame,function(x)
    length(x)==expected_rows && !anyNA(x),logical(1L))))
  expect_equal(length(formals(native_fun)),0L)
  expect_error(native_fun(1L))
  expect_error(native_fun(unexpected_argument=TRUE))
  # Native immutable source fixture: caller mutation may not alter the
  # subsequently returned source rows or their exact byte contents.
  modified <- frame
  modified[[1L]][1L] <- "MUTATED_BY_TEST"
  expect_identical(native_fun(),frame)

  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("full-domain source Python 1.2 oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  target <- etpy_get_export(python_name)
  py <- reticulate::py_call(target)
  expect_true(reticulate::py_has_attr(py,"columns"))
  original <- as.data.frame(et_to_r(py),stringsAsFactors=FALSE,
    check.names=FALSE)
  expect_identical(nrow(original),expected_rows)
  expect_identical(names(original),expected_columns)
  for(name in expected_columns) {
    actual <- enc2utf8(as.character(frame[[name]]))
    published <- enc2utf8(as.character(original[[name]]))
    expect_identical(actual,published,
      info=paste("Frozen 1.2 source mismatch for",python_name,
        "column",name))
    expect_identical(charToRaw(paste(actual,collapse="\n")),
      charToRaw(paste(published,collapse="\n")),
      info=paste("UTF-8 bytes mismatch for",python_name,name))
  }
  # Both published functions have def f() signatures. Reject any
  # additional argument in Python as well as native R.
  expect_error(reticulate::py_call(target,
    reticulate::r_to_py(1L)))
  expect_error(reticulate::py_call(target,
    unexpected_argument=TRUE))
}

test_that("27-row frozen recovery metric frame is semantic zero-arg exact",{
  .etr_verify_zeroarg_semantic_frame(
    etr_functional_recovery_metric_catalog_frame,
    "functional_recovery_metric_catalog_frame",27L,
    c("metric","quantity","direction","units","scope","description"))
})

test_that("88-row frozen mathematical contract frame is semantic zero-arg exact",{
  .etr_verify_zeroarg_semantic_frame(
    etr_mathematical_contract_frame,
    "mathematical_contract_frame",88L,
    c("contract_key","title","function","latex","site_anchor","scope"))
})

test_that("exact semantic frames clear only their historical source-gap flags",{
  catalog <- etr_native_parity_catalog()
  for(name in c("functional_recovery_metric_catalog_frame",
                "mathematical_contract_frame")) {
    row <- catalog[catalog$is_python_function &
      catalog$python_name==name,,drop=FALSE]
    expect_identical(nrow(row),1L)
    expect_true(row$source_contract_gap_known)
    expect_false(row$source_contract_gap_unresolved)
    expect_false(row$one_to_one_native_contract_complete)
    expect_false(row$independent_numeric_parity_pass)
  }
  witness<-utils::read.csv(.etr_test_extdata(
    "native_source_contract_gaps_stage22.csv"),
    stringsAsFactors=FALSE,check.names=FALSE)
  expect_identical(sum(catalog$is_python_function &
    catalog$source_contract_gap_unresolved),
    as.integer(sum(witness$unresolved_source_gap)))
  # The current authoritative nonfunction gap ledger has no open entries.
  # That closes its author-scoped gap flag, NOT independent certification.
  expect_false(any(catalog$nonfunction_source_gap_unresolved))
  expect_false(any(catalog$one_to_one_native_contract_complete))
})
