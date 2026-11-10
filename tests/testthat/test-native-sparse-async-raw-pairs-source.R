# Frozen eyetrajectoriespy==1.2.0 _sparse_multivariate_async.py
# raw_async_planar_covariance_pairs source c1cd95ad718327550f7e55393ff38582872f7a94.

.etr_async_pair_source_fixture<-function(){
  list(
    tx=list(c(.1,.2,.3),c(.5,.7)),
    rx=list(c(2,3,5),c(7,11)),
    ty=list(c(.1,.25),c(.6,.7,.8)),
    ry=list(c(13,17),c(19,23,29)),
    tolerance=.051)
}

test_that("cross-channel raw asynchronous products follow source ordering and indices",{
  a<-.etr_async_pair_source_fixture()
  native<-.etr_spna_cross_pairs(a$tx,a$rx,a$ty,a$ry,a$tolerance)
  expect_identical(native$xy$mirrored,FALSE)
  expect_true(is.integer(native$xy$curve_index))
  expect_identical(length(native$xy$curve_index),length(native$xy$s))
  expect_identical(length(native$xy$s),length(native$xy$t))
  expect_identical(length(native$xy$s),length(native$xy$products))
  expect_true(all(native$xy$curve_index%in%c(0L,1L)))
  expect_identical(native$audit$cross_candidate_pair_count,12L)
  expect_identical(native$audit$cross_same_time_pair_count_excluded,4L)
  expect_identical(native$audit$cross_retained_pair_count,8L)
  expect_identical(native$pair_counts[["xy"]],8L)
  expect_true(all(is.finite(native$xy$products)))
  expect_true(all(native$xx$mirrored))
  expect_true(all(native$yy$mirrored))
})

test_that("async cross covariance failure retains Python candidate/exclusion evidence",{
  tx<-list(c(0,1,2),c(0,1,2))
  ty<-list(c(0,1,2),c(0,1,2))
  rx<-list(1:3,3:1)
  ry<-list(2:4,4:2)
  failure<-tryCatch(.etr_spna_cross_pairs(tx,rx,ty,ry,0),
    error=identity)
  expect_s3_class(failure,"etr_sparse_native_error")
  expect_identical(failure$code,"insufficient_async_cross_covariance_pairs")
  expect_identical(failure$details$candidate_cross_pairs,18L)
  expect_identical(failure$details$same_time_pairs_excluded,6L)
  expect_identical(failure$details$retained_cross_pairs,12L)
})

test_that("async cross covariance reports source failure after tolerance exclusions",{
  tx<-list(c(0,1,2),c(0,1,2))
  ty<-list(c(0,1,2),c(0,1,2))
  rx<-list(1:3,3:1)
  ry<-list(2:4,4:2)
  failure<-tryCatch(.etr_spna_cross_pairs(tx,rx,ty,ry,2),
    error=identity)
  expect_s3_class(failure,"etr_sparse_native_error")
  expect_identical(failure$code,"insufficient_async_cross_covariance_pairs")
  expect_identical(failure$details$candidate_cross_pairs,18L)
  expect_identical(failure$details$same_time_pairs_excluded,18L)
  expect_identical(failure$details$retained_cross_pairs,0L)
  expect_equal(failure$details$same_time_tolerance,2)
  expect_identical(sort(names(failure$details)),sort(c(
    "candidate_cross_pairs","same_time_pairs_excluded",
    "retained_cross_pairs","same_time_tolerance")))
  expect_error(.etr_spna_cross_pairs(tx,rx,ty[-1L],ry,0),
    "equal curve counts")
  expect_error(.etr_spna_cross_pairs(tx,rx,ty,ry,-.001),
    "same_time_tolerance")
})

test_that("raw asynchronous pair order, diagnostics and failures match Python 1.2",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 raw async covariance source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
from eyetrajectoriespy._sparse_multivariate_async import raw_async_planar_covariance_pairs
from eyetrajectoriespy._sparse_native import SparseNativeError
_tx=[np.array([.1,.2,.3]),np.array([.5,.7])]
_rx=[np.array([2.,3.,5.]),np.array([7.,11.])]
_ty=[np.array([.1,.25]),np.array([.6,.7,.8])]
_ry=[np.array([13.,17.]),np.array([19.,23.,29.])]
_pairs,_audit=raw_async_planar_covariance_pairs(
 _tx,_rx,_ty,_ry,same_time_tolerance=.051)
def _raw_async_failure():
 tx=[np.array([0.,1.,2.]),np.array([0.,1.,2.])]
 rx=[np.array([1.,2.,3.]),np.array([3.,2.,1.])]
 ty=tx
 ry=[np.array([2.,3.,4.]),np.array([4.,3.,2.])]
 try:
  raw_async_planar_covariance_pairs(
   tx,rx,ty,ry,same_time_tolerance=2.)
 except SparseNativeError as exc:
  return dict(code=exc.code,details=exc.details)
 raise AssertionError('Expected failure after excluding all xy pairs')
")
  a<-.etr_async_pair_source_fixture()
  native<-.etr_spna_cross_pairs(a$tx,a$rx,a$ty,a$ry,a$tolerance)
  for(block in c("xx","xy","yy"))for(field in
      c("s","t","products","curve_index")){
    expected<-et_to_r(reticulate::py_eval(
      paste0("_pairs.",block,".",field),convert=FALSE))
    ours<-native[[block]][[field]]
    expect_equal(ours,expected,tolerance=1e-15,
      ignore_attr=TRUE,info=paste(block,field))
  }
  for(field in names(native$audit)){
    source<-reticulate::py_to_r(reticulate::py_get_item(
      reticulate::py_eval("_audit",convert=FALSE),field))
    expect_equal(native$audit[[field]],source,tolerance=0,
      ignore_attr=TRUE,info=field)
  }
  tx<-list(c(0,1,2),c(0,1,2))
  ry<-list(2:4,4:2)
  native_error<-tryCatch(.etr_spna_cross_pairs(tx,
    list(1:3,3:1),tx,ry,2),error=identity)
  source_error<-reticulate::py_to_r(reticulate::py_call(
    reticulate::py_get_attr(reticulate::py,"_raw_async_failure")))
  expect_identical(native_error$code,source_error$code)
  for(field in names(source_error$details))
    expect_equal(native_error$details[[field]],
      source_error$details[[field]],tolerance=0,info=field)
})
