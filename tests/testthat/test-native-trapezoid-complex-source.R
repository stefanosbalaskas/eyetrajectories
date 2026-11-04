# Frozen eyetrajectoriespy==1.2.0 fpca.py::functional_trapezoid_weights.
# Bounded NumPy complex ndarray casting and Python bool(complex) witnesses.
# These are developer-side tests, NOT independent scientific certification.

test_that("native complex time-grid casting is opt-in and preserves real NumPy geometry",{
  grid<-complex(real=c(0,1,3),imaginary=c(7,-2,5))
  ordinary<-c(.5,1.5,1)
  expect_error(etr_trapezoid_weights(grid),"time must")
  expect_equal(etr_trapezoid_weights(grid,python_boundary_mode=TRUE),
    ordinary,tolerance=0)
  expect_equal(etr_trapezoid_weights(grid,normalize=TRUE,
    python_boundary_mode=TRUE),ordinary/3,tolerance=1e-14)
  # Complex lists are NOT a NumPy ndarray cast: np.asarray(list,dtype=float)
  # rejects Python complex scalars. Keep that representation excluded.
  expect_error(etr_trapezoid_weights(
    as.list(grid),python_boundary_mode=TRUE),"one-dimensional")
  expect_error(etr_trapezoid_weights(
    complex(real=c(1,0,3),imaginary=c(1,2,3)),
    python_boundary_mode=TRUE),"strictly increasing")
  expect_error(etr_trapezoid_weights(
    complex(real=c(0,NaN,3),imaginary=c(1,2,3)),
    python_boundary_mode=TRUE),"strictly increasing")
})

test_that("nonfinite Python complex truthiness matches signed zero, NaN and Inf",{
  t<-c(0,1,3)
  ordinary<-c(.5,1.5,1)
  positive<-list(
    complex(real=Inf,imaginary=0),
    complex(real=0,imaginary=Inf),
    complex(real=NaN,imaginary=0),
    complex(real=0,imaginary=NaN),
    complex(real=-Inf,imaginary=NaN))
  for(flag in positive) {
    expect_error(etr_trapezoid_weights(t,normalize=flag),
      "normalize")
    expect_equal(etr_trapezoid_weights(t,normalize=flag,
      python_boundary_mode=TRUE),ordinary/3,tolerance=1e-14)
  }
  expect_equal(etr_trapezoid_weights(t,
    normalize=complex(real=0,imaginary=-0),
    python_boundary_mode=TRUE),ordinary,tolerance=0)
  expect_error(etr_trapezoid_weights(t,normalize=NA_complex_,
    python_boundary_mode=TRUE),"normalize")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("pinned Python 1.2 complex ndarray and nonfinite flags match native",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 complex time/flag source oracles opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
import warnings
_ET_COMPLEX_SOURCE_GRID=np.array([0+7j,1-2j,3+5j],
  dtype=np.complex128)
def _ET_COMPLEX_SOURCE_CALL(source_fn, time, normalize):
    with warnings.catch_warnings():
        warnings.simplefilter('ignore')
        return source_fn(time,normalize=normalize)
")
  func<-reticulate::py_eval("_ET_COMPLEX_SOURCE_CALL",convert=FALSE)
  py_grid<-reticulate::py_eval("_ET_COMPLEX_SOURCE_GRID",convert=FALSE)
  r_grid<-complex(real=c(0,1,3),imaginary=c(7,-2,5))
  for(norm in c(FALSE,TRUE)) {
    py<-reticulate::py_call(func,
      source_fn=etpy_get_export("functional_trapezoid_weights"),
      time=py_grid,normalize=norm)
    native<-etr_trapezoid_weights(r_grid,normalize=norm,
      python_boundary_mode=TRUE)
    expect_equal(native,as.numeric(et_to_r(py)),tolerance=1e-14)
  }
  flags<-list(
    list(expr="complex(float('inf'),0)",val=complex(real=Inf,imaginary=0)),
    list(expr="complex(0,float('inf'))",val=complex(real=0,imaginary=Inf)),
    list(expr="complex(float('nan'),0)",val=complex(real=NaN,imaginary=0)),
    list(expr="complex(0,float('nan'))",val=complex(real=0,imaginary=NaN)),
    list(expr="complex(0,0)",val=0+0i))
  for(item in flags){
    py_flag<-reticulate::py_eval(item$expr,convert=FALSE)
    py<-reticulate::py_call(func,
      source_fn=etpy_get_export("functional_trapezoid_weights"),
      time=py_grid,normalize=py_flag)
    local<-etr_trapezoid_weights(r_grid,normalize=item$val,
      python_boundary_mode=TRUE)
    expect_equal(local,as.numeric(et_to_r(py)),tolerance=1e-14)
  }
  # The scientific parity ledger must not be reclassified by this
  # bounded developer source comparison.
  expect_identical(sum(etr_native_parity_catalog()$
    one_to_one_native_contract_complete),0L)
})
