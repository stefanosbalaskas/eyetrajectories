# Frozen eyetrajectoriespy==1.2.0:
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Scope is source scientific artists, not Python Matplotlib Axes identity.

.etr_four_mv_rqa_recovery_fixture <- function() {
  surrogate<-list(n_surrogates=3L,reference_dimension="x",
    convergence_iterations=c(4L,5L,6L),
    spectral_errors=matrix(c(.1,.2,.3,.4,.5,.6),
      3L,2L,byrow=TRUE),
    cross_spectral_errors=matrix(c(.03,.07,.11),3L,1L))
  nonlinearity<-list(
    surrogate_statistics=c(.1,.2,.3,.4,.5),
    observed_statistic=.36,statistic="joint_recurrence",p_value=.2)
  summary<-data.frame(metric=c("recurrence_rate","determinism"),
    mean=c(.45,.6),lower=c(.3,.4),upper=c(.65,.75),
    stringsAsFactors=FALSE)
  rqa<-structure(list(summary_table=summary,
    metrics=summary$metric,unit="curve"),
    class="etr_rqa_metric_bootstrap")
  recovery<-data.frame(
    scenario=c("alpha","beta"),metric=rep("mean_integrated_error",2L),
    median=c(.2,.2),mean=c(.3,.25),
    q25=c(.15,.2),q75=c(.25,.2),
    source=c("curve","curve"),component=c(1L,1L),
    stringsAsFactors=FALSE)
  list(surrogate=surrogate,nonlinearity=nonlinearity,rqa=rqa,
    recovery=recovery)
}
.etr_four_mv_rqa_recovery_pdf <- function(expr) {
  file<-tempfile(fileext=".pdf")
  grDevices::pdf(file,width=10,height=7)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(file)
  },add=TRUE)
  force(expr)
}

test_that("multivariate IAAFT source line artists preserve dimension maxima and legends",{
  z<-.etr_four_mv_rqa_recovery_fixture()
  .etr_four_mv_rqa_recovery_pdf({
    a<-etr_plot_multivariate_iaaft_diagnostics(z$surrogate,
      strict_source_record=TRUE)
    expect_s3_class(a,"etr_nonlinear_scientific_artist_record")
    expect_identical(a$source_export,"plot_multivariate_iaaft_diagnostics")
    expect_false(a$matplotlib_object_identity)
    expect_false(a$independently_certified)
    expect_identical(a$python_return_kind,"matplotlib.axes.Axes")
    ax<-a$axes[[1L]]
    expect_identical(ax$title,
      "Multivariate IAAFT preservation diagnostics: x reference")
    expect_identical(ax$xlabel,"Surrogate index")
    expect_identical(ax$ylabel,"Relative mismatch")
    expect_identical(ax$legend_labels,c("Max power-spectrum error",
      "Max cross-spectrum error"))
    expect_length(ax$artists,2L)
    for(artist in ax$artists) {
      expect_identical(artist$kind,"line")
      expect_identical(artist$marker,"o")
      expect_identical(artist$linestyle,"-")
      expect_equal(artist$xdata,c(0,1,2))
    }
    expect_equal(ax$artists[[1L]]$ydata,c(.2,.4,.6))
    expect_equal(ax$artists[[2L]]$ydata,c(.03,.07,.11))
    old<-etr_plot_multivariate_iaaft_diagnostics(z$surrogate)
    expect_equal(old$max_spectral_error,c(.2,.4,.6))
    expect_identical(old$surrogate,0:2)
    expect_error(etr_plot_multivariate_iaaft_diagnostics(z$surrogate,
      strict_source_record=NA),"strict_source_record")
    bad<-z$surrogate
    bad$spectral_errors[1L,1L]<-Inf
    expect_error(etr_plot_multivariate_iaaft_diagnostics(bad,
      strict_source_record=TRUE),"spectral_errors")
  })
})

test_that("multivariate surrogate strict histogram preserves exact NumPy boundaries",{
  z<-.etr_four_mv_rqa_recovery_fixture()
  .etr_four_mv_rqa_recovery_pdf({
    a<-etr_plot_multivariate_surrogate_nonlinearity(z$nonlinearity,
      bins=4L,strict_source_record=TRUE)
    expect_identical(a$source_export,
      "plot_multivariate_surrogate_nonlinearity")
    ax<-a$axes[[1L]]
    expect_identical(ax$title,
      "Multivariate IAAFT surrogate test (p=0.2)")
    expect_identical(ax$xlabel,"joint_recurrence")
    expect_identical(ax$ylabel,"Surrogate count")
    expect_identical(ax$legend_labels,"Observed")
    expect_length(ax$artists,2L)
    hist<-ax$artists[[1L]]
    expect_identical(hist$kind,"histogram")
    expect_identical(hist$alpha,.7)
    expect_equal(hist$edges,c(.1,.2,.3,.4,.5),
      tolerance=1e-12)
    # numpy.histogram uses binary-float edges: 0.3 falls just below
    # the computed third edge, into bin two.
    expect_equal(hist$counts,c(1,2,0,2),tolerance=0)
    expect_equal(sum(hist$counts),5)
    expect_identical(ax$artists[[2L]]$label,"Observed")
    expect_identical(ax$artists[[2L]]$linestyle,"--")
    expect_equal(ax$artists[[2L]]$xdata,c(.36,.36))
    expect_equal(ax$artists[[2L]]$ydata,c(0,1))
    single<-z$nonlinearity
    single$surrogate_statistics<-rep(.3,5L)
    b<-etr_plot_multivariate_surrogate_nonlinearity(single,
      bins=4L,strict_source_record=TRUE)
    expect_equal(b$axes[[1L]]$artists[[1L]]$edges,
      seq(-.2,.8,length.out=5L),tolerance=1e-12)
    old<-etr_plot_multivariate_surrogate_nonlinearity(
      z$nonlinearity,bins=4L)
    expect_equal(old$observed_statistic,.36)
    expect_error(etr_plot_multivariate_surrogate_nonlinearity(
      z$nonlinearity,bins=4,strict_source_record=TRUE),
      "Python integer")
    expect_error(etr_plot_multivariate_surrogate_nonlinearity(
      z$nonlinearity,strict_source_record="yes"),"strict_source_record")
  })
})

test_that("RQA population mean bootstrap source artists retain asymmetric percentile yerr",{
  z<-.etr_four_mv_rqa_recovery_fixture()
  .etr_four_mv_rqa_recovery_pdf({
    a<-etr_plot_rqa_metric_mean_bootstrap(z$rqa,
      strict_source_record=TRUE)
    expect_identical(a$source_export,"plot_rqa_metric_mean_bootstrap")
    ax<-a$axes[[1L]]
    expect_identical(ax$title,
      "RQA population mean (curve-level bootstrap)")
    expect_identical(ax$ylabel,"RQA metric")
    expect_identical(ax$xlabel,"")
    expect_false(ax$legend)
    expect_identical(ax$xticklabels,
      c("recurrence_rate","determinism"))
    expect_identical(ax$tick_rotation,30)
    expect_identical(ax$tick_horizontal_alignment,"right")
    er<-ax$artists[[1L]]
    expect_identical(er$kind,"errorbar")
    expect_identical(er$marker,"o")
    expect_identical(er$capsize,4)
    expect_equal(er$xdata,c(0,1))
    expect_equal(er$ydata,c(.45,.6))
    expect_equal(er$lower,c(.3,.4))
    expect_equal(er$upper,c(.65,.75))
    expect_equal(er$yerr,rbind(c(.15,.2),c(.2,.15)),
      tolerance=1e-12)
    b<-etr_plot_rqa_metric_mean_bootstrap(z$rqa,
      metrics="determinism",strict_source_record=TRUE)
    expect_identical(b$axes[[1L]]$xticklabels,"determinism")
    expect_equal(b$axes[[1L]]$artists[[1L]]$xdata,0)
    expect_equal(b$axes[[1L]]$artists[[1L]]$ydata,.6)
    legacy<-etr_plot_rqa_metric_mean_bootstrap(z$rqa)
    expect_equal(legacy$mean,c(.45,.6))
    expect_error(etr_plot_rqa_metric_mean_bootstrap(z$rqa,
      strict_source_record=1),"strict_source_record")
    bad<-z$rqa
    bad$summary_table$lower[1L]<-.8
    expect_error(etr_plot_rqa_metric_mean_bootstrap(bad,
      strict_source_record=TRUE),"must contain")
  })
})

test_that("functional recovery artists distinguish IQR median errorbars and point-only means",{
  z<-.etr_four_mv_rqa_recovery_fixture()
  .etr_four_mv_rqa_recovery_pdf({
    median<-etr_plot_functional_recovery_summary(z$recovery,
      metric="mean_integrated_error",
      strict_source_record=TRUE)
    expect_identical(median$source_export,
      "plot_functional_recovery_summary")
    ax<-median$axes[[1L]]
    expect_identical(ax$title,"mean integrated error")
    expect_identical(ax$ylabel,"median")
    expect_identical(ax$xlabel,"")
    expect_identical(ax$xticklabels,
      c("alpha / curve / C1","beta / curve / C1"))
    expect_identical(ax$tick_rotation,45)
    expect_identical(ax$tick_horizontal_alignment,"right")
    expect_true(ax$tight_layout)
    expect_length(ax$artists,1L)
    er<-ax$artists[[1L]]
    expect_identical(er$kind,"errorbar")
    expect_identical(er$marker,"o")
    expect_identical(er$capsize,3)
    expect_equal(er$xdata,c(0,1))
    expect_equal(er$ydata,c(.2,.2))
    expect_equal(er$yerr,rbind(c(.05,0),c(.05,0)),
      tolerance=1e-12)
    mean<-etr_plot_functional_recovery_summary(z$recovery,
      metric="mean_integrated_error",statistic="mean",
      strict_source_record=TRUE)
    ax<-mean$axes[[1L]]
    expect_identical(ax$ylabel,"mean")
    expect_identical(ax$artists[[1L]]$kind,"line")
    expect_identical(ax$artists[[1L]]$linestyle,"None")
    expect_equal(ax$artists[[1L]]$ydata,c(.3,.25))
    expect_false(mean$source_options$has_interquartile_errorbars)
    old<-etr_plot_functional_recovery_summary(z$recovery,
      metric="mean_integrated_error")
    expect_equal(old$estimate,c(.2,.2))
    expect_error(etr_plot_functional_recovery_summary(z$recovery,
      metric="missing",strict_source_record=TRUE),"absent")
    expect_error(etr_plot_functional_recovery_summary(z$recovery,
      metric="mean_integrated_error",
      strict_source_record=NA),"strict_source_record")
  })
})

test_that("frozen Python 1.2 multivariate/RQA/recovery scientific plotting artists match",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen public Python 1.2 scientific source artists opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_four_mv_rqa_recovery_fixture()
  .etr_four_mv_rqa_recovery_pdf({
    native<-list(
      etr_plot_multivariate_iaaft_diagnostics(z$surrogate,
        strict_source_record=TRUE),
      etr_plot_multivariate_surrogate_nonlinearity(z$nonlinearity,
        bins=4L,strict_source_record=TRUE),
      etr_plot_rqa_metric_mean_bootstrap(z$rqa,
        strict_source_record=TRUE),
      etr_plot_functional_recovery_summary(z$recovery,
        metric="mean_integrated_error",strict_source_record=TRUE),
      etr_plot_functional_recovery_summary(z$recovery,
        metric="mean_integrated_error",statistic="mean",
        strict_source_record=TRUE))
    reticulate::py_run_string("
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et
from types import SimpleNamespace as S

def _mk(cls,**kw):
    obj=object.__new__(cls)
    for k,v in kw.items(): object.__setattr__(obj,k,v)
    return obj

mv=_mk(et.MultivariateIAAFTResult,
    n_surrogates=3,reference_dimension='x',
    spectral_errors=np.array([[.1,.2],[.3,.4],[.5,.6]]),
    cross_spectral_errors=np.array([[.03],[.07],[.11]]))
sur=_mk(et.MultivariateSurrogateNonlinearityResult,
    surrogate_statistics=np.array([.1,.2,.3,.4,.5]),
    observed_statistic=.36,statistic='joint_recurrence',p_value=.2)
bootstrap=S(summary_table=pd.DataFrame({
    'metric':['recurrence_rate','determinism'],
    'mean':[.45,.6],'lower':[.3,.4],'upper':[.65,.75]}),
    metrics=('recurrence_rate','determinism'),unit='curve')
rec=pd.DataFrame({
    'scenario':['alpha','beta'],
    'metric':['mean_integrated_error','mean_integrated_error'],
    'median':[.2,.2],'mean':[.3,.25],
    'q25':[.15,.2],'q75':[.25,.2],
    'source':['curve','curve'],'component':[1,1]})
axes=[
    et.plot_multivariate_iaaft_diagnostics(mv),
    et.plot_multivariate_surrogate_nonlinearity(sur,bins=4),
    et.plot_rqa_metric_mean_bootstrap(bootstrap),
    et.plot_functional_recovery_summary(rec,
      metric='mean_integrated_error'),
    et.plot_functional_recovery_summary(rec,
      metric='mean_integrated_error',statistic='mean')]
def _line(x):
    return {
      'x':np.asarray(x.get_xdata(),dtype=float),
      'y':np.asarray(x.get_ydata(),dtype=float),
      'marker':x.get_marker(),
      'linestyle':x.get_linestyle()}
def _ax(x):
    return {'title':x.get_title(),'xlabel':x.get_xlabel(),
      'ylabel':x.get_ylabel(),
      'lines':[_line(line) for line in x.lines],
      'legend':[] if x.get_legend() is None else
         [t.get_text() for t in x.get_legend().get_texts()],
      'xticklabels':[t.get_text() for t in x.get_xticklabels()],
      'xtick_rotation':[t.get_rotation() for t in x.get_xticklabels()]}
oracle=[_ax(ax) for ax in axes]
hist=axes[1].patches
oracle[1]['edges']=np.asarray(
    [p.get_x() for p in hist]+
    [hist[-1].get_x()+hist[-1].get_width()],dtype=float)
oracle[1]['counts']=np.asarray([p.get_height() for p in hist],dtype=float)
oracle[1]['alpha']=hist[0].get_alpha()
oracle[1]['observed_x']=np.asarray(
    axes[1].lines[0].get_xdata(),dtype=float)
for i in [2,3]:
    segments=np.asarray(axes[i].containers[0].lines[2][0].get_segments(),
      dtype=float)
    oracle[i]['lower']=segments[:,0,1]
    oracle[i]['upper']=segments[:,1,1]
plt.close('all')
")
    oracle<-et_to_r(reticulate::py_get_attr(reticulate::py,"oracle"))
    expect_length(oracle,5L)
    for(i in seq_along(oracle)){
      a<-native[[i]]$axes[[1L]]
      for(k in c("title","xlabel","ylabel"))
        expect_identical(a[[k]],oracle[[i]][[k]],
          info=paste("source axis",i,k))
      expect_identical(a$legend_labels,
        as.character(oracle[[i]]$legend))
    }
    a<-native[[1L]]$axes[[1L]]$artists
    for(i in 1:2){
      expect_equal(a[[i]]$xdata,
        as.numeric(oracle[[1L]]$lines[[i]]$x),tolerance=0)
      expect_equal(a[[i]]$ydata,
        as.numeric(oracle[[1L]]$lines[[i]]$y),tolerance=1e-12)
      expect_identical(a[[i]]$marker,
        oracle[[1L]]$lines[[i]]$marker)
      expect_identical(a[[i]]$linestyle,
        oracle[[1L]]$lines[[i]]$linestyle)
    }
    h<-native[[2L]]$axes[[1L]]$artists[[1L]]
    expect_equal(h$edges,as.numeric(oracle[[2L]]$edges),
      tolerance=1e-12)
    expect_equal(h$counts,as.numeric(oracle[[2L]]$counts),
      tolerance=0)
    expect_equal(h$alpha,oracle[[2L]]$alpha,tolerance=0)
    expect_equal(native[[2L]]$axes[[1L]]$artists[[2L]]$xdata,
      as.numeric(oracle[[2L]]$observed_x),tolerance=0)
    for(i in c(3L,4L)){
      a<-native[[i]]$axes[[1L]]
      expect_equal(a$artists[[1L]]$lower,
        as.numeric(oracle[[i]]$lower),tolerance=1e-12)
      expect_equal(a$artists[[1L]]$upper,
        as.numeric(oracle[[i]]$upper),tolerance=1e-12)
      expect_identical(a$xticklabels,
        as.character(oracle[[i]]$xticklabels))
      expect_equal(rep(a$tick_rotation,length(a$xticklabels)),
        as.numeric(oracle[[i]]$xtick_rotation),tolerance=0)
    }
    expect_equal(native[[5L]]$axes[[1L]]$artists[[1L]]$ydata,
      as.numeric(oracle[[5L]]$lines[[1L]]$y),tolerance=0)
  })
})
