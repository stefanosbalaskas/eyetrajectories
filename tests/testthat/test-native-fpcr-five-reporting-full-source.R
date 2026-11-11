# Frozen eyetrajectoriespy==1.2.0 at c1cd95ad718327550f7e55393ff38582872f7a94.
# Complete source reporting strings from scientific typed Python dataclasses;
# native R record semantics, not Python runtime class identity.
.etr_fpcr_five_source_fixture<-function(variant="base") {
  stopifnot(variant %in% c("base","alternate"))
  alt<-identical(variant,"alternate")
  sims<-matrix(c(.91,.76,.87,.83,.93,.71),3L,2L)
  uncertainty<-list(
    slope_lower=matrix(c(.1,.2,.3,.4,.5,.6),3L,2L),
    slope_upper=matrix(c(.9,1.,1.1,1.2,1.3,1.4),3L,2L),
    prediction_lower=c(.4,1.6),prediction_upper=c(1.2,2.4),
    bootstrap_slopes=array(0,c(9L,3L,2L)),
    n_components=2L,scaling=if(alt) "Fisher's σ" else "none",
    resampling_unit=if(alt) "participant" else "curve",
    level=if(alt) .95 else .9)
  future<-list(
    lower=c(.6,1.6),upper=c(1.8,2.9),
    centered_residuals=c(-1.1,-.3,.1,1.3),
    predictive_draws=matrix(0,9L,2L),
    confidence_level=if(alt) .9 else .95)
  band<-list(
    regression_uncertainty=list(
      reference_fpca=list(dimension_names=c("x","gaze_β"))),
    critical_values=c(2.145,3.005),
    confidence_level=if(alt) .9 else .95,
    simultaneous_scope=if(alt) "dimension" else "global")
  nested<-list(
    outer_folds=data.frame(loss=c(.41,.56,.48,.45),
                           selected_n_components=c(1L,2L,1L,3L)),
    outer_splits=4L,inner_splits=3L,
    cv_unit=if(alt) "curve" else "group",
    selection_rule=if(alt) "one_se" else "minimum",loss="rmse")
  envelope<-list(
    similarities=sims,level=if(alt) .95 else .9,
    resampling_unit=if(alt) "participant" else "curve")
  list(future=future,uncertainty=uncertainty,band=band,
       nested=nested,envelope=envelope)
}
.etr_fpcr_five_source_texts<-function(z,digits){
  c(
    etr_fpca_regression_future_prediction_reporting_text(z$future,digits),
    etr_fpca_regression_uncertainty_reporting_text(z$uncertainty,digits),
    etr_fpca_regression_slope_band_reporting_text(z$band,digits),
    etr_fpca_nested_regression_cv_reporting_text(z$nested,digits),
    etr_fpca_component_envelope_reporting_text(z$envelope,digits))
}
test_that("five source FPCR reports preserve inference interpretations", {
  a<-.etr_fpcr_five_source_texts(.etr_fpcr_five_source_fixture(),3L)
  b<-.etr_fpcr_five_source_texts(.etr_fpcr_five_source_fixture("alternate"),3L)
  expect_identical(length(a),5L)
  expect_true(all(nzchar(a)))
  expect_match(a[[1L]],"residual exchangeability",ignore.case=TRUE)
  expect_match(a[[1L]],"not heteroscedasticity-robust",fixed=TRUE)
  expect_match(a[[2L]],"scaling='none'",fixed=TRUE)
  expect_match(a[[2L]],"not prediction intervals for future noisy outcomes",fixed=TRUE)
  expect_match(a[[3L]],"x=2.145, gaze_β=3.005",fixed=TRUE)
  expect_match(a[[3L]],"not claim coverage between grid points",fixed=TRUE)
  expect_match(a[[4L]],"1×2, 2×1, 3×1",fixed=TRUE)
  expect_match(a[[4L]],"complete selection-and-fit pipeline",fixed=TRUE)
  expect_match(a[[5L]],"not simultaneous confidence bands",fixed=TRUE)
  expect_match(b[[2L]],"scaling=\"Fisher's σ\"",fixed=TRUE)
  expect_match(b[[3L]],"a separate maximum",fixed=TRUE)
  expect_match(b[[4L]],"curve-level folds",fixed=TRUE)
})
test_that("five FPCR reporting contracts reject invalid source-science records",{
  z<-.etr_fpcr_five_source_fixture()
  f<-z$future;f$upper[[1L]]<-.3
  expect_error(etr_fpca_regression_future_prediction_reporting_text(f),"bounds")
  u<-z$uncertainty;u$scaling<-NA_character_
  expect_error(etr_fpca_regression_uncertainty_reporting_text(u),"scaling")
  u<-z$uncertainty;u$resampling_unit<-"tank"
  expect_error(etr_fpca_regression_uncertainty_reporting_text(u),"resampling_unit")
  b<-z$band;b$critical_values<-1
  expect_error(etr_fpca_regression_slope_band_reporting_text(b),"critical values")
  n<-z$nested;n$outer_folds<-data.frame(loss=c(.4,.5))
  expect_error(etr_fpca_nested_regression_cv_reporting_text(n),"outer_folds")
  e<-z$envelope;e$similarities[1,1]<-Inf
  expect_error(etr_fpca_component_envelope_reporting_text(e),"similarities")
  expect_error(etr_fpca_component_envelope_reporting_text(z$envelope,-1L),"digits")
})
test_that("30 exact typed Python FPCR source report strings match native R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python typed scientific source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "import numpy as np",
    "import pandas as pd",
    "import eyetrajectoriespy as et",
    "def _etr_fpcr_text_record(cls,**fields):",
    "    x=object.__new__(cls)",
    "    for k,v in fields.items(): object.__setattr__(x,k,v)",
    "    return x",
    "def _etr_fpcr_five_source(variant,digits):",
    "    alt=(variant=='alternate')",
    "    sim=np.array([[.91,.83],[.76,.93],[.87,.71]])",
    "    ref=_etr_fpcr_text_record(et.FPCAResult,",
    "         dimension_names=('x','gaze_β'))",
    "    unc=_etr_fpcr_text_record(et.FPCARegressionUncertaintyResult,",
    "         reference_fpca=ref,bootstrap_slopes=np.zeros((9,3,2)),",
    "         slope_lower=np.array([[.1,.4],[.2,.5],[.3,.6]]),",
    "         slope_upper=np.array([[.9,1.2],[1.,1.3],[1.1,1.4]]),",
    "         prediction_lower=np.array([.4,1.6]),",
    "         prediction_upper=np.array([1.2,2.4]),n_components=2,",
    "         scaling=\"Fisher's σ\" if alt else 'none',",
    "         resampling_unit='participant' if alt else 'curve',",
    "         level=.95 if alt else .9)",
    "    future=_etr_fpcr_text_record(et.FPCARegressionPredictionIntervalResult,",
    "         lower=np.array([.6,1.6]),upper=np.array([1.8,2.9]),",
    "         centered_residuals=np.array([-1.1,-.3,.1,1.3]),",
    "         predictive_draws=np.zeros((9,2)),",
    "         confidence_level=.9 if alt else .95)",
    "    band=_etr_fpcr_text_record(et.FPCARegressionSlopeBandResult,",
    "         regression_uncertainty=unc,critical_values=np.array([2.145,3.005]),",
    "         confidence_level=.9 if alt else .95,",
    "         simultaneous_scope='dimension' if alt else 'global')",
    "    outer=pd.DataFrame({'loss':[.41,.56,.48,.45],",
    "                        'selected_n_components':[1,2,1,3]})",
    "    nested=_etr_fpcr_text_record(et.FPCANestedRegressionCVResult,",
    "         outer_folds=outer,outer_splits=4,inner_splits=3,",
    "         cv_unit='curve' if alt else 'group',",
    "         selection_rule='one_se' if alt else 'minimum',loss='rmse')",
    "    envelope=_etr_fpcr_text_record(et.FPCAComponentEnvelopeResult,",
    "         similarities=sim,level=.95 if alt else .9,",
    "         resampling_unit='participant' if alt else 'curve')",
    "    return [",
    "       et.fpca_regression_future_prediction_reporting_text(future,digits=digits),",
    "       et.fpca_regression_uncertainty_reporting_text(unc,digits=digits),",
    "       et.fpca_regression_slope_band_reporting_text(band,digits=digits),",
    "       et.fpca_nested_regression_cv_reporting_text(nested,digits=digits),",
    "       et.fpca_component_envelope_reporting_text(envelope,digits=digits)]"
  ),collapse="\n"),convert=FALSE)
  oracle<-reticulate::py_get_attr(reticulate::py,"_etr_fpcr_five_source")
  for(variant in c("base","alternate")){
    z<-.etr_fpcr_five_source_fixture(variant)
    for(digits in c(0L,3L,5L)){
      expected<-reticulate::py_to_r(
        reticulate::py_call(oracle,variant,as.integer(digits)))
      actual<-.etr_fpcr_five_source_texts(z,digits)
      expect_identical(length(actual),length(expected))
      for(i in seq_along(actual))
        expect_identical(actual[[i]],as.character(expected[[i]]),
          info=paste(variant,digits,i))
    }
  }
})
