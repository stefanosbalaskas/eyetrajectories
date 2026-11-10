# Frozen Python 1.2 reporting.py: source text and Python !r labels.
.etr_mixed_report_string_fixture<-function(){
  list(predictor_names="dose",boundary_fit=FALSE,
    trial_random_effect=NULL,random_effect_singular=FALSE,
    trial_random_effect_singular=FALSE,
    random_effect_complexity_warning=FALSE,
    residual_correlation_boundary_fit=FALSE,
    residual_correlation_independence_limit_fit=FALSE,
    backend_warnings=character(),random_slope_predictor=NULL,
    random_basis_size=3L,residual_correlation="iid",dimension_name="x",
    fixed_basis_size=4L,spline_degree=3L,n_curves=8L,
    n_participants=4L,reml=TRUE,method="lbfgs",
    random_effect_covariance_condition_number=7.123)
}

test_that("native mixed report accepts Python text label boundary cases", {
  x<-.etr_mixed_report_string_fixture()
  cases<-list(
    list(dim="channel'left",method='both"quotes',slope=NULL,
      predictor="dose"),
    list(dim="a\\b\nc",method="β😀",slope="dose'\\group",
      predictor="dose\nper participant"),
    list(dim="α\u00a0\u200b",method="x\u2028y",slope='a"b',
      predictor="ζ-Δ"),
    list(dim="\tseparated",method="x\\path",slope=NULL,
      predictor="β"))
  for(case in cases){
    x$dimension_name<-case$dim
    x$method<-case$method
    x$predictor_names<-case$predictor
    x["random_slope_predictor"]<-list(case$slope)
    if(!is.null(case$slope)){
      x$random_effect_dimension<-6L
      x$random_effect_covariance_parameter_count<-21L
    }
    report<-etr_functional_mixed_effects_reporting_text(x)
    expect_true(grepl(case$predictor,report,fixed=TRUE))
    expect_true(grepl("Gaussian functional mixed-effects regression",report,
      fixed=TRUE))
  }
})

test_that("mixed report repr agrees with real frozen Python 1.2 source", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 mixed reporting oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import eyetrajectoriespy as et
import numpy as np
def _mixed_string_source(dimname, method, slope, predictor, kind):
    fit = object.__new__(et.FunctionalMixedEffectsResult)
    fields = dict(
        predictor_names=(predictor,),boundary_fit=False,
        trial_random_effect=None,random_effect_singular=False,
        trial_random_effect_singular=False,
        random_effect_complexity_warning=False,
        residual_correlation_boundary_fit=False,
        residual_correlation_independence_limit_fit=False,
        backend_warnings=(),random_slope_predictor=slope,
        random_basis_size=3,residual_correlation='iid',
        dimension_name=dimname,fixed_basis_size=4,spline_degree=3,
        source_curve_ids=tuple('c'+str(i) for i in range(8)),
        participant_ids=tuple('p'+str(i) for i in range(4)),
        reml=True,method=method,
        random_effect_covariance_condition_number=7.123)
    if slope is not None:
        fields['random_effect_dimension'] = 6
        fields['random_effect_covariance_parameter_count'] = 21
    for k,v in fields.items():object.__setattr__(fit,k,v)
    if kind == 'none':
        return et.functional_mixed_effects_reporting_text(fit)
    cls=(et.FunctionalMixedEffectsFullRefitBootstrapResult if kind=='full_refit'
         else et.FunctionalMixedEffectsBootstrapResult)
    boot=object.__new__(cls)
    object.__setattr__(boot,'bootstrap_coefficient_functions',np.zeros((4,1,2)))
    band=object.__new__(et.FunctionalMixedEffectsBandResult)
    for k,v in dict(reference=fit,bootstrap=boot,
        confidence_level=.95,simultaneous_scope='family').items():
        object.__setattr__(band,k,v)
    return et.functional_mixed_effects_reporting_text(fit,band=band)
")
  cases<-list(
    list(dim="channel'left",method='both"quotes',slope=NULL,
      predictor="dose"),
    list(dim="a\\b\nc",method="β😀",slope="dose'\\group",
      predictor="dose\nper participant"),
    list(dim="α\u00a0\u200b",method="x\u2028y",slope='a"b',
      predictor="ζ-Δ"),
    list(dim="\tseparated",method="x\\path",slope=NULL,
      predictor="β"))
  for(case in cases) for(kind in c("none","conditional_covariance","full_refit")){
    fit<-.etr_mixed_report_string_fixture()
    fit$dimension_name<-case$dim
    fit$method<-case$method
    fit["random_slope_predictor"]<-list(case$slope)
    fit$predictor_names<-case$predictor
    if(!is.null(case$slope)){
      fit$random_effect_dimension<-6L
      fit$random_effect_covariance_parameter_count<-21L
    }
    band<-NULL
    if(kind!="none")band<-list(reference=fit,confidence_level=.95,
      simultaneous_scope="family",
      bootstrap=list(bootstrap_type=kind,
        bootstrap_coefficient_functions=array(0,c(4L,1L,2L))))
    native<-etr_functional_mixed_effects_reporting_text(fit,band)
    source<-reticulate::py_call(reticulate::py_get_attr(reticulate::py,
      "_mixed_string_source"),
      case$dim,case$method,case$slope,case$predictor,kind)
    expect_identical(native,as.character(reticulate::py_to_r(source)),
      info=paste(kind,case$dim,case$method))
  }
})
