# Frozen eyetrajectoriespy==1.2.0 workflows/_dense_regression.py and
# reporting.py at c1cd95ad718327550f7e55393ff38582872f7a94.
# W3 dense FPCA and observed-grid HC1 FOS source scientific records.
# Python sklearn object/dataclass identity and wall-clock times are
# language-specific; FPCA score signs are mathematically unidentifiable.

.etr_w3_source_pair_fixture<-function(){
  t<-seq(0,1,length.out=15L); n<-16L
  values<-array(0,c(n,length(t),2L))
  for(i in seq_len(n)){
    values[i,,1L]<-sin(pi*t)*(1+i/17)+
      .11*cos(2*pi*t)*(i%%4)+t*i/18
    values[i,,2L]<-cos(2*pi*t)*(.4+i/29)+
      .09*sin(pi*t)*(i%%3)+.05*t*i
  }
  subject<-rep(sprintf("p%02d",seq_len(8L)),each=2L)
  x<-etr_trajectory_set(t,values,sprintf("c%02d",seq_len(n)),
    c("x","y"),metadata=data.frame(subject=subject),
    coordinate_system="normalized",time_unit="s")
  design<-data.frame(curve_id=x$curve_ids,
    treatment=rep(seq_len(8L)/8,each=2L))
  list(x=x,design=design)
}
.etr_w3_source_outer<-c("workflow_schema_version",
  "workflow_contract","config","fit","steps","decisions",
  "provenance","reports","tables")

test_that("full W3 source FPCA output has real timing, source reports and variance tables",{
  fixture<-.etr_w3_source_pair_fixture()
  for(count in list(1L,2L,.85))
    for(scale in c("none","dimension_sd")){
      z<-etr_run_fpca_workflow(fixture$x,
        config=list(n_components=count,scaling=scale),
        python_boundary_mode=TRUE)
      expect_identical(names(z),.etr_w3_source_outer)
      expect_identical(names(z$config),
        c("n_components","scaling","preprocessing"))
      expect_identical(names(z$config$preprocessing),"steps")
      expect_length(z$config$preprocessing$steps,0L)
      expect_identical(names(z$provenance),c(
        "input_layout","preprocessing_executed",
        "automatic_model_selection_performed",
        "component_resolution_rule_changed"))
      expect_identical(names(z$decisions),c(
        "requested_n_components","retained_n_components","scaling"))
      expect_identical(length(z$steps),1L)
      expect_identical(z$steps[[1L]][["function"]],"fit_fpca")
      expect_identical(z$steps[[1L]]$name,"fit")
      expect_true(is.finite(z$steps[[1L]]$elapsed_seconds)&&
        z$steps[[1L]]$elapsed_seconds>=0)
      expect_identical(z$fit$provenance$fpca$method,
        "quadrature_weighted_grid_pca")
      expect_identical(z$fit$provenance$fpca$scaling,scale)
      expect_identical(z$fit$provenance$fpca$n_components,
        z$fit$n_components)
      expect_identical(names(z$tables$explained_variance),c(
        "component","explained_variance",
        "explained_variance_ratio","cumulative_variance_ratio"))
      expect_equal(z$tables$explained_variance$explained_variance,
        z$fit$explained_variance,tolerance=0)
      expect_identical(names(z$tables$scores),
        c("curve_id",paste0("FPC",seq_len(z$fit$n_components))))
      expect_match(z$reports$fit,"Functional PCA retained",fixed=TRUE)
      expect_match(z$reports$fit,"weighted functional variance",fixed=TRUE)
      expect_false(z$provenance$automatic_model_selection_performed)
      old<-etr_run_fpca_workflow(fixture$x,
        config=list(n_components=count,scaling=scale))
      expect_true("source_schema_equivalent"%in%names(old$provenance))
      expect_false(old$provenance$source_schema_equivalent)
      expect_equal(old$fit$explained_variance,z$fit$explained_variance,
        tolerance=0)
    }
})

test_that("full W3 FOS source workflow covers curve and participant inference",{
  fixture<-.etr_w3_source_pair_fixture()
  cases<-list(
    curve_both=list(predictors="treatment",unit="curve"),
    curve_x=list(predictors="treatment",dimensions="x",unit="curve"),
    participant_both=list(predictors="treatment",
      participant_column="subject",unit="participant"),
    participant_y=list(predictors="treatment",dimensions="y",
      participant_column="subject",unit="participant"))
  for(label in names(cases)){
    cfg<-cases[[label]]
    z<-etr_run_function_on_scalar_workflow(fixture$x,fixture$design,
      config=cfg,python_boundary_mode=TRUE)
    expect_identical(names(z),.etr_w3_source_outer)
    expect_identical(names(z$config),c(
      "predictors","dimensions","participant_column","unit",
      "preprocessing"))
    expect_identical(names(z$config$preprocessing),"steps")
    expect_length(z$config$preprocessing$steps,0L)
    expect_identical(names(z$decisions),c(
      "predictors","dimensions","participant_column","unit"))
    expect_identical(names(z$provenance),c(
      "input_layout","preprocessing_executed",
      "automatic_predictor_encoding",
      "automatic_model_selection_performed",
      "functional_mixed_effects_inferred"))
    expect_identical(z$steps[[1L]][["function"]],
      "fit_function_on_scalar_regression")
    expect_true(is.finite(z$steps[[1L]]$elapsed_seconds)&&
      z$steps[[1L]]$elapsed_seconds>=0)
    expect_false(z$provenance$functional_mixed_effects_inferred)
    expect_identical(names(z$tables$coefficients),c(
      "coefficient","time","dimension","estimate","standard_error"))
    expect_identical(nrow(z$tables$coefficients),
      length(z$fit$coefficient_names)*length(z$fit$time)*
        length(z$fit$dimension_names))
    expect_match(z$reports$fit,
      "ordinary least squares independently at each observed",fixed=TRUE)
    expect_match(z$reports$fit,"HC1 sandwich estimator",fixed=TRUE)
    if(identical(cfg$unit,"participant")){
      expect_match(z$reports$fit,"participant-average",fixed=TRUE)
      expect_identical(length(z$fit$unit_ids),8L)
    }else
      expect_match(z$reports$fit,
        "curve-level functional responses",fixed=TRUE)
    ordinary<-etr_run_function_on_scalar_workflow(
      fixture$x,fixture$design,cfg)
    expect_equal(ordinary$fit$coefficients,z$fit$coefficients,
      tolerance=0)
    expect_false(ordinary$provenance$source_schema_equivalent)
  }
})

test_that("W3 source modes fail closed without disrupting legacy defaults",{
  fixture<-.etr_w3_source_pair_fixture()
  expect_error(etr_run_fpca_workflow(fixture$x,
    python_boundary_mode=1),"python_boundary_mode")
  expect_error(etr_run_fpca_workflow(fixture$x,
    python_boundary_mode=NA),"python_boundary_mode")
  expect_error(etr_run_fpca_workflow(fixture$x,
    config=list(preprocessing=list("smooth")),
    python_boundary_mode=TRUE),"empty preprocessing")
  expect_error(etr_run_function_on_scalar_workflow(
    fixture$x,fixture$design,list(predictors="treatment"),
    python_boundary_mode=1),"python_boundary_mode")
  expect_error(etr_run_function_on_scalar_workflow(
    fixture$x,fixture$design,list(predictors="treatment",
      unit="curve",participant_column="subject"),
    python_boundary_mode=TRUE),"participant_column")
  expect_error(etr_run_function_on_scalar_workflow(
    fixture$x,fixture$design,list(predictors="treatment",
      preprocessing=list("smooth")),
    python_boundary_mode=TRUE),"empty preprocessing")
})

test_that("pinned Python 1.2 W3 full workflows agree in scientific estimands and reports",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 W3 typed source-scientific oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
import eyetrajectoriespy as et
from eyetrajectoriespy.workflows._dense_regression import (
  FPCAWorkflowConfig, FunctionOnScalarWorkflowConfig)
w3_t=np.linspace(0,1,15); w3_values=np.empty((16,15,2))
for i in range(1,17):
 w3_values[i-1,:,0]=(np.sin(np.pi*w3_t)*(1+i/17)+
    .11*np.cos(2*np.pi*w3_t)*(i%4)+w3_t*i/18)
 w3_values[i-1,:,1]=(np.cos(2*np.pi*w3_t)*(.4+i/29)+
    .09*np.sin(np.pi*w3_t)*(i%3)+.05*w3_t*i)
w3_subject=[f'p{(i+1)//2:02d}' for i in range(1,17)]
w3_x=et.TrajectorySet(time=w3_t,values=w3_values,
 curve_ids=tuple(f'c{i:02d}' for i in range(1,17)),
 dimension_names=('x','y'),
 metadata=pd.DataFrame({'subject':w3_subject}),
 coordinate_system='normalized',time_unit='s')
w3_design=pd.DataFrame({
 'curve_id':[f'c{i:02d}' for i in range(1,17)],
 'treatment':np.repeat(np.arange(1,9)/8.,2)})
")
  fixture<-.etr_w3_source_pair_fixture()
  py_fpca<-etpy_get_export("run_fpca_workflow",.namespace="workflows")
  py_fos<-etpy_get_export("run_function_on_scalar_workflow",
    .namespace="workflows")
  for(spec in list(
    list(n=1L,scale="none"),list(n=2L,scale="dimension_sd"),
    list(n=.85,scale="none"))){
    actual<-etr_run_fpca_workflow(fixture$x,list(
      n_components=spec$n,scaling=spec$scale),python_boundary_mode=TRUE)
    py_config<-reticulate::py_call(
      reticulate::py_eval("FPCAWorkflowConfig",convert=FALSE),
      n_components=spec$n,scaling=spec$scale)
    oracle<-reticulate::py_call(py_fpca,
      trajectories=reticulate::py_eval("w3_x",convert=FALSE),
      config=py_config)
    expect_identical(actual$reports$fit,et_to_r(oracle$reports[["fit"]]))
    expect_identical(names(actual$provenance),
      names(et_to_r(oracle$provenance)))
    for(key in names(actual$provenance))
      expect_identical(actual$provenance[[key]],
        et_to_r(oracle$provenance)[[key]])
    expect_equal(actual$fit$mean,et_to_r(oracle$fit$mean),
      tolerance=1e-10,ignore_attr=TRUE)
    expect_equal(actual$fit$explained_variance,
      et_to_r(oracle$fit$explained_variance),tolerance=1e-9,
      ignore_attr=TRUE)
    expect_equal(actual$fit$explained_variance_ratio,
      et_to_r(oracle$fit$explained_variance_ratio),
      tolerance=1e-9,ignore_attr=TRUE)
    expected_scores<-et_to_r(oracle$tables[["scores"]])
    expect_identical(names(actual$tables$scores),
      names(expected_scores))
    expect_equal(tcrossprod(actual$fit$scores),
      tcrossprod(et_to_r(oracle$fit$scores)),tolerance=1e-7,
      ignore_attr=TRUE,info="FPCA score signed-basis invariant")
    expected_variance<-et_to_r(oracle$tables[["explained_variance"]])
    expect_identical(names(actual$tables$explained_variance),
      names(expected_variance))
    for(key in names(expected_variance))
      expect_equal(actual$tables$explained_variance[[key]],
        expected_variance[[key]],tolerance=1e-9,ignore_attr=TRUE)
    expect_identical(actual$steps[[1L]]$name,"fit")
    expect_identical(actual$steps[[1L]][["function"]],"fit_fpca")
    expect_identical(actual$decisions$retained_n_components$criterion,
      et_to_r(oracle$decisions[["retained_n_components"]]$criterion))
  }
  for(cfg in list(
    list(predictors="treatment",unit="curve"),
    list(predictors="treatment",unit="participant",
      participant_column="subject"),
    list(predictors="treatment",dimensions="x",unit="curve"))){
    actual<-etr_run_function_on_scalar_workflow(fixture$x,
      fixture$design,cfg,python_boundary_mode=TRUE)
    kw<-list(predictors=reticulate::tuple("treatment"),unit=cfg$unit)
    if(!is.null(cfg$dimensions))
      kw$dimensions<-reticulate::tuple(cfg$dimensions)
    if(!is.null(cfg$participant_column))
      kw$participant_column<-cfg$participant_column
    py_config<-do.call(reticulate::py_call,
      c(list(reticulate::py_eval("FunctionOnScalarWorkflowConfig",
        convert=FALSE)),kw))
    oracle<-reticulate::py_call(py_fos,
      trajectories=reticulate::py_eval("w3_x",convert=FALSE),
      design=reticulate::py_eval("w3_design",convert=FALSE),
      config=py_config)
    expect_equal(actual$fit$coefficients,
      et_to_r(oracle$fit$coefficients),tolerance=1e-9,ignore_attr=TRUE)
    expect_equal(actual$fit$standard_errors,
      et_to_r(oracle$fit$standard_errors),tolerance=1e-8,
      ignore_attr=TRUE)
    expect_identical(actual$reports$fit,et_to_r(oracle$reports[["fit"]]))
    expect_identical(names(actual$provenance),
      names(et_to_r(oracle$provenance)))
    expect_identical(actual$steps[[1L]][["function"]],
      "fit_function_on_scalar_regression")
    expected_table<-et_to_r(oracle$tables[["coefficients"]])
    expect_identical(names(actual$tables$coefficients),
      names(expected_table))
    for(key in names(expected_table))
      expect_equal(actual$tables$coefficients[[key]],
        expected_table[[key]],tolerance=1e-8,ignore_attr=TRUE,
        info=paste("source FOS workflow coefficient",cfg$unit,key))
    expect_identical(names(actual$decisions),
      names(et_to_r(oracle$decisions)))
    expect_identical(actual$decisions$unit$value,
      et_to_r(oracle$decisions[["unit"]]$value))
  }
})
