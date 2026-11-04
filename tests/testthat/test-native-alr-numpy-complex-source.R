# Frozen eyetrajectoriespy==1.2.0, compositional.py::alr_transform()
# and inverse_alr(); exact source commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Developer-side bounded NumPy coercion and overflow tests, NOT independent
# full-domain certification.

.etr_complex_alr_simplex_fixture<-function(){
  x<-array(complex(real=0,imaginary=0),c(2L,3L,3L))
  for(i in seq_len(2L))for(t in seq_len(3L)){
    re<-c(.2+.02*i,.3+.01*t,.5-.02*i-.01*t)
    x[i,t,]<-complex(real=re,imaginary=c(4,-8,12))
  }
  x
}

test_that("complex NumPy ndarray to float is opt-in for ALR forward",{
  x<-.etr_complex_alr_simplex_fixture()
  expect_error(etr_alr_transform(x))
  expected<-etr_alr_transform(Re(x),0L)
  actual<-etr_alr_transform(x,0L,python_boundary_mode=TRUE)
  expect_equal(actual,expected,tolerance=0)
  expect_identical(dim(actual),c(2L,3L,2L))
  expect_true(all(is.finite(actual)))
  expect_equal(etr_alr_transform(x,reference_dimension=TRUE,
    python_boundary_mode=TRUE),
    etr_alr_transform(Re(x),reference_dimension=1L),
    tolerance=0)
  # Finite imaginary components do not affect the source real-cast.
  y<-x; Im(y)<-rep(c(Inf,-Inf,NaN),length.out=length(y))
  expect_equal(etr_alr_transform(y,0L,python_boundary_mode=TRUE),
    expected,tolerance=0)
})

test_that("inverse ALR complex ndarray and NumPy shape semantics are opt-in",{
  z<-array(complex(real=c(-3,2,1,-2,4,0),
    imaginary=c(9,-8,7,6,-5,4)),dim=c(1L,3L,2L))
  expect_error(etr_inverse_alr(z,0L,3L),
    "incompatible dimensions")
  expected<-etr_inverse_alr(Re(z),0L,3L)
  actual<-etr_inverse_alr(z,0L,3L,python_boundary_mode=TRUE)
  expect_equal(actual,expected,tolerance=0)
  expect_identical(dim(actual),c(1L,3L,3L))
  expect_equal(as.numeric(apply(actual,c(1L,2L),sum)),
    rep(1,3),tolerance=1e-14)
  expect_equal(etr_inverse_alr(z,TRUE,3L,
    python_boundary_mode=TRUE),
    etr_inverse_alr(Re(z),1L,3L),tolerance=0)
  expect_error(etr_inverse_alr(z,0L,3,
    python_boundary_mode=TRUE),"Python integer shape")
  expect_error(etr_inverse_alr(z,0L,TRUE,
    python_boundary_mode=TRUE),"Python integer shape")
  expect_error(etr_inverse_alr(z,0L,3.5,
    python_boundary_mode=TRUE),"Python integer shape")
  # Default R retains legacy integral-double shape acceptance.
  expect_equal(etr_inverse_alr(Re(z),0L,3),expected,tolerance=0)
})

test_that("one-channel inverse remains well defined for zero-column ALR",{
  z<-array(numeric(),c(2L,3L,0L))
  actual<-etr_inverse_alr(z,reference_dimension=0L,
    n_dimensions=1L,python_boundary_mode=TRUE)
  expect_identical(dim(actual),c(2L,3L,1L))
  expect_equal(actual,array(1,c(2L,3L,1L)),tolerance=0)
})

test_that("complex ALR source mode preserves overflow/NaN from NumPy exp",{
  z<-array(complex(real=c(1000,-1000,NaN,Inf),
    imaginary=c(2,-2,0,0)),c(2L,1L,2L))
  expect_error(etr_inverse_alr(z,0L,3L),"incompatible dimensions")
  actual<-suppressWarnings(etr_inverse_alr(z,0L,3L,
    python_boundary_mode=TRUE))
  direct<-suppressWarnings(etr_inverse_alr(Re(z),0L,3L,
    python_boundary_mode=TRUE))
  expect_identical(is.nan(actual),is.nan(direct))
  expect_equal(actual,direct,tolerance=0)
  expect_true(any(is.nan(actual)))
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("pinned Python 1.2 ALR source exports agree on complex arrays and shapes",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 complex ALR source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import warnings
def _ET_COMPLEX_ALR_ORACLE(fn, x, ref, ndim=None):
    with warnings.catch_warnings():
        warnings.simplefilter('ignore')
        with np.errstate(all='ignore'):
            if ndim is None:
                return fn(x, reference_dimension=ref)
            return fn(x, reference_dimension=ref, n_dimensions=ndim)
")
  oracle<-reticulate::py_eval("_ET_COMPLEX_ALR_ORACLE",convert=FALSE)
  x<-.etr_complex_alr_simplex_fixture()
  for(ref in c(0L,1L,2L,-1L)){
    py<-reticulate::py_call(oracle,
      fn=etpy_get_export("alr_transform"),
      x=reticulate::r_to_py(x),ref=ref)
    local<-etr_alr_transform(x,reference_dimension=ref,
      python_boundary_mode=TRUE)
    expect_equal(unname(local),unname(et_to_r(py)),tolerance=1e-13)
  }
  py_bool<-reticulate::py_call(oracle,
    fn=etpy_get_export("alr_transform"),
    x=reticulate::r_to_py(x),ref=TRUE)
  expect_equal(unname(etr_alr_transform(x,TRUE,
    python_boundary_mode=TRUE)),unname(et_to_r(py_bool)),tolerance=1e-13)
  z<-array(complex(real=c(-3,2,1,-2,4,0),
    imaginary=c(9,-8,7,6,-5,4)),c(1L,3L,2L))
  for(ref in c(0L,1L,2L,-1L)){
    py<-reticulate::py_call(oracle,
      fn=etpy_get_export("inverse_alr"),
      x=reticulate::r_to_py(z),ref=ref,ndim=3L)
    local<-etr_inverse_alr(z,ref,3L,
      python_boundary_mode=TRUE)
    expect_equal(unname(local),unname(et_to_r(py)),tolerance=1e-13)
  }
  nan_z<-array(complex(real=c(1000,-1000,NaN,Inf),
    imaginary=c(2,-2,0,0)),c(2L,1L,2L))
  py_extreme<-reticulate::py_call(oracle,
    fn=etpy_get_export("inverse_alr"),
    x=reticulate::r_to_py(nan_z),ref=0L,ndim=3L)
  local_extreme<-suppressWarnings(etr_inverse_alr(nan_z,0L,3L,
    python_boundary_mode=TRUE))
  expect_identical(is.nan(local_extreme),is.nan(et_to_r(py_extreme)))
  expect_equal(unname(local_extreme),unname(et_to_r(py_extreme)),
    tolerance=0)
  z0<-array(numeric(),c(2L,3L,0L))
  py_single<-reticulate::py_call(oracle,
    fn=etpy_get_export("inverse_alr"),
    x=reticulate::r_to_py(z0),ref=0L,ndim=1L)
  expect_equal(etr_inverse_alr(z0,0L,1L,
    python_boundary_mode=TRUE),et_to_r(py_single),tolerance=0)
  expect_error(reticulate::py_call(oracle,
    fn=etpy_get_export("inverse_alr"),
    x=reticulate::r_to_py(z),ref=0L,ndim=3.0))
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
