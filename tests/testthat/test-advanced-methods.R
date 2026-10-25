test_that("sparse representation retains original observation times", {
  tt <- list(c(0,.2,1), c(.1,.4,.9), c(0,.5,.8))
  z <- etr_sparse_curves(tt, lapply(tt, sin), c("a","b","c"))
  expect_s3_class(z, "etr_sparse_curves")
  expect_equal(z$times[[2]], tt[[2]])
  expect_error(etr_sparse_curves(tt, list(1:2,1:2,1:2)), "match")
  tt[[1]] <- c(0,.2,.2)
  expect_error(etr_sparse_curves(tt, list(1:3,1:3,1:3)), "strictly increasing")
})

test_that("known-truth hierarchical decomposition respects participant units", {
  sim <- etr_simulate_hierarchical(n_subjects = 10L, n_time = 21L, seed = 123L)
  fit <- etr_fit_multilevel_fpca(sim$trajectories, sim$participant, 2L, 2L)
  expect_s3_class(fit, "etr_multilevel_fpca")
  expect_equal(length(fit$participants), 10L)
  expect_equal(nrow(etr_multilevel_scores(fit)$between), 10L)
  expect_equal(nrow(etr_multilevel_scores(fit)$within), 30L)
  for (g in seq_len(10L)) {
    ix <- which(fit$group_index == g)
    expect_lt(max(abs(apply(fit$residuals[ix,,,drop = FALSE],
                            c(2L,3L), mean))), 1e-12)
  }
  aud <- etr_evaluate_multilevel_recovery(simulations = 3L,
                                          n_subjects = 10L, seed = 6L)
  expect_true(all(is.finite(aud$population_mean_rmse)))
})

test_that("cluster mean bootstrap returns seeded known-truth bands", {
  sim <- etr_simulate_hierarchical(n_subjects = 12L, n_time = 21L, seed = 21L)
  set.seed(9); before <- .Random.seed
  a <- etr_bootstrap_mean_band(sim$trajectories, sim$participant,
                               B = 59L, alpha = .1, seed = 11L)
  expect_identical(.Random.seed, before)
  b <- etr_bootstrap_mean_band(sim$trajectories, sim$participant,
                               B = 59L, alpha = .1, seed = 11L)
  expect_equal(a$simultaneous_lower, b$simultaneous_lower)
  expect_equal(dim(a$mean), c(21L,2L))
  expect_equal(a$independent_clusters, 12L)
  expect_true(all(a$simultaneous_lower <= a$simultaneous_upper))
  aud <- etr_evaluate_mean_band_coverage(simulations = 5L, B = 49L,
                                         n_subjects = 10L, seed = 7L)
  expect_true(is.finite(aud$simultaneous_coverage))
  expect_gte(aud$simultaneous_coverage, 0)
  expect_lte(aud$simultaneous_coverage, 1)
})

test_that("directed discrete dependency is stronger in generating direction", {
  set.seed(100)
  x <- sample(c(0L,1L), 400L, replace = TRUE)
  y <- c(0L, head(x,-1L))
  a <- etr_transfer_entropy(x,y)
  b <- etr_transfer_entropy(y,x)
  expect_gt(a$transfer_entropy_bits, b$transfer_entropy_bits + .3)
  set.seed(8); prior <- .Random.seed
  s <- etr_transfer_entropy_shift_test(x,y,n_surrogates = 39L,seed = 6L)
  expect_identical(.Random.seed, prior)
  expect_gte(s$diagnostic_p, 1/40)
  expect_lte(s$diagnostic_p, 1)
  expect_equal(s$inferential_scope, "descriptive_only")
  expect_error(etr_transfer_entropy(1:50,1:50), "distinct states")
  expect_error(etr_transfer_entropy(x,y,lag = 999L), "lag 1-20")
})

test_that("advanced workflow records explicit decisions", {
  sim <- etr_simulate_hierarchical(n_subjects = 8L, n_time = 21L, seed = 15L)
  ml <- etr_run_multilevel_workflow(sim$trajectories, sim$participant)
  expect_s3_class(ml, "etr_advanced_workflow")
  expect_equal(ml$workflow, "two_level_descriptive_fpca")
  mb <- etr_run_mean_band_workflow(sim$trajectories,sim$participant,
                                   B = 49L, alpha = .1, seed = 8L)
  expect_equal(mb$declared$resampling_unit, "participant")
})

test_that("univariate sparse known-truth generator is independent", {
  sim <- etr_simulate_sparse_known_truth(n_subjects = 20L,
                          min_observations = 5L, max_observations = 8L, seed = 20L)
  expect_equal(length(sim$curves$times), 20L)
  expect_equal(dim(sim$true_curves), c(20L,101L))
  expect_true(all(lengths(sim$curves$times) >= 5L))
  expect_true(all(lengths(sim$curves$times) <= 8L))
})

test_that("optional fdapace interface returns native R score and fit frames", {
  skip_if_not_installed("fdapace", minimum_version = "0.6.0")
  sim <- etr_simulate_sparse_known_truth(n_subjects = 35L, seed = 44L)
  fit <- etr_fit_sparse_pace(sim$curves, max_components = 2L,
                             options = list(nRegGrid = 31L))
  expect_s3_class(fit, "etr_sparse_pace")
  expect_identical(fit$backend, "fdapace")
  expect_equal(nrow(etr_sparse_pace_scores(fit)),35L)
  pred <- etr_sparse_pace_fitted(fit)
  expect_equal(dim(pred$fitted), c(35L,length(pred$time)))
})
