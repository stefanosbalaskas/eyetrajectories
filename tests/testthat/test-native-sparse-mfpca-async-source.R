# Noncertifying direct frozen Python 1.2 sparse multivariate async source.
test_that("asynchronous joint FPCA respects missing coordinate native times",{
  data<-.etr_spna_fixture()
  args<-.etr_spna_options()
  fit<-do.call(etr_fit_sparse_mfpca_async_native,
    c(list(trajectories=data),args))
  expect_s3_class(fit,"etr_sparse_mfpca_async_source")
  expect_identical(fit$fit_method,
    "direct_async_sparse_block_covariance")
  expect_identical(fit$score_method,"asynchronous_joint_PACE")
  expect_identical(dim(fit$mean),c(9L,2L))
  expect_identical(dim(fit$eigenfunctions),c(2L,9L,2L))
  expect_identical(dim(fit$scores),c(24L,2L))
  expect_true(all(is.finite(fit$scores)))
  expect_true(all(fit$score_diagnostics$status_code=="ok"))
  expect_true(all(fit$score_diagnostics$solve_status=="solved"))
  expect_true(any(fit$score_diagnostics$
    measurement_error_cross_links>0L))
  expect_equal(fit$covariance_cyx,t(fit$covariance_cxy),
    tolerance=1e-12)
  expect_equal(fit$smoothed_cyx,t(fit$smoothed_cxy),
    tolerance=1e-12)
  expect_false(fit$provenance$sparse_mfpca_async$
    rank_k_covariance_used_for_scoring)
  expect_false(fit$provenance$sparse_mfpca_async$
    raw_sparse_trajectory_interpolation_performed)
  expect_false(fit$independent_full_source_certified)
  expect_gt(fit$support_diagnostics$cross_candidate_pair_count,
    fit$support_diagnostics$cross_retained_pair_count)
  # Only truly retained simultaneous coordinate pairs are excluded:
  # raw simultaneous events outside the population support are not counted.
  expected_sim<-sum(vapply(seq_along(data$time),function(i){
    t<-data$time[[i]];v<-data$values[[i]]
    sum(t>=.10&t<=.86&is.finite(v[,1L])&
      is.finite(v[,2L]))
  },integer(1L)))
  expect_identical(
    fit$support_diagnostics$cross_same_time_pair_count_excluded,
    as.integer(expected_sim))
  config<-c(list(backend="native_covariance"),args)
  workflow<-etr_run_sparse_mfpca_async_workflow(data,config)
  expect_s3_class(workflow,"etr_native_sparse_mfpca_workflow")
  expect_identical(workflow$workflow_contract,"sparse_mfpca_async:v1")
  expect_equal(workflow$fit$scores,fit$scores,tolerance=1e-12)
  expect_false(workflow$provenance$raw_interpolation_performed)
})

test_that("asynchronous source fitting fails closed on invalid union timestamps",{
  data<-.etr_spna_fixture()
  a<-.etr_spna_options()
  wrong<-data
  wrong$values[[1L]][1L,]<-c(NaN,NaN)
  expect_error(do.call(etr_fit_sparse_mfpca_async_native,
    c(list(trajectories=wrong),a)),"empty_async_timestamp_row")
  wrong<-data;wrong$values[[1L]][2L,1L]<-Inf
  expect_error(do.call(etr_fit_sparse_mfpca_async_native,
    c(list(trajectories=wrong),a)),
    "infinity|nonfinite_sparse_async_observation")
  bad<-a;bad$same_time_tolerance<--1e-3
  expect_error(do.call(etr_fit_sparse_mfpca_async_native,
    c(list(trajectories=data),bad)),"same_time_tolerance")
  bad<-a;bad$measurement_error_covariance<-
    matrix(c(.05,.2,.2,.06),2L)
  expect_error(do.call(etr_fit_sparse_mfpca_async_native,
    c(list(trajectories=data),bad)),
    "invalid_measurement_error_covariance")
  bad<-a;bad$analysis_support_action<-"error"
  expect_error(do.call(etr_fit_sparse_mfpca_async_native,
    c(list(trajectories=data),bad)),
    "observations_outside_analysis_support")
})

test_that("native asynchronous source arrays and scores match frozen Python 1.2",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("source-pinned asynchronous numerical oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  data<-.etr_spna_fixture()
  args<-.etr_spna_options()
  ours<-do.call(etr_fit_sparse_mfpca_async_native,
    c(list(trajectories=data),args))
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as _etr_async_source
import importlib
_etr_async_module=importlib.import_module('eyetrajectoriespy.sparse_multivariate_async')
def _etr_async_input(times,values,ids,batch):
    assert not isinstance(ids,(str,bytes))
    assert len(times)==len(values)==len(ids)==len(batch)
    return _etr_async_source.IrregularTrajectorySet(
      time=tuple(np.asarray(x,dtype=float) for x in times),
      values=tuple(np.asarray(v,dtype=float) for v in values),
      curve_ids=tuple(str(x) for x in ids),
      dimension_names=('x','y'),
      metadata=pd.DataFrame({'batch':list(batch)}),
      coordinate_system='degrees',time_unit='s')
")
  source_tr<-reticulate::py_call(
    reticulate::py_eval("_etr_async_input",convert=FALSE),
    times=reticulate::r_to_py(data$time),
    values=reticulate::r_to_py(data$values),
    ids=reticulate::r_to_py(as.list(as.character(data$curve_ids))),
    batch=reticulate::r_to_py(
      as.list(as.character(data$metadata$batch))))
  pyargs<-args
  pyargs$dimensions<-reticulate::tuple("x","y")
  pyargs$evaluation_grid<-reticulate::r_to_py(args$evaluation_grid)
  pyargs$measurement_error_covariance<-
    reticulate::r_to_py(args$measurement_error_covariance)
  fit<-do.call(reticulate::py_call,
    c(list(reticulate::py_get_attr(
      reticulate::py_eval("_etr_async_module",convert=FALSE),
      "fit_sparse_mfpca_async"),trajectories=source_tr),
      pyargs))
  attr<-function(name)et_to_r(reticulate::py_get_attr(fit,name))
  for(field in c("scores","eigenvalues","eigenfunctions",
      "mean","quadrature_weights",
      "smoothed_cxx","smoothed_cxy","smoothed_cyx","smoothed_cyy",
      "covariance_cxx","covariance_cxy","covariance_cyx","covariance_cyy",
      "measurement_error_covariance","mean_support_counts")){
    expect_equal(unname(ours[[field]]),unname(attr(field)),
      tolerance=3e-6,ignore_attr=TRUE,
      info=paste("async native PACE source",field))
  }
  their<-attr("score_diagnostics")
  for(field in c("status_code","solve_status",
      "n_x_observations","n_y_observations",
      "n_scalar_observations","n_simultaneous_pairs",
      "measurement_error_cross_links")){
    expect_identical(as.character(ours$score_diagnostics[[field]]),
      as.character(their[[field]]),
      info=paste("frozen async PACE score diagnostics",field))
  }
  support<-attr("support_diagnostics")
  for(field in c("original_union_sample_counts",
      "analysis_x_sample_counts","analysis_y_sample_counts",
      "cross_candidate_pair_count",
      "cross_same_time_pair_count_excluded",
      "cross_retained_pair_count")){
    expect_equal(unname(ours$support_diagnostics[[field]]),
      unname(support[[field]]),ignore_attr=TRUE,
      info=paste("source async support",field))
  }
})
