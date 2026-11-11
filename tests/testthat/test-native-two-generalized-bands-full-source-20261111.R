# Full source-semantic observed-grid generalized FoSR band contracts.
# Frozen Python 1.2 commit c1cd95ad718327550f7e55393ff38582872f7a94
# generalized_function_on_scalar.py and generalized_function_on_scalar_prediction.py

.etr_two_gfosr_band_source_fixture <- function(family="binomial") {
  time<-c(0,.25,.5,.75)
  offsets<-c(-.3,-.1,0,.2,.4)
  cc<-rbind(c(.2,.4,.6,.8),c(-.1,.1,.3,.5))
  cs<-rbind(c(.1,.2,.15,.25),c(.2,.1,0,.12))
  sensitivity<-rbind(c(1,2,1.5,1),c(.3,.2,100,2))
  coefficient_draws<-array(0,c(5L,2L,4L))
  for(b in seq_along(offsets))
    coefficient_draws[b,,]<-cc+offsets[b]*sensitivity
  reference<-list(time=time,family=family,
    coefficient_names=c("Intercept","treatment"),
    coefficient_functions=cc,coefficient_standard_errors=cs)
  coefficient<-list(reference=reference,
    bootstrap_coefficient_functions=coefficient_draws,
    provenance=list(study="typed-generalized-band"))
  center<-rbind(c(-1,-.5,0,.5),c(.2,.3,.4,.5),c(1,.8,.6,.4))
  se<-rbind(c(.1,.2,.15,.1),c(.12,.2,.25,.3),c(.2,.18,.16,.14))
  psensitivity<-rbind(c(.1,.2,.3,.4),c(.3,.1,.2,.4),c(.5,.4,.3,.2))
  prediction_draws<-array(0,c(5L,3L,4L))
  for(b in seq_along(offsets))
    prediction_draws[b,,]<-center+offsets[b]*psensitivity
  prediction<-list(reference=reference,
    profile_ids=c("base","treatment","out_of_range"),
    linear_predictor_functions=center,
    linear_predictor_standard_errors=se)
  fixed_profile<-list(prediction=prediction,
    bootstrap_linear_predictor_functions=prediction_draws,
    provenance=list(study="typed-generalized-band"))
  list(coefficient=coefficient,fixed_profile=fixed_profile)
}

test_that("source coefficient family law masks zero-SE but retains all numerical fields",{
  f<-.etr_two_gfosr_band_source_fixture()
  a<-etr_generalized_function_on_scalar_simultaneous_bands(
    f$coefficient,confidence_level=.75,simultaneous_scope="coefficient")
  b<-etr_generalized_function_on_scalar_simultaneous_bands(
    f$coefficient,confidence_level=.75,simultaneous_scope="family")
  expect_identical(names(a),c("reference","lower","upper",
    "critical_values","max_statistics","confidence_level",
    "simultaneous_scope","bootstrap","provenance"))
  expect_identical(dim(a$max_statistics),c(5L,2L))
  expect_identical(dim(b$max_statistics),c(5L,1L))
  expect_identical(dim(a$lower),c(2L,4L))
  expect_equal(a$lower[2L,3L],.3,tolerance=0)
  expect_equal(a$upper[2L,3L],.3,tolerance=0)
  expect_true(all(b$critical_values>=a$critical_values))
  expect_identical(a$provenance$study,"typed-generalized-band")
  expect_identical(a$provenance$
    generalized_function_on_scalar_simultaneous_band$
    coefficient_scale,"link")
})

test_that("source profile and family band laws preserve monotone inverse links",{
  for(family in c("binomial","poisson")){
    f<-.etr_two_gfosr_band_source_fixture(family)
    a<-etr_generalized_function_on_scalar_prediction_bands(
      f$fixed_profile,confidence_level=.75,simultaneous_scope="profile")
    b<-etr_generalized_function_on_scalar_prediction_bands(
      f$fixed_profile,confidence_level=.75,simultaneous_scope="family")
    expect_identical(names(a),c("prediction","linear_lower",
      "linear_upper","mean_lower","mean_upper","critical_values",
      "max_statistics","confidence_level","simultaneous_scope",
      "bootstrap","provenance"))
    expect_identical(dim(a$max_statistics),c(5L,3L))
    expect_identical(dim(b$max_statistics),c(5L,1L))
    expect_identical(dim(a$mean_lower),c(3L,4L))
    expect_true(all(a$linear_lower<=a$linear_upper))
    expect_true(all(b$critical_values>=a$critical_values))
    if(family=="binomial"){
      expect_true(all(a$mean_lower>0 & a$mean_upper<1))
      expect_equal(a$mean_lower,plogis(a$linear_lower),tolerance=1e-14)
    }else{
      expect_true(all(a$mean_lower>0))
      expect_equal(a$mean_upper,exp(a$linear_upper),tolerance=1e-12)
    }
    expect_identical(a$provenance$study,"typed-generalized-band")
    expect_false(a$provenance$
      generalized_function_on_scalar_prediction_band$
      between_grid_coverage_claim)
  }
})

test_that("source generalized band invalid scientific and inference domains fail closed",{
  z<-.etr_two_gfosr_band_source_fixture()
  bad<-z$coefficient
  bad$reference$coefficient_standard_errors[1L,1L]<--.1
  expect_error(etr_generalized_function_on_scalar_simultaneous_bands(bad),
    "nonnegative")
  bad<-z$fixed_profile
  bad$prediction$linear_predictor_standard_errors[1L,1L]<-0
  expect_error(etr_generalized_function_on_scalar_prediction_bands(bad),
    "strictly positive")
  bad<-z$fixed_profile
  bad$bootstrap_linear_predictor_functions<-array(0,c(5L,4L,4L))
  expect_error(etr_generalized_function_on_scalar_prediction_bands(bad),
    "B-by-profile-by-time")
  expect_error(etr_generalized_function_on_scalar_simultaneous_bands(
    z$coefficient,confidence_level=1),"confidence_level")
  expect_error(etr_generalized_function_on_scalar_prediction_bands(
    z$fixed_profile,confidence_level=0),"confidence_level")
  expect_error(etr_generalized_function_on_scalar_simultaneous_bands(
    z$coefficient,simultaneous_scope="grid"),"simultaneous_scope")
  expect_error(etr_generalized_function_on_scalar_prediction_bands(
    z$fixed_profile,simultaneous_scope="grid"),"simultaneous_scope")
})

test_that("complete frozen typed Python 1.2 generalized bands match R field by field",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python full typed generalized band oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
def _src_band_obj(cls,**attrs):
    obj=object.__new__(cls)
    for key,value in attrs.items():
        object.__setattr__(obj,key,value)
    return obj
_src_time=np.array([0.,.25,.5,.75])
_src_offsets=np.array([-.3,-.1,0.,.2,.4])
_src_coef_center=np.array([[.2,.4,.6,.8],[-.1,.1,.3,.5]])
_src_coef_se=np.array([[.1,.2,.15,.25],[.2,.1,0.,.12]])
_src_coef_sensitivity=np.array([[1.,2.,1.5,1.],[.3,.2,100.,2.]])
_src_coef_draws=np.stack([_src_coef_center+o*_src_coef_sensitivity
                           for o in _src_offsets])
_src_cfit=_src_band_obj(et.GeneralizedFunctionOnScalarResult,
    time=_src_time,family='binomial',
    coefficient_names=('Intercept','treatment'),
    coefficient_functions=_src_coef_center,
    coefficient_standard_errors=_src_coef_se)
_src_cboot=_src_band_obj(et.GeneralizedFunctionOnScalarBootstrapResult,
    reference=_src_cfit,bootstrap_coefficient_functions=_src_coef_draws,
    provenance={'study':'typed-generalized-band'})
_src_cresult={scope:et.generalized_function_on_scalar_simultaneous_bands(
    _src_cboot,confidence_level=.75,simultaneous_scope=scope)
    for scope in ('coefficient','family')}
_src_pred_center=np.array([[-1.,-.5,0.,.5],[.2,.3,.4,.5],[1.,.8,.6,.4]])
_src_pred_se=np.array([[.1,.2,.15,.1],[.12,.2,.25,.3],[.2,.18,.16,.14]])
_src_pred_sensitivity=np.array([[.1,.2,.3,.4],[.3,.1,.2,.4],[.5,.4,.3,.2]])
_src_pred_draws=np.stack([_src_pred_center+o*_src_pred_sensitivity
                           for o in _src_offsets])
_src_presult={}
for _family in ('binomial','poisson'):
    _fit=_src_band_obj(et.GeneralizedFunctionOnScalarResult,
                      time=_src_time,family=_family)
    _pred=_src_band_obj(et.GeneralizedFunctionOnScalarPredictionResult,
        reference=_fit,profile_ids=('base','treatment','out_of_range'),
        linear_predictor_functions=_src_pred_center,
        linear_predictor_standard_errors=_src_pred_se)
    _boot=_src_band_obj(et.GeneralizedFunctionOnScalarPredictionBootstrapResult,
        prediction=_pred,bootstrap_linear_predictor_functions=_src_pred_draws,
        provenance={'study':'typed-generalized-band'})
    for _scope in ('profile','family'):
        _src_presult[(_family,_scope)]=(
            et.generalized_function_on_scalar_prediction_bands(
                _boot,confidence_level=.75,simultaneous_scope=_scope))
")
  z<-.etr_two_gfosr_band_source_fixture()
  for(scope in c("coefficient","family")){
    native<-etr_generalized_function_on_scalar_simultaneous_bands(
      z$coefficient,confidence_level=.75,simultaneous_scope=scope)
    py<-reticulate::py_eval(paste0("_src_cresult['",scope,"']"),
      convert=FALSE)
    for(field in setdiff(names(native),c("reference","bootstrap",
      "provenance"))) {
      expect_equal(native[[field]],
        et_to_r(reticulate::py_get_attr(py,field)),
        tolerance=2e-12,ignore_attr=TRUE,info=paste("coefficient",scope,field))
    }
    expect_equal(native$provenance,
      et_to_r(reticulate::py_get_attr(py,"provenance")),
      ignore_attr=TRUE)
    expect_equal(native$reference$coefficient_functions,
      et_to_r(reticulate::py_get_attr(
        reticulate::py_get_attr(py,"reference"),"coefficient_functions")),
      tolerance=0,ignore_attr=TRUE)
  }
  for(family in c("binomial","poisson")){
    x<-.etr_two_gfosr_band_source_fixture(family)
    for(scope in c("profile","family")){
      native<-etr_generalized_function_on_scalar_prediction_bands(
        x$fixed_profile,confidence_level=.75,simultaneous_scope=scope)
      py<-reticulate::py_eval(
        paste0("_src_presult[('",family,"','",scope,"')]"),
        convert=FALSE)
      for(field in setdiff(names(native),c("prediction","bootstrap",
        "provenance"))){
        expect_equal(native[[field]],
          et_to_r(reticulate::py_get_attr(py,field)),
          tolerance=2e-12,ignore_attr=TRUE,
          info=paste("prediction",family,scope,field))
      }
      expect_equal(native$provenance,
        et_to_r(reticulate::py_get_attr(py,"provenance")),
        ignore_attr=TRUE)
      expect_equal(native$prediction$linear_predictor_functions,
        et_to_r(reticulate::py_get_attr(
          reticulate::py_get_attr(py,"prediction"),
          "linear_predictor_functions")),
        tolerance=0,ignore_attr=TRUE)
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
