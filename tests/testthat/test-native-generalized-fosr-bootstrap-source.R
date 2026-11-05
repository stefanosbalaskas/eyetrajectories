# Source: eyetrajectoriespy==1.2.0 fixed-profile bootstrap source.
.etr_gfosr_bootstrap_fixture<-function(family="binomial",exposed=FALSE){
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
  draws<-array(NA_real_,c(4L,2L,3L))
  draws[1L,,]<-rbind(c(.10,.20,.25),c(.35,.55,.65))
  draws[2L,,]<-rbind(c(.22,.26,.32),c(.48,.58,.68))
  draws[3L,,]<-rbind(c(.27,.29,.38),c(.51,.59,.73))
  draws[4L,,]<-rbind(c(.32,.36,.42),c(.65,.80,.85))
  list(bootstrap=list(reference=fit,
    bootstrap_coefficient_functions=draws,
    provenance=list(source="retained")),profiles=profiles)
}

test_that("fixed participant coefficient draws project without resampling",{
  z<-.etr_gfosr_bootstrap_fixture()
  p<-etr_bootstrap_generalized_function_on_scalar_predictions(
    z$bootstrap,z$profiles)
  expect_identical(dim(p$bootstrap_linear_predictor_functions),c(4L,3L,3L))
  expect_equal(p$bootstrap_linear_predictor_functions[1L,2L,],
    c(.45,.75,.9))
  expect_equal(p$bootstrap_mean_functions,
    plogis(p$bootstrap_linear_predictor_functions))
  expect_true(is.null(p$bootstrap_rate_functions))
  expect_true(is.null(p$bootstrap_expected_count_functions))
  expect_identical(p$prediction$extrapolation_flags,c(FALSE,FALSE,TRUE))
  expect_true(p$provenance$
    generalized_function_on_scalar_prediction_bootstrap$
    same_participant_draws_as_coefficient_bootstrap)
})

test_that("Poisson exposure changes counts but never rate estimands",{
  z<-.etr_gfosr_bootstrap_fixture("poisson",TRUE)
  a<-etr_bootstrap_generalized_function_on_scalar_predictions(
    z$bootstrap,z$profiles)
  b<-etr_bootstrap_generalized_function_on_scalar_predictions(
    z$bootstrap,z$profiles,prediction_scale="expected_count",
    exposure_profiles=c(2,3,4))
  expect_equal(a$bootstrap_rate_functions,b$bootstrap_rate_functions)
  expect_equal(b$bootstrap_expected_count_functions,
    b$bootstrap_mean_functions)
  expect_equal(b$bootstrap_mean_functions[1L,,],
    matrix(a$bootstrap_mean_functions[1L,,],3,3)*
      matrix(rep(c(2,3,4),each=3L),3,byrow=TRUE))
})

test_that("profile versus family max bands use NumPy higher quantiles",{
  z<-.etr_gfosr_bootstrap_fixture()
  b<-etr_bootstrap_generalized_function_on_scalar_predictions(
    z$bootstrap,z$profiles)
  x<-etr_generalized_function_on_scalar_prediction_bands(
    b,confidence_level=.5,simultaneous_scope="profile")
  y<-etr_generalized_function_on_scalar_prediction_bands(
    b,confidence_level=.5,simultaneous_scope="family")
  expect_identical(dim(x$max_statistics),c(4L,3L))
  expect_identical(dim(y$max_statistics),c(4L,1L))
  expect_identical(length(x$critical_values),3L)
  expect_true(all(y$critical_values==y$critical_values[1L]))
  expect_true(all(y$critical_values>=x$critical_values))
  expect_equal(x$mean_lower,plogis(x$linear_lower))
  expect_equal(x$mean_upper,plogis(x$linear_upper))
  f<-etr_generalized_function_on_scalar_prediction_frame(x)
  expect_identical(nrow(f),9L)
  expect_identical(tail(names(f),5L),c("linear_lower",
    "linear_upper","mean_lower","mean_upper","critical_value"))
  # For B=4, NumPy higher 50th percentile uses the 3rd order statistic.
  v<-c(0,.2,.4,.9)
  expect_equal(.etr_gfosr_numpy_higher(v,.5),.4)
})

test_that("new native prediction inference fails closed on unsupported support",{
  z<-.etr_gfosr_bootstrap_fixture()
  bad<-z$bootstrap
  bad$bootstrap_coefficient_functions<-array(1,c(3L,3L,3L))
  expect_error(etr_bootstrap_generalized_function_on_scalar_predictions(
    bad,z$profiles),"bootstrap_coefficient_functions")
  b<-etr_bootstrap_generalized_function_on_scalar_predictions(
    z$bootstrap,z$profiles)
  bad<-b
  bad$prediction$linear_predictor_standard_errors[1L,1L]<-0
  expect_error(etr_generalized_function_on_scalar_prediction_bands(bad),
    "strictly positive")
  expect_error(etr_generalized_function_on_scalar_prediction_bands(
    b,simultaneous_scope="all"),"simultaneous_scope")
  expect_error(etr_generalized_function_on_scalar_prediction_bands(
    b,confidence_level=1),"confidence_level")
})

test_that("frozen Python 1.2 reproduces retained bootstrap projections and bands",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 fixed-profile bootstrap source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as et
def _boot_source_obj(cls,**kw):
    x=object.__new__(cls)
    for key,value in kw.items(): object.__setattr__(x,key,value)
    return x
_boot_fit_base=dict(time=np.array([0.,.5,1.]),
    predictor_names=('treatment',),
    basis=np.array([[1.,0.],[1.,.5],[1.,1.]]),
    basis_coefficients=np.array([[.2,.1],[.5,.25]]),
    parameter_covariance=np.diag([.04,.01,.09,.04]),
    scalar_design_matrix=np.array([[1.,0.],[1.,1.]]),
    provenance={'audit':'frozen'})
_boot_profiles=pd.DataFrame({'profile_id':['A','B','C'],
    'treatment':[0.,1.,2.]})
_boot_coef=np.array([
  [[.10,.20,.25],[.35,.55,.65]],
  [[.22,.26,.32],[.48,.58,.68]],
  [[.27,.29,.38],[.51,.59,.73]],
  [[.32,.36,.42],[.65,.80,.85]]
])
_boot_oracles={}
_boot_inputs={}
for _family,_exposed,_kind in [
    ('binomial',False,'binomial'),
    ('poisson',False,'poisson'),
    ('poisson',True,'poisson_rate'),
    ('poisson',True,'poisson_count')]:
    _fit=_boot_source_obj(et.GeneralizedFunctionOnScalarResult,
        **_boot_fit_base,family=_family,
        link='logit' if _family=='binomial' else 'log',
        exposure=np.ones((2,3)) if _exposed else None)
    _bootstrap=_boot_source_obj(et.GeneralizedFunctionOnScalarBootstrapResult,
        reference=_fit,bootstrap_coefficient_functions=_boot_coef,
        provenance={'source':'retained'})
    _extra={'prediction_scale':'expected_count',
        'exposure_profiles':np.array([2.,3.,4.])} if _kind=='poisson_count' else {}
    _boot_inputs[_kind]=_bootstrap
    _result=et.bootstrap_generalized_function_on_scalar_predictions(
        _bootstrap,_boot_profiles,**_extra)
    _profile=et.generalized_function_on_scalar_prediction_bands(
        _result,confidence_level=.5,simultaneous_scope='profile')
    _family_band=et.generalized_function_on_scalar_prediction_bands(
        _result,confidence_level=.5,simultaneous_scope='family')
    _boot_oracles[_kind]=(_result,_profile,_family_band)
")
  for(kind in c("binomial","poisson","poisson_rate","poisson_count")){
    z<-.etr_gfosr_bootstrap_fixture(
      if(kind=="binomial")"binomial" else "poisson",
      exposed=kind%in%c("poisson_rate","poisson_count"))
    b<-if(kind=="poisson_count")
      etr_bootstrap_generalized_function_on_scalar_predictions(
        z$bootstrap,z$profiles,prediction_scale="expected_count",
        exposure_profiles=c(2,3,4)) else
      etr_bootstrap_generalized_function_on_scalar_predictions(
        z$bootstrap,z$profiles)
    # Public frozen Python source export replay on the retained inputs.
    call_args<-list(
      bootstrap=reticulate::py_eval(paste0(
        "_boot_inputs['",kind,"']"),convert=FALSE),
      profiles=reticulate::py_eval("_boot_profiles",convert=FALSE))
    if(identical(kind,"poisson_count")){
      call_args$prediction_scale<-"expected_count"
      call_args$exposure_profiles<-reticulate::py_eval(
        "np.array([2.,3.,4.])",convert=FALSE)
    }
    direct<-do.call(reticulate::py_call,c(list(
      etpy_get_export("bootstrap_generalized_function_on_scalar_predictions")),
      call_args))
    for(field in c("bootstrap_linear_predictor_functions",
      "bootstrap_mean_functions","bootstrap_rate_functions",
      "bootstrap_expected_count_functions")){
      py<-reticulate::py_eval(paste0("_boot_oracles['",kind,
        "'][0].",field),convert=TRUE)
      expect_equal(b[[field]],py,ignore_attr=TRUE,tolerance=1e-10,
        info=paste(kind,field))
      expect_equal(et_to_r(reticulate::py_get_attr(direct,field)),py,
        ignore_attr=TRUE,tolerance=1e-10)
    }
    for(scope in c("profile","family")){
      rb<-etr_generalized_function_on_scalar_prediction_bands(
        b,confidence_level=.5,simultaneous_scope=scope)
      direct_band<-reticulate::py_call(
        etpy_get_export("generalized_function_on_scalar_prediction_bands"),
        bootstrap=direct,confidence_level=.5,simultaneous_scope=scope)
      ix<-if(scope=="profile")1L else 2L
      for(field in c("linear_lower","linear_upper",
        "mean_lower","mean_upper","critical_values","max_statistics")){
        py<-reticulate::py_eval(paste0("_boot_oracles['",kind,
          "'][",ix,"].",field),convert=TRUE)
        expect_equal(rb[[field]],py,ignore_attr=TRUE,tolerance=1e-10,
          info=paste(kind,scope,field))
        expect_equal(et_to_r(reticulate::py_get_attr(direct_band,field)),
          py,ignore_attr=TRUE,tolerance=1e-10)
      }
    }
  }
})
