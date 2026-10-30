# Pinned 1.2.0 regression_inference.py future prediction law
.etr_fpcr_future_fixture<-function(){
  base<-c(.8,2.4,2.9,4.1)
  fit<-c(1,2,3,4)
  b<-20L
  mean_pred<-cbind(1+.02*(0:(b-1L)),2.5+.01*(0:(b-1L)))
  uncertain<-list(
    reference_regression=list(family="gaussian",predictions=fit),
    bootstrap_slopes=array(0,c(b,1L,1L)),
    bootstrap_mean_predictions=mean_pred,
    target_curve_ids=c("A","B"),
    target_source="external",provenance=list(source="retained"))
  idx<-matrix(rep(c(0,1,2,3),length.out=b*2L),nrow=b,ncol=2L)
  list(result=uncertain,outcome=base,idx=idx)
}
test_that("retained FPCR predictive draws preserve centered residual and marginal target",{
  z<-.etr_fpcr_future_fixture()
  a<-etr_fpca_regression_future_prediction_interval(
    z$result,z$outcome,.9,residual_indices=z$idx)
  residuals<-z$outcome-z$result$reference_regression$predictions
  centered<-residuals-mean(residuals)
  expect_equal(a$centered_residuals,centered)
  expect_equal(a$sampled_residuals,matrix(centered[z$idx+1L],
    nrow=20L,ncol=2L))
  expect_equal(a$predictive_draws,
    z$result$bootstrap_mean_predictions+a$sampled_residuals)
  expect_equal(a$lower,as.numeric(apply(a$predictive_draws,2,
    quantile,probs=.05,names=FALSE,type=7)),tolerance=1e-12)
  expect_equal(a$median,as.numeric(apply(a$predictive_draws,2,
    quantile,probs=.5,names=FALSE,type=7)),tolerance=1e-12)
  expect_equal(a$upper,as.numeric(apply(a$predictive_draws,2,
    quantile,probs=.95,names=FALSE,type=7)),tolerance=1e-12)
  expect_equal(a$predictive_se,apply(a$predictive_draws,2,sd),
    tolerance=1e-12)
  expect_false(a$provenance$fpca_regression_future_prediction_interval$
    simultaneous_across_targets)
  expect_false(a$provenance$fpca_regression_future_prediction_interval$
    heteroscedasticity_robust)
  expect_identical(a$native_rng_source,
    "externally_retained_python_source_indices")
})
test_that("source invalid training and resampling domains fail closed",{
  z<-.etr_fpcr_future_fixture()
  bad<-z$result;bad$reference_regression$family<-"binomial"
  expect_error(etr_fpca_regression_future_prediction_interval(bad,z$outcome),
    "Gaussian FPCR")
  bad<-z$result;bad$bootstrap_mean_predictions[1,1]<-NA_real_
  expect_error(etr_fpca_regression_future_prediction_interval(bad,z$outcome),
    "finite two-dimensional")
  bad<-z$result;bad$target_curve_ids<-"A"
  expect_error(etr_fpca_regression_future_prediction_interval(bad,z$outcome),
    "target prediction count")
  expect_error(etr_fpca_regression_future_prediction_interval(
    z$result,z$outcome,confidence_level=1),"confidence_level")
  expect_error(etr_fpca_regression_future_prediction_interval(
    z$result,z$outcome,residual_method="wild"),"residual_method")
  x<-z$idx;x[1,1]<-4
  expect_error(etr_fpca_regression_future_prediction_interval(
    z$result,z$outcome,residual_indices=x),
    "zero-based integer")
})
test_that("R-only independent residual draws preserve seed and caller RNG state",{
  z<-.etr_fpcr_future_fixture()
  set.seed(821)
  before<-.Random.seed
  a<-etr_fpca_regression_future_prediction_interval(
    z$result,z$outcome,random_state=121)
  expect_identical(.Random.seed,before)
  b<-etr_fpca_regression_future_prediction_interval(
    z$result,z$outcome,random_state=121)
  expect_identical(a$sampled_residuals,b$sampled_residuals)
  expect_identical(a$native_rng_source,
    "r_native_random_draws_not_numpy_seedsequence")
  expect_identical(a$provenance$
    fpca_regression_future_prediction_interval$residual_rng_stream,
    "r_native_random_stream_not_numpy_seedsequence")
})
test_that("pinned Python 1.2 future-outcome predictive distribution matches fixed draws",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("future FPCR outcome source oracle requires pinned Python 1.2")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
from types import SimpleNamespace
def _pi_obj(cls,**fields):
    obj=object.__new__(cls)
    for k,v in fields.items():object.__setattr__(obj,k,v)
    return obj
_pi_outcome=np.array([.8,2.4,2.9,4.1])
_pi_fitted=np.array([1.,2.,3.,4.])
_pi_mean=np.column_stack((1.+.02*np.arange(20),
                          2.5+.01*np.arange(20)))
_pi_result=_pi_obj(et.FPCARegressionUncertaintyResult,
  reference_regression=SimpleNamespace(
    family='gaussian',predictions=_pi_fitted),
  bootstrap_slopes=np.zeros((20,1,1)),
  bootstrap_mean_predictions=_pi_mean,
  target_curve_ids=('A','B'),
  target_source='external',provenance={'source':'retained'})
_pi_source=et.fpca_regression_future_prediction_interval(
    _pi_result,_pi_outcome,confidence_level=.9,random_state=121)
_pi_centered=_pi_source.centered_residuals
_pi_sampled=_pi_source.sampled_residuals
_pi_indices=np.array(
  [[int(np.where(np.isclose(_pi_centered,v,rtol=0,atol=1e-12))[0][0])
    for v in row] for row in _pi_sampled],dtype=np.int64)
_pi_provenance=dict(
  _pi_source.provenance['fpca_regression_future_prediction_interval'])
")
  z<-.etr_fpcr_future_fixture()
  indices<-reticulate::py_to_r(reticulate::py_eval(
    "_pi_indices",convert=FALSE))
  a<-etr_fpca_regression_future_prediction_interval(
    z$result,z$outcome,confidence_level=.9,
    random_state=121,residual_indices=indices)
  for(field in c("centered_residuals","sampled_residuals",
    "predictive_draws","lower","median","upper","predictive_se")){
    expected<-reticulate::py_to_r(reticulate::py_eval(
      paste0("_pi_source.",field),convert=FALSE))
    expect_equal(a[[field]],expected,tolerance=1e-12,
      ignore_attr=TRUE,info=field)
  }
  expected_prov<-reticulate::py_to_r(reticulate::py_eval(
    "_pi_provenance",convert=FALSE))
  native_prov<-a$provenance$fpca_regression_future_prediction_interval
  for(name in names(expected_prov))
    expect_equal(native_prov[[name]],expected_prov[[name]],
      info=paste("source predictive inference provenance",name))
  expect_identical(a$native_rng_source,
    "externally_retained_python_source_indices")
})
