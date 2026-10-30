# Source pinned to published eyetrajectoriespy 1.2.0
# c1cd95ad718327550f7e55393ff38582872f7a94,
# src/eyetrajectoriespy/recovery_scenarios.py and simulate.py.
# Source class/backend domains remain separately tracked and uncertified.

test_that("fourteen explicit stress designs include covariance and edge regimes",{
  skip_if_not_installed("jsonlite")
  stress<-etr_functional_recovery_stress_scenarios()
  expect_length(stress,14L)
  names<-vapply(stress,function(x)x$name,character(1L))
  expect_identical(names,c(
    "stress_very_sparse","stress_unequal_sample_counts",
    "stress_center_clustered_times","stress_boundary_poor_times",
    "stress_estimated_noise_diagonal_difference",
    "stress_high_measurement_noise","stress_nearly_tied_eigenvalues",
    "stress_heavy_tailed_scores","stress_participant_heavy_hierarchy",
    "stress_trial_heavy_hierarchy","stress_phase_variation",
    "stress_mcar_missingness","stress_block_missingness",
    "stress_correlated_multichannel_noise"))
  expect_true(all(vapply(stress,function(x)
    identical(x$labels$matrix_role,"stress"),logical(1L))))
  expect_true(all(vapply(stress,function(x)
    identical(x$labels$automatic_thresholds,FALSE),logical(1L))))
  expect_identical(vapply(stress,function(x)x$seed_start,integer(1L)),
    204000L+c(0L,100L,200L,300L,350L,400L,500L,600L,
      700L,800L,900L,1000L,1100L,1200L))
  expect_identical(stress[[7L]]$eigenvalues,c(1,.90))
  expect_identical(stress[[8L]]$score_distribution,"student_t")
  expect_identical(stress[[8L]]$score_df,4)
  expect_identical(stress[[9L]]$participant_eigenvalues,c(.60,.20))
  expect_identical(stress[[10L]]$trial_eigenvalues,c(.60,.20))
  expect_identical(stress[[11L]]$phase_variation$kind,"power")
  expect_identical(stress[[12L]]$missingness$kind,"mcar")
  expect_identical(stress[[13L]]$missingness$kind,"block")
  expect_null(stress[[14L]]$measurement_noise_sd)
  expect_identical(stress[[14L]]$dimension_names,c("x","y"))
  expect_equal(stress[[14L]]$measurement_noise_covariance,
    matrix(c(.04,.018,.018,.09),2L,2L),tolerance=0)
  expect_equal(etr_functional_recovery_stress_scenarios(4L)[[14L]]$replicates,4L)
  expect_error(etr_functional_recovery_stress_scenarios(replicates=0L),
    "replicates")
  expect_error(etr_functional_recovery_stress_scenarios(
    seed_start=.Machine$integer.max),"seed_start")
  expect_identical(stress,etr_functional_recovery_stress_scenarios())
})

test_that("source catalogue is ordered and noninferential",{
  skip_if_not_installed("jsonlite")
  tab<-etr_functional_recovery_scenario_catalog_frame(
    qualification_replicates=2L,stress_replicates=4L)
  expect_equal(nrow(tab),18L)
  expect_identical(names(tab)[1:4],
    c("scenario","matrix_role","scientific_target","description"))
  expect_identical(as.character(tab$matrix_role),
    c(rep("qualification",4L),rep("stress",14L)))
  expect_identical(as.integer(tab$replicates),
    c(rep(2L,4L),rep(4L,14L)))
  expect_identical(tab$scenario[1L],"dense_gaussian")
  expect_identical(tab$scenario[18L],
    "stress_correlated_multichannel_noise")
  expect_identical(tab$scientific_target[18L],"mfpca")
  expect_identical(tab$measurement_noise_sd[18L],"null")
  expect_equal(jsonlite::fromJSON(
    tab$measurement_noise_covariance[18L]),
    matrix(c(.04,.018,.018,.09),2L,2L))
  expect_true(all(nzchar(tab$description)))
  expect_equal(ncol(tab),26L)
})

test_that("new stress source contracts remain blocked from full certification",{
  z<-etr_native_parity_catalog()
  for(name in c("functional_recovery_stress_scenarios",
    "functional_recovery_scenario_catalog_frame")){
    row<-z[z$is_python_function & z$python_name==name,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,paste0("etr_",name))
    expect_true(row$native_implementation_started)
    expect_true(row$source_contract_gap_unresolved)
    expect_false(row$one_to_one_native_contract_complete)
  }
  expect_equal(sum(z$is_python_function & z$named_native_candidate),318L)
  expect_equal(sum(z$native_implementation_started),293L)
  expect_equal(sum(z$source_contract_gap_unresolved),140L)
  expect_equal(nrow(z),508L)
})

test_that("published Python 1.2 recovery stress source and full catalogue agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published Python 1.2 stress and catalogue source oracles are opt-in")
  skip_if_not_installed("jsonlite")
  expect_identical(et_python_version(),"1.2.0")
  for(rep in c(1L,4L)){
    py_stress<-reticulate::py_call(
      etpy_get_export("functional_recovery_stress_scenarios"),
      replicates=as.integer(rep),seed_start=as.integer(204000L))
    py_stress_frame<-et_to_r(reticulate::py_call(
      etpy_get_export("functional_simulation_scenario_frame"),
      scenarios=py_stress))
    native<-etr_functional_simulation_scenario_frame(
      etr_functional_recovery_stress_scenarios(rep))
    expect_equal(nrow(py_stress_frame),14L)
    expect_identical(names(py_stress_frame),names(native))
    for(col in c("scenario","n_participants","trials_per_participant",
      "n_curves","n_time_truth","n_components","observation_design",
      "samples_per_curve_min","samples_per_curve_max",
      "irregular_time_design","coordinate_system","time_unit",
      "score_distribution","replicates","seed_start"))
      expect_equal(unname(py_stress_frame[[col]]),
        unname(native[[col]]),info=col)
    for(i in seq_len(14L)){
      for(col in c("eigenvalues","labels",
        "participant_eigenvalues","trial_eigenvalues",
        "missingness","phase_variation","measurement_noise_covariance")){
        p<-py_stress_frame[[col]][i]
        n<-native[[col]][i]
        # Distinguish literal JSON "null" from a genuinely missing
        # pandas cell (None); they are different source output schemas.
        expect_identical(is.na(p),is.na(n),info=paste(i,col))
        if(!is.na(p))expect_equal(jsonlite::fromJSON(p),
          jsonlite::fromJSON(n),info=paste(i,col))
      }
    }
    py_full<-et_to_r(reticulate::py_call(
      etpy_get_export("functional_recovery_scenario_catalog_frame"),
      qualification_replicates=as.integer(2L),
      stress_replicates=as.integer(rep)))
    r_full<-etr_functional_recovery_scenario_catalog_frame(
      qualification_replicates=2L,stress_replicates=rep)
    expect_equal(nrow(py_full),18L)
    expect_identical(names(py_full),names(r_full))
    for(col in c("scenario","matrix_role","scientific_target",
      "description","n_participants","replicates","seed_start"))
      expect_equal(unname(py_full[[col]]),unname(r_full[[col]]),
        info=paste("catalogue",col))
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
