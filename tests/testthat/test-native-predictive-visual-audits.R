# Pinned published Python 1.2 plotting.py predictive and bootstrap figure witnesses.

.etr_predictive_visual_fixture <- function(){
  cv<-list(fold_losses=data.frame(
    n_components=c(2L,1L,1L,2L,3L),
    loss=c(4,2,4,6,5)),
    loss="mse",family="gaussian")
  nested<-list(outer_folds=data.frame(
    outer_fold=c(0L,1L,2L),loss=c(.9,.6,.8)),loss="mse")
  cmp<-data.frame(coefficient=c("beta","beta","gamma","beta"),
    time=c(2,0,1,1),
    full_refit_to_fixed_covariance_width_ratio=c(1.4,1.1,9,1.2),
    stringsAsFactors=FALSE)
  widths<-matrix(c(4,5,3,6,2,7),nrow=3L,byrow=TRUE)
  centers<-matrix(c(.2,.5,.3,.6,.4,.7),nrow=3L,byrow=TRUE)
  scan<-list(candidate_components=c(1L,2L,3L),
    target_curve_ids=c("first","second"),
    widths=widths,centers=centers)
  selected<-list(scan=scan,selected_components=c(2L,NA_real_))
  list(cv=cv,nested=nested,comparison=cmp,scan=scan,selection=selected)
}

test_that("predictive CV plots respect source fold aggregation and order",{
  x<-.etr_predictive_visual_fixture()
  grDevices::pdf(file=tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  z<-etr_plot_fpca_regression_cv(x$cv)
  expect_identical(names(z$summary),c("n_components",
    "mean_loss","sd_loss","n_folds","se_loss"))
  expect_identical(z$summary$n_components,1:3)
  expect_equal(z$summary$mean_loss,c(3,5,5))
  expect_equal(z$summary$sd_loss,c(sqrt(2),sqrt(2),0))
  expect_equal(z$summary$se_loss,c(1,1,0))
  expect_identical(z$summary$n_folds,c(2L,2L,1L))
  expect_equal(z$errorbar$lower,c(2,4,5))
  expect_equal(z$errorbar$upper,c(4,6,5))
  expect_identical(z$provenance$variance_ddof,1L)
  n<-etr_plot_nested_fpca_regression_cv(x$nested)
  expect_equal(n$line$x,c(1,2,3))
  expect_equal(n$line$y,c(.9,.6,.8))
  bad<-x$cv;bad$fold_losses$loss[1L]<-NA_real_
  expect_error(etr_plot_fpca_regression_cv(bad),"finite")
  bad<-x$nested;bad$outer_folds$outer_fold[1L]<--1
  expect_error(etr_plot_nested_fpca_regression_cv(bad),"nonnegative")
})

test_that("bootstrap comparison and FPCA truncation plots retain source geometry",{
  x<-.etr_predictive_visual_fixture()
  grDevices::pdf(file=tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  a<-etr_plot_functional_mixed_effects_bootstrap_comparison(
    x$comparison,"beta")
  expect_equal(a$line$x,c(0,1,2))
  expect_equal(a$line$y,c(1.1,1.2,1.4))
  expect_identical(a$identity_baseline,1)
  expect_error(etr_plot_functional_mixed_effects_bootstrap_comparison(
    x$comparison,"unknown"),"Unknown coefficient")
  b<-etr_plot_fpca_wild_bootstrap_truncation_scan(
    x$selection,target="first",metric="width")
  expect_equal(b$line$x,1:3)
  expect_equal(b$line$y,c(4,3,2))
  expect_identical(b$selected_inference_components,2L)
  expect_false(b$provenance$python_numeric_target_index_parity)
  c<-etr_plot_fpca_wild_bootstrap_truncation_scan(
    x$selection,target="second",metric="center")
  expect_equal(c$line$y,c(.5,.6,.7))
  expect_true(is.na(c$selected_inference_components))
  d<-etr_plot_fpca_wild_bootstrap_truncation_scan(x$scan,target=2L)
  expect_equal(d$line$y,c(5,6,7))
  expect_error(etr_plot_fpca_wild_bootstrap_truncation_scan(
    x$scan,target="missing"),"target")
  expect_error(etr_plot_fpca_wild_bootstrap_truncation_scan(
    x$scan,metric="variance"),"metric")
  expect_false(any(etr_native_parity_catalog()$one_to_one_native_contract_complete))
})

test_that("predictive source graphics are mapped but not fully certified",{
  names<-c("plot_fpca_regression_cv",
    "plot_nested_fpca_regression_cv",
    "plot_functional_mixed_effects_bootstrap_comparison",
    "plot_fpca_wild_bootstrap_truncation_scan")
  z<-etr_native_parity_catalog()
  for(nm in names){
    row<-z[z$is_python_function&z$python_name==nm,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_identical(row$native_r_candidate,paste0("etr_",nm))
    expect_true(row$native_implementation_started)
    expect_true(row$source_contract_gap_unresolved)
    expect_false(row$one_to_one_native_contract_complete)
  }
  expect_equal(sum(z$is_python_function&z$named_native_candidate),326L)
  expect_equal(sum(z$native_implementation_started),301L)
  expect_equal(sum(z$source_contract_gap_unresolved),148L)
})

test_that("source Python 1.2 direct Matplotlib lines reproduce native geometry",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Published Python 1.2 predictive visual source oracles are opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import eyetrajectoriespy as et
def _gp_record(cls, **fields):
    obj=object.__new__(cls)
    for key,value in fields.items():
        object.__setattr__(obj,key,value)
    return obj
_pcv=_gp_record(et.FPCARegressionCVResult,
    fold_losses=pd.DataFrame({'n_components':[2,1,1,2,3],
                              'loss':[4.,2.,4.,6.,5.]}),
    loss='mse',family='gaussian')
_pnested=_gp_record(et.FPCANestedRegressionCVResult,
    outer_folds=pd.DataFrame({'outer_fold':[0,1,2],'loss':[.9,.6,.8]}),
    loss='mse')
_pcomparison=pd.DataFrame({
    'coefficient':['beta','beta','gamma','beta'],
    'time':[2.,0.,1.,1.],
    'full_refit_to_fixed_covariance_width_ratio':[1.4,1.1,9.,1.2]})
_pwidth=np.array([[4.,5.],[3.,6.],[2.,7.]])
_pcenter=np.array([[.2,.5],[.3,.6],[.4,.7]])
_pscan=_gp_record(et.FPCAWildBootstrapTruncationScanResult,
    candidate_components=(1,2,3),target_curve_ids=('first','second'),
    widths=_pwidth,centers=_pcenter)
_psel=_gp_record(et.FPCAWildBootstrapTruncationSelectionResult,
    scan=_pscan,selected_components=np.array([2.,np.nan]))
_p_cv_summary=et.summarise_fpca_regression_cv(_pcv)
_paxes=[
    et.plot_fpca_regression_cv(_pcv),
    et.plot_nested_fpca_regression_cv(_pnested),
    et.plot_functional_mixed_effects_bootstrap_comparison(
        _pcomparison,coefficient='beta'),
    et.plot_fpca_wild_bootstrap_truncation_scan(
        _psel,target='first',metric='width'),
    et.plot_fpca_wild_bootstrap_truncation_scan(
        _psel,target='second',metric='center')]
_pgeometry=[
    {'x':np.asarray(ax.lines[0].get_xdata(),dtype=float),
     'y':np.asarray(ax.lines[0].get_ydata(),dtype=float),
     'n_lines':len(ax.lines)}
    for ax in _paxes]
for ax in _paxes:
    plt.close(ax.figure)
",convert=FALSE)
  x<-.etr_predictive_visual_fixture()
  grDevices::pdf(file=tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  native<-list(etr_plot_fpca_regression_cv(x$cv),
    etr_plot_nested_fpca_regression_cv(x$nested),
    etr_plot_functional_mixed_effects_bootstrap_comparison(
      x$comparison,"beta"),
    etr_plot_fpca_wild_bootstrap_truncation_scan(
      x$selection,target="first"),
    etr_plot_fpca_wild_bootstrap_truncation_scan(
      x$selection,target="second",metric="center"))
  source<-reticulate::py_to_r(reticulate::py_get_attr(
    reticulate::py,"_pgeometry"))
  expect_length(source,length(native))
  for(i in seq_along(native)){
    expect_equal(native[[i]]$line$x,as.numeric(source[[i]]$x),
      tolerance=1e-12,info=paste("x",i))
    expect_equal(native[[i]]$line$y,as.numeric(source[[i]]$y),
      tolerance=1e-12,info=paste("y",i))
  }
  py_summary<-reticulate::py_to_r(reticulate::py_get_attr(
    reticulate::py,"_p_cv_summary"))
  native_summary<-native[[1L]]$summary
  expect_identical(names(native_summary),names(py_summary))
  expect_equal(nrow(native_summary),nrow(py_summary))
  for(col in names(py_summary))
    expect_equal(as.numeric(native_summary[[col]]),
      as.numeric(py_summary[[col]]),tolerance=1e-12,info=paste("cv",col))
  expect_equal(source[[4L]]$n_lines,2L)
  expect_equal(source[[5L]]$n_lines,1L)
})
