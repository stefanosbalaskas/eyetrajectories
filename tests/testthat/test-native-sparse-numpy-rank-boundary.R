test_that("sparse local rank follows the frozen NumPy SVD threshold", {
  # At 1e-13, NumPy's relative SVD rank is two; qr(tol=1e-12)
  # incorrectly treated this local-linear design as rank deficient.
  time <- c(-2, -1, 0, 1, 2) * 1e-13
  response <- c(2, 3, 5, 4, 6)
  fitted <- .etr_spn_mean(
    time, response, c(0, 5e-14), h=1e-12, min_points=3L
  )
  expect_identical(fitted$support_counts, c(5L, 5L))
  expect_equal(
    fitted$values,
    c(4.002040816326531, 4.450343290893233),
    tolerance=1e-9
  )

  # The same design on a 1e-18 time scale is rank one under
  # NumPy's max(m,n) * sigma_max * machine-epsilon criterion.
  failure <- tryCatch(
    .etr_spn_mean(time / 1e5, response, 0, h=1e-17),
    error=identity
  )
  expect_s3_class(failure, "etr_sparse_native_error")
  expect_identical(failure$code, "insufficient_mean_local_support")
  expect_identical(failure$details$evaluation_point, 0)
  expect_identical(failure$details$support_count, 5L)
  expect_equal(failure$details$bandwidth, 1e-17)
})

test_that("sparse source errors retain local support and point coordinates", {
  insufficient <- tryCatch(
    .etr_spn_mean(c(0, 1, 2), c(1, 2, 3), 0,
                  h=0.1, min_points=3L),
    error=identity
  )
  expect_s3_class(insufficient, "etr_sparse_native_error")
  expect_identical(insufficient$code, "insufficient_mean_local_support")
  expect_identical(insufficient$details$evaluation_point, 0)
  expect_identical(insufficient$details$support_count, 1L)
  expect_identical(insufficient$details$required_count, 3L)
  expect_equal(insufficient$details$bandwidth, 0.1)

  pairs <- list(s=rep(0, 6L), t=rep(0, 6L),
                products=as.numeric(seq_len(6L)))
  covariance <- tryCatch(
    .etr_spn_surface(pairs, c(0, 1, 2), h=2, min_pairs=6L),
    error=identity
  )
  expect_s3_class(covariance, "etr_sparse_native_error")
  expect_identical(covariance$code, "insufficient_covariance_local_support")
  expect_identical(covariance$details$s, 0)
  expect_identical(covariance$details$t, 0)
  expect_identical(covariance$details$support_count, 6L)
  expect_equal(covariance$details$bandwidth, 2)

  diagonal <- tryCatch(
    .etr_spn_rotated_diagonal(pairs, c(0, 1, 2),
                              h=2, min_pairs=6L),
    error=identity
  )
  expect_s3_class(diagonal, "etr_sparse_native_error")
  expect_identical(diagonal$code, "insufficient_noise_diagonal_local_support")
  expect_identical(diagonal$details$evaluation_point, 0)
  expect_identical(diagonal$details$support_count, 6L)
  expect_equal(diagonal$details$bandwidth, 2)
})

test_that("tiny-time sparse smoother agrees with frozen Python 1.2", {
  if (!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"), "true"))
    skip("Frozen Python 1.2 direct sparse oracle is opt-in")
  expect_identical(et_python_version(), "1.2.0")
  reticulate::py_run_string("
import numpy as np
from eyetrajectoriespy._sparse_native import local_linear_smooth_1d
_etr_small_t = np.array([-2., -1., 0., 1., 2.]) * 1e-13
_etr_small_y = np.array([2., 3., 5., 4., 6.])
_etr_small_p = np.array([0., 5e-14])
_etr_small_fit = local_linear_smooth_1d(
    _etr_small_t, _etr_small_y, _etr_small_p, bandwidth=1e-12
)
")
  native <- .etr_spn_mean(
    c(-2, -1, 0, 1, 2)*1e-13, c(2, 3, 5, 4, 6),
    c(0, 5e-14), h=1e-12
  )
  expect_equal(
    native$values,
    as.numeric(reticulate::py_eval("_etr_small_fit.values")),
    tolerance=1e-9
  )
  expect_identical(
    native$support_counts,
    as.integer(reticulate::py_eval("_etr_small_fit.support_counts"))
  )
})
