# Main-branch port of the finite weighted L2 fast path from PR #191.
# The earlier main API has no optional Python-boundary mode: do not add it.
# Compare to the *same branch's* original scalar integration on irregular
# grids, different channels, zero weights and floating-point boundaries.
.scalar_l2_matrix <- function(x, dimension_weights = NULL) {
  n <- dim(x$values)[1L]
  result <- matrix(0, n, n, dimnames = list(x$curve_ids, x$curve_ids))
  for (i in seq_len(n)) for (j in seq_len(n)) if (i < j) {
    a <- matrix(x$values[i, , , drop = FALSE],
                nrow = length(x$time), ncol = dim(x$values)[3L])
    b <- matrix(x$values[j, , , drop = FALSE],
                nrow = length(x$time), ncol = dim(x$values)[3L])
    result[i, j] <- etr_l2_distance(a, b, x$time, dimension_weights)
    result[j, i] <- result[i, j]
  }
  result
}

test_that("main finite L2 fast path agrees with scalar trapezoid integration", {
  set.seed(20261117L)
  for (n in c(2L, 3L, 7L))
    for (nd in c(1L, 2L, 3L))
      for (irregular in c(FALSE, TRUE)) {
        times <- if (irregular) c(0, .003, .1, .9, 1.4, 5.3)
                 else seq(0, 1, length.out = 6L)
        values <- array(stats::rnorm(n * length(times) * nd),
                        c(n, length(times), nd))
        ids <- paste0("trial-", seq_len(n))
        x <- etr_trajectory_set(times, values, ids, paste0("channel-", seq_len(nd)))
        weights <- list(NULL, rep(1, nd), seq_len(nd) / nd,
                        replace(rep(1, nd), 1L, 0))
        for (dw in weights) {
          actual <- etr_pairwise_l2(x, dw)
          expected <- .scalar_l2_matrix(x, dw)
          expect_identical(dim(actual), c(n, n))
          expect_identical(dimnames(actual), list(ids, ids))
          expect_equal(unname(actual), unname(expected), tolerance = 1e-11)
          expect_equal(actual, t(actual), tolerance = 0)
          expect_identical(unname(diag(actual)), rep(0, n))
        }
      }
})

test_that("zero channel weights, identical and near-coincident paths remain safe", {
  tm <- c(0, .05, .12, .7, 1.8)
  values <- array(0, c(4L, length(tm), 2L))
  values[1L, , 1L] <- c(0, 1, 1, 2, 3)
  values[2L, , 1L] <- values[1L, , 1L]
  values[3L, , 1L] <- c(1, 2, 3, 4, 5)
  values[4L, , 1L] <- -c(1, 2, 3, 4, 5)
  values[, , 2L] <- 20
  x <- etr_trajectory_set(tm, values, paste0("id", 1:4), c("x", "y"))
  zeros <- matrix(0, 4L, 4L, dimnames = list(x$curve_ids, x$curve_ids))
  expect_equal(etr_pairwise_l2(x, c(0, 0)), zeros, tolerance = 0)
  expect_identical(etr_pairwise_l2(x)[1L, 2L], 0)
  expect_equal(etr_pairwise_l2(x, c(1, 0)),
               .scalar_l2_matrix(x, c(1, 0)), tolerance = 1e-12)

  near <- array(1e12, c(3L, length(tm), 2L))
  near[2L, , 1L] <- near[2L, , 1L] + c(0, 0, .001, .002, .004)
  near[3L, , 2L] <- near[3L, , 2L] + c(.001, .002, .003, .004, .005)
  y <- etr_trajectory_set(tm, near, paste0("near", 1:3), c("x", "y"))
  expect_equal(etr_pairwise_l2(y), .scalar_l2_matrix(y), tolerance = 1e-11)
  expect_gt(etr_pairwise_l2(y)[1L, 2L], 0)
})

test_that("legacy single-curve and finite-input contracts are preserved", {
  one <- etr_trajectory_set(c(0, 1, 2), array(1, c(1L, 3L, 2L)),
                            "one", c("x", "y"))
  expect_equal(etr_pairwise_l2(one, c(-1, Inf)),
               matrix(0, 1L, 1L, dimnames = list("one", "one")), tolerance = 0)
  x <- etr_trajectory_set(0:3, array(seq_len(24) / 24, c(3L, 4L, 2L)),
                          paste0("c", 1:3), c("x", "y"))
  expect_error(etr_pairwise_l2(x, c(-1, 1)), "non-negative")
  expect_error(etr_pairwise_l2(x, c(1, Inf)), "finite")
  expect_error(etr_pairwise_l2(x, c(1, 2, 3)), "match dimensions")
  x$values[1L, 2L, 1L] <- NA_real_
  expect_error(etr_pairwise_l2(x), "complete")
})

test_that("finite values leading to unsafe transforms use scalar fallback", {
  tm <- c(0, 1, 2)
  values <- array(1e308, c(2L, 3L, 2L))
  values[2L, 1L, 1L] <- -1e308
  x <- etr_trajectory_set(tm, values, c("a", "b"), c("x", "y"))
  actual <- suppressWarnings(etr_pairwise_l2(x))
  expected <- suppressWarnings(.scalar_l2_matrix(x))
  expect_identical(is.infinite(actual), is.infinite(expected))
  expect_identical(unname(diag(actual)), c(0, 0))
})
