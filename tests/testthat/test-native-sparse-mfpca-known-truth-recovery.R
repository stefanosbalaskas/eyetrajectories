# Frozen Python 1.2.0 recovery.py::evaluate_sparse_mfpca_recovery
.etr_sparse_mfpca_truth_fixture<-function(){
  t<-c(0,.5,1);weights<-c(.25,.5,.25)
  mean<-cbind(c(.1,.2,.3),c(.4,.5,.6))
  phi<-array(rep(1/sqrt(2),6L),c(1L,3L,2L))
  scores<-matrix(c(-2,-1,1,2),ncol=1L)
  latent<-array(0,c(4L,3L,2L))
  for(i in 1:4)latent[i,,]<-mean+scores[i,1L]*
    matrix(phi,nrow=3L,ncol=2L)
  truth<-list(truth_grid=t,dimension_names=c("x","y"),
    mean=mean,eigenfunctions=phi,eigenvalues=.5,scores=scores,
    latent_on_truth_grid=latent,
    measurement_noise_covariance=diag(c(.1,.2)))
  fit_mean<-mean;fit_mean[2L,2L]<-fit_mean[2L,2L]+.1
  result<-list(evaluation_grid=t,dimensions=c("x","y"),
    mean=fit_mean,eigenfunctions= -phi,eigenvalues=.5,
    scores= -scores,quadrature_weights=weights,
    covariance_cxx=matrix(.35,3,3),
    covariance_cxy=matrix(.30,3,3),
    covariance_cyx=matrix(.30,3,3),
    covariance_cyy=matrix(.20,3,3),
    measurement_error_covariance=diag(c(.1,.2)),
    score_diagnostics=data.frame(
      status_code=c("ok","bad","ok","ok"),
      condition_number=c(1,2,3,4)),
    covariance_diagnostics=list(applied_action="project",
      relative_operator_correction_frobenius_norm=.03),
    provenance=list(sparse_mfpca=list(measurement_error_mode="supplied")))
  list(result=result,truth=truth)
}
test_that("sparse bivariate source covariance blocks remain distinct and additive",{
  z<-.etr_sparse_mfpca_truth_fixture()
  a<-etr_evaluate_sparse_mfpca_recovery(z$result,z$truth)
  metrics<-vapply(a$values,function(x)x$metric$name,character(1L))
  expected<-c("mean_ise",rep("covariance_block_ise",4L),
    "covariance_ise","eigenvalue_relative_error",
    "component_absolute_similarity","score_correlation","score_rmse",
    "subspace_principal_cosine","subspace_principal_angle_degrees",
    "reconstruction_ise","score_failure_rate",
    "score_condition_number_median","score_condition_number_q95",
    "score_condition_number_max","psd_repair_applied",
    "psd_relative_operator_correction")
  expect_identical(metrics,expected)
  expect_identical(vapply(a$values[2:5],function(x)x$source,character(1L)),
    c("cxx","cxy","cyx","cyy"))
  values<-vapply(a$values,function(v)v$value,numeric(1L))
  expect_equal(values[c(1:6,7:13,14:19)],c(
    .005,.01,.0025,.0025,.0025,.0175,
    0,1,1,0,1,0,.005,.25,2.5,3.85,4,1,.03),tolerance=1e-12)
  expect_true(a$provenance$measurement_error_truth_supplied)
  expect_false(a$provenance$component_metrics_omitted_for_tied_eigenspaces)
  expect_false(a$provenance$measurement_error_recovery_metric_reported)
  expect_identical(a$provenance$matched_truth_components,0L)
})
test_that("sparse MFPCA source mode/domain checks fail closed",{
  z<-.etr_sparse_mfpca_truth_fixture()
  x<-z$result;x$quadrature_weights<-rep(1/3,3)
  expect_error(etr_evaluate_sparse_mfpca_recovery(x,z$truth),
    "declared functional quadrature weights")
  x<-z$result;x$covariance_cxy<-matrix(.5,4,4)
  expect_error(etr_evaluate_sparse_mfpca_recovery(x,z$truth),
    "planar covariance block")
  x<-z$result;x$dimensions<-c("y","x")
  expect_error(etr_evaluate_sparse_mfpca_recovery(x,z$truth),
    "source order")
  x<-z$result;x$eigenfunctions<-array(1,c(2,3,2))
  expect_error(etr_evaluate_sparse_mfpca_recovery(x,z$truth),
    "one fitted bivariate")
  x<-z$result;x$measurement_error_covariance[1,1]<-.11
  a<-etr_evaluate_sparse_mfpca_recovery(x,z$truth)
  expect_false(a$provenance$measurement_error_truth_supplied)
})
test_that("pinned Python 1.2 sparse MFPCA recovery source values match",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python sparse multivariate recovery oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as et
from eyetrajectoriespy._functional_simulation import FunctionalSimulationTruth
def _spm_obj(cls,**kwargs):
    o=object.__new__(cls)
    for k,v in kwargs.items():object.__setattr__(o,k,v)
    return o
_spm_grid=np.array([0.,.5,1.])
_spm_phi=np.full((1,3,2),1/np.sqrt(2))
_spm_scores=np.array([[-2.],[-1.],[1.],[2.]])
_spm_mean=np.array([[.1,.4],[.2,.5],[.3,.6]])
_spm_latent=_spm_mean[None,:,:]+_spm_scores[:,:,None]*_spm_phi[0][None,:,:]
_spm_truth=_spm_obj(FunctionalSimulationTruth,
    truth_grid=_spm_grid,dimension_names=('x','y'),
    mean=_spm_mean,eigenfunctions=_spm_phi,eigenvalues=np.array([.5]),
    scores=_spm_scores,latent_on_truth_grid=_spm_latent,
    measurement_noise_covariance=np.diag([.1,.2]))
_spm_fit_mean=_spm_mean.copy();_spm_fit_mean[1,1]+=.1
_spm_result=_spm_obj(et.SparseMFPCAResult,
    evaluation_grid=_spm_grid,dimensions=('x','y'),
    mean=_spm_fit_mean,eigenfunctions=-_spm_phi,
    eigenvalues=np.array([.5]),scores=-_spm_scores,
    quadrature_weights=np.array([.25,.5,.25]),
    covariance_cxx=np.full((3,3),.35),
    covariance_cxy=np.full((3,3),.3),
    covariance_cyx=np.full((3,3),.3),
    covariance_cyy=np.full((3,3),.2),
    measurement_error_covariance=np.diag([.1,.2]),
    score_diagnostics=pd.DataFrame(
      {'status_code':['ok','bad','ok','ok'],
       'condition_number':[1.,2.,3.,4.]}),
    covariance_diagnostics={'applied_action':'project',
      'relative_operator_correction_frobenius_norm':.03},
    provenance={'sparse_mfpca':{'measurement_error_mode':'supplied'}})
_spm_py=et.evaluate_sparse_mfpca_recovery(_spm_result,_spm_truth)
_spm_names=[v.metric.name for v in _spm_py.values]
_spm_values=[v.value for v in _spm_py.values]
_spm_sources=[v.source for v in _spm_py.values]
_spm_provenance=dict(_spm_py.provenance)
")
  direct<-reticulate::py_call(
    etpy_get_export("evaluate_sparse_mfpca_recovery"),
    result=reticulate::py_eval("_spm_result",convert=FALSE),
    truth=reticulate::py_eval("_spm_truth",convert=FALSE))
  metric_values<-reticulate::py_eval(
    "lambda assessment: [float(v.value) for v in assessment.values]",
    convert=FALSE)
  expect_equal(as.numeric(et_to_r(reticulate::py_call(
    metric_values,direct))),as.numeric(reticulate::py_eval(
      "_spm_values",convert=TRUE)),tolerance=1e-12)
  z<-.etr_sparse_mfpca_truth_fixture()
  result<-etr_evaluate_sparse_mfpca_recovery(z$result,z$truth)
  expect_identical(vapply(result$values,function(v)v$metric$name,character(1L)),
    as.character(reticulate::py_eval("_spm_names",convert=TRUE)))
  expect_equal(vapply(result$values,function(v)v$value,numeric(1L)),
    as.numeric(reticulate::py_eval("_spm_values",convert=TRUE)),
    tolerance=1e-12)
  # Python slice [1:5] already contains exactly the four
  # cxx/cxy/cyx/cyy block labels; do not drop cxx again in R.
  expect_identical(vapply(result$values[2:5],function(v)v$source,character(1L)),
    as.character(reticulate::py_eval("_spm_sources[1:5]",
      convert=TRUE)))
  expect_identical(result$provenance$measurement_error_truth_supplied,
    reticulate::py_eval("_spm_provenance['measurement_error_truth_supplied']",
      convert=TRUE))
})
