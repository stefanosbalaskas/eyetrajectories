# Frozen Python 1.2 observational frame adapters.
# Native-only checks run without Python, while exact pinned-source schemas,
# values and metadata are tested with ET_RUN_PYTHON_TESTS=true.
.etr_scientific_frame_fixtures <- function() {
  time<-c(0,.5,1)
  fit<-list(time=time,family="poisson",link="log",
    coefficient_names=c("Intercept","treatment"),
    coefficient_functions=matrix(c(1,2,3,4,5,6),2,3,
      byrow=TRUE),
    coefficient_standard_errors=matrix(.25,2,3),
    source_curve_ids=c("c1","c2"),
    exposure=matrix(c(2,2,2,3,3,4),2,3,byrow=TRUE),
    exposure_units="hours",
    exposure_expanded_from_curve=FALSE)
  coef_band<-list(reference=fit,
    lower=fit$coefficient_functions-.5,
    upper=fit$coefficient_functions+.5,
    critical_values=c(2,2.5))
  prediction<-list(reference=fit,profile_ids=c("A","B"),
    linear_predictor_functions=matrix(1:6,2,3,byrow=TRUE),
    linear_predictor_standard_errors=matrix(.2,2,3),
    mean_functions=matrix(11:16,2,3,byrow=TRUE),
    mean_standard_errors=matrix(.3,2,3),
    prediction_scale="response",
    rate_functions=matrix(1:6,2,3,byrow=TRUE),
    expected_count_functions=NULL,
    exposure_profiles=NULL,
    extrapolation_flags=c(FALSE,TRUE))
  prediction_band<-list(prediction=prediction,
    linear_lower=prediction$linear_predictor_functions-1,
    linear_upper=prediction$linear_predictor_functions+1,
    mean_lower=prediction$mean_functions-2,
    mean_upper=prediction$mean_functions+2,
    critical_values=c(2,2.5))
  contrast<-list(prediction_bootstrap=list(prediction=prediction),
    estimate=c(.1,.2,.3),standard_error=c(.01,.02,.03),
    lower=c(.05,.1,.2),upper=c(.15,.3,.4),
    profile_a="A",profile_b="B",critical_value=2.5,
    contrast_scale="response_difference",inference_scale="response",
    interval_exceeds_physical_bounds=FALSE)
  sparse<-list(curve_ids=c("c1","c2"),
    metadata=data.frame(group=c("control","treatment")),
    scores=matrix(c(1,2,3,4),2,2,byrow=TRUE),
    n_components=2L)
  list(fit=fit,coef_band=coef_band,prediction=prediction,
    prediction_band=prediction_band,contrast=contrast,sparse=sparse)
}

test_that("six scientific extractors retain source order, column names, and scope",{
  z<-.etr_scientific_frame_fixtures()
  co<-etr_generalized_function_on_scalar_coefficient_frame(z$fit)
  expect_identical(names(co),c("coefficient","time","estimate",
    "standard_error","scale","family","link"))
  expect_identical(co$coefficient,rep(c("Intercept","treatment"),each=3L))
  expect_equal(co$estimate,c(1,2,3,4,5,6))
  expect_equal(co$time,rep(c(0,.5,1),2))
  cb<-etr_generalized_function_on_scalar_coefficient_frame(z$coef_band)
  expect_identical(tail(names(cb),3L),c("lower","upper","critical_value"))
  expect_equal(cb$critical_value,rep(c(2,2.5),each=3))
  pred<-etr_generalized_function_on_scalar_prediction_frame(z$prediction)
  expect_equal(pred$linear_predictor,1:6)
  expect_identical(pred$profile_id,rep(c("A","B"),each=3L))
  expect_true(all(is.na(pred$expected_count)))
  expect_identical(pred$extrapolation,c(FALSE,FALSE,FALSE,TRUE,TRUE,TRUE))
  expect_identical(ncol(pred),13L)
  bp<-etr_generalized_function_on_scalar_prediction_frame(
    z$prediction_band)
  expect_identical(tail(names(bp),5L),
    c("linear_lower","linear_upper","mean_lower","mean_upper",
      "critical_value"))
  diff<-etr_generalized_function_on_scalar_mean_difference_frame(
    z$contrast)
  expect_identical(names(diff),c("time","estimate",
    "standard_error","lower","upper","profile_a","profile_b",
    "critical_value","contrast_scale","inference_scale",
    "interval_exceeds_physical_bounds"))
  expect_equal(diff$estimate,c(.1,.2,.3))
  ex<-etr_generalized_function_on_scalar_exposure_frame(z$fit)
  expect_identical(ex$varies_over_time,c(FALSE,TRUE))
  expect_equal(ex$exposure_ratio,c(1,4/3))
  expect_equal(attr(ex,"exposure_audit")$extreme_exposure_ratio,2)
  expect_true(attr(ex,"exposure_audit")$varies_between_curves)
  sf<-etr_sparse_fpca_score_frame(z$sparse)
  sm<-etr_sparse_mfpca_score_frame(z$sparse)
  expect_identical(names(sf),c("curve_id","group","SFPC1","SFPC2"))
  expect_identical(names(sm),c("curve_id","group","SMFPC1","SMFPC2"))
  expect_equal(sf$SFPC2,c(2,4))
})

test_that("native science frames reject invalid identifiers, shape, uncertainty and exposure",{
  z<-.etr_scientific_frame_fixtures()
  bad<-z$fit;bad$coefficient_names<-c("repeated","repeated")
  expect_error(etr_generalized_function_on_scalar_coefficient_frame(bad),
    "distinct")
  bad<-z$fit;bad$coefficient_standard_errors[1,1]<--1
  expect_error(etr_generalized_function_on_scalar_coefficient_frame(bad),
    "coefficient_standard_errors")
  bad<-z$prediction;bad$mean_functions<-matrix(1:8,2,4)
  expect_error(etr_generalized_function_on_scalar_prediction_frame(bad),
    "mean_functions")
  bad<-z$prediction;bad$extrapolation_flags<-c(FALSE,NA)
  expect_error(etr_generalized_function_on_scalar_prediction_frame(bad),
    "extrapolation_flags")
  bad<-z$contrast;bad$lower[1]<-2
  expect_error(etr_generalized_function_on_scalar_mean_difference_frame(bad),
    "lower")
  bad<-z$fit;bad$exposure[1,1]<-0
  expect_error(etr_generalized_function_on_scalar_exposure_frame(bad),
    "exposure")
  bad<-z$fit;bad["exposure"]<-list(NULL)
  expect_error(etr_generalized_function_on_scalar_exposure_frame(bad),
    "does not contain")
  bad<-z$fit;bad$exposure<-NULL
  expect_error(etr_generalized_function_on_scalar_exposure_frame(bad),
    "explicit native R record")
  bad<-z$sparse;bad$metadata$curve_id<-c("a","b")
  expect_error(etr_sparse_fpca_score_frame(bad),"overwrite")
  bad<-z$sparse;bad$scores[1,2]<-Inf
  expect_error(etr_sparse_mfpca_score_frame(bad),"scores")
})

test_that("six adapter mappings retain open typed-Python source gaps",{
  names<-c("sparse_fpca_score_frame","sparse_mfpca_score_frame",
    "generalized_function_on_scalar_coefficient_frame",
    "generalized_function_on_scalar_prediction_frame",
    "generalized_function_on_scalar_mean_difference_frame",
    "generalized_function_on_scalar_exposure_frame")
  p<-etr_native_parity_catalog()
  rows<-p[p$is_python_function & p$python_name %in% names,,drop=FALSE]
  expect_equal(nrow(rows),6L)
  expect_identical(sort(rows$native_r_candidate),
    sort(paste0("etr_",names)))
  expect_true(all(rows$native_implementation_started))
  expect_true(all(rows$source_contract_gap_unresolved))
  expect_false(any(rows$one_to_one_native_contract_complete))
  expect_equal(sum(p$is_python_function & p$named_native_candidate),324L)
  expect_equal(sum(p$native_implementation_started),299L)
  expect_equal(sum(p$source_contract_gap_unresolved),146L)
})

test_that("six observation frames match published Python 1.2 source records",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned published Python 1.2 frame oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as et
def _sf_obj(cls, **fields):
    obj=object.__new__(cls)
    for name,value in fields.items():
        object.__setattr__(obj,name,value)
    return obj
_sf_fit=_sf_obj(et.GeneralizedFunctionOnScalarResult,
    time=np.array([0.,.5,1.]),family='poisson',link='log',
    coefficient_names=('Intercept','treatment'),
    coefficient_functions=np.array([[1.,2.,3.],[4.,5.,6.]]),
    coefficient_standard_errors=np.full((2,3),.25),
    source_curve_ids=('c1','c2'),
    exposure=np.array([[2.,2.,2.],[3.,3.,4.]]),
    exposure_units='hours',exposure_expanded_from_curve=False)
_sf_band=_sf_obj(et.GeneralizedFunctionOnScalarBandResult,
    reference=_sf_fit,lower=_sf_fit.coefficient_functions-.5,
    upper=_sf_fit.coefficient_functions+.5,
    critical_values=np.array([2.,2.5]))
_sf_pred=_sf_obj(et.GeneralizedFunctionOnScalarPredictionResult,
    reference=_sf_fit,profile_ids=('A','B'),
    linear_predictor_functions=np.array([[1.,2.,3.],[4.,5.,6.]]),
    linear_predictor_standard_errors=np.full((2,3),.2),
    mean_functions=np.array([[11.,12.,13.],[14.,15.,16.]]),
    mean_standard_errors=np.full((2,3),.3),
    prediction_scale='response',rate_functions=np.array(
      [[1.,2.,3.],[4.,5.,6.]]),
    expected_count_functions=None,exposure_profiles=None,
    extrapolation_flags=np.array([False,True]))
_sf_predband=_sf_obj(et.GeneralizedFunctionOnScalarPredictionBandResult,
    prediction=_sf_pred,linear_lower=_sf_pred.linear_predictor_functions-1.,
    linear_upper=_sf_pred.linear_predictor_functions+1.,
    mean_lower=_sf_pred.mean_functions-2.,mean_upper=_sf_pred.mean_functions+2.,
    critical_values=np.array([2.,2.5]))
_sf_contrast=_sf_obj(et.GeneralizedFunctionOnScalarMeanDifferenceResult,
    prediction_bootstrap=_sf_obj(
      et.GeneralizedFunctionOnScalarPredictionBootstrapResult,
      prediction=_sf_pred),
    estimate=np.array([.1,.2,.3]),standard_error=np.array([.01,.02,.03]),
    lower=np.array([.05,.1,.2]),upper=np.array([.15,.3,.4]),
    profile_a='A',profile_b='B',critical_value=2.5,
    contrast_scale='response_difference',inference_scale='response',
    interval_exceeds_physical_bounds=False)
_sf_sparse=_sf_obj(et.SparseFPCAResult,curve_ids=('c1','c2'),
    metadata=pd.DataFrame({'group':['control','treatment']}),
    scores=np.array([[1.,2.],[3.,4.]]),n_components=2)
_sf_multi=_sf_obj(et.SparseMFPCAResult,curve_ids=('c1','c2'),
    metadata=pd.DataFrame({'group':['control','treatment']}),
    scores=np.array([[1.,2.],[3.,4.]]),n_components=2)
_sf_python={
  'coefficient':et.generalized_function_on_scalar_coefficient_frame(_sf_fit),
  'coefficient_band':et.generalized_function_on_scalar_coefficient_frame(_sf_band),
  'prediction':et.generalized_function_on_scalar_prediction_frame(_sf_pred),
  'prediction_band':et.generalized_function_on_scalar_prediction_frame(_sf_predband),
  'difference':et.generalized_function_on_scalar_mean_difference_frame(_sf_contrast),
  'exposure':et.generalized_function_on_scalar_exposure_frame(_sf_fit),
  'sparse':et.sparse_fpca_score_frame(_sf_sparse),
  'multivariate':et.sparse_mfpca_score_frame(_sf_multi)
}
")
  z<-.etr_scientific_frame_fixtures()
  r<-list(coefficient=etr_generalized_function_on_scalar_coefficient_frame(
    z$fit),
    coefficient_band=etr_generalized_function_on_scalar_coefficient_frame(
      z$coef_band),
    prediction=etr_generalized_function_on_scalar_prediction_frame(
      z$prediction),
    prediction_band=etr_generalized_function_on_scalar_prediction_frame(
      z$prediction_band),
    difference=etr_generalized_function_on_scalar_mean_difference_frame(
      z$contrast),
    exposure=etr_generalized_function_on_scalar_exposure_frame(z$fit),
    sparse=etr_sparse_fpca_score_frame(z$sparse),
    multivariate=etr_sparse_mfpca_score_frame(z$sparse))
  for(name in names(r)){
    # Python None columns are object dtype; reticulate may convert them
    # differently from native NA_real_. Compare non-null fields directly.
    p<-reticulate::py_eval(
      paste0("_sf_python['",name,"']"),convert=TRUE)
    expect_identical(names(r[[name]]),names(p),info=name)
    for(column in names(p)){
      if(name=="prediction" && column%in%
        c("expected_count","exposure"))next
      if(name=="prediction_band" && column%in%
        c("expected_count","exposure"))next
      expect_equal(r[[name]][[column]],p[[column]],
        tolerance=1e-12,ignore_attr=TRUE,info=paste(name,column))
    }
  }
  audit<-reticulate::py_eval(
    "_sf_python['exposure'].attrs['exposure_audit']",convert=TRUE)
  for(key in names(attr(r$exposure,"exposure_audit")))
    expect_equal(attr(r$exposure,"exposure_audit")[[key]],
      audit[[key]],tolerance=1e-12,info=key)
})
