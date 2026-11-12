# Frozen eyetrajectoriespy==1.2.0 plotting.py source scientific
# artist oracle commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Scope: numerical Matplotlib artist geometry, not live Python Axes identity.

.etr_three_predictive_plot_fixture <- function() {
  cv<-list(fold_losses=data.frame(
      n_components=c(2L,1L,1L,2L,3L),
      loss=c(4,2,4,6,5)),loss="mse",family="gaussian")
  nested<-list(outer_folds=data.frame(
      outer_fold=c(0L,1L,2L),loss=c(.9,.6,.8)),
      loss="mse")
  scan<-list(candidate_components=c(1L,2L,3L),
      target_curve_ids=c("first","second"),
      widths=matrix(c(4,5,3,6,2,7),nrow=3L,byrow=TRUE),
      centers=matrix(c(.2,.5,.3,.6,.4,.7),nrow=3L,byrow=TRUE))
  selected<-list(scan=scan,selected_components=c(2L,NA_real_))
  list(cv=cv,nested=nested,scan=scan,selected=selected)
}
.etr_three_predictive_pdf <- function(expr) {
  p<-tempfile(fileext=".pdf")
  grDevices::pdf(p)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(p)
  },add=TRUE)
  force(expr)
}

test_that("FPCR CV artist preserves pandas sample-SE scientific errorbars",{
  z<-.etr_three_predictive_plot_fixture()
  .etr_three_predictive_pdf({
    a<-etr_plot_fpca_regression_cv(z$cv,strict_source_record=TRUE)
    expect_s3_class(a,"etr_predictive_scientific_artist_record")
    expect_false(a$matplotlib_object_identity)
    expect_false(a$independently_certified)
    expect_identical(a$source_export,"plot_fpca_regression_cv")
    expect_identical(a$python_return_kind,"matplotlib.axes.Axes")
    ax<-a$axes[[1L]]
    expect_identical(ax$title,"Predictive FPCA regression CV (gaussian)")
    expect_identical(ax$xlabel,
      "Retained functional principal components")
    expect_identical(ax$ylabel,"Held-out mse")
    expect_false(ax$legend)
    expect_length(ax$artists,1L)
    er<-ax$artists[[1L]]
    expect_identical(er$kind,"errorbar")
    expect_identical(er$marker,"o")
    expect_identical(er$capsize,3)
    expect_equal(er$xdata,c(1,2,3))
    expect_equal(er$ydata,c(3,5,5))
    expect_equal(er$lower,c(2,4,5))
    expect_equal(er$upper,c(4,6,5))
    expect_equal(er$yerr,rbind(c(1,1,0),c(1,1,0)),tolerance=1e-12)
    original<-etr_plot_fpca_regression_cv(z$cv)
    expect_identical(original$summary$n_folds,c(2L,2L,1L))
    expect_equal(original$summary$sd_loss,c(sqrt(2),sqrt(2),0))
    expect_equal(original$summary$se_loss,c(1,1,0),tolerance=1e-12)
    expect_false(original$provenance$python_axes_return_equivalence)
    single<-z$cv
    single$fold_losses<-data.frame(n_components=1L,loss=2)
    b<-etr_plot_fpca_regression_cv(single,strict_source_record=TRUE)
    expect_equal(b$axes[[1L]]$artists[[1L]]$yerr,
      matrix(c(0,0),nrow=2L),tolerance=0)
  })
})

test_that("nested FPCR CV artist preserves original outer fold source order",{
  z<-.etr_three_predictive_plot_fixture()
  .etr_three_predictive_pdf({
    a<-etr_plot_nested_fpca_regression_cv(z$nested,
      strict_source_record=TRUE)
    expect_s3_class(a,"etr_predictive_scientific_artist_record")
    expect_identical(a$source_export,"plot_nested_fpca_regression_cv")
    ax<-a$axes[[1L]]
    expect_identical(ax$title,"Nested predictive FPCA regression")
    expect_identical(ax$xlabel,"Outer fold")
    expect_identical(ax$ylabel,"Outer held-out mse")
    expect_false(ax$legend)
    expect_length(ax$artists,1L)
    expect_identical(ax$artists[[1L]]$kind,"line")
    expect_identical(ax$artists[[1L]]$marker,"o")
    expect_identical(ax$artists[[1L]]$linestyle,"-")
    expect_equal(ax$artists[[1L]]$xdata,c(1,2,3))
    expect_equal(ax$artists[[1L]]$ydata,c(.9,.6,.8))
    expect_equal(etr_plot_nested_fpca_regression_cv(z$nested)$line$y,
      c(.9,.6,.8))
  })
})

test_that("wild scan artists preserve selection and source zero-based targets",{
  z<-.etr_three_predictive_plot_fixture()
  .etr_three_predictive_pdf({
    # Native R default remains one-based; strict mode matches Python zero.
    old<-etr_plot_fpca_wild_bootstrap_truncation_scan(z$selected)
    expect_identical(old$target_curve_id,"first")
    expect_false(old$provenance$python_numeric_target_index_parity)
    first<-etr_plot_fpca_wild_bootstrap_truncation_scan(z$selected,
      strict_source_record=TRUE)
    expect_s3_class(first,"etr_predictive_scientific_artist_record")
    expect_identical(first$source_export,
      "plot_fpca_wild_bootstrap_truncation_scan")
    ax<-first$axes[[1L]]
    expect_identical(ax$title,"Wild-bootstrap truncation scan: first")
    expect_identical(ax$xlabel,"Inference truncation h")
    expect_identical(ax$ylabel,"Interval width")
    expect_length(ax$artists,2L)
    expect_true(ax$legend)
    expect_identical(ax$legend_labels,"selected h=2")
    expect_identical(ax$artists[[1L]]$marker,"o")
    expect_equal(ax$artists[[1L]]$xdata,c(1,2,3))
    expect_equal(ax$artists[[1L]]$ydata,c(4,3,2))
    expect_identical(ax$artists[[2L]]$kind,"vertical_reference")
    expect_identical(ax$artists[[2L]]$linestyle,"--")
    expect_equal(ax$artists[[2L]]$xdata,c(2,2))
    expect_equal(ax$artists[[2L]]$ydata,c(0,1))
    second<-etr_plot_fpca_wild_bootstrap_truncation_scan(z$selected,
      target=1L,metric="center",strict_source_record=TRUE)
    expect_identical(second$axes[[1L]]$title,
      "Wild-bootstrap truncation scan: second")
    expect_equal(second$axes[[1L]]$artists[[1L]]$ydata,c(.5,.6,.7))
    expect_length(second$axes[[1L]]$artists,1L)
    expect_false(second$axes[[1L]]$legend)
    by_id<-etr_plot_fpca_wild_bootstrap_truncation_scan(z$selected,
      target="second",metric="center",strict_source_record=TRUE)
    expect_equal(by_id$axes[[1L]]$artists[[1L]]$ydata,c(.5,.6,.7))
    native_second<-etr_plot_fpca_wild_bootstrap_truncation_scan(z$scan,
      target=2L)
    expect_identical(native_second$target_curve_id,"second")
    expect_error(etr_plot_fpca_wild_bootstrap_truncation_scan(z$scan,
      target=2L,strict_source_record=TRUE),"target")
  })
})

test_that("invalid strict flags, source target indices and numeric data fail closed",{
  z<-.etr_three_predictive_plot_fixture()
  .etr_three_predictive_pdf({
    expect_error(etr_plot_fpca_regression_cv(z$cv,
      strict_source_record=1L),"strict_source_record")
    expect_error(etr_plot_nested_fpca_regression_cv(z$nested,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_fpca_wild_bootstrap_truncation_scan(z$scan,
      strict_source_record="yes"),"strict_source_record")
    expect_error(etr_plot_fpca_wild_bootstrap_truncation_scan(z$scan,
      target=-1L,strict_source_record=TRUE),"target")
    expect_error(etr_plot_fpca_wild_bootstrap_truncation_scan(z$scan,
      target=2L,strict_source_record=TRUE),"target")
    expect_error(etr_plot_fpca_wild_bootstrap_truncation_scan(z$scan,
      target="missing",strict_source_record=TRUE),"target")
    bad<-z$cv;bad$fold_losses$loss[1L]<-Inf
    expect_error(etr_plot_fpca_regression_cv(bad,
      strict_source_record=TRUE),"finite")
    bad<-z$nested;bad$outer_folds$loss[1L]<-NA_real_
    expect_error(etr_plot_nested_fpca_regression_cv(bad,
      strict_source_record=TRUE),"finite")
    bad<-z$scan;bad$widths[1L,1L]<-Inf
    expect_error(etr_plot_fpca_wild_bootstrap_truncation_scan(bad,
      strict_source_record=TRUE),"finite")
  })
})

test_that("pinned Python 1.2 Matplotlib CV and wild source plots match artist geometry",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 plotting artist direct comparison opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_three_predictive_plot_fixture()
  .etr_three_predictive_pdf({
    a<-etr_plot_fpca_regression_cv(z$cv,strict_source_record=TRUE)
    b<-etr_plot_nested_fpca_regression_cv(z$nested,strict_source_record=TRUE)
    c<-etr_plot_fpca_wild_bootstrap_truncation_scan(z$selected,
      strict_source_record=TRUE)
    d<-etr_plot_fpca_wild_bootstrap_truncation_scan(z$selected,
      target=1L,metric="center",strict_source_record=TRUE)
    reticulate::py_run_string("
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et
def _plot_obj(cls, **fields):
    o=object.__new__(cls)
    for k,v in fields.items(): object.__setattr__(o,k,v)
    return o
cv=_plot_obj(et.FPCARegressionCVResult,
    fold_losses=pd.DataFrame({
      'n_components':[2,1,1,2,3],
      'loss':[4.,2.,4.,6.,5.]}),
    loss='mse',family='gaussian')
nested=_plot_obj(et.FPCANestedRegressionCVResult,
    outer_folds=pd.DataFrame({
      'outer_fold':[0,1,2],
      'loss':[.9,.6,.8]}),loss='mse')
scan=_plot_obj(et.FPCAWildBootstrapTruncationScanResult,
    candidate_components=(1,2,3),
    target_curve_ids=('first','second'),
    widths=np.array([[4.,5.],[3.,6.],[2.,7.]]),
    centers=np.array([[.2,.5],[.3,.6],[.4,.7]]))
selection=_plot_obj(et.FPCAWildBootstrapTruncationSelectionResult,
    scan=scan,selected_components=np.array([2.,np.nan]))
axes=[
 et.plot_fpca_regression_cv(cv),
 et.plot_nested_fpca_regression_cv(nested),
 et.plot_fpca_wild_bootstrap_truncation_scan(selection,target=0),
 et.plot_fpca_wild_bootstrap_truncation_scan(selection,target=1,metric='center')]
def _get_line(ax):
    line=ax.lines[0]
    return {
      'title':ax.get_title(),'xlabel':ax.get_xlabel(),
      'ylabel':ax.get_ylabel(),
      'x':np.asarray(line.get_xdata(),dtype=float),
      'y':np.asarray(line.get_ydata(),dtype=float),
      'marker':line.get_marker(),
      'linestyle':line.get_linestyle(),
      'line_count':len(ax.lines),
      'legend':None if ax.get_legend() is None else [
        t.get_text() for t in ax.get_legend().get_texts()]}
oracle=[_get_line(ax) for ax in axes]
eb=axes[0].containers[0].lines
segments=np.asarray(eb[2][0].get_segments(),dtype=float)
oracle[0]['lower']=segments[:,0,1]
oracle[0]['upper']=segments[:,1,1]
oracle[0]['capsize']=eb[1][0].get_markersize()/2.
oracle[2]['selected_x']=np.asarray(axes[2].lines[1].get_xdata(),dtype=float)
oracle[2]['selected_y']=np.asarray(axes[2].lines[1].get_ydata(),dtype=float)
plt.close('all')
")
    py<-et_to_r(reticulate::py_get_attr(reticulate::py,"oracle"))
    for(i in seq_along(py)){
      r<-list(a,b,c,d)[[i]]$axes[[1L]]
      source<-py[[i]]
      for(k in c("title","xlabel","ylabel"))
        expect_identical(r[[k]],source[[k]],info=paste("label",i,k))
      expect_equal(r$artists[[1L]]$xdata,
        as.numeric(source$x),tolerance=0,info=paste("x",i))
      expect_equal(r$artists[[1L]]$ydata,
        as.numeric(source$y),tolerance=1e-12,info=paste("y",i))
      expect_identical(r$artists[[1L]]$marker,source$marker)
      expect_identical(r$artists[[1L]]$linestyle,source$linestyle)
      if(i!=1L)expect_identical(length(r$artists),
        as.integer(source$line_count))
      expect_identical(r$legend_labels,
        if(is.null(source$legend))character(0) else
          as.character(source$legend))
    }
    expect_equal(a$axes[[1L]]$artists[[1L]]$lower,
      as.numeric(py[[1L]]$lower),tolerance=1e-12)
    expect_equal(a$axes[[1L]]$artists[[1L]]$upper,
      as.numeric(py[[1L]]$upper),tolerance=1e-12)
    expect_equal(a$axes[[1L]]$artists[[1L]]$capsize,
      as.numeric(py[[1L]]$capsize),tolerance=1e-12)
    expect_equal(c$axes[[1L]]$artists[[2L]]$xdata,
      as.numeric(py[[3L]]$selected_x),tolerance=0)
    expect_equal(c$axes[[1L]]$artists[[2L]]$ydata,
      as.numeric(py[[3L]]$selected_y),tolerance=0)
  })
})
