# Stage 6: preserve the entire fail-closed inventory while mapping exactly
# one new Python 1.2 callable to a deliberately limited native R reader.
test_that("maps Python portable-result loader only as a candidate", {
  was <- reticulate::py_available(initialize=FALSE)
  register <- etr_native_parity_catalog()
  expect_equal(nrow(register),508L)
  expect_equal(sum(register$is_python_function),380L)
  expect_gte(sum(register$named_native_candidate),236L)
  expect_gte(sum(register$native_implementation_started),211L)
  expect_equal(sum(register$native_implementation_stage==2L,na.rm=TRUE),4L)
  expect_equal(sum(register$native_implementation_stage==3L,na.rm=TRUE),7L)
  expect_equal(sum(register$native_implementation_stage==4L,na.rm=TRUE),3L)
  expect_equal(sum(register$native_implementation_stage==6L,na.rm=TRUE),1L)
  row <- register[register$python_name=="load_portable_result" &
                  register$namespace=="root",,drop=FALSE]
  expect_equal(nrow(row),1L)
  expect_identical(row$native_r_candidate,"etr_read_python_portable_result")
  expect_identical(row$native_implementation_stage,6L)
  expect_true(row$native_implementation_started)
  expect_false(row$one_to_one_native_contract_complete)
  expect_false(row$behavioral_schema_parity_pass)
  expect_false(row$independent_numeric_parity_pass)
  expect_equal(sum(!is.na(register$native_representation_stage)),7L)
  expect_equal(sum(nzchar(register$nonfunction_native_representation)),32L)
  expect_equal(sum(!nzchar(register$nonfunction_native_representation) &
    !register$is_python_function),96L)
  expect_equal(sum(register$status==
     "class_or_constant_native_representation_not_reviewed"),121L)
  expect_true(all(!register$one_to_one_native_contract_complete))
  expect_identical(reticulate::py_available(initialize=FALSE),was)
  expect_error(etr_native_parity_catalog(require_complete=TRUE),
               "NOT complete")
})
