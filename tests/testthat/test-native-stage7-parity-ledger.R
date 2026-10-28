# Full 508-symbol source census, Stage 7 cumulative partial candidate counts.
test_that("ten Stage 7 public functions are independently implemented and mapped",{
  was <- reticulate::py_available(initialize=FALSE)
  catalog<-etr_native_parity_catalog()
  names <- c(
    validate_common_grid="etr_validate_common_grid",
    validate_simplex="etr_validate_simplex",
    validate_no_long_missing_runs="etr_validate_no_long_missing_runs",
    from_irregular_long_dataframe_native="etr_from_irregular_long_native",
    common_overlap_interval="etr_common_overlap_interval",
    make_common_grid="etr_make_common_grid",
    resample_irregular_to_grid="etr_resample_irregular_to_grid",
    resample_irregular_to_common_grid="etr_resample_irregular_to_common_grid",
    irregular_sampling_summary="etr_irregular_sampling_summary",
    phase_landmark_frame="etr_phase_landmark_frame")
  expect_equal(nrow(catalog),508L)
  expect_equal(sum(catalog$is_python_function),380L)
  expect_equal(sum(catalog$named_native_candidate),107L)
  expect_equal(sum(catalog$is_python_function &
                   !catalog$named_native_candidate),273L)
  expect_equal(sum(catalog$native_implementation_started),77L)
  expect_equal(sum(catalog$native_implementation_stage==7L,
                   na.rm=TRUE),10L)
  for(name in names(names)){
    row<-catalog[catalog$namespace=="root" &
                 catalog$python_name==name,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,unname(names[[name]]))
    expect_identical(row$native_implementation_stage,7L)
    expect_true(row$native_implementation_started)
    expect_false(row$one_to_one_native_contract_complete)
  }
  for(pair in list(c("TrajectorySet",5L),c("IrregularTrajectorySet",7L))){
    row<-catalog[catalog$namespace=="root" &
                 catalog$python_name==pair[[1L]],,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_false(row$is_python_function)
    expect_identical(row$native_representation_stage,
                     as.integer(pair[[2L]]))
    expect_false(row$one_to_one_native_contract_complete)
  }
  expect_equal(sum(!is.na(catalog$native_representation_stage)),7L)
  expect_equal(sum(catalog$status==
    "class_or_constant_native_representation_not_reviewed"),121L)
  expect_true(all(!catalog$one_to_one_native_contract_complete))
  expect_identical(reticulate::py_available(initialize=FALSE),was)
  expect_error(etr_native_parity_catalog(require_complete=TRUE),
               "NOT complete")
})
