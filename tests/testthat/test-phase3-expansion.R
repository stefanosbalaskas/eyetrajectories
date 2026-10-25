# Phase 3 extension tests use generated mathematical data; they do not
# represent observed human-subject studies or coverage qualification.

test_that("sparse support diagnostics are observation-only", {
  times <- list(c(0,.2,1), c(.1,.4,.9), c(0,.5,.8))
  x <- etr_sparse_curves(times, lapply(times, sin), c("a","b","c"))
  d <- etr_sparse_design_diagnostics(x, bins = 4L)
  expect_equal(d$summary$n_curves, 3L)
  expect_equal(d$summary$n_observations, 9L)
  expect_equal(nrow(d$support), 4L)
  expect_true(all(d$support$fraction_observed >= 0))
  expect_true(all(d$support$fraction_observed <= 1))
  expect_equal(d$curves$visits, c(3L,3L,3L))
  expect_identical(d$provenance, "observed_support_only_no_interpolation")
  expect_error(etr_sparse_design_diagnostics(x, bins = 1L), "bins must")
})

test_that("continuous discretization is explicit and deterministic", {
  z <- seq(-2, 2, length.out = 120L)
  q <- etr_discretize_states(z, bins = 3L, method = "quantile")
  w <- etr_discretize_states(z, bins = 4L, method = "equal_width")
  expect_equal(length(q), 120L)
  expect_equal(length(unique(q)), 3L)
  expect_equal(length(unique(w)), 4L)
  expect_equal(attr(q,"method"), "quantile")
  expect_error(etr_discretize_states(rep(1, 40L), bins = 3L), "tied")
})

test_that("effective TE and Markov null are descriptive, reproducible", {
  set.seed(2026)
  driver <- sample(0:1, 400L, replace = TRUE)
  outcome <- c(0L, head(driver, -1L))
  before <- .Random.seed
  eff <- etr_effective_transfer_entropy(driver, outcome,
                                        n_shuffles = 39L, seed = 77L)
  expect_identical(before, .Random.seed)
  expect_gt(eff$transfer_entropy_bits, eff$mean_shuffled_bits + .3)
  expect_equal(eff$effective_bits, eff$transfer_entropy_bits -
                 eff$mean_shuffled_bits)
  null_a <- etr_simulate_te_null(n = 100L, persistence = .7, seed = 13L)
  null_b <- etr_simulate_te_null(n = 100L, persistence = .7, seed = 13L)
  expect_equal(null_a, null_b)
  expect_equal(null_a$truth_directed_effect, 0)
  aud <- etr_evaluate_te_null(simulations = 5L, n = 80L,
                              persistence = .65, n_surrogates = 19L, seed = 21L)
  expect_equal(nrow(aud$results), 5L)
  expect_true(all(is.finite(aud$results$plug_in_bits)))
  expect_true(aud$diagnostic_flag_rate >= 0 && aud$diagnostic_flag_rate <= 1)
  expect_equal(aud$interpretation, "diagnostic_not_calibrated_type_i_error_test")
})

test_that("group contrasts preserve participant randomization and truth", {
  sim <- etr_simulate_group_contrast(n_subjects = 12L, n_time = 21L, seed = 14L)
  expect_equal(dim(sim$true_contrast), c(21L, 2L))
  expect_equal(length(unique(sim$participant)), 12L)
  for (p in unique(sim$participant))
    expect_equal(length(unique(sim$treatment[sim$participant == p])), 1L)
  fit <- etr_bootstrap_group_contrast(sim$trajectories,
                                      sim$participant, sim$treatment,
                                      B = 49L, alpha = .10, seed = 18L)
  expect_equal(fit$group_levels, c("control","treatment"))
  expect_equal(fit$contrast, "treatment minus control")
  expect_equal(dim(fit$difference), dim(sim$true_contrast))
  expect_true(all(is.finite(fit$simultaneous_lower)))
  expect_true(all(fit$simultaneous_lower <= fit$simultaneous_upper))
  expect_equal(sum(fit$participants_per_group), 12L)
  audit <- etr_evaluate_group_contrast_coverage(simulations = 5L,
                          n_subjects = 12L, B = 49L, seed = 20L)
  expect_equal(nrow(audit$results), 5L)
  expect_true(is.finite(audit$simultaneous_coverage))
  expect_equal(audit$qualification, "empirical_diagnostic_only")
})

test_that("multilevel reconstruction and diagnostics preserve curve order", {
  sim <- etr_simulate_hierarchical(n_subjects = 8L, n_time = 21L, seed = 19L)
  fit <- etr_fit_multilevel_fpca(sim$trajectories, sim$participant, 2L, 2L)
  rec <- etr_multilevel_reconstruct(fit)
  expect_equal(dim(rec$values), dim(sim$trajectories$values))
  expect_equal(rec$curve_ids, sim$trajectories$curve_ids)
  diag <- etr_multilevel_diagnostics(fit)
  expect_equal(diag$n_participants, 8L)
  expect_equal(diag$minimum_trials, 3L)
  expect_true(is.finite(diag$fitted_reconstruction_rmse))
  expect_gte(diag$fitted_reconstruction_rmse, 0)
})

test_that("scalar-on-FPCA CV refits basis within participant folds", {
  sim <- etr_simulate_hierarchical(n_subjects = 12L, n_time = 21L,
                                    seed = 25L)
  y <- rowMeans(etr_dimension(sim$trajectories, "x")) +
       seq_len(length(sim$participant)) * .001
  cv <- etr_grouped_fpca_crossval(sim$trajectories, y, sim$participant,
                                  folds = 3L, n_components = 2L, seed = 6L)
  expect_equal(nrow(cv), 36L)
  expect_true(all(is.finite(cv$predicted)))
  expect_true(all(cv$squared_error >= 0))
  for (p in unique(cv$participant))
    expect_equal(length(unique(cv$fold[cv$participant == p])), 1L)
  wf <- etr_run_scalar_fpca_workflow(sim$trajectories, y, n_components = 2L)
  expect_equal(wf$workflow, "scalar_on_function_score_regression")
  expect_true(is.finite(wf$diagnostics$training_rmse))
})

test_that("advanced workflow and diagnostic plotting are type checked", {
  sim <- etr_simulate_hierarchical(n_subjects = 8L, n_time = 21L, seed = 88L)
  wf <- etr_run_mean_band_workflow(sim$trajectories,
                                  sim$participant, B = 49L, alpha = .1)
  expect_true(isTRUE(etr_validate_advanced_workflow(wf)))
  expect_equal(nrow(etr_workflow_summary(wf)), 1L)
  expect_true("scientific_status" %in% names(etr_workflow_summary(wf)))
  expect_error(etr_validate_advanced_workflow(list()), "etr_advanced_workflow")
  pdf <- tempfile(fileext = ".pdf")
  grDevices::pdf(pdf)
  on.exit({grDevices::dev.off(); unlink(pdf)}, add = TRUE)
  expect_silent(etr_plot_functional_band(wf$fit, dimension = 1L))
  set.seed(42)
  x <- sample(0:1, 80L, replace = TRUE)
  te <- etr_transfer_entropy_shift_test(x, c(0L, head(x, -1L)),
                                         n_surrogates = 19L, seed = 8L)
  expect_silent(etr_plot_transfer_surrogates(te))
  obs <- etr_sparse_curves(list(c(0,.2,1),c(.1,.5,.9),c(0,.3,.8)),
                           list(1:3,2:4,3:5))
  expect_silent(etr_plot_sparse_support(etr_sparse_design_diagnostics(obs)))
})
