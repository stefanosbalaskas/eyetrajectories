test_that("native PACE diagonal-difference noise carries complete primitive diagnostics", {
  times <- list(seq(0, 1, by=.25), seq(.1, .9, by=.2),
    seq(0, .8, by=.2))
  residuals <- lapply(times,function(t) sqrt(.3)+.1*t)
  grid <- seq(0, 1, by=.25)
  latent <- rep(.1,length(grid))
  noise <- .etr_spn_noise_diagonal_difference(
    times,residuals,grid,latent,
    noise_bandwidth=1.1,noise_support=c(.25,.75))
  expect_identical(noise$status_code,"ok")
  expect_gt(noise$variance,0)
  expect_identical(noise$support_mask,c(FALSE,TRUE,TRUE,TRUE,FALSE))
  expect_identical(noise$bandwidth,1.1)
  expect_identical(noise$support_interval,c(.25,.75))
  expect_equal(noise$diagonal_difference,
    noise$raw_diagonal-noise$latent_diagonal)
  expect_equal(noise$variance,
    sum(.etr_spn_weights(grid[2:4])*noise$diagonal_difference[2:4])/
      sum(.etr_spn_weights(grid[2:4])),tolerance=1e-12)

  invalid <- .etr_spn_noise_diagonal_difference(
    times,lapply(times,function(t)numeric(length(t))),
    grid,rep(0,length(grid)),1.1,c(.25,.75))
  expect_identical(invalid$status_code,"noise_variance_invalid")
  expect_identical(invalid$variance,0)
})

test_that("native PACE noise support errors retain source count and interval", {
  times <- list(seq(0, 1, by=.25), seq(0, 1, by=.25))
  residuals <- lapply(times,function(t) .5+.2*t)
  grid <- seq(0, 1, by=.25)
  err <- tryCatch(.etr_spn_noise_diagonal_difference(
    times,residuals,grid,rep(.1,5),1.1,c(.02,.05)),
    error=identity)
  expect_s3_class(err,"etr_sparse_native_error")
  expect_identical(err$code,"insufficient_noise_support")
  expect_equal(err$details$noise_support,c(.02,.05))
  expect_identical(err$details$n_grid_points,0L)
  expect_error(.etr_spn_noise_diagonal_difference(
    times,residuals,grid,rep(.1,4),1.1,c(.25,.75)),
    "latent_diagonal")
  expect_error(.etr_spn_noise_diagonal_difference(
    times,residuals[1],grid,rep(.1,5),1.1,c(.25,.75)),
    "equal length")
})

test_that("native sparse weighted PSD and eigendecomposition reject invalid domains", {
  grid <- c(0,1,2)
  C <- diag(3)
  expect_error(.etr_spn_psd(matrix(1,2,2),grid), "shape")
  expect_error(.etr_spn_psd(matrix(c(1,0,0,0,NaN,0,0,0,1),3,3),grid),
    "finite")
  expect_error(.etr_spn_psd(C,grid,action="unknown"), "psd_action")
  expect_error(.etr_spn_psd(C,grid,tolerance=-1), "psd_tolerance")
  expect_error(.etr_spn_eigensystem(matrix(1,2,2),grid,1L),"shape")
  expect_error(.etr_spn_eigensystem(C,grid,TRUE),"n_components")
  expect_error(.etr_spn_eigensystem(C,grid,0),"n_components")
  expect_error(.etr_spn_eigensystem(C,grid,1L,tolerance=-1),
    "positive_tolerance")
  expect_error(.etr_spn_eigensystem(matrix(c(1,0,0,0,Inf,0,0,0,1),3,3),
    grid,1L),"finite")
})

test_that("diagonal-difference native noise reproduces frozen Python 1.2", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 sparse-noise oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
from eyetrajectoriespy._sparse_native import (
    estimate_noise_variance_diagonal_difference as _etr_source_noise)
_etr_noise_times = [np.arange(0.,1.0001,.25),np.arange(.1,.9001,.2),
    np.arange(0.,.8001,.2)]
_etr_noise_resid = [np.sqrt(.3)+.1*t for t in _etr_noise_times]
_etr_noise_grid = np.arange(0.,1.0001,.25)
_etr_noise_latent = np.full(5,.1)
_etr_noise_cov = np.diag(_etr_noise_latent)
_etr_noise_result = _etr_source_noise(
    _etr_noise_times,_etr_noise_resid,_etr_noise_grid,
    _etr_noise_cov,latent_diagonal=_etr_noise_latent,
    bandwidth=1.1,noise_support=(.25,.75))
_etr_noise_zero = _etr_source_noise(
    _etr_noise_times,[np.zeros_like(t) for t in _etr_noise_times],
    _etr_noise_grid,np.zeros((5,5)),latent_diagonal=np.zeros(5),
    bandwidth=1.1,noise_support=(.25,.75))
")
  times <- list(seq(0,1,by=.25),seq(.1,.9,by=.2),seq(0,.8,by=.2))
  grid <- seq(0,1,by=.25)
  nr <- .etr_spn_noise_diagonal_difference(
    times,lapply(times,function(t)sqrt(.3)+.1*t),
    grid,rep(.1,5),1.1,c(.25,.75))
  py <- reticulate::py_eval("_etr_noise_result",convert=FALSE)
  get <- function(field)
    et_to_r(reticulate::py_get_attr(py,field))
  for(field in c("variance","raw_diagonal","latent_diagonal",
      "diagonal_difference","bandwidth","support_interval"))
    expect_equal(as.numeric(nr[[field]]),as.numeric(get(field)),
      tolerance=1e-11,info=field)
  expect_identical(nr$status_code,as.character(get("status_code")))
  expect_identical(nr$support_mask,as.logical(get("support_mask")))
  source_zero <- reticulate::py_eval(
    "_etr_noise_zero.status_code",convert=TRUE)
  expect_identical(source_zero,"noise_variance_invalid")
})
