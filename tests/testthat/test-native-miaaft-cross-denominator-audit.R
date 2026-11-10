test_that("MIAAFT denominator diagnostics preserve the frozen cross-spectral law", {
  n <- 96L
  t <- 0:(n-1L)
  original <- cbind(
    sin(2*pi*5*t/n),
    cos(2*pi*5*t/n+.3),
    sin(2*pi*11*t/n+.4)
  )
  changed <- original
  changed[,2L] <- .9*original[,2L]+.1*cos(2*pi*9*t/n)
  target <- .etr_multivariate_fft_half(original)
  pairs <- combn(1:3,2L,simplify=FALSE)
  plain <- .etr_multivariate_spectrum_errors(changed,target,pairs)
  audited <- .etr_multivariate_spectrum_errors(
    changed,target,pairs,denominator_audit=TRUE)
  expect_identical(plain, audited[c("spectral","cross")])
  expect_identical(names(audited),
    c("spectral","cross","denominator_audit"))
  diagnostics <- audited$denominator_audit
  expect_identical(nrow(diagnostics),3L)
  expect_identical(diagnostics$left,c(0L,0L,1L))
  expect_identical(diagnostics$right,c(1L,2L,2L))
  expect_identical(diagnostics$near_zero_cross_spectral_target,
    c(FALSE,TRUE,TRUE))
  expect_true(all(diagnostics$source_denominator >=
    .Machine$double.eps))
  expect_equal(diagnostics$relative_error,plain$cross,
    tolerance=1e-14)
  expect_equal(diagnostics$relative_error,
    diagnostics$cross_spectral_difference_norm/
      diagnostics$source_denominator,tolerance=1e-13)
  expect_true(all(diagnostics$roundoff_warning_threshold>0))
  expect_true(all(is.finite(diagnostics$target_cross_spectral_norm)))
  expect_true(all(is.finite(diagnostics$independent_channel_norm_product)))
  expect_gt(diagnostics$target_cross_spectral_norm[1],
    diagnostics$roundoff_warning_threshold[1])
  expect_lt(diagnostics$target_cross_spectral_norm[2],
    diagnostics$roundoff_warning_threshold[2])
})

test_that("MIAAFT denominator audit leaves surrogate p-value computations unchanged", {
  n <- 96L
  t <- 0:(n-1L)
  x <- cbind(sin(2*pi*5*t/n),
    cos(2*pi*5*t/n+.3),
    sin(2*pi*11*t/n+.4))
  target <- .etr_multivariate_fft_half(x)
  pairs <- combn(1:3,2L,simplify=FALSE)
  a <- .etr_multivariate_spectrum_errors(x,target,pairs)
  b <- .etr_multivariate_spectrum_errors(
    x,target,pairs,denominator_audit=TRUE)
  expect_identical(a,b[c("spectral","cross")])
  expect_equal(a$cross,rep(0,3L),tolerance=1e-12)
})

test_that("nondegenerate MIAAFT cross errors agree with frozen Python 1.2", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 direct spectral source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
from eyetrajectoriespy.multivariate_surrogates import _spectrum_errors
_t=np.arange(96,dtype=float)
_v=np.column_stack((
  np.sin(2*np.pi*5*_t/96),
  np.cos(2*np.pi*5*_t/96+.3),
  np.sin(2*np.pi*11*_t/96+.4)))
_w=_v.copy()
_w[:,1]=.9*_v[:,1]+.1*np.cos(2*np.pi*9*_t/96)
_target=np.fft.rfft(_v,axis=0)
_e,_c=_spectrum_errors(
  _w,target_amplitudes=np.abs(_target),
  target_cross_spectra=tuple(
    _target[:,i]*np.conj(_target[:,j]) for i,j in ((0,1),(0,2),(1,2))),
  pairs=((0,1),(0,2),(1,2)))
")
  n <- 96L
  t <- 0:(n-1L)
  source <- cbind(sin(2*pi*5*t/n),
    cos(2*pi*5*t/n+.3),
    sin(2*pi*11*t/n+.4))
  modified <- source
  modified[,2L] <- .9*source[,2L]+.1*cos(2*pi*9*t/n)
  native <- .etr_multivariate_spectrum_errors(
    modified,.etr_multivariate_fft_half(source),
    combn(1:3,2L,simplify=FALSE),denominator_audit=TRUE)
  py_spectral <- as.numeric(reticulate::py_eval("_e",convert=TRUE))
  py_cross <- as.numeric(reticulate::py_eval("_c",convert=TRUE))
  expect_equal(native$spectral,py_spectral,tolerance=1e-10)
  expect_equal(native$cross[1L],py_cross[1L],tolerance=1e-10)
  # A near-zero source cross-spectrum amplifies FFT roundoff.
  # It is explicitly excluded from numerical agreement claims.
  expect_identical(native$denominator_audit$
    near_zero_cross_spectral_target,c(FALSE,TRUE,TRUE))
})
