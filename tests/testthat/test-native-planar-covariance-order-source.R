# Frozen eyetrajectoriespy==1.2.0 _sparse_multivariate.py source:
# evaluate_planar_covariance and permute_planar_channel_major_to_time_major
# (commit c1cd95ad718327550f7e55393ff38582872f7a94).

.etr_cov_source_order_fixture <- function(){
  grid<-c(0,1,2,3,4)
  blocks<-list(
    cxx=outer(grid,grid,function(s,t)1+.1*s*t),
    cxy=outer(grid,grid,function(s,t).05+.1*s-.2*t),
    cyy=outer(grid,grid,function(s,t)2+.2*s*t))
  list(grid=grid,blocks=blocks,times=c(0,.2,1.7,4))
}

test_that("joint covariance preserves both source permutations and XY direction",{
  x<-.etr_cov_source_order_fixture()
  m<-length(x$times)
  cm<-.etr_spnm_cov_eval(x$grid,x$blocks,x$times,
    order="channel_major")
  tm<-.etr_spnm_cov_eval(x$grid,x$blocks,x$times)
  indices<-as.vector(rbind(seq_len(m),m+seq_len(m)))
  expect_identical(dim(cm),c(2L*m,2L*m))
  expect_equal(tm,cm[indices,indices,drop=FALSE],tolerance=0)
  expect_identical(tm,
    .etr_spnm_cov_eval(x$grid,x$blocks,x$times,
      order="time_major"))
  expect_equal(cm[seq_len(m),m+seq_len(m)],
    t(cm[m+seq_len(m),seq_len(m)]),tolerance=0)
  expect_gt(max(abs(cm[seq_len(m),m+seq_len(m)]-
    t(cm[seq_len(m),m+seq_len(m)]))),.01)
})

test_that("source covariance evaluation rejects out-of-support and empty time-major",{
  x<-.etr_cov_source_order_fixture()
  failure<-tryCatch(.etr_spnm_cov_eval(x$grid,x$blocks,
    c(-.25,1.2),order="channel_major"),error=identity)
  expect_s3_class(failure,"etr_sparse_native_error")
  expect_identical(failure$code,"native_time_outside_fitted_support")
  expect_equal(failure$details$grid_start,0)
  expect_equal(failure$details$grid_end,4)
  expect_equal(failure$details$target_min,-.25)
  expect_equal(failure$details$target_max,1.2)
  expect_identical(dim(.etr_spnm_cov_eval(x$grid,x$blocks,
    numeric(),order="channel_major")),c(0L,0L))
  expect_error(.etr_spnm_cov_eval(x$grid,x$blocks,numeric()),
    "n_time_points must be positive")
  expect_error(.etr_spnm_cov_eval(x$grid,x$blocks,1,
    order="invalid"),"order must")
  expect_error(.etr_spnm_cov_eval(x$grid,x$blocks,NA_real_),
    "finite one-dimensional")
})

test_that("joint covariance order and boundary data match frozen Python",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 evaluation source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
from eyetrajectoriespy._sparse_multivariate import (
  PlanarCovarianceBlocks, evaluate_planar_covariance)
from eyetrajectoriespy._sparse_native import SparseNativeError
_sgrid = np.array([0.,1.,2.,3.,4.])
_s = _sgrid[:,None]
_t = _sgrid[None,:]
_blocks = PlanarCovarianceBlocks(
 cxx=1+.1*_s*_t+np.zeros((5,5)),
 cxy=.05+.1*_s-.2*_t,
 cyx=(.05+.1*_s-.2*_t).T,
 cyy=2+.2*_s*_t+np.zeros((5,5)))
_times = np.array([0.,.2,1.7,4.])
def _s_cov_order(order, times=_times):
    return evaluate_planar_covariance(
      _sgrid,_blocks,times,order=order)
def _s_cov_failure():
    try:
        _s_cov_order('channel_major',np.array([-.25,1.2]))
    except SparseNativeError as e:
        return {'code':e.code,'details':e.details}
    raise AssertionError('Expected out-of-support error')
")
  f<-.etr_cov_source_order_fixture()
  for(order in c("time_major","channel_major")){
    result<-reticulate::py_call(
      reticulate::py_get_attr(reticulate::py,"_s_cov_order"),
      order)
    expect_equal(
      .etr_spnm_cov_eval(f$grid,f$blocks,f$times,order=order),
      et_to_r(result),tolerance=1e-12,ignore_attr=TRUE,
      info=paste(order,"frozen directional covariance"))
  }
  expected<-reticulate::py_to_r(reticulate::py_call(
    reticulate::py_get_attr(reticulate::py,"_s_cov_failure")))
  failure<-tryCatch(
    .etr_spnm_cov_eval(f$grid,f$blocks,c(-.25,1.2),
      order="channel_major"),error=identity)
  expect_identical(failure$code,expected$code)
  for(field in names(expected$details))
    expect_equal(failure$details[[field]],expected$details[[field]],
      tolerance=1e-12,info=field)
  py_empty<-reticulate::py_call(
    reticulate::py_get_attr(reticulate::py,"_s_cov_order"),
    "channel_major",reticulate::r_to_py(numeric()))
  expect_identical(dim(.etr_spnm_cov_eval(f$grid,f$blocks,
    numeric(),order="channel_major")),dim(et_to_r(py_empty)))
})
