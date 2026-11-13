# Frozen 1.2 elastic.py::fit_elastic_fpca; true native R fdasrvf
# Karcher/DP source-scientific approach, not Python object identity.
# Current CRAN native fdasrvf 2.5.1, independent reference Python
# jdtuck/fdasrsf_python fda curve_stats.py karcher_mean,
# srvf_align and shape_pca.

.etr_elastic_native_phase_fixture<-function(n=7L,m=29L){
  time<-seq(0,1,length.out=m)
  v<-array(NA_real_,dim=c(n,m,2L))
  for(i in seq_len(n)){
    ph<-time^(0.75+0.09*i)
    amp<-1+0.07*cos(.72*i)
    v[i,,1L]<-amp*(2*ph-1)+.08*cos(i)*sin(2*pi*ph)
    v[i,,2L]<-amp*sin(2*pi*ph)+.08*sin(i)*ph
  }
  meta<-data.frame(subject=paste0("subject_",seq_len(n)),
    treatment=rep(c("A","B"),length.out=n),
    stringsAsFactors=FALSE)
  etr_trajectory_set(time,v,
    curve_ids=paste0("e",seq_len(n)),
    dimension_names=c("x","y"),
    metadata=meta,coordinate_system="pixels",time_unit="ms",
    provenance=list(source="phase_perturbed_elastic_fixture"))
}

test_that("historical native R SRVF identity-only behavior remains unchanged and true DP is opt-in",{
  x<-.etr_elastic_native_phase_fixture()
  z<-etr_fit_elastic_fpca(x,n_components=2L)
  expect_s3_class(z,"etr_unregistered_srvf_fpca")
  expect_false(z$phase_amplitude_separated)
  expect_identical(z$aligned$values,x$values)
  expect_true(all(vapply(seq_len(dim(x$values)[1L]),
    function(i)isTRUE(all.equal(z$warping_functions[i,],x$time)),
    logical(1L))))
  expect_error(etr_fit_elastic_fpca(x,n_components=2L,method="DP"),
    "fdasrsf")
  expect_error(etr_fit_elastic_fpca(x,n_components=2L,
    rotation=TRUE),"fdasrsf")
  expect_error(etr_fit_elastic_fpca(x,n_components=2L,
    strict_source_record=NA),"strict_source_record")
  expect_error(etr_fit_elastic_fpca(x,n_components=2L,
    strict_source_record=TRUE),
    "method='DP'")
})

test_that("native R fdasrvf performs genuine elastic Karcher DP alignment and tangent-space geodesic PCA",{
  skip_if_not_installed("fdasrvf",minimum_version="2.5.1")
  x<-.etr_elastic_native_phase_fixture()
  before<-reticulate::py_available(initialize=FALSE)
  got<-etr_fit_elastic_fpca(x,n_components=2L,
    method="DP",strict_source_record=TRUE)
  expect_identical(reticulate::py_available(initialize=FALSE),before)
  expect_s3_class(got,"etr_native_elastic_karcher_pca_scientific_record")
  expect_s3_class(got$native_backend_object,"fdacurve")
  expect_s3_class(got$native_pca_object,"curve_pca")
  expect_identical(dim(got$native_srvf_reconstructed_aligned_curves),
    c(7L,29L,2L))
  expect_true(got$provenance$registration$source_input_srvfs_normalized)
  expect_true(got$provenance$registration$native_original_coordinate_alignment)
  expect_true(all(is.finite(got$native_srvf_reconstructed_aligned_curves)))
  qnorm<-vapply(seq_len(7L),function(i)
    sqrt(mean(colSums(got$source_original_srvfs[,,i]^2))),
    numeric(1L))
  expect_equal(qnorm,rep(1,7L),tolerance=1e-9)
  # A different, original-coordinate reparameterization now returns
  # source-appropriate curve amplitude, not q_to_curve normalized length.
  for(i in seq_len(7L)){
    b<-aperm(x$values,c(3L,2L,1L))[,,i]
    orig_centered<-.etr_elastic_source_center_open_curve(b)
    for(j in seq_len(2L)){
      expected<-stats::approx(
        seq(0,1,length.out=29L),orig_centered[j,],
        xout=got$warping_functions[i,],ties="ordered",rule=2)$y
      expect_equal(got$aligned$values[i,,j],expected,tolerance=1e-9)
    }
  }
  expect_identical(got$backend,"native_fdasrvf")
  expect_null(got$backend_object)
  expect_false(got$source_python_backend_object_identity)
  expect_false(got$source_equivalent)
  expect_false(got$source_full_numeric_parity_certified)
  expect_false(got$independently_source_certified)
  expect_identical(dim(got$aligned$values),c(7L,29L,2L))
  expect_identical(dim(got$warping_functions),c(7L,29L))
  expect_identical(dim(got$scores),c(7L,2L))
  expect_identical(dim(got$principal_directions),c(2L,29L,2L,10L))
  expect_identical(dim(got$mean_curve),c(2L,29L))
  expect_identical(dim(got$source_shooting_vectors),c(2L,29L,7L))
  expect_identical(dim(got$source_aligned_srvfs),c(2L,29L,7L))
  expect_true(all(is.finite(got$aligned$values)))
  expect_true(all(is.finite(got$principal_directions)))
  expect_true(all(is.finite(got$scores)))
  expect_true(all(is.finite(got$warping_functions)))
  expect_true(all(is.finite(got$mean_curve)))
  expect_true(all(got$warping_functions>=-1e-5))
  expect_true(all(got$warping_functions<=1+1e-5))
  # An actual phase-varying fixture must not silently return the old
  # scientific alternative with entirely identity warps.
  identity<-matrix(rep(x$time,each=7L),nrow=7L,ncol=29L)
  expect_gt(max(abs(got$warping_functions-identity)),1e-5)
  expect_true(all(vapply(seq_len(7L),function(i)
    all(diff(got$warping_functions[i,])>=-1e-5),logical(1L))))
  expect_equal(got$warping_functions[,1L],rep(0,7L),tolerance=1e-4)
  expect_equal(got$warping_functions[,29L],rep(1,7L),tolerance=1e-4)
  expect_identical(got$source_pca_geodesic_sigma,
    seq(-2,2.5,by=.5))
  expect_equal(got$scores,
    t(got$native_pca_object$coef[1:2,,drop=FALSE]),
    tolerance=0,ignore_attr=TRUE)
  expect_identical(got$source_karcher_optimization,
    "native_fdasrvf_Karcher_medoid_DP")
  expect_identical(got$source_phase_warp_method,
    "true_native_R_elastic_DP_not_identity")
  expect_true(got$provenance$phase_amplitude_separated)
  expect_true(grepl("Warping changes traversal timing",
    got$provenance$timing_warning))
  expect_identical(got$provenance$registration$method,"DP")
  expect_identical(got$provenance$registration$rotation,FALSE)
  expect_identical(got$provenance$registration$scale_curves,FALSE)
  expect_identical(got$provenance$registration$backend,
    "fdasrvf_native_R")
  expect_identical(got$aligned$curve_ids,x$curve_ids)
  expect_identical(got$aligned$dimension_names,x$dimension_names)
  expect_identical(got$aligned$metadata,x$metadata)
  expect_identical(got$aligned$time,x$time)
  expect_identical(got$aligned$time_unit,x$time_unit)
  expect_identical(got$aligned$coordinate_system,x$coordinate_system)
  expect_identical(got$aligned$provenance$source,
    "phase_perturbed_elastic_fixture")
  expect_identical(got$aligned$provenance$elastic_registration$backend,
    "fdasrvf_native_R")
  expect_false("elastic_registration"%in%names(x$provenance))
})

test_that("native fdasrvf source Karcher supports single principal component and rotated/scaled elastic geometry",{
  skip_if_not_installed("fdasrvf",minimum_version="2.5.1")
  x<-.etr_elastic_native_phase_fixture(n=6L,m=25L)
  got<-etr_fit_elastic_fpca(x,n_components=1L,
    rotation=TRUE,scale_curves=TRUE,lam=0,
    method="DP",strict_source_record=TRUE)
  expect_s3_class(got,"etr_native_elastic_karcher_pca_scientific_record")
  expect_identical(dim(got$scores),c(6L,1L))
  expect_identical(dim(got$principal_directions),c(2L,25L,1L,10L))
  expect_identical(dim(got$warping_functions),c(6L,25L))
  expect_true(all(is.finite(got$aligned$values)))
  expect_true(got$provenance$registration$source_input_srvfs_normalized)
  expect_identical(got$provenance$registration$rotation,TRUE)
  expect_identical(got$provenance$registration$scale_curves,TRUE)
  expect_true(all(is.finite(got$scores)))
  expect_true(all(is.finite(got$principal_directions)))
  expect_null(got$backend_object)
  expect_false(got$source_equivalent)
})

test_that("native elastic source explicitly rejects unreviewed method, warping and rank domains",{
  x<-.etr_elastic_native_phase_fixture(n=6L,m=25L)
  fit<-function(...){
    kwargs<-utils::modifyList(
      list(trajectories=x,n_components=2L,
        method="DP",strict_source_record=TRUE),
      list(...))
    do.call(etr_fit_elastic_fpca,kwargs)
  }
  expect_error(fit(method="RBFGS"),"DP.*only")
  expect_error(fit(method="identity_only"),"DP.*only")
  expect_error(fit(lam=-1),"lambda")
  expect_error(fit(lam=Inf),"lambda")
  expect_error(fit(rotation=NA),"rotation")
  expect_error(fit(scale_curves=NA),"scale_curves")
  expect_error(fit(n_components=0),"n_components")
  expect_error(fit(n_components=6),"n_components")
  bad<-x
  bad$values[1L,3L,1L]<-NA_real_
  expect_error(etr_fit_elastic_fpca(bad,n_components=2L,
    method="DP",strict_source_record=TRUE),
    "complete")
})

test_that("frozen real Python 1.2 public fdasrsf elastic contract vs true native R elastic shape and phase domains",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_ELASTIC_TESTS"),"true"))
    skip("frozen fdasrsf >=2.7 Python public differential requires explicit opt-in")
  skip_if_not_installed("fdasrvf",minimum_version="2.5.1")
  skip_if_not_installed("reticulate")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
import fdasrsf as fs
# fdasrsf 2.7 still calls joblib.Parallel(n_jobs=-1), even with
# karcher_mean(parallel=False) and srvf_align(parallel=False).
# In an embedded Windows R/reticulate session loky child processes may fail
# with WinError 6 (invalid standard handle). Threads avoid process spawning;
# this does not replace or mock the frozen Python SRVF/DP solver.
from joblib import parallel_config
T=np.linspace(0,1,25)
ys=[]
for i in range(1,7):
    p=T**(0.75+0.09*i)
    a=1+0.07*np.cos(.72*i)
    xx=a*(2*p-1)+.08*np.cos(i)*np.sin(2*np.pi*p)
    yy=a*np.sin(2*np.pi*p)+.08*np.sin(i)*p
    ys.append(np.stack((xx,yy),axis=-1))
vals=np.stack(ys,axis=0)
py_tr=et.TrajectorySet(
  time=T,values=vals,
  curve_ids=tuple('e'+str(i) for i in range(1,7)),
  dimension_names=('x','y'),
  coordinate_system='pixels',time_unit='ms',
  provenance={'source':'phase_perturbed_elastic_fixture'})
with parallel_config(backend='threading'):
    py_fit=et.fit_elastic_fpca(py_tr,n_components=2,
      rotation=False,scale_curves=False,lam=0.,method='DP')
assert py_fit.backend=='fdasrsf'
assert py_fit.backend_object is not None
py_elastic={
  'aligned':np.asarray(py_fit.aligned.values),
  'warps':np.asarray(py_fit.warping_functions),
  'scores':np.asarray(py_fit.scores),
  'input_q':np.asarray(py_fit.backend_object.q),
  'principal':np.asarray(py_fit.principal_directions),
  'mean':np.asarray(py_fit.mean_curve),
  'time':np.asarray(py_fit.aligned.time),
  'curve_ids':list(py_fit.aligned.curve_ids)}
")
  py<-reticulate::py_eval("py_elastic",convert=TRUE)
  fx<-.etr_elastic_native_phase_fixture(n=6L,m=25L)
  r<-etr_fit_elastic_fpca(fx,n_components=2L,
    rotation=FALSE,scale_curves=FALSE,lam=0,
    method="DP",strict_source_record=TRUE)
  # Invariant source scientific schema/shape. Native fdasrvf and
  # Python fdasrsf use different Karcher seed and aligned-curve
  # reconstructions, so numeric equality of actual samples, phase
  # warps or PCA score signs is NOT falsely asserted here.
  expect_identical(dim(r$aligned$values),dim(as.array(py$aligned)))
  expect_identical(dim(r$warping_functions),dim(as.matrix(py$warps)))
  expect_identical(dim(r$scores),dim(as.matrix(py$scores)))
  expect_identical(dim(r$source_original_srvfs),dim(as.array(py$input_q)))
  # This is a genuinely source-equal mathematical primitive on the
  # tested fixture; not equality of Karcher, phase or final PCA.
  expect_lt(sqrt(mean((r$source_original_srvfs-py$input_q)^2)),1e-10)
  expect_identical(dim(r$principal_directions),dim(as.array(py$principal)))
  expect_identical(dim(r$mean_curve),dim(as.matrix(py$mean)))
  expect_equal(r$aligned$time,as.numeric(py$time),tolerance=0)
  expect_identical(r$aligned$curve_ids,as.character(py$curve_ids))
  expect_true(all(is.finite(r$aligned$values)))
  expect_true(all(is.finite(r$warping_functions)))
  expect_true(all(is.finite(py$warps)))
  expect_true(all(is.finite(py$scores)))
  expect_false(r$source_equivalent)
  expect_false(r$source_full_numeric_parity_certified)
  expect_false(r$independently_source_certified)
  # Quantitative DIFFERENTIAL DIAGNOSTICS, not numerical parity assertions:
  # native fdasrvf uses a Karcher medoid and R tangent PCA, while frozen
  # Python fdasrsf uses the first curve as its mean seed and a different
  # aligned-curve reconstruction. No unvalidated shared-value tolerance.
  py_warp<-as.matrix(py$warps)
  py_aligned<-as.array(py$aligned)
  py_mean<-as.matrix(py$mean)
  py_scores<-as.matrix(py$scores)
  expect_true(all(is.finite(py_aligned)))
  expect_true(all(is.finite(py_mean)))
  expect_true(all(is.finite(py$principal)))
  expect_true(all(py_warp>=-1e-5 & py_warp<=1+1e-5))
  expect_true(all(vapply(seq_len(nrow(py_warp)),function(i)
    all(diff(py_warp[i,])>=-1e-5),logical(1L))))
  center_trajectories<-function(v){
    for(i in seq_len(dim(v)[1L]))
      for(j in seq_len(dim(v)[3L]))
        v[i,,j]<-v[i,,j]-mean(v[i,,j])
    v
  }
  center_mean<-function(m)
    sweep(m,1L,rowMeans(m),"-")
  rmse<-function(a,b)sqrt(mean((a-b)^2))
  # Score-pair distances are invariant to simultaneous sign flips,
  # rotations and component permutations within the retained subspace.
  score_distance_rmse<-rmse(
    as.numeric(stats::dist(r$scores)),
    as.numeric(stats::dist(py_scores)))
  comparisons<-c(
    warp_rmse=rmse(r$warping_functions,py_warp),
    warp_max_abs=max(abs(r$warping_functions-py_warp)),
    aligned_centered_rmse=rmse(
      center_trajectories(r$aligned$values),
      center_trajectories(py_aligned)),
    karcher_mean_centered_rmse=rmse(
      center_mean(r$mean_curve),
      center_mean(py_mean)),
    score_pairwise_distance_rmse=score_distance_rmse)
  expect_identical(length(comparisons),5L)
  expect_true(all(is.finite(comparisons)))
  expect_true(all(comparisons>=0))
  # Emit values in the actual local test logs for later scientific audit.
  # The values are DESCRIPTIVE. Distinct optimizers are not certified
  # source-numerically equivalent by existence or small magnitudes alone.
  cat("\nELASTIC_PYTHON12_NATIVE_R_DIFFERENTIAL_NUMERICAL_AUDIT\n")
  for(nm in names(comparisons))
    cat(sprintf("  %s = %.12g\n",nm,comparisons[[nm]]))
  cat("  numerical_parity_certified = FALSE\n")
  # Diagnostic decomposition: report whether differences are dominated by
  # a single trajectory, mean alignment scale or the PCA score scale.
  # These are unqualified measurements, not post-hoc acceptance tolerances.
  ncurves<-dim(fx$values)[1L]
  identity_gamma<-matrix(rep(fx$time,each=ncurves),nrow=ncurves)
  r_centered<-center_trajectories(r$aligned$values)
  py_centered<-center_trajectories(py_aligned)
  individual_warp_rmse<-sqrt(rowMeans(
    (r$warping_functions-py_warp)^2))
  individual_curve_rmse<-sqrt(rowMeans(matrix(
    (r_centered-py_centered)^2,nrow=ncurves)))
  r_score_dist<-as.numeric(stats::dist(r$scores))
  py_score_dist<-as.numeric(stats::dist(py_scores))
  score_scale_factor<-sum(r_score_dist*py_score_dist)/
    sum(r_score_dist^2)
  diagnostics<-c(
    python_warp_deformation_rmse=rmse(py_warp,identity_gamma),
    r_warp_deformation_rmse=rmse(r$warping_functions,identity_gamma),
    input_centered_coordinate_rms=sqrt(mean(
      center_trajectories(fx$values)^2)),
    python_aligned_centered_coordinate_rms=sqrt(mean(py_centered^2)),
    python_mean_centered_coordinate_rms=sqrt(mean(
      center_mean(py_mean)^2)),
    python_score_pair_distance_rms=sqrt(mean(py_score_dist^2)),
    optimally_rescaled_r_score_distance_factor=score_scale_factor,
    optimally_rescaled_score_pair_distance_rmse=rmse(
      score_scale_factor*r_score_dist,py_score_dist),
    score_pairwise_distance_correlation=stats::cor(
      r_score_dist,py_score_dist))
  expect_identical(length(individual_warp_rmse),ncurves)
  expect_identical(length(individual_curve_rmse),ncurves)
  expect_true(all(is.finite(individual_warp_rmse)))
  expect_true(all(is.finite(individual_curve_rmse)))
  expect_true(all(is.finite(diagnostics)))
  expect_true(all(diagnostics[names(diagnostics)!=
    "score_pairwise_distance_correlation"]>=0))
  cat("ELASTIC_PYTHON12_NATIVE_R_DIFFERENTIAL_DECOMPOSITION\n")
  for(nm in names(diagnostics))
    cat(sprintf("  %s = %.12g\n",nm,diagnostics[[nm]]))
  cat("  per_curve_warp_rmse = ",
    paste(sprintf("%.10g",individual_warp_rmse),collapse=", "), "\n",sep="")
  cat("  per_curve_aligned_centered_rmse = ",
    paste(sprintf("%.10g",individual_curve_rmse),collapse=", "),
    "\n",sep="")
  cat("  independently_numeric_parity_certified = FALSE\n")
})
