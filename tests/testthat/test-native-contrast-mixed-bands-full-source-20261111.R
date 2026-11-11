# Paired scientific inference source contracts, frozen eyetrajectoriespy 1.2.0.
# Python oracle commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Source: generalized_function_on_scalar_prediction.py and
# functional_mixed_effects_inference.py. These calls only calibrate
# previously retained bootstrap arrays; neither resamples nor fits models.

.etr_contrast_full_source_fixture <- function(family="binomial",
    exposed=FALSE,count=FALSE) {
  time <- c(0,.25,.5,.75)
  labels <- c("untreated","treated","stretch")
  p <- matrix(c(.20,.25,.30,.35,
                .40,.45,.50,.55,
                .75,.70,.65,.60),nrow=3L,byrow=TRUE)
  rate <- matrix(c(1,1.2,1.4,1.6,
                   2,2.1,2.2,2.3,
                   .8,.9,1,1.1),nrow=3L,byrow=TRUE)
  exposure <- matrix(rep(c(2,3,4),each=4L),nrow=3L,byrow=TRUE)
  shape <- matrix(c(.2,.1,.15,.2,
                    .45,.3,.35,.25,
                    .1,.2,.25,.15),nrow=3L,byrow=TRUE)
  offsets <- c(-.15,-.07,0,.09,.18)
  draws <- array(0,dim=c(length(offsets),3L,4L))
  for(b in seq_along(offsets))
    draws[b,,] <- if(family=="binomial")p+offsets[b]*shape else
      rate*exp(offsets[b]*shape)
  means <- if(family=="binomial") p else if(count) rate*exposure else rate
  draws_rate <- if(family=="poisson")draws else NULL
  draws_count <- if(count)
    sweep(draws,c(2L,3L),exposure,"*") else
      if(family=="poisson"&&!exposed)draws else NULL
  draws_mean <- if(count) draws_count else draws
  fit <- list(time=time,family=family,
    exposure=if(exposed)exposure else NULL)
  prediction <- list(reference=fit,profile_ids=labels,
    mean_functions=means,
    rate_functions=if(family=="poisson"&&exposed)rate else NULL,
    expected_count_functions=if(count)rate*exposure else
      if(family=="poisson"&&!exposed)rate else NULL,
    extrapolation_flags=c(FALSE,TRUE,FALSE),
    prediction_scale=if(count||(family=="poisson"&&!exposed))
      "expected_count" else if(family=="poisson")"rate" else "probability")
  list(prediction=prediction,
    bootstrap_mean_functions=draws_mean,
    bootstrap_rate_functions=if(exposed)draws_rate else NULL,
    bootstrap_expected_count_functions=draws_count,
    provenance=list(study="two-full-inference-source"))
}

.etr_mixed_full_source_fixture <- function(kind="conditional_covariance") {
  fit <- list(time=c(0,.25,.5,.75),
    coefficient_names=c("Intercept","treatment"),
    coefficient_functions=rbind(c(.2,.4,.5,.6),c(-.1,.1,.3,.4)))
  center <- rbind(c(.15,.35,.45,.55),c(-.15,.05,.25,.35))
  se <- rbind(c(.1,.12,.14,.16),c(.18,.15,.12,.09))
  offsets <- c(-.4,-.2,0,.25,.5)
  shape <- rbind(c(.1,.3,.2,.4),c(.2,.1,.4,.3))
  draws <- array(0,c(5L,2L,4L))
  for(b in seq_along(offsets)) draws[b,,]<-center+offsets[b]*shape
  list(reference=fit,bootstrap_mean=center,
    bootstrap_standard_errors=se,
    bootstrap_coefficient_functions=draws,
    bootstrap_type=kind,
    provenance=list(study="two-full-inference-source"))
}

test_that("predeclared mean contrasts retain five source response/ratio estimands",{
  cases <- list(
    list(family="binomial",exposed=FALSE,count=FALSE,scale=NULL,
      output="probability_difference",infer="probability_difference"),
    list(family="poisson",exposed=FALSE,count=FALSE,scale=NULL,
      output="expected_count_difference",infer="expected_count_difference"),
    list(family="poisson",exposed=TRUE,count=FALSE,scale=NULL,
      output="rate_difference",infer="rate_difference"),
    list(family="poisson",exposed=TRUE,count=FALSE,scale="rate_ratio",
      output="rate_ratio",infer="log_rate_ratio"),
    list(family="poisson",exposed=TRUE,count=TRUE,
      scale="expected_count_difference",
      output="expected_count_difference",infer="expected_count_difference"))
  for(item in cases) {
    f <- .etr_contrast_full_source_fixture(item$family,item$exposed,item$count)
    x <- etr_generalized_function_on_scalar_mean_difference_band(
      f,profile_a="treated",profile_b="untreated",
      confidence_level=.75,contrast_scale=item$scale)
    expect_identical(names(x),c("prediction_bootstrap","profile_a","profile_b",
      "estimate","standard_error","lower","upper","bootstrap_estimates",
      "max_statistics","critical_value","confidence_level",
      "physical_lower_bound","physical_upper_bound",
      "interval_exceeds_physical_bounds","contrast_scale",
      "inference_scale","provenance"))
    expect_identical(x$contrast_scale,item$output)
    expect_identical(x$inference_scale,item$infer)
    expect_identical(length(x$estimate),4L)
    expect_identical(dim(x$bootstrap_estimates),c(5L,4L))
    expect_equal(x$standard_error,apply(
      if(item$output=="rate_ratio")log(x$bootstrap_estimates)
      else x$bootstrap_estimates,2L,stats::sd),tolerance=1e-12)
    expect_identical(x$provenance$study,"two-full-inference-source")
    expect_true(x$provenance$
      generalized_function_on_scalar_mean_difference_band$
      profile_pair_extrapolated)
    expect_false(x$provenance$
      generalized_function_on_scalar_mean_difference_band$
      multiple_contrast_family_adjustment)
    expect_true(all(x$lower<=x$upper))
    if(item$output=="rate_ratio")expect_true(all(x$lower>0))
    if(item$output=="probability_difference"){
      expect_equal(x$physical_lower_bound,-1)
      expect_equal(x$physical_upper_bound,1)
    }else {
      expect_null(x$physical_lower_bound)
      expect_null(x$physical_upper_bound)
    }
  }
})

test_that("conditional and full-refit mixed bands share source maxima but differ in provenance",{
  for(kind in c("conditional_covariance","full_refit")){
    f <- .etr_mixed_full_source_fixture(kind)
    for(scope in c("coefficient","family")){
      x <- etr_functional_mixed_effects_simultaneous_bands(
        f,confidence_level=.75,simultaneous_scope=scope)
      expect_identical(names(x),c("reference","lower","upper",
        "pointwise_standard_errors","critical_values",
        "max_statistics","confidence_level","simultaneous_scope",
        "bootstrap","provenance"))
      expect_identical(dim(x$lower),c(2L,4L))
      expect_identical(dim(x$upper),c(2L,4L))
      expect_identical(dim(x$max_statistics),
        if(scope=="family")c(5L,1L) else c(5L,2L))
      expect_equal((x$lower+x$upper)/2,
        f$reference$coefficient_functions,tolerance=1e-12)
      expect_equal(x$pointwise_standard_errors,
        f$bootstrap_standard_errors,tolerance=0)
      expect_identical(x$provenance$study,"two-full-inference-source")
      expect_identical(x$provenance$
        functional_mixed_effects_simultaneous_bands$
        variance_components_refit,kind=="full_refit")
      expect_false(x$provenance$
        functional_mixed_effects_simultaneous_bands$
        continuous_between_grid_points)
    }
  }
})

test_that("both source calibrators fail on invalid numerical/scientific domains",{
  f <- .etr_contrast_full_source_fixture("poisson",TRUE)
  expect_error(etr_generalized_function_on_scalar_mean_difference_band(
    f,"treated","treated"),"different")
  expect_error(etr_generalized_function_on_scalar_mean_difference_band(
    f,"missing","untreated"),"Unknown profile")
  expect_error(etr_generalized_function_on_scalar_mean_difference_band(
    f,"treated","untreated",contrast_scale="invalid"),"contrast_scale")
  expect_error(etr_generalized_function_on_scalar_mean_difference_band(
    f,"treated","untreated",contrast_scale="expected_count_difference"),
    "expected_count_difference requires")
  bad <- f
  bad$bootstrap_rate_functions <- array(0,dim=c(1L,3L,4L))
  expect_error(etr_generalized_function_on_scalar_mean_difference_band(
    bad,"treated","untreated",contrast_scale="rate_ratio"),
    "B-by-profile-by-time")
  bad <- f
  bad$bootstrap_rate_functions[1L,2L,1L] <- 0
  expect_error(etr_generalized_function_on_scalar_mean_difference_band(
    bad,"treated","untreated",contrast_scale="rate_ratio"),
    "strictly positive")
  m <- .etr_mixed_full_source_fixture()
  bad <- m
  bad$bootstrap_standard_errors[1L,1L]<-0
  expect_error(etr_functional_mixed_effects_simultaneous_bands(bad),
    "zero-width")
  bad <- m
  bad$bootstrap_type<-"undefined"
  expect_error(etr_functional_mixed_effects_simultaneous_bands(bad),
    "bootstrap_type")
  bad <- m
  bad$bootstrap_coefficient_functions<-array(0,c(5L,2L,3L))
  expect_error(etr_functional_mixed_effects_simultaneous_bands(bad),
    "B-by-coefficient-by-time")
  expect_error(etr_functional_mixed_effects_simultaneous_bands(
    m,simultaneous_scope="profile"),"simultaneous_scope")
})

test_that("frozen Python 1.2 typed mean contrast and mixed bands agree field by field",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("source typed contrast and mixed bootstrap oracles are opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
def _src_obj(cls, **attrs):
    obj=object.__new__(cls)
    for key,value in attrs.items():
        object.__setattr__(obj,key,value)
    return obj
_src_time=np.array([0.,.25,.5,.75])
_src_offsets=np.array([-.15,-.07,0.,.09,.18])
_src_prob=np.array([[.20,.25,.30,.35],
                    [.40,.45,.50,.55],
                    [.75,.70,.65,.60]])
_src_rate=np.array([[1.,1.2,1.4,1.6],
                    [2.,2.1,2.2,2.3],
                    [.8,.9,1.,1.1]])
_src_exposure=np.array([[2.]*4,[3.]*4,[4.]*4])
_src_shape=np.array([[.2,.1,.15,.2],
                     [.45,.3,.35,.25],
                     [.1,.2,.25,.15]])
_src_contrasts={}
for _key,_family,_exposed,_count,_scale in (
    ('binomial','binomial',False,False,None),
    ('poisson','poisson',False,False,None),
    ('rate_difference','poisson',True,False,None),
    ('rate_ratio','poisson',True,False,'rate_ratio'),
    ('expected_count_difference','poisson',True,True,'expected_count_difference')):
    _fit=_src_obj(et.GeneralizedFunctionOnScalarResult,
        time=_src_time,family=_family,
        exposure=_src_exposure if _exposed else None)
    _draws=np.stack([(_src_prob+o*_src_shape) if _family=='binomial'
                     else (_src_rate*np.exp(o*_src_shape))
                     for o in _src_offsets])
    _mean=(_src_prob if _family=='binomial'
           else _src_rate*_src_exposure if _count else _src_rate)
    _rate=_src_rate if _family=='poisson' and _exposed else None
    _count_base=(_src_rate*_src_exposure if _count else
                 _src_rate if _family=='poisson' and not _exposed else None)
    _pred=_src_obj(et.GeneralizedFunctionOnScalarPredictionResult,
        reference=_fit,profile_ids=('untreated','treated','stretch'),
        mean_functions=_mean,rate_functions=_rate,
        expected_count_functions=_count_base,
        extrapolation_flags=np.array([False,True,False]),
        prediction_scale=('expected_count' if _count or (_family=='poisson' and not _exposed)
                          else 'rate' if _family=='poisson' else 'probability'))
    _boot=_src_obj(et.GeneralizedFunctionOnScalarPredictionBootstrapResult,
        prediction=_pred,
        bootstrap_mean_functions=_draws*_src_exposure if _count else _draws,
        bootstrap_rate_functions=_draws if _exposed else None,
        bootstrap_expected_count_functions=(
            _draws*_src_exposure if _count else
            _draws if _family=='poisson' and not _exposed else None),
        provenance={'study':'two-full-inference-source'})
    _src_contrasts[_key]=et.generalized_function_on_scalar_mean_difference_band(
        _boot,profile_a='treated',profile_b='untreated',
        confidence_level=.75,contrast_scale=_scale)
_src_mixed_center=np.array([[.15,.35,.45,.55],[-.15,.05,.25,.35]])
_src_mixed_ref=np.array([[.2,.4,.5,.6],[-.1,.1,.3,.4]])
_src_mixed_se=np.array([[.1,.12,.14,.16],[.18,.15,.12,.09]])
_src_mixed_shape=np.array([[.1,.3,.2,.4],[.2,.1,.4,.3]])
_src_mixed_offsets=np.array([-.4,-.2,0.,.25,.5])
_src_mixed_draws=np.stack([_src_mixed_center+o*_src_mixed_shape
                           for o in _src_mixed_offsets])
_src_mixed_fit=_src_obj(et.FunctionalMixedEffectsResult,
    time=_src_time,coefficient_names=('Intercept','treatment'),
    coefficient_functions=_src_mixed_ref)
_src_mixed={}
for _kind,_cls in (
    ('conditional_covariance',et.FunctionalMixedEffectsBootstrapResult),
    ('full_refit',et.FunctionalMixedEffectsFullRefitBootstrapResult)):
    _boot=_src_obj(_cls,reference=_src_mixed_fit,
        bootstrap_mean=_src_mixed_center,
        bootstrap_standard_errors=_src_mixed_se,
        bootstrap_coefficient_functions=_src_mixed_draws,
        provenance={'study':'two-full-inference-source'})
    for _scope in ('coefficient','family'):
        _src_mixed[(_kind,_scope)]=et.functional_mixed_effects_simultaneous_bands(
            _boot,confidence_level=.75,simultaneous_scope=_scope)
")
  cases <- list(
    binomial=list("binomial",FALSE,FALSE,NULL),
    poisson=list("poisson",FALSE,FALSE,NULL),
    rate_difference=list("poisson",TRUE,FALSE,NULL),
    rate_ratio=list("poisson",TRUE,FALSE,"rate_ratio"),
    expected_count_difference=list("poisson",TRUE,TRUE,
      "expected_count_difference"))
  for(key in names(cases)){
    item<-cases[[key]]
    z<-.etr_contrast_full_source_fixture(item[[1L]],item[[2L]],item[[3L]])
    native<-etr_generalized_function_on_scalar_mean_difference_band(
      z,"treated","untreated",confidence_level=.75,
      contrast_scale=item[[4L]])
    source<-reticulate::py_eval(
      paste0("_src_contrasts['",key,"']"),convert=FALSE)
    for(field in setdiff(names(native),c("prediction_bootstrap","provenance"))){
      ref<-et_to_r(reticulate::py_get_attr(source,field))
      expect_equal(native[[field]],ref,tolerance=2e-11,
        ignore_attr=TRUE,info=paste("contrast source",key,field))
    }
    expect_equal(native$provenance,
      et_to_r(reticulate::py_get_attr(source,"provenance")),
      ignore_attr=TRUE,info=paste(key,"nested provenance"))
  }
  for(kind in c("conditional_covariance","full_refit"))
    for(scope in c("coefficient","family")){
      native<-etr_functional_mixed_effects_simultaneous_bands(
        .etr_mixed_full_source_fixture(kind),confidence_level=.75,
        simultaneous_scope=scope)
      source<-reticulate::py_eval(
        paste0("_src_mixed[('",kind,"','",scope,"')]"),
        convert=FALSE)
      for(field in setdiff(names(native),c("reference","bootstrap","provenance"))){
        ref<-et_to_r(reticulate::py_get_attr(source,field))
        expect_equal(native[[field]],ref,tolerance=2e-12,
          ignore_attr=TRUE,info=paste("mixed source",kind,scope,field))
      }
      expect_equal(native$provenance,
        et_to_r(reticulate::py_get_attr(source,"provenance")),
        ignore_attr=TRUE)
      expect_equal(native$reference$coefficient_functions,
        et_to_r(reticulate::py_get_attr(
          reticulate::py_get_attr(source,"reference"),"coefficient_functions")),
        tolerance=0,ignore_attr=TRUE)
    }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
