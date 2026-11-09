test_that("paired sparse joint covariance is estimated without marginal fdapace",{
  tr<-.etr_spnm_fixture()
  args<-.etr_spnm_args()
  fit<-do.call(etr_fit_sparse_mfpca_native,c(
    list(trajectories=tr),args))
  expect_s3_class(fit,"etr_sparse_mfpca_source")
  expect_identical(fit$fit_method,"direct_sparse_block_covariance")
  expect_identical(fit$score_method,"joint_PACE")
  expect_identical(dim(fit$eigenfunctions),c(2L,9L,2L))
  expect_identical(dim(fit$mean),c(9L,2L))
  expect_identical(dim(fit$scores),c(24L,2L))
  expect_true(all(is.finite(fit$scores)))
  expect_true(all(fit$eigenvalues>0))
  expect_equal(fit$smoothed_cyx,t(fit$smoothed_cxy),
    tolerance=1e-12)
  expect_equal(fit$covariance_cyx,t(fit$covariance_cxy),
    tolerance=1e-12)
  expect_true(any(abs(fit$covariance_cxy)>1e-8))
  expect_true(all(fit$covariance_support_counts$cxy>=6L))
  retained<-vapply(tr$time,function(t)
    sum(t>=.08&t<=.92),integer(1L))
  expect_identical(fit$covariance_pair_counts$xy,
    sum(retained*(retained-1L)))
  expect_equal(sum(fit$quadrature_weights),.84,tolerance=1e-12)
  expect_false(fit$provenance$sparse_mfpca$
    rank_k_covariance_used_for_scoring)
  expect_false(fit$provenance$sparse_mfpca$
    raw_sparse_trajectory_interpolation_performed)
  expect_false(fit$independently_fully_certified)
  fit_mapped<-do.call(etr_fit_sparse_mfpca,
    c(list(trajectories=tr,backend="native_covariance"),args))
  expect_equal(fit$scores,fit_mapped$scores,
    tolerance=1e-12,ignore_attr=TRUE)
  config<-c(list(backend="native_covariance"),args)
  wf<-etr_run_sparse_mfpca_workflow(tr,config)
  expect_s3_class(wf,"etr_native_sparse_mfpca_workflow")
  expect_identical(wf$workflow_contract,
    "sparse_mfpca:native_direct_block_covariance_PACE")
  expect_false(wf$provenance$source_full_domain_certified)
  expect_equal(wf$fit$eigenvalues,fit$eigenvalues,tolerance=1e-12)
})

test_that("joint sparse covariance fails closed on unsupported sample/error mode",{
  tr<-.etr_spnm_fixture()
  args<-.etr_spnm_args()
  bad<-tr
  bad$values[[1L]][1L,1L]<-NA_real_
  expect_error(do.call(etr_fit_sparse_mfpca_native,
    c(list(trajectories=bad),args)),
    "coordinate_specific_missingness_unsupported")
  bad<-tr;bad$values[[1L]][1L,]<-NA_real_
  expect_error(do.call(etr_fit_sparse_mfpca_native,
    c(list(trajectories=bad),args)),
    "nonfinite_sparse_planar_observation")
  invalid<-args
  invalid$measurement_error_variance<-c(.08,-.10)
  expect_error(do.call(etr_fit_sparse_mfpca_native,
    c(list(trajectories=tr),invalid)),
    "invalid_measurement_error_covariance")
  invalid<-args
  invalid$measurement_error<-"fixed_matrix"
  invalid$measurement_error_variance<-NULL
  invalid$measurement_error_covariance<-matrix(c(1,2,2,1),2L)
  expect_error(do.call(etr_fit_sparse_mfpca_native,
    c(list(trajectories=tr),invalid)),
    "invalid_measurement_error_covariance")
  invalid<-args;invalid$analysis_support_action<-"error"
  expect_error(do.call(etr_fit_sparse_mfpca_native,
    c(list(trajectories=tr),invalid)),
    "observations_outside_analysis_support")
})

test_that("native joint sparse PACE numerical population arrays agree with public Python 1.2",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 source differential opt-in")
  expect_identical(et_python_version(),"1.2.0")
  tr<-.etr_spnm_fixture();args<-.etr_spnm_args()
  native<-do.call(etr_fit_sparse_mfpca_native,
    c(list(trajectories=tr),args))
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as _etr_spnm
def _etr_spnm_input(times,values,ids):
    return _etr_spnm.IrregularTrajectorySet(
      time=tuple(np.asarray(x,dtype=float) for x in times),
      values=tuple(np.asarray(x,dtype=float) for x in values),
      curve_ids=tuple(str(x) for x in ids),
      dimension_names=('x','y'),
      coordinate_system='degrees',time_unit='s')
")
  pytr<-reticulate::py_call(
    reticulate::py_eval("_etr_spnm_input",convert=FALSE),
    times=reticulate::r_to_py(tr$time),
    values=reticulate::r_to_py(tr$values),
    ids=reticulate::r_to_py(tr$curve_ids))
  pyargs<-args
  pyargs$dimensions<-reticulate::tuple("x","y")
  pyargs$measurement_error_variance<-reticulate::tuple(.08,.10)
  pyargs$evaluation_grid<-reticulate::r_to_py(
    pyargs$evaluation_grid)
  result<-do.call(reticulate::py_call,c(list(
    etpy_get_export("fit_sparse_mfpca"),
    trajectories=pytr),pyargs))
  get<-function(name)et_to_r(reticulate::py_get_attr(result,name))
  for(field in c("mean","eigenvalues","eigenfunctions","scores",
      "smoothed_cxx","smoothed_cxy","smoothed_cyx","smoothed_cyy",
      "covariance_cxx","covariance_cxy","covariance_cyx",
      "covariance_cyy","quadrature_weights",
      "measurement_error_covariance","mean_support_counts")){
    expect_equal(unname(native[[field]]),unname(get(field)),
      tolerance=3e-6,ignore_attr=TRUE,
      info=paste("frozen direct joint sparse",field))
  }
  for(field in c("cxx","cxy","cyy")){
    source_support<-et_to_r(reticulate::py_get_item(
      reticulate::py_get_attr(result,"covariance_support_counts"),
      field))
    expect_equal(native$covariance_support_counts[[field]],
      source_support,ignore_attr=TRUE,
      info=paste("joint support counts",field))
  }
})
