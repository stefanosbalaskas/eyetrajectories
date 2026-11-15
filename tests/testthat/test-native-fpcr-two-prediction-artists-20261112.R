# Exact source-scientific artists from eyetrajectoriespy==1.2.0 plotting.py
# at c1cd95ad718327550f7e55393ff38582872f7a94.
# Native scientific coordinates, NOT live Python Matplotlib objects.

.etr_fpcr_two_artist_fixture<-function(){
  ids<-c("q1","q2","q3")
  uncertainty<-list(target_curve_ids=ids,
    reference_mean_predictions=c(.6,-.5,.2),
    prediction_median=c(.7,-.4,.15),
    prediction_lower=c(.5,-.65,0),
    prediction_upper=c(.9,-.15,.3))
  future<-list(regression_uncertainty=uncertainty,
    median=c(.7,-.4,.15),lower=c(.4,-.7,-.05),
    upper=c(1,-.1,.35))
  list(uncertainty=uncertainty,future=future)
}

.etr_fpcr_two_artist_pdf<-function(expr){
  f<-tempfile(fileext=".pdf")
  grDevices::pdf(f,width=9,height=6)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(f)
  },add=TRUE)
  force(expr)
}

test_that("strict FPCR prediction artists preserve calibrated source asymmetric intervals",{
  z<-.etr_fpcr_two_artist_fixture()
  .etr_fpcr_two_artist_pdf({
    a<-etr_plot_fpca_regression_future_prediction_interval(z$future,
      max_targets=2L,strict_source_record=TRUE)
    b<-etr_plot_fpca_regression_mean_prediction_uncertainty(z$uncertainty,
      max_targets=2L,strict_source_record=TRUE)
    for(r in list(a,b)){
      expect_s3_class(r,"etr_fpca_inference_artist_source_record")
      expect_identical(r$python_return_kind,"matplotlib.axes.Axes")
      expect_false(r$matplotlib_object_identity)
      expect_false(r$independently_certified)
      ax<-r$axes[[1L]]
      expect_identical(ax$xlabel,"Fixed target trajectory")
      expect_identical(ax$xticklabels,c("q1","q2"))
      expect_identical(ax$xtick_rotation,90)
      expect_identical(vapply(ax$artists,function(x)x$kind,character(1L)),
        c("errorbar","scatter"))
      err<-ax$artists[[1L]]
      expect_identical(err$marker,"o")
      expect_identical(err$linestyle,"none")
      expect_identical(err$capsize,3)
      expect_equal(err$xdata,c(0,1))
      expect_equal(err$ydata,c(.7,-.4))
      expect_equal(err$yerr,rbind(err$ydata-err$lower,
        err$upper-err$ydata),tolerance=0)
      ref<-ax$artists[[2L]]
      expect_identical(ref$marker,"x")
      expect_equal(ref$offsets,unname(cbind(c(0,1),c(.6,-.5))))
    }
    expect_identical(a$source_export,
      "plot_fpca_regression_future_prediction_interval")
    expect_identical(a$axes[[1L]]$title,
      "Gaussian FPCR future-outcome prediction")
    expect_identical(a$axes[[1L]]$ylabel,"Scalar response")
    expect_identical(a$axes[[1L]]$legend_labels,
      c("full-sample conditional mean","future-outcome predictive interval"))
    expect_equal(a$axes[[1L]]$artists[[1L]]$lower,c(.4,-.7))
    expect_equal(a$axes[[1L]]$artists[[1L]]$upper,c(1,-.1))
    expect_identical(b$source_export,
      "plot_fpca_regression_mean_prediction_uncertainty")
    expect_identical(b$axes[[1L]]$title,"FPCR conditional-mean uncertainty")
    expect_identical(b$axes[[1L]]$ylabel,"Conditional mean response")
    expect_identical(b$axes[[1L]]$legend_labels,
      c("full-sample conditional mean",
        "bootstrap median + conditional-mean envelope"))
    expect_equal(b$axes[[1L]]$artists[[1L]]$lower,c(.5,-.65))
    expect_equal(b$axes[[1L]]$artists[[1L]]$upper,c(.9,-.15))
    one<-etr_plot_fpca_regression_future_prediction_interval(z$future,
      max_targets=1L,strict_source_record=TRUE)
    expect_length(one$axes[[1L]]$artists[[1L]]$ydata,1L)
    # Original native public returns preserve full numeric geometry.
    olda<-etr_plot_fpca_regression_future_prediction_interval(z$future)
    oldb<-etr_plot_fpca_regression_mean_prediction_uncertainty(z$uncertainty)
    expect_identical(olda$provenance$python_axes_return_equivalence,FALSE)
    expect_identical(oldb$provenance$python_axes_return_equivalence,FALSE)
    expect_identical(names(olda$geometry),c(
      "x","curve_id","center","lower","upper","reference"))
    expect_equal(olda$geometry$reference,z$uncertainty$reference_mean_predictions)
    expect_equal(oldb$geometry$upper,z$uncertainty$prediction_upper)
  })
})

test_that("FPCR prediction artist strict input domain fails closed",{
  z<-.etr_fpcr_two_artist_fixture()
  .etr_fpcr_two_artist_pdf({
    expect_error(etr_plot_fpca_regression_future_prediction_interval(
      z$future,strict_source_record=1),"strict_source_record")
    expect_error(etr_plot_fpca_regression_mean_prediction_uncertainty(
      z$uncertainty,strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_fpca_regression_future_prediction_interval(
      z$future,max_targets=0L,strict_source_record=TRUE),"max_targets")
    bad<-z$future;bad$lower[1L]<-.9e99;bad$upper[1L]<-0
    expect_error(etr_plot_fpca_regression_future_prediction_interval(
      bad,strict_source_record=TRUE),"between lower and upper")
    bad<-z$uncertainty;bad$prediction_upper[1L]<-Inf
    expect_error(etr_plot_fpca_regression_mean_prediction_uncertainty(
      bad,strict_source_record=TRUE),"upper")
    bad<-z$uncertainty;bad$reference_mean_predictions[1L]<-NA_real_
    expect_error(etr_plot_fpca_regression_mean_prediction_uncertainty(
      bad,strict_source_record=TRUE),"reference")
  })
})

test_that("frozen Python 1.2 Matplotlib prediction artists match native source geometry",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 plotting artist oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_fpcr_two_artist_fixture()
  .etr_fpcr_two_artist_pdf({
    ra<-etr_plot_fpca_regression_future_prediction_interval(z$future,
      strict_source_record=TRUE)
    rb<-etr_plot_fpca_regression_mean_prediction_uncertainty(z$uncertainty,
      strict_source_record=TRUE)
    reticulate::py_run_string("
import numpy as np
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et

def _fobj(cls,**kw):
  obj=object.__new__(cls)
  for k,v in kw.items(): object.__setattr__(obj,k,v)
  return obj

_py_unc=_fobj(et.FPCARegressionUncertaintyResult,
  target_curve_ids=('q1','q2','q3'),
  reference_mean_predictions=np.array([.6,-.5,.2]),
  prediction_median=np.array([.7,-.4,.15]),
  prediction_lower=np.array([.5,-.65,0.]),
  prediction_upper=np.array([.9,-.15,.3]),
  bootstrap_mean_predictions=np.zeros((4,3)))
_py_future=_fobj(et.FPCARegressionPredictionIntervalResult,
  regression_uncertainty=_py_unc,
  median=np.array([.7,-.4,.15]),
  lower=np.array([.4,-.7,-.05]),
  upper=np.array([1.,-.1,.35]),
  predictive_draws=np.zeros((4,3)))
_pax=et.plot_fpca_regression_future_prediction_interval(_py_future)
_qax=et.plot_fpca_regression_mean_prediction_uncertainty(_py_unc)
def _et_artist(ax):
  line,caps,bars=ax.containers[0].lines
  segments=np.asarray(bars[0].get_segments())
  return {
    'title':ax.get_title(),'xlabel':ax.get_xlabel(),
    'ylabel':ax.get_ylabel(),
    'labels':[t.get_text() for t in ax.get_xticklabels()],
    'legend':[t.get_text() for t in ax.get_legend().get_texts()],
    'x':np.asarray(line.get_xdata(),dtype=float),
    'y':np.asarray(line.get_ydata(),dtype=float),
    'lower':np.asarray(segments[:,0,1],dtype=float),
    'upper':np.asarray(segments[:,1,1],dtype=float),
    'scatter':np.asarray(ax.collections[-1].get_offsets(),dtype=float),
    'marker':line.get_marker(),
    'capsize':caps[0].get_markersize()/2 if caps else 0}
_py_fpcr_two_artists={'future':_et_artist(_pax),'mean':_et_artist(_qax)}
plt.close('all')
")
    p<-et_to_r(reticulate::py_get_attr(reticulate::py,
      "_py_fpcr_two_artists"))
    for(pair in list(list(native=ra,py=p$future),
                   list(native=rb,py=p$mean))){
      ax<-pair$native$axes[[1L]];src<-pair$py
      for(k in c("title","xlabel","ylabel"))
        expect_identical(ax[[k]],src[[k]])
      expect_identical(ax$xticklabels,as.character(src$labels))
      expect_identical(ax$legend_labels,as.character(src$legend))
      artist<-ax$artists[[1L]]
      expect_identical(artist$marker,src$marker)
      expect_equal(artist$capsize,src$capsize,tolerance=1e-12)
      expect_equal(artist$xdata,as.numeric(src$x),tolerance=0)
      expect_equal(artist$ydata,as.numeric(src$y),tolerance=1e-12)
      expect_equal(artist$lower,as.numeric(src$lower),tolerance=1e-12)
      expect_equal(artist$upper,as.numeric(src$upper),tolerance=1e-12)
      expect_equal(ax$artists[[2L]]$offsets,as.matrix(src$scatter),
        tolerance=1e-12,ignore_attr=TRUE)
    }
  })
})
