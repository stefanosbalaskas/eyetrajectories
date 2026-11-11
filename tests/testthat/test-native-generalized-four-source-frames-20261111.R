# Frozen Python oracle: eyetrajectoriespy==1.2.0, commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Source: generalized_function_on_scalar.py and
# generalized_function_on_scalar_prediction.py.
# Typed source objects are compared with checked native scientific R records.
.etr_four_gfosr_frames_fixture <- function(variant="rate") {
  stopifnot(variant %in% c("rate","count","nullable","binomial"))
  binomial<-identical(variant,"binomial")
  count<-identical(variant,"count")
  nullable<-identical(variant,"nullable")
  time<-c(0,.5,1)
  names<-if(count)c("fish's β","treatment") else c("intercept","treatment")
  exposure<-if(binomial)NULL else if(nullable)
    matrix(c(1,1,1,2,2,2),2L,3L,byrow=TRUE)
  else matrix(c(2,2,2,3,4,5),2L,3L,byrow=TRUE)
  units<-if(binomial||nullable)NULL else if(count)"fish's / tank" else "hours"
  fit<-list(
    time=time,coefficient_names=names,
    coefficient_functions=matrix(c(.25,.45,.75,.75,.8,.95),2L,3L,
      byrow=TRUE),
    coefficient_standard_errors=matrix(.12,2L,3L),
    family=if(binomial)"binomial" else "poisson",
    link=if(binomial)"logit" else "log",
    source_curve_ids=c("curve-A","curve-B"),
    exposure=exposure,exposure_units=units,
    exposure_expanded_from_curve=FALSE)
  coeffBand<-list(
    reference=fit,lower=fit$coefficient_functions-.2,
    upper=fit$coefficient_functions+.2,
    critical_values=c(2.1,2.3))
  linear<-matrix(c(.1,.2,.3,.3,.4,.5),2L,3L,byrow=TRUE)
  mean<-if(binomial)
    matrix(c(.35,.4,.45,.55,.6,.65),2L,3L,byrow=TRUE)
  else if(count)matrix(c(3.,3.6,4.2,5.,8.,11.),2L,3L,byrow=TRUE)
  else matrix(c(1.5,1.8,2.1,2.5,2.6,2.7),2L,3L,byrow=TRUE)
  rate<-if(binomial)NULL else
    matrix(c(1.5,1.8,2.1,2.5,2.6,2.7),2L,3L,byrow=TRUE)
  pred<-list(
    reference=fit,
    profile_ids=if(count)c("fish's β","B") else c("A","B"),
    linear_predictor_functions=linear,
    linear_predictor_standard_errors=matrix(.2,2L,3L),
    mean_functions=mean,mean_standard_errors=matrix(.08,2L,3L),
    prediction_scale=if(binomial)"probability" else
      if(count)"expected_count" else "rate",
    rate_functions=rate,
    expected_count_functions=if(count)mean else NULL,
    exposure_profiles=if(count)exposure else NULL,
    extrapolation_flags=c(FALSE,TRUE))
  predictionBand<-list(
    prediction=pred,
    linear_lower=linear-.2,linear_upper=linear+.2,
    mean_lower=mean-.1,mean_upper=mean+.1,
    critical_values=c(2.1,2.3))
  contrast<-list(
    prediction_bootstrap=list(prediction=pred),
    estimate=c(.1,.2,.15),standard_error=c(.05,.06,.04),
    lower=c(0,.08,.03),upper=c(.2,.32,.27),
    profile_a=pred$profile_ids[[1L]],profile_b=pred$profile_ids[[2L]],
    critical_value=2.2,
    contrast_scale=if(binomial)"probability_difference" else
      if(count)"expected_count_difference" else "rate_ratio",
    inference_scale=if(binomial)"probability_difference" else
      if(count)"expected_count_difference" else "log_rate_ratio",
    interval_exceeds_physical_bounds=FALSE)
  list(fit=fit,coef_band=coeffBand,prediction=pred,
    prediction_band=predictionBand,contrast=contrast)
}
.etr_four_gfosr_frames_native <- function(z) {
  out<-list(
    coefficient=etr_generalized_function_on_scalar_coefficient_frame(z$fit),
    coefficient_band=etr_generalized_function_on_scalar_coefficient_frame(
      z$coef_band),
    prediction=etr_generalized_function_on_scalar_prediction_frame(
      z$prediction),
    prediction_band=etr_generalized_function_on_scalar_prediction_frame(
      z$prediction_band),
    difference=etr_generalized_function_on_scalar_mean_difference_frame(
      z$contrast))
  if(!is.null(z$fit$exposure))
    out$exposure<-etr_generalized_function_on_scalar_exposure_frame(z$fit)
  out
}
.etr_four_gfosr_missing <- function(x) {
  if(is.list(x))
    return(all(vapply(x,function(y)
      is.null(y) || (length(y)==1L && is.na(y)),logical(1L))))
  all(is.na(x))
}
test_that("four related generalized source frames are fully ordered and auditable",{
  for(variant in c("rate","count","nullable","binomial")){
    z<-.etr_four_gfosr_frames_fixture(variant)
    cases<-.etr_four_gfosr_frames_native(z)
    expect_true(all(vapply(cases,function(x)is.data.frame(x)&&
      nrow(x)>=2L,logical(1L))))
    expect_identical(cases$coefficient$coefficient,
      rep(z$fit$coefficient_names,each=3L))
    expect_identical(cases$prediction$profile_id,
      rep(z$prediction$profile_ids,each=3L))
    expect_equal(cases$prediction$mean,
      as.vector(t(z$prediction$mean_functions)))
    expect_equal(cases$difference$estimate,z$contrast$estimate)
    expect_identical(cases$prediction$extrapolation,
      c(FALSE,FALSE,FALSE,TRUE,TRUE,TRUE))
    expect_identical(tail(names(cases$prediction_band),5L),
      c("linear_lower","linear_upper","mean_lower","mean_upper",
        "critical_value"))
    if(!is.null(z$fit$exposure)){
      expect_identical(names(attr(cases$exposure,"exposure_audit"))[1:4],
        c("minimum_exposure","maximum_exposure","exposure_range",
          "extreme_exposure_ratio"))
      if(variant=="nullable")
        expect_true(all(is.na(cases$exposure$exposure_units)))
      if(variant=="count")
        expect_identical(cases$exposure$exposure_units,
          rep("fish's / tank",2L))
    }
  }
})
test_that("four full-source frames reject non-source scientific input domains",{
  z<-.etr_four_gfosr_frames_fixture()
  bad<-z$fit;bad$coefficient_names<-c("A","A")
  expect_error(etr_generalized_function_on_scalar_coefficient_frame(bad),
    "distinct")
  bad<-z$prediction;bad$mean_functions<-matrix(1,2,4)
  expect_error(etr_generalized_function_on_scalar_prediction_frame(bad),
    "mean_functions")
  bad<-z$prediction_band;bad$linear_upper[1,1]<-(-5)
  expect_error(etr_generalized_function_on_scalar_prediction_frame(bad),
    "lower")
  bad<-z$contrast;bad$critical_value<-NaN
  expect_error(etr_generalized_function_on_scalar_mean_difference_frame(bad),
    "critical_value")
  bad<-z$fit;bad$exposure[1,1]<--2
  expect_error(etr_generalized_function_on_scalar_exposure_frame(bad),
    "exposure")
  bad<-z$fit;bad$exposure_units<-NA_character_
  expect_error(etr_generalized_function_on_scalar_exposure_frame(bad),
    "exposure_units")
})
test_that("23 source typed Python 1.2 generalized FoSR frames match native R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 four source frame comparison opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "import numpy as np",
    "import eyetrajectoriespy as et",
    "def _etr_gfour_typed(cls,**data):",
    "    value=object.__new__(cls)",
    "    for k,v in data.items():object.__setattr__(value,k,v)",
    "    return value",
    "def _etr_gfour_frames(variant):",
    "    count=variant=='count';nullable=variant=='nullable'",
    "    binomial=variant=='binomial'",
    "    expo=None if binomial else np.array([[1,1,1],[2,2,2]],dtype=float) if nullable else np.array([[2,2,2],[3,4,5]],dtype=float)",
    "    units=None if binomial or nullable else \"fish's / tank\" if count else 'hours'",
    "    fit=_etr_gfour_typed(et.GeneralizedFunctionOnScalarResult,",
    "      time=np.array([0.,.5,1.]),",
    "      coefficient_names=(\"fish's β\",'treatment') if count else ('intercept','treatment'),",
    "      coefficient_functions=np.array([[.25,.45,.75],[.75,.8,.95]]),",
    "      coefficient_standard_errors=np.full((2,3),.12),",
    "      family='binomial' if binomial else 'poisson',",
    "      link='logit' if binomial else 'log',",
    "      source_curve_ids=('curve-A','curve-B'),",
    "      exposure=expo,exposure_units=units,exposure_expanded_from_curve=False)",
    "    cb=_etr_gfour_typed(et.GeneralizedFunctionOnScalarBandResult,",
    "      reference=fit,lower=fit.coefficient_functions-.2,",
    "      upper=fit.coefficient_functions+.2,",
    "      critical_values=np.array([2.1,2.3]))",
    "    linear=np.array([[.1,.2,.3],[.3,.4,.5]])",
    "    mean=np.array([[.35,.4,.45],[.55,.6,.65]]) if binomial else np.array([[3.,3.6,4.2],[5.,8.,11.]]) if count else np.array([[1.5,1.8,2.1],[2.5,2.6,2.7]])",
    "    rate=None if binomial else np.array([[1.5,1.8,2.1],[2.5,2.6,2.7]])",
    "    p=_etr_gfour_typed(et.GeneralizedFunctionOnScalarPredictionResult,",
    "      reference=fit,profile_ids=(\"fish's β\",'B') if count else ('A','B'),",
    "      linear_predictor_functions=linear,",
    "      linear_predictor_standard_errors=np.full((2,3),.2),",
    "      mean_functions=mean,mean_standard_errors=np.full((2,3),.08),",
    "      prediction_scale='probability' if binomial else 'expected_count' if count else 'rate',",
    "      rate_functions=rate,",
    "      expected_count_functions=mean if count else None,",
    "      exposure_profiles=expo if count else None,",
    "      extrapolation_flags=np.array([False,True]))",
    "    pb=_etr_gfour_typed(et.GeneralizedFunctionOnScalarPredictionBandResult,",
    "      prediction=p,linear_lower=linear-.2,linear_upper=linear+.2,",
    "      mean_lower=mean-.1,mean_upper=mean+.1,",
    "      critical_values=np.array([2.1,2.3]))",
    "    ctr=_etr_gfour_typed(et.GeneralizedFunctionOnScalarMeanDifferenceResult,",
    "      prediction_bootstrap=_etr_gfour_typed(",
    "        et.GeneralizedFunctionOnScalarPredictionBootstrapResult,prediction=p),",
    "      estimate=np.array([.1,.2,.15]),",
    "      standard_error=np.array([.05,.06,.04]),",
    "      lower=np.array([0.,.08,.03]),upper=np.array([.2,.32,.27]),",
    "      profile_a=p.profile_ids[0],profile_b=p.profile_ids[1],",
    "      critical_value=2.2,",
    "      contrast_scale='probability_difference' if binomial else 'expected_count_difference' if count else 'rate_ratio',",
    "      inference_scale='probability_difference' if binomial else 'expected_count_difference' if count else 'log_rate_ratio',",
    "      interval_exceeds_physical_bounds=False)",
    "    result={'coefficient':et.generalized_function_on_scalar_coefficient_frame(fit),",
    "      'coefficient_band':et.generalized_function_on_scalar_coefficient_frame(cb),",
    "      'prediction':et.generalized_function_on_scalar_prediction_frame(p),",
    "      'prediction_band':et.generalized_function_on_scalar_prediction_frame(pb),",
    "      'difference':et.generalized_function_on_scalar_mean_difference_frame(ctr)}",
    "    if expo is not None:result['exposure']=et.generalized_function_on_scalar_exposure_frame(fit)",
    "    return result"
  ),collapse="\n"),convert=FALSE)
  oracle<-reticulate::py_get_attr(reticulate::py,"_etr_gfour_frames")
  for(variant in c("rate","count","nullable","binomial")){
    z<-.etr_four_gfosr_frames_fixture(variant)
    native<-.etr_four_gfosr_frames_native(z)
    expected<-reticulate::py_to_r(reticulate::py_call(oracle,variant))
    expect_identical(names(native),names(expected),info=variant)
    for(key in names(native)){
      a<-native[[key]];b<-expected[[key]]
      expect_identical(names(a),names(b),info=paste(variant,key))
      expect_identical(nrow(a),nrow(b),info=paste(variant,key))
      for(col in names(a)){
        av<-a[[col]];bv<-b[[col]]
        if(all(is.na(av))){
          expect_true(.etr_four_gfosr_missing(bv),
            info=paste(variant,key,col,"None/NA"))
        }else if(is.numeric(av)){
          expect_equal(as.numeric(av),as.numeric(bv),tolerance=1e-12,
            info=paste(variant,key,col))
        }else{
          expect_identical(as.character(av),as.character(bv),
            info=paste(variant,key,col))
        }
      }
    }
    if("exposure" %in% names(native)){
      audit<-reticulate::py_to_r(reticulate::py_get_attr(
        reticulate::py_get_item(
          reticulate::py_call(oracle,variant),"exposure"),"attrs"))
      sourceAudit<-audit[["exposure_audit"]]
      localAudit<-attr(native$exposure,"exposure_audit")
      expect_identical(names(localAudit),names(sourceAudit),info=variant)
      for(field in names(localAudit)){
        av<-localAudit[[field]];bv<-sourceAudit[[field]]
        if(is.null(av))expect_null(bv)
        else if(is.numeric(av))expect_equal(as.numeric(av),as.numeric(bv),
          tolerance=1e-12,info=paste(variant,field))
        else expect_identical(av,bv,info=paste(variant,field))
      }
    }
  }
})
