# Offline native stage 4 audit, never initializes Python.
test_that("stage4 maps exactly three Python public function contracts to R", {
  started <- reticulate::py_available(initialize=FALSE)
  catalog <- etr_native_parity_catalog()
  target <- c(
    discrete_frechet_distance="etr_discrete_frechet",
    dynamic_time_warping_distance="etr_dynamic_time_warping",
    pairwise_dynamic_time_warping_distances="etr_pairwise_dtw_full"
  )
  expect_equal(nrow(catalog),508L)
  expect_equal(sum(catalog$is_python_function),380L)
  expect_equal(sum(catalog$named_native_candidate),139L)
  expect_equal(sum(catalog$native_implementation_started),110L)
  expect_equal(sum(catalog$native_implementation_stage==2L,na.rm=TRUE),4L)
  expect_equal(sum(catalog$native_implementation_stage==3L,na.rm=TRUE),7L)
  expect_equal(sum(catalog$native_implementation_stage==4L,na.rm=TRUE),3L)
  for(name in names(target)){
    row <- catalog[catalog$python_name==name &
                   catalog$namespace=="root",,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,unname(target[[name]]))
    expect_identical(row$native_implementation_stage,4L)
    expect_true(row$native_implementation_started)
    expect_false(row$one_to_one_native_contract_complete)
  }
  expect_true(all(!catalog$one_to_one_native_contract_complete))
  expect_true(all(!catalog$independent_numeric_parity_pass))
  expect_identical(reticulate::py_available(initialize=FALSE),started)
  expect_error(etr_native_parity_catalog(require_complete=TRUE),
               "NOT complete")
})
