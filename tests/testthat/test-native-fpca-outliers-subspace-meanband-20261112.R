# Frozen published Python 1.2 FPCA plotting geometry, pin
# c1cd95ad718327550f7e55393ff38582872f7a94.
# These explicit source-scientific records are not Python Axes objects.
.etr_three_fpca_inference_fixture<-function(){
  out<-structure(list(
    diagnostics=data.frame(
      reconstruction_robust_z=c(.3,3.1,.8,1.6),
      score_mahalanobis_sq=c(2,10,4,5),
      score_cutoff=c(7,7,7,7),
      review_flag=c(FALSE,TRUE,FALSE,FALSE)),
    provenance=list(reconstruction_z_threshold=2.5)),
    class="etr_fpca_outliers")
  sub<-structure(list(
    component_indices=c(0L,1L),
    principal_cosines=matrix(c(.92,.83,.88,.81,.95,.75),3L,2L),
    principal_angles_degrees=matrix(c(20,30,24,35,18,41),3L,2L),
    normalized_projector_distance=c(.21,.15,.29)),
    class="etr_fpca_subspace_stability")
  band<-structure(list(
    time=c(0,.25,.5,.75,1),
    mean=cbind(x=c(1,1.2,1.5,1.4,1.1),y=c(2,2.2,2.3,2.1,2)),
    lower=cbind(x=c(.6,.7,1,.9,.7),y=c(1.7,1.8,1.9,1.7,1.6)),
    upper=cbind(x=c(1.4,1.7,2,1.9,1.5),y=c(2.3,2.6,2.7,2.5,2.4)),
    dimension_names=c("x","y"),time_unit="s",
    confidence_level=.95),class="etr_functional_mean_band")
  list(out=out,sub=sub,band=band)
}
.etr_three_fpca_inference_pdf<-function(expr){
  p<-tempfile(fileext=".pdf")
  grDevices::pdf(p,width=9,height=6)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(p)
  },add=TRUE)
  force(expr)
}

test_that("three source-scientific FPCA artists preserve original diagnostics and simultaneous confidence geometry",{
  x<-.etr_three_fpca_inference_fixture()
  .etr_three_fpca_inference_pdf({
    o<-etr_plot_fpca_outlier_diagnostics(x$out,
      strict_source_record=TRUE)
    expect_s3_class(o,"etr_fpca_source_artist_record")
    expect_identical(o$source_export,"plot_fpca_outlier_diagnostics")
    expect_identical(o$python_return_kind,"matplotlib.axes.Axes")
    expect_false(o$matplotlib_object_identity)
    expect_false(o$independently_certified)
    a<-o$axes[[1L]]
    expect_identical(a$title,"FPCA trajectory review diagnostics")
    expect_identical(a$artists[[1L]]$kind,"scatter")
    expect_identical(a$artists[[1L]]$marker,"o")
    expect_equal(a$artists[[1L]]$offsets,
      unname(cbind(x$out$diagnostics$reconstruction_robust_z,
        x$out$diagnostics$score_mahalanobis_sq)),tolerance=0)
    expect_length(a$lines,2L)
    expect_equal(a$lines[[1L]]$xdata,c(2.5,2.5))
    expect_equal(a$lines[[2L]]$ydata,c(7,7))
    expect_identical(o$source_options$n_review_flag,1L)
    no_threshold<-x$out
    no_threshold$provenance$reconstruction_z_threshold<-NULL
    o2<-etr_plot_fpca_outlier_diagnostics(no_threshold,
      strict_source_record=TRUE)
    expect_length(o2$axes[[1L]]$lines,1L)
    expect_identical(o2$axes[[1L]]$lines[[1L]]$kind,
      "horizontal_reference")
    for(metric in c("normalized_projector_distance",
      "max_principal_angle_degrees","min_principal_cosine")){
      sp<-etr_plot_fpca_subspace_stability(x$sub,
        metric=metric,strict_source_record=TRUE)
      expect_identical(sp$source_export,"plot_fpca_subspace_stability")
      expect_identical(sp$source_options$metric,metric)
      line<-sp$axes[[1L]]$artists[[1L]]
      expect_identical(line$linestyle,"none")
      expect_identical(line$marker,"o")
      expect_equal(line$xdata,c(1,2,3),tolerance=0)
      expected<-switch(metric,
        normalized_projector_distance=x$sub$normalized_projector_distance,
        max_principal_angle_degrees=apply(
          x$sub$principal_angles_degrees,1L,max),
        min_principal_cosine=apply(x$sub$principal_cosines,1L,min))
      expect_equal(line$ydata,expected,tolerance=1e-12)
      expect_identical(sp$axes[[1L]]$title,
        "FPCA subspace stability: FPC1–FPC2")
    }
    m<-etr_plot_functional_mean_band(x$band,
      dimension="y",strict_source_record=TRUE)
    expect_identical(m$source_export,"plot_functional_mean_band")
    expect_identical(m$axes[[1L]]$ylabel,"y")
    expect_identical(m$axes[[1L]]$title,"Functional mean band: y(t)")
    expect_true(m$axes[[1L]]$legend)
    expect_identical(m$axes[[1L]]$legend_labels,
      c("95.0% simultaneous band","functional mean"))
    fill<-m$axes[[1L]]$artists[[1L]]
    mean<-m$axes[[1L]]$artists[[2L]]
    expect_identical(fill$kind,"fill_between")
    expect_identical(fill$alpha,0.2)
    expect_equal(fill$xdata,x$band$time,tolerance=0)
    expect_equal(fill$lower,x$band$lower[,"y"],tolerance=0)
    expect_equal(fill$upper,x$band$upper[,"y"],tolerance=0)
    expect_equal(mean$ydata,x$band$mean[,"y"],tolerance=0)
    default<-etr_plot_functional_mean_band(x$band,dimension="y")
    expect_equal(default$mean,x$band$mean[,"y"])
    expect_identical(names(default),c("time","mean","lower","upper"))
  })
})

test_that("strict FPCA scientific geometry rejects invalid classes, channel and metrics",{
  x<-.etr_three_fpca_inference_fixture()
  .etr_three_fpca_inference_pdf({
    expect_error(etr_plot_fpca_outlier_diagnostics(
      unclass(x$out),strict_source_record=TRUE),"genuine native")
    expect_error(etr_plot_fpca_subspace_stability(
      unclass(x$sub),strict_source_record=TRUE),"genuine native")
    expect_error(etr_plot_functional_mean_band(
      unclass(x$band),strict_source_record=TRUE),"genuine native")
    expect_error(etr_plot_fpca_outlier_diagnostics(x$out,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_fpca_subspace_stability(x$sub,
      strict_source_record=1L),"strict_source_record")
    expect_error(etr_plot_functional_mean_band(x$band,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_fpca_subspace_stability(x$sub,
      metric="unknown",strict_source_record=TRUE),"metric")
    expect_error(etr_plot_functional_mean_band(x$band,
      dimension="absent",strict_source_record=TRUE),"dimension")
    o<-x$out
    o$diagnostics$review_flag[1]<-NA
    expect_error(etr_plot_fpca_outlier_diagnostics(o,
      strict_source_record=TRUE),"review flags")
    m<-x$band
    m$lower[1L,1L]<-m$upper[1L,1L]+1
    expect_error(etr_plot_functional_mean_band(m,
      strict_source_record=TRUE),"valid finite")
  })
})

test_that("frozen Python 1.2 actual Matplotlib scatter, no-line markers, fill-between scientific artist data match native R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 plotting differential opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_three_fpca_inference_fixture()
  .etr_three_fpca_inference_pdf({
    ro<-etr_plot_fpca_outlier_diagnostics(x$out,
      strict_source_record=TRUE)
    rs<-etr_plot_fpca_subspace_stability(x$sub,
      metric="max_principal_angle_degrees",strict_source_record=TRUE)
    rm<-etr_plot_functional_mean_band(x$band,
      dimension="y",strict_source_record=TRUE)
    reticulate::py_run_string("
import numpy as np
import pandas as pd
from types import SimpleNamespace
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et
def _etr_fpca_plot_source_oracle(
    outliers,threshold,angles,cosines,projector,components,
    times,mean,lower,upper,dimension_names,level):
    out=SimpleNamespace(
      diagnostics=pd.DataFrame(outliers),
      provenance={'reconstruction_z_threshold':threshold})
    sub=SimpleNamespace(
      normalized_projector_distance=np.asarray(projector),
      principal_angles_degrees=np.asarray(angles),
      principal_cosines=np.asarray(cosines),
      component_indices=np.asarray(components,dtype=int),
      n_bootstrap=len(projector))
    band=SimpleNamespace(
      time=np.asarray(times,dtype=float),
      mean=np.asarray(mean,dtype=float),
      lower=np.asarray(lower,dtype=float),
      upper=np.asarray(upper,dtype=float),
      dimension_names=tuple(dimension_names),
      time_unit='s',
      confidence_level=float(level))
    o=et.plot_fpca_outlier_diagnostics(out)
    s=et.plot_fpca_subspace_stability(
      sub,metric='max_principal_angle_degrees')
    b=et.plot_functional_mean_band(band,dimension='y')
    expected={
      'outlier':{
        'title':o.get_title(),'xlabel':o.get_xlabel(),
        'ylabel':o.get_ylabel(),
        'offsets':np.asarray(o.collections[0].get_offsets()),
        'reference_lines':[
          {'x':np.asarray(line.get_xdata()),
           'y':np.asarray(line.get_ydata())}
          for line in o.lines]},
      'subspace':{
        'title':s.get_title(),'xlabel':s.get_xlabel(),
        'ylabel':s.get_ylabel(),
        'x':np.asarray(s.lines[0].get_xdata()),
        'y':np.asarray(s.lines[0].get_ydata()),
        'marker':s.lines[0].get_marker(),
        'linestyle':s.lines[0].get_linestyle()},
      'mean':{
        'title':b.get_title(),'xlabel':b.get_xlabel(),
        'ylabel':b.get_ylabel(),
        'line_x':np.asarray(b.lines[0].get_xdata()),
        'line_y':np.asarray(b.lines[0].get_ydata()),
        'fill_label':b.collections[0].get_label(),
        'fill_alpha':b.collections[0].get_alpha(),
        'fill_vertices':np.asarray(b.collections[0].get_paths()[0].vertices),
        'legend_labels':[z.get_text() for z in b.get_legend().get_texts()]
      }
    }
    plt.close('all')
    return expected
")
    result<-reticulate::py_call(
      reticulate::py_eval("_etr_fpca_plot_source_oracle",convert=FALSE),
      outliers=x$out$diagnostics,threshold=2.5,
      angles=x$sub$principal_angles_degrees,
      cosines=x$sub$principal_cosines,
      projector=x$sub$normalized_projector_distance,
      components=x$sub$component_indices,
      times=x$band$time,mean=x$band$mean,
      lower=x$band$lower,upper=x$band$upper,
      dimension_names=as.list(x$band$dimension_names),
      level=x$band$confidence_level)
    get<-function(name)et_to_r(reticulate::py_get_item(result,name))
    po<-get("outlier")
    for(name in c("title","xlabel","ylabel"))
      expect_identical(ro$axes[[1L]][[name]],po[[name]])
    expect_equal(ro$axes[[1L]]$artists[[1L]]$offsets,
      po$offsets,tolerance=0,ignore_attr=TRUE)
    expect_length(po$reference_lines,2L)
    expect_equal(ro$axes[[1L]]$lines[[1L]]$xdata,
      po$reference_lines[[1L]]$x,tolerance=0,ignore_attr=TRUE)
    expect_equal(ro$axes[[1L]]$lines[[2L]]$ydata,
      po$reference_lines[[2L]]$y,tolerance=0,ignore_attr=TRUE)
    ps<-get("subspace")
    for(name in c("title","xlabel","ylabel"))
      expect_identical(rs$axes[[1L]][[name]],ps[[name]])
    expect_equal(rs$axes[[1L]]$artists[[1L]]$xdata,
      ps$x,tolerance=0,ignore_attr=TRUE)
    expect_equal(rs$axes[[1L]]$artists[[1L]]$ydata,
      ps$y,tolerance=1e-12,ignore_attr=TRUE)
    expect_identical(rs$axes[[1L]]$artists[[1L]]$linestyle,
      ps$linestyle)
    expect_identical(rs$axes[[1L]]$artists[[1L]]$marker,ps$marker)
    pm<-get("mean")
    for(name in c("title","xlabel","ylabel"))
      expect_identical(rm$axes[[1L]][[name]],pm[[name]])
    expect_identical(rm$axes[[1L]]$legend_labels,
      as.character(pm$legend_labels))
    expect_equal(rm$axes[[1L]]$artists[[2L]]$xdata,
      pm$line_x,tolerance=0,ignore_attr=TRUE)
    expect_equal(rm$axes[[1L]]$artists[[2L]]$ydata,
      pm$line_y,tolerance=0,ignore_attr=TRUE)
    expect_equal(rm$axes[[1L]]$artists[[1L]]$alpha,
      pm$fill_alpha,tolerance=0)
    expect_identical(rm$axes[[1L]]$artists[[1L]]$label,pm$fill_label)
    vertices<-pm$fill_vertices
    for(value in c(rm$axes[[1L]]$artists[[1L]]$lower,
       rm$axes[[1L]]$artists[[1L]]$upper))
      expect_true(any(abs(vertices[,2L]-value)<1e-10))
  })
})
