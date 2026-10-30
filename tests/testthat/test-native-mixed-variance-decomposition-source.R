# Published source: eyetrajectoriespy==1.2.0
# functional_mixed_effects_covariance_sensitivity.py.
# The fit is a typed Python result, not the restricted native moments class.
.etr_variance_source_fixture <- function(slope=TRUE,trial=TRUE){
  grid<-c(0,.5,1)
  B<-cbind(rep(1,3L),grid)
  list(time=grid,random_basis=B,
    random_intercept_covariance=diag(c(.4,.2)),
    random_slope_covariance=if(slope)diag(c(.1,.3)) else NULL,
    random_intercept_slope_covariance=if(slope)
      matrix(c(-.05,.02,.01,-.04),2L,2L) else NULL,
    trial_random_effect=if(trial)"functional_intercept" else NULL,
    trial_random_basis=if(trial)matrix(1,3,1) else NULL,
    trial_random_effect_covariance=if(trial)matrix(.25,1,1) else NULL,
    residual_variance=.08)
}
test_that("source variance decomposition preserves components and signed cross-covariance",{
  fit<-.etr_variance_source_fixture()
  out<-etr_functional_mixed_effects_variance_decomposition(fit,model_label="m")
  expect_identical(names(out),c("model","component","component_type","time","value"))
  expect_identical(nrow(out),15L)
  expect_identical(unique(out$component),c(
    "participant_intercept_variance",
    "participant_slope_variance",
    "participant_intercept_slope_cross_covariance",
    "trial_variance","residual_variance"))
  expect_identical(out$component_type[c(1L,4L,7L,10L,13L)],
    c("variance","variance","covariance","variance","variance"))
  expect_equal(out$value[1:3],c(.4,.45,.6),tolerance=1e-12)
  expect_equal(out$value[4:6],c(.1,.175,.4),tolerance=1e-12)
  expect_equal(out$value[7:9],c(-.05,-.045,-.06),tolerance=1e-12)
  expect_equal(out$value[10:12],rep(.25,3L))
  expect_equal(out$value[13:15],rep(.08,3L))
  expect_true(any(out$value[out$component_type=="covariance"]<0))
})
test_that("source variance decomposition supports univariate intercept-only and rejects invalid structures",{
  fit<-.etr_variance_source_fixture(FALSE,FALSE)
  out<-etr_functional_mixed_effects_variance_decomposition(fit)
  expect_identical(unique(out$component),
    c("participant_intercept_variance","residual_variance"))
  expect_identical(nrow(out),6L)
  bad<-.etr_variance_source_fixture()
  bad$random_intercept_slope_covariance<-NULL
  expect_error(etr_functional_mixed_effects_variance_decomposition(bad),
    "cross-covariance")
  bad<-.etr_variance_source_fixture()
  bad$trial_random_effect_covariance<-NULL
  expect_error(etr_functional_mixed_effects_variance_decomposition(bad),
    "trial random-effect")
  bad<-.etr_variance_source_fixture()
  bad$random_basis<-matrix(1,4,2)
  expect_error(etr_functional_mixed_effects_variance_decomposition(bad),
    "random_basis")
  expect_error(etr_functional_mixed_effects_variance_decomposition(
    fit,model_label=""),"model_label")
})
test_that("frozen Python 1.2 mixed variance rows and numeric values match",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("source variance decomposition Python 1.2 oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
def _v_src(cls,**kw):
    o=object.__new__(cls)
    for k,v in kw.items():object.__setattr__(o,k,v)
    return o
_v_py={}
for slope,trial in ((True,True),(False,False)):
    B=np.column_stack((np.ones(3),np.array([0.,.5,1.])))
    fit=_v_src(et.FunctionalMixedEffectsResult,
      time=np.array([0.,.5,1.]),random_basis=B,
      random_intercept_covariance=np.diag([.4,.2]),
      random_slope_covariance=np.diag([.1,.3]) if slope else None,
      random_intercept_slope_covariance=np.array([[-.05,.01],[.02,-.04]]) if slope else None,
      trial_random_effect='functional_intercept' if trial else None,
      trial_random_basis=np.ones((3,1)) if trial else None,
      trial_random_effect_covariance=np.array([[.25]]) if trial else None,
      residual_variance=.08)
    _v_py[(slope,trial)]=et.functional_mixed_effects_variance_decomposition(
      fit,model_label='m').to_dict(orient='list')
")
  for(full in c(FALSE,TRUE)){
    fit<-.etr_variance_source_fixture(slope=full,trial=full)
    actual<-etr_functional_mixed_effects_variance_decomposition(fit,"m")
    key<-if(full)"_v_py[(True,True)]" else "_v_py[(False,False)]"
    for(field in c("model","component","component_type")){
      expected<-reticulate::py_eval(paste0(key,"['",field,"']"),
        convert=TRUE)
      expect_identical(actual[[field]],as.character(expected))
    }
    for(field in c("time","value")){
      expected<-reticulate::py_eval(paste0(key,"['",field,"']"),
        convert=TRUE)
      expect_equal(actual[[field]],as.numeric(expected),tolerance=1e-12)
    }
  }
})
