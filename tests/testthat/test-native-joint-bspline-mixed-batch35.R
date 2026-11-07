# Frozen Python reference: eyetrajectoriespy 1.2.0, functional_mixed_effects.py
# Basic joint model only: unstructured participant random intercept, iid noise.

test_that("joint B-spline model reconstructs an independent dense Gaussian GLS solution", {
  skip_if_not_installed("nlme")
  tt <- seq(0, 1, length.out = 7L)
  ids <- sprintf("c%02d", seq_len(24L))
  group <- rep(sprintf("P%02d", 1:8), each = 3L)
  xx <- rep(c(-1, 0, 1), times = 8L)
  a <- array(0, c(24L, 7L, 1L))
  for (i in seq_len(8L)) for (j in seq_len(3L)) {
    ci <- (i - 1L) * 3L + j
    a[ci, , 1L] <- 0.7 + .2 * tt + xx[ci] * (.5 - .15 * tt) +
      .6 * sin(1.1 * i) + .3 * cos(2 * i) * tt +
      .07 * sin(.7 * (i * 3 + j) * (tt + .3)) +
      .035 * cos((i + j) * tt)
  }
  traj <- etr_trajectory_set(tt, a, curve_ids = ids,
    dimension_names = "gaze_x", metadata = data.frame(participant = group),
    coordinate_system = "degrees", time_unit = "s")
  design <- data.frame(curve_id = rev(ids), x = rev(xx))
  fit <- etr_fit_joint_bspline_functional_mixed_effects(
    trajectories = traj, design = design, predictors = "x",
    participant_column = "participant", dimension = "gaze_x",
    fixed_basis_size = 2L, random_basis_size = 2L,
    spline_degree = 1L, reml = TRUE)
  expect_s3_class(fit, "etr_joint_bspline_mixed")
  expect_identical(fit$backend, "nlme::lme")
  expect_false(fit$source_python_full_parity)
  expect_equal(dim(fit$fixed_coefficient_functions), c(2L, 7L))
  expect_equal(dim(fit$random_effect_functions), c(8L, 7L))
  expect_equal(dim(fit$random_effect_covariance), c(2L, 2L))
  expect_equal(dim(fit$fitted_functions), c(24L, 7L))
  expect_equal(unname(fit$fitted_functions + fit$residual_functions),
    unname(fit$observed_functions), tolerance = 1e-9)
  expect_true(all(is.finite(fit$fixed_standard_errors)))
  expect_true(all(fit$fixed_standard_errors >= 0))
  expect_true(all(is.finite(fit$random_effect_covariance)))
  expect_true(fit$residual_variance > 0)
  # Statsmodels source-contract anchor on exactly this deterministic
  # fixture and linear clamped spline basis; optimizer conventions and
  # covariance estimates can differ, so this is a bounded developer probe.
  expect_lt(max(abs(as.numeric(t(fit$fixed_basis_coefficients)) -
    c(.85281979, .97443119, .49323236, .35045984))), .16)
  expect_equal(as.numeric(fit$fixed_basis[1L, ]), c(1, 0), tolerance = 1e-10)
  expect_equal(as.numeric(fit$fixed_basis[7L, ]), c(0, 1), tolerance = 1e-10)
  # Independently build V = Z (I_G kron G) Z' + sigma2 I and compare
  # generalized least-squares fixed coefficients with fitted output.
  nobs <- length(fit$observed_functions)
  ng <- length(fit$participant_ids)
  k <- ncol(fit$random_basis)
  Z <- matrix(0, nobs, ng * k)
  gids <- rep(fit$curve_participant_ids, each = fit$n_time)
  for (g in seq_len(ng)) {
    rows <- which(gids == fit$participant_ids[g])
    Z[rows, (g - 1L) * k + seq_len(k)] <-
      fit$random_long_design[rows, , drop = FALSE]
  }
  V <- Z %*% kronecker(diag(ng), fit$random_effect_covariance) %*% t(Z) +
    diag(fit$residual_variance, nobs)
  X <- fit$fixed_long_design
  y <- as.vector(t(fit$observed_functions))
  gls_information <- crossprod(X, solve(V, X))
  gls_coefficient <- solve(gls_information,
    crossprod(X, solve(V, y)))
  expect_lt(max(abs(as.numeric(gls_coefficient) -
    as.numeric(t(fit$fixed_basis_coefficients)))), 2e-4)
  expect_lt(max(abs(solve(gls_information) -
    fit$fixed_parameter_covariance)), 2e-4)
  report <- etr_joint_bspline_mixed_coefficient_frame(fit)
  expect_equal(nrow(report), 14L)
  expect_identical(names(report),
    c("coefficient", "time", "estimate", "se", "lower", "upper"))
  expect_true(all(report$lower <= report$estimate))
  expect_true(all(report$estimate <= report$upper))
  expect_error(etr_joint_bspline_mixed_coefficient_frame(fit,
    confidence_level = 1), "confidence_level")
})

test_that("joint estimator rejects unsupported domains without substituting a model", {
  skip_if_not_installed("nlme")
  tt <- c(0, .25, .5, .75, 1)
  v <- array(0, c(6L, 5L, 1L))
  tr <- etr_trajectory_set(tt, v,
    metadata = data.frame(pid = paste0("P", seq_len(6L))),
    dimension_names = "x")
  d <- data.frame(curve_id = tr$curve_ids, pressure = rep(1, 6))
  expect_error(etr_fit_joint_bspline_functional_mixed_effects(
    tr, d, "pressure", "pid", "x", 2L, 2L, 1L),
    "rank deficient")
  expect_error(etr_fit_joint_bspline_functional_mixed_effects(
    tr, d, character(), "unknown_column", "x", 2L, 2L, 1L),
    "participant_column")
  expect_error(etr_fit_joint_bspline_functional_mixed_effects(
    tr, d, character(), "pid", "x", 2L, 2L, 1L,
    reml = NA), "reml")
})
