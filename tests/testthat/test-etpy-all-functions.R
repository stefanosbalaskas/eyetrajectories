test_that("all source Python callable exports have explicit R proxy functions", {
  cat <- etpy_catalog()
  expect_equal(nrow(cat), 380L)
  expect_equal(sum(cat$namespace == "root"), 362L)
  expect_equal(sum(cat$namespace == "workflows"), 18L)
  expect_equal(length(unique(cat$r_wrapper)), 380L)
  expect_true(all(cat$kind == "function"))
  for (name in cat$r_wrapper)
    expect_true(exists(name, mode = "function", inherits = FALSE,
                       envir = asNamespace("eyetrajectories")),
                info = name)
  all <- etpy_catalog(include_nonfunctions = TRUE)
  expect_equal(nrow(all), 508L)
  expect_equal(sum(all$namespace == "root"), 458L)
  expect_equal(sum(all$namespace == "workflows"), 50L)
  expect_equal(sum(all$kind == "other_export"), 128L)
  expect_error(etpy_catalog(NA), "include_nonfunctions")
  expect_error(etpy_verify_api(strict = NA), "strict")
  expect_error(etpy_get_export("invalid symbol"), "identifier")
})

test_that("actual installed Python exports are callable where declared", {
  if (!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"), "true"))
    skip("Full Python function verification is opt-in")
  live <- etpy_verify_api(strict = FALSE)
  expect_equal(nrow(live), 380L)
  failed <- live$python_name[!live$available | !live$callable]
  if (length(failed) > 0L) {
    testthat::fail(paste0(
      "Unavailable or noncallable Python exports: ",
      paste(utils::head(failed, 20L), collapse = ", "),
      if (length(failed) > 20L) " ..." else ""
    ))
  }
  expect_length(failed, 0L)
  expect_identical(unique(live$installed_python_version), "1.2.0")
  is_callable <- function(x) isTRUE(reticulate::py_to_r(
    reticulate::import_builtins(convert = FALSE)$callable(x)))
  expect_true(is_callable(etpy_get_export("fit_fpca")))
  expect_true(is_callable(
    etpy_get_export("run_fpca_workflow", .namespace = "workflows")))
})


test_that("Python-backed explicit R wrappers execute the common-grid pipeline", {
  if (!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"), "true"))
    skip("Python direct R wrapper execution is opt-in")
  trajectories <- etpy_simulate_planar_trajectories(
    n_participants = 4L, trials_per_participant = 2L,
    n_time = 31L, random_state = 2026L
  )
  expect_equal(as.integer(et_to_r(trajectories$n_curves)), 8L)
  fit <- etpy_fit_mfpca(trajectories, n_components = 1L,
                        scaling = "dimension_sd")
  score_frame <- etpy_fpca_score_frame(fit, .convert = TRUE)
  expect_s3_class(score_frame, "data.frame")
  expect_equal(nrow(score_frame), 8L)
  configuration <- et_call("FPCAWorkflowConfig", n_components = 1L,
                           scaling = "dimension_sd", .namespace = "workflows")
  workflow <- etpy_workflow_run_fpca_workflow(trajectories, config = configuration)
  expect_true(reticulate::py_has_attr(workflow, "fit"))
  expect_s3_class(etpy_fpca_score_frame(workflow$fit, .convert = TRUE),
                  "data.frame")
})
