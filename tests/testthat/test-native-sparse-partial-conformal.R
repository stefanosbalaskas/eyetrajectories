
test_that("reticulate preserves one-curve IDs and metadata as Python sequences",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("reticulate Python sequence regression is opt-in")
  reticulate::py_run_string("
def _etr_source_roles_lengths(time,values,ids,batch):
    assert not isinstance(ids,(str,bytes)), 'ids must be a sequence'
    assert not isinstance(batch,(str,bytes)), 'batch must be a sequence'
    return (len(time),len(values),len(ids),len(batch),
      str(ids[0]),str(batch[0]))
")
  target<-.etr_spnp_partial_target_safe()
  fn<-reticulate::py_eval("_etr_source_roles_lengths",convert=FALSE)
  result<-reticulate::py_call(fn,
    time=reticulate::r_to_py(target$time),
    values=reticulate::r_to_py(target$values),
    ids=reticulate::r_to_py(as.list(as.character(target$curve_ids))),
    batch=reticulate::r_to_py(
      as.list(as.character(target$metadata$batch))))
  actual<-unlist(reticulate::py_to_r(result),use.names=FALSE)
  expect_identical(as.character(actual),
    c("1","1","1","1","target_conformal","target_unique"))
})

test_that("native split conformal uses exact finite-grid futures and group maxima",{
  training<-.etr_spn_source_fixture()
  fit<-.etr_spn_fit_from_fixture(training)
  calibration<-.etr_spnpc_fixture()
  future<-c(.60,.72,.84)
  cal<-etr_calibrate_sparse_fpca_partial_conformal_native(
    fit,calibration,history_cutoff=.50,
    prediction_grid=future,alpha=.2)
  expect_identical(cal$n_calibration_units,12L)
  expect_identical(length(cal$unit_scores),12L)
  expect_identical(nrow(cal$curve_scores),12L)
  expect_true(all(is.finite(cal$unit_scores)))
  expect_true(all(cal$unit_scores>=0))
  expect_equal(cal$critical_value,
    sort(cal$unit_scores)[ceiling(13*.8)],tolerance=1e-12)
  expect_true(all(cal$curve_scores$n_history==4L))
  expect_true(all(cal$curve_scores$n_future_grid==3L))
  expect_false(cal$provenance$raw_future_response_interpolation_performed)
  grouped<-etr_calibrate_sparse_fpca_partial_conformal_native(
    fit,calibration,history_cutoff=.5,
    prediction_grid=future,alpha=.30,group_column="batch")
  expect_identical(grouped$n_calibration_units,4L)
  expect_identical(grouped$calibration_unit_ids,
    paste0("cal_g",seq_len(4L)))
  want<-vapply(seq_len(4L),function(i)
    max(cal$curve_scores$nonconformity_score[
      (3L*i-2L):(3L*i)]),numeric(1L))
  expect_equal(grouped$unit_scores,want,tolerance=1e-12)
  expect_equal(grouped$critical_value,sort(want)[4L],
    tolerance=1e-12)
  target<-.etr_spnp_partial_target_safe()
  band<-etr_sparse_fpca_conformal_prediction_band_native(
    grouped,target)
  expect_s3_class(band,
    "etr_sparse_fpca_conformal_prediction_band_native")
  expect_equal(band$upper-band$lower,
    2*grouped$critical_value*
      band$prediction$observed_predictive_standard_errors,
    tolerance=1e-12)
  expect_identical(band$target_calibration_unit,"target_unique")
  expect_false(band$provenance$continuous_domain_coverage_claimed)
  expect_false(band$provenance$latent_function_coverage_claimed)
  frame<-etr_sparse_fpca_conformal_band_frame_native(band)
  expect_identical(names(frame),c("curve_id","dimension","time",
    "conditional_mean","observed_predictive_standard_error",
    "lower","upper","alpha","critical_value"))
  expect_identical(nrow(frame),3L)
})

test_that("native grouped conformal rejects role leakage and nonexistent future observations",{
  fit<-.etr_spn_fit_from_fixture(.etr_spn_source_fixture())
  calibration<-.etr_spnpc_fixture()
  conformal<-etr_calibrate_sparse_fpca_partial_conformal_native
  expect_error(conformal(fit,calibration,.50,c(.61,.72,.84),
    alpha=.2),"calibration_future_grid_observation_missing")
  expect_error(conformal(fit,calibration,.50,c(.60,.72,.84),
    alpha=.01),"insufficient_calibration_units_for_alpha")
  overlap<-calibration
  overlap$curve_ids[1L]<-fit$curve_ids[1L]
  expect_error(conformal(fit,overlap,.50,c(.60,.72,.84),
    alpha=.2),"disjoint")
  grouped<-calibration
  grouped$metadata$batch[1L]<-as.character(
    fit$metadata$batch[1L])
  expect_error(conformal(fit,grouped,.50,c(.60,.72,.84),
    alpha=.3,group_column="batch"),"disjoint")
  c<-conformal(fit,calibration,.50,c(.60,.72,.84),
    alpha=.3,group_column="batch")
  new<-.etr_spnp_partial_target_safe()
  new$metadata$batch<-c$calibration_unit_ids[1L]
  expect_error(etr_sparse_fpca_conformal_prediction_band_native(
    c,new),"disjoint")
})

test_that("mapped sparse prediction workflow uses full native source PACE split conformal",{
  proper<-.etr_spn_source_fixture()
  cal<-.etr_spnpc_fixture()
  target<-.etr_spnp_partial_target_safe()
  cfg<-list(
    backend="native_sparse_partial_conformal",
    training=list(
      backend="native_covariance",dimension="signal",
      n_components=1L,
      evaluation_grid=seq(.08,.92,length.out=9L),
      mean_bandwidth=.5,covariance_bandwidth=.85,
      noise_variance_method="fixed",
      measurement_error_variance=.07,
      analysis_support_action="restrict",psd_action="project",
      score_ridge=.002),
    history_cutoff=.5,prediction_grid=c(.60,.72,.84),
    alpha=.30,group_column="batch")
  w<-etr_run_sparse_prediction_workflow(proper,cal,target,cfg)
  expect_s3_class(w,"etr_native_sparse_prediction_workflow")
  expect_identical(w$workflow_contract,"sparse_prediction:v1")
  expect_identical(w$band$calibration$n_calibration_units,4L)
  expect_identical(nrow(w$tables$prediction_band),3L)
  expect_identical(nrow(w$tables$calibration_curve_scores),12L)
  expect_false(w$provenance$raw_interpolation_performed)
  expect_false(w$provenance$independent_full_contract_certified)
  cfg$training$mean_bandwidth<-cfg$training$covariance_bandwidth<-NULL
  cfg$training$bandwidth_selection<-list(mean_bandwidths=c(.5,.6),
    covariance_bandwidths=.85,n_splits=3L,shuffle=FALSE)
  selected<-etr_run_sparse_prediction_workflow(proper,cal,target,cfg)
  assignments<-selected$training_workflow$bandwidth_selection$assignments
  expect_setequal(assignments$curve_id,proper$curve_ids)
  expect_identical(selected$steps[[1L]]$name,"proper_training.bandwidth_selection")
  expect_identical(nrow(selected$tables$prediction_band),3L)
})

test_that("frozen Python 1.2 sparse future conformal critical values and bands match",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("direct source split conformal numerical replay opt-in")
  expect_identical(et_python_version(),"1.2.0")
  proper<-.etr_spn_source_fixture()
  cal<-.etr_spnpc_fixture()
  target<-.etr_spnp_partial_target_safe()
  nativefit<-.etr_spn_fit_from_fixture(proper)
  opts<-list(history_cutoff=.5,
    prediction_grid=c(.60,.72,.84),alpha=.20)
  nr<-do.call(etr_calibrate_sparse_fpca_partial_conformal_native,
    c(list(fit=nativefit,calibration=cal),opts))
  nb<-etr_sparse_fpca_conformal_prediction_band_native(nr,target)
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as _etr_spnpc
import importlib
_etr_spnpc_module=importlib.import_module('eyetrajectoriespy.sparse_partial_conformal')
def _etr_spnpc_irregular(time,values,ids,batch):
    if isinstance(ids,(str,bytes)) or isinstance(batch,(str,bytes)):
        raise TypeError('one-curve ids and batch must be sequences, not strings')
    if not (len(time)==len(values)==len(ids)==len(batch)):
        raise AssertionError('source-fixture curve-role lengths do not match')
    return _etr_spnpc.IrregularTrajectorySet(
      time=tuple(np.asarray(t,dtype=float) for t in time),
      values=tuple(np.asarray(v,dtype=float) for v in values),
      curve_ids=tuple(str(z) for z in ids),
      dimension_names=('signal',),
      metadata=pd.DataFrame({'batch':list(batch)}),
      coordinate_system='degrees',time_unit='s')
")
  mk<-reticulate::py_eval("_etr_spnpc_irregular",convert=FALSE)
  make<-function(z)reticulate::py_call(mk,
    time=reticulate::r_to_py(z$time),
    values=reticulate::r_to_py(z$values),
    ids=reticulate::r_to_py(as.list(as.character(z$curve_ids))),
    batch=reticulate::r_to_py(as.list(as.character(z$metadata$batch))))
  pytrain<-make(proper);pycal<-make(cal);pytarget<-make(target)
  pyfit<-reticulate::py_call(etpy_get_export("fit_sparse_fpca"),
    trajectories=pytrain,dimension="signal",n_components=1L,
    evaluation_grid=reticulate::r_to_py(
      seq(.08,.92,length.out=9L)),
    mean_bandwidth=.5,covariance_bandwidth=.85,
    noise_variance_method="fixed",
    measurement_error_variance=.07,
    analysis_support_action="restrict",psd_action="project",
    score_ridge=.002)
  module<-reticulate::py_eval("_etr_spnpc_module",convert=FALSE)
  pycalibration<-reticulate::py_call(reticulate::py_get_attr(module,
    "calibrate_sparse_fpca_partial_prediction_conformal"),
    fit=pyfit,calibration=pycal,
    history_cutoff=.5,
    prediction_grid=reticulate::r_to_py(c(.60,.72,.84)),
    alpha=.2)
  attr<-function(x,k)et_to_r(reticulate::py_get_attr(x,k))
  expect_equal(nr$unit_scores,attr(pycalibration,"unit_scores"),
    tolerance=2e-6,ignore_attr=TRUE)
  expect_equal(nr$critical_value,attr(pycalibration,"critical_value"),
    tolerance=2e-6)
  pyband<-reticulate::py_call(reticulate::py_get_attr(module,
    "sparse_fpca_conformal_prediction_band"),
    calibration=pycalibration,trajectory=pytarget)
  for(field in c("lower","upper")){
    expect_equal(unname(nb[[field]]),unname(attr(pyband,field)),
      tolerance=2e-6,ignore_attr=TRUE,
      info=paste("source conformal",field))
  }
  source_frame<-et_to_r(reticulate::py_call(
    reticulate::py_get_attr(module,"sparse_fpca_conformal_band_frame"),
    result=pyband))
  native_frame<-etr_sparse_fpca_conformal_band_frame_native(nb)
  expect_identical(names(native_frame),names(source_frame))
  for(field in names(native_frame)){
    if(is.numeric(native_frame[[field]]))
      expect_equal(native_frame[[field]],source_frame[[field]],
        tolerance=2e-6,ignore_attr=TRUE,
        info=paste("source conformal frame",field))
    else expect_identical(as.character(native_frame[[field]]),
      as.character(source_frame[[field]]))
  }
})
