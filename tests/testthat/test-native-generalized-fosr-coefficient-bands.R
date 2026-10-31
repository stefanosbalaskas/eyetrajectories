# Source replay: eyetrajectoriespy v1.2.0 generalized FoSR coefficient bands.
.etr_gfosr_coefficient_band_fixture <- function(){
  center<-rbind(c(.2,.4,.6),c(-.1,.3,.5))
  se<-rbind(c(.1,.2,.1),c(.15,.1,0))
  draws<-array(NA_real_,c(4L,2L,3L))
  draws[1L,,]<-rbind(c(.1,.3,.65),c(-.2,.35,10))
  draws[2L,,]<-rbind(c(.3,.5,.7),c(-.1,.2,-12))
  draws[3L,,]<-rbind(c(.25,.4,.9),c(.2,.25,8))
  draws[4L,,]<-rbind(c(.21,.7,.65),c(-.15,.5,-11))
  list(reference=list(time=c(0,.5,1),
    family="binomial",link="logit",
    coefficient_names=c("Intercept","treatment"),
    coefficient_functions=center,
    coefficient_standard_errors=se,provenance=list(fit="retained")),
    bootstrap_coefficient_functions=draws,
    provenance=list(source="whole_participant"))
}

test_that("source link-scale coefficient bands ignore zero SE bootstrap noise",{
  b<-.etr_gfosr_coefficient_band_fixture()
  a<-etr_generalized_function_on_scalar_simultaneous_bands(
    b,confidence_level=.5)
  f<-etr_generalized_function_on_scalar_simultaneous_bands(
    b,confidence_level=.5,simultaneous_scope="family")
  expect_identical(dim(a$max_statistics),c(4L,2L))
  expect_identical(dim(f$max_statistics),c(4L,1L))
  expect_equal(a$max_statistics[1L,],
    c(1,2/3),tolerance=1e-12)
  expect_true(all(f$critical_values>=a$critical_values))
  expect_equal(a$lower[2L,3L],b$reference$coefficient_functions[2L,3L])
  expect_equal(a$upper[2L,3L],b$reference$coefficient_functions[2L,3L])
  expect_true(all(a$lower<=a$upper))
  expect_identical(a$provenance$
    generalized_function_on_scalar_simultaneous_band$
    response_scale_coefficient_band,FALSE)
  expect_identical(a$provenance$source,"whole_participant")
  frame<-etr_generalized_function_on_scalar_coefficient_frame(a)
  expect_identical(nrow(frame),6L)
  expect_equal(frame$lower,as.vector(t(a$lower)))
})

test_that("source coefficient bands fail closed on invalid geometry and scope",{
  b<-.etr_gfosr_coefficient_band_fixture()
  expect_error(etr_generalized_function_on_scalar_simultaneous_bands(
    b,confidence_level=1),"confidence_level")
  expect_error(etr_generalized_function_on_scalar_simultaneous_bands(
    b,simultaneous_scope="profile"),"simultaneous_scope")
  bad<-b;bad$reference$coefficient_standard_errors[2L,2L]<-NA_real_
  expect_error(etr_generalized_function_on_scalar_simultaneous_bands(
    bad),"coefficient_standard_errors")
  bad<-b;bad$bootstrap_coefficient_functions<-array(0,c(2,3,3))
  expect_error(etr_generalized_function_on_scalar_simultaneous_bands(
    bad),"bootstrap_coefficient_functions")
})

test_that("published Python 1.2 numerical coefficient-band oracle matches",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python generalized coefficient-band oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
def _band_obj(cls,**kwargs):
    x=object.__new__(cls)
    for k,v in kwargs.items():object.__setattr__(x,k,v)
    return x
_gbc_center=np.array([[.2,.4,.6],[-.1,.3,.5]])
_gbc_se=np.array([[.1,.2,.1],[.15,.1,0.]])
_gbc_draws=np.array([
  [[.1,.3,.65],[-.2,.35,10.]],
  [[.3,.5,.7],[-.1,.2,-12.]],
  [[.25,.4,.9],[.2,.25,8.]],
  [[.21,.7,.65],[-.15,.5,-11.]]
])
_gbc_fit=_band_obj(et.GeneralizedFunctionOnScalarResult,
    coefficient_names=('Intercept','treatment'),
    coefficient_functions=_gbc_center,
    coefficient_standard_errors=_gbc_se,
    time=np.array([0.,.5,1.]),
    family='binomial',link='logit',
    provenance={'fit':'retained'})
_gbc_boot=_band_obj(et.GeneralizedFunctionOnScalarBootstrapResult,
    reference=_gbc_fit,
    bootstrap_coefficient_functions=_gbc_draws,
    provenance={'source':'whole_participant'})
_gbc_py={s:et.generalized_function_on_scalar_simultaneous_bands(
    _gbc_boot,confidence_level=.5,simultaneous_scope=s)
    for s in ('coefficient','family')}
")
  direct<-list(
    coefficient=reticulate::py_call(
      etpy_get_export("generalized_function_on_scalar_simultaneous_bands"),
      bootstrap=reticulate::py_eval("_gbc_boot",convert=FALSE),
      confidence_level=.5,simultaneous_scope="coefficient"),
    family=reticulate::py_call(
      etpy_get_export("generalized_function_on_scalar_simultaneous_bands"),
      bootstrap=reticulate::py_eval("_gbc_boot",convert=FALSE),
      confidence_level=.5,simultaneous_scope="family")
  )
  b<-.etr_gfosr_coefficient_band_fixture()
  for(scope in c("coefficient","family")){
    actual<-etr_generalized_function_on_scalar_simultaneous_bands(
      b,confidence_level=.5,simultaneous_scope=scope)
    for(field in c("lower","upper","critical_values","max_statistics")){
      expected<-reticulate::py_eval(paste0("_gbc_py['",scope,
        "'].",field),convert=TRUE)
      expect_equal(actual[[field]],expected,tolerance=1e-12,
        ignore_attr=TRUE,info=paste(scope,field))
      expect_equal(et_to_r(reticulate::py_get_attr(direct[[scope]],field)),
        expected,tolerance=1e-12,ignore_attr=TRUE)
    }
    expected<-reticulate::py_eval(paste0(
      "_gbc_py['",scope,"'].provenance"),convert=TRUE)
    expect_identical(actual$provenance$
      generalized_function_on_scalar_simultaneous_band$
      calibration,expected$
      generalized_function_on_scalar_simultaneous_band$calibration)
  }
})
