# Native finite pairwise L2 optimization: mathematical contracts and edges.
# No network, Python, external datasets, or timing-based pass/fail criteria.

.pairwise_l2_scalar_oracle <- function(x, dimension_weights = NULL,
                                       python_boundary_mode = FALSE) {
  n <- dim(x$values)[1L]
  out <- matrix(0, n, n, dimnames = list(x$curve_ids, x$curve_ids))
  for (i in seq_len(n)) for (j in seq_len(n)) if (i < j) {
    a <- matrix(x$values[i, , , drop = FALSE],
                nrow = length(x$time), ncol = dim(x$values)[3L])
    b <- matrix(x$values[j, , , drop = FALSE],
                nrow = length(x$time), ncol = dim(x$values)[3L])
    out[i, j] <- etr_l2_distance(a, b, x$time,
                                 dimension_weights = dimension_weights,
                                 python_boundary_mode = python_boundary_mode)
    out[j, i] <- out[i, j]
  }
  out
}

test_that("compiled finite pairwise L2 agrees with scalar integration across shapes", {
  set.seed(20261117L)
  for (nc in c(2L, 3L, 7L))
    for (nd in c(1L, 2L, 3L))
      for (irregular in c(FALSE, TRUE)) {
        tm <- if (irregular) c(0, .003, .1, .9, 1.4, 5.3) else seq(0, 1, length.out = 6L)
        vals <- array(stats::rnorm(nc * length(tm) * nd),
                      c(nc, length(tm), nd))
        ids <- paste0("trial-", seq_len(nc))
        x <- etr_trajectory_set(tm, vals, ids, paste0("channel-", seq_len(nd)),
                                coordinate_system = "pixels")
        cases <- list(NULL, rep(1, nd), seq_len(nd) / nd,
                      replace(rep(1, nd), 1L, 0))
        for (dw in cases) {
          actual <- etr_pairwise_l2(x, dimension_weights = dw)
          expected <- .pairwise_l2_scalar_oracle(x, dw)
          expect_identical(dim(actual), c(nc, nc))
          expect_identical(dimnames(actual), list(ids, ids))
          expect_equal(unname(actual), unname(expected), tolerance = 1e-11)
          expect_equal(actual, t(actual), tolerance = 0)
          expect_identical(unname(diag(actual)), rep(0, nc))
        }
      }
})

test_that("zero channel weights, all-zero distances and near-coincident gaze work", {
  tm <- c(0, .05, .12, .7, 1.8)
  vals <- array(0, c(4L, length(tm), 2L))
  vals[1L, , 1L] <- c(0, 1, 1, 2, 3)
  vals[2L, , 1L] <- c(0, 1, 1, 2, 3)
  vals[3L, , 1L] <- c(1, 2, 3, 4, 5)
  vals[4L, , 1L] <- -c(1, 2, 3, 4, 5)
  vals[, , 2L] <- 20
  x <- etr_trajectory_set(tm, vals, paste0("id", 1:4), c("x", "y"),
                          coordinate_system = "pixels")
  expect_equal(etr_pairwise_l2(x, c(0, 0)), matrix(0, 4L, 4L,
    dimnames = list(x$curve_ids, x$curve_ids)), tolerance = 0)
  expect_equal(etr_pairwise_l2(x, c(1, 0)),
               .pairwise_l2_scalar_oracle(x, c(1, 0)), tolerance = 1e-12)
  expect_identical(etr_pairwise_l2(x)[1L, 2L], 0)

  # Large common pixel offset: distance differences must be computed
  # without subtracting large squared norms (catastrophic cancellation).
  near <- array(1e12, c(3L, length(tm), 2L))
  near[2L, , 1L] <- near[2L, , 1L] + c(0, 0, .001, .002, .004)
  near[3L, , 2L] <- near[3L, , 2L] + c(.001, .002, .003, .004, .005)
  y <- etr_trajectory_set(tm, near, paste0("near", 1:3), c("x", "y"))
  expect_equal(etr_pairwise_l2(y), .pairwise_l2_scalar_oracle(y),
               tolerance = 1e-11)
  expect_gt(etr_pairwise_l2(y)[1L, 2L], 0)
})

test_that("invalid strict weights and missing observations remain rejected", {
  x <- etr_trajectory_set(0:3, array(seq_len(24L) / 24,
                         c(3L, 4L, 2L)), paste0("c", 1:3), c("x", "y"))
  expect_error(etr_pairwise_l2(x, c(-1, 1)), "non-negative")
  expect_error(etr_pairwise_l2(x, c(1, Inf)), "finite")
  expect_error(etr_pairwise_l2(x, c(1, 2, 3)), "match dimensions")
  expect_error(etr_pairwise_l2(x, python_boundary_mode = NA), "logical scalar")
  x$values[1L, 2L, 1L] <- NA_real_
  expect_error(etr_pairwise_l2(x), "complete")
})

test_that("0/1-curve legacy behavior and nonfinite source mode are unchanged", {
  tm <- c(0, .1, 2)
  one <- etr_trajectory_set(tm, array(1, c(1L, 3L, 2L)),
                            curve_ids = "one", dimension_names = c("x", "y"))
  # Existing scalar implementation never checks dimension weights when
  # there are no off-diagonal pairs. This is intentionally preserved.
  expect_equal(etr_pairwise_l2(one, c(-1, Inf)),
               matrix(0, 1L, 1L, dimnames = list("one", "one")), tolerance = 0)

  empty <- etr_trajectory_set(tm, array(numeric(), c(0L, 3L, 2L)),
    curve_ids = character(), dimension_names = c("x", "y"),
    python_boundary_mode = TRUE)
  expect_identical(dim(etr_pairwise_l2(empty, python_boundary_mode = TRUE)),
                   c(0L, 0L))

  vals <- array(c(0, 1, 2, 3, Inf, 5), c(2L, 3L, 1L))
  nonfinite <- etr_trajectory_set(c(0, 1, 2), vals, c("a", "b"), "x",
    coordinate_system = "pixels", python_boundary_mode = TRUE)
  actual <- etr_pairwise_l2(nonfinite, python_boundary_mode = TRUE)
  expected <- .pairwise_l2_scalar_oracle(nonfinite, python_boundary_mode = TRUE)
  expect_identical(is.infinite(actual), is.infinite(expected))
  expect_identical(unname(diag(actual)), c(0, 0))
})

test_that("unsafe scaled finite coordinates follow the scalar fallback", {
  tm <- c(0, 1, 2)
  vals <- array(1e308, c(2L, 3L, 2L))
  vals[2L, 1L, 1L] <- -1e308
  x <- etr_trajectory_set(tm, vals, c("a", "b"), c("x", "y"))
  actual <- suppressWarnings(etr_pairwise_l2(x))
  expected <- suppressWarnings(.pairwise_l2_scalar_oracle(x))
  expect_identical(is.infinite(actual), is.infinite(expected))
  expect_identical(unname(diag(actual)), c(0, 0))
})
