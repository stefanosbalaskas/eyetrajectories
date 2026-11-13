# Frozen eyetrajectoriespy==1.2.0, commit
# c1cd95ad718327550f7e55393ff38582872f7a94,
# workflows/_sparse_mfpca.py and workflows/_sparse_async.py.
# Two native source-scientific W2 contracts; no Python object impersonation.

.etr_mfpca_w2_paired_keys<-c(
  "workflow_schema_version","workflow_contract","config","fit",
  "bandwidth_selection","score_uncertainty","observation_diagnostics",
  "steps","decisions","provenance","reports","tables")
.etr_mfpca_w2_async_keys<-c(
  "workflow_schema_version","workflow_contract","config","fit",
  "observation_diagnostics","steps","decisions","provenance","reports","tables")
.etr_mfpca_w2_paired_config_keys<-c(
  "n_components","evaluation_grid","measurement_error",
  "dimensions","mean_bandwidth","covariance_bandwidth",
  "bandwidth_selection","measurement_error_variance",
  "measurement_error_covariance","analysis_support_action",
  "psd_action","psd_tolerance","positive_eigen_tolerance",
  "score_ridge","score_condition_limit","min_score_time_points",
  "score_failure_action","mean_min_local_points",
  "covariance_min_local_pairs","score_uncertainty",
  "observation_diagnostics","preprocessing")
.etr_mfpca_w2_async_config_keys<-c(
  "n_components","evaluation_grid","mean_bandwidth",
  "covariance_bandwidth","measurement_error","dimensions",
  "measurement_error_variance","measurement_error_covariance",
  "analysis_support_action","same_time_tolerance",
  "psd_action","psd_tolerance","positive_eigen_tolerance",
  "score_ridge","score_condition_limit","min_score_observations",
  "score_failure_action","mean_min_local_points",
  "covariance_min_local_pairs","observation_diagnostics","preprocessing")
.etr_mfpca_w2_paired_decision_keys<-c(
  "n_components","mean_bandwidth","covariance_bandwidth",
  "measurement_error","psd_action",
  "score_uncertainty_requested","observation_diagnostics_requested")
.etr_mfpca_w2_async_decision_keys<-c(
  "n_components","mean_bandwidth","covariance_bandwidth",
  "measurement_error","same_time_tolerance","psd_action",
  "observation_diagnostics_requested")
.etr_mfpca_w2_paired_provenance_keys<-c(
  "raw_interpolation_performed","native_paired_observation_grids_retained",
  "bandwidth_mode","automatic_model_selection_performed")
.etr_mfpca_w2_async_provenance_keys<-c(
  "raw_interpolation_performed","raw_synchronization_performed",
  "time_binning_performed","coordinate_specific_native_grids_retained",
  "bandwidth_mode","paired_bandwidth_selector_reused",
  "automatic_model_selection_performed")

test_that("paired native W2 fixed and uncertainty sources are canonical",{
  for(with_uncertainty in c(FALSE,TRUE)){
    x<-.etr_spnm_fixture()
    cfg<-c(list(backend="native_covariance"),.etr_spnm_args())
    if(with_uncertainty)cfg$score_uncertainty<-list(condition_limit=1e10)
    legacy<-etr_run_sparse_mfpca_workflow(x,cfg)
    strict<-etr_run_sparse_mfpca_workflow(x,cfg,strict_source_record=TRUE)
    expect_s3_class(strict,"etr_sparse_mfpca_paired_source_workflow")
    expect_identical(names(strict),.etr_mfpca_w2_paired_keys)
    expect_identical(strict$workflow_schema_version,1L)
    expect_identical(strict$workflow_contract,"sparse_mfpca:v1")
    expect_identical(names(strict$config),.etr_mfpca_w2_paired_config_keys)
    expect_identical(names(strict$config$preprocessing),"steps")
    expect_length(strict$config$preprocessing$steps,0L)
    expect_identical(names(strict$decisions),
      .etr_mfpca_w2_paired_decision_keys)
    expect_identical(names(strict$provenance),
      .etr_mfpca_w2_paired_provenance_keys)
    expect_identical(strict$provenance$bandwidth_mode,"fixed")
    expect_null(strict$bandwidth_selection)
    expect_null(strict$observation_diagnostics)
    expect_equal(strict$fit$scores,legacy$fit$scores,tolerance=0)
    expect_equal(strict$fit$eigenvalues,legacy$fit$eigenvalues,tolerance=0)
    expect_equal(strict$fit$covariance_cxy,
      legacy$fit$covariance_cxy,tolerance=0)
    expect_identical(names(strict$reports),
      if(with_uncertainty)c("fit","score_uncertainty")else"fit")
    expect_identical(names(strict$tables),
      if(with_uncertainty)c("scores","score_uncertainty")else"scores")
    expect_identical(strict$tables$scores,legacy$tables$scores)
    expect_identical(strict$decisions$measurement_error$value,"diagonal")
    expect_equal(strict$decisions$mean_bandwidth$value,.5)
    expect_equal(strict$decisions$covariance_bandwidth$value,.85)
    expect_identical(strict$decisions$score_uncertainty_requested$value,
      with_uncertainty)
    expect_length(strict$steps,if(with_uncertainty)2L else 1L)
    for(step in strict$steps){
      expect_identical(names(step),c("name","function","status",
        "parameters","elapsed_seconds","warnings"))
      expect_true(is.finite(step$elapsed_seconds))
      expect_gte(step$elapsed_seconds,0)
    }
    if(with_uncertainty){
      expect_identical(names(strict$config$score_uncertainty),
        c("condition_limit","failure_action"))
      expect_identical(strict$tables$score_uncertainty,
        legacy$tables$score_uncertainty)
    } else expect_null(strict$score_uncertainty)
  }
})

test_that("asynchronous native W2 retains coordinate-specific times and canonical records",{
  x<-.etr_spna_fixture()
  cfg<-c(list(backend="native_covariance"),.etr_spna_options())
  legacy<-etr_run_sparse_mfpca_async_workflow(x,cfg)
  strict<-etr_run_sparse_mfpca_async_workflow(x,cfg,
    strict_source_record=TRUE)
  expect_s3_class(strict,"etr_sparse_mfpca_async_source_workflow")
  expect_identical(names(strict),.etr_mfpca_w2_async_keys)
  expect_identical(strict$workflow_contract,"sparse_mfpca_async:v1")
  expect_identical(names(strict$config),.etr_mfpca_w2_async_config_keys)
  expect_identical(names(strict$decisions),
    .etr_mfpca_w2_async_decision_keys)
  expect_identical(names(strict$provenance),
    .etr_mfpca_w2_async_provenance_keys)
  expect_identical(names(strict$tables),"scores")
  expect_identical(names(strict$reports),"fit")
  expect_identical(strict$tables$scores,legacy$tables$scores)
  expect_equal(strict$fit$scores,legacy$fit$scores,tolerance=0)
  expect_equal(strict$fit$covariance_cxy,
    legacy$fit$covariance_cxy,tolerance=0)
  expect_identical(strict$decisions$measurement_error$value,"fixed_matrix")
  expect_identical(strict$provenance$bandwidth_mode,"fixed")
  expect_false(strict$provenance$raw_interpolation_performed)
  expect_false(strict$provenance$raw_synchronization_performed)
  expect_false(strict$provenance$time_binning_performed)
  expect_true(strict$provenance$coordinate_specific_native_grids_retained)
  expect_equal(strict$config$measurement_error_covariance,
    cfg$measurement_error_covariance)
  expect_identical(names(strict$config$preprocessing),"steps")
  expect_length(strict$steps,1L)
  expect_true(is.finite(strict$steps[[1L]]$elapsed_seconds))
  expect_gte(strict$steps[[1L]]$elapsed_seconds,0)
  expect_true(any(strict$fit$score_diagnostics$n_x_observations!=
    strict$fit$score_diagnostics$n_y_observations)||
    any(strict$fit$score_diagnostics$n_simultaneous_pairs>0L))
})

test_that("strict paired/async W2 mode rejects alternative estimator and supplied folds",{
  x<-.etr_spnm_fixture()
  p<-c(list(backend="native_covariance"),.etr_spnm_args())
  expect_error(etr_run_sparse_mfpca_workflow(x,p,
    strict_source_record=NA),"strict_source_record")
  expect_error(etr_run_sparse_mfpca_async_workflow(
    .etr_spna_fixture(),c(list(backend="native_covariance"),
      .etr_spna_options()),strict_source_record=1L),
    "strict_source_record")
  alt<-p;alt$backend<-"fdapace_joint_score_pca"
  expect_error(etr_run_sparse_mfpca_workflow(x,alt,
    strict_source_record=TRUE),"native_covariance")
  bad<-c(list(backend="native_covariance"),.etr_spna_options())
  bad$backend<-"fdapace_joint_score_pca"
  expect_error(etr_run_sparse_mfpca_async_workflow(
    .etr_spna_fixture(),bad,strict_source_record=TRUE),
    "native_covariance")
  p$mean_bandwidth<-p$covariance_bandwidth<-NULL
  p$bandwidth_selection<-list(mean_bandwidths=.5,
    covariance_bandwidths=.85,fold_assignments=rep(0L,24L))
  expect_error(etr_run_sparse_mfpca_workflow(x,p,
    strict_source_record=TRUE),"fold assignments")
})

test_that("direct Python 1.2 paired and async sparse W2 workflows match source scientific outputs",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("requires frozen Python 1.2 MFPCA paired and async W2 oracles")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np,pandas as pd
import eyetrajectoriespy as et
import eyetrajectoriespy.workflows as wf
def _w2_mfpca_input(times,values,ids,group_column,groups):
    return et.IrregularTrajectorySet(
      time=tuple(np.asarray(t,dtype=float) for t in times),
      values=tuple(np.asarray(v,dtype=float) for v in values),
      curve_ids=tuple(str(s) for s in ids),
      dimension_names=('x','y'),
      metadata=pd.DataFrame({group_column:list(groups)}),
      coordinate_system='degrees',time_unit='s')
")
  wf<-reticulate::import("eyetrajectoriespy.workflows",convert=FALSE)
  make<-reticulate::py_eval("_w2_mfpca_input",convert=FALSE)
  for(which in c("paired","async")){
    is_async<-identical(which,"async")
    x<-if (is_async) .etr_spna_fixture() else .etr_spnm_fixture()
    cfg<-c(list(backend="native_covariance"),
      if (is_async) .etr_spna_options() else .etr_spnm_args())
    if(!is_async)cfg$score_uncertainty<-list(condition_limit=1e10)
    group<-if (is_async) "batch" else "block"
    pyx<-reticulate::py_call(make,
      times=reticulate::r_to_py(x$time),
      values=reticulate::r_to_py(x$values),
      ids=reticulate::r_to_py(as.list(x$curve_ids)),
      group_column=group,
      groups=reticulate::r_to_py(as.list(x$metadata[[group]])))
    pycfg<-cfg[names(cfg)!="backend"]
    pycfg$dimensions<-reticulate::tuple("x","y")
    pycfg$evaluation_grid<-reticulate::r_to_py(
      as.numeric(cfg$evaluation_grid))
    if(!is.null(cfg$measurement_error_variance))
      pycfg$measurement_error_variance<-reticulate::tuple(
        cfg$measurement_error_variance[[1L]],
        cfg$measurement_error_variance[[2L]])
    if(!is.null(cfg$measurement_error_covariance))
      pycfg$measurement_error_covariance<-reticulate::r_to_py(
        cfg$measurement_error_covariance)
    if(!is_async)
      pycfg$score_uncertainty<-reticulate::py_call(
        wf$ScoreUncertaintyConfig,condition_limit=1e10)
    source_config<-do.call(reticulate::py_call,c(
      list(if (is_async) wf$SparseMFPCAAsyncWorkflowConfig
        else wf$SparseMFPCAWorkflowConfig),pycfg))
    source<-reticulate::py_call(
      if (is_async) wf$run_sparse_mfpca_async_workflow
        else wf$run_sparse_mfpca_workflow,
      trajectories=pyx,config=source_config)
    native<-if (is_async) etr_run_sparse_mfpca_async_workflow(
      x,cfg,strict_source_record=TRUE)else
        etr_run_sparse_mfpca_workflow(x,cfg,strict_source_record=TRUE)
    expect_identical(names(native),
      if (is_async) .etr_mfpca_w2_async_keys
      else .etr_mfpca_w2_paired_keys)
    expect_identical(native$workflow_contract,
      et_to_r(source$workflow_contract))
    source_keys<-reticulate::py_to_r(reticulate::py_eval(
      if (is_async) "tuple(wf.SparseMFPCAAsyncWorkflowResult.__dataclass_fields__)"
      else"tuple(wf.SparseMFPCAWorkflowResult.__dataclass_fields__)",
      convert=FALSE))
    expect_identical(names(native),as.character(source_keys))
    config_keys<-reticulate::py_to_r(reticulate::py_eval(
      if (is_async) "tuple(wf.SparseMFPCAAsyncWorkflowConfig.__dataclass_fields__)"
      else"tuple(wf.SparseMFPCAWorkflowConfig.__dataclass_fields__)",
      convert=FALSE))
    expect_identical(names(native$config),as.character(config_keys))
    expect_identical(names(native$provenance),
      names(et_to_r(source$provenance)))
    expect_identical(names(native$decisions),
      names(et_to_r(source$decisions)))
    for(n in names(native$provenance))
      expect_equal(native$provenance[[n]],
        et_to_r(source$provenance[[n]]),ignore_attr=TRUE)
    for(n in names(native$decisions)){
      expected<-source$decisions[[n]]
      expect_equal(native$decisions[[n]]$value,
        et_to_r(expected$value),ignore_attr=TRUE)
      expect_identical(native$decisions[[n]]$source,
        et_to_r(expected$source))
    }
    for(n in c("mean","eigenvalues","eigenfunctions","scores",
        "smoothed_cxx","smoothed_cxy","smoothed_cyy",
        "covariance_cxx","covariance_cxy","covariance_cyy",
        "quadrature_weights","measurement_error_covariance")){
      expect_equal(unname(native$fit[[n]]),
        unname(et_to_r(reticulate::py_get_attr(source$fit,n))),
        tolerance=3e-6,ignore_attr=TRUE,
        info=paste(which,"frozen Python",n))
    }
    pyframe<-et_to_r(source$tables[["scores"]])
    expect_identical(names(native$tables$scores),names(pyframe))
    for(n in names(pyframe)){
      if(is.numeric(native$tables$scores[[n]]))
        expect_equal(as.numeric(native$tables$scores[[n]]),
          as.numeric(pyframe[[n]]),tolerance=3e-6,
          info=paste(which,"score frame",n))
      else
        expect_identical(as.character(native$tables$scores[[n]]),
          as.character(pyframe[[n]]))
    }
    expect_length(native$steps,length(et_to_r(source$steps)))
    for(i in seq_along(native$steps)){
      expect_identical(native$steps[[i]]$name,
        et_to_r(source$steps[[i]]$name))
      expect_identical(native$steps[[i]][["function"]],
        et_to_r(source$steps[[i]][["function"]]))
      expect_identical(native$steps[[i]]$status,
        et_to_r(source$steps[[i]]$status))
      expect_true(is.finite(native$steps[[i]]$elapsed_seconds))
    }
    if(!is_async){
      expect_equal(unname(native$score_uncertainty$covariance),
        unname(et_to_r(source$score_uncertainty$covariance)),
        tolerance=3e-6,ignore_attr=TRUE)
    }
  }
})
