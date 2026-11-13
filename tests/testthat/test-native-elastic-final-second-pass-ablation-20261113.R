# Frozen Python 1.2 fdasrsf.fdacurve.srvf_align calls one more final
# DP registration to the *converged* Karcher mean, after karcher_mean.
# Native fdasrvf::multivariate_karcher_mean returns the last iterative
# registration; native fdasrvf::multiple_align_multivariate provides a
# genuine one-shot second pass against a supplied mean, without Python.
#
# This controlled real-Python, real-R comparison is an EXPERIMENT:
# production R source is not modified or declared numerically certified.
# Crucially, frozen Python shape_pca uses KARCHER-stage self.v (not the
# second-pass aligned qn), so post-alignment R tangent PCA must not be
# silently substituted into the production scores.

test_that("real frozen fdasrsf second SRVF alignment vs native R final mean registration",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_ELASTIC_TESTS"),"true"))
    skip("frozen Python and native R final DP SRVF alignment comparison is opt-in")
  skip_if_not_installed("fdasrvf",minimum_version="2.5.1")
  skip_if_not_installed("reticulate")
  expect_identical(et_python_version(),"1.2.0")
  n<-6L;nt<-25L
  time<-seq(0,1,length.out=nt)
  values<-array(NA_real_,dim=c(n,nt,2L))
  for(i in seq_len(n)){
    p<-time^(0.75+0.09*i)
    a<-1+0.07*cos(.72*i)
    values[i,,1L]<-a*(2*p-1)+.08*cos(i)*sin(2*pi*p)
    values[i,,2L]<-a*sin(2*pi*p)+.08*sin(i)*p
  }
  x<-etr_trajectory_set(time,values,
    curve_ids=paste0("e",seq_len(n)),
    dimension_names=c("x","y"),coordinate_system="pixels",
    time_unit="ms",
    provenance=list(source="real_python_final_alignment_ablation"))
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
from joblib import parallel_config
pass_t=np.linspace(0,1,25)
pass_ys=[]
for i in range(1,7):
    p=pass_t**(0.75+0.09*i)
    a=1+0.07*np.cos(.72*i)
    xx=a*(2*p-1)+.08*np.cos(i)*np.sin(2*np.pi*p)
    yy=a*np.sin(2*np.pi*p)+.08*np.sin(i)*p
    pass_ys.append(np.stack((xx,yy),axis=-1))
pass_values=np.stack(pass_ys,axis=0)
pass_input=et.TrajectorySet(
  time=pass_t,values=pass_values,
  curve_ids=tuple('e'+str(i) for i in range(1,7)),
  dimension_names=('x','y'),
  coordinate_system='pixels',time_unit='ms')
with parallel_config(backend='threading'):
    pass_fit=et.fit_elastic_fpca(
      pass_input,n_components=2,rotation=False,
      scale_curves=False,lam=0.,method='DP')
pass_obj=pass_fit.backend_object
pass_oracle={
  'input':np.asarray(pass_values),
  'aligned':np.asarray(pass_fit.aligned.values),
  'warps':np.asarray(pass_fit.warping_functions),
  'qmean':np.asarray(pass_obj.q_mean),
  'qn':np.asarray(pass_obj.qn),
  'mean':np.asarray(pass_fit.mean_curve),
  'scores':np.asarray(pass_fit.scores)}
")
  py<-reticulate::py_eval("pass_oracle",convert=TRUE)
  expect_equal(values,py$input,tolerance=1e-12)
  beta<-aperm(values,c(3L,2L,1L))
  native<-etr_fit_elastic_fpca(x,n_components=2L,
    rotation=FALSE,scale_curves=FALSE,lam=0,
    method="DP",strict_source_record=TRUE)
  km<-native$native_backend_object
  # The public exported R function aligns once against a specified mean,
  # independent of the mean-estimation iteration. Internal q is normalized.
  second<-fdasrvf::multiple_align_multivariate(
    beta=beta,mu=km$betamean,
    mode="O",alignment=TRUE,rotation=FALSE,
    scale=TRUE,lambda=0,ncores=1L,verbose=FALSE)
  expect_s3_class(second,"fdacurve")
  expect_identical(dim(second$gamma),c(nt,n))
  expect_identical(dim(second$qn),c(2L,nt,n))
  expect_identical(dim(second$R),c(2L,2L,n))
  expect_identical(dim(py$warps),c(n,nt))
  expect_identical(dim(py$qn),c(2L,nt,n))
  expect_identical(dim(py$qmean),c(2L,nt))
  expect_true(all(is.finite(second$gamma)))
  expect_true(all(is.finite(second$qn)))
  expect_true(all(vapply(seq_len(n),function(i)
    all(diff(second$gamma[,i])>=-1e-5),logical(1L))))
  g_second<-t(second$gamma)
  expect_true(all(g_second>=-1e-5 & g_second<=1+1e-5))
  aligned_second<-.etr_elastic_source_original_coordinate_align(
    beta,second$gamma,second$R,apply_rotation=FALSE)
  expect_identical(dim(aligned_second),c(n,nt,2L))
  expect_true(all(is.finite(aligned_second)))
  center<-function(v){
    for(i in seq_len(dim(v)[1L]))
      for(j in seq_len(dim(v)[3L]))
        v[i,,j]<-v[i,,j]-mean(v[i,,j])
    v
  }
  cm<-function(v)sweep(v,1L,rowMeans(v),"-")
  rmse<-function(a,b)sqrt(mean((a-b)^2))
  before_warp<-native$warping_functions
  after_warp<-g_second
  before_aligned<-center(native$aligned$values)
  after_aligned<-center(aligned_second)
  py_aligned<-center(py$aligned)
  observed<-c(
    r_karcher_vs_python_final_mean_q_rmse=rmse(km$mu,py$qmean),
    r_first_pass_vs_python_warp_rmse=rmse(before_warp,py$warps),
    r_second_pass_vs_python_warp_rmse=rmse(after_warp,py$warps),
    r_first_pass_vs_python_warp_max=max(abs(before_warp-py$warps)),
    r_second_pass_vs_python_warp_max=max(abs(after_warp-py$warps)),
    r_first_vs_second_warp_rmse=rmse(before_warp,after_warp),
    r_first_pass_vs_python_aligned_centered_rmse=rmse(
      before_aligned,py_aligned),
    r_second_pass_vs_python_aligned_centered_rmse=rmse(
      after_aligned,py_aligned),
    r_first_pass_vs_python_aligned_q_rmse=rmse(km$qn,py$qn),
    r_second_pass_vs_python_aligned_q_rmse=rmse(second$qn,py$qn),
    r_second_pass_mean_q_vs_python_rmse=rmse(second$mu,py$qmean),
    r_second_pass_mean_curve_vs_python_centered_rmse=rmse(
      cm(second$betamean),cm(py$mean)))
  expect_identical(length(observed),12L)
  expect_true(all(is.finite(observed)))
  expect_true(all(observed>=0))
  per_curve_first<-sqrt(rowMeans((before_warp-py$warps)^2))
  per_curve_second<-sqrt(rowMeans((after_warp-py$warps)^2))
  expect_identical(length(per_curve_first),n)
  expect_identical(length(per_curve_second),n)
  cat("\nELASTIC_PYTHON12_NATIVE_R_FINAL_ALIGNMENT_ABLATION\n")
  for(label in names(observed))
    cat(sprintf("  %s = %.12g\n",label,observed[[label]]))
  cat("  per_curve_first_warp_rmse = ",
    paste(sprintf("%.10g",per_curve_first),collapse=", "),"\n",sep="")
  cat("  per_curve_second_warp_rmse = ",
    paste(sprintf("%.10g",per_curve_second),collapse=", "),"\n",sep="")
  cat("  python_pca_scores_remain_karcher_stage = TRUE\n")
  cat("  source_numeric_parity_certified = FALSE\n")
})
