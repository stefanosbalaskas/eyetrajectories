# Frozen source: eyetrajectoriespy==1.2.0, plotting.py at
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Provisional source-scientific artist data; NOT Matplotlib runtime parity.

.etr_three_inference_fixture<-function() {
  time<-c(0,.5,1)
  components<-array(c(.2,.1,.4,-.2,.6,.3),c(2L,3L,1L))
  ref<-list(time=time,dimension_names="x",time_unit="s",
    components=components)
  envelope<-list(reference=ref,lower=components-.2,
    median=components+.02,upper=components+.25,level=.95)
  projection<-list(target_curve_ids=c("u","v"),
    reference_projection=c(.1,-.2),lower=c(-.04,-.4),
    upper=c(.3,-.01))
  family<-list(projection_result=projection,
    adjusted_p_values=c(.2,.7),targetwise_p_values=c(.1,.35),
    significance_level=.05)
  list(envelope=envelope,projection=projection,family=family)
}

.etr_three_inference_pdf<-function(expr) {
  f<-tempfile(fileext=".pdf")
  grDevices::pdf(f,width=8,height=5)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(f)
  },add=TRUE)
  force(expr)
}

test_that("three FPCA inference source artists preserve frozen scientific coordinates",{
  z<-.etr_three_inference_fixture()
  .etr_three_inference_pdf({
    a<-etr_plot_fpca_component_envelope(z$envelope,component=1L,
      strict_source_record=TRUE)
    expect_s3_class(a,"etr_fpca_inference_artist_source_record")
    expect_identical(a$source_export,"plot_fpca_component_envelope")
    expect_identical(a$python_return_kind,"matplotlib.axes.Axes")
    expect_false(a$matplotlib_object_identity)
    expect_false(a$independently_certified)
    expect_identical(a$axes[[1L]]$title,"FPC2 matched-bootstrap envelope")
    expect_identical(a$axes[[1L]]$xlabel,"Time (s)")
    expect_identical(a$axes[[1L]]$ylabel,"FPC loading: x")
    expect_identical(a$axes[[1L]]$legend_labels,
      c("95% pointwise envelope","bootstrap median","reference FPC"))
    artists<-a$axes[[1L]]$artists
    expect_identical(vapply(artists,function(q)q$kind,character(1L)),
      c("fill_between","line","line"))
    expect_identical(artists[[1L]]$alpha,.2)
    expect_equal(artists[[1L]]$xdata,c(0,.5,1))
    expect_equal(artists[[1L]]$lower,
      as.numeric(z$envelope$lower[2L,,1L]))
    expect_equal(artists[[1L]]$upper,
      as.numeric(z$envelope$upper[2L,,1L]))
    expect_identical(artists[[2L]]$linestyle,"--")
    expect_equal(artists[[2L]]$ydata,
      as.numeric(z$envelope$median[2L,,1L]))
    expect_equal(artists[[3L]]$ydata,
      as.numeric(z$envelope$reference$components[2L,,1L]))
    b<-etr_plot_fpca_wild_bootstrap_projection(z$projection,
      max_targets=2L,strict_source_record=TRUE)
    expect_s3_class(b,"etr_fpca_inference_artist_source_record")
    expect_identical(b$source_export,
      "plot_fpca_wild_bootstrap_projection")
    expect_identical(b$axes[[1L]]$xticklabels,c("u","v"))
    expect_identical(b$axes[[1L]]$xtick_rotation,90)
    er<-b$axes[[1L]]$artists[[1L]]
    expect_identical(er$kind,"errorbar")
    expect_identical(er$marker,"o")
    expect_identical(er$linestyle,"none")
    expect_identical(er$capsize,3)
    expect_equal(er$xdata,c(0,1))
    expect_equal(er$ydata,c(.1,-.2))
    expect_equal(er$yerr,rbind(c(.14,.2),c(.2,.19)),tolerance=1e-12)
    expect_equal(b$axes[[1L]]$artists[[2L]]$ydata,c(0,0))
    c<-etr_plot_fpca_wild_bootstrap_family_test(z$family,
      strict_source_record=TRUE)
    expect_identical(c$source_export,
      "plot_fpca_wild_bootstrap_family_test")
    expect_equal(c$axes[[1L]]$ylim,c(-.02,1.02))
    expect_identical(c$axes[[1L]]$legend_labels,
      c("single-step maxT adjusted","target-wise","alpha=0.05"))
    expect_equal(c$axes[[1L]]$artists[[1L]]$offsets,
      unname(cbind(c(0,1),c(.2,.7))))
    expect_equal(c$axes[[1L]]$artists[[2L]]$offsets,
      unname(cbind(c(0,1),c(.1,.35))))
    expect_equal(c$axes[[1L]]$artists[[3L]]$ydata,c(.05,.05))
    no_target<-etr_plot_fpca_wild_bootstrap_family_test(z$family,
      show_targetwise=FALSE,max_targets=1L,strict_source_record=TRUE)
    expect_length(no_target$axes[[1L]]$artists,2L)
    expect_identical(no_target$axes[[1L]]$legend_labels,
      c("single-step maxT adjusted","alpha=0.05"))
    only_one<-etr_plot_fpca_wild_bootstrap_projection(z$projection,
      max_targets=1L,strict_source_record=TRUE)
    expect_length(only_one$axes[[1L]]$artists[[1L]]$xdata,1L)
    # Default R scientific outputs remain backward-compatible.
    expect_identical(names(etr_plot_fpca_component_envelope(
      z$envelope)),c("time","lower","median","upper","reference"))
    expect_identical(names(etr_plot_fpca_wild_bootstrap_projection(
      z$projection)$geometry),c("x","curve_id","center","lower","upper"))
    expect_identical(names(etr_plot_fpca_wild_bootstrap_family_test(
      z$family)),c("target_index","target_curve_id","adjusted_p_value",
        "targetwise_p_value","significance_level"))
  })
})

test_that("three FPCA inference source records fail closed on bad scientific domains",{
  z<-.etr_three_inference_fixture()
  .etr_three_inference_pdf({
    expect_error(etr_plot_fpca_component_envelope(z$envelope,
      strict_source_record=1L),"strict_source_record")
    expect_error(etr_plot_fpca_wild_bootstrap_projection(z$projection,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_fpca_wild_bootstrap_family_test(z$family,
      strict_source_record="yes"),"strict_source_record")
    expect_error(etr_plot_fpca_component_envelope(z$envelope,
      component=2L,strict_source_record=TRUE),"component")
    expect_error(etr_plot_fpca_component_envelope(z$envelope,
      dimension="missing",strict_source_record=TRUE),"dimension")
    bad<-z$envelope;bad$median[1L,1L,1L]<-Inf
    expect_error(etr_plot_fpca_component_envelope(bad,
      strict_source_record=TRUE),"finite")
    bad<-z$envelope;bad$lower[1L,1L,1L]<-100
    expect_error(etr_plot_fpca_component_envelope(bad,
      strict_source_record=TRUE),"ordered")
    bad<-z$projection;bad$lower[1L]<-Inf
    expect_error(etr_plot_fpca_wild_bootstrap_projection(bad,
      strict_source_record=TRUE),"finite")
    bad<-z$projection;bad$upper[1L]<--10
    expect_error(etr_plot_fpca_wild_bootstrap_projection(bad,
      strict_source_record=TRUE),"interval")
    expect_error(etr_plot_fpca_wild_bootstrap_projection(z$projection,
      max_targets=0L,strict_source_record=TRUE),"max_targets")
    bad<-z$family;bad$adjusted_p_values[1L]<-1.2
    expect_error(etr_plot_fpca_wild_bootstrap_family_test(bad,
      strict_source_record=TRUE),"adjusted_p_values")
    bad<-z$family;bad$significance_level<-0
    expect_error(etr_plot_fpca_wild_bootstrap_family_test(bad,
      strict_source_record=TRUE),"significance_level")
    expect_error(etr_plot_fpca_wild_bootstrap_family_test(z$family,
      show_targetwise=1L,strict_source_record=TRUE),"show_targetwise")
  })
})

test_that("frozen Python 1.2 Matplotlib source scientific artists match native R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 source artist comparison is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_three_inference_fixture()
  .etr_three_inference_pdf({
    a<-etr_plot_fpca_component_envelope(z$envelope,
      component=1L,strict_source_record=TRUE)
    b<-etr_plot_fpca_wild_bootstrap_projection(z$projection,
      strict_source_record=TRUE)
    c<-etr_plot_fpca_wild_bootstrap_family_test(z$family,
      strict_source_record=TRUE)
    reticulate::py_run_string("
import numpy as np
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
from types import SimpleNamespace
import eyetrajectoriespy as et

components=np.array([[[.2],[.4],[.6]],[[.1],[-.2],[.3]]],dtype=float)
reference=SimpleNamespace(
  n_components=2, components=components,
  time=np.array([0.,.5,1.]),time_unit='s',
  dimension_names=('x',))
envelope=SimpleNamespace(reference=reference,
  lower=components-.2,median=components+.02,upper=components+.25,
  level=.95)
projection=SimpleNamespace(
  target_curve_ids=('u','v'),reference_projection=np.array([.1,-.2]),
  lower=np.array([-.04,-.4]),upper=np.array([.3,-.01]),
  bootstrap_projections=np.zeros((4,2)))
family=object.__new__(et.FPCAWildBootstrapFamilyTestResult)
object.__setattr__(family,'projection_result',projection)
object.__setattr__(family,'adjusted_p_values',np.array([.2,.7]))
object.__setattr__(family,'targetwise_p_values',np.array([.1,.35]))
object.__setattr__(family,'significance_level',.05)
ax1=et.plot_fpca_component_envelope(envelope,component=1,dimension='x')
ax2=et.plot_fpca_wild_bootstrap_projection(projection)
ax3=et.plot_fpca_wild_bootstrap_family_test(family)
etr_three_py_out={
 'envelope':{'title':ax1.get_title(),'xlabel':ax1.get_xlabel(),
             'ylabel':ax1.get_ylabel(),
             'legend':[t.get_text() for t in ax1.get_legend().get_texts()],
             'median':list(np.asarray(ax1.lines[0].get_ydata())),
             'reference':list(np.asarray(ax1.lines[1].get_ydata())),
             'alpha':ax1.collections[0].get_alpha()},
 'projection':{'title':ax2.get_title(),'ylabel':ax2.get_ylabel(),
             'x':list(np.asarray(ax2.lines[0].get_xdata())),
             'y':list(np.asarray(ax2.lines[0].get_ydata())),
             'legend':[t.get_text() for t in ax2.get_legend().get_texts()],
             'xticks':list(np.asarray(ax2.get_xticks())),
             'labels':[t.get_text() for t in ax2.get_xticklabels()]},
 'family':{'title':ax3.get_title(),'ylabel':ax3.get_ylabel(),
             'ylim':list(ax3.get_ylim()),
             'adjusted':np.asarray(ax3.collections[0].get_offsets()).tolist(),
             'targetwise':np.asarray(ax3.collections[1].get_offsets()).tolist(),
             'legend':[t.get_text() for t in ax3.get_legend().get_texts()],
             'labels':[t.get_text() for t in ax3.get_xticklabels()]}
}
plt.close('all')
")
    p<-reticulate::py_to_r(reticulate::py$etr_three_py_out)
    expect_identical(a$axes[[1L]]$title,p$envelope$title)
    expect_identical(a$axes[[1L]]$xlabel,p$envelope$xlabel)
    expect_identical(a$axes[[1L]]$ylabel,p$envelope$ylabel)
    expect_identical(a$axes[[1L]]$legend_labels,p$envelope$legend)
    expect_equal(a$axes[[1L]]$artists[[1L]]$alpha,p$envelope$alpha)
    expect_equal(a$axes[[1L]]$artists[[2L]]$ydata,
      unlist(p$envelope$median),tolerance=1e-12)
    expect_equal(a$axes[[1L]]$artists[[3L]]$ydata,
      unlist(p$envelope$reference),tolerance=1e-12)
    expect_identical(b$axes[[1L]]$title,p$projection$title)
    expect_identical(b$axes[[1L]]$ylabel,p$projection$ylabel)
    expect_equal(b$axes[[1L]]$artists[[1L]]$xdata,
      unlist(p$projection$x))
    expect_equal(b$axes[[1L]]$artists[[1L]]$ydata,
      unlist(p$projection$y),tolerance=1e-12)
    expect_identical(b$axes[[1L]]$legend_labels,p$projection$legend)
    expect_identical(b$axes[[1L]]$xticklabels,p$projection$labels)
    expect_identical(c$axes[[1L]]$title,p$family$title)
    expect_identical(c$axes[[1L]]$ylabel,p$family$ylabel)
    expect_equal(c$axes[[1L]]$ylim,unlist(p$family$ylim))
    expect_identical(c$axes[[1L]]$legend_labels,p$family$legend)
    expect_identical(c$axes[[1L]]$xticklabels,p$family$labels)
    expect_equal(c$axes[[1L]]$artists[[1L]]$offsets,
      matrix(as.numeric(unlist(p$family$adjusted)),ncol=2L,byrow=TRUE),
      ignore_attr=TRUE)
    expect_equal(c$axes[[1L]]$artists[[2L]]$offsets,
      matrix(as.numeric(unlist(p$family$targetwise)),ncol=2L,byrow=TRUE),
      ignore_attr=TRUE)
  })
})
