# Frozen Python 1.2 source: compositional.py::alr_transform/inverse_alr
# and validation.py::validate_simplex, commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
# This suite exercises two related public numerical contracts.

.etr_alr_pair_simplex<-function(n,k,time=3L,seed=27L) {
  set.seed(seed)
  x<-array(stats::runif(n*time*k,min=.01,max=.95),c(n,time,k))
  for(i in seq_len(n))for(j in seq_len(time))
    x[i,j,]<-x[i,j,]/sum(x[i,j,])
  x
}

test_that("ALR and inverse have source algebra and normalization in every reference",{
  for(k in c(1L,2L,3L,5L,7L)){
    x<-if(k==1L)array(1,c(2L,3L,1L))
       else .etr_alr_pair_simplex(2L,k,3L,seed=18L+k)
    for(ref in c(-k,-1L,0L,k-1L,k+1L)){
      z<-etr_alr_transform(x,reference_dimension=as.integer(ref),
        epsilon=1e-12,python_boundary_mode=TRUE)
      expect_identical(dim(z),c(2L,3L,k-1L))
      back<-etr_inverse_alr(z,reference_dimension=as.integer(ref),
        n_dimensions=k,python_boundary_mode=TRUE)
      expect_identical(dim(back),c(2L,3L,k))
      expect_equal(back,x,tolerance=2e-13)
      expect_equal(as.vector(apply(back,c(1L,2L),sum)),
        rep(1,6L),tolerance=3e-14)
    }
  }
})

test_that("zeros clip to epsilon and inverse returns clipped composition",{
  x<-array(c(0,0,1,.2,.8,0,.4,.6,0),c(1L,3L,3L))
  for(eps in c(1e-8,1e-4,.01,.1)){
    for(ref in c(0L,1L,-1L)){
      z<-etr_alr_transform(x,ref,epsilon=eps,
        python_boundary_mode=TRUE)
      back<-etr_inverse_alr(z,ref,3L,python_boundary_mode=TRUE)
      expected<-pmax(x,eps)
      for(j in seq_len(3L))
        expected[1L,j,]<-expected[1L,j,]/sum(expected[1L,j,])
      expect_equal(back,expected,tolerance=5e-14)
    }
  }
})

test_that("shared float64 coercion preserves source shape and nonfinite casts",{
  x<-array(c(.3,.4,.3,.2,.3,.5),c(1L,2L,3L))
  ch<-array(as.character(x),dim=dim(x))
  expect_equal(etr_alr_transform(ch,0L,python_boundary_mode=TRUE),
    etr_alr_transform(x,0L,python_boundary_mode=TRUE),
    tolerance=0)
  flag<-array(c(TRUE,FALSE,FALSE,FALSE,TRUE,FALSE),c(1L,2L,3L))
  out<-etr_alr_transform(flag,0L,python_boundary_mode=TRUE)
  expect_identical(dim(out),c(1L,2L,2L))
  cx<-array(complex(real=as.vector(x),
    imaginary=rep(c(Inf,NaN,-Inf),length.out=length(x))),dim=dim(x))
  expect_equal(etr_alr_transform(cx,0L,python_boundary_mode=TRUE),
    etr_alr_transform(x,0L,python_boundary_mode=TRUE),tolerance=0)
  logits<-array(c("Inf","-Inf","NaN","-4",".3","2"),
    c(1L,3L,2L))
  local<-suppressWarnings(etr_inverse_alr(logits,0L,3L,
    python_boundary_mode=TRUE))
  reference<-suppressWarnings(etr_inverse_alr(
    array(as.numeric(logits),dim=dim(logits)),0L,3L,
    python_boundary_mode=TRUE))
  expect_identical(dim(local),dim(reference))
  expect_identical(is.nan(local),is.nan(reference))
  finite<-is.finite(reference)&is.finite(local)
  expect_equal(local[finite],reference[finite],tolerance=0)
})

test_that("empty axes and one-channel ALR retain frozen NumPy dimensionality",{
  for(d in list(c(0L,3L,3L),c(2L,0L,3L),c(0L,0L,3L),
      c(3L,0L,1L),c(0L,2L,1L))){
    x<-array(numeric(),d)
    z<-etr_alr_transform(x,0L,python_boundary_mode=TRUE)
    expect_identical(dim(z),c(d[1L],d[2L],d[3L]-1L))
    back<-etr_inverse_alr(z,0L,d[3L],python_boundary_mode=TRUE)
    expect_identical(dim(back),d)
  }
  ones<-array(1,c(2L,4L,1L))
  z<-etr_alr_transform(ones,0L,python_boundary_mode=TRUE)
  expect_identical(dim(z),c(2L,4L,0L))
  back<-etr_inverse_alr(z,0L,1L,python_boundary_mode=TRUE)
  expect_equal(back,ones,tolerance=0)
})

test_that("source input validation preserves scientific error classes",{
  expect_error(etr_alr_transform(array(c(0,-.2,1.2),c(1L,1L,3L)),
    0L,python_boundary_mode=TRUE),"non-negative")
  expect_error(etr_alr_transform(array(c(.1,.1,.1),c(1L,1L,3L)),
    0L,python_boundary_mode=TRUE),"sum to one")
  expect_error(etr_alr_transform(matrix(1,2,3),0L,
    python_boundary_mode=TRUE),"shape")
  expect_error(etr_alr_transform(array(c(.2,.3,.5),c(1L,1L,3L)),
    0L,epsilon=0,python_boundary_mode=TRUE),"epsilon")
  expect_error(etr_alr_transform(array(c(.2,.3,.5),c(1L,1L,3L)),
    0L,epsilon=-1,python_boundary_mode=TRUE),"epsilon")
  expect_error(etr_inverse_alr(array(0,c(2L,3L,2L)),0L,4L,
    python_boundary_mode=TRUE),"incompatible")
  expect_error(etr_inverse_alr(array(0,c(2L,3L,2L)),0L,3,
    python_boundary_mode=TRUE),"Python integer shape")
  expect_error(etr_alr_transform(array(c(.2,.3,.5),c(1L,1L,3L)),
    reference_dimension=0,python_boundary_mode=TRUE),
    "Python integer/Boolean")
})

test_that("both public transforms match direct frozen Python 1.2 across numerical domains",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Direct pinned Python 1.2 ALR pair oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import warnings
from eyetrajectoriespy.compositional import alr_transform, inverse_alr
def _alr_pair_source(values,ref,eps):
    with warnings.catch_warnings():
        warnings.simplefilter('ignore')
        with np.errstate(all='ignore'):
            z=alr_transform(values,reference_dimension=ref,epsilon=eps)
            back=inverse_alr(z,reference_dimension=ref,
                n_dimensions=values.shape[2])
    return z,back
def _inverse_source(values,ref,k):
    with np.errstate(all='ignore'):
        return inverse_alr(values,reference_dimension=ref,n_dimensions=k)
")
  np<-reticulate::import("numpy",convert=FALSE)
  pypair<-reticulate::py_get_attr(reticulate::py,"_alr_pair_source")
  pyinverse<-reticulate::py_get_attr(reticulate::py,"_inverse_source")
  for(k in c(1L,2L,3L,5L)){
    x<-if(k==1L)array(1,c(2L,3L,1L))
      else .etr_alr_pair_simplex(2L,k,3L,seed=k+29L)
    for(ref in c(-k,-1L,0L,k-1L,k+1L))
      for(eps in c(1e-8,.01)){
        source<-reticulate::py_call(pypair,np$array(
          reticulate::r_to_py(x),dtype="float64"),
          as.integer(ref),eps)
        native_z<-etr_alr_transform(x,as.integer(ref),
          eps,python_boundary_mode=TRUE)
        native_back<-etr_inverse_alr(native_z,as.integer(ref),
          k,python_boundary_mode=TRUE)
        expected_z<-et_to_r(reticulate::py_get_item(source,0L))
        expected_back<-et_to_r(reticulate::py_get_item(source,1L))
        expect_equal(native_z,expected_z,tolerance=1e-12,
          ignore_attr=TRUE,info=paste("ALR",k,ref,eps))
        expect_equal(native_back,expected_back,tolerance=1e-12,
          ignore_attr=TRUE,info=paste("inverse",k,ref,eps))
      }
  }
  for(shape in list(c(0L,3L,3L),c(2L,0L,3L),
      c(3L,0L,1L),c(0L,2L,1L))){
    array_np<-np$zeros(reticulate::tuple(shape[1L],shape[2L],
      shape[3L]),dtype="float64")
    src<-reticulate::py_call(pypair,array_np,as.integer(0L),1e-8)
    native<-etr_alr_transform(array(numeric(),shape),0L,
      python_boundary_mode=TRUE)
    pyshape<-as.integer(unlist(reticulate::py_to_r(
      reticulate::py_get_attr(reticulate::py_get_item(src,0L),"shape")),
      use.names=FALSE))
    expect_identical(dim(native),pyshape)
  }
  extreme<-array(c(800,-800,Inf,-Inf,NaN,0),c(1L,3L,2L))
  source<-reticulate::py_call(pyinverse,np$array(
    reticulate::r_to_py(extreme),dtype="float64"),0L,3L)
  native<-suppressWarnings(etr_inverse_alr(extreme,0L,3L,
    python_boundary_mode=TRUE))
  expected<-et_to_r(source)
  expect_identical(is.nan(native),is.nan(expected))
  expect_identical(is.infinite(native),is.infinite(expected))
  good<-is.finite(native)&is.finite(expected)
  expect_equal(native[good],expected[good],tolerance=1e-13)
})
