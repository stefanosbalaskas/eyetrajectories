# Frozen eyetrajectoriespy==1.2.0 / commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Native scientific source geometry only, not live Python Matplotlib Axes.

.etr_three_mixed_conformal_source_fixture <- function() {
  participant<-list(participant_ids=c("p2","p1"),time=c(0,.5,1),
    time_unit="s",dimension_name="y",
    random_intercept_functions=matrix((1:6)/10,nrow=2L),
    random_slope_functions=matrix((11:16)/10,nrow=2L),
    random_slope_predictor="cue")
  trial<-list(source_curve_ids=c("c2","c1"),
    curve_participant_ids=c("p1","p2"),
    curve_trial_ids=c("trial2","trial1"),
    trial_ids=c("p1/trial2","p2/trial1"),
    time=c(0,.5,1),time_unit="s",
    trial_random_effect="functional_intercept",
    trial_random_effect_functions=matrix((1:6)/5,nrow=2L))
  conformal<-list(target_curve_ids=c("t1","t2","t3"),
    p_values=c(.8,.4,.2),alpha=.2,review_flags=c(FALSE,FALSE,TRUE))
  legacy<-list(calibration=data.frame(
    curve_id=paste0("cal",1:4),score=c(.1,.3,.4,.5)),
    test=data.frame(curve_id=c("t1","t2","t3"),
      score=c(.2,.5,.9)),
    cutoff=list(alpha=.2),training_ids="source")
  list(participant=participant,trial=trial,
    conformal=conformal,legacy=legacy)
}

.etr_three_mixed_conformal_pdf <- function(code) {
  path<-tempfile(fileext=".pdf")
  grDevices::pdf(path,width=9,height=6)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(path)
  },add=TRUE)
  force(code)
}

test_that("participant source artists preserve BLUP order, opacity and conditional legend",{
  z<-.etr_three_mixed_conformal_source_fixture()
  .etr_three_mixed_conformal_pdf({
    a<-etr_plot_functional_random_effects(z$participant,
      strict_source_record=TRUE)
    expect_s3_class(a,"etr_nonlinear_scientific_artist_record")
    expect_identical(a$source_export,"plot_functional_random_effects")
    expect_false(a$matplotlib_object_identity)
    expect_false(a$independently_certified)
    expect_identical(a$python_return_kind,"matplotlib.axes.Axes")
    ax<-a$axes[[1L]]
    expect_identical(ax$title,
      "Participant functional random intercepts")
    expect_identical(ax$xlabel,"Time (s)")
    expect_identical(ax$ylabel,"Random intercept: y")
    expect_true(ax$legend)
    expect_identical(ax$legend_labels,c("p2","p1"))
    expect_length(ax$artists,3L)
    expect_equal(ax$artists[[1L]]$xdata,c(0,.5,1))
    expect_equal(ax$artists[[1L]]$ydata,c(.1,.3,.5))
    expect_equal(ax$artists[[2L]]$ydata,c(.2,.4,.6))
    expect_identical(ax$artists[[1L]]$alpha,.35)
    expect_identical(ax$artists[[2L]]$alpha,.35)
    expect_identical(ax$artists[[3L]]$kind,"horizontal_reference")
    expect_identical(ax$artists[[3L]]$linestyle,"--")
    slope<-etr_plot_functional_random_effects(z$participant,
      effect="slope",max_participants=1L,alpha=.5,
      strict_source_record=TRUE)
    ax<-slope$axes[[1L]]
    expect_identical(ax$title,"Participant functional random slopes: cue")
    expect_identical(ax$ylabel,"Random slope: y")
    expect_identical(ax$legend_labels,"p2")
    expect_length(ax$artists,2L)
    expect_equal(ax$artists[[1L]]$ydata,c(1.1,1.3,1.5))
    expect_identical(ax$artists[[1L]]$alpha,.5)
    default<-etr_plot_functional_random_effects(z$participant)
    expect_equal(default$lines$estimate,c(.1,.3,.5,.2,.4,.6))
    expect_false(default$provenance$python_axes_return_equivalence)
    many<-z$participant
    many$participant_ids<-paste0("p",seq_len(13L))
    many$random_intercept_functions<-matrix(seq_len(39L)/100,
      nrow=13L)
    nolegend<-etr_plot_functional_random_effects(many,
      strict_source_record=TRUE)
    expect_false(nolegend$axes[[1L]]$legend)
    expect_length(nolegend$axes[[1L]]$legend_labels,0L)
    expect_length(nolegend$axes[[1L]]$artists,14L)
    expect_error(etr_plot_functional_random_effects(z$participant,
      max_participants=1,strict_source_record=TRUE),
      "Python-style integer")
    expect_error(etr_plot_functional_random_effects(z$participant,
      strict_source_record=1L),"strict_source_record")
  })
})

test_that("trial source artists retain first-seen trial IDs and physical curves",{
  z<-.etr_three_mixed_conformal_source_fixture()
  .etr_three_mixed_conformal_pdf({
    a<-etr_plot_functional_trial_random_effects(z$trial,
      strict_source_record=TRUE)
    ax<-a$axes[[1L]]
    expect_identical(a$source_export,
      "plot_functional_trial_random_effects")
    expect_identical(ax$title,"Trial-level functional random effects")
    expect_identical(ax$xlabel,"Time (s)")
    expect_identical(ax$ylabel,"Trial functional random intercept")
    expect_identical(ax$legend_labels,
      c("p1/trial2","p2/trial1"))
    expect_length(ax$artists,3L)
    expect_equal(ax$artists[[1L]]$ydata,c(.2,.6,1))
    expect_equal(ax$artists[[2L]]$ydata,c(.4,.8,1.2))
    expect_identical(ax$artists[[3L]]$linestyle,"-")
    expect_identical(ax$artists[[3L]]$linewidth,1.0)
    one<-etr_plot_functional_trial_random_effects(z$trial,
      participant_id="p1",max_trials=1L,
      strict_source_record=TRUE)
    expect_identical(one$axes[[1L]]$title,
      "Trial-level functional random effects: p1")
    expect_identical(one$axes[[1L]]$legend_labels,"p1/trial2")
    expect_equal(one$axes[[1L]]$artists[[1L]]$xdata,c(0,.5,1))
    default<-etr_plot_functional_trial_random_effects(z$trial)
    expect_identical(default$trial_ids,c("p1/trial2","p2/trial1"))
    expect_error(etr_plot_functional_trial_random_effects(z$trial,
      max_trials=1,strict_source_record=TRUE),"Python-style integer")
    expect_error(etr_plot_functional_trial_random_effects(z$trial,
      max_trials=0L,strict_source_record=TRUE),"max_trials")
    expect_error(etr_plot_functional_trial_random_effects(z$trial,
      participant_id="absent",strict_source_record=TRUE),
      "Unknown participant_id")
  })
})

test_that("conformal source p-values are used directly and never silently reconstructed",{
  z<-.etr_three_mixed_conformal_source_fixture()
  .etr_three_mixed_conformal_pdf({
    r<-etr_plot_conformal_fpca_anomaly(z$conformal,
      strict_source_record=TRUE)
    expect_s3_class(r,"etr_nonlinear_scientific_artist_record")
    expect_identical(r$source_export,"plot_conformal_fpca_anomaly")
    expect_false(r$matplotlib_object_identity)
    expect_false(r$independently_certified)
    expect_true(r$source_options$source_pvalues_direct)
    expect_true(r$source_options$no_reconstructed_calibration_scores)
    ax<-r$axes[[1L]]
    expect_identical(ax$title,"Split-conformal FPCA anomaly review")
    expect_identical(ax$xlabel,"Target trajectory")
    expect_identical(ax$ylabel,"Marginal conformal p-value")
    expect_equal(ax$ylim,c(0,1))
    expect_equal(ax$xticks,c(0,1,2))
    expect_identical(ax$xticklabels,c("t1","t2","t3"))
    expect_identical(ax$tick_rotation,90)
    expect_identical(ax$legend_labels,"alpha=0.2")
    expect_length(ax$artists,2L)
    expect_identical(ax$artists[[1L]]$kind,"scatter")
    expect_equal(ax$artists[[1L]]$offsets,
      unname(cbind(c(0,1,2),c(.8,.4,.2))),tolerance=0)
    expect_equal(ax$artists[[2L]]$ydata,c(.2,.2))
    expect_identical(ax$artists[[2L]]$linestyle,"--")
    only<-etr_plot_conformal_fpca_anomaly(z$conformal,
      max_targets=1L,strict_source_record=TRUE)
    expect_identical(only$axes[[1L]]$xticklabels,"t1")
    expect_equal(nrow(only$axes[[1L]]$artists[[1L]]$offsets),1)
    # Existing conservative score-calibration path still returns numeric p-values.
    legacy<-etr_plot_conformal_fpca_anomaly(z$legacy)
    expect_equal(legacy$p_value,c(.8,.4,.2))
    bad<-z$conformal
    bad$p_values[1L]<-.99
    expect_error(etr_plot_conformal_fpca_anomaly(bad,
      strict_source_record=TRUE),"p-values/IDs/alpha")
    bad<-z$conformal
    bad$review_flags[1L]<-TRUE
    expect_error(etr_plot_conformal_fpca_anomaly(bad,
      strict_source_record=TRUE),"review_flags")
    bad<-z$conformal
    bad$p_values<-NULL
    expect_error(etr_plot_conformal_fpca_anomaly(bad,
      strict_source_record=TRUE),"requires original")
    expect_error(etr_plot_conformal_fpca_anomaly(z$conformal,
      max_targets=1,strict_source_record=TRUE),
      "positive integer")
    expect_error(etr_plot_conformal_fpca_anomaly(z$conformal,
      strict_source_record="true"),"strict_source_record")
  })
})

test_that("frozen Python 1.2 public mixed BLUP and conformal Matplotlib artists compare",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 Matplotlib direct scientific oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_three_mixed_conformal_source_fixture()
  .etr_three_mixed_conformal_pdf({
    native<-list(
      etr_plot_functional_random_effects(z$participant,
        strict_source_record=TRUE),
      etr_plot_functional_random_effects(z$participant,effect="slope",
        max_participants=1L,alpha=.5,strict_source_record=TRUE),
      etr_plot_functional_trial_random_effects(z$trial,
        strict_source_record=TRUE),
      etr_plot_functional_trial_random_effects(z$trial,
        participant_id="p1",max_trials=1L,
        strict_source_record=TRUE),
      etr_plot_conformal_fpca_anomaly(z$conformal,
        strict_source_record=TRUE))
    reticulate::py_run_string("
import numpy as np
import matplotlib
matplotlib.use('Agg',force=True)
import matplotlib.pyplot as plt
import eyetrajectoriespy as et

def _mk(cls,**kw):
    obj=object.__new__(cls)
    for k,v in kw.items():object.__setattr__(obj,k,v)
    return obj

t=np.array([0.,.5,1.])
participants=_mk(et.FunctionalMixedEffectsResult,
    participant_ids=('p2','p1'),
    time=t,time_unit='s',dimension_name='y',
    random_intercept_functions=np.arange(1.,7.).reshape((2,3),order='F')/10.,
    random_slope_functions=np.arange(11.,17.).reshape((2,3),order='F')/10.,
    random_slope_predictor='cue')
trials=_mk(et.FunctionalMixedEffectsResult,
    source_curve_ids=('c2','c1'),
    curve_participant_ids=('p1','p2'),
    curve_trial_ids=('trial2','trial1'),
    trial_ids=('p1/trial2','p2/trial1'),
    time=t,time_unit='s',trial_random_effect='functional_intercept',
    trial_random_effect_functions=np.arange(1.,7.).reshape((2,3),order='F')/5.)
conformal=_mk(et.ConformalFunctionalAnomalyResult,
    target_curve_ids=('t1','t2','t3'),
    p_values=np.array([.8,.4,.2]),alpha=.2)
axes=[
    et.plot_functional_random_effects(participants),
    et.plot_functional_random_effects(participants,effect='slope',
      max_participants=1,alpha=.5),
    et.plot_functional_trial_random_effects(trials),
    et.plot_functional_trial_random_effects(trials,
      participant_id='p1',max_trials=1),
    et.plot_conformal_fpca_anomaly(conformal)]
def _line(line):
    return {'x':np.asarray(line.get_xdata(),dtype=float),
      'y':np.asarray(line.get_ydata(),dtype=float),
      'alpha':line.get_alpha(),
      'linestyle':line.get_linestyle(),
      'linewidth':line.get_linewidth()}
def _axis(ax):
    return {'title':ax.get_title(),'xlabel':ax.get_xlabel(),
      'ylabel':ax.get_ylabel(),
      'lines':[_line(l) for l in ax.lines],
      'legend':[] if ax.get_legend() is None else
        [t.get_text() for t in ax.get_legend().get_texts()]}
oracle=[_axis(ax) for ax in axes]
oracle[4]['offsets']=np.asarray(
    axes[4].collections[0].get_offsets(),dtype=float)
oracle[4]['labels']=[s.get_text() for s in axes[4].get_xticklabels()]
oracle[4]['rotation']=[s.get_rotation() for s in axes[4].get_xticklabels()]
oracle[4]['ylim']=axes[4].get_ylim()
plt.close('all')
")
    py<-et_to_r(reticulate::py_get_attr(reticulate::py,"oracle"))
    expect_length(py,5L)
    for(i in seq_along(py)) {
      a<-native[[i]]$axes[[1L]]
      for(n in c("title","xlabel","ylabel"))
        expect_identical(a[[n]],py[[i]][[n]],
          info=paste("axis",i,n))
      expect_identical(a$legend_labels,as.character(py[[i]]$legend))
      lines<-Filter(function(x)x$kind%in%c("line","horizontal_reference"),
        a$artists)
      expect_length(lines,length(py[[i]]$lines))
      for(j in seq_along(lines)){
        expect_equal(lines[[j]]$xdata,
          as.numeric(py[[i]]$lines[[j]]$x),tolerance=0)
        expect_equal(lines[[j]]$ydata,
          as.numeric(py[[i]]$lines[[j]]$y),tolerance=1e-12)
        expect_identical(lines[[j]]$linestyle,
          py[[i]]$lines[[j]]$linestyle)
        if(!is.null(lines[[j]]$alpha))
          expect_equal(lines[[j]]$alpha,
            py[[i]]$lines[[j]]$alpha,tolerance=0)
      }
    }
    expect_equal(native[[5L]]$axes[[1L]]$artists[[1L]]$offsets,
      as.matrix(py[[5L]]$offsets),tolerance=0,ignore_attr=TRUE)
    expect_equal(native[[5L]]$axes[[1L]]$ylim,
      as.numeric(py[[5L]]$ylim),tolerance=0)
    expect_identical(native[[5L]]$axes[[1L]]$xticklabels,
      as.character(py[[5L]]$labels))
    expect_equal(rep(native[[5L]]$axes[[1L]]$tick_rotation,3L),
      as.numeric(py[[5L]]$rotation),tolerance=0)
  })
})
