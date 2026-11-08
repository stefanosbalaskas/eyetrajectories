# Batch 44: source-grounded IID residual-correlation identity output.
# The statistical fitting algorithms and nlme likelihood are unchanged.

test_that("Batch 44 non-nested mixed effects expose the Python IID matrix", {
  skip_if_not_installed("nlme")
  tt <- seq(0, 1, length.out = 8L)
  ng <- 20L
  nc <- 3L * ng
  ids <- sprintf("b44c%03d", seq_len(nc))
  pid <- rep(sprintf("b44P%02d", seq_len(ng)), each = 3L)
  z <- rep(c(-1, 0, 1), ng)
  yy <- array(NA_real_, c(nc, length(tt), 1L))
  for (g in seq_len(ng)) for (k in seq_len(3L)) {
    i <- 3L * (g-1L) + k
    yy[i, , 1L] <- .6 + .15*tt + z[i]*(.3-.08*tt) +
      (.22*sin(.47*g))*(1-tt) + (.17*cos(.61*g))*tt +
      z[i]*(.11*cos(.39*g)*(1-tt)+.14*sin(.29*g)*tt) +
      .03*sin(.9*i + 2.1*tt) + .02*cos(.4*i*tt + .2*g)
  }
  tr <- etr_trajectory_set(tt, yy, curve_ids=ids,
    dimension_names="signal", metadata=data.frame(pid=pid),
    coordinate_system="degrees", time_unit="s")
  design <- data.frame(curve_id=rev(ids), x=rev(z))
  shared <- list(trajectories=tr, design=design, predictors="x",
    participant_column="pid", dimension="signal",
    fixed_basis_size=2L, random_basis_size=2L,
    spline_degree=1L, reml=TRUE, maxiter=500L)
  basic <- do.call(etr_fit_joint_bspline_functional_mixed_effects, shared)
  slope <- do.call(etr_fit_joint_bspline_functional_random_slope,
    c(shared, list(random_slope_predictor="x")))
  for (fit in list(basic, slope)) {
    actual <- fit$residual_correlation_matrix
    expect_true(is.matrix(actual))
    expect_identical(dim(actual), c(length(tt), length(tt)))
    expect_identical(unname(actual), diag(1, length(tt)))
    expect_equal(crossprod(actual), diag(1, length(tt)), tolerance=0)
    expect_equal(fit$residual_variance * actual,
      diag(fit$residual_variance, length(tt)), tolerance=0)
    expect_gt(fit$residual_variance, 0)
    expect_true(is.finite(as.numeric(stats::logLik(fit$fitted_model))))
    expect_equal(unname(fit$fitted_functions + fit$residual_functions),
      unname(fit$observed_functions), tolerance=1e-9)
    expect_false(fit$source_python_full_parity)
  }
})
