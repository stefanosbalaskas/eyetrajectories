# Self-contained source fixture: does not depend on a different test file.
.etr_gfosr_contrast_fixture<-function(family="binomial",exposed=FALSE,
    count=FALSE){
  fit<-list(time=c(0,.5,1),family=family,
    link=if(family=="binomial")"logit" else "log",
    predictor_names="treatment",
    basis=cbind(c(1,1,1),c(0,.5,1)),
    basis_coefficients=matrix(c(.2,.1,.5,.25),2,2,byrow=TRUE),
    parameter_covariance=diag(c(.04,.01,.09,.04)),
    scalar_design_matrix=rbind(c(1,0),c(1,1)),
    exposure=if(exposed)matrix(2,2,3) else NULL,
    provenance=list(audit="frozen"))
  draws<-array(NA_real_,c(4L,2L,3L))
  draws[1L,,]<-rbind(c(.10,.20,.25),c(.35,.55,.65))
  draws[2L,,]<-rbind(c(.22,.26,.32),c(.48,.58,.68))
  draws[3L,,]<-rbind(c(.27,.29,.38),c(.51,.59,.73))
  draws[4L,,]<-rbind(c(.32,.36,.42),c(.65,.80,.85))
  bootstrap<-list(reference=fit,bootstrap_coefficient_functions=draws,
    provenance=list(source="retained"))
  profiles<-data.frame(profile_id=c("A","B","C"),treatment=c(0,1,2))
  if(count)etr_bootstrap_generalized_function_on_scalar_predictions(
    bootstrap,profiles,prediction_scale="expected_count",
    exposure_profiles=c(2,3,4))
  else etr_bootstrap_generalized_function_on_scalar_predictions(
    bootstrap,profiles)
}

test_that("predeclared probability contrast preserves physical-bound audit",{
  b<-.etr_gfosr_contrast_fixture()
  a<-etr_generalized_function_on_scalar_mean_difference_band(
    b,profile_a="B",profile_b="A",confidence_level=.5)
  expect_identical(a$contrast_scale,"probability_difference")
  expect_identical(a$inference_scale,"probability_difference")
  expect_identical(length(a$estimate),3L)
  expect_identical(length(a$max_statistics),4L)
  expect_equal(a$estimate,
    b$prediction$mean_functions[2L,]-
      b$prediction$mean_functions[1L,])
  expect_equal(a$standard_error,apply(a$bootstrap_estimates,2L,sd))
  expect_true(a$critical_value>=0)
  expect_identical(a$physical_lower_bound,-1)
  expect_identical(a$physical_upper_bound,1)
  expect_false(a$provenance$
    generalized_function_on_scalar_mean_difference_band$
    multiple_contrast_family_adjustment)
  expect_false(a$provenance$
    generalized_function_on_scalar_mean_difference_band$
    physical_bounds_clipped)
  frame<-etr_generalized_function_on_scalar_mean_difference_frame(a)
  expect_identical(nrow(frame),3L)
  expect_equal(frame$estimate,a$estimate)
})

test_that("rate ratios use log-scale calibration; count differences use exposures",{
  b<-.etr_gfosr_contrast_fixture("poisson",TRUE)
  a<-etr_generalized_function_on_scalar_mean_difference_band(
    b,profile_a="B",profile_b="A",confidence_level=.5,
    contrast_scale="rate_ratio")
  expect_identical(a$contrast_scale,"rate_ratio")
  expect_identical(a$inference_scale,"log_rate_ratio")
  expect_true(all(a$lower>0))
  expect_true(all(a$upper>0))
  expect_equal(a$estimate,
    b$prediction$rate_functions[2L,]/
      b$prediction$rate_functions[1L,])
  count<-.etr_gfosr_contrast_fixture("poisson",TRUE,count=TRUE)
  c<-etr_generalized_function_on_scalar_mean_difference_band(
    count,profile_a="B",profile_b="A",confidence_level=.5,
    contrast_scale="expected_count_difference")
  expect_identical(c$inference_scale,"expected_count_difference")
  expect_true(is.null(c$physical_lower_bound))
  expect_false(c$interval_exceeds_physical_bounds)
  expect_error(etr_generalized_function_on_scalar_mean_difference_band(
    b,"B","A",contrast_scale="expected_count_difference"),
    "expected_count_difference requires")
})

test_that("contrast API rejects invalid identifiers and calibration support",{
  b<-.etr_gfosr_contrast_fixture()
  expect_error(etr_generalized_function_on_scalar_mean_difference_band(
    b,"A","A"),"different")
  expect_error(etr_generalized_function_on_scalar_mean_difference_band(
    b,"Z","A"),"Unknown profile")
  expect_error(etr_generalized_function_on_scalar_mean_difference_band(
    b,"A","B",contrast_scale="rate_ratio"),"contrast_scale")
  expect_error(etr_generalized_function_on_scalar_mean_difference_band(
    b,"A","B",confidence_level=1),"confidence_level")
  bad<-b
  bad$bootstrap_mean_functions<-bad$bootstrap_mean_functions[1L,,,drop=FALSE]
  expect_error(etr_generalized_function_on_scalar_mean_difference_band(
    bad,"B","A"),"B >= 2")
})

test_that("frozen Python 1.2 matches all source contrast estimands",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 generalized contrast source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as et
def _contrast_obj(cls,**kw):
    x=object.__new__(cls)
    for key,value in kw.items(): object.__setattr__(x,key,value)
    return x
_c_base=dict(time=np.array([0.,.5,1.]),
    predictor_names=('treatment',),
    basis=np.array([[1.,0.],[1.,.5],[1.,1.]]),
    basis_coefficients=np.array([[.2,.1],[.5,.25]]),
    parameter_covariance=np.diag([.04,.01,.09,.04]),
    scalar_design_matrix=np.array([[1.,0.],[1.,1.]]),
    provenance={'audit':'frozen'})
_c_profiles=pd.DataFrame({'profile_id':['A','B','C'],
    'treatment':[0.,1.,2.]})
_c_coef=np.array([
  [[.10,.20,.25],[.35,.55,.65]],
  [[.22,.26,.32],[.48,.58,.68]],
  [[.27,.29,.38],[.51,.59,.73]],
  [[.32,.36,.42],[.65,.80,.85]]
])
_c_oracles={}
for _key,_family,_exposed,_count,_scale in (
    ('binomial','binomial',False,False,None),
    ('poisson','poisson',False,False,None),
    ('rate_difference','poisson',True,False,'rate_difference'),
    ('rate_ratio','poisson',True,False,'rate_ratio'),
    ('expected_count_difference','poisson',True,True,'expected_count_difference')):
    _fit=_contrast_obj(et.GeneralizedFunctionOnScalarResult,
        **_c_base,family=_family,
        link='logit' if _family=='binomial' else 'log',
        exposure=np.ones((2,3)) if _exposed else None)
    _boost=_contrast_obj(et.GeneralizedFunctionOnScalarBootstrapResult,
        reference=_fit,bootstrap_coefficient_functions=_c_coef,
        provenance={'source':'retained'})
    _kw={'prediction_scale':'expected_count',
        'exposure_profiles':np.array([2.,3.,4.])} if _count else {}
    _prediction=et.bootstrap_generalized_function_on_scalar_predictions(
        _boost,_c_profiles,**_kw)
    _c_oracles[_key]=et.generalized_function_on_scalar_mean_difference_band(
        _prediction,profile_a='B',profile_b='A',
        confidence_level=.5,contrast_scale=_scale)
")
  for(key in c("binomial","poisson","rate_difference","rate_ratio",
      "expected_count_difference")){
    family<-if(key=="binomial")"binomial" else "poisson"
    exposed<-key%in%c("rate_difference","rate_ratio",
      "expected_count_difference")
    b<-.etr_gfosr_contrast_fixture(family,exposed,
      count=key=="expected_count_difference")
    specified<-if(key%in%c("rate_difference","rate_ratio",
      "expected_count_difference")) key else NULL
    native<-etr_generalized_function_on_scalar_mean_difference_band(
      b,"B","A",confidence_level=.5,contrast_scale=specified)
    fields<-c("estimate","standard_error","lower","upper",
      "bootstrap_estimates","max_statistics","critical_value",
      "interval_exceeds_physical_bounds","contrast_scale","inference_scale")
    for(field in fields){
      py<-reticulate::py_eval(paste0("_c_oracles['",key,"'].",field),
        convert=TRUE)
      expect_equal(native[[field]],py,ignore_attr=TRUE,tolerance=1e-10,
        info=paste(key,field))
    }
  }
})
