
test_that("source logical shape audit distinguishes vector versus matrix without dropping dimensions",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Python ndarray.shape verification is opt-in")
  reticulate::py_run_string("
import numpy as np
_etr_shape_1d=np.arange(9,dtype=float)
_etr_shape_2d=np.arange(9,dtype=float).reshape(1,9)
")
  shape<-function(name)as.integer(unlist(et_to_r(
    reticulate::py_get_attr(
      reticulate::py_eval(name,convert=FALSE),"shape"))))
  native_shape<-function(x)
    as.integer(if(is.null(dim(x)))length(x)else dim(x))
  expect_identical(native_shape(seq_len(9)),shape("_etr_shape_1d"))
  expect_identical(native_shape(matrix(seq_len(9),1L,9L)),
    shape("_etr_shape_2d"))
  expect_false(identical(
    native_shape(matrix(seq_len(9),1L,9L)),shape("_etr_shape_1d")))
  expect_false(identical(
    native_shape(seq_len(9)),shape("_etr_shape_2d")))
})

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
  expect_identical(w$tables$scores,etr_sparse_fpca_score_frame(w$fit))
  expect_null(w$score_uncertainty)
  expect_equal(w$fit$scores,.etr_spn_fit_from_fixture(x)$scores,
    tolerance=1e-10,ignore_attr=TRUE)
  config$score_uncertainty<-list()
  w<-etr_run_sparse_fpca_workflow(x,config)
  expect_s3_class(w$score_uncertainty,"etr_sparse_fpca_score_uncertainty_native")
  expect_identical(w$tables$score_uncertainty,
    etr_sparse_fpca_score_uncertainty_frame_native(w$score_uncertainty))
  expect_identical(w$steps[[2L]]$name,"score_uncertainty")
  expect_true(w$decisions$score_uncertainty_requested$value)
  config$score_uncertainty<-list(unknown=TRUE)
  expect_error(etr_run_sparse_fpca_workflow(x,config),"score_uncertainty")
  config$score_uncertainty<-NULL
  x$dimension_names<-config$dimension<-"pupil (mm)"
  x$metadata$curve_id<-paste0("study-",seq_along(x$curve_ids))
  x$metadata$SFPC1<-seq_along(x$curve_ids)
  w<-etr_run_sparse_fpca_workflow(x,config)
  expect_identical(w$tables$scores$curve_id,x$curve_ids)
  expect_identical(w$tables$scores$curve_id.1,x$metadata$curve_id)
  expect_identical(w$tables$scores$SFPC1.1,x$metadata$SFPC1)
  expect_match(w$reports$fit,"'pupil (mm)'",fixed=TRUE)
  config$backend<-"unsupported"
  expect_error(etr_run_sparse_fpca_workflow(x,config),
    "unsupported fields|fdapace backend")
})



test_that("sparse FPCA bandwidth selection retains failed candidates and audits the refit",{
  x<-.etr_spn_source_fixture()
  cfg<-list(backend="native_covariance",dimension="signal",n_components=1L,
    evaluation_grid=seq(.08,.92,length.out=9L),noise_variance_method="fixed",
    measurement_error_variance=.07,analysis_support_action="restrict",psd_action="project",
    bandwidth_selection=list(mean_bandwidths=c(.5,.002,.5),
      covariance_bandwidths=.85,n_splits=3L,random_state=41L))
  w<-etr_run_sparse_fpca_workflow(x,cfg)
  a<-w$bandwidth_selection
  expect_identical(a$candidate_summary$mean_bandwidth,c(.002,.5))
  expect_identical(a$candidate_summary$n_failed_folds,c(3L,0L))
  expect_identical(a$selected_bandwidths$candidate_id,"candidate_0001")
  expect_identical(w$decisions$mean_bandwidth$source,"audited_selector")
  expect_equal(w$fit$provenance$sparse_fpca$mean_bandwidth,.5)
  expect_identical(w$steps[[1L]]$name,"bandwidth_selection")
  expect_identical(a$provenance$fold_policy,"numpy_randomstate_kfold")
  expect_false(a$provenance$validation_observations_used_for_population_fitting)
  bad<-cfg;bad$mean_bandwidth<-.5
  expect_error(etr_run_sparse_fpca_workflow(x,bad),"exactly one bandwidth mode")
  bad<-cfg;bad$bandwidth_selection$mean_bandwidths<-.002
  condition<-expect_error(etr_run_sparse_fpca_workflow(x,bad),
    class="etr_sparse_bandwidth_selection_error")
  expect_identical(condition$bandwidth_selection$status_code,"no_eligible_candidate")
  expect_true(all(condition$bandwidth_selection$fold_results$status_code=="fit_failure"))
  bad$bandwidth_selection$failure_action<-"error"
  expect_error(etr_run_sparse_fpca_workflow(x,bad),"insufficient_mean_local_support")
  bad<-cfg
  bad$bandwidth_selection$mean_bandwidths<-.5
  bad$bandwidth_selection$predictive_condition_limit<-1.000001
  condition<-expect_error(etr_run_sparse_fpca_workflow(x,bad),
    class="etr_sparse_bandwidth_selection_error")
  expect_true(all(condition$bandwidth_selection$fold_results$status_code=="validation_failure"))
  expect_true(all(condition$bandwidth_selection$curve_losses$failure_code==
    "predictive_covariance_ill_conditioned"))
})

test_that("rotated covariance diagonal and noise estimate match frozen numerical primitives",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen sparse covariance primitive differential is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_spn_source_fixture()
  grid<-seq(.08,.92,length.out=9L)
  times<-lapply(x$time,function(t)t[t>=grid[1L]&t<=tail(grid,1L)])
  # Use explicit source-curve index to avoid any object-equality inference.
  values<-lapply(seq_along(x$curve_ids),function(i){
    m<-x$time[[i]]>=grid[1L]&x$time[[i]]<=tail(grid,1L)
    as.numeric(x$values[[i]][m,1L])
  })
  pt<-unlist(times,use.names=FALSE)
  py<-unlist(values,use.names=FALSE)
  residuals<-Map(function(t,v)
    v-.etr_spn_mean(pt,py,t,.5)$values,times,values)
  pairs<-.etr_spn_pairs(times,residuals)
  native_diag<-.etr_spn_rotated_diagonal(pairs,grid,.85,6L)
  native_noise<-.etr_spn_noise_diagonal_difference(
    times,residuals,grid,native_diag$values,.7,c(.2,.8),3L)
  reticulate::py_run_string("
import numpy as np
from eyetrajectoriespy import _sparse_native as _etr_pace_src
def _etr_diag_source(a,b,prod,grid,times,residuals):
    pairs=_etr_pace_src.RawCovariancePairs(
      s=np.asarray(a,dtype=float),
      t=np.asarray(b,dtype=float),
      products=np.asarray(prod,dtype=float),
      curve_index=np.zeros(len(prod),dtype=int),mirrored=True)
    g=np.asarray(grid,dtype=float)
    rotated=_etr_pace_src.rotated_local_quadratic_covariance_diagonal(
      pairs,g,bandwidth=.85,min_local_pairs=6)
    noise=_etr_pace_src.estimate_noise_variance_diagonal_difference(
      tuple(np.asarray(t,dtype=float) for t in times),
      tuple(np.asarray(r,dtype=float) for r in residuals),
      g,np.eye(g.size),latent_diagonal=rotated.values,
      bandwidth=.7,noise_support=(.2,.8),min_local_points=3)
    return rotated,noise
")
  p<-reticulate::py_call(
    reticulate::py_eval("_etr_diag_source",convert=FALSE),
    reticulate::r_to_py(pairs$s),reticulate::r_to_py(pairs$t),
    reticulate::r_to_py(pairs$products),reticulate::r_to_py(grid),
    reticulate::r_to_py(times),reticulate::r_to_py(residuals))
  rotated<-reticulate::py_get_item(p,0L)
  noise<-reticulate::py_get_item(p,1L)
  get<-function(o,k)et_to_r(reticulate::py_get_attr(o,k))
  expect_equal(native_diag$values,get(rotated,"values"),
    tolerance=1e-7,ignore_attr=TRUE)
  expect_equal(native_diag$support_counts,get(rotated,"support_counts"),
    ignore_attr=TRUE)
  for(field in c("raw_diagonal","latent_diagonal",
      "diagonal_difference","variance")){
    expect_equal(native_noise[[field]],get(noise,field),
      tolerance=1e-7,ignore_attr=TRUE,info=field)
  }
  expect_identical(native_noise$status_code,get(noise,"status_code"))
})
