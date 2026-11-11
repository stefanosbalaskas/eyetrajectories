# Frozen Python 1.2 analysis.py::score_distance_matrix
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Native source-compatibility mode computes sklearn's retained FPCA score
# Euclidean matrix. Default R stable pairwise stats::dist is separately kept.
.etr_score_full_source_fixture<-function() {
  z<-rbind(c(0,.5,-1,2),c(1,.5,-1,2),
    c(1,.5,-1,2),c(-2,0,1,.25),
    c(.5,2,.75,-.5))
  list(scores=z,n_components=as.integer(ncol(z)))
}

test_that("full dense Euclidean source geometry matches complete and sliced scores",{
  z<-.etr_score_full_source_fixture()
  for(k in 1:4) {
    got<-etr_score_distance_matrix(z,n_components=as.integer(k),
      python_boundary_mode=TRUE)
    expect_identical(dim(got),c(5L,5L))
    expect_identical(dimnames(got),NULL)
    expect_equal(diag(got),rep(0,5L),tolerance=0)
    expect_equal(got,t(got),tolerance=0)
    expect_equal(got[2L,3L],0,tolerance=0)
    expect_equal(got,
      unname(as.matrix(stats::dist(z$scores[,seq_len(k),drop=FALSE]))),
      tolerance=1e-12)
  }
  all<-etr_score_distance_matrix(z,python_boundary_mode=TRUE)
  expect_equal(all,etr_score_distance_matrix(z,n_components=4L,
    python_boundary_mode=TRUE),tolerance=0)
  # The frozen source slices actual columns even if metadata overstates k.
  over<-z;over$n_components<-11L
  expect_equal(etr_score_distance_matrix(over,python_boundary_mode=TRUE),
    all,tolerance=0)
  expect_equal(etr_score_distance_matrix(over,n_components=7L,
    python_boundary_mode=TRUE),all,tolerance=0)
})

test_that("source sparse and Boolean score geometries retain exact node distances",{
  skip_if_not_installed("Matrix")
  z<-.etr_score_full_source_fixture()
  for(input in list(Matrix::Matrix(z$scores,sparse=TRUE),
      Matrix::Matrix(z$scores!=0,sparse=TRUE))) {
    x<-list(scores=input,n_components=as.integer(ncol(input)))
    d<-etr_score_distance_matrix(x,python_boundary_mode=TRUE)
    expected<-unname(as.matrix(stats::dist(as.matrix(input))))
    expect_equal(d,expected,tolerance=1e-12)
    expect_true(all(is.finite(d)))
    expect_identical(diag(d),rep(0,5L))
  }
})

test_that("source distance fails on out-of-domain slice and invalid numeric scores",{
  z<-.etr_score_full_source_fixture()
  expect_error(etr_score_distance_matrix(z,n_components=1.0,
    python_boundary_mode=TRUE),"Python integer/Boolean slice index")
  expect_error(etr_score_distance_matrix(z,n_components=-1L,
    python_boundary_mode=TRUE),"outside the fitted range")
  expect_error(etr_score_distance_matrix(z,n_components=5L,
    python_boundary_mode=TRUE),"outside the fitted range")
  bad<-z;bad$scores[2L,3L]<-Inf
  expect_error(etr_score_distance_matrix(bad,
    python_boundary_mode=TRUE),"finite")
  bad<-z;bad$scores<-bad$scores[,FALSE,drop=FALSE]
  expect_error(etr_score_distance_matrix(bad,
    python_boundary_mode=TRUE),"fpca must provide")
})

test_that("pinned Python 1.2 score distances directly match dense and SciPy CSR",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 score-distance oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
from types import SimpleNamespace
from scipy import sparse
import eyetrajectoriespy as et
_x=np.array([[0.,.5,-1.,2.],[1.,.5,-1.,2.],
             [1.,.5,-1.,2.],[-2.,0.,1.,.25],
             [.5,2.,.75,-.5]])
_score_oracles={}
for _kind,_values in [('dense',_x),
                      ('csr',sparse.csr_matrix(_x))]:
    for _k in (1,2,3,4,7):
        _fit=SimpleNamespace(scores=_values,n_components=11)
        _score_oracles[(_kind,_k)]=et.score_distance_matrix(
            _fit,n_components=_k)
")
  z<-.etr_score_full_source_fixture()
  for(kind in c("dense","csr")){
    z$scores<-if(kind=="dense")z$scores
      else {
        skip_if_not_installed("Matrix")
        Matrix::Matrix(.etr_score_full_source_fixture()$scores,sparse=TRUE)
      }
    z$n_components<-11L
    for(k in c(1L,2L,3L,4L,7L)){
      actual<-etr_score_distance_matrix(z,n_components=k,
        python_boundary_mode=TRUE)
      py<-reticulate::py_eval(paste0("_score_oracles[('",
        kind,"',",k,")]"),convert=FALSE)
      expect_equal(actual,et_to_r(py),
        tolerance=2e-12,ignore_attr=TRUE,
        info=paste("full frozen score source",kind,k))
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
