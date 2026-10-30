# Three reporting analogues of pinned eyetrajectoriespy==1.2.0
# reporting.py at c1cd95ad718327550f7e55393ff38582872f7a94.
.etr_inference_extension_fixtures <- function() {
  cv<-list(fold_losses=data.frame(
    n_components=c(1L,1L,1L,2L,2L,2L),
    loss=c(.41,.43,.45,.32,.45,.49)),
    n_splits=3L,cv_unit="group",family="gaussian",loss="rmse")
  envelope<-list(similarities=matrix(c(.7,.8,.9,.6,.7,.8),3L,2L),
    resampling_unit="participant",level=.9)
  truncation<-list(scan=list(candidate_components=1:4,
    residual_components=2L),
    selected_components=c(2,3,NaN),width_threshold=.1,
    center_threshold=.2,stability_run=1L)
  list(cv=cv,envelope=envelope,truncation=truncation)
}
test_that("new native reports preserve explicit scientific distinctions",{
  z<-.etr_inference_extension_fixtures()
  cv<-etr_fpca_regression_cv_reporting_text(z$cv)
  heuristic<-etr_fpca_regression_cv_reporting_text(z$cv,rule="one_se")
  envelope<-etr_fpca_component_envelope_reporting_text(z$envelope)
  truncation<-etr_fpca_wild_bootstrap_truncation_reporting_text(z$truncation)
  expect_match(cv,"selected 2 component")
  expect_match(heuristic,"selected 1 component")
  expect_match(heuristic,"parsimony heuristic")
  expect_match(envelope,"not simultaneous confidence bands")
  expect_match(envelope,"FPC1=0.80, FPC2=0.70")
  expect_match(truncation,"h values \\(1, 2, 3, 4\\)")
  expect_match(truncation,"Selected h ranged from 2 to 3 across 2 target")
  missing<-z$truncation;missing$selected_components[]<-NaN
  expect_match(etr_fpca_wild_bootstrap_truncation_reporting_text(missing),
    "No target received a qualifying h")
})

test_that("new inference summaries fail on scientifically invalid records",{
  z<-.etr_inference_extension_fixtures()
  bad<-z$cv;bad$cv_unit<-"unknown"
  expect_error(etr_fpca_regression_cv_reporting_text(bad),"cv_unit")
  expect_error(etr_fpca_regression_cv_reporting_text(z$cv,rule="anything"),
    "rule")
  bad<-z$envelope;bad$similarities[1L,1L]<-NA_real_
  expect_error(etr_fpca_component_envelope_reporting_text(bad),
    "similarities")
  bad<-z$truncation;bad$scan$candidate_components<-c(1,3,4,5)
  expect_error(etr_fpca_wild_bootstrap_truncation_reporting_text(bad),
    "consecutive")
  bad<-z$truncation;bad$width_threshold<--.1
  expect_error(etr_fpca_wild_bootstrap_truncation_reporting_text(bad),
    "width_threshold")
  bad<-z$truncation;bad$stability_run<-.Machine$integer.max
  expect_error(etr_fpca_wild_bootstrap_truncation_reporting_text(bad),
    "stability_run requires")
  bad<-z$truncation;bad$selected_components<-c(4.5,NaN)
  expect_error(etr_fpca_wild_bootstrap_truncation_reporting_text(bad),
    "candidate integers")
})

test_that("3 source reporting functions stay uncertified until full review",{
  names<-c("fpca_regression_cv_reporting_text",
    "fpca_component_envelope_reporting_text",
    "fpca_wild_bootstrap_truncation_reporting_text")
  z<-etr_native_parity_catalog()
  actual<-z[z$is_python_function & z$python_name%in%names,,drop=FALSE]
  expect_equal(nrow(actual),3L)
  expect_identical(sort(actual$native_r_candidate),
    sort(paste0("etr_",names)))
  expect_true(all(actual$native_implementation_started))
  expect_true(all(actual$source_contract_gap_unresolved))
  expect_false(any(actual$one_to_one_native_contract_complete))
  expect_equal(sum(z$is_python_function & z$named_native_candidate),325L)
  expect_equal(sum(z$native_implementation_started),300L)
  expect_equal(sum(z$source_contract_gap_unresolved),147L)
})

test_that("three reports match direct Python 1.2 source strings",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned published Python 1.2 reporter oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as et
from types import SimpleNamespace as NS
def _typed_text_record(cls, **fields):
    obj=object.__new__(cls)
    for key,value in fields.items():
        object.__setattr__(obj,key,value)
    return obj
_cv=NS(fold_losses=pd.DataFrame({
    'n_components':[1,1,1,2,2,2],
    'loss':[.41,.43,.45,.32,.45,.49]}),
    n_splits=3,cv_unit='group',family='gaussian',loss='rmse')
_env=_typed_text_record(et.FPCAComponentEnvelopeResult,
    similarities=np.array([[.7,.6],[.8,.7],[.9,.8]]),
    resampling_unit='participant',level=.9)
_scan=NS(candidate_components=(1,2,3,4),residual_components=2)
_trunc=_typed_text_record(et.FPCAWildBootstrapTruncationSelectionResult,
    scan=_scan,selected_components=np.array([2.,3.,np.nan]),
    width_threshold=.1,center_threshold=.2,stability_run=1)
_text_qualification={
    'cv':et.fpca_regression_cv_reporting_text(_cv),
    'cv_one_se':et.fpca_regression_cv_reporting_text(_cv,rule='one_se'),
    'envelope':et.fpca_component_envelope_reporting_text(_env),
    'truncation':et.fpca_wild_bootstrap_truncation_reporting_text(_trunc)
}
")
  z<-.etr_inference_extension_fixtures()
  targets<-list(cv=etr_fpca_regression_cv_reporting_text(z$cv),
    cv_one_se=etr_fpca_regression_cv_reporting_text(z$cv,rule="one_se"),
    envelope=etr_fpca_component_envelope_reporting_text(z$envelope),
    truncation=etr_fpca_wild_bootstrap_truncation_reporting_text(z$truncation))
  for(name in names(targets)){
    python<-reticulate::py_eval(paste0("_text_qualification['",name,"']"))
    expect_identical(targets[[name]],as.character(python),
      info=paste("direct Python 1.2.0 text for",name))
  }
})
