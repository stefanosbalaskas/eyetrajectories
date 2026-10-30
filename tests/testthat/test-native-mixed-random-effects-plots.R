# Native plot line provenance against Python 1.2 published plotting source.
.etr_random_visual_test_records <- function(){
  time<-c(0,.5,1)
  participant<-list(participant_ids=c("p2","p1"),time=time,
    time_unit="s",dimension_name="y",
    random_intercept_functions=matrix(1:6/10,nrow=2L),
    random_slope_functions=matrix(11:16/10,nrow=2L),
    random_slope_predictor="cue")
  trial<-list(source_curve_ids=c("c2","c1"),
    curve_participant_ids=c("p1","p2"),
    curve_trial_ids=c("trial2","trial1"),
    trial_ids=c("p1/trial2","p2/trial1"),
    time=time,time_unit="s",trial_random_effect="functional_intercept",
    trial_random_effect_functions=matrix(1:6/5,nrow=2L))
  list(participant=participant,trial=trial)
}

test_that("participant and trial graphics expose source ordered R geometries",{
  x<-.etr_random_visual_test_records()
  grDevices::pdf(file=tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  p<-etr_plot_functional_random_effects(x$participant,max_participants=1L)
  expect_identical(p$n_plotted,1L)
  expect_identical(p$participant_ids,"p2")
  expect_equal(p$lines$estimate,c(.1,.3,.5))
  expect_false(p$provenance$python_axes_return_equivalence)
  ps<-etr_plot_functional_random_effects(x$participant,effect="slope",
    max_participants=NULL,alpha=.5)
  expect_identical(ps$n_plotted,2L)
  expect_equal(ps$lines$estimate,c(1.1,1.3,1.5,1.2,1.4,1.6))
  expect_error(etr_plot_functional_random_effects(
    x$participant,max_participants=0),"max_participants")
  expect_error(etr_plot_functional_random_effects(
    x$participant,alpha=1.1),"alpha")
  t<-etr_plot_functional_trial_random_effects(x$trial)
  expect_identical(t$trial_ids,c("p1/trial2","p2/trial1"))
  expect_equal(t$lines$value,c(.2,.6,1,.4,.8,1.2))
  p1<-etr_plot_functional_trial_random_effects(x$trial,
    participant_id="p1",max_trials=1L)
  expect_identical(p1$trial_ids,"p1/trial2")
  expect_identical(p1$n_plotted,1L)
  expect_error(etr_plot_functional_trial_random_effects(x$trial,
    participant_id="absent"),"Unknown participant_id")
  expect_error(etr_plot_functional_trial_random_effects(x$trial,
    max_trials=0L),"max_trials")
})

test_that("mixed random graphics are not incorrectly fully certified",{
  z<-etr_native_parity_catalog()
  for(nm in c("plot_functional_random_effects",
              "plot_functional_trial_random_effects")){
    a<-z[z$is_python_function&z$python_name==nm,,drop=FALSE]
    expect_equal(nrow(a),1L)
    expect_identical(a$native_r_candidate,paste0("etr_",nm))
    expect_true(a$native_implementation_started)
    expect_true(a$source_contract_gap_unresolved)
    expect_false(a$one_to_one_native_contract_complete)
  }
  expect_equal(sum(z$is_python_function&z$named_native_candidate),321L)
  expect_equal(sum(z$native_implementation_started),296L)
  expect_equal(sum(z$source_contract_gap_unresolved),143L)
})

test_that("Python 1.2 participant and trial axes line values equal native",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Python 1.2 random-effect Matplotlib line oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
def _r_visual_record(cls, **fields):
    obj = object.__new__(cls)
    for name,value in fields.items():
        object.__setattr__(obj,name,value)
    return obj
_v_part=_r_visual_record(et.FunctionalMixedEffectsResult,
    participant_ids=('p2','p1'),time=np.array([0.,.5,1.]),
    time_unit='s',dimension_name='y',
    random_intercept_functions=np.arange(1.,7.).reshape((2,3),order='F')/10.,
    random_slope_functions=np.arange(11.,17.).reshape((2,3),order='F')/10.,
    random_slope_predictor='cue')
_v_trial=_r_visual_record(et.FunctionalMixedEffectsResult,
    source_curve_ids=('c2','c1'),curve_participant_ids=('p1','p2'),
    curve_trial_ids=('trial2','trial1'),trial_ids=('p1/trial2','p2/trial1'),
    time=np.array([0.,.5,1.]),time_unit='s',
    trial_random_effect='functional_intercept',
    trial_random_effect_functions=np.arange(1.,7.).reshape((2,3),order='F')/5.)
_v_axes=[
    et.plot_functional_random_effects(_v_part,effect='intercept',
                                      max_participants=1),
    et.plot_functional_random_effects(_v_part,effect='slope'),
    et.plot_functional_trial_random_effects(_v_trial),
    et.plot_functional_trial_random_effects(_v_trial,
                                            participant_id='p1',max_trials=1)]
_v_lines=[
 [(np.asarray(line.get_xdata(),dtype=float),
   np.asarray(line.get_ydata(),dtype=float))
  for line in ax.lines] for ax in _v_axes]
for ax in _v_axes:
    plt.close(ax.figure)
",convert=FALSE)
  x<-.etr_random_visual_test_records()
  grDevices::pdf(file=tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  native<-list(
    etr_plot_functional_random_effects(x$participant,max_participants=1L),
    etr_plot_functional_random_effects(x$participant,effect="slope"),
    etr_plot_functional_trial_random_effects(x$trial),
    etr_plot_functional_trial_random_effects(x$trial,
      participant_id="p1",max_trials=1L))
  source<-reticulate::py_to_r(
    reticulate::py_get_attr(reticulate::py,"_v_lines"))
  for(i in seq_along(native)){
    expected<-native[[i]]$lines
    keep<-length(unique(if(i<=2L)expected$participant_id else
      expected$trial_id))
    expect_equal(length(source[[i]]),keep+1L,info=paste("axis",i))
    idcol<-if(i<=2L)"participant_id" else "trial_id"
    valcol<-if(i<=2L)"estimate" else "value"
    ids<-unique(expected[[idcol]])
    for(j in seq_along(ids)){
      a<-expected[expected[[idcol]]==ids[j],,drop=FALSE]
      expect_equal(as.numeric(source[[i]][[j]][[1L]]),a$time,
        tolerance=1e-12,info=paste("time",i,j))
      expect_equal(as.numeric(source[[i]][[j]][[2L]]),a[[valcol]],
        tolerance=1e-12,info=paste("value",i,j))
    }
  }
})
