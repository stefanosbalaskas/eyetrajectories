# Full developer source-equivalence review for eyetrajectoriespy==1.2.0
# fpca.py::functional_trapezoid_weights, frozen c1cd95ad718327550f7e55393ff38582872f7a94.
# Numeric 1-D grid and Python-compatible truthiness; no Python call inside R.

test_that("one-dimensional native ndarray shapes and NumPy scalar sequences agree",{
  grids<-list(
    c(0,1,3),
    array(c(0,1,3),dim=3L),
    array(c(0L,1L,3L),dim=3L),
    array(c("0","1","3"),dim=3L),
    list(0L,TRUE,"3"),
    array(c(0+2i,1-1i,3+0i),dim=3L))
  expected<-c(.5,1.5,1)
  for(grid in grids){
    out<-etr_trapezoid_weights(grid,python_boundary_mode=TRUE)
    expect_equal(as.numeric(out),expected,tolerance=0,
      info=paste(class(grid),typeof(grid),length(dim(grid))))
    expect_identical(dim(out),NULL)
    expect_equal(etr_trapezoid_weights(grid,normalize=TRUE,
      python_boundary_mode=TRUE),expected/3,tolerance=1e-14)
  }
  expect_equal(etr_trapezoid_weights(array(c(1,5),dim=2L),
    python_boundary_mode=TRUE),c(2,2),tolerance=0)
  expect_equal(etr_trapezoid_weights(array(c(FALSE,TRUE),dim=2L),
    python_boundary_mode=TRUE),c(.5,.5),tolerance=0)
  expect_error(etr_trapezoid_weights(matrix(c(0,1,3),ncol=1),
    python_boundary_mode=TRUE),"one-dimensional")
  expect_error(etr_trapezoid_weights(array(c(0,1,3),
    dim=c(1L,1L,3L)),python_boundary_mode=TRUE),"one-dimensional")
})

test_that("source validation rejects non-increasing grids after NumPy float casting",{
  invalid<-list(numeric(),1,0,TRUE,NA_real_,NaN,
    c(0,0),c(0,-1),c(1,NaN,3),c(0,NA_real_,3),
    c(Inf,Inf),c(0,Inf,Inf),c(-Inf,-Inf),
    array(1:4,dim=c(2L,2L)),
    list(1,2,c(3,4)),list(0,NA_character_,1),
    array(c(FALSE,FALSE),dim=2L))
  for(x in invalid)
    expect_error(etr_trapezoid_weights(x,
      python_boundary_mode=TRUE))
  # Python np.diff checks only positive differences; infinite endpoints
  # can be accepted, and a grid spanning signed extremes overflows.
  nonfinite<-list(c(-Inf,0),c(0,Inf),c(-Inf,Inf),
    c(-Inf,0,Inf),c(-1e308,1e308))
  for(x in nonfinite){
    y<-etr_trapezoid_weights(x,python_boundary_mode=TRUE)
    expect_identical(length(y),length(x))
    expect_true(any(is.infinite(y)))
  }
  expect_error(etr_trapezoid_weights(c(0,Inf),
    python_boundary_mode=FALSE),"finite")
})

test_that("source normalization accepts scalar, list and ndarray truthiness",{
  t<-c(0,1,3);v<-c(.5,1.5,1)
  yes<-list(TRUE,1,-1,2.5,Inf,-Inf,NaN,"0","False",
    list(0),list(FALSE),array(1,dim=1L),
    array(TRUE,dim=c(1L,1L)),complex(real=0,imaginary=1))
  no<-list(FALSE,0,-0,0L,"",list(),NULL,
    array(0,dim=1L),array(FALSE,dim=c(1L,1L)),
    complex(real=0,imaginary=0))
  for(value in yes)
    expect_equal(etr_trapezoid_weights(t,normalize=value,
      python_boundary_mode=TRUE),v/3,tolerance=0)
  for(value in no)
    expect_equal(etr_trapezoid_weights(t,normalize=value,
      python_boundary_mode=TRUE),v,tolerance=0)
  expect_error(etr_trapezoid_weights(t,normalize=c(TRUE,FALSE),
    python_boundary_mode=TRUE),"normalize")
  expect_error(etr_trapezoid_weights(t,normalize=array(c(1,2),
    dim=c(2L,1L)),python_boundary_mode=TRUE),"ambiguous")
  expect_error(etr_trapezoid_weights(t,normalize=NA_real_,
    python_boundary_mode=TRUE),"normalize")
})

test_that("seeded finite quadrature and normalization satisfy direct source algebra",{
  set.seed(21978)
  for(n in c(2L,3L,4L,7L,17L,64L))
    for(iter in seq_len(30L)){
      gap<-stats::runif(n-1L,1e-8,2)
      t<-c(0,cumsum(gap))
      w<-etr_trapezoid_weights(array(t,dim=length(t)),
        python_boundary_mode=TRUE)
      expected<-numeric(n)
      expected[1L]<-gap[1L]/2
      expected[n]<-gap[n-1L]/2
      if(n>2L)expected[2L:(n-1L)]<-
        (gap[1L:(n-2L)]+gap[2L:(n-1L)])/2
      expect_equal(w,expected,tolerance=2e-14)
      expect_equal(sum(w),t[n]-t[1L],tolerance=2e-14)
      normalized<-etr_trapezoid_weights(t,TRUE,TRUE)
      expect_equal(sum(normalized),1,tolerance=2e-14)
    }
})

test_that("direct pinned Python covers numerical, container, warning and error domains",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 direct source comparison is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import warnings
from eyetrajectoriespy.fpca import functional_trapezoid_weights as _trapezoid
def _trapezoid_source(time, flag):
    try:
        with warnings.catch_warnings(record=True) as out:
            warnings.simplefilter('always')
            weights=_trapezoid(time,normalize=flag)
        return {'ok':True,'weights':weights,
                'warnings':tuple(type(q.message).__name__ for q in out)}
    except Exception as e:
        return {'ok':False,'exception':type(e).__name__,
                'message':str(e)}
")
  func<-reticulate::py_get_attr(reticulate::py,"_trapezoid_source")
  checks<-list(
    list(t=c(0,1,3),pt=reticulate::r_to_py(c(0,1,3)),
      flag=FALSE,pflag=FALSE,ok=TRUE),
    list(t=array(c(0,1,3),dim=3L),
      pt=reticulate::py_eval("np.array([0.,1.,3.])",convert=FALSE),
      flag=TRUE,pflag=TRUE,ok=TRUE),
    list(t=array(c(0L,1L,3L),dim=3L),
      pt=reticulate::py_eval("np.array([0,1,3],dtype=int)",convert=FALSE),
      flag=array(1L,dim=1L),
      pflag=reticulate::py_eval("np.array([1])",convert=FALSE),ok=TRUE),
    list(t=array(c("0","1","3"),dim=3L),
      pt=reticulate::py_eval("np.array(['0','1','3'])",convert=FALSE),
      flag="False",pflag="False",ok=TRUE),
    list(t=list(0L,TRUE,"3"),
      pt=reticulate::py_eval("[0,True,'3']",convert=FALSE),
      flag=list(0),pflag=reticulate::py_eval("[0]",convert=FALSE),
      ok=TRUE),
    list(t=c(-Inf,0,Inf),pt=reticulate::py_eval(
      "np.array([-np.inf,0,np.inf])",convert=FALSE),
      flag=TRUE,pflag=TRUE,ok=TRUE),
    list(t=array(c(0+1i,1+2i,3-4i),dim=3L),
      pt=reticulate::py_eval(
        "np.array([0+1j,1+2j,3-4j])",convert=FALSE),
      flag=TRUE,pflag=TRUE,ok=TRUE),
    list(t=array(c(0,1,1),dim=3L),
      pt=reticulate::py_eval("np.array([0.,1.,1.])",convert=FALSE),
      flag=FALSE,pflag=FALSE,ok=FALSE),
    list(t=matrix(c(0,1,3),3,1),
      pt=reticulate::py_eval("np.array([[0.],[1.],[3.]])",convert=FALSE),
      flag=FALSE,pflag=FALSE,ok=FALSE),
    list(t=c(0,1,3),pt=reticulate::py_eval(
      "np.array([0.,1.,3.])",convert=FALSE),
      flag=array(c(1,2),dim=2L),
      pflag=reticulate::py_eval("np.array([1,2])",convert=FALSE),
      ok=FALSE)
  )
  for(i in seq_along(checks)){
    q<-checks[[i]]
    expected<-reticulate::py_to_r(reticulate::py_call(func,
      time=q$pt,flag=q$pflag))
    native<-tryCatch(etr_trapezoid_weights(q$t,
      normalize=q$flag,python_boundary_mode=TRUE),
      error=identity)
    expect_identical(expected$ok,q$ok,info=paste("source case",i))
    if(q$ok){
      expect_false(inherits(native,"error"),info=paste("case",i))
      expect_equal(native,as.numeric(expected$weights),
        tolerance=1e-14,info=paste("source numeric case",i))
      expect_identical(is.null(dim(native)),TRUE)
    }else{
      expect_true(inherits(native,"error"),
        info=paste("source rejects case",i))
      expect_identical(expected$exception,"ValueError",
        info=paste("Python error kind case",i))
    }
  }
  for(n in c(2L,3L,8L,32L,65L)){
    x<-c(0,cumsum((seq_len(n-1L)+1)^1.25/n))
    for(normalize in c(FALSE,TRUE)){
      expected<-reticulate::py_call(func,time=reticulate::r_to_py(x),
        flag=normalize)
      native<-etr_trapezoid_weights(array(x,dim=n),normalize=normalize,
        python_boundary_mode=TRUE)
      expect_equal(native,as.numeric(et_to_r(
        reticulate::py_get_item(expected,"weights"))),
        tolerance=2e-13,info=paste(n,normalize))
    }
  }
})
