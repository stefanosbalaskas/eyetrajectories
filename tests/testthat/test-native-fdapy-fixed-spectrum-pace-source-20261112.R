# Frozen 1.2 sparse.py -> FDApy 1.0.x _transform_pace_irregular.
# Conditional fixed-source-spectrum PACE *scoring* (not FDApy UFPCA.fit).

.etr_fdapy_fixed_fixture<-function(){
  tt<-list(c(0,.6,2),c(.2,1.2,2),c(0,.7,1.6,2),
    c(.2,1.6,2),c(0,1.2,2),c(.6,1.6,2))
  pooled<-sort(unique(unlist(tt,use.names=FALSE)))
  mean<-1+.2*pooled
  phi<-rbind(
    sin(pi*pooled/2),
    cos(pi*pooled/2))
  y<-lapply(seq_along(tt),function(i)
    cbind(x=1+.2*tt[[i]]+(i-3)/7+
      .3*sin(pi*tt[[i]]/2)+.08*i*cos(pi*tt[[i]]/2),
      y=rep(i,length(tt[[i]]))))
  metadata<-data.frame(group=rep(c("A","B"),3L),
    stringsAsFactors=FALSE)
  tr<-etr_irregular_trajectory_set(tt,y,
    curve_ids=paste0("i",seq_along(tt)),
    dimension_names=c("x","y"),time_unit="seconds",
    metadata=metadata)
  centered<-lapply(seq_along(tt),function(i)
    as.numeric(y[[i]][,1L]-(1+.2*tt[[i]])))
  snap<-list(
    mean_grid=mean,
    eigenfunctions=phi,
    eigenvalues=c(2.5,1.1),
    noise_variance=.04,
    centered_observations=centered,
    backend_version="1.0.3")
  list(trajectories=tr,time=tt,pooled=pooled,mean=mean,
    centered=centered,snapshot=snap,metadata=metadata)
}

test_that("FDApy fixed-spectrum PACE matches source pooled linear interpolation and BLUP scoring",{
  fx<-.etr_fdapy_fixed_fixture()
  got<-etr_fit_sparse_fpca_fdapy(fx$trajectories,
    "x",n_components=2L,strict_source_record=TRUE,
    source_fit_snapshot=fx$snapshot)
  expect_s3_class(got,"etr_fdapy_fixed_spectrum_pace_scientific_record")
  expect_identical(got$curve_ids,fx$trajectories$curve_ids)
  expect_identical(got$dimension,"x")
  expect_identical(got$fit_method,"covariance")
  expect_identical(got$fit_smoothing,"PS")
  expect_identical(got$score_method,"PACE")
  expect_identical(got$score_smoothing,"LP")
  expect_identical(got$n_components,2L)
  expect_identical(dim(got$scores),c(6L,2L))
  expect_identical(got$time_unit,"seconds")
  expect_identical(got$provenance$sparse_fpca$backend,"FDApy")
  expect_identical(got$provenance$sparse_fpca$interpolation_performed,TRUE)
  expect_true(got$interpolation_performed)
  expect_false(got$fitted_UFPCA_model_natively)
  expect_null(got$backend_object)
  expect_null(got$backend_data)
  expect_null(got$reconstructed_backend)
  expect_false(got$source_equivalent)
  expect_false(got$independently_source_certified)
  reference_centered<-do.call(rbind,lapply(seq_along(fx$time),
    function(i)approx(fx$time[[i]],fx$centered[[i]],
      xout=fx$pooled,rule=2)$y))
  expect_equal(got$source_centered_grid,reference_centered,
    tolerance=1e-15)
  phi<-fx$snapshot$eigenfunctions
  lambda<-fx$snapshot$eigenvalues
  cov<-t(phi)%*%(lambda*phi)
  sigma<-cov+diag(.04,ncol(phi))
  direct<-sweep(reference_centered%*%solve(sigma)%*%
    t(phi),2L,lambda,"*")
  expect_equal(got$scores,direct,tolerance=1e-12,
    ignore_attr=TRUE)
  expect_equal(got$source_covariance_spectral,cov,tolerance=1e-12)
  expect_equal(got$source_noise_floor,.04)
  expect_equal(got$source_reconstructed$values,
    got$scores%*%phi+
      matrix(rep(fx$mean,each=6L),nrow=6L),
    tolerance=1e-12,ignore_attr=TRUE)
  expect_equal(got$source_reconstructed$grid,fx$pooled)
})

test_that("FDApy native PACE uses source max(tol, fitted noise) floor, not a ridge added twice",{
  fx<-.etr_fdapy_fixed_fixture()
  got<-etr_fit_sparse_fpca_fdapy(fx$trajectories,"x",
    n_components=2L,strict_source_record=TRUE,
    tol=.2,source_fit_snapshot=fx$snapshot)
  expect_equal(got$source_noise_floor,.2)
  expect_equal(diag(got$source_covariance_spectral+diag(.2,length(fx$pooled))),
    diag(got$source_covariance_spectral)+.2,tolerance=0)
  y<-got$source_centered_grid
  phi<-fx$snapshot$eigenfunctions
  lam<-fx$snapshot$eigenvalues
  expected<-sweep(y%*%solve(t(phi)%*%(lam*phi)+
    diag(.2,ncol(phi)))%*%t(phi),2L,lam,"*")
  expect_equal(got$scores,expected,tolerance=1e-12,
    ignore_attr=TRUE)
})

test_that("FDApy source-snapshot checks frozen grid, rank and unsupported fitting claims",{
  fx<-.etr_fdapy_fixed_fixture()
  run<-function(...){
    etr_fit_sparse_fpca_fdapy(fx$trajectories,"x",
      n_components=2L,strict_source_record=TRUE,
      source_fit_snapshot=fx$snapshot,...)
  }
  expect_error(run(evaluation_grid=seq(0,2,length.out=5)),
    "pooled observed times")
  expect_error(run(n_components=0),"n_components")
  expect_error(run(tol=-1),"tol")
  expect_error(run(normalize=TRUE),"normalize=FALSE")
  expect_error(run(score_smoothing="interpolation"),
    "score_smoothing")
  expect_error(run(fit_smoothing="unknown"),"fit_smoothing")
  expect_error(run(strict_source_record=NA),"strict_source_record")
  # No supplied snapshot now opts into native FDApy UFPCA PS/LP fitting.
  # Unsupported unsmoothed native fitting is an explicit separate boundary.
  expect_error(etr_fit_sparse_fpca_fdapy(fx$trajectories,"x",
    n_components=2L,fit_smoothing=NULL,
    strict_source_record=TRUE),"PS or LP")
  bad<-fx$snapshot;bad$centered_observations[[2L]]<-1
  expect_error(etr_fit_sparse_fpca_fdapy(fx$trajectories,"x",
    n_components=2L,strict_source_record=TRUE,
    source_fit_snapshot=bad),"centered_observations")
  bad<-fx$snapshot;bad$eigenfunctions<-t(bad$eigenfunctions)
  expect_error(etr_fit_sparse_fpca_fdapy(fx$trajectories,"x",
    n_components=2L,strict_source_record=TRUE,
    source_fit_snapshot=bad),"eigenfunctions")
  bad<-fx$snapshot;bad$eigenvalues[1]<-NA_real_
  expect_error(etr_fit_sparse_fpca_fdapy(fx$trajectories,"x",
    n_components=2L,strict_source_record=TRUE,
    source_fit_snapshot=bad),"eigenvalues")
  expect_error(etr_fit_sparse_fpca_fdapy(fx$trajectories,"x"),
    "fdapace")
})

test_that("FDApy source pseudoinverse uses NumPy SVD rcond not solve/Cholesky when singular",{
  x<-diag(c(1,1e-16,0))
  z<-.etr_fdapy_spectrum_pinv(x)
  expect_equal(diag(z),c(1,0,0),tolerance=1e-14)
  expect_true(all(is.finite(z)))
  expect_equal(.etr_fdapy_spectrum_pinv(matrix(0,2,2)),
    matrix(0,2,2),tolerance=0)
})

test_that("actual frozen FDApy 1.0.x internal PACE interpolation, scores and reconstructed values match native R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("opt-in FDApy==1.0.3 and eyetrajectoriespy==1.2.0 real source required")
  skip_if_not_installed("reticulate")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import FDApy
import eyetrajectoriespy as et
from FDApy.representation import (
  DenseArgvals,DenseValues,DenseFunctionalData,
  IrregularArgvals,IrregularValues,IrregularFunctionalData)
from FDApy.preprocessing.dim_reduction.ufpca import (
  _transform_pace_irregular)
t=[np.array(v,float) for v in (
  [0,.6,2],[.2,1.2,2],[0,.7,1.6,2],
  [.2,1.6,2],[0,1.2,2],[.6,1.6,2])]
pooled=np.unique(np.concatenate(t))
mean=1+.2*pooled
phi=np.vstack([np.sin(np.pi*pooled/2),np.cos(np.pi*pooled/2)])
lam=np.array([2.5,1.1])
ys=[np.column_stack((
    1+.2*ti+(i-2)/7+.3*np.sin(np.pi*ti/2)+
      .08*(i+1)*np.cos(np.pi*ti/2),
    np.repeat(float(i+1),len(ti))))
    for i,ti in enumerate(t)]
centered=[y[:,0]-(1+.2*ti) for ti,y in zip(t,ys)]
frozen=et.IrregularTrajectorySet(
   time=tuple(t),values=tuple(ys),
   curve_ids=tuple('i'+str(i+1) for i in range(len(t))),
   dimension_names=('x','y'),time_unit='seconds')
real_data=et.to_fdapy_irregular(frozen,dimension='x')
assert isinstance(real_data,IrregularFunctionalData)
cdata=IrregularFunctionalData(
  IrregularArgvals({i:DenseArgvals({'input_dim_0':ti})
                   for i,ti in enumerate(t)}),
  IrregularValues({i:val for i,val in enumerate(centered)}))
func=DenseFunctionalData(
  DenseArgvals({'input_dim_0':pooled}),DenseValues(phi))
cov=np.einsum('k,ki,kj->ij',lam,phi,phi)
covf=DenseFunctionalData(
  DenseArgvals({'input_dim_0':pooled,'input_dim_1':pooled}),
  DenseValues(cov[np.newaxis,:,:]))
fitted_scores=_transform_pace_irregular(
  cdata,func,lam,covf,noise_variance=.04)
fitted_reconstructed=fitted_scores@phi+mean
source_values={'scores':fitted_scores,
  'reconstructed':fitted_reconstructed,
  'centered_grid':cdata.smooth(method='interpolation').values,
  'grid':pooled,'eigenvalues':lam,'eigenfunctions':phi,
  'noise_variance':.04}
")
  fx<-.etr_fdapy_fixed_fixture()
  ours<-etr_fit_sparse_fpca_fdapy(fx$trajectories,"x",
    n_components=2L,strict_source_record=TRUE,
    source_fit_snapshot=fx$snapshot)
  data<-reticulate::py_eval("source_values",convert=TRUE)
  expect_equal(ours$scores,as.matrix(data$scores),
    tolerance=1e-10,ignore_attr=TRUE)
  expect_equal(ours$source_reconstructed$values,
    as.matrix(data$reconstructed),tolerance=1e-10,
    ignore_attr=TRUE)
  expect_equal(ours$source_centered_grid,
    as.matrix(data$centered_grid),tolerance=1e-10,
    ignore_attr=TRUE)
  expect_equal(ours$source_reconstructed$grid,
    as.numeric(data$grid),tolerance=0)
})
