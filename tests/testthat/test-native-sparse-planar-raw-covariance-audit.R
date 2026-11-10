# Pinned eyetrajectoriespy==1.2.0 _sparse_multivariate.py:
# raw_planar_covariance_pairs, _local_linear_planar_surface,
# audit_repair_planar_covariance, commit c1cd95ad718327550f7e55393ff38582872f7a94.
# These are fixed source-algorithm comparisons, not estimator certifications.

.etr_spnm_raw_order_fixture<-function(){
  list(times=list(c(0,1,2),c(3,4)),
    rx=list(c(2,3,5),c(7,11)),
    ry=list(c(7,11,13),c(17,19)))
}

test_that("planar xy products follow frozen Python left-outer right-inner order",{
  p<-.etr_spnm_raw_order_fixture()
  raw<-.etr_spnm_pairs(p$times,p$rx,p$ry)
  expect_identical(raw$xy$s,c(0,0,1,1,2,2,3,4))
  expect_identical(raw$xy$t,c(1,2,0,2,0,1,4,3))
  expect_identical(raw$xy$products,
    c(22,26,21,39,35,55,133,187))
  expect_identical(raw$counts,
    c(xx=8L,xy=8L,yy=8L))
  expect_false(any(raw$xy$s==raw$xy$t))
})

test_that("raw planar smoother does not mask within-channel asymmetry",{
  p<-list(s=rep(c(0,1,2),each=3),
    t=rep(c(0,1,2),times=3))
  p$products<-1+2*p$s-.4*p$t
  smoothed<-.etr_spnm_surface(p,c(0,1,2),4,min_pairs=6L)
  expect_identical(smoothed$support_counts,matrix(9L,3L,3L))
  expect_equal(smoothed$values,
    outer(c(0,1,2),c(0,1,2),
      function(s,t)1+2*s-.4*t),tolerance=1e-12)
  expect_gt(max(abs(smoothed$values-t(smoothed$values))),1)
})

test_that("planar joint operator checks raw asymmetry before symmetrizing",{
  grid<-c(0,1,2)
  xx<-diag(c(1,1.2,1.5))
  xx[1,2]<-.05+1e-12
  xx[2,1]<-.05
  yy<-diag(c(1.1,1.3,1.6))
  xy<-matrix(0,3L,3L)
  audited<-.etr_spnm_operator(list(xx=xx,xy=xy,yy=yy),
    grid,action="error",symmetry_tolerance=1e-10)
  expect_equal(audited$smoothed$cxx,xx,tolerance=0)
  expect_gt(audited$audit$pre_enforcement_symmetry_error,0)
  expect_equal(audited$covariance$cxx,
    (xx+t(xx))/2,tolerance=1e-14)
  bad<-xx
  bad[1,2]<-.055
  failure<-tryCatch(
    .etr_spnm_operator(list(xx=bad,xy=xy,yy=yy),
      grid,action="project",symmetry_tolerance=1e-10),
    error=identity)
  expect_s3_class(failure,"etr_sparse_native_error")
  expect_identical(failure$code,"joint_covariance_symmetry_failure")
  expect_equal(failure$details$maximum_symmetry_error,.005,tolerance=1e-12)
})

test_that("planar raw pairs smoothing and PSD audit match frozen Python 1.2",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 raw planar source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  p<-.etr_spnm_raw_order_fixture()
  reticulate::py_run_string("
import numpy as np
from eyetrajectoriespy._sparse_native import RawCovariancePairs
from eyetrajectoriespy._sparse_multivariate import (
    raw_planar_covariance_pairs,
    _local_linear_planar_surface,
    audit_repair_planar_covariance)
_time=[np.array([0.,1.,2.]),np.array([3.,4.])]
_x=[np.array([2.,3.,5.]),np.array([7.,11.])]
_y=[np.array([7.,11.,13.]),np.array([17.,19.])]
_source_pairs=raw_planar_covariance_pairs(_time,_x,_y)
_s=np.repeat(np.array([0.,1.,2.]),3)
_t=np.tile(np.array([0.,1.,2.]),3)
_p=RawCovariancePairs(s=_s,t=_t,products=1+2*_s-.4*_t,
   curve_index=np.zeros(9,dtype=int),mirrored=False)
_source_surface=_local_linear_planar_surface(
   _p,np.array([0.,1.,2.]),bandwidth=4.,
   min_local_pairs=6,block_name='xx')
_xx=np.diag([1.,1.2,1.5])
_xx[0,1]=.05+1e-12
_xx[1,0]=.05
_yy=np.diag([1.1,1.3,1.6])
_xy=np.zeros((3,3))
_source_audit=audit_repair_planar_covariance(
   _xx,_xy,_yy,np.array([0.,1.,2.]),
   action='error',symmetry_tolerance=1e-10)
")
  native<-.etr_spnm_pairs(p$times,p$rx,p$ry)
  for(field in c("s","t","products")){
    py<-reticulate::py_eval(
      paste0("_source_pairs.xy.",field),convert=FALSE)
    expect_identical(as.numeric(native$xy[[field]]),
      as.numeric(et_to_r(py)),info=field)
  }
  points<-list(s=rep(c(0,1,2),each=3),
    t=rep(c(0,1,2),times=3))
  points$products<-1+2*points$s-.4*points$t
  smooth<-.etr_spnm_surface(points,c(0,1,2),4,min_pairs=6L)
  expect_equal(smooth$values,
    et_to_r(reticulate::py_eval("_source_surface.values",convert=FALSE)),
    tolerance=1e-12,ignore_attr=TRUE)
  expect_equal(smooth$support_counts,
    et_to_r(reticulate::py_eval(
      "_source_surface.support_counts",convert=FALSE)),
    tolerance=0,ignore_attr=TRUE)
  xx<-diag(c(1,1.2,1.5))
  xx[1,2]<-.05+1e-12
  xx[2,1]<-.05
  op<-.etr_spnm_operator(
    list(xx=xx,xy=matrix(0,3,3),yy=diag(c(1.1,1.3,1.6))),
    c(0,1,2),action="error",symmetry_tolerance=1e-10)
  expect_equal(op$smoothed$cxx,
    et_to_r(reticulate::py_eval(
      "_source_audit.smoothed_cxx",convert=FALSE)),
    tolerance=0,ignore_attr=TRUE)
  expect_equal(op$covariance$cxx,
    et_to_r(reticulate::py_eval("_source_audit.cxx",convert=FALSE)),
    tolerance=1e-12,ignore_attr=TRUE)
  expect_equal(op$audit$pre_enforcement_symmetry_error,
    as.numeric(reticulate::py_eval(
      "_source_audit.audit.pre_enforcement_symmetry_error",convert=TRUE)),
    tolerance=1e-14)
})
