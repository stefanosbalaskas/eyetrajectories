test_that("stage 3 port mapping covers exact Python 1.2 named contracts", {
  py_before <- reticulate::py_available(initialize=FALSE)
  z <- etr_native_parity_catalog()
  expected <- c(
    normalize_coordinates="etr_normalize_coordinates",
    center_on_landmark="etr_center_on_landmark",
    normalize_time="etr_normalize_time_interval",
    heading_function="etr_heading_function",
    trajectory_tortuosity="etr_trajectory_tortuosity_frame",
    pairwise_discrete_frechet_distances="etr_pairwise_frechet",
    nearest_trajectory_indices="etr_nearest_trajectory_indices"
  )
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_equal(sum(z$named_native_candidate),225L)
  expect_equal(sum(z$native_implementation_started),200L)
  expect_equal(sum(z$native_implementation_stage==2L,na.rm=TRUE),4L)
  expect_equal(sum(z$native_implementation_stage==3L,na.rm=TRUE),7L)
  for (name in names(expected)) {
    row <- z[z$namespace=="root" & z$python_name==name,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,unname(expected[[name]]))
    expect_identical(row$native_implementation_stage,3L)
    expect_true(row$native_implementation_started)
    expect_false(row$one_to_one_native_contract_complete)
  }
  expect_false(any(z$independent_numeric_parity_pass))
  expect_identical(reticulate::py_available(initialize=FALSE),py_before)
  expect_error(etr_native_parity_catalog(require_complete=TRUE),
               "NOT complete")
})
