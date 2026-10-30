# Frozen source eyetrajectoriespy 1.2.0, recovery_scenarios.py
# c1cd95ad718327550f7e55393ff38582872f7a94.
test_that("four recovery qualification designs are explicit and deterministic",{
  z<-etr_functional_recovery_qualification_scenarios()
  expect_length(z,4L)
  expect_identical(vapply(z,function(x)x$name,character(1L)),
    c("dense_gaussian","dense_student_t","native_sparse",
      "hierarchy_sources"))
  expect_identical(vapply(z,function(x)x$n_participants,integer(1L)),
    c(200L,200L,64L,300L))
  expect_identical(vapply(z,function(x)x$replicates,integer(1L)),
    rep(3L,4L))
  expect_identical(vapply(z,function(x)x$seed_start,integer(1L)),
    c(202800L,202900L,203000L,203100L))
  expect_equal(vapply(z,function(x)length(x$truth_grid),integer(1L)),
    c(81L,81L,31L,31L))
  expect_identical(z[[2L]]$score_distribution,"student_t")
  expect_identical(z[[2L]]$score_df,6)
  expect_identical(z[[3L]]$observation_design,"irregular")
  expect_identical(z[[3L]]$samples_per_curve,c(8L,12L))
  expect_identical(z[[4L]]$trials_per_participant,2L)
  expect_equal(z[[4L]]$participant_eigenvalues,c(.20,.08))
  expect_equal(z[[4L]]$trial_eigenvalues,c(.10,.04))
  expect_true(all(vapply(z,function(x)
    isTRUE(x$labels$automatic_thresholds),logical(1L))))
  expect_true(all(vapply(z,function(x)
    identical(x$labels$matrix_role,"qualification"),logical(1L))))
  expect_identical(z,etr_functional_recovery_qualification_scenarios())
  expect_error(etr_functional_recovery_qualification_scenarios(0L),
    "replicates")
  expect_error(etr_functional_recovery_qualification_scenarios(
    seed_start=.Machine$integer.max),"seed_start")
})

test_that("recovery designs are traceable and remain uncertified",{
  skip_if_not_installed("jsonlite")
  z<-etr_native_parity_catalog()
  row<-z[z$is_python_function &
    z$python_name=="functional_recovery_qualification_scenarios",,
    drop=FALSE]
  expect_equal(nrow(row),1L)
  expect_identical(row$native_r_candidate,
    "etr_functional_recovery_qualification_scenarios")
  expect_true(row$native_implementation_started)
  expect_true(row$source_contract_gap_unresolved)
  expect_false(row$one_to_one_native_contract_complete)
  expect_equal(nrow(etr_functional_simulation_scenario_frame(
    etr_functional_recovery_qualification_scenarios())),4L)
  expect_equal(sum(z$is_python_function & z$named_native_candidate),322L)
  expect_equal(sum(z$native_implementation_started),297L)
  expect_equal(sum(z$source_contract_gap_unresolved),144L)
})

test_that("frozen Python 1.2 four recovery designs match native source metadata",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 recovery scenario dataclass oracle is opt-in")
  skip_if_not_installed("jsonlite")
  expect_identical(et_python_version(),"1.2.0")
  for(reps in c(1L,3L,6L)){
    python<-reticulate::py_call(
      etpy_get_export("functional_recovery_qualification_scenarios"),
      replicates=as.integer(reps),seed_start=as.integer(202800L))
    source<-reticulate::py_to_r(reticulate::py_call(
      etpy_get_export("functional_simulation_scenario_frame"),
      scenarios=python))
    native<-etr_functional_simulation_scenario_frame(
      etr_functional_recovery_qualification_scenarios(reps))
    expect_identical(names(source),names(native))
    for(name in c("scenario","n_participants","n_curves",
      "trials_per_participant","n_time_truth","n_components",
      "observation_design","samples_per_curve_min",
      "samples_per_curve_max","score_distribution","replicates",
      "seed_start","coordinate_system","time_unit"))
      expect_equal(unname(source[[name]]),unname(native[[name]]),info=name)
    for(i in seq_len(4L)){
      expect_equal(jsonlite::fromJSON(source$eigenvalues[[i]]),
        jsonlite::fromJSON(native$eigenvalues[[i]]),tolerance=0)
      expect_equal(jsonlite::fromJSON(source$labels[[i]]),
        jsonlite::fromJSON(native$labels[[i]]))
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
