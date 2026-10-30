.etr_mixed_text_fixture<-function(){
  list(predictor_names=c("dose"),boundary_fit=FALSE,
    trial_random_effect=NULL,random_effect_singular=FALSE,
    trial_random_effect_singular=FALSE,
    random_effect_complexity_warning=FALSE,
    residual_correlation_boundary_fit=FALSE,
    residual_correlation_independence_limit_fit=FALSE,
    backend_warnings=character(),
    random_slope_predictor=NULL,random_basis_size=3L,
    residual_correlation="iid",dimension_name="x",
    fixed_basis_size=4L,spline_degree=3L,n_curves=8L,
    n_participants=4L,reml=TRUE,method="lbfgs",
    random_effect_covariance_condition_number=7.123)
}
test_that("source-shaped mixed-effect manuscript wording does not overclaim",{
  x<-.etr_mixed_text_fixture()
  t<-etr_functional_mixed_effects_reporting_text(x)
  expect_true(is.character(t)&&length(t)==1L)
  expect_match(t,"Gaussian functional mixed-effects regression",fixed=TRUE)
  expect_match(t,"REML using optimizer 'lbfgs'",fixed=TRUE)
  expect_match(t,"condition number was 7.12",fixed=TRUE)
  expect_match(t,"pointwise Wald intervals",fixed=TRUE)
  expect_match(t,"simultaneous functional coverage",fixed=TRUE)
  expect_false(grepl("full-refit participant bootstrap",t,fixed=TRUE))
  expect_error(etr_functional_mixed_effects_reporting_text(x,band=list()),
    "mixed band")
  bad<-x;bad$boundary_fit<-NA
  expect_error(etr_functional_mixed_effects_reporting_text(bad),
    "boundary_fit")
  bad<-x;bad$n_curves<-2^40
  expect_error(etr_functional_mixed_effects_reporting_text(bad),
    "representable integer")
  bad<-x;bad$residual_correlation<-"ar1"
  bad$residual_correlation_parameter<-NaN
  expect_error(etr_functional_mixed_effects_reporting_text(bad),
    "residual_correlation_parameter")
})
test_that("mixed source report preserves warnings and declared covariance",{
  x<-.etr_mixed_text_fixture()
  x$boundary_fit<-TRUE
  x$random_effect_singular<-TRUE
  x$backend_warnings<-"optimizer warning"
  x$residual_correlation<-"ar1"
  x$residual_correlation_parameter<-.25
  x$random_slope_predictor<-"dose"
  x$random_effect_dimension<-6L
  x$random_effect_covariance_parameter_count<-21L
  t<-etr_functional_mixed_effects_reporting_text(x)
  expect_match(t,"rho=0.25",fixed=TRUE)
  expect_match(t,"stacked 6-dimensional",fixed=TRUE)
  expect_match(t,"numerically singular",fixed=TRUE)
  expect_match(t,"Backend warnings were retained",fixed=TRUE)
  x$trial_random_effect<-"functional_intercept"
  x$n_trials<-8L
  x$trial_random_basis_size<-2L
  x$trial_random_effect_covariance_parameter_count<-3L
  t<-etr_functional_mixed_effects_reporting_text(x)
  expect_match(t,"nested trial-specific",fixed=TRUE)
})
test_that("frozen Python 1.2 mixed report exact strings match the native subset",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published mixed-effect report exact-string oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import eyetrajectoriespy as et
def _mix_obj(cls,**kw):
    x=object.__new__(cls)
    for name,value in kw.items(): object.__setattr__(x,name,value)
    return x
_mix_source=dict(predictor_names=('dose',),
    boundary_fit=False,trial_random_effect=None,
    random_effect_singular=False,trial_random_effect_singular=False,
    random_effect_complexity_warning=False,
    residual_correlation_boundary_fit=False,
    residual_correlation_independence_limit_fit=False,
    backend_warnings=(),random_slope_predictor=None,
    random_basis_size=3,residual_correlation='iid',dimension_name='x',
    fixed_basis_size=4,spline_degree=3,
    source_curve_ids=tuple(f'curve{i}' for i in range(8)),
    participant_ids=tuple(f'participant{i}' for i in range(4)),
    reml=True,method='lbfgs',
    random_effect_covariance_condition_number=7.123)
_mix_py0=et.functional_mixed_effects_reporting_text(
    _mix_obj(et.FunctionalMixedEffectsResult,**_mix_source))
_mix_other=dict(_mix_source)
_mix_other.update(boundary_fit=True,random_effect_singular=True,
    backend_warnings=('optimizer warning',),
    residual_correlation='ar1',residual_correlation_parameter=.25,
    random_slope_predictor='dose',random_effect_dimension=6,
    random_effect_covariance_parameter_count=21,
    trial_random_effect='functional_intercept',
    trial_ids=tuple(f'trial{i}' for i in range(8)),
    trial_random_basis_size=2,
    trial_random_effect_covariance_parameter_count=3)
_mix_py1=et.functional_mixed_effects_reporting_text(
    _mix_obj(et.FunctionalMixedEffectsResult,**_mix_other))
")
  x<-.etr_mixed_text_fixture()
  expect_identical(etr_functional_mixed_effects_reporting_text(x),
    reticulate::py_eval("_mix_py0",convert=TRUE))
  x$boundary_fit<-TRUE;x$random_effect_singular<-TRUE
  x$backend_warnings<-"optimizer warning"
  x$residual_correlation<-"ar1";x$residual_correlation_parameter<-.25
  x$random_slope_predictor<-"dose"
  x$random_effect_dimension<-6L
  x$random_effect_covariance_parameter_count<-21L
  x$trial_random_effect<-"functional_intercept"
  x$n_trials<-8L;x$trial_random_basis_size<-2L
  x$trial_random_effect_covariance_parameter_count<-3L
  expect_identical(etr_functional_mixed_effects_reporting_text(x),
    reticulate::py_eval("_mix_py1",convert=TRUE))
})

test_that("native mixed report distinguishes source conditional and full-refit bootstrap wording",{
  x<-.etr_mixed_text_fixture()
  coef<-array(0,c(4L,1L,2L))
  for(kind in c("conditional_covariance","full_refit")){
    band<-list(reference=x,confidence_level=.95,
      simultaneous_scope="family",
      bootstrap=list(bootstrap_type=kind,
        bootstrap_coefficient_functions=coef))
    txt<-etr_functional_mixed_effects_reporting_text(x,band)
    expect_match(txt,"95.0% simultaneous coefficient bands",fixed=TRUE)
    expect_match(txt,"4 whole-participant resamples",fixed=TRUE)
    if(kind=="full_refit"){
      expect_match(txt,"Full-refit participant bootstrap",fixed=TRUE)
      expect_match(txt,"variance-component re-estimation",fixed=TRUE)
    }else{
      expect_match(txt,"Participant-cluster bootstrap",fixed=TRUE)
      expect_match(txt,"were held fixed",fixed=TRUE)
      expect_false(grepl("variance-component re-estimation",txt,fixed=TRUE))
    }
    bad<-band;bad$reference$dimension_name<-"not_same_reference"
    expect_error(etr_functional_mixed_effects_reporting_text(x,bad),
      "band.reference")
  }
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published mixed-model bootstrap wording oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import eyetrajectoriespy as et
import numpy as np
def _mr_obj(cls,**kw):
    x=object.__new__(cls)
    for k,v in kw.items():object.__setattr__(x,k,v)
    return x
_mr_fit=_mr_obj(et.FunctionalMixedEffectsResult,
    predictor_names=('dose',),
    boundary_fit=False,trial_random_effect=None,
    random_effect_singular=False,trial_random_effect_singular=False,
    random_effect_complexity_warning=False,
    residual_correlation_boundary_fit=False,
    residual_correlation_independence_limit_fit=False,
    backend_warnings=(),random_slope_predictor=None,
    random_basis_size=3,residual_correlation='iid',dimension_name='x',
    fixed_basis_size=4,spline_degree=3,
    source_curve_ids=tuple('c'+str(i) for i in range(8)),
    participant_ids=tuple('p'+str(i) for i in range(4)),
    reml=True,method='lbfgs',
    random_effect_covariance_condition_number=7.123)
_mr_py={}
for _k,_cls in [('conditional_covariance',
    et.FunctionalMixedEffectsBootstrapResult),
    ('full_refit',et.FunctionalMixedEffectsFullRefitBootstrapResult)]:
    _boot=_mr_obj(_cls,bootstrap_coefficient_functions=np.zeros((4,1,2)))
    _band=_mr_obj(et.FunctionalMixedEffectsBandResult,
        reference=_mr_fit,bootstrap=_boot,
        confidence_level=.95,simultaneous_scope='family')
    _mr_py[_k]=et.functional_mixed_effects_reporting_text(_mr_fit,band=_band)
")
  for(kind in c("conditional_covariance","full_refit")){
    band<-list(reference=x,confidence_level=.95,
      simultaneous_scope="family",
      bootstrap=list(bootstrap_type=kind,
        bootstrap_coefficient_functions=coef))
    expect_identical(etr_functional_mixed_effects_reporting_text(x,band),
      reticulate::py_eval(paste0("_mr_py['",kind,"']"),convert=TRUE))
  }
})
