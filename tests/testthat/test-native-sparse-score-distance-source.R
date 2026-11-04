# Frozen eyetrajectoriespy==1.2.0 analysis.py:
# score_distance_matrix -> scikit-learn pairwise_distances(metric="euclidean").
# Developer numerical witnesses only, NOT independent 508 certification.

.etr_sparse_score_source_fixture <- function() {
  testthat::skip_if_not_installed("Matrix")
  # >2e6 input cells, only five nonzero values, and just 16 output cells.
  # The older R source-compatibility path rejected this valid sparse shape
  # because it forced dense input materialization.
  scores<-Matrix::sparseMatrix(
    i=c(1L,1L,2L,3L,4L),
    j=c(1L,5L,2L,3L,4L),
    x=c(1,5,2,3,4),
    dims=c(4L,600001L))
  list(scores=scores,n_components=as.integer(ncol(scores)))
}

test_that("wide SciPy-like sparse FPCA scores use sparse-native matrix geometry",{
  fit<-.etr_sparse_score_source_fixture()
  expect_true(inherits(fit$scores,"sparseMatrix"))
  expect_gt(as.double(nrow(fit$scores))*ncol(fit$scores),2e6)
  expect_error(etr_score_distance_matrix(fit),
    "compatible n_components")
  d<-etr_score_distance_matrix(fit,python_boundary_mode=TRUE)
  norms<-c(26,4,9,16)
  expected<-sqrt(outer(norms,norms,"+"))
  diag(expected)<-0
  expect_identical(dim(d),c(4L,4L))
  expect_equal(d,expected,tolerance=1e-12)
  expect_equal(d,t(d),tolerance=0)
  expect_equal(diag(d),rep(0,4),tolerance=0)
  expect_true(all(is.finite(d)))
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("sparse source mode agrees with complete dense Euclidean R distances",{
  testthat::skip_if_not_installed("Matrix")
  scores<-matrix(c(1,0,2,0,3,0,1,2,0,2,0,1,4,0,3,0,2,0),
    nrow=6L,ncol=3L,byrow=TRUE)
  fit<-list(scores=Matrix::Matrix(scores,sparse=TRUE),n_components=3L)
  for(k in c(1L,2L,3L)){
    actual<-etr_score_distance_matrix(fit,n_components=k,
      python_boundary_mode=TRUE)
    expected<-as.matrix(stats::dist(scores[,seq_len(k),drop=FALSE]))
    expect_equal(actual,unname(expected),tolerance=1e-12)
  }
  # Pattern and logical sparse score matrices are finite numeric sources.
  pattern<-Matrix::sparseMatrix(
    i=c(1L,2L,3L),j=c(1L,2L,1L),dims=c(3L,2L))
  source<-etr_score_distance_matrix(
    list(scores=pattern,n_components=2L),python_boundary_mode=TRUE)
  expected<-as.matrix(stats::dist(as.matrix(pattern)))
  expect_equal(source,unname(expected),tolerance=1e-12)
})

test_that("sparse FPCA source rejects nonfinite slots and excessive dense output",{
  z<-.etr_sparse_score_source_fixture()
  bad<-z
  bad$scores@x[1L]<-Inf
  expect_error(etr_score_distance_matrix(
    bad,python_boundary_mode=TRUE),
    "finite real numeric entries")
  no_rows<-list(scores=Matrix::sparseMatrix(
    i=integer(),j=integer(),dims=c(0L,3L)),n_components=3L)
  expect_error(etr_score_distance_matrix(
    no_rows,python_boundary_mode=TRUE),
    "positive matrix dimensions")
  too_many<-list(scores=Matrix::sparseMatrix(
    i=1L,j=1L,x=1,dims=c(2237L,2L)),n_components=2L)
  expect_error(etr_score_distance_matrix(
    too_many,python_boundary_mode=TRUE),
    "5e6-cell resource bound")
  expect_error(etr_score_distance_matrix(z,n_components=1,
    python_boundary_mode=TRUE),"Python integer/Boolean slice index")
  expect_error(etr_score_distance_matrix(z,n_components=NA_integer_,
    python_boundary_mode=TRUE),"Python integer/Boolean slice index")
})

test_that("pinned Python 1.2 scipy.sparse score distances agree for wide sparse input",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 sparse FPCA score oracle opt-in")
  testthat::skip_if_not_installed("Matrix")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
from scipy import sparse
from types import SimpleNamespace
_ET_SCORE_SPARSE_WIDE = sparse.csr_matrix(
  (np.array([1.,5.,2.,3.,4.]),
   (np.array([0,0,1,2,3]), np.array([0,4,1,2,3]))),
  shape=(4,600001))
_ET_SCORE_SPARSE_FPCA = SimpleNamespace(
  scores=_ET_SCORE_SPARSE_WIDE,n_components=600001)
")
  pfit<-reticulate::py_eval("_ET_SCORE_SPARSE_FPCA",
    convert=FALSE)
  z<-.etr_sparse_score_source_fixture()
  py<-reticulate::py_call(etpy_get_export("score_distance_matrix"),
    fpca=pfit)
  native<-etr_score_distance_matrix(z,python_boundary_mode=TRUE)
  expect_equal(unname(native),unname(et_to_r(py)),tolerance=1e-12)
  # Verify actual source slicing at one component on the same wide CSR.
  py1<-reticulate::py_call(etpy_get_export("score_distance_matrix"),
    fpca=pfit,n_components=as.integer(1L))
  native1<-etr_score_distance_matrix(z,n_components=1L,
    python_boundary_mode=TRUE)
  expect_equal(unname(native1),unname(et_to_r(py1)),
    tolerance=1e-12)
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
