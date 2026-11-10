# Frozen Python 1.2 _sparse_multivariate_async.py:
# build_async_observation_layout, evaluate_async_planar_covariance,
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
# No reticulate dependency in the native scientific implementation.

.etr_async_cov_source_fixture<-function(){
  grid<-c(0,1,2,3)
  xx<-outer(grid,grid,function(s,t)1+.12*s+.07*t)
  xy<-outer(grid,grid,function(s,t).1+.09*s-.14*t)
  yy<-outer(grid,grid,function(s,t)2+.03*s+.11*t)
  blocks<-list(cxx=xx,cxy=xy,cyx=t(xy),cyy=yy)
  list(grid=grid,blocks=blocks,
    tx=c(.1,1,2.5),x=c(3,1,5),
    ty=c(.1,1.4,2.7),y=c(2,4,6))
}

test_that("async scalar observation index and source time order are preserved",{
  f<-.etr_async_cov_source_fixture()
  a<-.etr_spna_scalar_layout(f$tx,f$x,f$ty,f$y,0)
  expect_equal(a$time,c(.1,.1,1,1.4,2.5,2.7),tolerance=0)
  expect_identical(a$channel,c(1L,2L,1L,2L,1L,2L))
  expect_identical(a$source_indices,c(0L,0L,1L,1L,2L,2L))
  expect_identical(a$original,a$source_indices+1L)
  expect_identical(a$simultaneous,1L)
  expect_error(.etr_spna_scalar_layout(1,1,2,c(2,3),0),
    "aligned finite")
  expect_error(.etr_spna_scalar_layout(c(1,Inf),c(1,2),2,2,0),
    "aligned finite")
  expect_error(.etr_spna_scalar_layout(1,1,2,2,-.1),
    "same_time_tolerance")
})

test_that("source async covariance uses directional XY on real asynchronous times",{
  f<-.etr_async_cov_source_fixture()
  layout<-.etr_spna_scalar_layout(f$tx,f$x,f$ty,f$y,0)
  c<-.etr_spna_cov_eval(f$grid,f$blocks,layout)
  expect_identical(dim(c),c(6L,6L))
  expect_equal(c,t(c),tolerance=1e-15)
  expect_true(all(is.finite(c)))
  # XY is directional: cross pairing is not obtained by
  # self-symmetrizing Cxy(s,t) or synchronizing observations.
  ix<-which(layout$channel==1L)
  iy<-which(layout$channel==2L)
  source_xy<-outer(layout$time[ix],layout$time[iy],
    function(s,t).1+.09*s-.14*t)
  expect_equal(c[ix,iy],source_xy,tolerance=1e-14)
  expect_equal(c[iy,ix],t(source_xy),tolerance=1e-14)
  expect_gt(max(abs(source_xy-t(source_xy))),.02)
})

test_that("async covariance validates support and admits empty/one-channel layouts",{
  f<-.etr_async_cov_source_fixture()
  empty<-.etr_spna_scalar_layout(numeric(),numeric(),
    numeric(),numeric(),0)
  expect_identical(dim(.etr_spna_cov_eval(f$grid,f$blocks,empty)),c(0L,0L))
  xonly<-.etr_spna_scalar_layout(c(.1,2.7),c(1,2),
    numeric(),numeric(),0)
  xx<-.etr_spna_cov_eval(f$grid,f$blocks,xonly)
  expect_identical(dim(xx),c(2L,2L))
  expect_equal(xx,t(xx),tolerance=1e-15)
  yonly<-.etr_spna_scalar_layout(numeric(),numeric(),
    c(.2,1.8),c(2,3),0)
  expect_identical(dim(.etr_spna_cov_eval(f$grid,f$blocks,yonly)),c(2L,2L))
  outer<-.etr_spna_scalar_layout(c(-.1,1),c(1,2),
    c(3.25),c(5),0)
  failed<-tryCatch(.etr_spna_cov_eval(f$grid,f$blocks,outer),
    error=identity)
  expect_s3_class(failed,"etr_sparse_native_error")
  expect_identical(failed$code,"native_time_outside_fitted_support")
  expect_equal(failed$details$grid_start,0)
  expect_equal(failed$details$grid_end,3)
  expect_equal(failed$details$target_min,-.1)
  expect_equal(failed$details$target_max,3.25)
  layout<-.etr_spna_scalar_layout(f$tx,f$x,f$ty,f$y,0)
  invalid<-layout;invalid$channel[1]<-3L
  expect_error(.etr_spna_cov_eval(f$grid,f$blocks,invalid),
    "aligned planar")
  invalid<-layout;invalid$time[1]<-NA_real_
  expect_error(.etr_spna_cov_eval(f$grid,f$blocks,invalid),
    "aligned planar")
})

test_that("async covariance and layout match Python frozen numerical source",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Python 1.2 async source comparison is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
from eyetrajectoriespy._sparse_multivariate import PlanarCovarianceBlocks
from eyetrajectoriespy._sparse_multivariate_async import (
  build_async_observation_layout,evaluate_async_planar_covariance)
from eyetrajectoriespy._sparse_native import SparseNativeError
_grid=np.array([0.,1.,2.,3.])
_s=_grid[:,None]
_t=_grid[None,:]
_xx=1+.12*_s+.07*_t
_yy=2+.03*_s+.11*_t
_xy=.1+.09*_s-.14*_t
_blocks=PlanarCovarianceBlocks(cxx=_xx,cyy=_yy,cxy=_xy,cyx=_xy.T)
_tx=np.array([.1,1.,2.5]);_ty=np.array([.1,1.4,2.7])
_lay=build_async_observation_layout(_tx,np.array([3.,1.,5.]),
 _ty,np.array([2.,4.,6.]),same_time_tolerance=0.)
_pycov=evaluate_async_planar_covariance(_grid,_blocks,_lay)
def _async_cov_for(tx,ty):
    lay=build_async_observation_layout(np.array(tx,dtype=float),
      np.ones(len(tx)),np.array(ty,dtype=float),np.ones(len(ty)))
    return evaluate_async_planar_covariance(_grid,_blocks,lay)
def _async_cov_error():
    try:
        _async_cov_for([-.1,1.],[3.25])
    except SparseNativeError as e:
        return dict(code=e.code,details=e.details)
    raise AssertionError('missing source covariance support error')
")
  f<-.etr_async_cov_source_fixture()
  r<-.etr_spna_scalar_layout(f$tx,f$x,f$ty,f$y,0)
  for(pair in list(
    c("time","times"),c("channel","channels"),
    c("value","values"),c("source_indices","source_indices"))){
    native<-r[[pair[[1L]]]]
    py<-et_to_r(reticulate::py_eval(
      paste0("_lay.",pair[[2L]]),convert=FALSE))
    if(pair[[1L]]=="channel")py<-as.integer(py)+1L
    expect_equal(native,py,tolerance=0,ignore_attr=TRUE,
      info=paste("layout",pair[[1L]]))
  }
  expect_identical(r$simultaneous,as.integer(
    reticulate::py_eval("_lay.n_simultaneous_pairs")))
  ours<-.etr_spna_cov_eval(f$grid,f$blocks,r)
  theirs<-et_to_r(reticulate::py_eval("_pycov",convert=FALSE))
  expect_equal(ours,theirs,tolerance=1e-12,ignore_attr=TRUE)
  for(case in list(list(tx=numeric(),ty=numeric()),
    list(tx=c(.1,2.7),ty=numeric()),
    list(tx=numeric(),ty=c(.2,1.8)))){
    layout<-.etr_spna_scalar_layout(case$tx,rep(1,length(case$tx)),
      case$ty,rep(1,length(case$ty)),0)
    native<-.etr_spna_cov_eval(f$grid,f$blocks,layout)
    source<-reticulate::py_call(
      reticulate::py_get_attr(reticulate::py,"_async_cov_for"),
      case$tx,case$ty)
    expect_equal(native,et_to_r(source),tolerance=1e-12,
      ignore_attr=TRUE,info=paste("x=",length(case$tx),
      "y=",length(case$ty)))
  }
  x<-.etr_spna_scalar_layout(c(-.1,1),c(1,1),3.25,1,0)
  failed<-tryCatch(.etr_spna_cov_eval(f$grid,f$blocks,x),
    error=identity)
  expected<-reticulate::py_to_r(reticulate::py_call(
    reticulate::py_get_attr(reticulate::py,"_async_cov_error")))
  expect_identical(failed$code,expected$code)
  for(field in names(expected$details))
    expect_equal(failed$details[[field]],expected$details[[field]],
      tolerance=1e-14,info=field)
})
