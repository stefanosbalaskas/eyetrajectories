test_that("native sparse covariance pairs reproduce Python order and mirror policy", {
  times <- list(c(0, 1, 2), c(10, 11))
  residuals <- list(c(2, 3, 5), c(7, 11))
  both <- .etr_spn_pairs(times, residuals)
  expect_identical(names(both),
    c("s", "t", "products", "curve_index", "mirrored"))
  expect_identical(both$s, c(0, 1, 0, 2, 1, 2, 10, 11))
  expect_identical(both$t, c(1, 0, 2, 0, 2, 1, 11, 10))
  expect_identical(both$products, c(6, 6, 10, 10, 15, 15, 77, 77))
  expect_identical(both$curve_index, c(rep(0L, 6L), 1L, 1L))
  expect_identical(both$mirrored, TRUE)

  forward <- .etr_spn_pairs(times, residuals, include_mirror=FALSE)
  expect_identical(forward$s, c(0, 0, 1, 10))
  expect_identical(forward$t, c(1, 2, 2, 11))
  expect_identical(forward$products, c(6, 10, 15, 77))
  expect_identical(forward$curve_index, c(0L, 0L, 0L, 1L))
  expect_identical(forward$mirrored, FALSE)
})

test_that("native sparse covariance pairs reject invalid source records", {
  expect_error(.etr_spn_pairs(list(c(0, 1, 2)), list()),
    "equal length")
  expect_error(.etr_spn_pairs(list(matrix(c(0, 1, 2), nrow=1L)),
    list(c(2, 3, 5))), "one-dimensional")
  expect_error(.etr_spn_pairs(list(c(0, 1, 2)),
    list(c(2, NA_real_, 5))), "finite")
  expect_error(.etr_spn_pairs(list(c(0, 1, 2)),
    list(c(2, 3, 5)), include_mirror=NA), "scalar logical")
  failed <- tryCatch(
    .etr_spn_pairs(list(c(0, 1)), list(c(2, 3))), error=identity
  )
  expect_s3_class(failed, "etr_sparse_native_error")
  expect_identical(failed$code, "insufficient_within_curve_covariance_pairs")
  expect_identical(failed$details$n_pairs, 2L)

  # One forward-only pair and a single-sample curve are below the
  # Python primitive's three-pair minimum.
  failed <- tryCatch(
    .etr_spn_pairs(list(c(0, 1), 2), list(c(2, 3), 5),
                   include_mirror=FALSE), error=identity
  )
  expect_s3_class(failed, "etr_sparse_native_error")
  expect_identical(failed$details$n_pairs, 1L)
})

test_that("native sparse covariance pair fields match frozen Python 1.2", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"), "true"))
    skip("Frozen Python 1.2 sparse source comparison is opt-in")
  expect_identical(et_python_version(), "1.2.0")
  reticulate::py_run_string("
import numpy as np
from eyetrajectoriespy._sparse_native import raw_offdiagonal_covariance_pairs
_etr_pair_times = [np.array([0., 1., 2.]), np.array([10., 11.])]
_etr_pair_residuals = [np.array([2., 3., 5.]), np.array([7., 11.])]
_etr_pair_both = raw_offdiagonal_covariance_pairs(
    _etr_pair_times, _etr_pair_residuals)
_etr_pair_forward = raw_offdiagonal_covariance_pairs(
    _etr_pair_times, _etr_pair_residuals, include_mirror=False)
")
  times <- list(c(0, 1, 2), c(10, 11))
  residuals <- list(c(2, 3, 5), c(7, 11))
  for(mode in c(TRUE, FALSE)){
    native <- .etr_spn_pairs(times, residuals, include_mirror=mode)
    py <- reticulate::py_eval(
      if(mode) "_etr_pair_both" else "_etr_pair_forward",
      convert=FALSE)
    get <- function(name)
      et_to_r(reticulate::py_get_attr(py,name))
    for(field in c("s", "t", "products"))
      expect_identical(unname(native[[field]]),
        as.numeric(get(field)), info=field)
    expect_identical(native$curve_index, as.integer(get("curve_index")))
    expect_identical(native$mirrored, as.logical(get("mirrored")))
  }
})
