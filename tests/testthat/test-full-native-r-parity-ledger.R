# Offline parity ledger checks: source API != native R mathematical parity.
test_that("strict register covers all 508 Python public exports without Python", {
  started <- reticulate::py_available(initialize=FALSE)
  z <- etr_native_parity_catalog()
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function),380L)
  expect_equal(sum(!z$is_python_function),128L)
  expect_equal(sum(z$native_implementation_started),302L)
  # The authoritative exact current census lives only in this ledger.
  # Historical scientific integration suites assert milestone floors/ceilings.
  mapped <- sum(z$is_python_function & z$named_native_candidate)
  unmapped <- sum(z$is_python_function & !z$named_native_candidate)
  expect_equal(mapped,327L)
  expect_equal(unmapped,53L)
  expect_equal(mapped+unmapped,380L)
  expect_equal(sum(z$source_contract_gap_known),149L)
  expect_equal(sum(z$source_contract_gap_unresolved),149L)
  expect_true(all(z$one_to_one_native_contract_complete==FALSE))
  expect_true(all(z$independent_numeric_parity_pass==FALSE))
  expect_true(all(z$scientific_inference_qualified==FALSE))
  expect_true(all(z$python_bridge_available))
  expect_true(all(z$named_native_candidate[z$native_implementation_started]))
  expect_identical(reticulate::py_available(initialize=FALSE),started)
  expect_error(etr_native_parity_catalog(require_complete=TRUE),
               "NOT complete")
  expect_error(etr_native_parity_catalog(require_complete=NA),
               "TRUE or FALSE")
})

test_that("four new native implementation names map one-to-one to public Python names", {
  z <- etr_native_parity_catalog()
  analogues <- c(
    acceleration_magnitude_function="etr_acceleration_magnitude",
    distance_to_landmark_function="etr_distance_to_landmark",
    signed_curvature_function="etr_signed_curvature",
    turning_rate_function="etr_turning_rate")
  for(n in names(analogues)) {
    row <- z[z$namespace=="root" & z$python_name==n,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,unname(analogues[[n]]))
    expect_true(row$native_implementation_started)
    expect_identical(row$status,
       "native_algorithm_implemented_qualification_pending")
    expect_false(row$one_to_one_native_contract_complete)
  }
})

test_that("classes and constants are separately tracked, not called native algorithms",{
  z <- etr_native_parity_catalog()
  others <- z[!z$is_python_function,,drop=FALSE]
  expect_equal(nrow(others),128L)
  stage5 <- others[others$python_name=="TrajectorySet" &
                    others$namespace=="root",,drop=FALSE]
  expect_equal(nrow(stage5),1L)
  expect_identical(stage5$status,
                   "class_or_constant_native_representation_partial")
  expect_identical(stage5$native_representation_stage,5L)
  pending <- others[is.na(others$native_representation_stage),,drop=FALSE]
  expect_equal(nrow(pending),121L) # 128 non-functions minus 7 partial representations
  expect_true(all(pending$status==
     "class_or_constant_native_representation_not_reviewed"))
  expect_false(any(others$native_implementation_started))
})
