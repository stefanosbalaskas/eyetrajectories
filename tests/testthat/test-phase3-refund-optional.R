test_that("optional refund pffr functional response model runs on a minimal nested design", {
  skip_if_not_installed("refund")
  sim <- etr_simulate_hierarchical(n_subjects = 8L,
                                   trials_per_subject = 2L,
                                   n_time = 17L, seed = 65L)
  x <- sim$trajectories
  one <- etr_trajectory_set(x$time, x$values[, , 1L, drop = FALSE],
                             x$curve_ids, "x", x$metadata,
                             x$coordinate_system, x$time_unit)
  fit <- etr_fit_functional_mixed(one, participant = "participant", basis_k = 6L)
  expect_s3_class(fit, "etr_functional_mixed")
  expect_equal(fit$backend, "refund::pffr")
  pred <- etr_functional_mixed_fitted(fit)
  expect_identical(pred$status, "experimental_model_unqualified")
  expect_true(is.matrix(pred$fitted) || is.numeric(pred$fitted))
})
