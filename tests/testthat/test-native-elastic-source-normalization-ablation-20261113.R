# Source-method ablation, NOT a claim of numerical equivalence.
# Python fdasrsf fdacurve.__init__ calls curve_to_q(..., scale=TRUE) even
# when its public scale_curves is FALSE; R fdasrvf::multivariate_karcher_mean
# computes curve_to_srvf(..., scale=scale) and the current native wrapper uses
# scale=FALSE for the corresponding public option. Compare both R pathways
# on the identical public frozen Python 1.2 fixture.
#
# Independent original-coordinate reparameterization follows the true Python
# scipy.interpolate.interp1d (piecewise linear) geometry, rather than the
# R fdasrvf normalized-SRVF q_to_curve reconstruction.
# This test is opt-in and does not relax or redefine any scientific contract.

test_that("frozen elastic original-SRVF scaling and coordinate-alignment controlled ablation",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_ELASTIC_TESTS"),"true"))
    skip("real frozen Python 1.2 elastic source normalization ablation is opt-in")
  skip_if_not_installed("fdasrvf",minimum_version="2.5.1")
  skip_if_not_installed("reticulate")
  expect_identical(et_python_version(),"1.2.0")
  n<-6L; nt<-25L
  time<-seq(0,1,length.out=nt)
  values<-array(NA_real_,dim=c(n,nt,2L))
  for(i in seq_len(n)){
    phase<-time^(0.75+0.09*i)
    amplitude<-1+0.07*cos(0.72*i)
    values[i,,1L]<-amplitude*(2*phase-1)+
      0.08*cos(i)*sin(2*pi*phase)
    values[i,,2L]<-amplitude*sin(2*pi*phase)+
      0.08*sin(i)*phase
  }
  x<-etr_trajectory_set(time,values,
    curve_ids=paste0("e",seq_len(n)),
    dimension_names=c("x","y"),
    coordinate_system="pixels",time_unit="ms",
    provenance=list(source="normalization_source_ablation"))
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
from joblib import parallel_config
ab_t=np.linspace(0.,1.,25)
ab_values=[]
for i in range(1,7):
    p=ab_t**(0.75+0.09*i)
    a=1+0.07*np.cos(0.72*i)
    xx=a*(2*p-1)+.08*np.cos(i)*np.sin(2*np.pi*p)
    yy=a*np.sin(2*np.pi*p)+.08*np.sin(i)*p
    ab_values.append(np.stack((xx,yy),axis=-1))
ab_values=np.stack(ab_values,axis=0)
ab_tr=et.TrajectorySet(time=ab_t,values=ab_values,
  curve_ids=tuple('e'+str(i) for i in range(1,7)),
  dimension_names=('x','y'),coordinate_system='pixels',time_unit='ms')
with parallel_config(backend='threading'):
    ab_fit=et.fit_elastic_fpca(ab_tr,n_components=2,rotation=False,
      scale_curves=False,lam=0.,method='DP')
ab_oracle={
  'input':np.asarray(ab_values),
  'original_q':np.asarray(ab_fit.backend_object.q),
  'warp':np.asarray(ab_fit.warping_functions),
  'aligned':np.asarray(ab_fit.aligned.values),
  'mean':np.asarray(ab_fit.mean_curve),
  'scores':np.asarray(ab_fit.scores)}
")
  py<-reticulate::py_eval("ab_oracle",convert=TRUE)
  expect_identical(dim(py$input),dim(values))
  expect_lt(max(abs(values-py$input)),1e-12)
  expect_identical(dim(py$original_q),c(2L,nt,n))
  expect_identical(dim(py$warp),c(n,nt))
  betas<-aperm(values,c(3L,2L,1L))
  base<-etr_fit_elastic_fpca(x,n_components=2L,rotation=FALSE,
    scale_curves=FALSE,lam=0,method="DP",strict_source_record=TRUE)
  k0<-base$native_backend_object
  # This is an ABLATION: scale=TRUE here normalizes the internal SRVF
  # geometry; it is NOT silently substituted into the public scale option.
  k1<-fdasrvf::multivariate_karcher_mean(betas,
    mode="O",alignment=TRUE,rotation=FALSE,scale=TRUE,
    lambda=0,maxit=20L,ms="mean",exact_medoid=FALSE,
    ncores=1L,verbose=FALSE)
  expect_s3_class(k1,"fdacurve")
  expect_identical(dim(k1$q),c(2L,nt,n))
  expect_true(all(is.finite(k1$betan)))
  expect_true(all(is.finite(k1$gamma)))
  pca1<-fdasrvf::multivariate_pca(k1,no=2L,
    ci=seq(-2,2.5,by=.5),mode="O",showplot=FALSE)
  expect_true(all(is.finite(pca1$coef)))
  gamma1<-t(k1$gamma)
  aligned1<-aperm(k1$betan,c(3L,2L,1L))
  scores1<-t(pca1$coef[1:2,,drop=FALSE])
  centered<-function(v){
    for(i in seq_len(dim(v)[1L]))
      for(j in seq_len(dim(v)[3L]))
        v[i,,j]<-v[i,,j]-mean(v[i,,j])
    v
  }
  cmean<-function(m)sweep(m,1L,rowMeans(m),"-")
  rmse<-function(a,b)sqrt(mean((a-b)^2))
  # Python 2.7 source applies gamma directly to *original centered curves*
  # using scipy.interpolate.interp1d. Translation-centering the outputs
  # removes the difference between Python arc-length centroid and raw
  # source input without changing the coordinate shape being compared.
  interpolate_original<-function(warp){
    out<-array(NA_real_,dim=dim(values))
    for(i in seq_len(n))
      for(j in 1:2){
        out[i,,j]<-stats::approx(time,values[i,,j],
          xout=warp[i,],ties="ordered",rule=2)$y
      }
    out
  }
  norm_sq<-function(q){
    vapply(seq_len(dim(q)[3L]),function(i)
      sqrt(mean(colSums(q[,,i]^2))),numeric(1L))
  }
  norm_python<-norm_sq(py$original_q)
  norm_r_unscaled<-norm_sq(k0$q)
  norm_r_scaled<-norm_sq(k1$q)
  score_dist<-function(s)as.numeric(stats::dist(s))
  d_py<-score_dist(py$scores)
  d_base<-score_dist(base$scores)
  d_scaled<-score_dist(scores1)
  score_d_rmse<-function(v)rmse(v,d_py)
  scale_fit<-function(v)sum(v*d_py)/sum(v^2)
  rel_score_rmse<-function(v){
    factor<-scale_fit(v)
    rmse(factor*v,d_py)
  }
  # Normalized source R vs Python q residual, with identical curve order.
  # No PCA sign or eigenspace equivalence is declared.
  diagnostics<-c(
    python_initial_srvf_norm_min=min(norm_python),
    python_initial_srvf_norm_max=max(norm_python),
    r_unscaled_initial_srvf_norm_min=min(norm_r_unscaled),
    r_unscaled_initial_srvf_norm_max=max(norm_r_unscaled),
    r_scaled_initial_srvf_norm_min=min(norm_r_scaled),
    r_scaled_initial_srvf_norm_max=max(norm_r_scaled),
    source_q_scaled_rmse=rmse(k1$q,py$original_q),
    source_q_unscaled_rmse=rmse(k0$q,py$original_q),
    native_unscaled_warp_rmse=rmse(base$warping_functions,py$warp),
    native_scaled_warp_rmse=rmse(gamma1,py$warp),
    native_unscaled_mean_centered_rmse=rmse(
      cmean(base$mean_curve),cmean(py$mean)),
    native_scaled_mean_centered_rmse=rmse(
      cmean(k1$betamean),cmean(py$mean)),
    native_unscaled_reconstructed_aligned_rmse=rmse(
      centered(base$aligned$values),centered(py$aligned)),
    native_scaled_reconstructed_aligned_rmse=rmse(
      centered(aligned1),centered(py$aligned)),
    native_unscaled_original_coordinate_warp_rmse=rmse(
      centered(interpolate_original(base$warping_functions)),
      centered(py$aligned)),
    native_scaled_original_coordinate_warp_rmse=rmse(
      centered(interpolate_original(gamma1)),
      centered(py$aligned)),
    native_unscaled_score_distance_rmse=score_d_rmse(d_base),
    native_scaled_score_distance_rmse=score_d_rmse(d_scaled),
    native_unscaled_rescaled_score_distance_rmse=rel_score_rmse(d_base),
    native_scaled_rescaled_score_distance_rmse=rel_score_rmse(d_scaled),
    native_scaled_score_pair_distance_correlation=stats::cor(
      d_scaled,d_py))
  expect_true(all(is.finite(diagnostics)))
  cat("\nELASTIC_PYTHON12_NATIVE_R_NORMALIZATION_ABLATION\n")
  for(nm in names(diagnostics))
    cat(sprintf("  %s = %.12g\n",nm,diagnostics[[nm]]))
  cat("  source_numeric_parity_certified = FALSE\n")
})
