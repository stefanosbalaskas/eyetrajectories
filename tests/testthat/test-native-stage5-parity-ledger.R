# Stage 5 improves the native TrajectorySet class representation, NOT a
# new count of published Python callable functions or completed 508 contracts.
test_that("native Stage 5 provenance does not overclaim 508-export parity", {
  was <- reticulate::py_available(initialize=FALSE)
  catalog <- etr_native_parity_catalog()
  expect_equal(nrow(catalog),508L)
  expect_equal(sum(catalog$is_python_function),380L)
  expect_equal(sum(!catalog$is_python_function),128L)
  expect_equal(sum(catalog$named_native_candidate),132L)
  expect_equal(sum(catalog$native_implementation_started),103L)
  expect_equal(sum(catalog$native_implementation_stage==2L,na.rm=TRUE),4L)
  expect_equal(sum(catalog$native_implementation_stage==3L,na.rm=TRUE),7L)
  expect_equal(sum(catalog$native_implementation_stage==4L,na.rm=TRUE),3L)
  record <- catalog[catalog$python_name=="TrajectorySet" &
                    catalog$namespace=="root",,drop=FALSE]
  expect_equal(nrow(record),1L)
  expect_false(record$is_python_function)
  expect_false(record$native_implementation_started)
  expect_false(record$one_to_one_native_contract_complete)
  expect_identical(record$native_representation_stage,5L)
  expect_identical(record$status,
                   "class_or_constant_native_representation_partial")
  expect_equal(sum(!is.na(catalog$native_representation_stage)),7L)
  expect_equal(sum(catalog$status==
    "class_or_constant_native_representation_not_reviewed"),132L)
  expect_true(all(!catalog$one_to_one_native_contract_complete))
  expect_identical(reticulate::py_available(initialize=FALSE),was)
  expect_error(etr_native_parity_catalog(require_complete=TRUE),
               "NOT complete")
})
