# Five source-scientific artists, frozen eyetrajectoriespy==1.2.0:
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Native numeric artists are not actual Python Matplotlib Axes.

.etr_five_nonlinear_te_fixture <- function() {
  table<-data.frame(embedding_dimension=c(2,3,4),
    requested_delay=c(1,1,1),exponent=c(.12,-.25,.17),
    r_squared=c(.65,.78,.72),standard_error=c(.05,.04,.05))
  kantz<-structure(list(table=table,curve_id="curve_1",
    exponent_unit="1/s"),class="etr_kantz_parameter_sensitivity")
  lyap<-structure(list(table=table,curve_id="curve_2",
    exponent_unit="1/s"),class="etr_lyapunov_parameter_sensitivity")
  analysis<-function(times,values,w,s) {
    a<-array(NA_real_,c(2L,length(times),1L))
    a[1L,,1L]<-values;a[2L,,1L]<-values+.1
    list(trajectories=list(curve_ids=c("a","b"),
      dimension_names="recurrence_rate",
      time=as.numeric(times),values=a),
      window_samples=as.integer(w),step_samples=as.integer(s),
      time_unit="s")
  }
  window<-structure(list(analyses=list(
    analysis(c(2,4,6),c(.2,.3,.4),5,2),
    analysis(c(3,6,9),c(.25,.4,.5),7,3)),
    metrics="recurrence_rate",
    provenance=list(specification_ids=c("spec_1","spec_2"))),
    class="etr_windowed_rqa_sensitivity")
  samples<-c(.11,.29,.38,.53,.77,.91)
  te<-structure(list(surrogate_transfer_entropy_bits=samples,
    observed=list(transfer_entropy_bits=.42)),
    class="etr_transfer_entropy_circular_shift_test")
  cte<-structure(list(surrogate_conditional_transfer_entropy_bits=
    samples+.04,observed=list(conditional_transfer_entropy_bits=.46)),
    class="etr_conditional_transfer_entropy_circular_shift_test")
  list(kantz=kantz,lyapunov=lyap,window=window,te=te,cte=cte)
}

.etr_five_nonlinear_te_pdf <- function(expr) {
  f<-tempfile(fileext=".pdf")
  grDevices::pdf(f,width=9,height=6)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(f)
  },add=TRUE)
  force(expr)
}

test_that("strict Kantz and Lyapunov source artists separate exponent from other measures",{
  z<-.etr_five_nonlinear_te_fixture()
  .etr_five_nonlinear_te_pdf({
    k<-etr_plot_kantz_sensitivity(z$kantz,
      parameter="embedding_dimension",strict_source_record=TRUE)
    l<-etr_plot_lyapunov_sensitivity(z$lyapunov,
      parameter="embedding_dimension",strict_source_record=TRUE)
    for(r in list(k,l)){
      expect_s3_class(r,"etr_nonlinear_scientific_artist_record")
      expect_false(r$matplotlib_object_identity)
      expect_false(r$independently_certified)
      expect_identical(r$python_return_kind,"matplotlib.axes.Axes")
      ax<-r$axes[[1L]]
      expect_identical(ax$xlabel,"embedding_dimension")
      expect_identical(ax$ylabel,"exponent (1/s)")
      expect_false(ax$legend)
      expect_identical(ax$artists[[1L]]$kind,"line")
      expect_identical(ax$artists[[1L]]$marker,"o")
      expect_identical(ax$artists[[1L]]$linestyle,"-")
      expect_equal(ax$artists[[1L]]$xdata,c(2,3,4))
      expect_equal(ax$artists[[1L]]$ydata,c(.12,-.25,.17))
      expect_length(ax$artists,2L)
      expect_identical(ax$artists[[2L]]$kind,"horizontal_reference")
      expect_identical(ax$artists[[2L]]$linestyle,":")
      expect_equal(ax$artists[[2L]]$ydata,c(0,0))
    }
    expect_identical(k$axes[[1L]]$title,"Kantz sensitivity: curve_1")
    expect_identical(l$axes[[1L]]$title,
      "Rosenstein sensitivity: curve_2")
    r<-etr_plot_lyapunov_sensitivity(z$lyapunov,
      parameter="embedding_dimension",response="r_squared",
      strict_source_record=TRUE)
    expect_identical(r$axes[[1L]]$ylabel,"r_squared")
    expect_length(r$axes[[1L]]$artists,1L)
    expect_equal(r$axes[[1L]]$artists[[1L]]$ydata,c(.65,.78,.72))
    old<-etr_plot_kantz_sensitivity(z$kantz,
      parameter="embedding_dimension")
    expect_equal(old$exponent,c(.12,-.25,.17))
    expect_identical(names(old),c("embedding_dimension","exponent"))
    expect_error(etr_plot_kantz_sensitivity(z$kantz,
      parameter="embedding_dimension",
      strict_source_record=1L),"strict_source_record")
    expect_error(etr_plot_lyapunov_sensitivity(z$lyapunov,
      parameter="embedding_dimension",response="missing",
      strict_source_record=TRUE),"response")
    duplicate<-z$kantz
    duplicate$table<-rbind(duplicate$table,duplicate$table[1L,,drop=FALSE])
    expect_error(etr_plot_kantz_sensitivity(duplicate,
      parameter="embedding_dimension",strict_source_record=TRUE),
      "multiple rows")
  })
})

test_that("window/step RQA source artists preserve each specification center grid and legend",{
  z<-.etr_five_nonlinear_te_fixture()
  .etr_five_nonlinear_te_pdf({
    r<-etr_plot_windowed_rqa_sensitivity(z$window,curve="a",
      metric="recurrence_rate",strict_source_record=TRUE)
    expect_s3_class(r,"etr_nonlinear_scientific_artist_record")
    expect_identical(r$source_export,"plot_windowed_rqa_sensitivity")
    ax<-r$axes[[1L]]
    expect_identical(ax$title,
      "Window/step sensitivity: a / recurrence_rate")
    expect_identical(ax$xlabel,"Window center (s)")
    expect_identical(ax$ylabel,"recurrence_rate")
    expect_true(ax$legend)
    expect_identical(ax$legend_labels,
      c("spec_1: W=5, S=2","spec_2: W=7, S=3"))
    expect_length(ax$artists,2L)
    expect_equal(ax$artists[[1L]]$xdata,c(2,4,6))
    expect_equal(ax$artists[[2L]]$xdata,c(3,6,9))
    expect_equal(ax$artists[[1L]]$ydata,c(.2,.3,.4))
    expect_equal(ax$artists[[2L]]$ydata,c(.25,.4,.5))
    expect_true(all(vapply(ax$artists,
      function(x)identical(x$marker,"o"),logical(1L))))
    index<-etr_plot_windowed_rqa_sensitivity(z$window,
      curve=0L,metric="recurrence_rate",strict_source_record=TRUE)
    expect_identical(index$axes[[1L]]$artists,ax$artists)
    old<-etr_plot_windowed_rqa_sensitivity(z$window,
      curve="a",metric="recurrence_rate")
    expect_length(old,2L)
    expect_equal(old[[1L]]$time,c(2,4,6))
    expect_error(etr_plot_windowed_rqa_sensitivity(z$window,
      curve=2L,metric="recurrence_rate",strict_source_record=TRUE),
      "zero-based")
    expect_error(etr_plot_windowed_rqa_sensitivity(z$window,
      curve="a",metric="recurrence_rate",
      strict_source_record=NA),"strict_source_record")
  })
})

test_that("both TE shift histograms retain fixed NumPy bin edges and observed markers",{
  z<-.etr_five_nonlinear_te_fixture()
  .etr_five_nonlinear_te_pdf({
    for(kind in c("plain","conditional")){
      conditional<-identical(kind,"conditional")
      r<-if(conditional)
        etr_plot_conditional_transfer_entropy_circular_shift_test(
          z$cte,bins=4L,strict_source_record=TRUE) else
        etr_plot_transfer_entropy_circular_shift_test(
          z$te,bins=4L,strict_source_record=TRUE)
      expect_s3_class(r,"etr_nonlinear_scientific_artist_record")
      expect_false(r$matplotlib_object_identity)
      expect_false(r$independently_certified)
      expect_identical(r$python_return_kind,"matplotlib.axes.Axes")
      ax<-r$axes[[1L]]
      expect_false(ax$legend)
      expect_length(ax$artists,2L)
      hist<-ax$artists[[1L]]
      expect_identical(hist$kind,"histogram")
      expect_identical(hist$bins,"explicit_equal_width")
      expect_equal(sum(hist$counts),6)
      expect_identical(length(hist$edges),5L)
      expect_identical(hist$sample_size,6L)
      expect_equal(hist$counts,c(2,1,1,2))
      expect_equal(hist$edges,
        if(conditional)seq(.15,.95,length.out=5L)
        else seq(.11,.91,length.out=5L),tolerance=1e-12)
      expect_identical(ax$artists[[2L]]$kind,"vertical_reference")
      expect_identical(ax$artists[[2L]]$linestyle,"--")
      expect_equal(ax$artists[[2L]]$xdata,
        rep(if(conditional).46 else .42,2L))
      expect_equal(ax$artists[[2L]]$ydata,c(0,1))
      expect_false(r$source_options$causal_identification_claim)
      expect_identical(ax$title,if(conditional)
        "Conditional-TE circular-shift test" else
        "Transfer-entropy circular-shift test")
      expect_identical(ax$ylabel,if(conditional)
        "Source-only circular-shift surrogates" else
        "Circular-shift surrogates")
    }
    original<-etr_plot_transfer_entropy_circular_shift_test(z$te,
      bins=4L)
    expect_identical(original$binning,"explicit_equal_width")
    expect_equal(original$counts,c(2,1,1,2))
    expect_error(etr_plot_transfer_entropy_circular_shift_test(z$te,
      bins=4L,strict_source_record=1),"strict_source_record")
    expect_error(etr_plot_transfer_entropy_circular_shift_test(z$te,
      bins=4,strict_source_record=TRUE),"R integer")
    expect_error(etr_plot_conditional_transfer_entropy_circular_shift_test(
      z$cte,bins="invalid",strict_source_record=TRUE),"bins")
    expect_error(etr_plot_conditional_transfer_entropy_circular_shift_test(
      z$cte,bins=4L,strict_source_record=NA),"strict_source_record")
  })
})

test_that("strict auto TE source histograms use NumPy equal-width and include last bin",{
  z<-.etr_five_nonlinear_te_fixture()
  .etr_five_nonlinear_te_pdf({
    a<-etr_plot_transfer_entropy_circular_shift_test(z$te,
      bins="auto",strict_source_record=TRUE)
    b<-etr_plot_conditional_transfer_entropy_circular_shift_test(z$cte,
      bins="auto",strict_source_record=TRUE)
    for(record in list(a,b)){
      x<-record$axes[[1L]]$artists[[1L]]
      expect_match(x$bins,"^numpy_auto_(relaxed|classic)$")
      expect_equal(sum(x$counts),6)
      expect_length(x$edges,length(x$counts)+1L)
      expect_equal(tail(x$edges,1),tail(record$axes[[1L]]$
        artists[[1L]]$upper,1))
    }
    legacy<-etr_plot_transfer_entropy_circular_shift_test(z$te)
    expect_identical(legacy$binning,"R_Sturges_not_numpy_auto")
  })
})

test_that("pinned Python 1.2 Matplotlib nonlinear and TE artists match source numeric geometry",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 scientific artists are opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_five_nonlinear_te_fixture()
  .etr_five_nonlinear_te_pdf({
    native<-list(
      etr_plot_kantz_sensitivity(z$kantz,
        parameter="embedding_dimension",strict_source_record=TRUE),
      etr_plot_lyapunov_sensitivity(z$lyapunov,
        parameter="embedding_dimension",response="r_squared",
        strict_source_record=TRUE),
      etr_plot_windowed_rqa_sensitivity(z$window,
        curve="a",metric="recurrence_rate",strict_source_record=TRUE),
      etr_plot_transfer_entropy_circular_shift_test(z$te,
        bins=4L,strict_source_record=TRUE),
      etr_plot_conditional_transfer_entropy_circular_shift_test(z$cte,
        bins=4L,strict_source_record=TRUE))
    reticulate::py_run_string("
import numpy as np
import pandas as pd
from types import SimpleNamespace as S
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et

t=pd.DataFrame({
  'embedding_dimension':[2,3,4],
  'requested_delay':[1,1,1],
  'exponent':[.12,-.25,.17],
  'r_squared':[.65,.78,.72],
  'standard_error':[.05,.04,.05]})
kantz=S(table=t,curve_id='curve_1',exponent_unit='1/s')
lyap=S(table=t,curve_id='curve_2',exponent_unit='1/s')
class Trajectory:
    def __init__(self,time,values):
      self.time=np.asarray(time,dtype=float)
      self.curve_ids=('a','b')
      self._values=np.vstack((values,np.asarray(values)+.1))
    def dimension(self,metric):
      if metric!='recurrence_rate':raise KeyError(metric)
      return self._values
a1=S(trajectories=Trajectory([2.,4.,6.],[.2,.3,.4]),
  window_samples=5,step_samples=2,time_unit='s')
a2=S(trajectories=Trajectory([3.,6.,9.],[.25,.4,.5]),
  window_samples=7,step_samples=3,time_unit='s')
window=S(analyses=(a1,a2),metrics=('recurrence_rate',),
 provenance={'specification_ids':('spec_1','spec_2')})
def _make(cls,**kw):
    o=object.__new__(cls)
    for key,value in kw.items():object.__setattr__(o,key,value)
    return o
v=np.array([.11,.29,.38,.53,.77,.91])
te=_make(et.TransferEntropyCircularShiftTestResult,
    surrogate_transfer_entropy_bits=v,
    observed=S(transfer_entropy_bits=.42))
cte=_make(et.ConditionalTransferEntropyCircularShiftTestResult,
    surrogate_conditional_transfer_entropy_bits=v+.04,
    observed=S(conditional_transfer_entropy_bits=.46))
ax=[
  et.plot_kantz_sensitivity(kantz,parameter='embedding_dimension'),
  et.plot_lyapunov_sensitivity(lyap,parameter='embedding_dimension',
    response='r_squared'),
  et.plot_windowed_rqa_sensitivity(window,curve='a',
    metric='recurrence_rate'),
  et.plot_transfer_entropy_circular_shift_test(te,bins=4),
  et.plot_conditional_transfer_entropy_circular_shift_test(cte,bins=4)]
def _line(l):
  return {'x':np.asarray(l.get_xdata(),dtype=float),
          'y':np.asarray(l.get_ydata(),dtype=float),
          'marker':l.get_marker(),'linestyle':l.get_linestyle()}
def _axis(a):
  return {'title':a.get_title(),'xlabel':a.get_xlabel(),
   'ylabel':a.get_ylabel(),
   'lines':[_line(x) for x in a.lines],
   'legend':[] if a.get_legend() is None else
     [t.get_text() for t in a.get_legend().get_texts()]}
oracle=[_axis(a) for a in ax]
for i in (3,4):
    patches=ax[i].patches
    oracle[i]['counts']=np.array([p.get_height() for p in patches])
    oracle[i]['edges']=np.array([p.get_x() for p in patches]+[
      patches[-1].get_x()+patches[-1].get_width()])
    oracle[i]['observed_x']=np.asarray(ax[i].lines[0].get_xdata(),
      dtype=float)
plt.close('all')
")
    py<-et_to_r(reticulate::py_get_attr(reticulate::py,"oracle"))
    expect_length(py,5L)
    for(i in seq_along(py)){
      ax<-native[[i]]$axes[[1L]]
      for(k in c("title","xlabel","ylabel"))
        expect_identical(ax[[k]],py[[i]][[k]],
          info=paste("source axis label",i,k))
      expect_identical(ax$legend_labels,
        as.character(py[[i]]$legend))
    }
    for(i in 1:3){
      art<-native[[i]]$axes[[1L]]$artists
      expect_equal(art[[1L]]$xdata,
        as.numeric(py[[i]]$lines[[1L]]$x),tolerance=0)
      expect_equal(art[[1L]]$ydata,
        as.numeric(py[[i]]$lines[[1L]]$y),tolerance=1e-12)
      expect_identical(art[[1L]]$marker,
        py[[i]]$lines[[1L]]$marker)
    }
    for(i in 4:5){
      art<-native[[i]]$axes[[1L]]$artists
      expect_equal(art[[1L]]$counts,as.numeric(py[[i]]$counts),
        tolerance=0)
      expect_equal(art[[1L]]$edges,as.numeric(py[[i]]$edges),
        tolerance=1e-12)
      expect_equal(art[[2L]]$xdata,
        as.numeric(py[[i]]$observed_x),tolerance=0)
      expect_identical(art[[2L]]$linestyle,
        py[[i]]$lines[[1L]]$linestyle)
    }
    expect_equal(native[[1L]]$axes[[1L]]$artists[[2L]]$ydata,
      as.numeric(py[[1L]]$lines[[2L]]$y),tolerance=0)
  })
})
