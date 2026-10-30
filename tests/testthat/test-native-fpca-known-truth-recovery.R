.etr_fpca_recovery_source_fixture<-function(nd=1L){
  grid<-c(0,.5,1)
  n<-4L
  phi<-array(rep(1/sqrt(nd),3L*nd),c(1L,3L,nd))
  true_scores<-matrix(c(-2,-1,1,2),ncol=1L)
  mean<-matrix(rep(c(.1,.2,.3),nd),3L,nd)
  latent<-array(0,c(n,3L,nd))
  for(i in seq_len(n)){
    latent[i,,]<-mean+true_scores[i,1L]*
      matrix(phi,nrow=3L,ncol=nd)
  }
  truth<-list(truth_grid=grid,dimension_names=paste0("d",seq_len(nd)),
    mean=mean,eigenfunctions=phi,eigenvalues=.5,
    scores=true_scores,latent_on_truth_grid=latent)
  estimated_mean<-mean
  estimated_mean[2L,1L]<-estimated_mean[2L,1L]+.1
  fit<-list(time=grid,dimension_names=truth$dimension_names,
    provenance=list(fpca=list(scaling="none")),
    scale=rep(1,nd),mean=estimated_mean,
    components= -phi,explained_variance=.5,
    scores= -true_scores,weights=c(.25,.5,.25))
  list(fit=fit,truth=truth)
}
test_that("FPCA source recovery sign alignment and original score laws are retained",{
  z<-.etr_fpca_recovery_source_fixture()
  x<-etr_evaluate_fpca_recovery(z$fit,z$truth)
  expect_identical(length(x$values),9L)
  expect_identical(vapply(x$values,function(v)v$metric$name,character(1L)),
    c("mean_ise","covariance_ise","eigenvalue_relative_error",
      "component_absolute_similarity","score_correlation","score_rmse",
      "subspace_principal_cosine","subspace_principal_angle_degrees",
      "reconstruction_ise"))
  expect_equal(vapply(x$values,function(v)v$value,numeric(1L)),
    c(.005,0,0,1,1,0,1,0,.005),tolerance=1e-12)
  expect_identical(x$provenance$matched_truth_components,0L)
  expect_equal(x$provenance$alignment_signs,-1)
  expect_false(x$provenance$multivariate)
  two<-.etr_fpca_recovery_source_fixture(2L)
  multiv<-etr_evaluate_fpca_recovery(two$fit,two$truth)
  expect_true(multiv$provenance$multivariate)
  expect_equal(multiv$values[[1L]]$value,.005)
  expect_equal(multiv$values[[2L]]$value,0,tolerance=1e-12)
})
test_that("FPCA source recovery fails closed outside declared one-mode domain",{
  z<-.etr_fpca_recovery_source_fixture()
  invalid<-z$fit;invalid$time[2L]<-.51
  expect_error(etr_evaluate_fpca_recovery(invalid,z$truth),"exact source grid")
  invalid<-z$fit;invalid$scale<-2
  expect_error(etr_evaluate_fpca_recovery(invalid,z$truth),"unit dimension scales")
  invalid<-z$fit;invalid$provenance$fpca$scaling<-"zscore"
  expect_error(etr_evaluate_fpca_recovery(invalid,z$truth),"scaling='none'")
  invalid<-z$fit;invalid$components<-array(1,c(2L,3L,1L))
  expect_error(etr_evaluate_fpca_recovery(invalid,z$truth),
    "exactly one fitted")
  invalid<-z$fit;invalid$dimension_names<-"different"
  expect_error(etr_evaluate_fpca_recovery(invalid,z$truth),
    "dimension names/order")
})
test_that("frozen Python 1.2 FPCA one-mode recovery matches direct source",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published Python 1.2 unscaled one-component FPCA oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
from eyetrajectoriespy._functional_simulation import FunctionalSimulationTruth
def _fpcr_obj(cls,**fields):
    z=object.__new__(cls)
    for key,value in fields.items():object.__setattr__(z,key,value)
    return z
_fpcr_oracle={}
for ndim in (1,2):
    grid=np.array([0.,.5,1.])
    mode=np.full((1,3,ndim),1/np.sqrt(ndim))
    scores=np.array([[-2.],[-1.],[1.],[2.]])
    mean=np.tile(np.array([.1,.2,.3])[:,None],(1,ndim))
    latent=mean[None,:,:]+scores[:,:,None]*mode[0][None,:,:]
    truth=_fpcr_obj(FunctionalSimulationTruth,
        truth_grid=grid,dimension_names=tuple('d'+str(i+1) for i in range(ndim)),
        mean=mean,eigenfunctions=mode,eigenvalues=np.array([.5]),
        scores=scores,latent_on_truth_grid=latent)
    estimated=mean.copy();estimated[1,0]+=.1
    fit=_fpcr_obj(et.FPCAResult,time=grid,
        dimension_names=truth.dimension_names,
        provenance={'fpca':{'scaling':'none'}},
        scale=np.ones(ndim),mean=estimated,
        components=-mode,explained_variance=np.array([.5]),
        scores=-scores,weights=np.array([.25,.5,.25]))
    assessment=et.evaluate_fpca_recovery(fit,truth)
    _fpcr_oracle[ndim]=dict(
      names=[v.metric.name for v in assessment.values],
      values=[float(v.value) for v in assessment.values],
      components=[v.component for v in assessment.values],
      provenance=dict(assessment.provenance))
")
  for(ndim in 1:2){
    z<-.etr_fpca_recovery_source_fixture(ndim)
    x<-etr_evaluate_fpca_recovery(z$fit,z$truth)
    key<-paste0("_fpcr_oracle[",ndim,"]")
    expect_identical(vapply(x$values,function(v)v$metric$name,character(1L)),
      as.character(reticulate::py_eval(paste0(key,"['names']"),convert=TRUE)))
    expect_equal(vapply(x$values,function(v)v$value,numeric(1L)),
      as.numeric(reticulate::py_eval(paste0(key,"['values']"),convert=TRUE)),
      tolerance=1e-12)
    expect_identical(x$provenance$multivariate,ndim>1L)
    expect_equal(x$provenance$alignment_signs,
      as.numeric(reticulate::py_eval(paste0(key,
        "['provenance']['alignment_signs']"),convert=TRUE)))
  }
})
