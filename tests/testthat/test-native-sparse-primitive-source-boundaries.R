test_that("sparse interpolators accept two-point grids and retain shape", {
  grid <- c(0, 2)
  target <- c(0, .5, 2)
  values <- c(1, 5)
  C <- matrix(c(2, .5, .5, 3), 2, 2, byrow=TRUE)
  expect_equal(.etr_spn_eval(grid, values, target), c(1, 2, 5),
    tolerance=1e-14)
  expected <- matrix(c(2, 1.625, .5, 1.625, 1.5, 1.125,
    .5, 1.125, 3), 3, 3, byrow=TRUE)
  expect_equal(.etr_spn_cov_eval(grid, C, target), expected,
    tolerance=1e-14)
  expect_identical(.etr_spn_eval(grid, values, numeric()), numeric())
  expect_identical(dim(.etr_spn_cov_eval(grid, C, numeric())), c(0L, 0L))
})

test_that("sparse interpolators reject malformed domains with source details", {
  grid <- c(0, 2)
  bad <- tryCatch(.etr_spn_eval(grid, c(1, 5), c(-.25, 1)),
    error=identity)
  expect_s3_class(bad, "etr_sparse_native_error")
  expect_identical(bad$code, "native_time_outside_fitted_support")
  expect_equal(bad$details$grid_start, 0)
  expect_equal(bad$details$grid_end, 2)
  expect_equal(bad$details$target_min, -.25)
  expect_equal(bad$details$target_max, 1)

  C <- matrix(c(2, .5, .5, 3), 2, 2)
  bad_c <- tryCatch(.etr_spn_cov_eval(grid, C, c(1, 2.25)),
    error=identity)
  expect_s3_class(bad_c, "etr_sparse_native_error")
  expect_identical(bad_c$code, "native_time_outside_fitted_support")
  expect_equal(bad_c$details$target_min, 1)
  expect_equal(bad_c$details$target_max, 2.25)
  expect_error(.etr_spn_eval(grid, 1, 1), "one value per evaluation-grid")
  expect_error(.etr_spn_cov_eval(grid, matrix(1, 1L, 1L), 1),
    "shape")
  expect_error(.etr_spn_eval(c(0, 0), c(1, 2), 0), "grid")
  expect_error(.etr_spn_eval(grid, c(1, 2), NA_real_), "finite")
  expect_error(.etr_spn_eval(grid, c(1, 2), matrix(1, 1L, 1L)),
    "one-dimensional")
})

test_that("sparse PSD and weighted eigensystem failures retain source diagnostics", {
  grid <- c(0, 1)
  covariance <- matrix(c(1, 3, 3, 1), 2, 2)
  psd <- tryCatch(.etr_spn_psd(covariance, grid, action="error"),
    error=identity)
  expect_s3_class(psd, "etr_sparse_native_error")
  expect_identical(psd$code, "covariance_psd_failure")
  expect_equal(psd$details$most_negative_eigenvalue, -1,
    tolerance=1e-12)
  expect_identical(psd$details$negative_eigenvalue_count, 1L)
  expect_identical(psd$details$substantial_negative_eigenvalue_count, 1L)
  expect_equal(psd$details$tolerance, 1e-8)

  one_component <- diag(c(2, 0))
  insufficient <- tryCatch(.etr_spn_eigensystem(
    one_component, grid, k=2L, tolerance=1e-10), error=identity)
  expect_s3_class(insufficient, "etr_sparse_native_error")
  expect_identical(insufficient$code, "insufficient_positive_components")
  expect_identical(insufficient$details$requested_components, 2L)
  expect_identical(insufficient$details$positive_components, 1L)
  expect_equal(insufficient$details$positive_tolerance, 1e-10)
})

test_that("sparse primitive arrays and source error details match frozen Python", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"), "true"))
    skip("Frozen Python 1.2 sparse primitive oracle is opt-in")
  expect_identical(et_python_version(), "1.2.0")
  reticulate::py_run_string("
import numpy as np
from eyetrajectoriespy import _sparse_native as _etr_spn_py
_etr_spn_grid2 = np.array([0., 2.])
_etr_spn_t2 = np.array([0., .5, 2.])
_etr_spn_vals2 = np.array([1., 5.])
_etr_spn_c2 = np.array([[2., .5], [.5, 3.]])
_etr_spn_fn2 = _etr_spn_py.evaluate_fitted_function(
    _etr_spn_grid2, _etr_spn_vals2, _etr_spn_t2)
_etr_spn_cov2 = _etr_spn_py.evaluate_fitted_covariance(
    _etr_spn_grid2, _etr_spn_c2, _etr_spn_t2)
def _etr_spn_catch(fn):
    try:
        fn()
    except Exception as error:
        return (type(error).__name__, getattr(error, 'code', None),
                getattr(error, 'details', {}))
    raise AssertionError('expected frozen source failure')
_etr_spn_bounds = _etr_spn_catch(
    lambda: _etr_spn_py.evaluate_fitted_function(
        _etr_spn_grid2, _etr_spn_vals2, np.array([-.25, 1.])))
_etr_spn_psd_error = _etr_spn_catch(
    lambda: _etr_spn_py.repair_covariance_psd(
        np.array([[1., 3.], [3., 1.]]), np.array([0., 1.])))
_etr_spn_eigen_error = _etr_spn_catch(
    lambda: _etr_spn_py.weighted_covariance_eigendecomposition(
        np.array([[2., 0.], [0., 0.]]), np.array([0., 1.]),
        n_components=2))
")
  py_get <- function(expr) et_to_r(reticulate::py_eval(expr,convert=FALSE))
  expect_equal(.etr_spn_eval(c(0, 2), c(1, 5), c(0, .5, 2)),
    as.numeric(py_get("_etr_spn_fn2")), tolerance=1e-13)
  expect_equal(.etr_spn_cov_eval(c(0, 2),
    matrix(c(2,.5,.5,3),2,2),c(0,.5,2)),
    unname(py_get("_etr_spn_cov2")), tolerance=1e-13,
    ignore_attr=TRUE)
  bounds <- py_get("_etr_spn_bounds")
  error <- tryCatch(.etr_spn_eval(c(0,2),c(1,5),c(-.25,1)),
    error=identity)
  expect_identical(as.character(bounds[[2L]]), error$code)
  for(key in names(error$details))
    expect_equal(as.numeric(bounds[[3L]][[key]]),
      as.numeric(error$details[[key]]), info=key)

  for(spec in list(
      list(name="_etr_spn_psd_error",
        failure=tryCatch(.etr_spn_psd(matrix(c(1,3,3,1),2,2),
          c(0,1),action="error"),error=identity)),
      list(name="_etr_spn_eigen_error",
        failure=tryCatch(.etr_spn_eigensystem(diag(c(2,0)),
          c(0,1),2L),error=identity)))) {
    ref <- py_get(spec$name)
    expect_identical(as.character(ref[[2L]]), spec$failure$code)
    for(key in names(spec$failure$details))
      expect_equal(as.numeric(ref[[3L]][[key]]),
        as.numeric(spec$failure$details[[key]]), tolerance=1e-12,
        info=paste(spec$name,key))
  }
})
