# Three native source-scientific Matplotlib plot contracts.
# Frozen eyetrajectoriespy==1.2.0, src/eyetrajectoriespy/plotting.py,
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Developer-scoped artist parity only; Python Axes identity not claimed.

.etr_fpcr_slope_pace_fixture<-function() {
  time<-c(0,.5,1)
  ref<-matrix(c(.1,.2,.3,.5,.6,.7),nrow=3L)
  fpca<-list(time=time,time_unit="s",dimension_names=c("x","y"))
  uncertainty<-list(reference_fpca=fpca,reference_slope=ref,
    slope_lower=ref-.1,slope_upper=ref+.1,level=.95)
  band<-list(regression_uncertainty=uncertainty,lower=ref-.2,
    upper=ref+.2,confidence_level=.9,
    simultaneous_scope="whole_function")
  sparse<-list(score_diagnostics=data.frame(
    n_samples=c(3,4,5,6,7,8),
    condition_number=c(2,Inf,4,0,8,5),
    status_code=c("ok","warn","failed","ok","ok","flagged"),
    stringsAsFactors=FALSE))
  list(uncertainty=uncertainty,band=band,sparse=sparse)
}

.etr_fpcr_slope_pace_pdf<-function(expr){
  path<-tempfile(fileext=".pdf")
  grDevices::pdf(path,width=9,height=6)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(path)
  },add=TRUE)
  force(expr)
}

test_that("strict simultaneous and pointwise FPCR slopes match source geometry",{
  x<-.etr_fpcr_slope_pace_fixture()
  .etr_fpcr_slope_pace_pdf({
    a<-etr_plot_fpca_regression_slope_band(x$band,
      dimension="y",strict_source_record=TRUE)
    b<-etr_plot_fpca_regression_slope_uncertainty(x$uncertainty,
      strict_source_record=TRUE)
    for(r in list(a,b)){
      expect_s3_class(r,"etr_fpca_inference_artist_source_record")
      expect_false(r$matplotlib_object_identity)
      expect_false(r$independently_certified)
      expect_identical(r$python_return_kind,"matplotlib.axes.Axes")
      artist<-r$axes[[1L]]$artists
      expect_identical(vapply(artist,function(z)z$kind,character(1)),
        c("fill_between","line","horizontal_reference"))
      expect_identical(artist[[1L]]$alpha,.2)
      expect_equal(artist[[1L]]$xdata,c(0,.5,1))
      expect_identical(artist[[2L]]$label,"full-sample FPCR slope")
      expect_identical(artist[[3L]]$linestyle,"--")
      expect_equal(artist[[3L]]$ydata,c(0,0))
      expect_identical(r$axes[[1L]]$legend_labels,
        vapply(artist[1:2],function(z)z$label,character(1)))
    }
    expect_identical(a$source_export,"plot_fpca_regression_slope_band")
    expect_identical(a$axes[[1L]]$title,
      "Gaussian FPCR simultaneous slope band")
    expect_identical(a$axes[[1L]]$xlabel,"Time (s)")
    expect_identical(a$axes[[1L]]$ylabel,"Slope for y")
    expect_identical(a$axes[[1L]]$artists[[1L]]$label,
      "90.0% observed-grid whole_function band")
    expect_equal(a$axes[[1L]]$artists[[1L]]$lower,c(.3,.4,.5))
    expect_equal(a$axes[[1L]]$artists[[1L]]$upper,c(.7,.8,.9))
    expect_equal(a$axes[[1L]]$artists[[2L]]$ydata,c(.5,.6,.7))
    expect_identical(b$source_export,
      "plot_fpca_regression_slope_uncertainty")
    expect_identical(b$axes[[1L]]$title,
      "Gaussian FPCR slope uncertainty")
    expect_identical(b$axes[[1L]]$ylabel,"Slope for x")
    expect_identical(b$axes[[1L]]$artists[[1L]]$label,
      "95.0% pointwise percentile envelope")
    expect_equal(b$axes[[1L]]$artists[[1L]]$lower,c(0,.1,.2),
      tolerance=1e-12)
    expect_equal(b$axes[[1L]]$artists[[2L]]$ydata,c(.1,.2,.3))
    # Backward-compatible numerical returns for both functions.
    olda<-etr_plot_fpca_regression_slope_band(x$band,dimension="y")
    oldb<-etr_plot_fpca_regression_slope_uncertainty(x$uncertainty)
    expect_identical(olda$dimension,"y")
    expect_identical(oldb$dimension,"x")
    expect_equal(olda$geometry$lower,c(.3,.4,.5))
    expect_equal(oldb$geometry$reference,c(.1,.2,.3))
    expect_false(olda$provenance$python_axes_return_equivalence)
  })
})

test_that("sparse PACE source artists preserve ok and flagged log scatters",{
  x<-.etr_fpcr_slope_pace_fixture()
  .etr_fpcr_slope_pace_pdf({
    a<-etr_plot_sparse_fpca_score_diagnostics(x$sparse,
      strict_source_record=TRUE)
    expect_s3_class(a,"etr_fpca_inference_artist_source_record")
    expect_identical(a$source_export,
      "plot_sparse_fpca_score_diagnostics")
    expect_identical(a$axes[[1L]]$yscale,"log")
    expect_identical(a$axes[[1L]]$title,
      "Sparse PACE score-system conditioning")
    expect_identical(a$axes[[1L]]$xlabel,
      "Observed samples used for PACE score")
    expect_identical(a$axes[[1L]]$ylabel,
      "Conditional covariance condition number")
    expect_true(a$axes[[1L]]$legend)
    expect_identical(a$axes[[1L]]$legend_labels,
      c("score system ok","flagged/failed score system"))
    expect_identical(vapply(a$axes[[1L]]$artists,
      function(z)z$kind,character(1)),c("scatter","scatter"))
    expect_identical(a$axes[[1L]]$artists[[1L]]$marker,"o")
    expect_identical(a$axes[[1L]]$artists[[2L]]$marker,"x")
    expect_equal(a$axes[[1L]]$artists[[1L]]$offsets,
      unname(cbind(c(3,7),c(2,8))))
    expect_equal(a$axes[[1L]]$artists[[2L]]$offsets,
      unname(cbind(c(5,8),c(4,5))))
    # Source Python creates a single scatter and no legend for only OK.
    only_ok<-x$sparse
    only_ok$score_diagnostics<-data.frame(
      n_samples=c(2,4),condition_number=c(3,7),
      status_code=c("ok","ok"))
    ok<-etr_plot_sparse_fpca_score_diagnostics(only_ok,
      strict_source_record=TRUE)
    expect_length(ok$axes[[1L]]$artists,1L)
    expect_false(ok$axes[[1L]]$legend)
    expect_length(ok$axes[[1L]]$legend_labels,0L)
    only_failed<-x$sparse
    only_failed$score_diagnostics<-data.frame(
      n_samples=c(2,4),condition_number=c(3,7),
      status_code=c("flagged","failed"))
    failed<-etr_plot_sparse_fpca_score_diagnostics(only_failed,
      strict_source_record=TRUE)
    expect_length(failed$axes[[1L]]$artists,1L)
    expect_true(failed$axes[[1L]]$legend)
    expect_identical(failed$axes[[1L]]$legend_labels,
      "flagged/failed score system")
    old<-etr_plot_sparse_fpca_score_diagnostics(x$sparse)
    expect_true(old$provenance$log_y)
    expect_equal(old$geometry$n_samples,as.numeric(3:8))
    expect_identical(old$geometry$ok,c(TRUE,FALSE,FALSE,FALSE,TRUE,FALSE))
  })
})

test_that("invalid plotting source domains and strict flags fail explicitly",{
  x<-.etr_fpcr_slope_pace_fixture()
  .etr_fpcr_slope_pace_pdf({
    expect_error(etr_plot_fpca_regression_slope_band(x$band,
      strict_source_record=1L),"strict_source_record")
    expect_error(etr_plot_fpca_regression_slope_uncertainty(x$uncertainty,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_sparse_fpca_score_diagnostics(x$sparse,
      strict_source_record=0),"strict_source_record")
    expect_error(etr_plot_fpca_regression_slope_band(x$band,
      dimension="other",strict_source_record=TRUE),"dimension")
    bad<-x$band;bad$upper[1L,1L]<--100
    expect_error(etr_plot_fpca_regression_slope_band(bad,
      strict_source_record=TRUE),"inside supplied diagnostic bounds")
    bad<-x$uncertainty;bad$slope_lower[1L,1L]<-Inf
    expect_error(etr_plot_fpca_regression_slope_uncertainty(bad,
      strict_source_record=TRUE),"slope")
    bad<-x$sparse;bad$score_diagnostics$condition_number[]<-0
    expect_error(etr_plot_sparse_fpca_score_diagnostics(bad,
      strict_source_record=TRUE),"positive finite condition numbers")
  })
})

test_that("frozen Python 1.2 Matplotlib band and sparse scatter compare directly",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen source plotting oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_fpcr_slope_pace_fixture()
  .etr_fpcr_slope_pace_pdf({
    ra<-etr_plot_fpca_regression_slope_band(x$band,
      dimension="y",strict_source_record=TRUE)
    rb<-etr_plot_fpca_regression_slope_uncertainty(x$uncertainty,
      dimension="x",strict_source_record=TRUE)
    rc<-etr_plot_sparse_fpca_score_diagnostics(x$sparse,
      strict_source_record=TRUE)
    reticulate::py_run_string("
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et
def _fpcr_obj(cls,**kwargs):
    obj=object.__new__(cls)
    for k,v in kwargs.items(): object.__setattr__(obj,k,v)
    return obj
_t=np.array([0.,.5,1.])
_slope=np.array([[.1,.5],[.2,.6],[.3,.7]])
_fpca=_fpcr_obj(et.FPCAResult,time=_t,time_unit='s',
    dimension_names=('x','y'))
_unc=_fpcr_obj(et.FPCARegressionUncertaintyResult,
    reference_fpca=_fpca,reference_slope=_slope,
    slope_lower=_slope-.1,slope_upper=_slope+.1,level=.95)
_band=_fpcr_obj(et.FPCARegressionSlopeBandResult,
    regression_uncertainty=_unc,lower=_slope-.2,
    upper=_slope+.2,confidence_level=.9,
    simultaneous_scope='whole_function')
_sparse=_fpcr_obj(et.SparseFPCAResult,
    score_diagnostics=pd.DataFrame({
       'n_samples':[3,4,5,6,7,8],
       'condition_number':[2.,np.inf,4.,0.,8.,5.],
       'status_code':['ok','warn','failed','ok','ok','flagged']}))
ax1=et.plot_fpca_regression_slope_band(_band,dimension='y')
ax2=et.plot_fpca_regression_slope_uncertainty(_unc,dimension='x')
ax3=et.plot_sparse_fpca_score_diagnostics(_sparse)
def _slope_record(ax):
    vertices=np.asarray(ax.collections[0].get_paths()[0].vertices)
    return {
      'title':ax.get_title(),'xlabel':ax.get_xlabel(),
      'ylabel':ax.get_ylabel(),
      'legend':[i.get_text() for i in ax.get_legend().get_texts()],
      'alpha':ax.collections[0].get_alpha(),
      'band_label':ax.collections[0].get_label(),
      'line_x':np.asarray(ax.lines[0].get_xdata(),dtype=float),
      'line_y':np.asarray(ax.lines[0].get_ydata(),dtype=float),
      'reference_y':np.asarray(ax.lines[1].get_ydata(),dtype=float),
      'polygon_y':vertices[:,1]}
oracle={
  'band':_slope_record(ax1),
  'point':_slope_record(ax2),
  'sparse':{
    'title':ax3.get_title(),'xlabel':ax3.get_xlabel(),
    'ylabel':ax3.get_ylabel(),'scale':ax3.get_yscale(),
    'legend':[i.get_text() for i in ax3.get_legend().get_texts()],
    'ok':np.asarray(ax3.collections[0].get_offsets(),dtype=float),
    'failed':np.asarray(ax3.collections[1].get_offsets(),dtype=float)}}
plt.close('all')
")
    oracle<-et_to_r(reticulate::py_get_attr(reticulate::py,"oracle"))
    for(k in c("band","point")){
      native<-if(k=="band")ra else rb
      expected<-oracle[[k]]
      ax<-native$axes[[1L]]
      for(field in c("title","xlabel","ylabel"))
        expect_identical(ax[[field]],expected[[field]])
      expect_identical(ax$legend_labels,as.character(expected$legend))
      expect_equal(ax$artists[[1L]]$alpha,expected$alpha,tolerance=0)
      expect_identical(ax$artists[[1L]]$label,expected$band_label)
      expect_equal(ax$artists[[2L]]$xdata,as.numeric(expected$line_x),
        tolerance=0)
      expect_equal(ax$artists[[2L]]$ydata,as.numeric(expected$line_y),
        tolerance=1e-12)
      expect_equal(ax$artists[[3L]]$ydata,
        as.numeric(expected$reference_y),tolerance=1e-12)
      for(value in c(ax$artists[[1L]]$lower,ax$artists[[1L]]$upper))
        expect_true(any(abs(as.numeric(expected$polygon_y)-value)<1e-10))
    }
    sparse<-oracle$sparse
    for(field in c("title","xlabel","ylabel"))
      expect_identical(rc$axes[[1L]][[field]],sparse[[field]])
    expect_identical(rc$axes[[1L]]$yscale,sparse$scale)
    expect_identical(rc$axes[[1L]]$legend_labels,
      as.character(sparse$legend))
    expect_equal(rc$axes[[1L]]$artists[[1L]]$offsets,
      as.matrix(sparse$ok),tolerance=0,ignore_attr=TRUE)
    expect_equal(rc$axes[[1L]]$artists[[2L]]$offsets,
      as.matrix(sparse$failed),tolerance=0,ignore_attr=TRUE)
  })
})
