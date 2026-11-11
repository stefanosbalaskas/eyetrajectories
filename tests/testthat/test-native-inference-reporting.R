# Published Python 1.2.0 reporting.py source (pinned release commit).
# Native output is a declarative record subset; no estimator is refitted.
.etr_inference_reporting_fixtures <- function() {
  projection<-list(upper=c(1.2,2.4),lower=c(.8,1.6),
    reference_se=c(.1,.2),n_bootstrap=101L,multiplier="rademacher",
    residual_components=2L,inference_components=1L,
    confidence_level=.95,independent_unit_column=NULL)
  future<-list(upper=c(1.5,2.5),lower=c(.5,1.5),
    centered_residuals=c(-1,0,1),n_bootstrap=101L,
    n_targets=2L,confidence_level=.95)
  uncertainty<-list(slope_upper=matrix(c(.2,.3,.4,.5),2L,2L),
    slope_lower=matrix(c(0,.1,.2,.3),2L,2L),
    prediction_upper=c(1.3,2.3),prediction_lower=c(.7,1.7),
    n_bootstrap=101L,n_components=2L,resampling_unit="participant",
    scaling="none",level=.95)
  slope_band<-list(regression_uncertainty=list(
    reference_fpca=list(dimension_names=c("x","y"))),
    critical_values=c(2.1,2.2),confidence_level=.95,
    simultaneous_scope="global")
  nested<-list(outer_folds=data.frame(loss=c(.4,.5,.45),
    selected_n_components=c(1L,2L,1L)),
    outer_splits=3L,inner_splits=2L,cv_unit="group",
    selection_rule="minimum",loss="rmse")
  family<-list(projection_result=projection,
    reject_familywise=c(TRUE,FALSE),n_targets=2L,
    pvalue_correction="plus_one",significance_level=.05,
    global_statistic=2.3,global_p_value=.1)
  monte<-list(family_test_result=family,
    adjusted_decision_stable=c(TRUE,FALSE),n_bootstrap=101L,
    confidence_level=.95,global_tail_probability=.1,
    global_interval_lower=.05,global_interval_upper=.2,n_targets=2L)
  simultaneous<-list(projection_result=projection,
    lower=c(.7,1.5),upper=c(1.3,2.5),confidence_level=.95,
    n_targets=2L,critical_value=2.5)
  list(projection=projection,future=future,uncertainty=uncertainty,
    slope_band=slope_band,nested=nested,family=family,monte=monte,
    simultaneous=simultaneous)
}
.etr_inference_reporting_native <- function(z) {
  list(projection=etr_fpca_wild_bootstrap_projection_reporting_text(
    z$projection),
    future=etr_fpca_regression_future_prediction_reporting_text(z$future),
    uncertainty=etr_fpca_regression_uncertainty_reporting_text(
      z$uncertainty),
    slope_band=etr_fpca_regression_slope_band_reporting_text(
      z$slope_band),
    nested=etr_fpca_nested_regression_cv_reporting_text(z$nested),
    family=etr_fpca_wild_bootstrap_family_test_reporting_text(z$family),
    monte=etr_fpca_wild_bootstrap_monte_carlo_reporting_text(z$monte),
    simultaneous=etr_fpca_wild_bootstrap_simultaneous_reporting_text(
      z$simultaneous))
}
test_that("eight native R inference reports preserve source scope",{
  z<-.etr_inference_reporting_fixtures()
  output<-.etr_inference_reporting_native(z)
  expect_identical(length(output),8L)
  expect_true(all(vapply(output,function(x)
    is.character(x)&&length(x)==1L&&nzchar(x),logical(1L))))
  expect_match(output$projection,"not future-outcome prediction intervals")
  expect_match(output$future,"not heteroscedasticity-robust")
  expect_match(output$uncertainty,"not prediction intervals for future noisy")
  expect_match(output$slope_band,"does not claim coverage between grid points")
  expect_match(output$nested,"complete selection-and-fit pipeline")
  expect_match(output$family,"strong family-wise error control.*not claimed")
  expect_match(output$monte,"finite-bootstrap simulation precision")
  expect_match(output$simultaneous,"Simultaneity applies only to the fixed")
  expect_identical(output,.etr_inference_reporting_native(z))
})

test_that("native inference reporting rejects undeclared or unsafe inputs",{
  z<-.etr_inference_reporting_fixtures()
  bad<-z$projection;bad$upper[1]<-0
  expect_error(etr_fpca_wild_bootstrap_projection_reporting_text(bad),
    "bounds")
  bad<-z$projection;bad$multiplier<-"malicious'"
  expect_error(etr_fpca_wild_bootstrap_projection_reporting_text(bad),
    "identifier")
  bad<-z$future;bad$centered_residuals<-1
  expect_error(etr_fpca_regression_future_prediction_reporting_text(bad),
    "centered_residuals")
  bad<-z$uncertainty;bad$slope_lower<-matrix(0,1,4)
  expect_error(etr_fpca_regression_uncertainty_reporting_text(bad),
    "bounds")
  bad<-z$slope_band;bad$critical_values<-1
  expect_error(etr_fpca_regression_slope_band_reporting_text(bad),
    "critical values must match distinct functional dimension names")
  bad<-z$nested;bad$outer_folds$selected_n_components[1]<-1.5
  expect_error(etr_fpca_nested_regression_cv_reporting_text(bad),
    "positive whole")
  alternate<-z$family;alternate$pvalue_correction<-"none"
  expect_match(etr_fpca_wild_bootstrap_family_test_reporting_text(
    alternate),"empirical exceedance proportion")
  bad<-z$family;bad$pvalue_correction<-"raw"
  expect_error(etr_fpca_wild_bootstrap_family_test_reporting_text(bad),
    "plus_one or none")
  bad<-z$family;bad$reject_familywise[1]<-NA
  expect_error(etr_fpca_wild_bootstrap_family_test_reporting_text(bad),
    "reject_familywise")
  bad<-z$monte;bad$global_interval_lower<-.5
  expect_error(etr_fpca_wild_bootstrap_monte_carlo_reporting_text(bad),
    "probability")
  bad<-z$simultaneous;bad$critical_value<--1
  expect_error(etr_fpca_wild_bootstrap_simultaneous_reporting_text(bad),
    "nonnegative")
  expect_error(etr_fpca_regression_future_prediction_reporting_text(
    z$future,digits=-1L),"digits")
})

test_that("eight frozen reports map but remain uncertified",{
  expected<-c("fpca_wild_bootstrap_projection_reporting_text",
    "fpca_regression_future_prediction_reporting_text",
    "fpca_regression_uncertainty_reporting_text",
    "fpca_regression_slope_band_reporting_text",
    "fpca_nested_regression_cv_reporting_text",
    "fpca_wild_bootstrap_family_test_reporting_text",
    "fpca_wild_bootstrap_monte_carlo_reporting_text",
    "fpca_wild_bootstrap_simultaneous_reporting_text")
  api<-etr_native_parity_catalog()
  candidates<-api[api$python_name%in%expected & api$is_python_function,]
  expect_equal(nrow(candidates),8L)
  expect_true(all(candidates$native_implementation_started))
  ledger<-utils::read.csv(system.file("extdata",
    "native_source_contract_gaps_stage22.csv",package="eyetrajectories"),
    stringsAsFactors=FALSE)
  witnesses<-ledger[match(candidates$python_name,ledger$python_name),,drop=FALSE]
  expect_false(anyNA(witnesses$python_name))
  expect_identical(as.logical(candidates$source_contract_gap_unresolved),
    as.logical(witnesses$unresolved_source_gap))
  expect_identical(sort(candidates$native_r_candidate),
    sort(paste0("etr_",expected)))
  expect_false(any(candidates$one_to_one_native_contract_complete))
  expect_gte(sum(api$is_python_function & api$named_native_candidate),332L)
  expect_gte(sum(api$native_implementation_started),307L)
  expect_gte(sum(api$source_contract_gap_unresolved),154L)
  expect_false(any(api$one_to_one_native_contract_complete))
})

test_that("frozen Python 1.2 source returns identical report strings",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Published Python 1.2 inference report strings are opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as et
from types import SimpleNamespace as NS
def _report_record(cls, **fields):
    obj=object.__new__(cls)
    for key, value in fields.items():
        object.__setattr__(obj,key,value)
    return obj
_rp=NS(upper=np.array([1.2,2.4]),lower=np.array([.8,1.6]),
    reference_se=np.array([.1,.2]),n_bootstrap=101,
    multiplier='rademacher',residual_components=2,
    inference_components=1,confidence_level=.95,
    independent_unit_column=None,n_targets=2)
_rf=NS(upper=np.array([1.5,2.5]),lower=np.array([.5,1.5]),
    centered_residuals=np.array([-1.,0.,1.]),
    n_bootstrap=101,n_targets=2,confidence_level=.95)
_ru=NS(slope_upper=np.array([[.2,.4],[.3,.5]]),
    slope_lower=np.array([[0.,.2],[.1,.3]]),
    prediction_upper=np.array([1.3,2.3]),
    prediction_lower=np.array([.7,1.7]),n_bootstrap=101,
    n_components=2,resampling_unit='participant',scaling='none',level=.95)
_rs=NS(regression_uncertainty=NS(reference_fpca=NS(
    dimension_names=('x','y'))),
    critical_values=np.array([2.1,2.2]),confidence_level=.95,
    simultaneous_scope='global')
_rn=NS(outer_folds=pd.DataFrame({
    'loss':[.4,.5,.45],'selected_n_components':[1,2,1]}),
    outer_splits=3,inner_splits=2,cv_unit='group',
    selection_rule='minimum',loss='rmse')
_rfamily=_report_record(et.FPCAWildBootstrapFamilyTestResult,
    projection_result=_rp,reject_familywise=np.array([True,False]),
    pvalue_correction='plus_one',
    significance_level=.05,global_statistic=2.3,global_p_value=.1)
_rmonte=_report_record(et.FPCAWildBootstrapMonteCarloDiagnosticResult,
    family_test_result=_rfamily,adjusted_decision_stable=np.array(
    [True,False]),confidence_level=.95,
    global_tail_probability=.1,global_interval_lower=.05,
    global_interval_upper=.2)
_rsim=_report_record(et.FPCAWildBootstrapSimultaneousResult,
    projection_result=_rp,lower=np.array([.7,1.5]),
    upper=np.array([1.3,2.5]),confidence_level=.95,
    critical_value=2.5)
_report_strings=dict(
    projection=et.fpca_wild_bootstrap_projection_reporting_text(_rp),
    future=et.fpca_regression_future_prediction_reporting_text(_rf),
    uncertainty=et.fpca_regression_uncertainty_reporting_text(_ru),
    slope_band=et.fpca_regression_slope_band_reporting_text(_rs),
    nested=et.fpca_nested_regression_cv_reporting_text(_rn),
    family=et.fpca_wild_bootstrap_family_test_reporting_text(_rfamily),
    monte=et.fpca_wild_bootstrap_monte_carlo_reporting_text(_rmonte),
    simultaneous=et.fpca_wild_bootstrap_simultaneous_reporting_text(_rsim)
)
")
  expected<-.etr_inference_reporting_native(
    .etr_inference_reporting_fixtures())
  # Direct calls make all eight frozen public export witnesses individually
  # attributable in the source-review packet. The existing Python-side
  # registry provides a second concordance check on the very same records.
  direct<-list(
    projection=reticulate::py_call(
      etpy_get_export("fpca_wild_bootstrap_projection_reporting_text"),
      result=reticulate::py_eval("_rp",convert=FALSE)),
    future=reticulate::py_call(
      etpy_get_export("fpca_regression_future_prediction_reporting_text"),
      result=reticulate::py_eval("_rf",convert=FALSE)),
    uncertainty=reticulate::py_call(
      etpy_get_export("fpca_regression_uncertainty_reporting_text"),
      result=reticulate::py_eval("_ru",convert=FALSE)),
    slope_band=reticulate::py_call(
      etpy_get_export("fpca_regression_slope_band_reporting_text"),
      result=reticulate::py_eval("_rs",convert=FALSE)),
    nested=reticulate::py_call(
      etpy_get_export("fpca_nested_regression_cv_reporting_text"),
      result=reticulate::py_eval("_rn",convert=FALSE)),
    family=reticulate::py_call(
      etpy_get_export("fpca_wild_bootstrap_family_test_reporting_text"),
      result=reticulate::py_eval("_rfamily",convert=FALSE)),
    monte=reticulate::py_call(
      etpy_get_export("fpca_wild_bootstrap_monte_carlo_reporting_text"),
      result=reticulate::py_eval("_rmonte",convert=FALSE)),
    simultaneous=reticulate::py_call(
      etpy_get_export("fpca_wild_bootstrap_simultaneous_reporting_text"),
      result=reticulate::py_eval("_rsim",convert=FALSE))
  )
  expect_identical(names(direct),names(expected))
  for(n in names(expected)){
    from_python<-reticulate::py_eval(paste0("_report_strings['",n,"']"))
    expect_identical(expected[[n]],as.character(from_python),
      info=paste("frozen Python 1.2 text contract",n))
    expect_identical(expected[[n]],as.character(et_to_r(direct[[n]])),
      info=paste("direct Python 1.2 public source callable",n))
  }
})
test_that("fitted native FPCR inference results feed their reporting exports",{
  z<-.etr_wild_projection_fixture()
  x<-z$x
  unit<-"Analyst's unit"
  x$metadata[[unit]]<-x$curve_ids
  projection<-etr_wild_bootstrap_fpca_projection(x,z$y*0,
    n_bootstrap=20L,independent_unit_column=unit)
  expect_match(etr_fpca_wild_bootstrap_projection_reporting_text(projection),
    'unique values of "Analyst\'s unit"',fixed=TRUE)
  simultaneous<-etr_fpca_wild_bootstrap_projection_simultaneous_interval(projection)
  frame<-etr_fpca_wild_bootstrap_simultaneous_frame(simultaneous)
  expect_true(all(frame$familywise_critical_value==0))
  expect_identical(frame$simultaneous_lower,frame$simultaneous_upper)
  expect_match(etr_fpca_wild_bootstrap_simultaneous_reporting_text(simultaneous),
    "reused the 20")
  family<-etr_fpca_wild_bootstrap_projection_family_test(projection,"0_0.0")
  expect_match(etr_fpca_wild_bootstrap_family_test_reporting_text(family),
    "from 20 heteroscedastic")
  mc<-etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(family)
  expect_match(etr_fpca_wild_bootstrap_monte_carlo_reporting_text(mc),
    "same 20 retained")
  bad<-projection
  bad$n_bootstrap<-19L
  expect_error(etr_fpca_wild_bootstrap_projection_reporting_text(bad),
    "n_bootstrap must match")
  uncertainty<-etr_bootstrap_fpca_regression_uncertainty(x,z$y,
    n_bootstrap=20L,n_components=2L,random_state=21L)
  expect_match(etr_fpca_regression_uncertainty_reporting_text(uncertainty),
    "20 paired curve-level")
  future<-etr_fpca_regression_future_prediction_interval(uncertainty,z$y)
  expect_match(etr_fpca_regression_future_prediction_reporting_text(future),
    "reused 20 paired")
  slope<-etr_fpca_regression_slope_simultaneous_band(uncertainty,
    simultaneous_scope="dimension")
  expect_match(etr_fpca_regression_slope_band_reporting_text(slope),
    "a separate maximum over observed time")
})
