test_that("analytic multilevel variance agrees with independent exact trace", {
  time <- seq(0,1,length.out = 11L)
  expect_equal(etr_analytic_between_variance(time, 3L,
                   subject_sd = .4, trial_sd = 0, noise_sd = 0),
               .16, tolerance = 1e-12)
  expect_equal(etr_analytic_between_variance(time, 2L,
                   subject_sd = 0, trial_sd = 0, noise_sd = .1),
               .01, tolerance = 1e-12)
  z <- etr_evaluate_between_variance(simulations = 5L,
                                     n_subjects = 10L, n_time = 11L, seed = 55L)
  expect_equal(length(z$observed), 5L)
  expect_true(is.finite(z$analytic_truth))
  expect_true(all(is.finite(z$observed)))
  expect_true(is.finite(z$mc_se_of_mean))
  expect_true(is.finite(z$rmse))
})

test_that("participant-level eigenvalue bootstrap refits and retains failures", {
  s <- etr_simulate_hierarchical(n_subjects = 8L, n_time = 11L, seed = 29L)
  bs <- etr_bootstrap_fpca_spectrum(s$trajectories, s$participant,
                                    n_components = 2L, B = 39L, seed = 14L)
  expect_equal(length(bs$eigenvalues), 2L)
  expect_equal(nrow(bs$replicates), 39L)
  expect_equal(bs$successes + bs$failures, 39L)
  expect_true(all(is.finite(bs$eigenvalues)))
  expect_equal(bs$inference_scope,
               "exploratory_cluster_bootstrap_spectrum_no_calibration")
})
