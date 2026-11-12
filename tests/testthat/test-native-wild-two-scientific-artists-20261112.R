# Frozen source-scientific Matplotlib artist tests.
# eyetrajectoriespy==1.2.0 plotting.py at
# c1cd95ad718327550f7e55393ff38582872f7a94.
# No live Python Axes return or independent certification is claimed.

.etr_two_wild_plot_fixture <- function() {
  roots<-rbind(c(.1,.2,.3),c(.5,.4,.1),c(.9,.6,.7),c(.2,.8,.3))
  projection<-list(
    target_curve_ids=c("A","B","C"),
    bootstrap_projections=matrix(0,4L,3L),
    studentized_roots=roots,
    reference_projection=c(.3,-.2,.1),
    reference_se=c(.1,.2,.05),
    confidence_level=.95,multiplier="rademacher",
    residual_components=2L,inference_components=3L,
    provenance=list(fpca_wild_bootstrap_projection=list(
      studentization="full_fit")))
  family<-list(projection_result=projection,
    observed_statistics=c(.4,.5,.25),max_statistics=c(.3,.5,.9,.8),
    global_statistic=.7,reject_targetwise=rep(FALSE,3),
    reject_familywise=rep(FALSE,3),reject_global=FALSE,
    significance_level=.05,pvalue_correction="plus_one",
    provenance=list())
  list(family=family,projection=projection)
}

.etr_two_wild_plot_pdf <- function(expr) {
  path<-tempfile(fileext=".pdf")
  grDevices::pdf(path,width=9,height=6)
  on.exit({
    if(grDevices::dev.cur()>1L) grDevices::dev.off()
    unlink(path)
  },add=TRUE)
  force(expr)
}

test_that("Monte Carlo precision native artist preserves both fixed-family errorbars",{
  z<-.etr_two_wild_plot_fixture()
  mc<-etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(z$family)
  .etr_two_wild_plot_pdf({
    r<-etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics(mc,
      max_targets=2L,show_targetwise=TRUE,strict_source_record=TRUE)
    expect_s3_class(r,"etr_fpca_inference_artist_source_record")
    expect_identical(r$source_export,
      "plot_fpca_wild_bootstrap_monte_carlo_diagnostics")
    expect_identical(r$python_return_kind,"matplotlib.axes.Axes")
    expect_false(r$matplotlib_object_identity)
    expect_false(r$independently_certified)
    ax<-r$axes[[1L]]
    expect_identical(ax$xticklabels,c("A","B"))
    expect_identical(ax$xtick_rotation,90)
    expect_identical(ax$ylim,c(-.02,1.02))
    expect_identical(ax$ylabel,"Bootstrap exceedance probability")
    expect_identical(ax$legend_labels,c(
      "maxT tail probability","target-wise tail probability","alpha=0.05"))
    for(k in 1:2){
      artist<-ax$artists[[k]]
      expect_identical(artist$kind,"errorbar")
      expect_identical(artist$linestyle,"none")
      expect_identical(artist$capsize,3)
      expect_equal(artist$xdata,c(0,1))
    }
    expect_identical(ax$artists[[1L]]$marker,"o")
    expect_identical(ax$artists[[2L]]$marker,"x")
    expect_equal(ax$artists[[1L]]$ydata,mc$adjusted_tail_probabilities[1:2])
    expect_equal(ax$artists[[1L]]$lower,mc$adjusted_interval_lower[1:2])
    expect_equal(ax$artists[[1L]]$upper,mc$adjusted_interval_upper[1:2])
    expect_equal(ax$artists[[2L]]$ydata,mc$targetwise_tail_probabilities[1:2])
    expect_equal(ax$artists[[2L]]$lower,mc$targetwise_interval_lower[1:2])
    expect_equal(ax$artists[[2L]]$upper,mc$targetwise_interval_upper[1:2])
    expect_equal(ax$artists[[1L]]$yerr,rbind(
      mc$adjusted_tail_probabilities[1:2]-mc$adjusted_interval_lower[1:2],
      mc$adjusted_interval_upper[1:2]-mc$adjusted_tail_probabilities[1:2]),
      tolerance=0)
    expect_identical(ax$artists[[3L]]$kind,"horizontal_reference")
    expect_equal(ax$artists[[3L]]$ydata,c(.05,.05))
    no<-etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics(mc,
      max_targets=1L,show_targetwise=FALSE,strict_source_record=TRUE)
    expect_length(no$axes[[1L]]$artists,2L)
    expect_identical(no$axes[[1L]]$legend_labels,
      c("maxT tail probability","alpha=0.05"))
    expect_equal(no$axes[[1L]]$artists[[1L]]$xdata,0)
    # Backward compatible default R numerical geometry.
    base<-etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics(mc,
      max_targets=2L,show_targetwise=TRUE)
    expect_identical(names(base),c("target_index","target_curve_id",
      "adjusted","adjusted_lower","adjusted_upper",
      "targetwise","targetwise_lower","targetwise_upper"))
    expect_equal(base$adjusted,mc$adjusted_tail_probabilities[1:2])
  })
})

test_that("simultaneous FPCR intervals retain exact source errorbar families",{
  z<-.etr_two_wild_plot_fixture()
  sim<-etr_fpca_wild_bootstrap_projection_simultaneous_interval(
    z$projection,confidence_level=.5)
  .etr_two_wild_plot_pdf({
    r<-etr_plot_fpca_wild_bootstrap_simultaneous_interval(sim,
      max_targets=2L,show_targetwise=TRUE,strict_source_record=TRUE)
    expect_s3_class(r,"etr_fpca_inference_artist_source_record")
    expect_identical(r$source_export,
      "plot_fpca_wild_bootstrap_simultaneous_interval")
    ax<-r$axes[[1L]]
    expect_identical(ax$title,
      "Familywise heteroscedastic Gaussian FPCR projection inference")
    expect_identical(ax$xlabel,"Fixed target trajectory")
    expect_identical(ax$ylabel,"Centered FPCR projection")
    expect_identical(ax$xticklabels,c("A","B"))
    expect_identical(ax$legend_labels,c(
      "familywise simultaneous interval","target-wise interval"))
    expect_length(ax$artists,3L)
    expect_identical(ax$artists[[1L]]$marker,"o")
    expect_identical(ax$artists[[1L]]$capsize,3)
    expect_identical(ax$artists[[2L]]$marker,".")
    expect_identical(ax$artists[[2L]]$capsize,2)
    expect_equal(ax$artists[[1L]]$ydata,c(.3,-.2))
    expect_equal(ax$artists[[1L]]$lower,sim$lower[1:2])
    expect_equal(ax$artists[[1L]]$upper,sim$upper[1:2])
    expect_equal(ax$artists[[2L]]$lower,
      c(.3,-.2)-sim$targetwise_critical_values[1:2]*c(.1,.2))
    expect_equal(ax$artists[[2L]]$upper,
      c(.3,-.2)+sim$targetwise_critical_values[1:2]*c(.1,.2))
    expect_equal(ax$artists[[3L]]$ydata,c(0,0))
    no<-etr_plot_fpca_wild_bootstrap_simultaneous_interval(sim,
      max_targets=1L,show_targetwise=FALSE,strict_source_record=TRUE)
    expect_length(no$axes[[1L]]$artists,2L)
    expect_identical(no$axes[[1L]]$legend_labels,
      "familywise simultaneous interval")
    expect_equal(no$axes[[1L]]$xticks,0)
    # Default plotting record and computed intervals are unchanged.
    base<-etr_plot_fpca_wild_bootstrap_simultaneous_interval(sim,
      max_targets=2L)
    expect_identical(names(base),c("target_index","target_curve_id",
      "reference_projection","simultaneous_lower","simultaneous_upper",
      "targetwise_lower","targetwise_upper"))
    expect_equal(base$simultaneous_lower,sim$lower[1:2])
    expect_equal(base$simultaneous_upper,sim$upper[1:2])
  })
})

test_that("strict wild plot modes fail closed on malformed inputs and flags",{
  z<-.etr_two_wild_plot_fixture()
  mc<-etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(z$family)
  sim<-etr_fpca_wild_bootstrap_projection_simultaneous_interval(z$projection)
  .etr_two_wild_plot_pdf({
    expect_error(etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics(
      mc,strict_source_record=1L),"strict_source_record")
    expect_error(etr_plot_fpca_wild_bootstrap_simultaneous_interval(
      sim,strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics(
      mc,max_targets=0,strict_source_record=TRUE),"max_targets")
    expect_error(etr_plot_fpca_wild_bootstrap_simultaneous_interval(
      sim,show_targetwise=1L,strict_source_record=TRUE),"show_targetwise")
    bad<-mc;bad$adjusted_interval_lower[1L]<-1
    expect_error(etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics(
      bad,strict_source_record=TRUE),"interval bounds")
    bad<-sim;bad$projection_result$reference_se[1L]<--.1
    expect_error(etr_plot_fpca_wild_bootstrap_simultaneous_interval(
      bad,strict_source_record=TRUE),"nonnegative")
    bad<-sim;bad$upper[1L]<-0
    expect_error(etr_plot_fpca_wild_bootstrap_simultaneous_interval(
      bad,strict_source_record=TRUE),"must enclose")
  })
})

test_that("direct frozen Python 1.2 public Matplotlib artists reproduce both records",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 wild graphics oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_two_wild_plot_fixture()
  mc<-etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(z$family)
  sim<-etr_fpca_wild_bootstrap_projection_simultaneous_interval(
    z$projection,confidence_level=.5)
  .etr_two_wild_plot_pdf({
    a<-etr_plot_fpca_wild_bootstrap_monte_carlo_diagnostics(mc,
      max_targets=2L,show_targetwise=TRUE,strict_source_record=TRUE)
    b<-etr_plot_fpca_wild_bootstrap_simultaneous_interval(sim,
      max_targets=2L,show_targetwise=TRUE,strict_source_record=TRUE)
    reticulate::py_run_string("
import numpy as np
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et

def _eobj(cls, **kw):
    o=object.__new__(cls)
    for k,v in kw.items(): object.__setattr__(o,k,v)
    return o

_proj=_eobj(et.FPCAWildBootstrapProjectionResult,
    target_curve_ids=('A','B','C'),
    bootstrap_projections=np.zeros((4,3)),
    studentized_roots=np.array([
       [.1,.2,.3],[.5,.4,.1],[.9,.6,.7],[.2,.8,.3]]),
    reference_projection=np.array([.3,-.2,.1]),
    reference_se=np.array([.1,.2,.05]),
    confidence_level=.95,multiplier='rademacher',
    residual_components=2,inference_components=3,
    provenance={'fpca_wild_bootstrap_projection':
      {'studentization':'full_fit'}})
_fam=_eobj(et.FPCAWildBootstrapFamilyTestResult,
    projection_result=_proj,
    observed_statistics=np.array([.4,.5,.25]),
    max_statistics=np.array([.3,.5,.9,.8]),global_statistic=.7,
    reject_targetwise=np.array([False,False,False]),
    reject_familywise=np.array([False,False,False]),
    reject_global=False,significance_level=.05,
    pvalue_correction='plus_one',provenance={})
_py_mc=et.fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(_fam)
_py_sim=et.fpca_wild_bootstrap_projection_simultaneous_interval(
    _proj,confidence_level=.5)
_py_a=et.plot_fpca_wild_bootstrap_monte_carlo_diagnostics(
    _py_mc,max_targets=2,show_targetwise=True)
_py_b=et.plot_fpca_wild_bootstrap_simultaneous_interval(
    _py_sim,max_targets=2,show_targetwise=True)
def _view(ax):
    bars=[]
    for c in ax.containers:
        plotline, caplines, segments = c.lines
        lines=np.asarray(segments[0].get_segments())
        bars.append({
            'x':np.asarray(plotline.get_xdata(),dtype=float),
            'y':np.asarray(plotline.get_ydata(),dtype=float),
            'lo':np.asarray(lines[:,0,1],dtype=float),
            'hi':np.asarray(lines[:,1,1],dtype=float),
            'marker':plotline.get_marker(),
            'cap_marker_size':caplines[0].get_markersize() if caplines else 0})
    return {'title':ax.get_title(),'xlabel':ax.get_xlabel(),
      'ylabel':ax.get_ylabel(),
      'labels':[t.get_text() for t in ax.get_xticklabels()],
      'legend':[t.get_text() for t in ax.get_legend().get_texts()],
      'xticks':np.asarray(ax.get_xticks(),dtype=float),
      'bars':bars}
_py_wild_two_artist_oracle={'mc':_view(_py_a),'sim':_view(_py_b)}
_py_wild_two_artist_oracle['mc']['ylim']=np.asarray(_py_a.get_ylim())
plt.close('all')
")
    out<-et_to_r(reticulate::py_get_attr(
      reticulate::py,"_py_wild_two_artist_oracle"))
    for(spec in list(list(r=a,source=out$mc),
                   list(r=b,source=out$sim))){
      ax<-spec$r$axes[[1L]];py<-spec$source
      for(field in c("title","xlabel","ylabel"))
        expect_identical(ax[[field]],py[[field]])
      expect_identical(ax$xticklabels,as.character(py$labels))
      expect_identical(ax$legend_labels,as.character(py$legend))
      expect_equal(ax$xticks,as.numeric(py$xticks),tolerance=0)
      expect_length(py$bars,2L)
      for(k in 1:2){
        artist<-ax$artists[[k]];bars<-py$bars[[k]]
        expect_identical(artist$marker,bars$marker)
        expect_equal(artist$xdata,as.numeric(bars$x),tolerance=0)
        expect_equal(artist$ydata,as.numeric(bars$y),tolerance=1e-12)
        expect_equal(artist$lower,as.numeric(bars$lo),tolerance=1e-12)
        expect_equal(artist$upper,as.numeric(bars$hi),tolerance=1e-12)
        expect_equal(artist$capsize*2,bars$cap_marker_size,tolerance=1e-12)
      }
    }
    expect_equal(a$axes[[1L]]$ylim,as.numeric(out$mc$ylim),tolerance=0)
  })
})
