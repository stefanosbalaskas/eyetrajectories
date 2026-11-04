# Pinned eyetrajectoriespy==1.2.0 analysis.py::functional_l2_distance.
# First-party bounded NumPy dtype=float and nonfinite arithmetic tests;
# not an independent full-domain certification or signed source review.

.etr_l2_complex_fixture<-function(){
  a<-matrix(complex(real=c(0,1,2,4,6,8),
    imaginary=c(7,-3,1,-2,9,5)),nrow=3L,byrow=TRUE)
  b<-matrix(0+0i,nrow=3L,ncol=2L)
  grid<-complex(real=c(0,1,3),imaginary=c(2,-7,4))
  list(a=a,b=b,time=grid,
    weights=complex(real=c(1,2),imaginary=c(-6,9)))
}

test_that("opt-in L2 source mode casts complex NumPy-like inputs to real",{
  z<-.etr_l2_complex_fixture()
  expect_error(etr_l2_distance(z$a,z$b,z$time,z$weights),
    "complete numeric")
  actual<-etr_l2_distance(z$a,z$b,z$time,z$weights,
    python_boundary_mode=TRUE)
  xx<-matrix(Re(z$a),nrow=3L,ncol=2L)
  yy<-matrix(Re(z$b),nrow=3L,ncol=2L)
  ww<-c(.5,1.5,1)
  expected<-sqrt(sum(rowSums(sweep((xx-yy)^2,2L,
    Re(z$weights),"*"))*ww))
  expect_equal(actual,expected,tolerance=1e-12)
  expect_true(is.finite(actual))
  expect_error(etr_l2_distance(z$a,z$b,z$time,z$weights,
    python_boundary_mode=NA),"python_boundary_mode")
})

test_that("opt-in source mode allows infinities and propagates NaN arithmetic",{
  a<-matrix(c(Inf,1,2,3,4,5),nrow=3L,byrow=TRUE)
  b<-matrix(0,nrow=3L,ncol=2L)
  expect_error(etr_l2_distance(a,b,c(0,1,3)),
    "complete numeric")
  expect_identical(etr_l2_distance(a,b,c(0,1,3),
    python_boundary_mode=TRUE),Inf)
  b[1L,1L]<-Inf
  expect_true(is.nan(etr_l2_distance(a,b,c(0,1,3),
    python_boundary_mode=TRUE)))
  a[1L,1L]<-NaN
  expect_error(etr_l2_distance(a,b,c(0,1,3),
    python_boundary_mode=TRUE),"without NaN")
  # Empty channels are legal NumPy 2D arrays; no dimension contributes
  # to the weighted integral, returning exactly zero.
  empty<-matrix(numeric(),nrow=3L,ncol=0L)
  expect_equal(etr_l2_distance(empty,empty,c(0,1,3),
    python_boundary_mode=TRUE),0,tolerance=0)
})

test_that("Python source-weight checks retain negative rejection and nonfinite results",{
  a<-matrix(c(1,2,3),nrow=3L,ncol=1L)
  b<-matrix(0,nrow=3L,ncol=1L)
  expect_error(etr_l2_distance(a,b,c(0,1,3),
    dimension_weights=Inf),"finite")
  expect_identical(etr_l2_distance(a,b,c(0,1,3),
    dimension_weights=Inf,python_boundary_mode=TRUE),Inf)
  expect_true(is.nan(etr_l2_distance(a,b,c(0,1,3),
    dimension_weights=NaN,python_boundary_mode=TRUE)))
  expect_error(etr_l2_distance(a,b,c(0,1,3),
    dimension_weights=-1,python_boundary_mode=TRUE),"non-negative")
  expect_error(etr_l2_distance(a,b,c(0,1,3),
    dimension_weights=NA_real_,python_boundary_mode=TRUE),
    "non-negative")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("frozen Python 1.2 complex and infinity source L2 calls agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 NumPy L2 source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import warnings
import eyetrajectoriespy as et
_ET_L2_A=np.array([[0+7j,1-3j],[2+1j,4-2j],[6+9j,8+5j]],
  dtype=np.complex128)
_ET_L2_B=np.zeros((3,2),dtype=np.complex128)
_ET_L2_TIME=np.array([0+2j,1-7j,3+4j],dtype=np.complex128)
_ET_L2_DW=np.array([1-6j,2+9j],dtype=np.complex128)
def _ET_L2_CALL(a,b,time,dw):
    with warnings.catch_warnings():
        warnings.simplefilter('ignore')
        with np.errstate(over='ignore',invalid='ignore',divide='ignore'):
            return et.functional_l2_distance(a,b,time=time,
                dimension_weights=dw)
")
  f<-reticulate::py_eval("_ET_L2_CALL",convert=FALSE)
  z<-.etr_l2_complex_fixture()
  py<-reticulate::py_call(f,
    a=reticulate::py_eval("_ET_L2_A",convert=FALSE),
    b=reticulate::py_eval("_ET_L2_B",convert=FALSE),
    time=reticulate::py_eval("_ET_L2_TIME",convert=FALSE),
    dw=reticulate::py_eval("_ET_L2_DW",convert=FALSE))
  native<-etr_l2_distance(z$a,z$b,z$time,z$weights,
    python_boundary_mode=TRUE)
  expect_equal(native,as.numeric(et_to_r(py)),tolerance=1e-12)
  npa<-reticulate::py_eval("np.array([[np.inf,1],[2,3],[4,5]],dtype=float)",
    convert=FALSE)
  npb<-reticulate::py_eval("np.zeros((3,2),dtype=float)",convert=FALSE)
  tm<-reticulate::r_to_py(c(0,1,3))
  py_inf<-reticulate::py_call(f,a=npa,b=npb,time=tm,
    dw=reticulate::r_to_py(c(1,2)))
  expect_identical(as.numeric(et_to_r(py_inf)),Inf)
  a_inf<-matrix(c(Inf,1,2,3,4,5),nrow=3L,byrow=TRUE)
  b0<-matrix(0,nrow=3L,ncol=2L)
  expect_identical(etr_l2_distance(a_inf,b0,c(0,1,3),c(1,2),
    python_boundary_mode=TRUE),Inf)
  py_nan<-reticulate::py_call(f,a=npa,b=npa,time=tm,
    dw=reticulate::r_to_py(c(1,2)))
  expect_true(is.nan(as.numeric(et_to_r(py_nan))))
  expect_true(is.nan(etr_l2_distance(a_inf,a_inf,c(0,1,3),c(1,2),
    python_boundary_mode=TRUE)))
  py_weight_nan<-reticulate::py_call(f,a=npb,b=npb,time=tm,
    dw=reticulate::r_to_py(c(NaN,1)))
  expect_true(is.nan(as.numeric(et_to_r(py_weight_nan))))
  expect_true(is.nan(etr_l2_distance(b0,b0,c(0,1,3),c(NaN,1),
    python_boundary_mode=TRUE)))
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
