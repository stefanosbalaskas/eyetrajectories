# Frozen Python 1.2 source-scientific parity, commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Direct typed GeneralizedFunctionOnScalarResult prediction plus seeded
# FPCARegressionUncertaintyResult future Gaussian prediction intervals.
# No new fitting, residual model selection, or target selection is done.

.etr_profile_future_two_predictor_fixture <- function(
    family="binomial",exposed=FALSE){
  time<-c(0,.25,.5,1)
  fit<-list(time=time,family=family,
    link=if(family=="binomial")"logit" else "log",
    predictor_names=c("treatment","promotion"),
    basis=cbind(rep(1,4L),time),
    basis_coefficients=matrix(c(.2,.1,.5,.25,-.3,.12),
      nrow=3L,ncol=2L,byrow=TRUE),
    parameter_covariance=diag(c(.04,.02,.03,.01,.05,.025)),
    scalar_design_matrix=rbind(c(1,0,-1),c(1,1,0),
      c(1,2,1),c(1,3,2)),
    exposure=if(exposed)matrix(2,2L,4L) else NULL,
    provenance=list(study="two-predictor-source"))
  profiles<-data.frame(profile_id=c("alpha","beta","gamma","outside"),
    treatment=c(0,1,2,4),promotion=c(-1,0,1,3))
  matrix_exposure<-rbind(c(2,2.5,3,3.5),
    c(3,3.25,3.5,3.75),
    c(4,4.5,5,5.5),c(6,6.5,7,7.5))
  list(fit=fit,profiles=profiles,exposure=matrix_exposure)
}

.etr_profile_future_gaussian_fixture <- function(){
  y<-c(.75,1.4,2.8,3.1,4.4,5.3)
  fitted<-c(.8,1.6,2.6,3.3,4.2,5.5)
  n<-17L
  means<-cbind(.7+.05*seq.int(0L,n-1L),
    1.4+.025*seq.int(0L,n-1L),
    2.0+.035*seq.int(0L,n-1L))
  fit<-list(reference_regression=list(family="gaussian",
    predictions=fitted),bootstrap_slopes=array(0,dim=c(n,2L,2L)),
    bootstrap_mean_predictions=means,
    target_curve_ids=c("fixed-alpha","fixed-beta","fixed-gamma"),
    target_source="external",
    provenance=list(study="seeded-future-source"))
  list(fit=fit,outcome=y)
}

test_that("fixed profiles use multivariate source design and all marginal scales",{
  for(family in c("binomial","poisson"))
    for(exposed in if(family=="binomial")FALSE else c(FALSE,TRUE)){
      f<-.etr_profile_future_two_predictor_fixture(family,exposed)
      scales<-if(exposed)c("rate","expected_count") else
        if(family=="poisson")"expected_count" else "probability"
      for(scale in scales){
        args<-list(result=f$fit,profiles=f$profiles,
          prediction_scale=scale)
        if(identical(scale,"expected_count")&&exposed)
          args$exposure_profiles<-f$exposure
        p<-do.call(etr_generalized_function_on_scalar_predict,args)
        expect_identical(names(p),c("reference","profile_ids",
          "profile_design_matrix","predictor_values",
          "linear_predictor_functions","linear_predictor_standard_errors",
          "mean_functions","mean_standard_errors","extrapolation_flags",
          "predictor_minima","predictor_maxima","prediction_scale",
          "exposure_profiles","log_exposure_profiles","rate_functions",
          "expected_count_functions","linear_predictor_rate",
          "linear_predictor_count","provenance"))
        expect_identical(dim(p$profile_design_matrix),c(4L,3L))
        expect_equal(unname(p$profile_design_matrix),
          cbind(rep(1,4),f$profiles$treatment,f$profiles$promotion),
          tolerance=0)
        expect_identical(dim(p$linear_predictor_functions),c(4L,4L))
        expect_identical(p$profile_ids,as.character(f$profiles$profile_id))
        expect_identical(p$extrapolation_flags,c(FALSE,FALSE,FALSE,TRUE))
        expect_true(all(is.finite(p$linear_predictor_standard_errors)))
        expect_true(all(p$linear_predictor_standard_errors>=0))
        expect_true(all(p$mean_standard_errors>=0))
        expect_identical(p$prediction_scale,scale)
        expect_identical(p$provenance$study,"two-predictor-source")
        expect_false(p$provenance$
          generalized_function_on_scalar_prediction$
          automatic_profile_selection)
        if(family=="binomial"){
          expect_true(all(p$mean_functions>0&p$mean_functions<1))
          expect_null(p$rate_functions)
          expect_null(p$expected_count_functions)
        }else if(exposed){
          expect_equal(p$rate_functions,
            exp(p$linear_predictor_rate),tolerance=1e-12)
          if(scale=="expected_count"){
            expect_equal(p$mean_functions,
              p$rate_functions*f$exposure,tolerance=1e-12)
            expect_equal(p$log_exposure_profiles,
              log(f$exposure),tolerance=1e-12)
          }
        }else{
          expect_equal(p$expected_count_functions,p$mean_functions,
            tolerance=0)
          expect_null(p$rate_functions)
        }
      }
    }
})

test_that("centered residual resampling matches source marginal predictive law",{
  z<-.etr_profile_future_gaussian_fixture()
  for(seed in c(0L,121L,32768L)){
    a<-etr_fpca_regression_future_prediction_interval(
      z$fit,z$outcome,confidence_level=.8,random_state=seed)
    b<-etr_fpca_regression_future_prediction_interval(
      z$fit,z$outcome,confidence_level=.8,random_state=seed)
    expect_identical(a$sampled_residuals,b$sampled_residuals)
    expect_identical(dim(a$predictive_draws),c(17L,3L))
    expect_equal(a$predictive_draws,
      z$fit$bootstrap_mean_predictions+a$sampled_residuals,
      tolerance=0)
    residuals<-z$outcome-z$fit$reference_regression$predictions
    expect_equal(a$centered_residuals,residuals-mean(residuals),
      tolerance=1e-12)
    expect_equal(a$lower,as.numeric(apply(a$predictive_draws,2,
      quantile,probs=.1,names=FALSE,type=7)),tolerance=2e-12)
    expect_equal(a$upper,as.numeric(apply(a$predictive_draws,2,
      quantile,probs=.9,names=FALSE,type=7)),tolerance=2e-12)
    expect_equal(a$predictive_se,
      as.numeric(apply(a$predictive_draws,2,sd)),tolerance=2e-12)
    expect_identical(a$native_rng_source,
      "numpy_seedsequence_spawned_pcg64")
    expect_identical(a$provenance$
      fpca_regression_future_prediction_interval$residual_rng_stream,
      "spawned_domain_separated_stream")
    expect_false(a$provenance$
      fpca_regression_future_prediction_interval$heteroscedasticity_robust)
    expect_false(a$provenance$
      fpca_regression_future_prediction_interval$simultaneous_across_targets)
  }
})

test_that("full source prediction input and forecast domain failures are explicit",{
  f<-.etr_profile_future_two_predictor_fixture("poisson",TRUE)
  invalid<-f$profiles;invalid$promotion[4L]<-NA_real_
  expect_error(etr_generalized_function_on_scalar_predict(f$fit,invalid),
    "finite numeric")
  invalid<-f$profiles;invalid$profile_id[2L]<-"alpha"
  expect_error(etr_generalized_function_on_scalar_predict(f$fit,invalid),
    "unique")
  invalid<-f$profiles;invalid$extra<-0
  expect_error(etr_generalized_function_on_scalar_predict(f$fit,invalid),
    "exactly")
  expect_error(etr_generalized_function_on_scalar_predict(
    f$fit,f$profiles,prediction_scale="expected_count"),
    "requires explicit exposure_profiles")
  expect_error(etr_generalized_function_on_scalar_predict(
    f$fit,f$profiles,exposure_profiles=f$exposure),
    "omitted for rate predictions")
  expect_error(etr_generalized_function_on_scalar_predict(
    f$fit,f$profiles,prediction_scale="expected_count",
    exposure_profiles=matrix(-1,4,4)),"strictly positive")
  fit<-.etr_profile_future_gaussian_fixture()
  invalid<-fit$fit;invalid$reference_regression$family<-"poisson"
  expect_error(etr_fpca_regression_future_prediction_interval(
    invalid,fit$outcome),"Gaussian")
  invalid<-fit$fit;invalid$bootstrap_mean_predictions[1,1]<-Inf
  expect_error(etr_fpca_regression_future_prediction_interval(
    invalid,fit$outcome),"finite two-dimensional")
  expect_error(etr_fpca_regression_future_prediction_interval(
    fit$fit,fit$outcome,confidence_level=0),"confidence_level")
  expect_error(etr_fpca_regression_future_prediction_interval(
    fit$fit,fit$outcome,residual_method="wild"),"residual_method")
})

test_that("full frozen Python 1.2 typed two-predictor prediction and seeded FPCR match",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 typed fixed-profile/future source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as et
from types import SimpleNamespace
def _paired_source_obj(cls,**kw):
    obj=object.__new__(cls)
    for name,value in kw.items():object.__setattr__(obj,name,value)
    return obj
_p_time=np.array([0.,.25,.5,1.])
_p_basis=np.column_stack((np.ones(4),_p_time))
_p_coeff=np.array([[.2,.1],[.5,.25],[-.3,.12]])
_p_cov=np.diag([.04,.02,.03,.01,.05,.025])
_p_observed=np.array([[1.,0.,-1.],[1.,1.,0.],
                      [1.,2.,1.],[1.,3.,2.]])
_p_profiles=pd.DataFrame({'profile_id':['alpha','beta','gamma','outside'],
   'treatment':[0.,1.,2.,4.],'promotion':[-1.,0.,1.,3.]})
_p_exposure=np.array([[2.,2.5,3.,3.5],[3.,3.25,3.5,3.75],
                      [4.,4.5,5.,5.5],[6.,6.5,7.,7.5]])
_p_result={}
for _family,_exposed,_key,_scale in [
  ('binomial',False,'binomial','probability'),
  ('poisson',False,'poisson','expected_count'),
  ('poisson',True,'rate','rate'),
  ('poisson',True,'count','expected_count')]:
    _fit=_paired_source_obj(et.GeneralizedFunctionOnScalarResult,
       time=_p_time,family=_family,
       link='logit' if _family=='binomial' else 'log',
       predictor_names=('treatment','promotion'),basis=_p_basis,
       basis_coefficients=_p_coeff,parameter_covariance=_p_cov,
       scalar_design_matrix=_p_observed,
       exposure=np.full((2,4),2.) if _exposed else None,
       provenance={'study':'two-predictor-source'})
    _kw={'prediction_scale':_scale}
    if _key=='count':_kw['exposure_profiles']=_p_exposure
    _p_result[_key]=et.generalized_function_on_scalar_predict(
       _fit,_p_profiles,**_kw)
_pi_y=np.array([.75,1.4,2.8,3.1,4.4,5.3])
_pi_fit=np.array([.8,1.6,2.6,3.3,4.2,5.5])
_pi_boot=np.column_stack((.7+.05*np.arange(17),
    1.4+.025*np.arange(17),2.0+.035*np.arange(17)))
_pi_uncertainty=_paired_source_obj(et.FPCARegressionUncertaintyResult,
    reference_regression=SimpleNamespace(family='gaussian',
      predictions=_pi_fit),bootstrap_slopes=np.zeros((17,2,2)),
    bootstrap_mean_predictions=_pi_boot,
    target_curve_ids=('fixed-alpha','fixed-beta','fixed-gamma'),
    target_source='external',provenance={'study':'seeded-future-source'})
_pi_forecasts={seed:et.fpca_regression_future_prediction_interval(
    _pi_uncertainty,_pi_y,confidence_level=.8,random_state=seed)
    for seed in (0,121,32768)}
")
  for(key in c("binomial","poisson","rate","count")){
    family<-if(key=="binomial")"binomial" else "poisson"
    exposed<-key%in%c("rate","count")
    f<-.etr_profile_future_two_predictor_fixture(family,exposed)
    args<-list(result=f$fit,profiles=f$profiles,
      prediction_scale=if(key=="binomial")"probability" else
        if(key=="poisson"||key=="count")"expected_count" else "rate")
    if(key=="count")args$exposure_profiles<-f$exposure
    actual<-do.call(etr_generalized_function_on_scalar_predict,args)
    py<-reticulate::py_eval(paste0("_p_result['",key,"']"),
      convert=FALSE)
    for(field in setdiff(names(actual),c("reference","provenance"))){
      target<-et_to_r(reticulate::py_get_attr(py,field))
      expect_equal(actual[[field]],target,tolerance=3e-11,
        ignore_attr=TRUE,info=paste("source two-predictor",key,field))
    }
    pyp<-et_to_r(reticulate::py_get_attr(py,"provenance"))
    for(field in names(actual$provenance$
        generalized_function_on_scalar_prediction)){
      got<-actual$provenance$
        generalized_function_on_scalar_prediction[[field]]
      target<-pyp$generalized_function_on_scalar_prediction[[field]]
      expect_equal(got,target,tolerance=3e-11,ignore_attr=TRUE,
        info=paste("source predictor provenance",key,field))
    }
  }
  f<-.etr_profile_future_gaussian_fixture()
  for(seed in c(0L,121L,32768L)){
    actual<-etr_fpca_regression_future_prediction_interval(
      f$fit,f$outcome,confidence_level=.8,random_state=seed)
    py<-reticulate::py_eval(paste0("_pi_forecasts[",seed,"]"),
      convert=FALSE)
    for(field in setdiff(names(actual),c("regression_uncertainty",
        "native_rng_source","provenance"))){
      target<-et_to_r(reticulate::py_get_attr(py,field))
      expect_equal(actual[[field]],target,tolerance=3e-11,
        ignore_attr=TRUE,info=paste("seeded Python future",seed,field))
    }
    pyp<-et_to_r(reticulate::py_get_attr(py,"provenance"))
    expect_equal(actual$provenance,pyp,tolerance=3e-11,
      ignore_attr=TRUE,info=paste("future source complete provenance",seed))
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
