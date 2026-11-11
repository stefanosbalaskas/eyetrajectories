# Paired full scientific source review, Python eyetrajectoriespy 1.2.0
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Fixed-profile generalized FoSR coefficient-bootstrap projection and
# mixed-model fitted covariance variance decomposition. Neither refits.

.etr_source_pair_variance_fixture <- function(trial="functional_intercept",
    slope=TRUE) {
  time <- c(0,.25,.5,1)
  basis <- cbind(rep(1,4),time)
  list(time=time,random_basis=basis,
    random_intercept_covariance=matrix(c(.4,.03,.03,.2),2,2),
    random_slope_covariance=if(slope)matrix(c(.1,.02,.02,.3),2,2)
      else NULL,
    random_intercept_slope_covariance=if(slope)
      matrix(c(-.05,.02,.01,-.04),2,2) else NULL,
    trial_random_effect=trial,
    trial_random_basis=cbind(rep(1,4),time^2),
    trial_random_effect_covariance=matrix(c(.25,.01,.01,.10),2,2),
    residual_variance=.08)
}

.etr_source_pair_bootstrap_fixture <- function(family="binomial",
    exposed=FALSE) {
  tt<-c(0,.25,.5,1)
  basis<-cbind(rep(1,4),tt)
  fit<-list(time=tt,family=family,
    link=if(family=="binomial")"logit" else "log",
    predictor_names="treatment",basis=basis,
    basis_coefficients=matrix(c(.2,.1,.5,.25),2,2,byrow=TRUE),
    parameter_covariance=diag(c(.04,.01,.09,.04)),
    scalar_design_matrix=rbind(c(1,0),c(1,1)),
    exposure=if(exposed)matrix(2,2,4) else NULL,
    provenance=list(source="frozen-fit"))
  profiles<-data.frame(profile_id=c("A","B","C"),
    treatment=c(0,1,2))
  draws<-array(0,c(5L,2L,4L))
  for(b in seq_len(5L)){
    draws[b,1L,]<-c(.10,.20,.25,.30)+b*c(.02,.015,.012,.008)
    draws[b,2L,]<-c(.35,.55,.65,.75)+b*c(.035,.025,.02,.012)
  }
  list(bootstrap=list(reference=fit,
    bootstrap_coefficient_functions=draws,
    provenance=list(study="source-projection-pair")),
    profiles=profiles)
}

test_that("variance decomposition source includes only declared functional trial intercept",{
  scenarios<-list(list(trial="functional_intercept",slope=TRUE,n=20L),
    list(trial="other",slope=TRUE,n=16L),
    list(trial=NULL,slope=FALSE,n=8L))
  for(case in scenarios){
    fit<-.etr_source_pair_variance_fixture(case$trial,case$slope)
    native<-etr_functional_mixed_effects_variance_decomposition(
      fit,model_label="study")
    expect_identical(names(native),c("model","component",
      "component_type","time","value"))
    expect_identical(nrow(native),case$n)
    expect_true(all(native$model=="study"))
    expect_true(all(is.finite(native$value)))
    expect_identical(native$time,rep(fit$time,case$n/4L))
    expect_true(all(native$value[native$component=="residual_variance"]==.08))
    if(identical(case$trial,"functional_intercept"))
      expect_true("trial_variance"%in%native$component)
    else expect_false("trial_variance"%in%native$component)
    if(case$slope){
      expect_true("participant_intercept_slope_cross_covariance" %in% native$component)
      expect_true(any(native$value[
        native$component=="participant_intercept_slope_cross_covariance"]<0))
    }
  }
})

test_that("fixed profile bootstrap projection retains full source arrays and exposure scaling",{
  for(family in c("binomial","poisson"))
    for(exposed in if(family=="binomial")FALSE else c(FALSE,TRUE)){
      z<-.etr_source_pair_bootstrap_fixture(family,exposed)
      for(count in if(exposed) c(FALSE,TRUE) else FALSE){
        args<-list(bootstrap=z$bootstrap,profiles=z$profiles)
        if(count) {
          args$prediction_scale<-"expected_count"
          args$exposure_profiles<-c(2,3,4)
        }
        native<-do.call(
          etr_bootstrap_generalized_function_on_scalar_predictions,args)
        expect_identical(names(native),c("prediction","coefficient_bootstrap",
          "bootstrap_linear_predictor_functions",
          "bootstrap_mean_functions","bootstrap_rate_functions",
          "bootstrap_expected_count_functions","provenance"))
        expect_identical(dim(native$bootstrap_linear_predictor_functions),
          c(5L,3L,4L))
        expect_identical(native$prediction$profile_ids,c("A","B","C"))
        expect_identical(native$coefficient_bootstrap$provenance$study,
          "source-projection-pair")
        expect_identical(native$provenance$study,"source-projection-pair")
        expect_true(all(is.finite(native$bootstrap_mean_functions)))
        expect_true(native$provenance$
          generalized_function_on_scalar_prediction_bootstrap$
          same_participant_draws_as_coefficient_bootstrap)
        if(family=="binomial"){
          expect_true(all(native$bootstrap_mean_functions>0&
            native$bootstrap_mean_functions<1))
        }else if(exposed){
          expect_true(all(native$bootstrap_rate_functions>0))
          if(count){
            expect_equal(native$bootstrap_expected_count_functions,
              native$bootstrap_mean_functions,tolerance=0)
            expected<-sweep(native$bootstrap_rate_functions,c(2L,3L),
              matrix(rep(c(2,3,4),each=4L),3,4,byrow=TRUE),"*")
            expect_equal(native$bootstrap_expected_count_functions,
              expected,tolerance=1e-12)
          }
        }else{
          expect_equal(native$bootstrap_expected_count_functions,
            native$bootstrap_mean_functions,tolerance=0)
        }
      }
    }
})

test_that("source pair scientific invalid inputs are rejected",{
  z<-.etr_source_pair_bootstrap_fixture()
  bad<-z
  bad$bootstrap$bootstrap_coefficient_functions<-array(1,c(5L,3L,4L))
  expect_error(etr_bootstrap_generalized_function_on_scalar_predictions(
    bad$bootstrap,bad$profiles),"bootstrap_coefficient_functions")
  bad<-z
  bad$profiles$treatment[2L]<-"invalid"
  expect_error(etr_bootstrap_generalized_function_on_scalar_predictions(
    bad$bootstrap,bad$profiles),"finite|numeric")
  bad<-z
  bad$profiles$profile_id[2L]<-"A"
  expect_error(etr_bootstrap_generalized_function_on_scalar_predictions(
    bad$bootstrap,bad$profiles),"unique|duplicate")
  fit<-.etr_source_pair_variance_fixture()
  bad<-fit
  bad$random_basis<-matrix(1,3,2)
  expect_error(etr_functional_mixed_effects_variance_decomposition(bad),
    "random_basis")
  bad<-fit
  bad$random_slope_covariance<-NULL
  expect_error(etr_functional_mixed_effects_variance_decomposition(bad,
    model_label=""),"model_label")
  bad<-fit
  bad$random_intercept_slope_covariance<-NULL
  expect_error(etr_functional_mixed_effects_variance_decomposition(bad),
    "cross-covariance")
  bad<-fit
  bad$trial_random_effect_covariance<-NULL
  expect_error(etr_functional_mixed_effects_variance_decomposition(bad),
    "trial random-effect")
})

test_that("pinned frozen Python source variance tables and fixed projections match",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen typed Python 1.2 source projection/variance oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as et
def _fp_source_obj(cls,**fields):
    obj=object.__new__(cls)
    for name,value in fields.items():
        object.__setattr__(obj,name,value)
    return obj
_fp_time=np.array([0.,.25,.5,1.])
_fp_basis=np.column_stack((np.ones(4),_fp_time))
_fp_trial_basis=np.column_stack((np.ones(4),_fp_time**2))
_fp_source_variances={}
for _trial,_slope,_key in (
    ('functional_intercept',True,'full'),
    ('other',True,'other'),
    (None,False,'intercept')):
    _fit=_fp_source_obj(et.FunctionalMixedEffectsResult,
        time=_fp_time,random_basis=_fp_basis,
        random_intercept_covariance=np.array([[.4,.03],[.03,.2]]),
        random_slope_covariance=np.array([[.1,.02],[.02,.3]]) if _slope else None,
        random_intercept_slope_covariance=np.array([[-.05,.01],[.02,-.04]]) if _slope else None,
        trial_random_effect=_trial,
        trial_random_basis=_fp_trial_basis,
        trial_random_effect_covariance=np.array([[.25,.01],[.01,.1]]),
        residual_variance=.08)
    _fp_source_variances[_key]=et.functional_mixed_effects_variance_decomposition(
        _fit,model_label='study')
_fp_profile_data=pd.DataFrame(
    {'profile_id':['A','B','C'],'treatment':[0.,1.,2.]})
_fp_basis_reg=np.column_stack((np.ones(4),_fp_time))
_fp_draws=np.zeros((5,2,4),dtype=float)
for b in range(1,6):
    _fp_draws[b-1,0]=np.array([.10,.20,.25,.30])+b*np.array([.02,.015,.012,.008])
    _fp_draws[b-1,1]=np.array([.35,.55,.65,.75])+b*np.array([.035,.025,.02,.012])
_fp_boots={}
for _family,_exposed,_kind in (
    ('binomial',False,'binomial'),
    ('poisson',False,'poisson'),
    ('poisson',True,'rate'),
    ('poisson',True,'count')):
    _fit=_fp_source_obj(et.GeneralizedFunctionOnScalarResult,
        time=_fp_time,family=_family,
        link='logit' if _family=='binomial' else 'log',
        predictor_names=('treatment',),basis=_fp_basis_reg,
        basis_coefficients=np.array([[.2,.1],[.5,.25]]),
        parameter_covariance=np.diag([.04,.01,.09,.04]),
        scalar_design_matrix=np.array([[1.,0.],[1.,1.]]),
        exposure=np.ones((2,4))*2 if _exposed else None,
        provenance={'source':'frozen-fit'})
    _coef_boot=_fp_source_obj(et.GeneralizedFunctionOnScalarBootstrapResult,
        reference=_fit,
        bootstrap_coefficient_functions=_fp_draws,
        provenance={'study':'source-projection-pair'})
    _kw={'prediction_scale':'expected_count',
         'exposure_profiles':np.array([2.,3.,4.])} if _kind=='count' else {}
    _fp_boots[_kind]=et.bootstrap_generalized_function_on_scalar_predictions(
        _coef_boot,_fp_profile_data,**_kw)
")
  for(item in list(list(key="full",trial="functional_intercept",slope=TRUE),
    list(key="other",trial="other",slope=TRUE),
    list(key="intercept",trial=NULL,slope=FALSE))){
    x<-etr_functional_mixed_effects_variance_decomposition(
      .etr_source_pair_variance_fixture(item$trial,item$slope),
      model_label="study")
    py<-reticulate::py_eval(
      paste0("_fp_source_variances['",item$key,"']"),convert=FALSE)
    frame<-et_to_r(py)
    expect_identical(names(x),names(frame))
    expect_identical(as.character(x$component),
      as.character(frame$component))
    expect_identical(as.character(x$component_type),
      as.character(frame$component_type))
    expect_equal(x$time,frame$time,tolerance=0,ignore_attr=TRUE)
    expect_equal(x$value,frame$value,tolerance=2e-12,ignore_attr=TRUE)
  }
  for(key in c("binomial","poisson","rate","count")){
    z<-.etr_source_pair_bootstrap_fixture(
      if(key=="binomial")"binomial" else "poisson",
      exposed=key%in%c("rate","count"))
    args<-list(bootstrap=z$bootstrap,profiles=z$profiles)
    if(key=="count"){
      args$prediction_scale<-"expected_count"
      args$exposure_profiles<-c(2,3,4)
    }
    native<-do.call(etr_bootstrap_generalized_function_on_scalar_predictions,
      args)
    source<-reticulate::py_eval(paste0("_fp_boots['",key,"']"),
      convert=FALSE)
    for(field in setdiff(names(native),c("prediction",
      "coefficient_bootstrap","provenance"))){
      expect_equal(native[[field]],
        et_to_r(reticulate::py_get_attr(source,field)),
        tolerance=2e-10,ignore_attr=TRUE,
        info=paste("full source bootstrap",key,field))
    }
    expect_equal(native$provenance,
      et_to_r(reticulate::py_get_attr(source,"provenance")),
      ignore_attr=TRUE,info=paste("source provenance",key))
    pred<-reticulate::py_get_attr(source,"prediction")
    for(field in c("profile_design_matrix","predictor_values",
      "linear_predictor_functions","linear_predictor_standard_errors",
      "mean_functions","mean_standard_errors","extrapolation_flags",
      "predictor_minima","predictor_maxima")){
      expect_equal(native$prediction[[field]],
        et_to_r(reticulate::py_get_attr(pred,field)),
        tolerance=2e-10,ignore_attr=TRUE,
        info=paste("nested prediction",key,field))
    }
  }
})
