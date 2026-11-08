# Frozen Python 1.2 source structure: functional_mixed_effects.py
# Scientific contract: one participant random slope and intercept, iid noise.

test_that("joint random-slope mixed model agrees with independent dense GLS algebra", {
  skip_if_not_installed("nlme")
  tt <- seq(0, 1, length.out = 7L)
  g <- 18L
  nc <- g * 3L
  ids <- sprintf("c%03d", seq_len(nc))
  pid <- rep(sprintf("P%02d", seq_len(g)), each = 3L)
  z <- rep(c(-1, 0, 1), times = g)
  a <- array(0, c(nc, length(tt), 1L))
  for (i in seq_len(g)) for (j in seq_len(3L)) {
    idx <- (i - 1L) * 3L + j
    ri0 <- .25*sin(.71*i)+.14*cos(1.37*i)
    ri1 <- .22*cos(.37*i)-.15*sin(1.40*i)
    rs0 <- .20*cos(.79*i)+.13*sin(.33*i)
    rs1 <- .16*sin(1.13*i)+.12*cos(.21*i)
    a[idx, , 1L] <- .7 + .15*tt + z[idx]*(.4 - .1*tt) +
      (1-tt)*ri0 + tt*ri1 +
      z[idx]*((1-tt)*rs0 + tt*rs1) +
      .03*sin(2.3*i*j + 1.7*tt*(i+j)) +
      .02*cos(.7*i + 2.1*j*tt)
  }
  tr <- etr_trajectory_set(tt, a, curve_ids = ids,
    dimension_names = "gaze_x", metadata = data.frame(pid=pid),
    coordinate_system = "degrees", time_unit = "s")
  d <- data.frame(curve_id = rev(ids), treatment = rev(z))
  fit <- etr_fit_joint_bspline_functional_random_slope(
    tr, d, predictors="treatment", participant_column="pid",
    dimension="gaze_x", random_slope_predictor="treatment",
    fixed_basis_size=2L, random_basis_size=2L,
    spline_degree=1L, reml=TRUE, maxiter=500L)
  expect_s3_class(fit, "etr_joint_bspline_mixed_slope")
  expect_s3_class(fit, "etr_joint_bspline_mixed")
  expect_identical(fit$backend, "nlme::lme")
  expect_false(fit$source_python_full_parity)
  expect_equal(dim(fit$fixed_coefficient_functions), c(2L, 7L))
  expect_equal(dim(fit$random_effect_covariance), c(4L, 4L))
  expect_equal(dim(fit$intercept_slope_covariance), c(2L, 2L))
  expect_equal(dim(fit$random_effect_functions), c(g, 7L))
  expect_equal(dim(fit$random_slope_effect_functions), c(g, 7L))
  expect_equal(dim(fit$fitted_functions), c(nc, 7L))
  expect_equal(unname(fit$fitted_functions + fit$residual_functions),
    unname(fit$observed_functions), tolerance=1e-9)
  expect_true(all(is.finite(fit$fixed_standard_errors)))
  expect_true(all(fit$fixed_standard_errors >= 0))
  expect_true(all(is.finite(fit$random_effect_covariance)))
  expect_true(all(is.finite(fit$intercept_slope_covariance)))
  expect_true(fit$residual_variance > 0)
  expect_equal(unname(fit$random_effect_covariance),
    unname(t(fit$random_effect_covariance)), tolerance=1e-8)
  expect_gt(min(eigen(fit$random_effect_covariance, symmetric=TRUE,
    only.values=TRUE)$values), -1e-7)

  # Independently assemble the implied marginal model V=Z G Z' + sigma^2 I.
  # The fitted coefficients must be the GLS solution under these quantities.
  nobs <- length(fit$observed_functions)
  nre <- ncol(fit$random_long_design)
  ng <- length(fit$participant_ids)
  Z <- matrix(0, nobs, ng*nre)
  gid <- rep(fit$curve_participant_ids, each=fit$n_time)
  for (k in seq_len(ng)) {
    rows <- which(gid == fit$participant_ids[k])
    Z[rows, (k-1L)*nre + seq_len(nre)] <-
      fit$random_long_design[rows, , drop=FALSE]
  }
  V <- Z %*% kronecker(diag(ng), fit$random_effect_covariance) %*% t(Z) +
    diag(fit$residual_variance, nobs)
  X <- fit$fixed_long_design
  y <- as.vector(t(fit$observed_functions))
  information <- crossprod(X, solve(V, X))
  bhat <- solve(information, crossprod(X, solve(V, y)))
  expect_lt(max(abs(as.numeric(bhat) -
    as.numeric(t(fit$fixed_basis_coefficients)))), 2e-3)
  expect_lt(max(abs(solve(information) -
    fit$fixed_parameter_covariance)), 2e-3)
  report <- etr_joint_bspline_mixed_coefficient_frame(fit)
  expect_equal(nrow(report), 14L)
  expect_identical(names(report),
    c("coefficient", "time", "estimate", "se", "lower", "upper"))
  expect_true(all(report$lower <= report$estimate))
  expect_true(all(report$estimate <= report$upper))
})

test_that("joint random slope rejects nonidentifiable or unsupported domains", {
  tt <- seq(0, 1, length.out=5L)
  ids <- paste0("c", seq_len(36))
  pid <- rep(sprintf("P%02d", seq_len(12L)), each=3L)
  tr <- etr_trajectory_set(tt, array(0, c(36L, 5L, 1L)),
    curve_ids=ids, dimension_names="x", metadata=data.frame(pid=pid))
  d <- data.frame(curve_id=ids, x=rep(c(-1, 0, 1), 12L))
  expect_error(etr_fit_joint_bspline_functional_random_slope(
    tr, d, "x", "pid", "x", "not_in_predictors",
    2L, 2L, 1L), "random_slope_predictor")
  d$x <- rep(seq_len(12), each=3L)
  expect_error(etr_fit_joint_bspline_functional_random_slope(
    tr, d, "x", "pid", "x", "x",
    2L, 2L, 1L), "must vary within every participant")
  expect_error(etr_fit_joint_bspline_functional_random_slope(
    tr, d, "x", "pid", "x", "x",
    2L, 2L, 1L, reml=NA), "reml")
})
