# Five text-only scientific contracts against frozen eyetrajectoriespy==1.2.0
# commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Python typed source objects map to checked R source-science records.
.etr_five_scientific_text_fixture<-function(variant="base") {
  stopifnot(variant%in%c("base","grouped","apostrophe","zero"))
  grouped<-identical(variant,"grouped")
  apostrophe<-identical(variant,"apostrophe")
  zero<-identical(variant,"zero")
  pid<-if(apostrophe)c("fish's β","control") else c("target","control")
  scale<-if(grouped)"probability" else if(apostrophe)"expected_count" else "rate"
  contrast<-if(grouped)"probability_difference" else
    if(apostrophe)"expected_count_difference" else
      if(zero)"rate_difference" else "rate_ratio"
  prediction<-list(
    prediction=list(profile_ids=pid,
      extrapolation_flags=if(grouped)c(FALSE,FALSE) else c(FALSE,TRUE),
      prediction_scale=scale,
      reference=list(family=if(grouped)"binomial" else "poisson",
                     link=if(grouped)"logit" else "log",
                     binomial_denominators=if(grouped)c(10,20) else NULL)),
    simultaneous_scope=if(apostrophe)"profile's grid" else "profile")
  difference<-list(
    contrast_scale=contrast,profile_a=pid[[1L]],profile_b=pid[[2L]],
    confidence_level=if(zero).9 else .95,
    interval_exceeds_physical_bounds=grouped)
  covariance<-list(
    reference_label=if(apostrophe)"fish's iid" else "iid",
    fits=if(zero)list() else list(iid=1,ar1=2),
    failures=if(grouped)list() else list(exponential="failed"),
    provenance=list(functional_mixed_effects_covariance_sensitivity=list(
      information_criterion_mode=if(apostrophe)"REML's choice" else "ML")))
  dims<-if(apostrophe)c("fish's β","y") else if(zero)c("x","y","z") else c("x","y")
  spectral<-if(zero)c(0,0,0) else c(.01,.003,.0004)
  cross<-if(zero)c(0,0) else c(.02,.007)
  surrogate<-list(n_surrogates=if(zero)3L else 9L,
    dimension_names=dims,reference_dimension=dims[[1L]],
    spectral_errors=spectral,cross_spectral_errors=cross,
    random_state=if(zero)NULL else 123L)
  nonlinear<-list(surrogate_result=surrogate,
    surrogate_statistics=if(zero)c(0,0,0) else c(.1,.5,.2),
    p_value=if(zero)1 else if(grouped).3333 else .25,
    statistic=if(apostrophe)"transfer_entropy" else "joint_recurrence",
    alternative=if(grouped)"less" else "greater")
  list(prediction=prediction,difference=difference,
       covariance=covariance,surrogate=surrogate,nonlinear=nonlinear)
}
.etr_five_scientific_texts<-function(z) {
  c(
    etr_generalized_function_on_scalar_prediction_reporting_text(z$prediction),
    etr_generalized_function_on_scalar_mean_difference_reporting_text(z$difference),
    etr_functional_mixed_effects_covariance_sensitivity_reporting_text(z$covariance),
    etr_multivariate_iaaft_reporting_text(z$surrogate),
    etr_multivariate_surrogate_nonlinearity_reporting_text(z$nonlinear))
}
test_that("five source scientific reports preserve statistical interpretation",{
  base<-.etr_five_scientific_texts(.etr_five_scientific_text_fixture())
  grouped<-.etr_five_scientific_texts(.etr_five_scientific_text_fixture("grouped"))
  apostrophe<-.etr_five_scientific_texts(.etr_five_scientific_text_fixture("apostrophe"))
  zero<-.etr_five_scientific_texts(.etr_five_scientific_text_fixture("zero"))
  expect_identical(length(base),5L)
  expect_true(all(nzchar(base)))
  expect_match(base[[1L]],"scalar-predictor extrapolations: control",fixed=TRUE)
  expect_match(grouped[[1L]],"success probability and does not require",fixed=TRUE)
  expect_match(grouped[[2L]],"bounds were retained rather than silently clipped",fixed=TRUE)
  expect_match(base[[2L]],"log-rate-ratio scale and exponentiated",fixed=TRUE)
  expect_match(base[[3L]],"No covariance structure was ranked",fixed=TRUE)
  expect_match(apostrophe[[3L]],'reference "fish\'s iid"',fixed=TRUE)
  expect_match(apostrophe[[3L]],'convention "REML\'s choice"',fixed=TRUE)
  expect_match(apostrophe[[4L]],'using "fish\'s β"',fixed=TRUE)
  expect_match(apostrophe[[5L]],'using "fish\'s β"',fixed=TRUE)
  expect_match(zero[[4L]],"mismatch=0",fixed=TRUE)
  expect_match(zero[[5L]],"random_state=None",fixed=TRUE)
  expect_match(base[[5L]],"not as proof of deterministic chaos",fixed=TRUE)
})
test_that("five source text reporters reject malformed scientific records",{
  z<-.etr_five_scientific_text_fixture()
  p<-z$prediction;p$prediction$prediction_scale<-"unknown"
  expect_error(etr_generalized_function_on_scalar_prediction_reporting_text(p),
    "prediction_scale")
  d<-z$difference;d$confidence_level<-1
  expect_error(etr_generalized_function_on_scalar_mean_difference_reporting_text(d),
    "confidence_level")
  c<-z$covariance;c$provenance<-list()
  expect_error(etr_functional_mixed_effects_covariance_sensitivity_reporting_text(c),
    "provenance")
  m<-z$surrogate;m$dimension_names<-c("x","x")
  expect_error(etr_multivariate_iaaft_reporting_text(m),"dimension_names")
  m<-z$surrogate;m$spectral_errors<-c(.01,NaN)
  expect_error(etr_multivariate_iaaft_reporting_text(m),"spectral_errors")
  n<-z$nonlinear;n$surrogate_statistics<-c(.1,Inf)
  expect_error(etr_multivariate_surrogate_nonlinearity_reporting_text(n),
    "surrogate_statistics")
  n<-z$nonlinear;n$p_value<--.1
  expect_error(etr_multivariate_surrogate_nonlinearity_reporting_text(n),
    "p_value")
})
test_that("20 complete typed frozen Python 1.2 source texts match native R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("direct frozen Python 1.2 source oracle is opt in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "import numpy as np",
    "import eyetrajectoriespy as et",
    "def _etr_five_typed(cls,**kw):",
    "    x=object.__new__(cls)",
    "    for k,v in kw.items():object.__setattr__(x,k,v)",
    "    return x",
    "def _etr_five_new_source(variant):",
    "    grouped=variant=='grouped'; apostrophe=variant=='apostrophe';zero=variant=='zero'",
    "    ids=(\"fish's β\",'control') if apostrophe else ('target','control')",
    "    scale='probability' if grouped else 'expected_count' if apostrophe else 'rate'",
    "    contrast='probability_difference' if grouped else 'expected_count_difference' if apostrophe else 'rate_difference' if zero else 'rate_ratio'",
    "    ref=_etr_five_typed(et.GeneralizedFunctionOnScalarResult,",
    "      family='binomial' if grouped else 'poisson',",
    "      link='logit' if grouped else 'log',",
    "      binomial_denominators=np.array([10,20]) if grouped else None)",
    "    prediction=_etr_five_typed(et.GeneralizedFunctionOnScalarPredictionResult,",
    "      profile_ids=ids,extrapolation_flags=np.array([False,False]) if grouped else np.array([False,True]),",
    "      prediction_scale=scale,reference=ref)",
    "    band=_etr_five_typed(et.GeneralizedFunctionOnScalarPredictionBandResult,",
    "      prediction=prediction,simultaneous_scope=\"profile's grid\" if apostrophe else 'profile')",
    "    difference=_etr_five_typed(et.GeneralizedFunctionOnScalarMeanDifferenceResult,",
    "      contrast_scale=contrast,profile_a=ids[0],profile_b=ids[1],",
    "      confidence_level=.9 if zero else .95,interval_exceeds_physical_bounds=grouped)",
    "    fits={} if zero else {'iid':1,'ar1':2}",
    "    failures={} if grouped else {'exponential':'failed'}",
    "    covariance=_etr_five_typed(et.FunctionalMixedEffectsCovarianceSensitivityResult,",
    "      reference_label=\"fish's iid\" if apostrophe else 'iid',",
    "      fits=fits,failures=failures,",
    "      provenance={'functional_mixed_effects_covariance_sensitivity':{",
    "        'information_criterion_mode':\"REML's choice\" if apostrophe else 'ML'}})",
    "    dims=(\"fish's β\",'y') if apostrophe else ('x','y','z') if zero else ('x','y')",
    "    surrogate=_etr_five_typed(et.MultivariateIAAFTResult,",
    "      n_surrogates=3 if zero else 9,dimension_names=dims,reference_dimension=dims[0],",
    "      spectral_errors=np.array([0.,0.,0.]) if zero else np.array([.01,.003,.0004]),",
    "      cross_spectral_errors=np.array([0.,0.]) if zero else np.array([.02,.007]),",
    "      random_state=None if zero else 123)",
    "    nonlinear=_etr_five_typed(et.MultivariateSurrogateNonlinearityResult,",
    "      surrogate_result=surrogate,surrogate_statistics=np.array([0.,0.,0.]) if zero else np.array([.1,.5,.2]),",
    "      p_value=1. if zero else .3333 if grouped else .25,",
    "      statistic='transfer_entropy' if apostrophe else 'joint_recurrence',",
    "      alternative='less' if grouped else 'greater')",
    "    return [",
    "      et.generalized_function_on_scalar_prediction_reporting_text(band),",
    "      et.generalized_function_on_scalar_mean_difference_reporting_text(difference),",
    "      et.functional_mixed_effects_covariance_sensitivity_reporting_text(covariance),",
    "      et.multivariate_iaaft_reporting_text(surrogate),",
    "      et.multivariate_surrogate_nonlinearity_reporting_text(nonlinear)]"
  ),collapse="\n"),convert=FALSE)
  fn<-reticulate::py_get_attr(reticulate::py,"_etr_five_new_source")
  for(variant in c("base","grouped","apostrophe","zero")){
    expected<-reticulate::py_to_r(reticulate::py_call(fn,variant))
    actual<-.etr_five_scientific_texts(.etr_five_scientific_text_fixture(variant))
    expect_identical(length(actual),length(expected))
    for(i in seq_along(actual))
      expect_identical(actual[[i]],as.character(expected[[i]]),
        info=paste(variant,i))
  }
})
