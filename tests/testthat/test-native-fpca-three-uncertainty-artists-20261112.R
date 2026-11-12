# Native FPCA bootstrap uncertainty source-scientific Matplotlib artist audit.
# Frozen eyetrajectoriespy==1.2.0 commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
# No live Python Axes identity or independent certification is claimed.

.etr_uncertainty_three_fixture<-function() {
  sims<-matrix(c(.9,.8,.75,.85,.95,.8),nrow=3L,ncol=2L)
  score<-structure(list(similarities=sims,n_components=2L,
    target_curve_ids=c("a","b"),
    reference_scores=matrix(c(.25,.45,-.1,.1),2L,2L),
    median=matrix(c(.2,.4,-.12,.13),2L,2L),
    lower=matrix(c(.15,.35,-.2,.1),2L,2L),
    upper=matrix(c(.3,.5,-.05,.2),2L,2L),
    resampling_unit="curve",target_source="external",level=.9),
    class="etr_fpca_score_uncertainty")
  ref<-list(n_components=2L,explained_variance=c(3,1.5),
    explained_variance_ratio=c(.6,.3),
    time=c(0,.5,1),time_unit="s",dimension_names="x",
    components=array(c(.1,.2,.3,-.3,.2,.1),c(2L,3L,1L)))
  spec<-structure(list(similarities=sims,n_components=2L,
    reference=ref,confidence_level=.95,simultaneous_scope="family",
    eigenvalue_lower=c(2.5,1.2),eigenvalue_upper=c(3.5,1.7),
    explained_variance_ratio_lower=c(.55,.25),
    explained_variance_ratio_upper=c(.65,.35),
    cumulative_variance_ratio_lower=c(.55,.85),
    cumulative_variance_ratio_upper=c(.65,.95)),
    class="etr_fpca_spectrum_uncertainty")
  band<-structure(list(similarities=sims,n_components=2L,
    reference=ref,confidence_level=.95,simultaneous_scope="family",
    lower=ref$components-.05,upper=ref$components+.05),
    class="etr_fpca_component_band")
  list(score=score,spec=spec,band=band)
}

.etr_uncertainty_three_pdf<-function(expr) {
  file<-tempfile(fileext=".pdf")
  grDevices::pdf(file,width=9,height=6)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(file)
  },add=TRUE)
  force(expr)
}

test_that("three strict FPCA uncertainty plots preserve exact score intervals, spectrum and component confidence geometry",{
  z<-.etr_uncertainty_three_fixture()
  .etr_uncertainty_three_pdf({
    a<-etr_plot_fpca_score_uncertainty(z$score,
      component=1L,max_targets=2L,strict_source_record=TRUE)
    expect_s3_class(a,"etr_fpca_uncertainty_artist_source_record")
    expect_identical(a$source_export,"plot_fpca_score_uncertainty")
    expect_identical(a$python_return_kind,"matplotlib.axes.Axes")
    expect_false(a$matplotlib_object_identity)
    expect_false(a$independently_certified)
    expect_identical(a$axes[[1L]]$ylabel,"FPC2 score")
    expect_identical(a$axes[[1L]]$xticklabels,c("a","b"))
    expect_identical(a$axes[[1L]]$xtick_rotation,90)
    median<-z$score$median[,2L]
    lo<-z$score$lower[,2L];up<-z$score$upper[,2L]
    error<-a$axes[[1L]]$artists[[1L]]
    expect_identical(error$kind,"errorbar")
    expect_identical(error$marker,"o")
    expect_identical(error$linestyle,"none")
    expect_identical(error$capsize,3)
    expect_equal(error$xdata,c(0,1))
    expect_equal(error$ydata,median)
    expect_equal(error$yerr,rbind(median-lo,up-median))
    expect_equal(error$lower,lo)
    expect_equal(error$upper,up)
    scatter<-a$axes[[1L]]$artists[[2L]]
    expect_identical(scatter$marker,"x")
    expect_equal(scatter$offsets,
      unname(cbind(0:1,z$score$reference_scores[,2L])),
      tolerance=0,ignore_attr=TRUE)
    expect_identical(a$axes[[1L]]$artists[[3L]]$kind,
      "horizontal_reference")
    one<-etr_plot_fpca_score_uncertainty(z$score,
      component=0L,max_targets=1L,strict_source_record=TRUE)
    expect_identical(one$source_options$n_plotted,1L)
    expect_length(one$axes[[1L]]$artists[[1L]]$ydata,1L)
    for(metric in c("eigenvalue","explained_variance_ratio",
      "cumulative_variance_ratio")){
      b<-etr_plot_fpca_spectrum_uncertainty(z$spec,metric,
        strict_source_record=TRUE)
      expect_identical(b$source_export,
        "plot_fpca_spectrum_uncertainty")
      expect_identical(b$axes[[1L]]$title,
        "FPCA spectrum uncertainty (familywise)")
      expect_equal(b$axes[[1L]]$xticks,1:2)
      v<-b$axes[[1L]]$artists[[1L]]
      expect_identical(v$capsize,3)
      expect_equal(v$yerr,rbind(v$ydata-v$lower,v$upper-v$ydata),
        tolerance=0)
      ylabel<-switch(metric,eigenvalue="Eigenvalue",
        explained_variance_ratio="Explained variance ratio",
        cumulative_variance_ratio="Cumulative explained variance ratio")
      expect_identical(b$axes[[1L]]$ylabel,ylabel)
      expect_identical(b$source_options$metric,metric)
    }
    tmp<-z$spec;tmp$simultaneous_scope<-"component"
    b<-etr_plot_fpca_spectrum_uncertainty(tmp,
      strict_source_record=TRUE)
    expect_identical(b$axes[[1L]]$title,
      "FPCA spectrum uncertainty (component-wise)")
    c<-etr_plot_fpca_component_band(z$band,
      component=0L,dimension="x",strict_source_record=TRUE)
    expect_identical(c$source_export,"plot_fpca_component_band")
    expect_identical(c$axes[[1L]]$title,
      "FPC1 simultaneous band (familywise)")
    expect_identical(c$axes[[1L]]$xlabel,"Time (s)")
    expect_identical(c$axes[[1L]]$ylabel,"FPC loading: x")
    expect_identical(c$axes[[1L]]$legend_labels,
      c("95.0% simultaneous band","reference FPC"))
    fill<-c$axes[[1L]]$artists[[1L]]
    expect_identical(fill$kind,"fill_between")
    expect_identical(fill$alpha,.2)
    expect_equal(fill$xdata,z$band$reference$time)
    expect_equal(fill$lower,as.numeric(z$band$lower[1L,,1L]))
    expect_equal(fill$upper,as.numeric(z$band$upper[1L,,1L]))
    expect_equal(c$axes[[1L]]$artists[[2L]]$ydata,
      as.numeric(z$band$reference$components[1L,,1L]))
    expect_identical(c$source_options$component,0L)
    expect_identical(c$source_options$confidence_level,.95)
    # Existing native R public returns must remain unchanged by opt-in mode.
    expect_equal(etr_plot_fpca_score_uncertainty(z$score)$median,
      z$score$median[,1L])
    expect_equal(etr_plot_fpca_spectrum_uncertainty(z$spec)$estimate,
      z$spec$reference$explained_variance_ratio)
    expect_equal(etr_plot_fpca_component_band(z$band)$estimate,
      as.numeric(z$band$reference$components[1L,,1L]))
  })
})

test_that("strict FPCA uncertainty plots reject non-source and invalid scientific bounds",{
  z<-.etr_uncertainty_three_fixture()
  .etr_uncertainty_three_pdf({
    expect_error(etr_plot_fpca_score_uncertainty(z$score,
      strict_source_record=1L),"strict_source_record")
    expect_error(etr_plot_fpca_spectrum_uncertainty(z$spec,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_fpca_component_band(z$band,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_fpca_score_uncertainty(unclass(z$score),
      strict_source_record=TRUE),"etr_fpca_score_uncertainty")
    expect_error(etr_plot_fpca_spectrum_uncertainty(unclass(z$spec),
      strict_source_record=TRUE),"metric")
    expect_error(etr_plot_fpca_component_band(unclass(z$band),
      strict_source_record=TRUE),"etr_fpca_component_band")
    expect_error(etr_plot_fpca_score_uncertainty(z$score,
      component=2L,strict_source_record=TRUE),"zero-based")
    expect_error(etr_plot_fpca_score_uncertainty(z$score,
      max_targets=0L,strict_source_record=TRUE),"max_targets")
    expect_error(etr_plot_fpca_spectrum_uncertainty(z$spec,
      metric="unknown",strict_source_record=TRUE),"metric")
    expect_error(etr_plot_fpca_component_band(z$band,
      dimension="unknown",strict_source_record=TRUE),"dimension")
    bad<-z$score;bad$lower[1L,1L]<-bad$median[1L,1L]+1
    expect_error(etr_plot_fpca_score_uncertainty(bad,
      strict_source_record=TRUE),"interval")
    bad<-z$spec;bad$simultaneous_scope<-"invalid"
    expect_error(etr_plot_fpca_spectrum_uncertainty(bad,
      strict_source_record=TRUE),"simultaneous_scope")
    bad<-z$band;bad$confidence_level<-1
    expect_error(etr_plot_fpca_component_band(bad,
      strict_source_record=TRUE),"confidence")
  })
})

test_that("genuine native FPCA bootstrap model output drives all three scientific artist records",{
  t<-seq(0,1,length.out=11L)
  y<-array(0,c(12L,11L,2L))
  for(i in 1:12){
    y[i,,1L]<-sin(2*pi*t)*(1+i/11)+.05*i*t+.04*cos(3*pi*t+i/7)
    y[i,,2L]<-cos(2*pi*t+i/8)+t^2*(i/7)+.04*sin(5*pi*t+i/5)
  }
  x<-etr_trajectory_set(t,y,sprintf("c%02d",1:12),
    c("x","y"),coordinate_system="normalized",time_unit="s")
  scores<-etr_bootstrap_fpca_score_uncertainty(x,
    n_bootstrap=20L,n_components=2L,random_state=11L)
  spec<-etr_bootstrap_fpca_spectrum_uncertainty(x,
    n_bootstrap=20L,n_components=2L,
    simultaneous_scope="family",random_state=9L)
  band<-etr_bootstrap_fpca_component_bands(x,
    n_bootstrap=20L,n_components=2L,
    simultaneous_scope="family",random_state=7L)
  expect_s3_class(scores,"etr_fpca_score_uncertainty")
  expect_s3_class(spec,"etr_fpca_spectrum_uncertainty")
  expect_s3_class(band,"etr_fpca_component_band")
  .etr_uncertainty_three_pdf({
    a<-etr_plot_fpca_score_uncertainty(scores,
      component=0L,max_targets=3L,strict_source_record=TRUE)
    expect_equal(a$axes[[1L]]$artists[[1L]]$ydata,
      scores$median[1:3,1L],tolerance=1e-12)
    b<-etr_plot_fpca_spectrum_uncertainty(spec,
      metric="eigenvalue",strict_source_record=TRUE)
    expect_equal(b$axes[[1L]]$artists[[1L]]$ydata,
      spec$reference$explained_variance[1:2],tolerance=1e-12)
    c<-etr_plot_fpca_component_band(band,component=1L,
      dimension="y",strict_source_record=TRUE)
    expect_equal(c$axes[[1L]]$artists[[2L]]$ydata,
      as.numeric(band$reference$components[2L,,2L]),
      tolerance=1e-12)
  })
})

test_that("published Python 1.2 Matplotlib errorbars and component fill match native source artist data",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 Matplotlib FPCA uncertainty oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_uncertainty_three_fixture()
  .etr_uncertainty_three_pdf({
    ra<-etr_plot_fpca_score_uncertainty(z$score,
      component=0L,strict_source_record=TRUE)
    rb<-etr_plot_fpca_spectrum_uncertainty(z$spec,
      metric="cumulative_variance_ratio",strict_source_record=TRUE)
    rc<-etr_plot_fpca_component_band(z$band,
      component=1L,dimension="x",strict_source_record=TRUE)
    reticulate::py_run_string("
import numpy as np
from types import SimpleNamespace
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et
def _etr_fpca_uncertainty_artists(scores,reference_scores,median,
                                 lower,upper,ids,ev,evr,
                                 cum_lower,cum_upper,
                                 components,time,band_lower,
                                 band_upper,confidence):
    score=SimpleNamespace(n_components=int(median.shape[1]),
      n_targets=int(median.shape[0]),
      target_curve_ids=tuple(ids),
      reference_scores=np.asarray(reference_scores),
      median=np.asarray(median),
      lower=np.asarray(lower),upper=np.asarray(upper))
    ref=SimpleNamespace(
      explained_variance=np.asarray(ev,dtype=float),
      explained_variance_ratio=np.asarray(evr,dtype=float),
      components=np.asarray(components,dtype=float),
      time=np.asarray(time,dtype=float),
      time_unit='s',
      dimension_names=('x',))
    spectrum=SimpleNamespace(
      reference=ref,n_components=len(ev),
      simultaneous_scope='family',
      cumulative_variance_ratio_lower=np.asarray(cum_lower,dtype=float),
      cumulative_variance_ratio_upper=np.asarray(cum_upper,dtype=float))
    band=SimpleNamespace(
      reference=ref,n_components=len(ev),
      simultaneous_scope='family',
      confidence_level=float(confidence),
      lower=np.asarray(band_lower,dtype=float),
      upper=np.asarray(band_upper,dtype=float))
    a=et.plot_fpca_score_uncertainty(score,component=0)
    b=et.plot_fpca_spectrum_uncertainty(
      spectrum,metric='cumulative_variance_ratio')
    c=et.plot_fpca_component_band(band,component=1,dimension='x')
    out={
      'score':{
         'title':a.get_title(),'xlabel':a.get_xlabel(),
         'ylabel':a.get_ylabel(),
         'x':np.asarray(a.lines[0].get_xdata(),dtype=float),
         'y':np.asarray(a.lines[0].get_ydata(),dtype=float),
         'scatter':np.asarray(a.collections[0].get_offsets()),
         'xticklabels':[v.get_text() for v in a.get_xticklabels()],
         'legend':[v.get_text() for v in a.get_legend().get_texts()],
         'errorbar_count':len(a.containers)},
      'spectrum':{
         'title':b.get_title(),'xlabel':b.get_xlabel(),
         'ylabel':b.get_ylabel(),
         'x':np.asarray(b.lines[0].get_xdata(),dtype=float),
         'y':np.asarray(b.lines[0].get_ydata(),dtype=float),
         'errorbar_count':len(b.containers)},
      'band':{
         'title':c.get_title(),'xlabel':c.get_xlabel(),
         'ylabel':c.get_ylabel(),
         'x':np.asarray(c.lines[0].get_xdata(),dtype=float),
         'y':np.asarray(c.lines[0].get_ydata(),dtype=float),
         'alpha':c.collections[0].get_alpha(),
         'fill_label':c.collections[0].get_label(),
         'fill_vertices':np.asarray(c.collections[0].get_paths()[0].vertices),
         'legend':[v.get_text() for v in c.get_legend().get_texts()]}
    }
    plt.close('all')
    return out
")
    py<-reticulate::py_call(
      reticulate::py_eval("_etr_fpca_uncertainty_artists",convert=FALSE),
      scores=z$score$similarities,
      reference_scores=z$score$reference_scores,
      median=z$score$median,lower=z$score$lower,
      upper=z$score$upper,ids=as.list(z$score$target_curve_ids),
      ev=z$spec$reference$explained_variance,
      evr=z$spec$reference$explained_variance_ratio,
      cum_lower=z$spec$cumulative_variance_ratio_lower,
      cum_upper=z$spec$cumulative_variance_ratio_upper,
      components=z$band$reference$components,
      time=z$band$reference$time,
      band_lower=z$band$lower,band_upper=z$band$upper,
      confidence=z$band$confidence_level)
    get<-function(key)et_to_r(reticulate::py_get_item(py,key))
    score<-get("score")
    for(k in c("title","xlabel","ylabel"))
      expect_identical(ra$axes[[1L]][[k]],score[[k]])
    expect_equal(ra$axes[[1L]]$artists[[1L]]$xdata,
      score$x,ignore_attr=TRUE,tolerance=0)
    expect_equal(ra$axes[[1L]]$artists[[1L]]$ydata,
      score$y,ignore_attr=TRUE,tolerance=0)
    expect_equal(ra$axes[[1L]]$artists[[2L]]$offsets,
      score$scatter,ignore_attr=TRUE,tolerance=0)
    expect_identical(ra$axes[[1L]]$xticklabels,
      as.character(score$xticklabels))
    expect_identical(ra$axes[[1L]]$legend_labels,
      as.character(score$legend))
    expect_identical(as.integer(score$errorbar_count),1L)
    spectrum<-get("spectrum")
    for(k in c("title","xlabel","ylabel"))
      expect_identical(rb$axes[[1L]][[k]],spectrum[[k]])
    expect_equal(rb$axes[[1L]]$artists[[1L]]$xdata,
      spectrum$x,ignore_attr=TRUE,tolerance=0)
    expect_equal(rb$axes[[1L]]$artists[[1L]]$ydata,
      spectrum$y,ignore_attr=TRUE,tolerance=1e-12)
    expect_identical(as.integer(spectrum$errorbar_count),1L)
    band<-get("band")
    for(k in c("title","xlabel","ylabel"))
      expect_identical(rc$axes[[1L]][[k]],band[[k]])
    expect_equal(rc$axes[[1L]]$artists[[2L]]$xdata,
      band$x,ignore_attr=TRUE,tolerance=0)
    expect_equal(rc$axes[[1L]]$artists[[2L]]$ydata,
      band$y,ignore_attr=TRUE,tolerance=0)
    expect_equal(rc$axes[[1L]]$artists[[1L]]$alpha,
      band$alpha,tolerance=0)
    expect_identical(rc$axes[[1L]]$artists[[1L]]$label,
      band$fill_label)
    expect_identical(rc$axes[[1L]]$legend_labels,
      as.character(band$legend))
    vertices<-as.matrix(band$fill_vertices)
    for(value in c(rc$axes[[1L]]$artists[[1L]]$lower,
      rc$axes[[1L]]$artists[[1L]]$upper))
      expect_true(any(abs(vertices[,2L]-value)<1e-10))
  })
})
