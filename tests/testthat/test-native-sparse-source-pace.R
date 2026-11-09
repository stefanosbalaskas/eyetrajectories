test_that("native sparse PACE fits a local covariance and conditions on full operator",{
  x<-.etr_spn_source_fixture()
  f<-.etr_spn_fit_from_fixture(x)
  expect_s3_class(f,"etr_sparse_fpca_native")
  expect_identical(f$fit_method,"native_covariance")
  expect_identical(f$score_method,"PACE")
  expect_identical(dim(f$scores),c(24L,1L))
  expect_identical(dim(f$covariance),c(9L,9L))
  expect_identical(dim(f$eigenfunctions),c(1L,9L))
  expect_equal(f$covariance,t(f$covariance),tolerance=1e-10)
  expect_true(all(is.finite(f$scores)))
  expect_true(all(is.finite(f$eigenvalues)))
  expect_true(all(f$eigenvalues>0))
  expect_true(all(is.finite(f$mean)))
  expect_true(all(f$mean_support_counts>=3L))
  expect_true(all(f$covariance_support_counts>=6L))
  expect_equal(sum(f$quadrature_weights),.92-.08,tolerance=1e-12)
  expect_equal(sum(f$eigenfunctions[1L,]^2*f$quadrature_weights),
    1,tolerance=1e-8)
  expect_false(f$provenance$sparse_fpca$
    raw_sparse_trajectory_interpolation_performed)
  expect_false(f$independent_full_source_certified)
  u<-etr_sparse_fpca_score_uncertainty_native(f,x)
  expect_identical(dim(u$covariance),c(24L,1L,1L))
  expect_identical(dim(u$standard_errors),c(24L,1L))
  expect_true(all(is.finite(u$standard_errors)))
  expect_true(all(u$standard_errors>=0))
  expect_true(all(u$covariance>= -1e-9))
  frame<-etr_sparse_fpca_score_uncertainty_frame_native(u)
  expect_equal(nrow(frame),24L)
  expect_identical(names(frame),c("curve_id","component",
    "conditional_variance","conditional_standard_error",
    "status_code","condition_number","method"))
  expect_identical(frame$curve_id,x$curve_ids)
  expect_identical(frame$component,rep(1L,24L))
})

test_that("source sparse FPCA guards unsupported estimators and source support",{
  x<-.etr_spn_source_fixture()
  f<-.etr_spn_fit_from_fixture(x)
  expect_error(etr_fit_sparse_fpca_native(
    x,"signal",1L,seq(.08,.92,length.out=9L),
    .5,.85,noise_variance_method="diagonal_difference"),
    "diagonal_difference")
  expect_error(etr_fit_sparse_fpca_native(
    x,"signal",1L,seq(.08,.92,length.out=9L),
    .5,.85,noise_variance_method="fixed",
    measurement_error_variance=-1),
    "measurement_error_variance")
  expect_error(etr_fit_sparse_fpca_native(
    x,"signal",1L,seq(.08,.92,length.out=9L),
    .5,.85,noise_variance_method="fixed",
    measurement_error_variance=.07,
    analysis_support_action="error"),
    "observations_outside_analysis_support")
  other<-x;other$curve_ids<-rev(other$curve_ids)
  expect_error(etr_sparse_fpca_score_uncertainty_native(f,other),
    "curve IDs")
  expect_error(etr_sparse_fpca_score_uncertainty_native(f,x,
    condition_limit=1),"condition_limit")
})

test_that("native sparse source PACE and score uncertainty match pinned Python arrays",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 direct sparse numerical oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_spn_source_fixture()
  nr<-.etr_spn_fit_from_fixture(x)
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as _etr_spn_et
import importlib
_etr_spn_module=importlib.import_module('eyetrajectoriespy.sparse_score_uncertainty')
def _etr_spn_build_irregular(times, values, ids):
    return _etr_spn_et.IrregularTrajectorySet(
        time=tuple(np.asarray(t,dtype=float) for t in times),
        values=tuple(np.asarray(v,dtype=float) for v in values),
        curve_ids=tuple(str(i) for i in ids),
        dimension_names=('signal',),
        coordinate_system='degrees',time_unit='s')
")
  py<-reticulate::py_call(
    reticulate::py_eval("_etr_spn_build_irregular",convert=FALSE),
    times=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    ids=reticulate::r_to_py(x$curve_ids))
  pyfit<-reticulate::py_call(
    etpy_get_export("fit_sparse_fpca"),
    trajectories=py,
    dimension="signal",n_components=1L,
    evaluation_grid=reticulate::r_to_py(seq(.08,.92,length.out=9L)),
    mean_bandwidth=.50,covariance_bandwidth=.85,
    noise_variance_method="fixed",measurement_error_variance=.07,
    analysis_support_action="restrict",psd_action="project",
    score_ridge=.002,score_condition_limit=1e12,
    mean_min_local_points=3L,covariance_min_local_pairs=6L)
  get<-function(object,name)
    et_to_r(reticulate::py_get_attr(object,name))
  for(field in c("mean","covariance","eigenvalues",
      "eigenfunctions","scores","quadrature_weights",
      "mean_support_counts","covariance_support_counts")){
    expect_equal(unname(nr[[field]]),unname(get(pyfit,field)),
      tolerance=2e-6,ignore_attr=TRUE,
      info=paste("frozen sparse FPCA",field))
  }
  nrposterior<-etr_sparse_fpca_score_uncertainty_native(nr,x)
  pyposterior<-reticulate::py_call(
    reticulate::py_get_attr(
      reticulate::py_eval("_etr_spn_module",convert=FALSE),
      "sparse_fpca_score_uncertainty"),
    fit=pyfit,trajectories=py)
  for(field in c("covariance","standard_errors")){
    expect_equal(unname(nrposterior[[field]]),
      unname(get(pyposterior,field)),tolerance=2e-6,
      ignore_attr=TRUE,info=paste("source sparse posterior",field))
  }
  source_frame<-reticulate::py_call(
    reticulate::py_get_attr(
      reticulate::py_eval("_etr_spn_module",convert=FALSE),
      "sparse_fpca_score_uncertainty_frame"),
    result=pyposterior)
  native_frame<-etr_sparse_fpca_score_uncertainty_frame_native(nrposterior)
  pyframe<-et_to_r(source_frame)
  for(field in names(native_frame)){
    if(is.numeric(native_frame[[field]])){
      expect_equal(native_frame[[field]],pyframe[[field]],
        tolerance=2e-6,ignore_attr=TRUE,
        info=paste("source sparse uncertainty frame",field))
    }else expect_identical(
      as.character(native_frame[[field]]),
      as.character(pyframe[[field]]))
  }
})

test_that("source-model sparse workflow uses actual custom native PACE",{
  x<-.etr_spn_source_fixture()
  config<-list(
    backend="native_covariance",dimension="signal",
    n_components=1L,evaluation_grid=seq(.08,.92,length.out=9L),
    mean_bandwidth=.50,covariance_bandwidth=.85,
    noise_variance_method="fixed",
    measurement_error_variance=.07,
    analysis_support_action="restrict",psd_action="project",
    score_ridge=.002)
  w<-etr_run_sparse_fpca_workflow(x,config)
  expect_s3_class(w,"etr_sparse_fpca_workflow")
  expect_s3_class(w$fit,"etr_sparse_fpca_native")
  expect_identical(w$workflow_contract,
    "sparse_fpca:native_local_linear_fixed_noise")
  expect_false(w$provenance$fdapace_backend_used)
  expect_false(w$provenance$full_source_contract_certified)
  expect_identical(nrow(w$tables$scores),24L)
  expect_equal(w$fit$scores,.etr_spn_fit_from_fixture(x)$scores,
    tolerance=1e-10,ignore_attr=TRUE)
  config$backend<-"unsupported"
  expect_error(etr_run_sparse_fpca_workflow(x,config),
    "unsupported fields|fdapace backend")
})

