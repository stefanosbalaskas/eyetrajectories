# Frozen Python 1.2.0: recovery.py::evaluate_functional_mixed_effects_recovery
.etr_mixed_truth_fixture <- function(trial=FALSE) {
  t<-c(0,.5,1)
  modes<-array(1,c(1L,3L,1L))
  truth<-list(truth_grid=t,dimension_names="x",
    mean=matrix(c(.2,.3,.4),ncol=1),
    eigenfunctions=modes,participant_eigenvalues=2,
    trial_eigenvalues=if(trial).5 else 0)
  fit<-list(time=t,dimension_name="x",
    coefficient_names="Intercept",
    coefficient_functions=matrix(c(.1,.4,.45),nrow=1),
    random_slope_predictor=NULL,
    random_basis=matrix(1,3,1),
    random_intercept_covariance=matrix(2,1,1),
    trial_random_effect=if(trial)"functional_intercept" else NULL)
  if(trial){
    fit$trial_random_basis<-matrix(1,3,1)
    fit$trial_random_effect_covariance<-matrix(.75,1,1)
  }
  list(fit=fit,truth=truth)
}

test_that("mixed source recovery compares intercept and time-domain variances",{
  z<-.etr_mixed_truth_fixture()
  a<-etr_evaluate_functional_mixed_effects_recovery(z$fit,z$truth)
  expect_identical(length(a$values),4L)
  expect_identical(vapply(a$values,function(x)x$metric$name,character(1L)),
    c("coefficient_function_ise","source_variance_function_ise",
      "source_integrated_variance_absolute_error",
      "source_integrated_variance_relative_error"))
  expect_equal(vapply(a$values,function(x)x$value,numeric(1L)),
    c(.01*.25+.01*.5+.0025*.25,0,0,0),tolerance=1e-12)
  expect_identical(vapply(a$values,function(x)x$source,character(1L)),
    c("intercept","participant","participant","participant"))
  expect_false(a$provenance$basis_covariance_compared_directly_to_kl_eigenvalues)
  expect_false(a$provenance$curve_level_kl_variance_scored_as_scalar_residual)
})

test_that("nested trial variance uses its own functional covariance, not scalar residual",{
  z<-.etr_mixed_truth_fixture(TRUE)
  a<-etr_evaluate_functional_mixed_effects_recovery(z$fit,z$truth)
  expect_identical(length(a$values),7L)
  expect_equal(vapply(a$values,function(x)x$value,numeric(1L))[5:7],
    c(.25^2,.25,.5),tolerance=1e-12)
  expect_identical(vapply(a$values,function(x)x$source,character(1L))[5:7],
    rep("trial",3L))
  z$fit$trial_random_effect<-NULL
  expect_error(etr_evaluate_functional_mixed_effects_recovery(z$fit,z$truth),
    "truth contains trial functional variance")
  z$truth$trial_eigenvalues[]<-0
  no_trial<-etr_evaluate_functional_mixed_effects_recovery(z$fit,z$truth)
  expect_identical(length(no_trial$values),4L)
  expect_identical(no_trial$provenance$trial_variance_target,
    "time_domain_variance_function")
})

test_that("multidimensional truth contracts keep source variance in the selected channel",{
  grid<-c(0,.5,1)
  modes<-array(0,c(2L,3L,2L))
  modes[1L,,]<-1
  modes[2L,,1L]<-grid
  modes[2L,,2L]<- -grid
  truth<-list(truth_grid=grid,dimension_names=c("x","y"),
    mean=cbind(c(.2,.3,.4),c(.5,.6,.7)),
    eigenfunctions=modes,
    participant_eigenvalues=c(.4,.2),
    trial_eigenvalues=c(0,0))
  fit<-list(time=grid,dimension_name="y",
    coefficient_names="Intercept",
    coefficient_functions=matrix(c(.55,.65,.75),nrow=1L),
    random_slope_predictor=NULL,
    random_basis=cbind(rep(1,3L),grid),
    random_intercept_covariance=diag(c(.4,.2)),
    trial_random_effect=NULL)
  a<-etr_evaluate_functional_mixed_effects_recovery(fit,truth)
  expect_identical(length(a$values),4L)
  expect_equal(vapply(a$values,function(v)v$value,numeric(1L)),
    c(.0025,0,0,0),tolerance=1e-12)
  expect_identical(a$provenance$dimension,"y")
  truth$participant_eigenvalues<-c(.2,.4)
  b<-etr_evaluate_functional_mixed_effects_recovery(fit,truth)
  expect_true(b$values[[2L]]$value>0)
  expect_true(b$values[[3L]]$value>0)
})

test_that("mixed source recovery rejects silent truth interpolation and unsupported slopes",{
  z<-.etr_mixed_truth_fixture()
  z$fit$random_slope_predictor<-"dose"
  expect_error(etr_evaluate_functional_mixed_effects_recovery(z$fit,z$truth),
    "random intercepts only")
  z<-.etr_mixed_truth_fixture()
  z$fit$time[2]<-.4
  expect_error(etr_evaluate_functional_mixed_effects_recovery(z$fit,z$truth),
    "exactly")
  z<-.etr_mixed_truth_fixture()
  z$truth$dimension_names<-"y"
  expect_error(etr_evaluate_functional_mixed_effects_recovery(z$fit,z$truth),
    "absent")
})

test_that("published Python 1.2 mixed known-truth oracle matches both regimes",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python mixed-effects known-truth recovery oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
from eyetrajectoriespy._functional_simulation import FunctionalSimulationTruth
def _mrec_obj(cls,**kw):
    z=object.__new__(cls)
    for k,v in kw.items(): object.__setattr__(z,k,v)
    return z
_mrec_py={}
for trial in (False,True):
    truth=_mrec_obj(FunctionalSimulationTruth,
        truth_grid=np.array([0.,.5,1.]),
        dimension_names=('x',),
        mean=np.array([[.2],[.3],[.4]]),
        eigenfunctions=np.ones((1,3,1)),
        participant_eigenvalues=np.array([2.]),
        trial_eigenvalues=np.array([.5 if trial else 0.]))
    args=dict(time=truth.truth_grid,dimension_name='x',
        coefficient_names=('Intercept',),
        coefficient_functions=np.array([[.1,.4,.45]]),
        random_slope_predictor=None,
        random_basis=np.ones((3,1)),
        random_intercept_covariance=np.array([[2.]]),
        trial_random_effect='functional_intercept' if trial else None)
    if trial:
        args['trial_random_basis']=np.ones((3,1))
        args['trial_random_effect_covariance']=np.array([[.75]])
    fit=_mrec_obj(et.FunctionalMixedEffectsResult,**args)
    result=et.evaluate_functional_mixed_effects_recovery(fit,truth)
    _mrec_py[trial]=dict(
      names=[v.metric.name for v in result.values],
      source=[v.source for v in result.values],
      value=[float(v.value) for v in result.values],
      provenance=dict(result.provenance))
")
  for(trial in c(FALSE,TRUE)){
    z<-.etr_mixed_truth_fixture(trial)
    x<-etr_evaluate_functional_mixed_effects_recovery(z$fit,z$truth)
    py<-if(trial)"_mrec_py[True]" else "_mrec_py[False]"
    actual_names<-vapply(x$values,function(v)v$metric$name,character(1L))
    actual_source<-vapply(x$values,function(v)v$source,character(1L))
    actual_values<-vapply(x$values,function(v)v$value,numeric(1L))
    expect_identical(actual_names,as.character(reticulate::py_eval(
      paste0(py,"['names']"),convert=TRUE)))
    expect_identical(actual_source,as.character(reticulate::py_eval(
      paste0(py,"['source']"),convert=TRUE)))
    expect_equal(actual_values,as.numeric(reticulate::py_eval(
      paste0(py,"['value']"),convert=TRUE)),tolerance=1e-12)
    expect_identical(x$provenance,reticulate::py_eval(
      paste0(py,"['provenance']"),convert=TRUE))
  }
})
