# Frozen eyetrajectoriespy==1.2.0, pinned:
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Source-scientific geometry only, NOT Python Matplotlib runtime identity.

.etr_four_recurrence_te_fixture <- function() {
  m<-matrix(FALSE,3L,3L)
  m[1L,1L]<-TRUE;m[1L,3L]<-TRUE
  m[2L,2L]<-TRUE;m[3L,1L]<-TRUE
  joint<-structure(list(matrix=m,
    joint_recurrence_rate=.444,component_labels=c("left","right")),
    class="etr_joint_recurrence")
  vals<-array(NA_real_,dim=c(2L,3L,1L))
  vals[1L,,1L]<-c(.1,.2,.3)
  vals[2L,,1L]<-c(.5,.4,.6)
  traj<-structure(list(time=c(1,2,3),values=vals,
    curve_ids=c("alpha","beta"),dimension_names="recurrence_rate",
    provenance=list(metric_units=list(recurrence_rate="fraction"))),
    class="etr_trajectory_set")
  window<-structure(list(trajectories=traj,
    metrics="recurrence_rate",time_unit="s"),
    class="etr_windowed_rqa_functional")
  table<-data.frame(embedding_dimension=c(3L,1L,2L),
    radius=c(.2,.2,.2),delay_samples=c(1L,1L,1L),
    recurrence_rate=c(.6,.2,.4))
  rqa<-structure(list(table=table,
    parameter_columns=c("embedding_dimension","radius","delay_samples"),
    metric_columns="recurrence_rate",curve_id="unit01"),
    class="etr_rqa_parameter_sensitivity")
  te_table<-data.frame(target_history=c(1L,1L,1L),
    source_history=c(1L,1L,1L),source_lag=c(3L,1L,2L),
    transfer_entropy_bits=c(.6,.2,.4))
  te<-structure(list(table=te_table,
    parameter_columns=c("target_history","source_history","source_lag"),
    metric_columns="transfer_entropy_bits"),
    class="etr_transfer_entropy_sensitivity")
  list(joint=joint,window=window,rqa=rqa,te=te)
}

.etr_four_recurrence_te_pdf <- function(expr) {
  f<-tempfile(fileext=".pdf")
  grDevices::pdf(f,width=9,height=6)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(f)
  },add=TRUE)
  force(expr)
}

test_that("joint recurrence source sparse offsets preserve scipy COO row order",{
  z<-.etr_four_recurrence_te_fixture()
  .etr_four_recurrence_te_pdf({
    r<-etr_plot_joint_recurrence(z$joint,strict_source_record=TRUE)
    expect_s3_class(r,"etr_nonlinear_scientific_artist_record")
    expect_identical(r$source_export,"plot_joint_recurrence")
    expect_false(r$matplotlib_object_identity)
    expect_false(r$independently_certified)
    expect_identical(r$python_return_kind,"matplotlib.axes.Axes")
    ax<-r$axes[[1L]]
    expect_identical(ax$title,
      "Joint recurrence (JRR=0.444, components=2)")
    expect_identical(ax$xlabel,"State index")
    expect_identical(ax$ylabel,"State index")
    expect_true(ax$inverted_yaxis)
    expect_identical(ax$aspect,"equal")
    expect_identical(ax$adjustable,"box")
    expect_identical(ax$artists[[1L]]$kind,"scatter")
    expect_identical(ax$artists[[1L]]$marker,"s")
    expect_identical(ax$artists[[1L]]$size,4)
    expect_equal(ax$artists[[1L]]$offsets,
      unname(rbind(c(0,0),c(2,0),c(1,1),c(0,2))),tolerance=0)
    old<-etr_plot_joint_recurrence(z$joint)
    expect_equal(nrow(old),4)
    expect_identical(names(old),c("col_index","row_index"))
    expect_error(etr_plot_joint_recurrence(z$joint,
      max_points=1L,strict_source_record=TRUE),"exceeds max_points")
    no_cap<-etr_plot_joint_recurrence(z$joint,
      max_points=NULL,strict_source_record=TRUE)
    expect_equal(nrow(no_cap$axes[[1L]]$artists[[1L]]$offsets),4)
  })
})

test_that("functional windowed RQA source preserves curves and full-ensemble mean",{
  z<-.etr_four_recurrence_te_fixture()
  .etr_four_recurrence_te_pdf({
    r<-etr_plot_windowed_rqa_trajectories(z$window,
      metric="recurrence_rate",show_mean=TRUE,max_curves=1L,
      strict_source_record=TRUE)
    expect_s3_class(r,"etr_nonlinear_scientific_artist_record")
    expect_identical(r$source_export,"plot_windowed_rqa_trajectories")
    ax<-r$axes[[1L]]
    expect_identical(ax$title,
      "Functional windowed RQA: recurrence_rate")
    expect_identical(ax$xlabel,"Window center (s)")
    expect_identical(ax$ylabel,"recurrence_rate (fraction)")
    expect_true(ax$legend)
    expect_identical(ax$legend_labels,"Across-curve mean")
    expect_length(ax$artists,2L)
    expect_identical(ax$artists[[1L]]$alpha,.45)
    expect_equal(ax$artists[[1L]]$xdata,c(1,2,3))
    expect_equal(ax$artists[[1L]]$ydata,c(.1,.2,.3))
    expect_identical(ax$artists[[2L]]$linewidth,2.2)
    expect_equal(ax$artists[[2L]]$ydata,c(.3,.3,.45),
      tolerance=1e-12)
    no_mean<-etr_plot_windowed_rqa_trajectories(z$window,
      metric="recurrence_rate",strict_source_record=TRUE)
    expect_length(no_mean$axes[[1L]]$artists,2L)
    expect_false(no_mean$axes[[1L]]$legend)
    expect_equal(no_mean$axes[[1L]]$artists[[2L]]$ydata,c(.5,.4,.6))
    old<-etr_plot_windowed_rqa_trajectories(z$window,
      metric="recurrence_rate",show_mean=TRUE,max_curves=1L)
    expect_equal(old$curve_values[1L,],c(.1,.2,.3))
    expect_equal(old$across_curve_mean,c(.3,.3,.45))
    missing_units<-z$window
    missing_units$trajectories$provenance<-list()
    fallback<-etr_plot_windowed_rqa_trajectories(missing_units,
      metric="recurrence_rate",strict_source_record=TRUE)
    expect_identical(fallback$axes[[1L]]$ylabel,
      "recurrence_rate (metric units)")
  })
})

test_that("RQA and TE strict scientific sensitivity lines use explicit ordered slices",{
  z<-.etr_four_recurrence_te_fixture()
  .etr_four_recurrence_te_pdf({
    rqa<-etr_plot_rqa_sensitivity(z$rqa,
      parameter="embedding_dimension",metric="recurrence_rate",
      strict_source_record=TRUE)
    ax<-rqa$axes[[1L]]
    expect_identical(rqa$source_export,"plot_rqa_sensitivity")
    expect_identical(ax$title,"RQA parameter sensitivity: unit01")
    expect_identical(ax$xlabel,"embedding_dimension")
    expect_identical(ax$ylabel,"recurrence_rate")
    expect_equal(ax$artists[[1L]]$xdata,c(1,2,3))
    expect_equal(ax$artists[[1L]]$ydata,c(.2,.4,.6))
    expect_identical(ax$artists[[1L]]$marker,"o")
    expect_false(ax$legend)
    te<-etr_plot_transfer_entropy_sensitivity(z$te,
      parameter="source_lag",strict_source_record=TRUE)
    ax<-te$axes[[1L]]
    expect_identical(te$source_export,
      "plot_transfer_entropy_sensitivity")
    expect_identical(ax$title,"Transfer-entropy specification sensitivity")
    expect_identical(ax$xlabel,"source lag")
    expect_identical(ax$ylabel,"transfer entropy bits")
    expect_equal(ax$artists[[1L]]$xdata,c(1,2,3))
    expect_equal(ax$artists[[1L]]$ydata,c(.2,.4,.6))
    expect_false(te$source_options$causal_identification_claim)
    expect_equal(etr_plot_rqa_sensitivity(z$rqa,
      parameter="embedding_dimension",metric="recurrence_rate")$recurrence_rate,
      c(.2,.4,.6))
    expect_equal(etr_plot_transfer_entropy_sensitivity(z$te,
      parameter="source_lag")$transfer_entropy_bits,c(.2,.4,.6))
  })
})

test_that("source plot modes reject ambiguous slices and nonlogical strict flags",{
  z<-.etr_four_recurrence_te_fixture()
  .etr_four_recurrence_te_pdf({
    expect_error(etr_plot_joint_recurrence(z$joint,
      strict_source_record=NA),"strict_source_record")
    expect_error(etr_plot_windowed_rqa_trajectories(z$window,
      metric="recurrence_rate",strict_source_record=1L),
      "strict_source_record")
    expect_error(etr_plot_rqa_sensitivity(z$rqa,
      parameter="embedding_dimension",metric="recurrence_rate",
      strict_source_record="yes"),"strict_source_record")
    expect_error(etr_plot_transfer_entropy_sensitivity(z$te,
      parameter="source_lag",strict_source_record=0L),
      "strict_source_record")
    duplicate<-z$rqa
    duplicate$table<-rbind(duplicate$table,duplicate$table[1L,,drop=FALSE])
    expect_error(etr_plot_rqa_sensitivity(duplicate,
      parameter="embedding_dimension",metric="recurrence_rate",
      strict_source_record=TRUE),"uniquely selected")
    varied<-z$te
    varied$table$target_history<-c(1L,1L,2L)
    # This is a genuine source-only refusal; the native original path is unchanged.
    expect_error(etr_plot_transfer_entropy_sensitivity(varied,
      parameter="source_lag",strict_source_record=TRUE),
      "must fix all other varying parameters")
    filtered<-etr_plot_transfer_entropy_sensitivity(varied,
      parameter="source_lag",filters=list(target_history=1L),
      strict_source_record=TRUE)
    expect_equal(filtered$axes[[1L]]$artists[[1L]]$xdata,c(1,2))
  })
})

test_that("pinned Python 1.2 joint, functional RQA and sensitivity artists compare",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("direct frozen Python 1.2 scientific artist oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_four_recurrence_te_fixture()
  .etr_four_recurrence_te_pdf({
    native<-list(
      etr_plot_joint_recurrence(z$joint,strict_source_record=TRUE),
      etr_plot_windowed_rqa_trajectories(z$window,
        metric="recurrence_rate",show_mean=TRUE,max_curves=1L,
        strict_source_record=TRUE),
      etr_plot_rqa_sensitivity(z$rqa,
        parameter="embedding_dimension",metric="recurrence_rate",
        strict_source_record=TRUE),
      etr_plot_transfer_entropy_sensitivity(z$te,
        parameter="source_lag",strict_source_record=TRUE))
    reticulate::py_run_string("
import numpy as np
import pandas as pd
from scipy.sparse import csr_matrix
from types import SimpleNamespace as S
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et

joint=object.__new__(et.JointRecurrenceResult)
mask=np.array([[True,False,True],[False,True,False],
  [True,False,False]],dtype=bool)
for key,val in dict(matrix=csr_matrix(mask),
  joint_recurrence_rate=.444,
  component_recurrences=(None,None),component_labels=('left','right')).items():
  object.__setattr__(joint,key,val)

class FakeTrajectory:
  def __init__(self):
    self.time=np.array([1.,2.,3.])
    self.curve_ids=('alpha','beta')
    self.n_curves=2
    self.provenance={'metric_units':{'recurrence_rate':'fraction'}}
  def dimension(self,metric):
    if metric!='recurrence_rate':raise KeyError(metric)
    return np.array([[.1,.2,.3],[.5,.4,.6]])
window=S(trajectories=FakeTrajectory(),metrics=('recurrence_rate',),
  n_curves=2,time_unit='s')
rqa=S(table=pd.DataFrame({
  'embedding_dimension':[3,1,2],
  'radius':[.2,.2,.2],'delay_samples':[1,1,1],
  'recurrence_rate':[.6,.2,.4]}),
  metric_columns=('recurrence_rate',),curve_id='unit01')
te=object.__new__(et.TransferEntropySensitivityResult)
for key,val in dict(table=pd.DataFrame({
   'target_history':[1,1,1],'source_history':[1,1,1],
   'source_lag':[3,1,2],'transfer_entropy_bits':[.6,.2,.4]}),
   parameter_columns=('target_history','source_history','source_lag'),
   metric_columns=('transfer_entropy_bits',)).items():
  object.__setattr__(te,key,val)
axes=[
  et.plot_joint_recurrence(joint),
  et.plot_windowed_rqa_trajectories(
    window,metric='recurrence_rate',show_mean=True,max_curves=1),
  et.plot_rqa_sensitivity(
    rqa,parameter='embedding_dimension',metric='recurrence_rate'),
  et.plot_transfer_entropy_sensitivity(te,parameter='source_lag')]
def _line(line):
  return {'x':np.asarray(line.get_xdata(),dtype=float),
    'y':np.asarray(line.get_ydata(),dtype=float),
    'alpha':line.get_alpha(),
    'linewidth':line.get_linewidth(),
    'marker':line.get_marker()}
def _axis(ax):
  return {'title':ax.get_title(),'xlabel':ax.get_xlabel(),
    'ylabel':ax.get_ylabel(),'lines':[_line(x) for x in ax.lines],
    'legend':[] if ax.get_legend() is None else
      [v.get_text() for v in ax.get_legend().get_texts()]}
oracle=[_axis(ax) for ax in axes]
oracle[0]['scatter']=np.asarray(axes[0].collections[0].get_offsets(),
  dtype=float)
oracle[0]['size']=np.asarray(axes[0].collections[0].get_sizes(),
  dtype=float)
oracle[0]['inverted']=axes[0].yaxis_inverted()
oracle[1]['mean']=np.asarray(axes[1].lines[-1].get_ydata(),dtype=float)
plt.close('all')
")
    py<-et_to_r(reticulate::py_get_attr(reticulate::py,"oracle"))
    expect_length(py,4L)
    for(i in seq_along(native)){
      ax<-native[[i]]$axes[[1L]]
      for(k in c("title","xlabel","ylabel"))
        expect_identical(ax[[k]],py[[i]][[k]],
          info=paste("plot",i,k))
      expect_identical(ax$legend_labels,as.character(py[[i]]$legend))
    }
    expect_equal(native[[1L]]$axes[[1L]]$artists[[1L]]$offsets,
      as.matrix(py[[1L]]$scatter),tolerance=0,ignore_attr=TRUE)
    expect_equal(native[[1L]]$axes[[1L]]$artists[[1L]]$size,
      as.numeric(py[[1L]]$size)[1L],tolerance=0)
    expect_identical(native[[1L]]$axes[[1L]]$inverted_yaxis,
      py[[1L]]$inverted)
    for(i in 2:4){
      artists<-native[[i]]$axes[[1L]]$artists
      expect_equal(artists[[1L]]$xdata,as.numeric(py[[i]]$lines[[1L]]$x),
        tolerance=0)
      expect_equal(artists[[1L]]$ydata,as.numeric(py[[i]]$lines[[1L]]$y),
        tolerance=1e-12)
      expect_identical(artists[[1L]]$marker,py[[i]]$lines[[1L]]$marker)
    }
    expect_equal(native[[2L]]$axes[[1L]]$artists[[1L]]$alpha,
      py[[2L]]$lines[[1L]]$alpha)
    expect_equal(native[[2L]]$axes[[1L]]$artists[[2L]]$linewidth,
      py[[2L]]$lines[[2L]]$linewidth)
    expect_equal(native[[2L]]$axes[[1L]]$artists[[2L]]$ydata,
      as.numeric(py[[2L]]$mean),tolerance=1e-12)
  })
})
