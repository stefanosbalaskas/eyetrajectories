# Frozen Python 1.2 source wording (FoSR, covariance and MIAAFT).
.etr_source_text_fixtures <- function() {
  prediction<-list(
    prediction=list(
      profile_ids=c("target","control"),
      extrapolation_flags=c(FALSE,TRUE),
      prediction_scale="rate",
      reference=list(family="poisson",link="log",
        binomial_denominators=NULL)),
    simultaneous_scope="profile")
  difference<-list(
    contrast_scale="rate_ratio",profile_a="target",
    profile_b="control",confidence_level=.95,
    interval_exceeds_physical_bounds=FALSE)
  covariance<-list(
    reference_label="iid",fits=list(iid=1,ar1=2),
    failures=list(exponential="did not converge"),
    provenance=list(
      functional_mixed_effects_covariance_sensitivity=list(
        information_criterion_mode="ML")))
  surrogate<-list(
    n_surrogates=9L,dimension_names=c("x","y"),
    reference_dimension="x",
    spectral_errors=c(.01,.003,.0004),
    cross_spectral_errors=c(.02,.007),
    random_state=123L)
  nonlinear<-list(surrogate_result=surrogate,
    surrogate_statistics=c(.1,.5,.2),p_value=.25,
    statistic="joint_recurrence",alternative="greater")
  list(prediction=prediction,difference=difference,
    covariance=covariance,surrogate=surrogate,nonlinear=nonlinear)
}
test_that("five source-aligned reporting functions preserve statistical claims",{
  z<-.etr_source_text_fixtures()
  a<-etr_generalized_function_on_scalar_prediction_reporting_text(z$prediction)
  expect_match(a,"marginal exposure-adjusted rate")
  expect_match(a,"target.*control",all=FALSE)
  expect_match(a,"scalar-predictor extrapolations: control")
  b<-etr_generalized_function_on_scalar_mean_difference_reporting_text(
    z$difference)
  expect_match(b,"marginal exposure-adjusted rate ratio")
  expect_match(b,"log-rate-ratio scale and exponentiated")
  c<-etr_functional_mixed_effects_covariance_sensitivity_reporting_text(
    z$covariance)
  expect_match(c,"2 declared structure\\(s\\) converged and 1 failed")
  expect_match(c,"No covariance structure was ranked")
  d<-etr_multivariate_iaaft_reporting_text(z$surrogate)
  expect_match(d,"9 multivariate IAAFT surrogates")
  expect_match(d,"maximum relative power-spectrum mismatch=0.01")
  e<-etr_multivariate_surrogate_nonlinearity_reporting_text(z$nonlinear)
  expect_match(e,"statistic was joint recurrence")
  expect_match(e,"not as proof of deterministic chaos")
  expect_false(grepl("stage",paste(deparse(etr_multivariate_iaaft_reporting_text),
    collapse=" "),fixed=TRUE))
})

test_that("new source reporting fails closed on undeclared scientific inputs",{
  z<-.etr_source_text_fixtures()
  bad<-z$prediction;bad$prediction$prediction_scale<-"response"
  expect_error(etr_generalized_function_on_scalar_prediction_reporting_text(bad),
    "prediction_scale")
  bad<-z$prediction;bad$prediction$extrapolation_flags<-TRUE
  expect_error(etr_generalized_function_on_scalar_prediction_reporting_text(bad),
    "extrapolation_flags")
  bad<-z$difference;bad$confidence_level<-1
  expect_error(etr_generalized_function_on_scalar_mean_difference_reporting_text(bad),
    "confidence_level")
  bad<-z$difference;bad$interval_exceeds_physical_bounds<-NA
  expect_error(etr_generalized_function_on_scalar_mean_difference_reporting_text(bad),
    "interval_exceeds_physical_bounds")
  bad<-z$covariance;bad$provenance<-list()
  expect_error(etr_functional_mixed_effects_covariance_sensitivity_reporting_text(bad),
    "provenance")
  bad<-z$surrogate;bad$reference_dimension<-"z"
  expect_error(etr_multivariate_iaaft_reporting_text(bad),
    "reference_dimension")
  bad<-z$surrogate;bad$spectral_errors<-c(.1,NaN)
  expect_error(etr_multivariate_iaaft_reporting_text(bad),
    "spectral_errors")
  bad<-z$nonlinear;bad$surrogate_statistics<-c(1,Inf)
  expect_error(etr_multivariate_surrogate_nonlinearity_reporting_text(bad),
    "surrogate_statistics")
  bad<-z$nonlinear;bad$p_value<-1.5
  expect_error(etr_multivariate_surrogate_nonlinearity_reporting_text(bad),
    "p_value")
})

test_that("five reporting candidates remain unmapped-to-certificate gaps",{
  names<-c("generalized_function_on_scalar_prediction_reporting_text",
    "generalized_function_on_scalar_mean_difference_reporting_text",
    "functional_mixed_effects_covariance_sensitivity_reporting_text",
    "multivariate_iaaft_reporting_text",
    "multivariate_surrogate_nonlinearity_reporting_text")
  p<-etr_native_parity_catalog()
  rows<-p[p$is_python_function & p$python_name%in%names,,drop=FALSE]
  expect_equal(nrow(rows),5L)
  expect_identical(sort(rows$native_r_candidate),sort(paste0("etr_",names)))
  expect_true(all(rows$native_implementation_started))
  expect_true(all(rows$source_contract_gap_unresolved))
  expect_false(any(rows$one_to_one_native_contract_complete))
  expect_equal(sum(p$is_python_function & p$named_native_candidate),319L)
  expect_equal(sum(p$native_implementation_started),294L)
  expect_equal(sum(p$source_contract_gap_unresolved),141L)
})

test_that("five reporting summaries match pinned Python 1.2 exact source strings",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 FoSR/MIAAFT reporting oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
def _st_obj(cls, **fields):
    obj=object.__new__(cls)
    for name,value in fields.items():
        object.__setattr__(obj,name,value)
    return obj
_st_ref=_st_obj(et.GeneralizedFunctionOnScalarResult,
    family='poisson',link='log',binomial_denominators=None)
_st_predict=_st_obj(et.GeneralizedFunctionOnScalarPredictionResult,
    profile_ids=('target','control'),
    extrapolation_flags=np.array([False,True]),
    prediction_scale='rate',reference=_st_ref)
_st_band=_st_obj(et.GeneralizedFunctionOnScalarPredictionBandResult,
    prediction=_st_predict,simultaneous_scope='profile')
_st_diff=_st_obj(et.GeneralizedFunctionOnScalarMeanDifferenceResult,
    contrast_scale='rate_ratio',profile_a='target',
    profile_b='control',confidence_level=.95,
    interval_exceeds_physical_bounds=False)
_st_cov=_st_obj(et.FunctionalMixedEffectsCovarianceSensitivityResult,
    reference_label='iid',fits={'iid':1,'ar1':2},
    failures={'exponential':'did not converge'},
    provenance={'functional_mixed_effects_covariance_sensitivity':
        {'information_criterion_mode':'ML'}})
_st_surr=_st_obj(et.MultivariateIAAFTResult,
    n_surrogates=9,dimension_names=('x','y'),
    reference_dimension='x',
    spectral_errors=np.array([.01,.003,.0004]),
    cross_spectral_errors=np.array([.02,.007]),random_state=123)
_st_test=_st_obj(et.MultivariateSurrogateNonlinearityResult,
    surrogate_result=_st_surr,
    surrogate_statistics=np.array([.1,.5,.2]),
    p_value=.25,statistic='joint_recurrence',alternative='greater')
_st_python={
    'prediction':et.generalized_function_on_scalar_prediction_reporting_text(_st_band),
    'difference':et.generalized_function_on_scalar_mean_difference_reporting_text(_st_diff),
    'covariance':et.functional_mixed_effects_covariance_sensitivity_reporting_text(_st_cov),
    'surrogate':et.multivariate_iaaft_reporting_text(_st_surr),
    'nonlinear':et.multivariate_surrogate_nonlinearity_reporting_text(_st_test)
}
")
  z<-.etr_source_text_fixtures()
  native<-list(
    prediction=etr_generalized_function_on_scalar_prediction_reporting_text(
      z$prediction),
    difference=etr_generalized_function_on_scalar_mean_difference_reporting_text(
      z$difference),
    covariance=etr_functional_mixed_effects_covariance_sensitivity_reporting_text(
      z$covariance),
    surrogate=etr_multivariate_iaaft_reporting_text(z$surrogate),
    nonlinear=etr_multivariate_surrogate_nonlinearity_reporting_text(
      z$nonlinear))
  for(n in names(native)){
    python<-reticulate::py_eval(paste0("_st_python['",n,"']"),
      convert=TRUE)
    expect_identical(native[[n]],python,
      info=paste("direct Python 1.2 source report:",n))
  }
})
