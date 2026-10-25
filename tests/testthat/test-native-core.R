.native_fixture <- function() {
  t <- c(0, 1, 2, 4)
  v <- array(0, c(3L, 4L, 2L))
  for (i in 1:3) {
    v[i, , 1] <- i - 1L
    v[i, , 2] <- 2 * (i - 1L)
  }
  etr_trajectory_set(t, v, c("c1", "c2", "c3"), c("x", "y"),
                     coordinate_system = "pixels", time_unit = "s")
}
.native_reference <- function(key) {
  f <- utils::read.csv(testthat::test_path("fixtures", "python_1_2_0_math_reference.csv"))
  stopifnot(key %in% f$key)
  f$value[match(key, f$key)]
}

test_that("native structures and long conversion preserve grid and channels", {
  x <- .native_fixture()
  expect_true(isTRUE(etr_validate(x, require_complete = TRUE)))
  expect_equal(etr_summary(x)$n_curves, 3L)
  expect_equal(etr_summary(x)$n_time, 4L)
  expect_equal(etr_summary(x)$missing_samples, 0)
  expect_equal(dim(etr_dimension(x, "y")), c(3L, 4L))
  expect_equal(etr_subset(x, "c2")$curve_ids, "c2")
  long <- etr_as_long(x)
  back <- etr_from_long(long, "curve_id", "time", c("x", "y"))
  expect_equal(back$time, x$time)
  expect_equal(back$values, x$values)
  expect_equal(back$curve_ids, x$curve_ids)
  expect_null(names(back$curve_ids))
  expect_error(etr_from_long(rbind(long, long[1, ]), "curve_id"), "unique")
  expect_error(etr_trajectory_set(c(0, 0), array(0, c(2, 2, 1))), "strictly increasing")
  expect_error(etr_trajectory_set(c(0, 1), array(0, c(2, 2, 1)),
                                  curve_ids = c("x", "x")), "unique")
})

test_that("explicit preprocessing does not silently repair missing gaze", {
  x <- .native_fixture()
  x$values[1, 2, 1] <- NA_real_
  expect_error(etr_fit_fpca(x), "complete observations")
  expect_equal(etr_interpolate_gaps(x, 2.1)$values[1, 2, 1], 0)
  expect_true(is.na(etr_interpolate_gaps(x, 0.5)$values[1, 2, 1]))
  expect_true(is.na(etr_resample(x, seq(0, 4, by = 0.5), max_gap = 0.5)$values[1, 3, 1]))
  expect_equal(etr_normalize_time(.native_fixture())$time, c(0, .25, .5, 1))
  expect_equal(etr_center(.native_fixture())$values[3, 1, ], c(0, 0))
  expect_equal(etr_smooth(.native_fixture(), window = 3)$values[2, , 1], rep(1, 4))
  expect_error(etr_smooth(x), "complete observations")
})

test_that("quadrature FPCA matches frozen mathematical Python 1.2.0 fixture", {
  x <- .native_fixture()
  expect_equal(etr_trapezoid_weights(x$time),
    unname(vapply(paste0("trapezoid_w", 1:4), .native_reference, numeric(1))), tolerance = 1e-13)
  expect_equal(sum(etr_trapezoid_weights(x$time, normalize = TRUE)), 1)
  fit <- etr_fit_mfpca(x, n_components = 1L)
  expect_s3_class(fit, "etr_fpca")
  expect_equal(fit$n_components, 1L)
  expect_equal(fit$explained_variance, .native_reference("fpca_eigenvalue1"), tolerance = 1e-10)
  expect_equal(fit$explained_variance_ratio,
               .native_reference("fpca_variance_ratio1"), tolerance = 1e-10)
  expect_equal(as.vector(etr_transform_fpca(fit, x) %*% t(etr_transform_fpca(fit, x))),
               as.vector(fit$scores %*% t(fit$scores)), tolerance = 1e-10)
  expect_equal(etr_reconstruct_fpca(fit)$values, x$values, tolerance = 1e-10)
  expect_equal(nrow(etr_fpca_scores(fit)), 3L)
  expect_equal(etr_fpca_variance_frame(fit)$variance_ratio, 1, tolerance = 1e-10)
  scaled <- etr_fit_mfpca(x, n_components = 1L, scaling = "dimension_sd")
  expect_equal(scaled$explained_variance, 3, tolerance = 1e-10)
  expect_error(etr_fit_mfpca(etr_subset(x, 1:2), n_components = 1.0),
               "variance fraction")
})

test_that("native geometric distances match frozen Python 1.2.0 contracts", {
  x <- .native_fixture()
  a <- matrix(x$values[1, , ], ncol = 2)
  b <- matrix(x$values[2, , ], ncol = 2)
  expect_equal(etr_l2_distance(a, b, x$time),
               .native_reference("l2_curve1_curve2"), tolerance = 1e-12)
  expect_equal(etr_frechet(a, b),
               .native_reference("frechet_curve1_curve2"), tolerance = 1e-12)
  expect_equal(etr_dtw(a, b),
               .native_reference("dtw_curve1_curve2"), tolerance = 1e-12)
  expect_equal(etr_pairwise_l2(x)[1, 2], .native_reference("l2_curve1_curve2"))
  expect_equal(etr_pairwise_dtw(x)[1, 2], .native_reference("dtw_curve1_curve2"))
  expect_error(etr_frechet(a, b[, 1, drop = FALSE]), "channel count")
})

test_that("derivative and path metrics respect nonuniform time", {
  t <- c(0, 1, 2, 4)
  v <- array(0, c(1L, 4L, 2L))
  v[1, , 1] <- t
  v[1, , 2] <- 2*t
  x <- etr_trajectory_set(t, v, "linear", c("x", "y"))
  speed <- etr_dimension(etr_speed(x), "speed")
  expect_equal(as.vector(speed), rep(.native_reference("speed"), 4),
               tolerance = 1e-11)
  expect_equal(as.vector(etr_dimension(etr_velocity(x), "x_velocity")),
               rep(.native_reference("velocity_x"), 4), tolerance = 1e-11)
  expect_equal(as.vector(etr_acceleration(x)$values), rep(0, 8), tolerance = 1e-10)
  expect_equal(etr_path_length(x), .native_reference("path_length"), tolerance = 1e-11)
  expect_equal(etr_tortuosity(x), .native_reference("tortuosity"), tolerance = 1e-11)
  expect_equal(tail(as.vector(etr_cumulative_path_length(x)$values), 1),
               .native_reference("path_length"), tolerance = 1e-11)
  expect_equal(as.vector(etr_heading(x)$values), rep(atan2(2, 1), 4), tolerance = 1e-11)
})

test_that("recurrence rates and basic RQA match frozen Python 1.2.0 targets", {
  x <- .native_fixture()
  x$time <- 0:3
  r <- etr_recurrence_matrix(x, curve = "c1", radius = 0)
  expect_false(any(diag(r$matrix)))
  expect_equal(sum(r$matrix), 12)
  q <- etr_rqa_metrics(r)
  expect_equal(q$recurrence_rate, .native_reference("rqa_recurrence_rate"))
  expect_equal(q$determinism, .native_reference("rqa_determinism"))
  expect_equal(q$laminarity, .native_reference("rqa_laminarity"))
  r2 <- etr_recurrence_matrix(x, 1L, radius = 0, theiler = 1L)
  expect_equal(sum(r2$matrix), 6)
  expect_equal(etr_rqa_metrics(r2)$recurrence_rate, 1)
  a <- matrix(x$values[1, , ], ncol = 2)
  b <- matrix(x$values[2, , ], ncol = 2)
  cross <- etr_cross_recurrence_matrix(a, b, radius = 0)
  expect_equal(sum(cross$matrix), 0)
  expect_true(is.na(etr_rqa_metrics(cross)$determinism))
  expect_error(etr_recurrence_matrix(x, radius = 0, theiler = 3L), "eligible pairs")
  long <- etr_trajectory_set(0:2500, array(0, c(1L, 2501L, 2L)),
                              "long", c("x", "y"))
  expect_error(etr_recurrence_matrix(long, radius = 0), "2500 samples")
})

test_that("native plotting writes real base graphics without Python", {
  x <- .native_fixture()
  filename <- tempfile(fileext = ".pdf")
  grDevices::pdf(filename)
  on.exit({grDevices::dev.off(); unlink(filename)}, add = TRUE)
  expect_silent(etr_plot_trajectories(x))
  expect_silent(etr_plot_fpca_variance(etr_fit_mfpca(x, 1L)))
  x$time <- 0:3
  expect_silent(etr_plot_recurrence(etr_recurrence_matrix(x, radius = 0)))
})
