test_that("Python 1.2.0 bridge generates valid MFPCA results", {
  if (!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"), "true")) {
    skip("Python bridge integration tests are opt-in")
  }

  expect_equal(et_python_version(), "1.2.0")
  trajectories <- et_simulate_planar(
    n_participants = 6L,
    trials_per_participant = 2L,
    n_time = 41L,
    random_state = 7L
  )
  expect_equal(as.integer(et_to_r(trajectories$n_curves)), 12L)

  fit <- et_fit_mfpca(trajectories, n_components = 0.95,
                      scaling = "dimension_sd")
  scores <- et_scores(fit)
  expect_s3_class(scores, "data.frame")
  expect_equal(nrow(scores), 12L)
  expect_true("curve_id" %in% names(scores))
  expect_true(any(grepl("^FPC", names(scores))))
  ev <- et_explained_variance(fit)
  expect_true(is.numeric(ev))
  expect_true(all(is.finite(ev)))
  expect_true(all(ev >= 0))

  # Independent R-to-Python dispatch parity check against the same backend.
  direct <- et_python()$fit_mfpca(
    trajectories, n_components = 0.95, scaling = "dimension_sd"
  )
  expect_equal(ev, et_to_r(direct$explained_variance_ratio),
               tolerance = 1e-12)
  workflow <- et_run_fpca_workflow(trajectories, n_components = 0.95,
                                  scaling = "dimension_sd")
  expect_true(reticulate::py_has_attr(workflow, "fit"))
  expect_s3_class(et_scores(workflow$fit), "data.frame")
})

test_that("R data frames cross the bridge without synthetic preprocessing", {
  if (!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"), "true")) {
    skip("Python bridge integration tests are opt-in")
  }

  gaze_long <- data.frame(
    participant = rep(c("p1", "p2"), each = 8L),
    time = rep(seq(0, 1, length.out = 8L), times = 2L)
  )
  gaze_long$x <- gaze_long$time + as.numeric(gaze_long$participant == "p2")
  gaze_long$y <- gaze_long$time^2

  trajectories <- et_from_long(
    gaze_long,
    curve_columns = "participant",
    time_column = "time",
    value_columns = c("x", "y"),
    coordinate_system = "normalized",
    time_unit = "s"
  )
  expect_equal(as.integer(et_to_r(trajectories$n_curves)), 2L)
  expect_equal(as.integer(et_to_r(trajectories$n_time)), 8L)
  fit <- et_fit_mfpca(trajectories, n_components = 1L)
  expect_equal(nrow(et_scores(fit)), 2L)
})

test_that("matplotlib figures can be saved by the bridge", {
  if (!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"), "true")) {
    skip("Python bridge integration tests are opt-in")
  }

  gaze <- et_simulate_planar(
    n_participants = 2L, trials_per_participant = 2L,
    n_time = 15L, random_state = 4L
  )
  # The test writes a PNG; it must never require a GUI/Tcl/Tk renderer.
  reticulate::import("matplotlib", convert = FALSE)$use("Agg", force = TRUE)
  axes <- et_plot_planar(gaze)
  output <- tempfile(fileext = ".png")
  on.exit(unlink(output), add = TRUE)
  expect_identical(et_save_plot(axes, output), output)
  expect_true(file.exists(output))
  expect_gt(file.info(output)$size, 0)
})
