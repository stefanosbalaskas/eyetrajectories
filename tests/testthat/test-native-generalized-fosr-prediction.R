# Direct Python 1.2.0 numerical oracle: opt-in, NEVER inferred full parity.
.etr_gfosr_predict_fixture <- function(family="binomial",exposed=FALSE){
  fit<-list(time=c(0,.5,1),family=family,
    link=if(family=="binomial")"logit" else "log",
    predictor_names="treatment",
    basis=cbind(c(1,1,1),c(0,.5,1)),
    basis_coefficients=matrix(c(.2,.1,.5,.25),2,2,byrow=TRUE),
    parameter_covariance=diag(c(.04,.01,.09,.04)),
    scalar_design_matrix=rbind(c(1,0),c(1,1)),
    exposure=if(exposed)matrix(2,2,3) else NULL,
    provenance=list(audit="frozen"))
  profiles<-data.frame(profile_id=c("A","B","C"),
    treatment=c(0,1,2))
  list(fit=fit,profiles=profiles)
}

test_that("fixed binomial profiles use full robust parameter covariance",{
  z<-.etr_gfosr_predict_fixture()
  p<-etr_generalized_function_on_scalar_predict(z$fit,z$profiles)
  # Verify independent direct scalar design evaluation (not link-scale averaging).
  expect_equal(p$linear_predictor_functions[1,],c(.2,.25,.3))
  expect_equal(p$linear_predictor_functions[2,],c(.7,.875,1.05))
  expect_equal(p$linear_predictor_standard_errors[1,1],sqrt(.04))
  expect_equal(p$linear_predictor_standard_errors[2,1],sqrt(.13))
  correlated<-z$fit
  correlated$parameter_covariance[1,3]<-.005
  correlated$parameter_covariance[3,1]<-.005
  correlated_result<-etr_generalized_function_on_scalar_predict(
    correlated,z$profiles)
  expect_equal(correlated_result$linear_predictor_standard_errors[2,1],
    sqrt(.14),tolerance=1e-12)
  frame<-etr_generalized_function_on_scalar_prediction_frame(p)
  expect_equal(nrow(frame),9L)
  expect_identical(frame$profile_id,rep(c("A","B","C"),each=3L))
  expect_equal(p$mean_functions,plogis(p$linear_predictor_functions))
  expect_identical(p$extrapolation_flags,c(FALSE,FALSE,TRUE))
  expect_true(all(p$linear_predictor_standard_errors>=0))
  expect_equal(p$mean_standard_errors,
    p$mean_functions*(1-p$mean_functions)*
      p$linear_predictor_standard_errors)
  expect_true(is.null(p$rate_functions))
  expect_equal(p$predictor_minima,0)
  expect_equal(p$predictor_maxima,1)
  expect_equal(p$profile_design_matrix[,2],c(0,1,2))
  expect_true(p$provenance$generalized_function_on_scalar_prediction$
    extrapolated_profiles_retained)
  expect_false(p$provenance$generalized_function_on_scalar_prediction$
    simultaneous_inference)
})

test_that("Poisson rate and expected-count estimands separate exposure",{
  z<-.etr_gfosr_predict_fixture(family="poisson",exposed=TRUE)
  rate<-etr_generalized_function_on_scalar_predict(z$fit,z$profiles)
  count<-etr_generalized_function_on_scalar_predict(z$fit,z$profiles,
    prediction_scale="expected_count",exposure_profiles=c(2,3,4))
  expect_identical(rate$prediction_scale,"rate")
  expect_identical(count$prediction_scale,"expected_count")
  expect_equal(count$mean_functions,
    rate$mean_functions*matrix(rep(c(2,3,4),each=3),3,byrow=TRUE))
  expect_equal(rate$rate_functions,rate$mean_functions)
  expect_equal(count$rate_functions,rate$mean_functions)
  expect_equal(count$expected_count_functions,count$mean_functions)
  expect_true(is.null(rate$expected_count_functions))
  expect_error(etr_generalized_function_on_scalar_predict(z$fit,z$profiles,
    exposure_profiles=c(2,3,4)),"omitted")
  expect_error(etr_generalized_function_on_scalar_predict(z$fit,z$profiles,
    prediction_scale="expected_count"),"requires")
  expect_error(etr_generalized_function_on_scalar_predict(z$fit,z$profiles,
    prediction_scale="expected_count",exposure_profiles=c(2,-1,4)),
    "strictly positive")
})

test_that("generalized source prediction rejects unsupported shapes and inputs",{
  z<-.etr_gfosr_predict_fixture()
  bad<-z$profiles;bad$treatment[2]<-NA_real_
  expect_error(etr_generalized_function_on_scalar_predict(z$fit,bad),
    "finite numeric")
  bad<-z$profiles;bad$extra<-1
  expect_error(etr_generalized_function_on_scalar_predict(z$fit,bad),
    "exactly")
  bad<-z$profiles;bad$profile_id[3]<-"A"
  expect_error(etr_generalized_function_on_scalar_predict(z$fit,bad),
    "unique")
  bad<-z$fit;bad$parameter_covariance<-diag(3)
  expect_error(etr_generalized_function_on_scalar_predict(bad,z$profiles),
    "parameter_covariance")
  bad<-z$fit;bad$basis_coefficients[1,1]<-Inf
  expect_error(etr_generalized_function_on_scalar_predict(bad,z$profiles),
    "basis_coefficients")
  expect_error(etr_generalized_function_on_scalar_predict(z$fit,
    z$profiles,prediction_scale="rate"),"binomial")
  over<-.etr_gfosr_predict_fixture(family="poisson",exposed=FALSE)
  over$fit$basis_coefficients[1,1]<-1000
  expect_error(etr_generalized_function_on_scalar_predict(
    over$fit,over$profiles),"overflowed")
})

test_that("published Python 1.2 and native fixed profile predictions agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python generalized FoSR numerical oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as et
def _et_predict_obj(cls,**kw):
    x=object.__new__(cls)
    for name,value in kw.items():
        object.__setattr__(x,name,value)
    return x
_gp_base=dict(time=np.array([0.,.5,1.]),
    predictor_names=('treatment',),
    basis=np.array([[1.,0.],[1.,.5],[1.,1.]]),
    basis_coefficients=np.array([[.2,.1],[.5,.25]]),
    parameter_covariance=np.diag([.04,.01,.09,.04]),
    scalar_design_matrix=np.array([[1.,0.],[1.,1.]]),
    provenance={'audit':'frozen'})
_gp_profiles=pd.DataFrame({'profile_id':['A','B','C'],
    'treatment':[0.,1.,2.]})
_gp_results={}
_gp_inputs={}
for _gp_family,_gp_exposure in (
    ('binomial',None),('poisson',None),('poisson',np.ones((2,3)))):
    _gp_fit=_et_predict_obj(et.GeneralizedFunctionOnScalarResult,
        **_gp_base,family=_gp_family,
        link='logit' if _gp_family=='binomial' else 'log',
        exposure=_gp_exposure)
    _gp_key=_gp_family+('_exposed' if _gp_exposure is not None else '')
    _gp_inputs[_gp_key]=_gp_fit
    if _gp_exposure is not None:
        _gp_inputs['poisson_count']=_gp_fit
    _gp_results[_gp_key]=et.generalized_function_on_scalar_predict(
        _gp_fit,_gp_profiles)
    if _gp_exposure is not None:
        _gp_results['poisson_count']=et.generalized_function_on_scalar_predict(
            _gp_fit,_gp_profiles,prediction_scale='expected_count',
            exposure_profiles=np.array([2.,3.,4.]))
")
  for(key in c("binomial","poisson","poisson_exposed","poisson_count")){
    family<-if(key=="binomial")"binomial" else "poisson"
    exposed<-key%in%c("poisson_exposed","poisson_count")
    z<-.etr_gfosr_predict_fixture(family=family,exposed=exposed)
    native<-if(key=="poisson_count")
      etr_generalized_function_on_scalar_predict(z$fit,z$profiles,
        prediction_scale="expected_count",exposure_profiles=c(2,3,4)) else
      etr_generalized_function_on_scalar_predict(z$fit,z$profiles)
    args<-list(result=reticulate::py_eval(
        paste0("_gp_inputs['",key,"']"),convert=FALSE),
      profiles=reticulate::py_eval("_gp_profiles",convert=FALSE))
    if(identical(key,"poisson_count")){
      args$prediction_scale<-"expected_count"
      args$exposure_profiles<-reticulate::py_eval(
        "np.array([2.,3.,4.])",convert=FALSE)
    }
    direct<-do.call(reticulate::py_call,c(
      list(etpy_get_export("generalized_function_on_scalar_predict")),
      args))
    fields<-c("profile_design_matrix","predictor_values",
      "linear_predictor_functions",
      "linear_predictor_standard_errors","mean_functions",
      "mean_standard_errors","extrapolation_flags",
      "predictor_minima","predictor_maxima")
    for(field in fields){
      py<-reticulate::py_eval(paste0("_gp_results['",key,"'].",field),
        convert=TRUE)
      expect_equal(native[[field]],py,tolerance=1e-10,
        ignore_attr=TRUE,info=paste(key,field))
      expect_equal(et_to_r(reticulate::py_get_attr(direct,field)),
        py,tolerance=1e-10,ignore_attr=TRUE)
    }
    expect_identical(native$prediction_scale,
      reticulate::py_eval(paste0("_gp_results['",key,
        "'].prediction_scale"),convert=TRUE))
    for(field in c("rate_functions","expected_count_functions",
        "linear_predictor_rate","linear_predictor_count")){
      py<-reticulate::py_eval(paste0("_gp_results['",key,"'].",field),
        convert=TRUE)
      expect_equal(native[[field]],py,tolerance=1e-10,
        ignore_attr=TRUE,info=paste(key,field))
    }
  }
})
