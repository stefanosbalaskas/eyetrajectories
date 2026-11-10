.etr_sparse_truth_fixture<-function(diagnostics=TRUE){
  grid<-c(0,.5,1)
  mean<-matrix(c(.1,.2,.3),ncol=1L)
  scores<-matrix(c(-2,-1,1,2),ncol=1L)
  latent<-array(0,c(4L,3L,1L))
  for(i in seq_len(4L))latent[i,,1L]<-mean[,1L]+scores[i,1L]
  truth<-list(truth_grid=grid,dimension_names="x",mean=mean,
    eigenfunctions=array(1,c(1L,3L,1L)),eigenvalues=.5,
    scores=scores,latent_on_truth_grid=latent,
    measurement_noise_covariance=matrix(.1,1,1))
  fit<-list(evaluation_grid=grid,dimension="x",
    mean=c(.1,.3,.3),covariance=matrix(.6,3,3),
    eigenfunctions=matrix(-1,nrow=1L,ncol=3L),eigenvalues=.5,
    scores=-scores,quadrature_weights=NULL,
    noise_variance=.15,
    score_diagnostics=if(diagnostics)data.frame(
      status_code=c("ok","bad","ok","ok"),
      condition_number=c(1,2,3,4)) else data.frame(),
    covariance_diagnostics=list(applied_action="project",
      relative_operator_correction_frobenius_norm=.02),
    provenance=list(sparse_fpca=list(
      noise_variance_method="difference_diagonal",
      measurement_error_variance_supplied=FALSE)))
  list(fit=fit,truth=truth)
}
test_that("sparse known truth uses estimated covariance not mode reconstruction",{
  z<-.etr_sparse_truth_fixture()
  a<-etr_evaluate_sparse_fpca_recovery(z$fit,z$truth)
  values<-vapply(a$values,function(v)v$value,numeric(1L))
  names<-vapply(a$values,function(v)v$metric$name,character(1L))
  expect_identical(length(values),17L)
  expect_identical(names,c(
    "mean_ise","covariance_ise","eigenvalue_relative_error",
    "component_absolute_similarity","score_correlation","score_rmse",
    "subspace_principal_cosine","subspace_principal_angle_degrees",
    "reconstruction_ise","score_failure_rate",
    "score_condition_number_median","score_condition_number_q95",
    "score_condition_number_max","psd_repair_applied",
    "psd_relative_operator_correction",
    "noise_variance_absolute_error","noise_variance_relative_error"))
  expect_equal(values,c(.005,.01,0,1,1,0,1,0,.005,
    .25,2.5,3.85,4,1,.02,.05,.5),tolerance=1e-12)
  expect_identical(a$provenance$dimension,"x")
  expect_identical(a$provenance$noise_variance_method,"difference_diagonal")
  expect_false(a$provenance$measurement_error_variance_supplied)
  expect_equal(a$provenance$alignment_signs,-1)
})
test_that("sparse source metrics omit diagnostics and relative zero-truth-noise",{
  z<-.etr_sparse_truth_fixture(FALSE)
  z$truth$measurement_noise_covariance[1,1]<-0
  a<-etr_evaluate_sparse_fpca_recovery(z$fit,z$truth)
  names<-vapply(a$values,function(v)v$metric$name,character(1L))
  expect_identical(sum(names=="score_failure_rate"),1L)
  expect_true(!"score_condition_number_q95"%in%names)
  expect_true("noise_variance_absolute_error"%in%names)
  expect_true(!"noise_variance_relative_error"%in%names)
  bad<-z$fit;bad$evaluation_grid[2]<-.4
  expect_error(etr_evaluate_sparse_fpca_recovery(bad,z$truth),"exact truth")
  bad<-z$fit;bad$eigenfunctions<-matrix(1,2,3)
  expect_error(etr_evaluate_sparse_fpca_recovery(bad,z$truth),
    "truth contains fewer components")
})
test_that("frozen Python 1.2 sparse known-truth score/covariance oracle matches",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published sparse FPCA recovery Python 1.2 source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
from dataclasses import fields
import eyetrajectoriespy as et
from eyetrajectoriespy._functional_simulation import FunctionalSimulationTruth
grid=np.array([0.,.5,1.])
scores=np.array([[-2.],[-1.],[1.],[2.]])
mean=np.array([[.1],[.2],[.3]])
latent=mean[None,:,:]+scores[:,:,None]
truth_data={x.name:None for x in fields(FunctionalSimulationTruth)}
truth_data.update(truth_grid=grid,dimension_names=('x',),
    mean=mean,eigenfunctions=np.ones((1,3,1)),
    eigenvalues=np.array([.5]),scores=scores,
    latent_on_truth_grid=latent,
    measurement_noise_covariance=np.array([[.1]]))
truth=FunctionalSimulationTruth(**truth_data)
def _sp_obj(cls,**kw):
    obj=object.__new__(cls)
    for k,v in kw.items():object.__setattr__(obj,k,v)
    return obj
fit=_sp_obj(et.SparseFPCAResult,
    evaluation_grid=grid,dimension='x',
    mean=np.array([.1,.3,.3]),
    covariance=np.full((3,3),.6),
    eigenfunctions=-np.ones((1,3)),
    eigenvalues=np.array([.5]),scores=-scores,
    quadrature_weights=None,noise_variance=.15,
    score_diagnostics=pd.DataFrame(
      {'status_code':['ok','bad','ok','ok'],
       'condition_number':[1.,2.,3.,4.]}),
    covariance_diagnostics={
      'applied_action':'project',
      'relative_operator_correction_frobenius_norm':.02},
    provenance={'sparse_fpca':{
      'noise_variance_method':'difference_diagonal',
      'measurement_error_variance_supplied':False}})
_sp_source=et.evaluate_sparse_fpca_recovery(fit,truth)
_sp_source_names=[v.metric.name for v in _sp_source.values]
_sp_source_values=[float(v.value) for v in _sp_source.values]
_sp_source_metadata=[
    (v.metric.name,v.metric.quantity,v.metric.direction,
     v.metric.units,v.metric.scope,v.metric.description)
    for v in _sp_source.values]
_sp_source_provenance=dict(_sp_source.provenance)
")
  direct<-reticulate::py_call(
    etpy_get_export("evaluate_sparse_fpca_recovery"),
    result=reticulate::py_eval("fit",convert=FALSE),
    truth=reticulate::py_eval("truth",convert=FALSE))
  values_from<-reticulate::py_eval(
    "lambda assessment: [float(v.value) for v in assessment.values]",
    convert=FALSE)
  direct_values<-as.numeric(et_to_r(
    reticulate::py_call(values_from,direct)))
  source_values<-as.numeric(
    reticulate::py_eval("_sp_source_values",convert=TRUE))
  expect_equal(direct_values,source_values,tolerance=1e-12)
  z<-.etr_sparse_truth_fixture()
  a<-etr_evaluate_sparse_fpca_recovery(z$fit,z$truth)
  expect_identical(vapply(a$values,function(v)v$metric$name,character(1L)),
    as.character(reticulate::py_eval("_sp_source_names",convert=TRUE)))
  # Principal-angle degrees at an exactly matched subspace are
  # ill-conditioned at cosine 1. Check all other scientific values at
  # machine precision, then use a sqrt(epsilon) angular bound.
  actual_values<-vapply(a$values,function(v)v$value,numeric(1L))
  python_values<-as.numeric(
    reticulate::py_eval("_sp_source_values",convert=TRUE))
  angle_pos<-which(vapply(a$values,function(v)
    v$metric$name=="subspace_principal_angle_degrees",logical(1L)))
  expect_identical(length(angle_pos),1L)
  expect_equal(actual_values[-angle_pos],python_values[-angle_pos],
    tolerance=1e-12)
  expect_lte(abs(actual_values[angle_pos]-python_values[angle_pos]),
    2*(180/pi)*sqrt(2*.Machine$double.eps))
  metric_fields<-reticulate::py_eval("_sp_source_metadata",convert=TRUE)
  for(i in seq_along(a$values))
    expect_identical(unname(unlist(a$values[[i]]$metric,use.names=FALSE)),
      as.character(unlist(metric_fields[[i]],use.names=FALSE)),
      info=paste("sparse recovery metric",i))
  expect_identical(a$provenance$estimator,
    reticulate::py_eval("_sp_source_provenance['estimator']",convert=TRUE))
  expect_equal(a$provenance$alignment_signs,
    as.numeric(reticulate::py_eval(
      "_sp_source_provenance['alignment_signs']",convert=TRUE)))
})
