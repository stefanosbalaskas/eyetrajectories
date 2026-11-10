test_that("native sparse recovery keeps full covariance and finite score pairs", {
  z <- .etr_recovery_modes_fixture("sparse_fpca", "partial_scores")
  assessment <- etr_evaluate_sparse_fpca_recovery(z$fit, z$truth)
  frame <- etr_functional_recovery_assessment_frame(assessment)
  expect_identical(assessment$provenance$matched_truth_components, c(2L, 0L))
  expect_equal(frame$value[frame$metric == "score_failure_rate"], 1 / 3)
  expect_length(frame$value[frame$metric == "score_correlation"], 2L)
  expect_gt(frame$value[frame$metric == "covariance_ise"], 0)
  expect_true("reconstruction_ise" %in% frame$metric)
  z$fit$scores[,] <- NA_real_
  frame <- etr_functional_recovery_assessment_frame(
    etr_evaluate_sparse_fpca_recovery(z$fit, z$truth))
  expect_equal(frame$value[frame$metric == "score_failure_rate"], 1)
  expect_false(any(frame$metric %in% c("score_rmse", "score_correlation", "reconstruction_ise")))
})

test_that("tied sparse MFPCA compares subspaces and rejects split truth groups", {
  z <- .etr_recovery_modes_fixture("sparse_mfpca", "tied")
  assessment <- etr_evaluate_sparse_mfpca_recovery(z$fit, z$truth)
  frame <- etr_functional_recovery_assessment_frame(assessment)
  expect_identical(assessment$provenance$tied_truth_component_groups, list(1:2))
  expect_identical(assessment$provenance$tied_score_subspace_sources,
    list("truth_components_1_2"))
  expect_false(any(frame$metric %in% c("component_absolute_similarity", "score_correlation")))
  expect_equal(frame$value[frame$metric == "score_subspace_procrustes_rmse"], 0,
    tolerance = 1e-12)
  expect_equal(frame$value[frame$metric == "covariance_block_ise" &
    frame$source == "cxy"], .025^2 * prod(z$fit$quadrature_weights[2:3]))
  expect_equal(sum(frame$value[frame$metric == "covariance_block_ise"]),
    frame$value[frame$metric == "covariance_ise"])
  bad <- .etr_recovery_modes_fixture("sparse_mfpca", "split_tie")
  expect_error(etr_evaluate_sparse_mfpca_recovery(bad$fit, bad$truth), "split a tied truth eigenspace")
})

test_that("recovery assessments accept custom metrics and reject duplicate or nonfinite values", {
  assessment <- .etr_recovery_custom_assessment_fixture()
  frame <- etr_functional_recovery_assessment_frame(assessment)
  expect_identical(frame$metric, c("custom_loss", "mean_ise"))
  expect_identical(frame$source, c("participant", NA_character_))
  expect_identical(frame$component, c(2L, NA_integer_))
  expect_match(etr_functional_recovery_reporting_text(assessment),
    "custom_loss, mean_ise", fixed = TRUE)
  bad <- assessment
  bad$values[[3L]] <- bad$values[[1L]]
  expect_error(etr_functional_recovery_assessment_frame(bad), "duplicate metric labels")
  bad <- assessment
  bad$values[[2L]]$value <- NaN
  expect_error(etr_functional_recovery_assessment_frame(bad), "finite numeric scalar")
})

test_that("registration recovery uses the rightmost equal phase knot", {
  z <- .etr_recovery_repeated_warp_fixture()
  assessment <- etr_evaluate_registration_recovery(z$fit, z$truth)
  expect_equal(assessment$values[[2L]]$value, .25)
  z$truth$phase_warps_on_truth_grid[1L, 3L] <- .2
  expect_error(etr_evaluate_registration_recovery(z$fit, z$truth), "nondecreasing")
})

test_that("rectangular recovery assignment preserves the source tie order", {
  witness <- rbind(c(0, 0, 0), c(1, 0, 1))
  expect_identical(.etr_fpca_recovery_multi_assignment(witness), c(1L, 3L))
  expect_identical(.etr_fpca_recovery_multi_assignment(matrix(0, 2L, 4L)), 1:2)
  if (!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"), "true"))
    skip("frozen recovery assignment oracle is opt-in")
  scipy <- reticulate::import("scipy.optimize", convert = TRUE)
  cases <- expand.grid(rep(list(0:2), 6L))
  matches <- vapply(seq_len(nrow(cases)), function(i) {
    similarity <- matrix(as.numeric(cases[i, ]), 2L)
    reference <- as.integer(scipy$linear_sum_assignment(-similarity)[[2L]]) + 1L
    identical(.etr_fpca_recovery_multi_assignment(similarity), reference)
  }, logical(1L))
  expect_true(all(matches), info = paste(sum(!matches), "rectangular assignments differ"))
})

test_that("native sparse fits feed the multicomponent recovery evaluators", {
  grid <- seq(0, 1, length.out = 11L)
  weights <- etr_trapezoid_weights(grid)
  scale <- sqrt(2 * sum((grid - .5)^2 * weights))
  modes <- list(
    function(t) matrix(1 / sqrt(2), length(t), 2L),
    function(t) cbind((t - .5) / scale, (.5 - t) / scale))
  simulation <- etr_simulate_functional_process(
    mean = function(t) matrix(0, length(t), 2L), eigenfunctions = modes,
    eigenvalues = c(2, .6), truth_grid = grid, n_participants = 18L,
    dimension_names = c("x", "y"), observation_design = "irregular",
    observation_times = rep(list(grid), 18L),
    measurement_noise_sd = sqrt(.05), random_state = 42L)
  univariate <- etr_fit_sparse_fpca_native(simulation$observations, "x", 2L,
    grid, .45, .65, measurement_error_variance = .05, psd_action = "project")
  paired <- etr_fit_sparse_mfpca_native(simulation$observations,
    n_components = 2L, evaluation_grid = grid, mean_bandwidth = .45,
    covariance_bandwidth = .65, measurement_error_variance = rep(.05, 2L),
    psd_action = "project")
  for (assessment in list(
    etr_evaluate_sparse_fpca_recovery(univariate, simulation$truth),
    etr_evaluate_sparse_mfpca_recovery(paired, simulation$truth))) {
    frame <- etr_functional_recovery_assessment_frame(assessment)
    expect_equal(sum(frame$metric == "score_rmse"), 2L)
    expect_equal(sum(frame$metric == "reconstruction_ise"), 1L)
    expect_true(all(is.finite(frame$value)))
  }
})
