# Frozen Python eyetrajectoriespy==1.2.0; commit:
# c1cd95ad718327550f7e55393ff38582872f7a94
# workflows/_sparse_fpca.py::run_sparse_fpca_workflow
# Strict mode returns scientific source fields, never a Python dataclass.
.etr_sparse_w2_source_case<-function(uncertainty=FALSE){
  x<-.etr_spn_source_fixture()
  cfg<-list(backend="native_covariance",
    dimension="signal",n_components=1L,
    evaluation_grid=seq(.08,.92,length.out=9L),
    mean_bandwidth=.50,covariance_bandwidth=.85,
    noise_variance_method="fixed",measurement_error_variance=.07,
    analysis_support_action="restrict",psd_action="project",
    score_ridge=.002,score_condition_limit=1e12,
    mean_min_local_points=3L,covariance_min_local_pairs=6L)
  if(uncertainty)cfg$score_uncertainty<-list()
  list(x=x,cfg=cfg)
}
.etr_sparse_w2_source_names<-c(
  "workflow_schema_version","workflow_contract","config","fit",
  "bandwidth_selection","score_uncertainty",
  "observation_diagnostics","steps","decisions","provenance",
  "reports","tables")
.etr_sparse_w2_source_decisions<-c(
  "n_components","mean_bandwidth","covariance_bandwidth",
  "noise_variance_method","psd_action",
  "score_uncertainty_requested",
  "observation_diagnostics_requested")
.etr_sparse_w2_source_provenance<-c(
  "raw_interpolation_performed","native_observation_grids_retained",
  "bandwidth_mode","automatic_model_selection_performed")
.etr_sparse_w2_source_config<-c(
  "dimension","n_components","evaluation_grid","mean_bandwidth",
  "covariance_bandwidth","bandwidth_selection","noise_bandwidth",
  "noise_support","analysis_support_action","mean_smoother",
  "covariance_smoother","kernel","noise_variance_method",
  "measurement_error_variance","psd_action","psd_tolerance",
  "positive_eigen_tolerance","score_ridge","score_condition_limit",
  "min_score_samples","score_failure_action",
  "mean_min_local_points","covariance_min_local_pairs",
  "noise_min_local_points","score_uncertainty",
  "observation_diagnostics","preprocessing")

test_that("native sparse W2 fixed-bandwidth and conditional-score modes have 12 canonical fields",{
  for(with_uncertainty in c(FALSE,TRUE)){
    f<-.etr_sparse_w2_source_case(with_uncertainty)
    legacy<-etr_run_sparse_fpca_workflow(f$x,f$cfg)
    strict<-etr_run_sparse_fpca_workflow(
      f$x,f$cfg,strict_source_record=TRUE)
    expect_s3_class(strict,"etr_sparse_fpca_source_workflow")
    expect_identical(names(strict),.etr_sparse_w2_source_names)
    expect_identical(strict$workflow_schema_version,1L)
    expect_identical(strict$workflow_contract,"sparse_fpca:v1")
    expect_identical(names(strict$config),.etr_sparse_w2_source_config)
    expect_identical(names(strict$config$preprocessing),"steps")
    expect_length(strict$config$preprocessing$steps,0L)
    expect_true(is.null(strict$config$bandwidth_selection))
    expect_identical(names(strict$decisions),.etr_sparse_w2_source_decisions)
    expect_identical(names(strict$provenance),.etr_sparse_w2_source_provenance)
    expect_identical(strict$provenance$bandwidth_mode,"fixed")
    expect_true(strict$provenance$native_observation_grids_retained)
    expect_false(strict$provenance$raw_interpolation_performed)
    expect_false(strict$provenance$automatic_model_selection_performed)
    expect_null(strict$bandwidth_selection)
    expect_null(strict$observation_diagnostics)
    expect_equal(strict$fit$scores,legacy$fit$scores,tolerance=0)
    expect_equal(strict$fit$covariance,legacy$fit$covariance,tolerance=0)
    expect_identical(names(strict$tables),
      if(with_uncertainty)c("scores","score_uncertainty")else"scores")
    expect_identical(names(strict$reports),
      if(with_uncertainty)c("fit","score_uncertainty")else"fit")
    expect_identical(strict$tables$scores,legacy$tables$scores)
    expect_identical(strict$reports$fit,legacy$reports$fit)
    expect_identical(strict$decisions$n_components$value,1L)
    expect_identical(strict$decisions$mean_bandwidth$source,"analyst")
    expect_identical(strict$decisions$covariance_bandwidth$source,"analyst")
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
      expect_true(inherits(strict$score_uncertainty,
        "etr_sparse_fpca_score_uncertainty_native"))
      expect_identical(names(strict$config$score_uncertainty),
        c("condition_limit","failure_action"))
      expect_identical(strict$config$score_uncertainty$failure_action,"error")
      expect_identical(strict$tables$score_uncertainty,
        legacy$tables$score_uncertainty)
    } else expect_null(strict$score_uncertainty)
  }
})

test_that("strict native sparse W2 rejects R-only estimator and malformed source config",{
  f<-.etr_sparse_w2_source_case()
  expect_error(etr_run_sparse_fpca_workflow(f$x,f$cfg,
    strict_source_record=NA),"strict_source_record")
  expect_error(etr_run_sparse_fpca_workflow(f$x,f$cfg,
    strict_source_record=1L),"strict_source_record")
  bad<-f$cfg;bad$backend<-"fdapace"
  expect_error(etr_run_sparse_fpca_workflow(f$x,bad,
    strict_source_record=TRUE),"native_covariance")
  bad<-f$cfg
  bad$bandwidth_selection<-list(mean_bandwidths=.5,
    covariance_bandwidths=.85,fold_assignments=rep(0L,24L))
  bad$mean_bandwidth<-bad$covariance_bandwidth<-NULL
  expect_error(etr_run_sparse_fpca_workflow(f$x,bad,
    strict_source_record=TRUE),"fold_assignments|fold assignments")
  # Legacy result retains honest R backend and extended diagnostics.
  legacy<-etr_run_sparse_fpca_workflow(f$x,f$cfg)
  expect_identical(legacy$workflow_contract,
    "sparse_fpca:native_local_linear_fixed_noise")
  expect_false(legacy$provenance$full_source_contract_certified)
  expect_true("score_diagnostics"%in%names(legacy$tables))
})

test_that("frozen Python 1.2 W2 sparse workflow agrees with native source scientific fit and schema",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("requires frozen Python 1.2 sparse PACE workflow oracle")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as _w2et
def _w2_make_irregular(times,values,ids,metadata):
    return _w2et.IrregularTrajectorySet(
      time=tuple(np.asarray(t,dtype=float) for t in times),
      values=tuple(np.asarray(v,dtype=float) for v in values),
      curve_ids=tuple(str(k) for k in ids),
      dimension_names=('signal',),
      metadata=pd.DataFrame(metadata),
      coordinate_system='degrees',time_unit='s')
")
  for(with_uncertainty in c(FALSE,TRUE)){
    f<-.etr_sparse_w2_source_case(with_uncertainty)
    native<-etr_run_sparse_fpca_workflow(
      f$x,f$cfg,strict_source_record=TRUE)
    pyx<-reticulate::py_call(
      reticulate::py_eval("_w2_make_irregular",convert=FALSE),
      times=reticulate::r_to_py(f$x$time),
      values=reticulate::r_to_py(f$x$values),
      ids=reticulate::r_to_py(f$x$curve_ids),
      metadata=reticulate::r_to_py(lapply(f$x$metadata,as.list)))
    config_args<-list(
      dimension="signal",n_components=1L,
      evaluation_grid=reticulate::r_to_py(as.numeric(f$cfg$evaluation_grid)),
      mean_bandwidth=.5,covariance_bandwidth=.85,
      noise_variance_method="fixed",
      measurement_error_variance=.07,
      analysis_support_action="restrict",psd_action="project",
      score_ridge=.002,score_condition_limit=1e12,
      mean_min_local_points=3L,covariance_min_local_pairs=6L)
    if(with_uncertainty)
      config_args$score_uncertainty<-reticulate::py_call(
        etpy_get_export("ScoreUncertaintyConfig",.namespace="workflows"))
    pycfg<-do.call(reticulate::py_call,c(list(
      etpy_get_export("SparseFPCAWorkflowConfig",.namespace="workflows")),
      config_args))
    py<-reticulate::py_call(
      etpy_get_export("run_sparse_fpca_workflow",.namespace="workflows"),
      trajectories=pyx,config=pycfg)
    expect_identical(names(native),.etr_sparse_w2_source_names)
    expect_identical(native$workflow_contract,
      et_to_r(py$workflow_contract))
    expect_identical(names(native$provenance),
      names(et_to_r(py$provenance)))
    for(field in names(native$provenance))
      expect_equal(native$provenance[[field]],
        et_to_r(py$provenance[[field]]),ignore_attr=TRUE)
    expect_identical(names(native$decisions),
      names(et_to_r(py$decisions)))
    for(field in names(native$decisions)){
      expected<-py$decisions[[field]]
      expect_equal(native$decisions[[field]]$value,
        et_to_r(expected$value),ignore_attr=TRUE,
        info=paste("decision",field))
      expect_identical(native$decisions[[field]]$source,
        et_to_r(expected$source))
    }
    for(field in c("mean","covariance","eigenvalues",
        "eigenfunctions","scores","quadrature_weights"))
      expect_equal(unname(native$fit[[field]]),
        unname(et_to_r(reticulate::py_get_attr(py$fit,field))),
        tolerance=2e-6,ignore_attr=TRUE,
        info=paste("source sparse workflow fit",field))
    pyframe<-et_to_r(py$tables[["scores"]])
    expect_identical(names(native$tables$scores),names(pyframe))
    for(field in names(pyframe)){
      if(is.numeric(native$tables$scores[[field]]))
        expect_equal(as.numeric(native$tables$scores[[field]]),
          as.numeric(pyframe[[field]]),tolerance=2e-6,
          info=paste("score table",field))
      else expect_identical(
        as.character(native$tables$scores[[field]]),
        as.character(pyframe[[field]]))
    }
    expect_length(native$steps,length(et_to_r(py$steps)))
    for(i in seq_along(native$steps)){
      expect_identical(native$steps[[i]]$name,
        et_to_r(py$steps[[i-1L]]$name))
      expect_identical(native$steps[[i]][["function"]],
        et_to_r(py$steps[[i]][["function"]]))
      expect_identical(native$steps[[i]]$status,
        et_to_r(py$steps[[i]]$status))
    }
    if(with_uncertainty){
      for(field in c("covariance","standard_errors","correlations"))
        expect_equal(unname(native$score_uncertainty[[field]]),
          unname(et_to_r(reticulate::py_get_attr(py$score_uncertainty,field))),
          tolerance=2e-6,ignore_attr=TRUE)
    }
  }
})
