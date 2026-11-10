# Uncertified frozen Python 1.2 sparse_multilevel.py numerical source law.

test_that("sparse participant/trial joint BLUP preserves covariance hierarchy",{
  data<-.etr_spml_fixture()
  options<-.etr_spml_options()
  fit<-do.call(etr_fit_sparse_multilevel_fpca_native,
    c(list(trajectories=data),options))
  expect_s3_class(fit,"etr_sparse_multilevel_fpca_source")
  expect_identical(length(fit$participant_ids),6L)
  expect_identical(nrow(fit$participant_scores),6L)
  expect_identical(nrow(fit$trial_scores),24L)
  expect_identical(dim(fit$between_covariance),c(9L,9L))
  expect_identical(dim(fit$within_covariance),c(9L,9L))
  expect_identical(dim(fit$participant_eigenfunctions),c(1L,9L))
  expect_identical(dim(fit$trial_eigenfunctions),c(1L,9L))
  expect_equal(fit$total_covariance,
    fit$between_covariance+fit$within_covariance,
    tolerance=1e-12)
  expect_equal(fit$smoothed_within_covariance,
    fit$smoothed_total_covariance-
      fit$smoothed_between_covariance,
    tolerance=1e-12)
  expect_true(all(is.finite(fit$participant_scores[[2L]])))
  expect_true(all(is.finite(fit$trial_scores[[3L]])))
  expect_true(all(fit$score_diagnostics$status_code=="ok"))
  expect_true(all(fit$participant_eigenvalues>0))
  expect_true(all(fit$trial_eigenvalues>0))
  expect_identical(fit$support_diagnostics$n_participants,6L)
  expect_identical(fit$support_diagnostics$n_repeated_participants,6L)
  expect_identical(fit$support_diagnostics$between_covariance_pair_count,
    as.integer(6L*choose(4L,2L)*(7L*7L)*2L))
  expect_false(fit$provenance$sparse_multilevel_fpca$
    rank_k_covariance_used_for_scoring)
  expect_false(fit$provenance$sparse_multilevel_fpca$
    raw_sparse_trajectory_interpolation_performed)
  expect_false(fit$independent_full_source_certified)
  workflow<-etr_run_sparse_multilevel_workflow(data,
    c(list(backend="native_covariance"),options))
  expect_s3_class(workflow,"etr_native_sparse_multilevel_workflow")
  expect_identical(workflow$workflow_contract,"sparse_multilevel:v1")
  expect_equal(workflow$fit$participant_eigenvalues,
    fit$participant_eigenvalues,tolerance=1e-12)
  expect_false(workflow$provenance$interpolation_explicit)
})

test_that("sparse hierarchy requires multiple distinct repeated participants",{
  tr<-.etr_spml_fixture()
  args<-.etr_spml_options()
  bad<-tr
  bad$metadata$participant<-rep("same",24L)
  expect_error(do.call(etr_fit_sparse_multilevel_fpca_native,
    c(list(trajectories=bad),args)),"insufficient_participants")
  bad<-tr
  bad$metadata$participant[1L]<-NA_character_
  expect_error(do.call(etr_fit_sparse_multilevel_fpca_native,
    c(list(trajectories=bad),args)),"participant identifiers")
  invalid<-args
  invalid$weighting<-"equal_participant"
  expect_error(do.call(etr_fit_sparse_multilevel_fpca_native,
    c(list(trajectories=tr),invalid)),"observation weighting")
  invalid<-args
  invalid$measurement_error_variance<-(-.01)
  expect_error(do.call(etr_fit_sparse_multilevel_fpca_native,
    c(list(trajectories=tr),invalid)),"fixed noise")
})

test_that("native sparse multilevel BLUP numerical arrays agree with frozen Python 1.2 source module",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("source-pinned sparse multilevel differential opt-in")
  expect_identical(et_python_version(),"1.2.0")
  data<-.etr_spml_fixture();args<-.etr_spml_options()
  native<-do.call(etr_fit_sparse_multilevel_fpca_native,
    c(list(trajectories=data),args))
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as _etr_spml_et
import importlib
_etr_spml_source=importlib.import_module('eyetrajectoriespy.sparse_multilevel')
def _etr_spml_input(times, values, ids, participants):
    if isinstance(ids,(str,bytes)) or isinstance(participants,(str,bytes)):
        raise TypeError('ids/participants must be sequences')
    assert len(times)==len(values)==len(ids)==len(participants)
    return _etr_spml_et.IrregularTrajectorySet(
      time=tuple(np.asarray(t,dtype=float) for t in times),
      values=tuple(np.asarray(v,dtype=float) for v in values),
      curve_ids=tuple(str(z) for z in ids),
      dimension_names=('signal',),
      metadata=pd.DataFrame({'participant':list(participants)}),
      coordinate_system='degrees',time_unit='s')
")
  make<-reticulate::py_eval("_etr_spml_input",convert=FALSE)
  pytr<-reticulate::py_call(make,
    times=reticulate::r_to_py(data$time),
    values=reticulate::r_to_py(data$values),
    ids=reticulate::r_to_py(
      as.list(as.character(data$curve_ids))),
    participants=reticulate::r_to_py(
      as.list(as.character(data$metadata$participant))))
  pyargs<-args
  pyargs$evaluation_grid<-reticulate::r_to_py(args$evaluation_grid)
  source_fun<-reticulate::py_get_attr(
    reticulate::py_eval("_etr_spml_source",convert=FALSE),
    "fit_sparse_multilevel_fpca")
  source<-do.call(reticulate::py_call,
    c(list(source_fun,trajectories=pytr),pyargs))
  get<-function(field)et_to_r(reticulate::py_get_attr(source,field))
  for(field in c("grand_mean","smoothed_total_covariance",
    "smoothed_between_covariance","smoothed_within_covariance",
    "total_covariance","between_covariance","within_covariance",
    "participant_eigenvalues","participant_eigenfunctions",
    "trial_eigenvalues","trial_eigenfunctions",
    "quadrature_weights","noise_variance","mean_support_counts",
    "total_covariance_support_counts",
    "between_covariance_support_counts")){
    expect_equal(unname(native[[field]]),unname(get(field)),
      tolerance=3e-6,ignore_attr=TRUE,
      info=paste("frozen sparse multilevel",field))
  }
  for(field in c("participant_scores","trial_scores")){
    ours<-native[[field]];theirs<-get(field)
    expect_identical(as.character(ours[[1L]]),
      as.character(theirs[[1L]]))
    for(j in seq.int(2L,ncol(ours))){
      expect_equal(ours[[j]],theirs[[j]],
        tolerance=3e-6,ignore_attr=TRUE,
        info=paste("frozen multilevel BLUP",field,j))
    }
  }
  source_diag<-get("score_diagnostics")
  for(field in c("participant_id","n_trials","n_samples",
      "status_code","solve_status")){
    expect_identical(as.character(native$score_diagnostics[[field]]),
      as.character(source_diag[[field]]))
  }
})
