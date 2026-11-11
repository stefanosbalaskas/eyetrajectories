# Frozen Python 1.2 source workflow comparisons:
# c1cd95ad718327550f7e55393ff38582872f7a94
# workflows/_sparse_multilevel.py, workflows/_sparse_prediction.py.
# No source-Python runtime class equivalence is asserted in these R records.

.etr_spw2_multi_fields<-c("workflow_schema_version","workflow_contract",
  "config","fit","observation_diagnostics","steps","decisions",
  "provenance","reports","tables")
.etr_spw2_multi_config<-c(
  "dimension","participant_column","participant_components",
  "trial_components","evaluation_grid","mean_bandwidth",
  "total_covariance_bandwidth","between_covariance_bandwidth",
  "noise_bandwidth","noise_support","analysis_support_action",
  "weighting","mean_smoother","covariance_smoother","kernel",
  "noise_variance_method","measurement_error_variance",
  "psd_action","psd_tolerance","positive_eigen_tolerance",
  "score_ridge","score_condition_limit",
  "min_participant_score_samples","score_failure_action",
  "mean_min_local_points","total_covariance_min_local_pairs",
  "between_covariance_min_local_pairs","noise_min_local_points",
  "observation_diagnostics","preprocessing")
.etr_spw2_multi_decisions<-c(
  "participant_components","trial_components","mean_bandwidth",
  "total_covariance_bandwidth","between_covariance_bandwidth",
  "weighting","psd_action","observation_diagnostics_requested")
.etr_spw2_multi_provenance<-c(
  "raw_interpolation_performed","native_observation_grids_retained",
  "bandwidth_mode","bandwidth_selector_available",
  "automatic_model_selection_performed")
.etr_spw2_prediction_fields<-c(
  "workflow_schema_version","workflow_contract","config",
  "training_workflow","calibration","band","steps","decisions",
  "provenance","reports","tables")
.etr_spw2_prediction_config<-c(
  "training","history_cutoff","prediction_grid","alpha",
  "group_column","min_history_observations","condition_limit",
  "history_ridge","preprocessing")
.etr_spw2_prediction_provenance<-c(
  "raw_interpolation_performed","random_role_split_performed",
  "proper_training_role_explicit","calibration_role_explicit",
  "target_role_explicit","coverage_scope",
  "automatic_model_selection_performed")
.etr_spw2_prediction_cfg<-function(){
  list(backend="native_sparse_partial_conformal",
    training=list(
      backend="native_covariance",dimension="signal",
      n_components=1L,
      evaluation_grid=seq(.08,.92,length.out=9L),
      mean_bandwidth=.5,covariance_bandwidth=.85,
      noise_variance_method="fixed",measurement_error_variance=.07,
      analysis_support_action="restrict",psd_action="project",
      score_ridge=.002),
    history_cutoff=.5,prediction_grid=c(.60,.72,.84),
    alpha=.30,group_column="batch")
}

test_that("sparse multilevel W2 preserves native BLUP and canonical scientific schema",{
  x<-.etr_spml_fixture()
  cfg<-c(list(backend="native_covariance"),.etr_spml_options())
  prior<-etr_run_sparse_multilevel_workflow(x,cfg)
  source<-etr_run_sparse_multilevel_workflow(x,cfg,
    strict_source_record=TRUE)
  expect_s3_class(source,"etr_sparse_multilevel_w2_source_workflow")
  expect_identical(names(source),.etr_spw2_multi_fields)
  expect_identical(names(source$config),.etr_spw2_multi_config)
  expect_identical(names(source$decisions),.etr_spw2_multi_decisions)
  expect_identical(names(source$provenance),.etr_spw2_multi_provenance)
  expect_identical(source$workflow_contract,"sparse_multilevel:v1")
  expect_identical(source$workflow_schema_version,1L)
  expect_identical(names(source$config$preprocessing),"steps")
  expect_length(source$config$preprocessing$steps,0L)
  expect_identical(source$config$participant_column,"participant")
  expect_identical(source$decisions$weighting$value,"observation")
  expect_identical(source$decisions$mean_bandwidth$source,"analyst")
  expect_false(source$provenance$raw_interpolation_performed)
  expect_true(source$provenance$native_observation_grids_retained)
  expect_false(source$provenance$bandwidth_selector_available)
  expect_null(source$observation_diagnostics)
  expect_identical(names(source$tables),c(
    "participant_scores","trial_scores","score_diagnostics"))
  expect_identical(names(source$reports),"fit")
  expect_identical(source$tables,prior$tables)
  expect_equal(source$fit$grand_mean,prior$fit$grand_mean,tolerance=0)
  expect_equal(source$fit$between_covariance,
    prior$fit$between_covariance,tolerance=0)
  expect_equal(source$fit$within_covariance,
    prior$fit$within_covariance,tolerance=0)
  expect_length(source$steps,1L)
  expect_identical(names(source$steps[[1L]]),c(
    "name","function","status","parameters","elapsed_seconds","warnings"))
  expect_true(is.finite(source$steps[[1L]]$elapsed_seconds))
  expect_gte(source$steps[[1L]]$elapsed_seconds,0)
  expect_false(prior$provenance$independent_full_contract_certified)
})

test_that("sparse future conformal W2 binds disjoint roles with nested source training",{
  proper<-.etr_spn_source_fixture()
  cal<-.etr_spnpc_fixture()
  target<-.etr_spnpc_partial_target_safe()
  cfg<-.etr_spw2_prediction_cfg()
  prior<-etr_run_sparse_prediction_workflow(proper,cal,target,cfg)
  source<-etr_run_sparse_prediction_workflow(proper,cal,target,cfg,
    strict_source_record=TRUE)
  expect_s3_class(source,"etr_sparse_prediction_w2_source_workflow")
  expect_identical(names(source),.etr_spw2_prediction_fields)
  expect_identical(names(source$config),.etr_spw2_prediction_config)
  expect_identical(names(source$provenance),
    .etr_spw2_prediction_provenance)
  expect_identical(source$workflow_contract,"sparse_prediction:v1")
  expect_identical(source$config$alpha,.30)
  expect_identical(source$config$group_column,"batch")
  expect_identical(names(source$config$training),
    names(source$training_workflow$config))
  expect_identical(source$config$training$dimension,"signal")
  expect_identical(names(source$config$preprocessing),"steps")
  expect_s3_class(source$training_workflow,
    "etr_sparse_fpca_source_workflow")
  expect_identical(source$training_workflow$workflow_contract,
    "sparse_fpca:v1")
  expect_length(source$steps,3L)
  expect_identical(vapply(source$steps,`[[`,character(1L),"name"),
    c("proper_training.fit","conformal_calibration","target_prediction"))
  for(step in source$steps){
    expect_identical(names(step),c("name","function","status",
      "parameters","elapsed_seconds","warnings"))
    expect_gte(step$elapsed_seconds,0)
  }
  required_decisions<-c(
    paste0("training.",names(source$training_workflow$decisions)),
    "history_cutoff","prediction_grid","alpha","group_column",
    "role_assignment")
  expect_identical(names(source$decisions),required_decisions)
  roles<-source$decisions$role_assignment
  expect_identical(roles$source,"analyst")
  expect_identical(roles$criterion,"explicit_disjoint_workflow_roles")
  expect_identical(unlist(roles$value$proper_training,use.names=FALSE),
    proper$curve_ids)
  expect_identical(unlist(roles$value$calibration,use.names=FALSE),
    cal$curve_ids)
  expect_identical(unlist(roles$value$target,use.names=FALSE),
    target$curve_ids)
  expect_identical(names(source$tables),c(
    "training_scores","calibration_curve_scores","prediction_band"))
  expect_identical(names(source$reports),
    c("training_fit","prediction_band"))
  expect_identical(source$tables,prior$tables)
  expect_equal(source$calibration$critical_value,
    prior$calibration$critical_value,tolerance=0)
  expect_equal(source$band$upper,prior$band$upper,tolerance=0)
  expect_identical(source$provenance$coverage_scope,
    "future_observed_measurements_on_declared_finite_grid")
  expect_false(source$provenance$random_role_split_performed)
  expect_false(source$provenance$raw_interpolation_performed)
})

test_that("strict W2 refuses interpolated or mean-curve substitute and R-only CV replay",{
  x<-.etr_spml_fixture()
  cfg<-c(list(backend="native_covariance"),.etr_spml_options())
  expect_error(etr_run_sparse_multilevel_workflow(x,cfg,
    strict_source_record=NA),"strict_source_record")
  bad<-cfg;bad$backend<-"explicit_linear_interpolation_dense_multilevel"
  expect_error(etr_run_sparse_multilevel_workflow(x,bad,
    strict_source_record=TRUE),"native_covariance")
  proper<-.etr_spn_source_fixture()
  cal<-.etr_spnpc_fixture()
  target<-.etr_spnpc_partial_target_safe()
  p<-.etr_spw2_prediction_cfg()
  expect_error(etr_run_sparse_prediction_workflow(
    proper,cal,target,p,strict_source_record=1L),
    "strict_source_record")
  bad<-p;bad$backend<-"native_mean_curve_split_conformal"
  expect_error(etr_run_sparse_prediction_workflow(
    proper,cal,target,bad,strict_source_record=TRUE),
    "native_sparse_partial_conformal")
  bad<-p
  bad$training$mean_bandwidth<-bad$training$covariance_bandwidth<-NULL
  bad$training$bandwidth_selection<-list(
    mean_bandwidths=.5,covariance_bandwidths=.85,
    fold_assignments=rep(0L,length(proper$curve_ids)))
  expect_error(etr_run_sparse_prediction_workflow(
    proper,cal,target,bad,strict_source_record=TRUE),
    "fold_assignments")
})

test_that("frozen Python 1.2 multilevel and split-conformal W2 workflows agree on source scientific domain",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 workflows require opt-in Python oracle")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as et
import eyetrajectoriespy.workflows as wf
def _w2_irregular(time,values,ids,field,metadata,dimensions):
    return et.IrregularTrajectorySet(
      time=tuple(np.asarray(t,dtype=float) for t in time),
      values=tuple(np.asarray(y,dtype=float) for y in values),
      curve_ids=tuple(str(i) for i in ids),
      dimension_names=tuple(dimensions),
      metadata=pd.DataFrame({field:list(metadata)}),
      coordinate_system='degrees',time_unit='s')
")
  wf<-reticulate::import("eyetrajectoriespy.workflows",convert=FALSE)
  mk<-reticulate::py_eval("_w2_irregular",convert=FALSE)
  make<-function(x,field)reticulate::py_call(mk,
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    ids=reticulate::r_to_py(as.list(as.character(x$curve_ids))),
    field=field,metadata=reticulate::r_to_py(
      as.list(x$metadata[[field]])),
    dimensions=reticulate::r_to_py(as.list(x$dimension_names)))
  ml<-.etr_spml_fixture()
  cfg<-c(list(backend="native_covariance"),.etr_spml_options())
  native<-etr_run_sparse_multilevel_workflow(ml,cfg,
    strict_source_record=TRUE)
  pycfg<-cfg[names(cfg)!="backend"]
  pycfg$evaluation_grid<-reticulate::r_to_py(
    as.numeric(cfg$evaluation_grid))
  source_config<-do.call(reticulate::py_call,c(
    list(wf$SparseMultilevelWorkflowConfig),pycfg))
  py<-reticulate::py_call(wf$run_sparse_multilevel_workflow,
    trajectories=make(ml,"participant"),config=source_config)
  expect_identical(names(native),
    as.character(et_to_r(reticulate::py_eval(
      "tuple(wf.SparseMultilevelWorkflowResult.__dataclass_fields__)",
      convert=FALSE))))
  expect_identical(names(native$config),
    as.character(et_to_r(reticulate::py_eval(
      "tuple(wf.SparseMultilevelWorkflowConfig.__dataclass_fields__)",
      convert=FALSE))))
  expect_identical(names(native$decisions),
    names(et_to_r(py$decisions)))
  expect_identical(names(native$provenance),
    names(et_to_r(py$provenance)))
  for(field in names(native$provenance))
    expect_equal(native$provenance[[field]],
      et_to_r(py$provenance[[field]]),ignore_attr=TRUE)
  for(field in c("grand_mean","total_covariance","between_covariance",
      "within_covariance","participant_eigenvalues",
      "trial_eigenvalues","participant_eigenfunctions",
      "trial_eigenfunctions","quadrature_weights")){
    expect_equal(unname(native$fit[[field]]),
      unname(et_to_r(reticulate::py_get_attr(py$fit,field))),
      tolerance=3e-6,ignore_attr=TRUE,
      info=paste("multilevel workflow",field))
  }
  for(table_name in c("participant_scores","trial_scores",
      "score_diagnostics")){
    a<-native$tables[[table_name]]
    b<-et_to_r(py$tables[[table_name]])
    expect_identical(names(a),names(b))
    for(j in names(a)){
      if(is.numeric(a[[j]]))
        expect_equal(as.numeric(a[[j]]),as.numeric(b[[j]]),
          tolerance=3e-6,info=paste(table_name,j))
      else expect_identical(as.character(a[[j]]),
        as.character(b[[j]]))
    }
  }
  proper<-.etr_spn_source_fixture()
  cal<-.etr_spnpc_fixture()
  target<-.etr_spnpc_partial_target_safe()
  pcfg<-.etr_spw2_prediction_cfg()
  rpred<-etr_run_sparse_prediction_workflow(proper,cal,target,pcfg,
    strict_source_record=TRUE)
  training_config<-pcfg$training[names(pcfg$training)!="backend"]
  training_config$evaluation_grid<-reticulate::r_to_py(
    as.numeric(training_config$evaluation_grid))
  pytcfg<-do.call(reticulate::py_call,c(
    list(wf$SparseFPCAWorkflowConfig),training_config))
  py_pred_cfg<-reticulate::py_call(
    wf$SparsePredictionWorkflowConfig,training=pytcfg,
    history_cutoff=.5,prediction_grid=reticulate::r_to_py(c(.60,.72,.84)),
    alpha=.30,group_column="batch")
  pp<-reticulate::py_call(wf$run_sparse_prediction_workflow,
    proper_training=make(proper,"batch"),
    calibration=make(cal,"batch"),target=make(target,"batch"),
    config=py_pred_cfg)
  expect_identical(names(rpred),as.character(et_to_r(
    reticulate::py_eval(
      "tuple(wf.SparsePredictionWorkflowResult.__dataclass_fields__)",
      convert=FALSE))))
  expect_identical(names(rpred$config),as.character(et_to_r(
    reticulate::py_eval(
      "tuple(wf.SparsePredictionWorkflowConfig.__dataclass_fields__)",
      convert=FALSE))))
  expect_identical(names(rpred$decisions),
    names(et_to_r(pp$decisions)))
  expect_identical(names(rpred$provenance),
    names(et_to_r(pp$provenance)))
  for(field in names(rpred$provenance))
    expect_equal(rpred$provenance[[field]],
      et_to_r(pp$provenance[[field]]),ignore_attr=TRUE)
  for(field in c("critical_value","unit_scores")){
    expect_equal(unname(rpred$calibration[[field]]),
      unname(et_to_r(reticulate::py_get_attr(pp$calibration,field))),
      tolerance=3e-6,ignore_attr=TRUE,
      info=paste("prediction conformal calibration",field))
  }
  for(field in c("lower","upper"))
    expect_equal(unname(rpred$band[[field]]),
      unname(et_to_r(reticulate::py_get_attr(pp$band,field))),
      tolerance=3e-6,ignore_attr=TRUE,
      info=paste("prediction conformal band",field))
  for(table_name in c("training_scores","calibration_curve_scores",
      "prediction_band")){
    a<-rpred$tables[[table_name]];b<-et_to_r(pp$tables[[table_name]])
    expect_identical(names(a),names(b))
    for(j in names(a)){
      if(is.numeric(a[[j]]))
        expect_equal(as.numeric(a[[j]]),as.numeric(b[[j]]),
          tolerance=3e-6,info=paste("prediction table",table_name,j))
      else expect_identical(as.character(a[[j]]),
        as.character(b[[j]]))
    }
  }
  expect_length(rpred$steps,length(et_to_r(pp$steps)))
  for(i in seq_along(rpred$steps)){
    expect_identical(rpred$steps[[i]]$name,
      et_to_r(pp$steps[[i]]$name))
    expect_identical(rpred$steps[[i]][["function"]],
      et_to_r(pp$steps[[i]][["function"]]))
    expect_identical(rpred$steps[[i]]$status,
      et_to_r(pp$steps[[i]]$status))
    expect_true(is.finite(rpred$steps[[i]]$elapsed_seconds))
  }
})
