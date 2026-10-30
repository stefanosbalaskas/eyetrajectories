# Published eyetrajectoriespy==1.2.0 plotting.py numerical geometry
# source oracle, pinned c1cd95ad718327550f7e55393ff38582872f7a94.

.etr_fpcr_inference_plot_fixture <- function(){
  ids<-c("c1","c2","c3")
  projection<-list(target_curve_ids=ids,reference_projection=c(1,2,3),
    lower=c(.8,1.8,2.8),upper=c(1.2,2.2,3.2))
  fpca<-list(dimension_names=c("x","y"),
    time=c(0,.5,1),time_unit="s")
  slope<-matrix(c(.1,.2,.3,.5,.6,.7),nrow=3L)
  unc<-list(reference_fpca=fpca,reference_slope=slope,
    slope_lower=slope-.1,slope_upper=slope+.1,level=.95,
    target_curve_ids=ids,reference_mean_predictions=c(1.1,2.1,3.1),
    prediction_median=c(1,2,3),prediction_lower=c(.7,1.7,2.7),
    prediction_upper=c(1.3,2.3,3.3))
  prediction<-list(regression_uncertainty=unc,median=c(1,2,3),
    lower=c(.6,1.6,2.6),upper=c(1.4,2.4,3.4))
  band<-list(regression_uncertainty=unc,lower=slope-.2,
    upper=slope+.2,confidence_level=.95,
    simultaneous_scope="whole_function")
  sparse<-list(score_diagnostics=data.frame(n_samples=c(3,4,5,6,7),
    condition_number=c(2,Inf,4,0,8),
    status_code=c("ok","warn","failed","ok","ok"),
    stringsAsFactors=FALSE))
  list(ids=ids,projection=projection,unc=unc,prediction=prediction,
    band=band,sparse=sparse)
}

test_that("source-target intervals use zero-based plot x, retain bounds",{
  x<-.etr_fpcr_inference_plot_fixture()
  grDevices::pdf(file=tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  proj<-etr_plot_fpca_wild_bootstrap_projection(x$projection,max_targets=2L)
  expect_identical(proj$geometry$x,0:1)
  expect_identical(proj$geometry$curve_id,c("c1","c2"))
  expect_equal(proj$geometry$center,c(1,2))
  expect_equal(proj$geometry$lower,c(.8,1.8))
  future<-etr_plot_fpca_regression_future_prediction_interval(x$prediction)
  expect_identical(future$geometry$x,0:2)
  expect_equal(future$geometry$reference,c(1.1,2.1,3.1))
  expect_equal(future$geometry$lower,c(.6,1.6,2.6))
  mean<-etr_plot_fpca_regression_mean_prediction_uncertainty(x$unc)
  expect_equal(mean$geometry$upper,c(1.3,2.3,3.3))
  expect_equal(mean$geometry$reference,c(1.1,2.1,3.1))
  for(z in list(proj,future,mean))
    expect_false(z$provenance$python_axes_return_equivalence)
  expect_error(etr_plot_fpca_wild_bootstrap_projection(x$projection,
    max_targets=0L),"max_targets")
  bad<-x$projection;bad$lower[1L]<-2
  expect_error(etr_plot_fpca_wild_bootstrap_projection(bad),
    "between lower and upper")
})

test_that("source slopes preserve channels, limits and confidence semantics",{
  x<-.etr_fpcr_inference_plot_fixture()
  grDevices::pdf(file=tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  band<-etr_plot_fpca_regression_slope_band(x$band,dimension="y")
  expect_identical(band$dimension,"y")
  expect_equal(band$geometry$time,c(0,.5,1))
  expect_equal(band$geometry$reference,c(.5,.6,.7))
  expect_equal(band$geometry$lower,c(.3,.4,.5))
  expect_equal(band$geometry$upper,c(.7,.8,.9))
  expect_identical(band$confidence_level,.95)
  point<-etr_plot_fpca_regression_slope_uncertainty(x$unc)
  expect_identical(point$dimension,"x")
  expect_equal(point$geometry$reference,c(.1,.2,.3))
  expect_equal(point$geometry$lower,c(0,.1,.2))
  expect_error(etr_plot_fpca_regression_slope_band(
    x$band,dimension="unknown"),"Unknown dimension")
  bad<-x$unc;bad$slope_lower<-matrix(1,1L,2L)
  expect_error(etr_plot_fpca_regression_slope_uncertainty(bad),
    "expected shape")
})

test_that("PACE score diagnostics explicitly classify finite valid conditions",{
  x<-.etr_fpcr_inference_plot_fixture()
  grDevices::pdf(file=tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  z<-etr_plot_sparse_fpca_score_diagnostics(x$sparse)
  expect_identical(z$geometry$finite,c(TRUE,FALSE,TRUE,FALSE,TRUE))
  expect_identical(z$geometry$ok,c(TRUE,FALSE,FALSE,FALSE,TRUE))
  expect_identical(z$geometry$flagged,c(FALSE,FALSE,TRUE,FALSE,FALSE))
  expect_true(z$provenance$log_y)
  bad<-x$sparse;bad$score_diagnostics$condition_number[]<-0
  expect_error(etr_plot_sparse_fpca_score_diagnostics(bad),
    "positive finite condition numbers")
  bad<-x$sparse;bad$score_diagnostics<-data.frame(status_code="ok")
  expect_error(etr_plot_sparse_fpca_score_diagnostics(bad),
    "complete PACE score diagnostics")
})

test_that("six FPCR/PACE plots map to the frozen source but remain unapproved",{
  z<-etr_native_parity_catalog()
  keys<-c("plot_fpca_wild_bootstrap_projection",
    "plot_fpca_regression_future_prediction_interval",
    "plot_fpca_regression_mean_prediction_uncertainty",
    "plot_fpca_regression_slope_band",
    "plot_fpca_regression_slope_uncertainty",
    "plot_sparse_fpca_score_diagnostics")
  for(name in keys){
    row<-z[z$is_python_function&z$python_name==name,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,paste0("etr_",name))
    expect_true(row$native_implementation_started)
    expect_true(row$source_contract_gap_unresolved)
    expect_false(row$one_to_one_native_contract_complete)
  }
  expect_equal(sum(z$is_python_function&z$named_native_candidate),319L)
  expect_equal(sum(z$native_implementation_started),294L)
  expect_equal(sum(z$source_contract_gap_unresolved),141L)
})

test_that("published Python 1.2 axes geometry agrees with native FPCR/PACE",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published Python 1.2 FPCR/PACE source plotting oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import eyetrajectoriespy as et
def _rplot(cls, **values):
    x=object.__new__(cls)
    for name,value in values.items():
        object.__setattr__(x,name,value)
    return x
_ids=('c1','c2','c3')
_proj=_rplot(et.FPCAWildBootstrapProjectionResult,
    target_curve_ids=_ids,reference_projection=np.array([1.,2.,3.]),
    lower=np.array([.8,1.8,2.8]),upper=np.array([1.2,2.2,3.2]),
    bootstrap_projections=np.zeros((2,3)))
_fpca=_rplot(et.FPCAResult,dimension_names=('x','y'),
    time=np.array([0.,.5,1.]),time_unit='s')
_slope=np.array([[.1,.5],[.2,.6],[.3,.7]])
_unc=_rplot(et.FPCARegressionUncertaintyResult,
    reference_fpca=_fpca,reference_slope=_slope,
    slope_lower=_slope-.1,slope_upper=_slope+.1,level=.95,
    target_curve_ids=_ids,
    reference_mean_predictions=np.array([1.1,2.1,3.1]),
    prediction_median=np.array([1.,2.,3.]),
    prediction_lower=np.array([.7,1.7,2.7]),
    prediction_upper=np.array([1.3,2.3,3.3]),
    bootstrap_mean_predictions=np.zeros((2,3)))
_future=_rplot(et.FPCARegressionPredictionIntervalResult,
    regression_uncertainty=_unc,
    median=np.array([1.,2.,3.]),
    lower=np.array([.6,1.6,2.6]),upper=np.array([1.4,2.4,3.4]),
    predictive_draws=np.zeros((2,3)))
_band=_rplot(et.FPCARegressionSlopeBandResult,
    regression_uncertainty=_unc,lower=_slope-.2,upper=_slope+.2,
    confidence_level=.95,simultaneous_scope='whole_function')
_sparse=_rplot(et.SparseFPCAResult,score_diagnostics=pd.DataFrame({
    'n_samples':[3,4,5,6,7],
    'condition_number':[2.,np.inf,4.,0.,8.],
    'status_code':['ok','warn','failed','ok','ok']}))
_plot_axes=[
    et.plot_fpca_wild_bootstrap_projection(_proj,max_targets=2),
    et.plot_fpca_regression_future_prediction_interval(_future),
    et.plot_fpca_regression_mean_prediction_uncertainty(_unc),
    et.plot_fpca_regression_slope_band(_band,dimension='y'),
    et.plot_fpca_regression_slope_uncertainty(_unc),
    et.plot_sparse_fpca_score_diagnostics(_sparse)]
_plot_data=[
    (np.asarray(ax.lines[0].get_xdata(),dtype=float),
     np.asarray(ax.lines[0].get_ydata(),dtype=float))
    if i in (0,1,2,3,4) else
    (np.array([],dtype=float),np.array([],dtype=float))
    for i,ax in enumerate(_plot_axes)]
_plot_sparse_offsets=[
    np.asarray(collection.get_offsets(),dtype=float)
    for collection in _plot_axes[5].collections]
_plot_sparse_yscale=_plot_axes[5].get_yscale()
for ax in _plot_axes:
    plt.close(ax.figure)
",convert=FALSE)
  x<-.etr_fpcr_inference_plot_fixture()
  grDevices::pdf(file=tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  native<-list(
    etr_plot_fpca_wild_bootstrap_projection(x$projection,2L),
    etr_plot_fpca_regression_future_prediction_interval(x$prediction),
    etr_plot_fpca_regression_mean_prediction_uncertainty(x$unc),
    etr_plot_fpca_regression_slope_band(x$band,dimension="y"),
    etr_plot_fpca_regression_slope_uncertainty(x$unc),
    etr_plot_sparse_fpca_score_diagnostics(x$sparse))
  py<-reticulate::py
  source<-reticulate::py_to_r(reticulate::py_get_attr(py,"_plot_data"))
  for(i in seq_len(5L)){
    actual<-if(i<=3L)native[[i]]$geometry else native[[i]]$geometry
    xwant<-if(i<=3L)actual$x else actual$time
    ywant<-if(i<=3L)actual$center else actual$reference
    expect_equal(as.numeric(source[[i]][[1L]]),as.numeric(xwant),
      tolerance=1e-12,info=paste("x",i))
    expect_equal(as.numeric(source[[i]][[2L]]),as.numeric(ywant),
      tolerance=1e-12,info=paste("y",i))
  }
  offsets<-reticulate::py_to_r(reticulate::py_get_attr(py,
    "_plot_sparse_offsets"))
  expect_length(offsets,2L)
  expect_equal(as.numeric(offsets[[1L]][,1L]),c(3,7))
  expect_equal(as.numeric(offsets[[2L]][,1L]),5)
  expect_identical(as.character(reticulate::py_to_r(
    reticulate::py_get_attr(py,"_plot_sparse_yscale"))),"log")
})
