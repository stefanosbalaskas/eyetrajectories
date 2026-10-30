# Pinned reporting.py, generalized_function_on_scalar.py,
# functional_mixed_effects_diagnostics.py and sparse_multivariate.py.
# Native-only boundaries; Python 1.2.0 exact-string oracles are opt-in.
.etr_native_source_model_fixtures <- function() {
  fit<-list(dimension_name="pupil",family="poisson",link="log",
    basis_size=5L,binomial_denominators=NULL,exposure=NULL,
    exposure_units=NULL)
  band<-list(reference=fit,confidence_level=.95,
    simultaneous_scope="coefficient",
    bootstrap=list(bootstrap_coefficient_functions=array(0,dim=c(4,2,3))))
  residual<-list(trial_diagnostics=data.frame(
    lag_index=c(0L,1L,0L,1L),
    zero_residual_variance=c(FALSE,FALSE,TRUE,TRUE)),
    reference=list(random_slope_predictor=NULL,time_unit="seconds"),
    residual_scale="raw",max_lag=1L)
  sparse<-list(
    dimensions=c("x","y"),curve_ids=c("a","b"),n_components=2L,
    score_diagnostics=data.frame(status_code=c("ok","failed")),
    measurement_error_covariance=diag(2),
    covariance_diagnostics=list(
      requested_action="nearest_psd",applied_action="none",
      correction_frobenius_norm=0),
    provenance=list(sparse_mfpca=list(
      mean_bandwidth=.2,covariance_bandwidth=.5,
      measurement_error_mode="diagonal",
      score_ridge=.001,score_failure_action="record")))
  list(fit=fit,band=band,residual=residual,sparse=sparse)
}
test_that("three new source reports retain scientific limits and exact structure",{
  z<-.etr_native_source_model_fixtures()
  a<-etr_generalized_function_on_scalar_reporting_text(z$fit)
  expect_match(a,"population-averaged marginal interpretation")
  expect_match(a,"marginal log expected counts rather than rates")
  expect_match(a,"No simultaneous coefficient band was requested")
  b<-etr_generalized_function_on_scalar_reporting_text(z$fit,z$band)
  expect_match(b,"95.0% observed-grid coefficient-simultaneous")
  expect_match(b,"4 replicates")
  c<-etr_functional_mixed_effects_residual_reporting_text(z$residual)
  expect_match(c,"1 trial\\(s\\) had exactly zero residual variance")
  expect_match(c,"do not automatically select AR\\(1\\)")
  d<-etr_sparse_mfpca_reporting_text(z$sparse)
  expect_match(d,"2 curve\\(s\\), retaining 2 joint")
  expect_match(d,"1 curve\\(s\\) were scored successfully")
  expect_match(d,"never a rank-K covariance reconstruction")
  expect_match(d,"R_epsilon=\\[\\[1\\., 0\\.\\]")
})

test_that("scientific reporter boundaries fail closed",{
  z<-.etr_native_source_model_fixtures()
  bad<-z$fit;bad$basis_size<-0
  expect_error(etr_generalized_function_on_scalar_reporting_text(bad),
    "basis_size")
  bad<-z$fit;bad$exposure<-matrix(c(1,0),1,2)
  expect_error(etr_generalized_function_on_scalar_reporting_text(bad),
    "exposure")
  bad<-z$band;bad$reference<-list(family="binomial")
  expect_error(etr_generalized_function_on_scalar_reporting_text(z$fit,bad),
    "band.reference")
  bad<-z$residual;bad$residual_scale<-"unknown"
  expect_error(etr_functional_mixed_effects_residual_reporting_text(bad),
    "residual_scale")
  bad<-z$residual;bad$trial_diagnostics$zero_residual_variance[1]<-NA
  expect_error(etr_functional_mixed_effects_residual_reporting_text(bad),
    "trial_diagnostics")
  bad<-z$sparse;bad$measurement_error_covariance[1,1]<-Inf
  expect_error(etr_sparse_mfpca_reporting_text(bad),
    "measurement_error_covariance")
  bad<-z$sparse;bad$score_diagnostics$status_code[2]<-NA
  expect_error(etr_sparse_mfpca_reporting_text(bad),
    "score_diagnostics")
})

test_that("three new reporters remain mapped but not full-domain certified",{
  names<-c("generalized_function_on_scalar_reporting_text",
    "functional_mixed_effects_residual_reporting_text",
    "sparse_mfpca_reporting_text")
  p<-etr_native_parity_catalog()
  x<-p[p$is_python_function&p$python_name%in%names,,drop=FALSE]
  expect_equal(nrow(x),3L)
  expect_identical(sort(x$native_r_candidate),sort(paste0("etr_",names)))
  expect_true(all(x$native_implementation_started))
  expect_true(all(x$source_contract_gap_unresolved))
  expect_false(any(x$one_to_one_native_contract_complete))
  expect_equal(sum(p$is_python_function&p$named_native_candidate),299L)
  expect_equal(sum(p$native_implementation_started),274L)
  expect_equal(sum(p$source_contract_gap_unresolved),121L)
})

test_that("three source model reports match Python 1.2 exact-string oracles",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 source-model report oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as et
def _sr_obj(cls,**kw):
    x=object.__new__(cls)
    for k,v in kw.items(): object.__setattr__(x,k,v)
    return x
_sr_fit=_sr_obj(et.GeneralizedFunctionOnScalarResult,
    dimension_name='pupil',family='poisson',link='log',basis_size=5,
    binomial_denominators=None,exposure=None,exposure_units=None)
_sr_boot=_sr_obj(et.GeneralizedFunctionOnScalarBootstrapResult,
    bootstrap_coefficient_functions=np.zeros((4,2,3)))
_sr_band=_sr_obj(et.GeneralizedFunctionOnScalarBandResult,
    reference=_sr_fit,confidence_level=.95,
    simultaneous_scope='coefficient',bootstrap=_sr_boot)
_sr_reference=_sr_obj(et.FunctionalMixedEffectsResult,
    random_slope_predictor=None,time_unit='seconds')
_sr_residual=_sr_obj(et.FunctionalMixedEffectsResidualDiagnosticsResult,
    trial_diagnostics=pd.DataFrame({
      'lag_index':[0,1,0,1],
      'zero_residual_variance':[False,False,True,True]}),
    reference=_sr_reference,residual_scale='raw',max_lag=1)
_sr_sparse=_sr_obj(et.SparseMFPCAResult,
    dimensions=('x','y'),curve_ids=('a','b'),n_components=2,
    score_diagnostics=pd.DataFrame({'status_code':['ok','failed']}),
    measurement_error_covariance=np.eye(2),
    covariance_diagnostics={
      'requested_action':'nearest_psd','applied_action':'none',
      'correction_frobenius_norm':0},
    provenance={'sparse_mfpca':{
      'mean_bandwidth':.2,'covariance_bandwidth':.5,
      'measurement_error_mode':'diagonal','score_ridge':.001,
      'score_failure_action':'record'}})
_sr_oracle={
    'fit':et.generalized_function_on_scalar_reporting_text(_sr_fit),
    'fit_band':et.generalized_function_on_scalar_reporting_text(
      _sr_fit,band=_sr_band),
    'residual':et.functional_mixed_effects_residual_reporting_text(
      _sr_residual),
    'sparse':et.sparse_mfpca_reporting_text(_sr_sparse)
}
")
  z<-.etr_native_source_model_fixtures()
  results<-list(
    fit=etr_generalized_function_on_scalar_reporting_text(z$fit),
    fit_band=etr_generalized_function_on_scalar_reporting_text(
      z$fit,z$band),
    residual=etr_functional_mixed_effects_residual_reporting_text(
      z$residual),
    sparse=etr_sparse_mfpca_reporting_text(z$sparse))
  for(key in names(results)){
    python<-reticulate::py_eval(paste0("_sr_oracle['",key,"']"),
      convert=TRUE)
    expect_identical(results[[key]],python,
      info=paste("published Python 1.2.0:",key))
  }
})
