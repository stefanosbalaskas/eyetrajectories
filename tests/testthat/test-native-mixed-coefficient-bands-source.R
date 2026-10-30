.etr_mixed_band_fixture <- function(kind="conditional_covariance") {
  fit<-list(time=c(0,.5,1),
    coefficient_names=c("Intercept","dose"),
    coefficient_functions=rbind(c(.3,.4,.6),c(-.1,.2,.3)))
  draws<-array(NA_real_,c(4L,2L,3L))
  draws[1L,,]<-rbind(c(.1,.2,.3),c(.0,.1,.2))
  draws[2L,,]<-rbind(c(.2,.4,.5),c(-.2,.2,.3))
  draws[3L,,]<-rbind(c(.4,.6,.7),c(-.1,.4,.5))
  draws[4L,,]<-rbind(c(.5,.5,.9),c(.1,.2,.7))
  list(reference=fit,bootstrap_coefficient_functions=draws,
    bootstrap_mean=rbind(c(.25,.35,.45),c(-.05,.15,.25)),
    bootstrap_standard_errors=rbind(c(.1,.15,.2),c(.15,.1,.1)),
    bootstrap_type=kind,
    provenance=list(draws="retained"))
}
test_that("mixed bands studentize about bootstrap mean and center on fit",{
  b<-.etr_mixed_band_fixture()
  c<-etr_functional_mixed_effects_simultaneous_bands(
    b,confidence_level=.5,simultaneous_scope="coefficient")
  f<-etr_functional_mixed_effects_simultaneous_bands(
    b,confidence_level=.5,simultaneous_scope="family")
  expect_identical(dim(c$max_statistics),c(4L,2L))
  expect_identical(dim(f$max_statistics),c(4L,1L))
  expect_equal(c$max_statistics[1L,1L],
    max(abs(c(.1,.2,.3)-c(.25,.35,.45))/c(.1,.15,.2)))
  expect_true(all(f$critical_values>=c$critical_values))
  expect_equal((c$upper+c$lower)/2,b$reference$coefficient_functions)
  expect_equal(c$pointwise_standard_errors,b$bootstrap_standard_errors)
  expect_false(c$provenance$functional_mixed_effects_simultaneous_bands$
    variance_components_refit)
  b$bootstrap_type<-"full_refit"
  refit<-etr_functional_mixed_effects_simultaneous_bands(b,.5)
  expect_true(refit$provenance$functional_mixed_effects_simultaneous_bands$
    variance_components_refit)
})
test_that("mixed bands reject zero-width uncertainty and unknown bootstrap provenance",{
  b<-.etr_mixed_band_fixture()
  bad<-b;bad$bootstrap_standard_errors[1,2]<-0
  expect_error(etr_functional_mixed_effects_simultaneous_bands(bad),
    "zero-width cells")
  bad<-b;bad$bootstrap_type<-NULL
  expect_error(etr_functional_mixed_effects_simultaneous_bands(bad),
    "bootstrap_type")
  expect_error(etr_functional_mixed_effects_simultaneous_bands(
    b,simultaneous_scope="profile"),"simultaneous_scope")
  expect_error(etr_functional_mixed_effects_simultaneous_bands(
    b,confidence_level=0),"confidence_level")
})
test_that("frozen Python 1.2 source mixed band numerical oracle matches",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published mixed bootstrap band numerical source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import eyetrajectoriespy as et
import numpy as np
def _mb_obj(cls,**kw):
    obj=object.__new__(cls)
    for key,value in kw.items():object.__setattr__(obj,key,value)
    return obj
_mb_fit=_mb_obj(et.FunctionalMixedEffectsResult,
    time=np.array([0.,.5,1.]),
    coefficient_names=('Intercept','dose'),
    coefficient_functions=np.array([[.3,.4,.6],[-.1,.2,.3]]))
_mb_draws=np.array([
 [[.1,.2,.3],[.0,.1,.2]],
 [[.2,.4,.5],[-.2,.2,.3]],
 [[.4,.6,.7],[-.1,.4,.5]],
 [[.5,.5,.9],[.1,.2,.7]]])
_mb_base=dict(reference=_mb_fit,
    bootstrap_coefficient_functions=_mb_draws,
    bootstrap_mean=np.array([[.25,.35,.45],[-.05,.15,.25]]),
    bootstrap_standard_errors=np.array([[.1,.15,.2],[.15,.1,.1]]),
    provenance={'draws':'retained'})
_mb_oracle={}
for kind,klass in [('conditional_covariance',
     et.FunctionalMixedEffectsBootstrapResult),
     ('full_refit',et.FunctionalMixedEffectsFullRefitBootstrapResult)]:
    item=_mb_obj(klass,**_mb_base)
    for scope in ('coefficient','family'):
      _mb_oracle[(kind,scope)]=et.functional_mixed_effects_simultaneous_bands(
          item,confidence_level=.5,simultaneous_scope=scope)
")
  for(kind in c("conditional_covariance","full_refit")){
    b<-.etr_mixed_band_fixture(kind)
    for(scope in c("coefficient","family")){
      a<-etr_functional_mixed_effects_simultaneous_bands(
        b,confidence_level=.5,simultaneous_scope=scope)
      key<-paste0("_mb_oracle[('",kind,"','",scope,"')]")
      for(field in c("lower","upper","critical_values",
        "max_statistics","pointwise_standard_errors")){
        expected<-reticulate::py_eval(paste0(key,".",field),convert=TRUE)
        expect_equal(a[[field]],expected,tolerance=1e-12,
          ignore_attr=TRUE,info=paste(kind,scope,field))
      }
      expected<-reticulate::py_eval(paste0(
        key,".provenance['functional_mixed_effects_simultaneous_bands']",
        "['variance_components_refit']"),convert=TRUE)
      expect_identical(a$provenance$
        functional_mixed_effects_simultaneous_bands$variance_components_refit,
        expected)
    }
  }
})
