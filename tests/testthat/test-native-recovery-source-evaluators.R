# Direct-source oracle, published Python 1.2.0, never full domain certified.
.etr_truth_audit_fixture <- function() {
  grid<-c(0,.5,1)
  list(
    curve_scores=matrix(c(1,2,3,4),2,2,byrow=TRUE),
    eigenvalues=c(1,2),
    participant_scores=matrix(c(0,4),2,1),
    participant_eigenvalues=2,
    trial_scores=matrix(c(-1,1),2,1),
    trial_eigenvalues=0,
    truth_grid=grid,
    phase_warps_on_truth_grid=rbind(c(0,.25,1),c(0,.75,1)))
}
test_that("hierarchy truth audit uses population variance and source order",{
  truth<-.etr_truth_audit_fixture()
  a<-etr_evaluate_hierarchy_truth_recovery(truth)
  expect_identical(length(a$values),7L)
  names<-vapply(a$values,function(v)v$metric$name,character(1L))
  expect_identical(names[1:4],rep(c("source_variance_absolute_error",
    "source_variance_relative_error"),2L))
  expect_equal(vapply(a$values,function(v)v$value,numeric(1L)),
    c(0,0,1,.5,2,1,1),tolerance=1e-12)
  expect_identical(vapply(a$values,function(v)v$source,character(1L)),
    c(rep("curve",4L),rep("participant",2L),"trial"))
  expect_identical(a$provenance$ddof,0L)
  bad<-truth;bad$curve_scores[1,1]<-NA_real_
  expect_error(etr_evaluate_hierarchy_truth_recovery(bad),"finite")
})
test_that("inverse simulator warps are evaluated without interpolation of fitted grid",{
  truth<-.etr_truth_audit_fixture()
  fit<-list(original=list(time=truth$truth_grid),
    warping_functions=rbind(c(0,2/3,1),c(0,1/3,1)))
  a<-etr_evaluate_registration_recovery(fit,truth)
  expect_equal(vapply(a$values,function(v)v$value,numeric(1L)),
    c(0,0),tolerance=1e-12)
  fit$warping_functions[1,2]<-fit$warping_functions[1,2]+.1
  changed<-etr_evaluate_registration_recovery(fit,truth)
  expect_equal(changed$values[[1L]]$value,.005,tolerance=1e-12)
  expect_equal(changed$values[[2L]]$value,.1,tolerance=1e-12)
  expect_identical(changed$provenance$truth_target,"inverse_phase_warp")
  fit$original$time<-c(0,.4,1)
  expect_error(etr_evaluate_registration_recovery(fit,truth),
    "equal truth.truth_grid exactly")
})
test_that("frozen Python 1.2 known-truth recovery quantities match native",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published Python 1.2 recovery source oracles are opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
from eyetrajectoriespy._functional_simulation import FunctionalSimulationTruth
from types import SimpleNamespace
def _recovery_obj(cls,**kw):
    obj=object.__new__(cls)
    for k,v in kw.items(): object.__setattr__(obj,k,v)
    return obj
_rec_grid=np.array([0.,.5,1.])
_rec_truth=_recovery_obj(FunctionalSimulationTruth,
    truth_grid=_rec_grid,
    curve_scores=np.array([[1.,2.],[3.,4.]]),
    eigenvalues=np.array([1.,2.]),
    participant_scores=np.array([[0.],[4.]]),
    participant_eigenvalues=np.array([2.]),
    trial_scores=np.array([[-1.],[1.]]),
    trial_eigenvalues=np.array([0.]),
    phase_warps_on_truth_grid=np.array([[0.,.25,1.],[0.,.75,1.]]))
_rec_reg=_recovery_obj(et.RegistrationResult,
    original=SimpleNamespace(time=_rec_grid),
    warping_functions=np.array([[0.,2./3.,1.],[0.,1./3.,1.]]))
_rec_h=et.evaluate_hierarchy_truth_recovery(_rec_truth)
_rec_r=et.evaluate_registration_recovery(_rec_reg,_rec_truth)
_rec_names_h=[v.metric.name for v in _rec_h.values]
_rec_values_h=[float(v.value) for v in _rec_h.values]
_rec_names_r=[v.metric.name for v in _rec_r.values]
_rec_values_r=[float(v.value) for v in _rec_r.values]
")
  truth<-.etr_truth_audit_fixture()
  fit<-list(original=list(time=truth$truth_grid),
    warping_functions=rbind(c(0,2/3,1),c(0,1/3,1)))
  for(pair in list(list(name="h",result=etr_evaluate_hierarchy_truth_recovery(truth)),
    list(name="r",result=etr_evaluate_registration_recovery(fit,truth)))){
    actual<-pair$result$values
    names<-vapply(actual,function(v)v$metric$name,character(1L))
    values<-vapply(actual,function(v)v$value,numeric(1L))
    expect_identical(names,unlist(reticulate::py_eval(
      paste0("_rec_names_",pair$name),convert=TRUE),
      use.names=FALSE))
    expect_equal(values,as.numeric(unlist(reticulate::py_eval(
      paste0("_rec_values_",pair$name),convert=TRUE),
      use.names=FALSE)),tolerance=1e-12)
  }
})
