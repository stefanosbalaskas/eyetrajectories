# Native FDApy UFPCA original source PS+LP sparse curve mean/covariance
# smoothing, raw pooled covariance, eigenspace and PACE.
# Frozen public export eyetrajectoriespy==1.2.0, source pinned
# c1cd95ad718327550f7e55393ff38582872f7a94. Upstream FDApy
# source snapshot 6626ebc6a70a6496f3058c4abb0bb97f5bdb20be.

.etr_fdapy_native_fit_fixture <- function(){
  grid<-seq(0,1,length.out=17L)
  ti<-lapply(seq_len(10L),function(i) {
    # Sparse, non-identical sampling schedules with pooled full support
    keep<-sort(unique(c(1L,17L,seq(2L+i%%3L,16L,by=2L))))
    grid[keep]
  })
  yy<-lapply(seq_along(ti),function(i) {
    t<-ti[[i]]
    cbind(x=.08*i + (1+i/20)*sin(2*pi*t)+
      .12*cos(4*pi*t+i*.13)+.07*(i%%3L)*t,
      y=rep(i,length(t)))
  })
  tr<-etr_irregular_trajectory_set(ti,yy,
    curve_ids=paste0("p",seq_along(ti)),
    dimension_names=c("x","y"),
    time_unit="seconds",coordinate_system="degrees")
  list(trajectories=tr,pooled=sort(unique(unlist(ti))),
    kwargs_mean=list(n_segments=5L,degree=3L,penalty=1),
    kwargs_covariance=list(
      n_segments=4L,degree=3L,penalty=c(.3,.3)))
}

test_that("FDApy univariate PS basis matches source uniform unclamped B-spline geometry",{
  x<-seq(0,1,length.out=17L)
  for(degree in 1:3){
    B<-.etr_fdapy_ps_basis(x,n_segments=4L,degree=degree)
    expect_identical(dim(B),c(17L,4L+degree))
    expect_equal(rowSums(B),rep(1,17L),tolerance=1e-11)
    expect_true(all(B>=-1e-11))
    expect_true(all(B<=1+1e-11))
    expect_equal(rowSums(B^2),
      rowSums(splines::splineDesign(
        seq(-degree/4,1+degree/4,
          length.out=5L+2L*degree),
        x,ord=degree+1,outer.ok=TRUE)^2),
      tolerance=1e-13)
  }
  expect_error(.etr_fdapy_ps_basis(x,n_segments=0L),
    "n_segments")
  expect_error(.etr_fdapy_ps_basis(x,degree=0L),"degree")
})

test_that("source FDApy mean PS and local-polynomial smoothers reproduce known mathematical truths",{
  x<-seq(0,1,length.out=17L)
  y<-1+2*x
  pred<-.etr_fdapy_ps_1d(x,y,x,penalty=0,
    n_segments=4L,degree=3L)
  expect_equal(pred,y,tolerance=1e-10)
  for(degree in 0:2){
    px<-seq(-1,1,length.out=29L)
    v<-switch(as.character(degree),
      "0"=rep(2,length(px)),
      "1"=1+2*px,
      "2"=1+2*px+3*px^2)
    qp<-seq(-.9,.9,length.out=11L)
    actual<-.etr_fdapy_lp_predict(px,v,qp,bandwidth=2,
      degree=degree,kernel_name="gaussian")
    truth<-switch(as.character(degree),
      "0"=rep(2,length(qp)),
      "1"=1+2*qp,
      "2"=1+2*qp+3*qp^2)
    expect_equal(actual,truth,tolerance=1e-9)
  }
  two<-expand.grid(x=seq(-1,1,length.out=9L),
    y=seq(-1,1,length.out=7L))
  xmat<-as.matrix(two)
  zz<-2+3*xmat[,1L]-2*xmat[,2L]+
    .5*xmat[,1L]^2+.7*xmat[,1L]*xmat[,2L]+
    .9*xmat[,2L]^2
  pt<-rbind(c(-.2,.3),c(.4,-.5))
  pred2<-.etr_fdapy_lp_predict(xmat,zz,pt,bandwidth=3,
    degree=2L)
  truth2<-2+3*pt[,1L]-2*pt[,2L]+.5*pt[,1L]^2+
    .7*pt[,1L]*pt[,2L]+.9*pt[,2L]^2
  expect_equal(pred2,truth2,tolerance=1e-9)
  expect_error(.etr_fdapy_lp_predict(xmat,zz,pt,bandwidth=0),
    "positive bandwidth")
  expect_error(.etr_fdapy_lp_predict(xmat,zz,pt,bandwidth=2,
    degree=3L),"degrees 0")
})

test_that("observed-pair raw covariance and difference noise follow FDApy source without raw interpolation",{
  fx<-.etr_fdapy_native_fit_fixture()
  times<-fx$trajectories$time
  y<-lapply(fx$trajectories$values,function(v)as.numeric(v[,1L]))
  raw<-.etr_fdapy_cov_raw(times,y,fx$pooled)
  expect_identical(dim(raw$raw),
    c(length(fx$pooled),length(fx$pooled)))
  expect_equal(raw$raw,t(raw$raw),tolerance=0)
  expect_equal(raw$count,t(raw$count),tolerance=0)
  expect_true(all(raw$count>=0))
  expect_identical(raw$zero_weight,raw$count==0)
  ids<-match(times[[1L]],fx$pooled)
  for(i in ids){
    expect_gte(raw$count[i,i],1)
  }
  diag_expected<-vapply(seq_along(fx$pooled),function(j){
    v<-vapply(seq_along(times),function(i){
      loc<-match(fx$pooled[j],times[[i]])
      if(is.na(loc))NA_real_ else y[[i]][loc]^2
    },numeric(1L))
    mean(v,na.rm=TRUE)
  },numeric(1L))
  expect_equal(diag(raw$raw),diag_expected,tolerance=1e-14)
  zz<-.etr_fdapy_diff_noise(list(c(1,2),c(1,3,2,4)))
  expect_identical(zz[1],0)
  weight<-c(.809,-.5,-.309)
  expect_equal(zz[2],
    mean(c(sum(weight*c(1,3,2))^2,
      sum(weight*c(3,2,4))^2)),tolerance=1e-15)
})

test_that("full PS FDApy UFPCA fit produces real native source covariance, eigenfunction and conditional scores",{
  fx<-.etr_fdapy_native_fit_fixture()
  out<-etr_fit_sparse_fpca_fdapy(fx$trajectories,"x",
    n_components=2L,strict_source_record=TRUE,
    fit_smoothing="PS",
    kwargs_mean=fx$kwargs_mean,
    kwargs_covariance=fx$kwargs_covariance,
    tol=.02)
  expect_s3_class(out,"etr_fdapy_native_ufpca_ps_lp_scientific_record")
  expect_identical(out$dimension,"x")
  expect_identical(out$fit_smoothing,"PS")
  expect_identical(out$score_smoothing,"LP")
  expect_true(out$fitted_UFPCA_model_natively)
  expect_false(out$source_fit_full_parity)
  expect_identical(out$source_covariance_estimator,
    "FDApy_irregular_1.0.x_PS_smoothing")
  expect_identical(length(out$source_mean_fit),
    length(fx$pooled))
  expect_equal(out$source_smoothed_covariance,
    t(out$source_smoothed_covariance),tolerance=1e-12)
  expect_identical(dim(out$source_raw_covariance),
    c(length(fx$pooled),length(fx$pooled)))
  expect_identical(dim(out$source_eigenfunctions),
    c(2L,length(fx$pooled)))
  expect_identical(dim(out$scores),c(10L,2L))
  expect_true(all(is.finite(out$scores)))
  expect_true(all(is.finite(out$source_reconstructed$values)))
  expect_equal(sum(out$source_quadrature_weights),1,
    tolerance=1e-12)
  weighted_phi<-sweep(out$source_eigenfunctions,2L,
    out$source_quadrature_weights,"*")
  expect_equal(
    weighted_phi%*%t(out$source_eigenfunctions),
    diag(2),tolerance=1e-7)
  expect_identical(out$curve_ids,fx$trajectories$curve_ids)
  expect_false(out$source_equivalent)
  expect_false(out$independently_source_certified)
  expect_null(out$backend_object)
  expect_identical(
    out$provenance$sparse_fpca$spectral_state_supplied_instead_of_fitted,
    FALSE)
  expect_identical(
    out$provenance$sparse_fpca$scientific_native_UFPCA_fit,TRUE)
})

test_that("native FDApy UFPCA LP fits raw irregular mean, diagonal-excluded covariance and PACE",{
  fx<-.etr_fdapy_native_fit_fixture()
  out<-etr_fit_sparse_fpca_fdapy(fx$trajectories,"x",
    n_components=1L,strict_source_record=TRUE,
    fit_smoothing="LP",
    kwargs_mean=list(bandwidth=.8,degree=1L),
    kwargs_covariance=list(bandwidth=1.2,degree=2L),
    tol=.03)
  expect_s3_class(out,"etr_fdapy_native_ufpca_ps_lp_scientific_record")
  expect_identical(out$fit_smoothing,"LP")
  expect_identical(out$n_components,1L)
  expect_true(out$fitted_UFPCA_model_natively)
  expect_identical(dim(out$scores),c(10L,1L))
  expect_identical(out$source_covariance_estimator,
    "FDApy_irregular_1.0.x_LP_smoothing")
  expect_true(all(is.finite(out$source_mean_fit)))
  expect_true(all(is.finite(out$source_smoothed_covariance)))
  expect_true(all(is.finite(out$scores)))
  expect_true(out$source_noise_floor>=.03)
  expect_equal(out$source_quadrature_weights,
    etr_trapezoid_weights(out$source_reconstructed$grid),
    tolerance=1e-14)
})

test_that("FDApy full-fit and earlier fixed-spectrum conditional-score paths remain distinct",{
  fx<-.etr_fdapy_native_fit_fixture()
  fit<-etr_fit_sparse_fpca_fdapy(fx$trajectories,"x",
    n_components=1L,strict_source_record=TRUE,
    kwargs_mean=fx$kwargs_mean,
    kwargs_covariance=fx$kwargs_covariance)
  snap<-list(
    mean_grid=fit$source_mean_fit,
    eigenvalues=fit$eigenvalues,
    eigenfunctions=fit$source_eigenfunctions,
    noise_variance=fit$source_noise_floor,
    centered_observations=lapply(seq_along(fx$trajectories$time),
      function(i)as.numeric(fx$trajectories$values[[i]][,1L]-
        fit$source_mean_center_resmoothed[
          match(fx$trajectories$time[[i]],fx$pooled)])))
  conditional<-etr_fit_sparse_fpca_fdapy(fx$trajectories,"x",
    n_components=1L,strict_source_record=TRUE,
    source_fit_snapshot=snap)
  expect_s3_class(conditional,
    "etr_fdapy_fixed_spectrum_pace_scientific_record")
  expect_false(conditional$fitted_UFPCA_model_natively)
  expect_true(fit$fitted_UFPCA_model_natively)
  expect_equal(conditional$scores,fit$scores,tolerance=1e-12,
    ignore_attr=TRUE)
  old<-tryCatch(etr_fit_sparse_fpca_fdapy(fx$trajectories,"x"),
    error=function(e)conditionMessage(e))
  expect_match(old,"fdapace")
})

test_that("native FDApy full fit rejects unvalidated modes instead of fabricating backend parity",{
  fx<-.etr_fdapy_native_fit_fixture()
  go<-function(...){
    etr_fit_sparse_fpca_fdapy(fx$trajectories,"x",
      n_components=1L,strict_source_record=TRUE,
      kwargs_mean=fx$kwargs_mean,
      kwargs_covariance=fx$kwargs_covariance,...)
  }
  expect_error(go(normalize=TRUE),"normalize=FALSE")
  expect_error(go(fit_smoothing=NULL),"PS or LP")
  expect_error(go(kwargs_mean=list(unknown=TRUE)),"unsupported")
  expect_error(go(kwargs_covariance=list(remove_diagonal=FALSE)),
    "remove_diagonal")
  expect_error(go(evaluation_grid=seq(0,1,length.out=7L)),
    "pooled observed")
  expect_error(go(n_components=100L),"n_curves")
})

test_that("real frozen Python 1.2 and real FDApy UFPCA PS covariance fit match native source estimand modulo Python eig ordering/sign",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("actual frozen Python 1.2 and FDApy 1.0.3 source differential opt-in")
  skip_if_not_installed("reticulate")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
from FDApy.preprocessing import UFPCA
from FDApy.representation import DenseArgvals
grid=np.linspace(0.,1.,17)
times=[];vs=[]
for i in range(1,11):
    inds=sorted(set([0,16]+list(range(1+(i%3),16,2))))
    t=grid[inds]
    y=.08*i+(1+i/20.)*np.sin(2*np.pi*t)+.12*np.cos(4*np.pi*t+i*.13)+.07*(i%3)*t
    times.append(t)
    vs.append(np.column_stack([y,np.repeat(float(i),len(t))]))
tr=et.IrregularTrajectorySet(
    time=tuple(times),values=tuple(vs),
    curve_ids=tuple('p'+str(i) for i in range(1,11)),
    dimension_names=('x','y'),time_unit='seconds',
    coordinate_system='degrees')
fd=et.to_fdapy_irregular(tr,dimension='x')
models={}
for smoother,kwm,kwc in (
 ('PS',dict(n_segments=5,degree=3,penalty=1),
        dict(n_segments=4,degree=3,penalty=(.3,.3))),
 ('LP',dict(bandwidth=.8,degree=1),
        dict(bandwidth=1.2,degree=2))):
   model=UFPCA(method='covariance',n_components=2,normalize=False)
   model.fit(fd,method_smoothing=smoother,
      kwargs_mean=kwm,kwargs_covariance=kwc)
   scores=model.transform(fd,method='PACE',method_smoothing='LP',tol=.02)
   models[smoother]=dict(
      mean=np.asarray(model.mean.values[0]),
      eigenvalues=np.asarray(model.eigenvalues),
      eigenfunctions=np.asarray(model.eigenfunctions.values),
      covariance=np.asarray(model.covariance.values[0]),
      noise=float(model._noise_variance),
      scores=np.asarray(scores))
")
  fx<-.etr_fdapy_native_fit_fixture()
  for(mode in c("PS","LP")){
    p<-reticulate::py_eval(
      paste0("models['",mode,"']"),convert=TRUE)
    got<-etr_fit_sparse_fpca_fdapy(fx$trajectories,"x",
      n_components=2L,strict_source_record=TRUE,
      fit_smoothing=mode,tol=.02,
      kwargs_mean=if(mode=="PS")fx$kwargs_mean else
        list(bandwidth=.8,degree=1L),
      kwargs_covariance=if(mode=="PS")fx$kwargs_covariance else
        list(bandwidth=1.2,degree=2L))
    expect_equal(got$source_mean_fit,as.numeric(p$mean),
      tolerance=1e-7,info=mode)
    # Source uses np.linalg.eig *without sorting*. Match all 2
    # source eigenpairs only after relative closeness to eigenvalues.
    py_lambda<-as.numeric(p$eigenvalues)
    expect_equal(sort(got$eigenvalues),
      sort(py_lambda),tolerance=1e-5,info=mode)
    expect_equal(got$source_covariance_spectral,
      as.matrix(p$covariance),tolerance=1e-4,info=mode)
    expect_true(all(is.finite(got$scores)),info=mode)
  }
})
