# Frozen source Python 1.2 sparse_partial_prediction.py numerical law.
# Independent certification is neither inferred nor created by these tests.

.etr_spn_partial_target<-function(){
  tt<-c(.11,.23,.35,.47,.61,.73,.88)
  v<-(-.5)+.18*tt+.3*sin(pi*tt)+.12*cos(2*pi*tt)
  etr_irregular_trajectory_set(
    list(tt),list(matrix(v,ncol=1L)),
    "target_01","signal",
    metadata=data.frame(group="holdout"),
    coordinate_system="degrees",time_unit="s")
}

test_that("conditional latent and noisy future uncertainty use full covariance",{
  fit<-.etr_spn_fit_from_fixture(.etr_spn_source_fixture())
  target<-.etr_spn_partial_target()
  future<-c(.58,.64,.72,.82,.9)
  out<-etr_sparse_fpca_partial_trajectory_prediction_native(
    fit,target,history_cutoff=.53,prediction_grid=future)
  expect_s3_class(out,
    "etr_sparse_fpca_partial_trajectory_prediction_native")
  expect_identical(out$curve_id,"target_01")
  expect_identical(out$history_times,c(.11,.23,.35,.47))
  expect_identical(out$prediction_grid,future)
  expect_length(out$conditional_mean,5L)
  expect_identical(dim(out$latent_covariance),c(5L,5L))
  expect_identical(dim(out$observed_predictive_covariance),
    c(5L,5L))
  expect_equal(out$latent_covariance,t(out$latent_covariance),
    tolerance=1e-11)
  expect_equal(out$observed_predictive_covariance,
    out$latent_covariance+diag(fit$noise_variance,5L),
    tolerance=1e-12,ignore_attr=TRUE)
  expect_true(all(is.finite(out$conditional_mean)))
  expect_true(all(out$latent_standard_errors>=0))
  expect_true(all(out$observed_predictive_standard_errors>=
    out$latent_standard_errors))
  expect_true(all(out$diagnostics$status_code=="ok"))
  expect_identical(out$diagnostics$future_rows_ignored,3L)
  expect_false(out$provenance$rank_k_covariance_used_for_prediction)
  expect_false(out$provenance$future_observations_after_cutoff_used)
  expect_false(out$provenance$conformal_calibration_applied)
  expect_false(out$independent_full_source_certified)
  altered<-target
  altered$values[[1L]][5L:7L,1L]<-
    altered$values[[1L]][5L:7L,1L]+100
  other<-etr_sparse_fpca_partial_trajectory_prediction_native(
    fit,altered,history_cutoff=.53,prediction_grid=future)
  expect_equal(out$conditional_mean,other$conditional_mean,
    tolerance=1e-12)
  expect_equal(out$latent_covariance,other$latent_covariance,
    tolerance=1e-12)
  frame<-etr_sparse_fpca_partial_prediction_frame_native(out)
  expect_identical(names(frame),c("curve_id","dimension","time",
    "conditional_mean","latent_standard_error",
    "observed_predictive_standard_error"))
  expect_identical(nrow(frame),5L)
  expect_equal(frame$conditional_mean,out$conditional_mean)
})

test_that("native sparse conditional prediction fails on source-invalid future and history",{
  fit<-.etr_spn_fit_from_fixture(.etr_spn_source_fixture())
  target<-.etr_spn_partial_target()
  predict<-etr_sparse_fpca_partial_trajectory_prediction_native
  expect_error(predict(fit,target,history_cutoff=.53,
    prediction_grid=c(.52,.8)),
    "prediction_grid_not_strictly_future")
  expect_error(predict(fit,target,history_cutoff=.53,
    prediction_grid=c(.7,1.2)),
    "prediction_grid_outside_fitted_support")
  expect_error(predict(fit,target,history_cutoff=.99,
    prediction_grid=c(1.1)),
    "history_cutoff_outside_fitted_support")
  expect_error(predict(fit,target,history_cutoff=.13,
    prediction_grid=.7),
    "insufficient_history_observations")
  expect_error(predict(fit,target,history_cutoff=.53,
    prediction_grid=.7,history_ridge=-.01),
    "history_ridge")
  expect_error(predict(fit,target,history_cutoff=.53,
    prediction_grid=.7,condition_limit=1),
    "condition_limit")
  expect_error(predict(fit,target,history_cutoff=.53,
    prediction_grid=.7,min_history_observations=TRUE),
    "min_history_observations")
})

test_that("native sparse conditional future prediction matches pinned Python 1.2 output",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("direct frozen Python 1.2 conditional future oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  training<-.etr_spn_source_fixture()
  native_fit<-.etr_spn_fit_from_fixture(training)
  target<-.etr_spn_partial_target()
  selected_grid<-c(.58,.64,.72,.82,.9)
  out<-etr_sparse_fpca_partial_trajectory_prediction_native(
    native_fit,target,history_cutoff=.53,
    prediction_grid=selected_grid)
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as _etr_spnp
import importlib
_etr_spnp_future=importlib.import_module('eyetrajectoriespy.sparse_partial_prediction')
def _etr_spnp_input(times,values,ids):
    return _etr_spnp.IrregularTrajectorySet(
      time=tuple(np.asarray(t,dtype=float) for t in times),
      values=tuple(np.asarray(v,dtype=float) for v in values),
      curve_ids=tuple(str(i) for i in ids),
      dimension_names=('signal',),
      coordinate_system='degrees',time_unit='s')
")
  make<-reticulate::py_eval("_etr_spnp_input",convert=FALSE)
  pytrain<-reticulate::py_call(make,
    times=reticulate::r_to_py(training$time),
    values=reticulate::r_to_py(training$values),
    ids=reticulate::r_to_py(as.list(as.character(training$curve_ids))))
  pytarget<-reticulate::py_call(make,
    times=reticulate::r_to_py(target$time),
    values=reticulate::r_to_py(target$values),
    ids=reticulate::r_to_py(as.list(as.character(target$curve_ids))))
  pyfit<-reticulate::py_call(
    etpy_get_export("fit_sparse_fpca"),
    trajectories=pytrain,dimension="signal",n_components=1L,
    evaluation_grid=reticulate::r_to_py(
      seq(.08,.92,length.out=9L)),
    mean_bandwidth=.50,covariance_bandwidth=.85,
    noise_variance_method="fixed",
    measurement_error_variance=.07,
    analysis_support_action="restrict",psd_action="project",
    score_ridge=.002,score_condition_limit=1e12,
    mean_min_local_points=3L,covariance_min_local_pairs=6L)
  module<-reticulate::py_eval("_etr_spnp_future",convert=FALSE)
  source<-reticulate::py_call(reticulate::py_get_attr(
    module,"sparse_fpca_partial_trajectory_prediction"),
    fit=pyfit,trajectory=pytarget,history_cutoff=.53,
    prediction_grid=reticulate::r_to_py(selected_grid))
  get<-function(k)et_to_r(reticulate::py_get_attr(source,k))
  for(field in c("history_times","history_values",
      "prediction_grid","conditional_mean","latent_covariance",
      "latent_standard_errors","observed_predictive_covariance",
      "observed_predictive_standard_errors")){
    expect_equal(unname(out[[field]]),unname(get(field)),
      tolerance=2e-6,ignore_attr=TRUE,
      info=paste("frozen conditional future",field))
  }
  pdiag<-get("diagnostics")
  for(field in c("n_history","n_prediction","future_rows_ignored",
      "status_code","conditional_covariance_psd_repair_applied")){
    expect_identical(as.character(out$diagnostics[[field]]),
      as.character(pdiag[[field]]))
  }
  pframe<-et_to_r(reticulate::py_call(reticulate::py_get_attr(
    module,"sparse_fpca_partial_prediction_frame"),
    result=source))
  rframe<-etr_sparse_fpca_partial_prediction_frame_native(out)
  expect_identical(names(rframe),names(pframe))
  for(field in names(rframe)){
    if(is.numeric(rframe[[field]]))
      expect_equal(rframe[[field]],pframe[[field]],
        tolerance=2e-6,ignore_attr=TRUE)
    else expect_identical(
      as.character(rframe[[field]]),
      as.character(pframe[[field]]))
  }
})
