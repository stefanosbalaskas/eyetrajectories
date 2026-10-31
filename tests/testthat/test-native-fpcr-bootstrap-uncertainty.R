# Published eyetrajectoriespy 1.2 regression_inference.py, Gaussian FPCR.
.etr_fpcr_uncertainty_fixture<-function(){
  n<-14L;t<-seq(0,1,length.out=15L)
  values<-array(0,c(n,length(t),1L))
  for(i in seq_len(n))
    values[i,,1L]<-sin(pi*t)*(1+i/16)+
      .16*cos(2*pi*t)*(i%%4)/3+t*i/18
  x<-etr_trajectory_set(t,values,sprintf("c%02d",seq_len(n)),
    "gaze",metadata=data.frame(subject=rep(sprintf("p%02d",1:7),each=2)),
    coordinate_system="normalized",time_unit="s")
  list(x=x,y=.2+1.2*seq_len(n)/n+.2*sin(seq_len(n)))
}
test_that("paired full-refit Gaussian FPCR quantiles and provenance are coherent",{
  z<-.etr_fpcr_uncertainty_fixture()
  set.seed(602L);before<-.Random.seed
  a<-etr_bootstrap_fpca_regression_uncertainty(
    z$x,z$y,n_bootstrap=20L,n_components=1L,random_state=123L)
  expect_identical(before,.Random.seed)
  expect_s3_class(a,"etr_fpcr_bootstrap_uncertainty")
  expect_identical(dim(a$bootstrap_slopes),c(20L,15L,1L))
  expect_identical(dim(a$bootstrap_mean_predictions),c(20L,14L))
  expect_identical(dim(a$reference_slope),c(15L,1L))
  expect_equal(a$reference_mean_predictions,
    as.numeric(stats::fitted(a$reference_regression$native_model$model)),
    tolerance=1e-10)
  expect_equal(a$slope_lower[,1L],
    as.numeric(apply(a$bootstrap_slopes[,,1L],2,
      quantile,probs=.025,names=FALSE,type=7L)),
    tolerance=1e-10)
  expect_equal(a$prediction_se,
    apply(a$bootstrap_mean_predictions,2L,stats::sd),
    tolerance=1e-12)
  expect_true(all(a$slope_lower<=a$slope_median))
  expect_true(all(a$slope_median<=a$slope_upper))
  expect_true(all(a$prediction_lower<=a$prediction_upper))
  expect_false(a$provenance$fpca_regression_uncertainty$
    future_outcome_prediction_interval)
  expect_false(a$provenance$fpca_regression_uncertainty$
    source_schema_equivalent)
  expected<-etr_fpca_regression_future_prediction_interval(
    a,z$y,residual_indices=matrix(
      rep(0:13,length.out=20L*14L),nrow=20L))
  expect_identical(dim(expected$predictive_draws),c(20L,14L))
  again<-etr_bootstrap_fpca_regression_uncertainty(
    z$x,z$y,n_bootstrap=20L,n_components=1L,random_state=123L)
  expect_identical(a$bootstrap_mean_predictions,
    again$bootstrap_mean_predictions)
})

test_that("fixed zero-based source curves replay deterministically",{
  z<-.etr_fpcr_uncertainty_fixture()
  indexes<-replicate(20L,as.integer(c(0:13)),simplify=FALSE)
  r<-etr_bootstrap_fpca_regression_uncertainty(z$x,z$y,
    n_bootstrap=20L,n_components=1L,
    bootstrap_indices=indexes,random_state=91L)
  expect_equal(matrix(r$bootstrap_slopes[1,,,drop=FALSE],
    nrow=length(z$x$time),ncol=length(z$x$dimension_names)),
    r$reference_slope,tolerance=1e-8)
  expect_true(all(r$sampled_source_curve_indices[[1L]]==0:13))
  expect_identical(r$provenance$fpca_regression_uncertainty$
    random_engine,"externally_fixed_source_curve_indices")
})

test_that("FPCR paired bootstrap rejects unsupported scientific domains",{
  z<-.etr_fpcr_uncertainty_fixture()
  f<-etr_bootstrap_fpca_regression_uncertainty
  expect_error(f(z$x,z$y,n_bootstrap=19L),"n_bootstrap")
  expect_error(f(z$x,z$y,n_components=0L),"n_components")
  expect_error(f(z$x,z$y,n_components=1.5),"n_components")
  expect_error(f(z$x,z$y[-1L]),"outcome")
  expect_error(f(z$x,z$y,level=1),"level")
  expect_error(f(z$x,z$y,resample_unit="participant"),
    "participant_column")
  expect_error(f(z$x,z$y,resample_unit="curve",
    participant_column="subject"),"participant_column")
  expect_error(f(z$x,z$y,bootstrap_indices=list(0:13),
    n_bootstrap=20L),"bootstrap_indices")
  bad<-z$x;bad$time[2L]<-.07
  expect_error(f(z$x,z$y,targets=bad),"targets")
})

test_that("published Python 1.2 Gaussian FPCR agrees on the full-sample estimand",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 paired Gaussian FPCR reference oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_fpcr_uncertainty_fixture()
  native<-etr_bootstrap_fpca_regression_uncertainty(z$x,z$y,
    n_bootstrap=20L,n_components=1L,random_state=7L)
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as et
n=14
time=np.linspace(0.0,1.0,15)
x=np.empty((n,time.size,1))
for ind in range(1,n+1):
 x[ind-1,:,0]=(np.sin(np.pi*time)*(1+ind/16)
                +.16*np.cos(2*np.pi*time)*(ind%4)/3
                +time*ind/18)
y=.2+1.2*np.arange(1,n+1)/n+.2*np.sin(np.arange(1,n+1))
tr=et.TrajectorySet(time=time,values=x,
    curve_ids=tuple(f'c{ind:02d}' for ind in range(1,n+1)),
    dimension_names=('gaze',),
    metadata=pd.DataFrame({'subject':np.repeat(
        [f'p{j:02d}' for j in range(1,8)],2)}),
    coordinate_system='normalized',time_unit='s')
original=et.bootstrap_fpca_regression_uncertainty(
    tr,y,n_bootstrap=20,n_components=1,random_state=7)
_fpcr_published_reference={
    'slope':original.reference_slope,
    'mean':original.reference_mean_predictions,
    'fitted':original.reference_regression.predictions,
    'shape':original.bootstrap_slopes.shape
}
")
  oracle<-reticulate::py_to_r(reticulate::py_eval(
    "_fpcr_published_reference",convert=FALSE))
  expect_equal(unname(native$reference_slope),unname(oracle$slope),
    tolerance=1e-6)
  expect_equal(as.numeric(native$reference_mean_predictions),
    as.numeric(oracle$mean),tolerance=1e-6)
  expect_equal(as.numeric(native$reference_regression$predictions),
    as.numeric(oracle$fitted),tolerance=1e-6)
  expect_identical(as.integer(dim(native$bootstrap_slopes)),
    as.integer(oracle$shape))
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})


test_that("pinned Python 1.2 full paired-bootstrap refits match fixed source indices",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 20-replicate fixed-draw FPCR source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_fpcr_uncertainty_fixture()
  indices<-replicate(20L,as.integer(0:13),simplify=FALSE)
  native<-etr_bootstrap_fpca_regression_uncertainty(z$x,z$y,
    n_bootstrap=20L,n_components=1L,random_state=7L,
    bootstrap_indices=indices)
  reticulate::py_run_string("
import numpy as np
import pandas as pd
from unittest.mock import patch
import eyetrajectoriespy as et
import eyetrajectoriespy.regression_inference as ri
time=np.linspace(0.0,1.0,15)
n=14
values=np.empty((n,15,1))
for j in range(1,15):
 values[j-1,:,0]=(np.sin(np.pi*time)*(1+j/16)
     +.16*np.cos(2*np.pi*time)*(j%4)/3+time*j/18)
y=.2+1.2*np.arange(1,15)/14+.2*np.sin(np.arange(1,15))
x=et.TrajectorySet(time=time,values=values,
 curve_ids=tuple(f'c{j:02d}' for j in range(1,15)),
 dimension_names=('gaze',),
 metadata=pd.DataFrame({'subject':np.repeat(
     [f'p{j:02d}' for j in range(1,8)],2)}),
 coordinate_system='normalized',time_unit='s')
class _FixedBootstrapRNG:
 def integers(self,low,high=None,size=None):
  assert low==0 and high==14 and size==14
  return np.arange(14,dtype=int)
with patch.object(ri.np.random,'default_rng',
                  return_value=_FixedBootstrapRNG()):
 exact=ri.bootstrap_fpca_regression_uncertainty(
     x,y,n_bootstrap=20,n_components=1,random_state=7)
_python_fpcr_fixed={
 'bootstrap_slopes':exact.bootstrap_slopes,
 'bootstrap_mean_predictions':exact.bootstrap_mean_predictions,
 'slope_lower':exact.slope_lower,
 'slope_upper':exact.slope_upper,
 'prediction_lower':exact.prediction_lower,
 'prediction_upper':exact.prediction_upper
}
")
  source<-reticulate::py_to_r(reticulate::py_eval(
    "_python_fpcr_fixed",convert=FALSE))
  expect_equal(unname(native$bootstrap_slopes),
    unname(source$bootstrap_slopes),tolerance=1e-6)
  expect_equal(unname(native$bootstrap_mean_predictions),
    unname(source$bootstrap_mean_predictions),tolerance=1e-6)
  expect_equal(unname(native$slope_lower),
    unname(source$slope_lower),tolerance=1e-6)
  expect_equal(unname(native$slope_upper),
    unname(source$slope_upper),tolerance=1e-6)
  expect_equal(as.numeric(native$prediction_lower),
    as.numeric(source$prediction_lower),tolerance=1e-6)
  expect_equal(as.numeric(native$prediction_upper),
    as.numeric(source$prediction_upper),tolerance=1e-6)
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
