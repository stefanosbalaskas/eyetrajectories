# Frozen published Python 1.2.0: functional_mixed_effects_full_refit.py
.etr_compare_mixed_bootstrap_fixture<-function(){
  fit<-list(time=c(0,.5,1),
    coefficient_names=c("Intercept","dose"),
    coefficient_functions=rbind(c(.3,.4,.6),c(-.1,.2,.3)))
  draws<-array(NA_real_,c(4L,2L,3L))
  draws[1L,,]<-rbind(c(.1,.2,.3),c(.0,.1,.2))
  draws[2L,,]<-rbind(c(.2,.4,.5),c(-.2,.2,.3))
  draws[3L,,]<-rbind(c(.4,.6,.7),c(-.1,.4,.5))
  draws[4L,,]<-rbind(c(.5,.5,.9),c(.1,.2,.7))
  base<-list(reference=fit,bootstrap_coefficient_functions=draws,
    bootstrap_mean=rbind(c(.25,.35,.45),c(-.05,.15,.25)),
    bootstrap_standard_errors=rbind(c(.1,.15,.2),c(.15,.1,.1)),
    provenance=list(source="retained"))
  fixed<-base;fixed$bootstrap_type<-"conditional_covariance"
  full<-base;full$bootstrap_type<-"full_refit"
  full$bootstrap_standard_errors<-base$bootstrap_standard_errors*1.25
  list(fixed=fixed,full=full)
}
test_that("retained conditional/full-refit comparison follows source row order",{
  z<-.etr_compare_mixed_bootstrap_fixture()
  a<-etr_compare_functional_mixed_effects_bootstraps(z$fixed,z$full,
    confidence_level=.5,simultaneous_scope="coefficient")
  expect_identical(nrow(a),6L)
  expect_identical(names(a),c("coefficient","time",
    "fixed_covariance_band_width","full_refit_band_width",
    "full_refit_to_fixed_covariance_width_ratio","confidence_level",
    "simultaneous_scope"))
  expect_identical(a$coefficient,rep(c("Intercept","dose"),each=3L))
  expect_equal(a$time,rep(c(0,.5,1),2L))
  expect_true(all(is.finite(a$fixed_covariance_band_width)))
  expect_true(all(is.finite(a$full_refit_band_width)))
  expect_equal(a$full_refit_to_fixed_covariance_width_ratio,
    a$full_refit_band_width/a$fixed_covariance_band_width)
  family<-etr_compare_functional_mixed_effects_bootstraps(z$fixed,z$full,
    confidence_level=.5,simultaneous_scope="family")
  expect_identical(nrow(family),6L)
  expect_identical(unique(family$simultaneous_scope),"family")
})
test_that("zero-width fixed covariance bands produce source-defined infinite ratios",{
  z<-.etr_compare_mixed_bootstrap_fixture()
  for(b in seq_len(dim(z$fixed$bootstrap_coefficient_functions)[1L]))
    z$fixed$bootstrap_coefficient_functions[b,,]<-z$fixed$bootstrap_mean
  a<-etr_compare_functional_mixed_effects_bootstraps(z$fixed,z$full,
    confidence_level=.5)
  expect_true(all(a$fixed_covariance_band_width==0))
  expect_true(all(a$full_refit_band_width>0))
  expect_true(all(is.infinite(a$full_refit_to_fixed_covariance_width_ratio)))
})

test_that("bootstrap comparison refuses mismatched reference or provenance",{
  z<-.etr_compare_mixed_bootstrap_fixture()
  bad<-z$full;bad$reference$time[2L]<-.6
  expect_error(etr_compare_functional_mixed_effects_bootstraps(z$fixed,bad),
    "both bootstrap objects must share the exact reference fit",fixed=TRUE)
  bad<-z$full;bad$bootstrap_type<-"conditional_covariance"
  expect_error(etr_compare_functional_mixed_effects_bootstraps(z$fixed,bad),
    "full-refit bootstrap")
  bad<-z$fixed;bad$bootstrap_type<-NULL
  expect_error(etr_compare_functional_mixed_effects_bootstraps(bad,z$full),
    "bootstrap_type")
  expect_error(etr_compare_functional_mixed_effects_bootstraps(
    z$fixed,z$full,simultaneous_scope="unknown"),"simultaneous_scope")
})
test_that("frozen Python 1.2.0 conditional/full-refit bootstrap width oracle matches",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python conditional versus full-refit comparison is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
def _cm_obj(cls,**kw):
    o=object.__new__(cls)
    for k,v in kw.items():object.__setattr__(o,k,v)
    return o
_cm_fit=_cm_obj(et.FunctionalMixedEffectsResult,
    time=np.array([0.,.5,1.]),
    coefficient_names=('Intercept','dose'),
    coefficient_functions=np.array([[.3,.4,.6],[-.1,.2,.3]]))
_cm_draws=np.array([
 [[.1,.2,.3],[.0,.1,.2]],
 [[.2,.4,.5],[-.2,.2,.3]],
 [[.4,.6,.7],[-.1,.4,.5]],
 [[.5,.5,.9],[.1,.2,.7]]])
_cm_base=dict(reference=_cm_fit,
    bootstrap_coefficient_functions=_cm_draws,
    bootstrap_mean=np.array([[.25,.35,.45],[-.05,.15,.25]]),
    bootstrap_standard_errors=np.array([[.1,.15,.2],[.15,.1,.1]]),
    provenance={'source':'retained'})
_cm_fixed=_cm_obj(et.FunctionalMixedEffectsBootstrapResult,**_cm_base)
_cm_full=_cm_obj(et.FunctionalMixedEffectsFullRefitBootstrapResult,
    **dict(_cm_base,bootstrap_standard_errors=
      _cm_base['bootstrap_standard_errors']*1.25))
_cm_comparison={
  scope:et.compare_functional_mixed_effects_bootstraps(
    _cm_fixed,_cm_full,confidence_level=.5,simultaneous_scope=scope)
    for scope in ('coefficient','family')}
_cm_zero_draws=np.broadcast_to(
    _cm_base['bootstrap_mean'],_cm_draws.shape).copy()
_cm_zero=_cm_obj(et.FunctionalMixedEffectsBootstrapResult,
    **dict(_cm_base,bootstrap_coefficient_functions=_cm_zero_draws))
_cm_zero_ratio=et.compare_functional_mixed_effects_bootstraps(
    _cm_zero,_cm_full,confidence_level=.5
)['full_refit_to_fixed_covariance_width_ratio'].to_numpy()
")
  expect_true(all(is.infinite(as.numeric(reticulate::py_eval(
    "_cm_zero_ratio",convert=TRUE)))))
  z<-.etr_compare_mixed_bootstrap_fixture()
  for(scope in c("coefficient","family")){
    actual<-etr_compare_functional_mixed_effects_bootstraps(z$fixed,z$full,
      confidence_level=.5,simultaneous_scope=scope)
    py<-reticulate::py_to_r(reticulate::py_eval(paste0(
      "_cm_comparison['",scope,"']"),convert=FALSE))
    expect_identical(names(actual),names(py))
    for(field in names(actual)){
      if(is.numeric(actual[[field]]))
        expect_equal(actual[[field]],as.numeric(py[[field]]),
          tolerance=1e-12,info=paste(scope,field))
      else
        expect_identical(as.character(actual[[field]]),
          as.character(py[[field]]))
    }
  }
})
