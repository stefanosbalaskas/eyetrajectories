# Frozen 1.2 workflows/_dense_regression.py W3 contract subset.
.etr_source_workflow_fixture <- function() {
  n<-12L;time<-seq(0,1,length.out=15L)
  values<-array(0,c(n,length(time),1L))
  for(i in seq_len(n))
    values[i,,1L]<-sin(pi*time)*(1+i/19)+
      .13*cos(2*pi*time)*(i%%3)+time*i/15
  x<-etr_trajectory_set(time,values,sprintf("c%02d",seq_len(n)),
    "gaze",coordinate_system="normalized",time_unit="s")
  list(x=x,design=data.frame(curve_id=x$curve_ids,
    treatment=seq_len(n)/n))
}
test_that("native FPCA workflow does not silently preprocess or select models",{
  z<-.etr_source_workflow_fixture()
  out<-etr_run_fpca_workflow(z$x,
    config=list(n_components=1L,scaling="none",preprocessing=list()))
  expect_s3_class(etr_run_fpca_workflow(z$x),"etr_fpca_workflow")
  expect_s3_class(out,"etr_fpca_workflow")
  expect_s3_class(out$fit,"etr_fpca")
  expect_identical(out$workflow_contract,"fpca:v1")
  expect_identical(out$workflow_schema_version,1L)
  expect_identical(out$fit$n_components,1L)
  expect_identical(out$fit$explained_variance,
    etr_fit_fpca(z$x,n_components=1L)$explained_variance)
  expect_equal(out$tables$scores,etr_fpca_scores(out$fit))
  expect_false(out$provenance$preprocessing_executed)
  expect_false(out$provenance$automatic_model_selection_performed)
  expect_false(out$provenance$source_schema_equivalent)
  expect_false(out$steps[[1L]]$duration_measured)
  expect_error(etr_run_fpca_workflow(z$x,
    list(n_components=1L,preprocessing=list("interpolate"))),
    "empty preprocessing")
  expect_error(etr_run_fpca_workflow(z$x,list(extra=TRUE)),
    "unsupported fields")
  expect_error(etr_run_fpca_workflow(z$x,list(n_components=TRUE)),
    "n_components")
})

test_that("native function-on-scalar workflow keeps declared dimensions and units",{
  z<-.etr_source_workflow_fixture()
  result<-etr_run_function_on_scalar_workflow(z$x,z$design,
    list(predictors="treatment",unit="curve",preprocessing=list()))
  expect_s3_class(result,"etr_function_on_scalar_workflow")
  expect_s3_class(result$fit,"etr_function_on_scalar")
  expect_identical(result$workflow_contract,"function_on_scalar:v1")
  expect_identical(result$fit$predictor_names,"treatment")
  expect_equal(result$tables$coefficients,
    etr_function_on_scalar_coefficient_frame(result$fit))
  expect_false(result$provenance$automatic_predictor_encoding)
  expect_false(result$provenance$preprocessing_executed)
  expect_error(etr_run_function_on_scalar_workflow(z$x,z$design,
    list(predictors="treatment",unit="curve",participant_column="subject")),
    "participant_column")
  expect_error(etr_run_function_on_scalar_workflow(z$x,z$design,
    list(predictors="treatment",preprocessing=list("smooth"))),
    "empty preprocessing")
  expect_error(etr_run_function_on_scalar_workflow(z$x,z$design,
    list(predictors="treatment",extra=TRUE)),
    "unsupported fields")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("frozen Python 1.2 workflow contract discriminates empty preprocessing",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published W3 Python workflow controls oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
from eyetrajectoriespy.workflows._dense_regression import (
 FPCAWorkflowConfig, FunctionOnScalarWorkflowConfig
)
from eyetrajectoriespy.workflows._core import PreprocessingPlan
_native_w3_oracle={
 'fpca': FPCAWorkflowConfig(n_components=1,scaling='none').n_components,
 'fos_predictors': FunctionOnScalarWorkflowConfig(
   predictors=('treatment',)).predictors,
 'empty_plan': len(PreprocessingPlan().steps)
}
")
  source<-reticulate::py_to_r(reticulate::py_eval(
    "_native_w3_oracle",convert=FALSE))
  expect_equal(as.integer(source$fpca),1L)
  expect_identical(as.character(unlist(source$fos_predictors)),"treatment")
  expect_equal(as.integer(source$empty_plan),0L)
})

test_that("frozen Python 1.2 W3 FPCA workflow matches native scientific geometry",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 W3 complete workflow oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_source_workflow_fixture()
  native<-etr_run_fpca_workflow(z$x,
    list(n_components=1L,scaling="none",preprocessing=list()))
  # Construct the very same deterministic curves in the published Python
  # dataclass domain. This is a direct source workflow call, not a bridge
  # dispatch to native R, and makes no cross-language result-class claim.
  reticulate::py_run_string("
import numpy as np, pandas as pd
import eyetrajectoriespy as et
from eyetrajectoriespy.workflows._dense_regression import FPCAWorkflowConfig
w3_t=np.linspace(0.,1.,15)
w3_y=np.empty((12,15,1))
for i in range(1,13):
    w3_y[i-1,:,0]=(np.sin(np.pi*w3_t)*(1+i/19) +
        .13*np.cos(2*np.pi*w3_t)*(i%3)+w3_t*i/15)
w3_x=et.TrajectorySet(time=w3_t,values=w3_y,
    curve_ids=tuple(f'c{i:02d}' for i in range(1,13)),
    dimension_names=('gaze',),
    metadata=pd.DataFrame(index=range(12)),
    coordinate_system='normalized',time_unit='s')
w3_cfg=FPCAWorkflowConfig(n_components=1,scaling='none')
from eyetrajectoriespy.workflows._dense_regression import FunctionOnScalarWorkflowConfig
w3_design=pd.DataFrame({
    'curve_id':[f'c{i:02d}' for i in range(1,13)],
    'treatment':[i/12. for i in range(1,13)]
})
w3_fos_cfg=FunctionOnScalarWorkflowConfig(predictors=('treatment',),
    unit='curve')
")
  source<-reticulate::py_call(
    etpy_get_export("run_fpca_workflow",.namespace="workflows"),
    trajectories=reticulate::py_eval("w3_x",convert=FALSE),
    config=reticulate::py_eval("w3_cfg",convert=FALSE))
  expect_identical(reticulate::py_to_r(source$workflow_contract),
    native$workflow_contract)
  expect_equal(as.integer(reticulate::py_to_r(source$workflow_schema_version)),
    native$workflow_schema_version)
  expect_equal(as.integer(reticulate::py_to_r(source$fit$n_components)),
    native$fit$n_components)
  expect_equal(unname(et_to_r(source$fit$mean)),
    unname(native$fit$mean),tolerance=1e-10)
  expect_equal(as.numeric(et_to_r(source$fit$explained_variance)),
    as.numeric(native$fit$explained_variance),tolerance=1e-9)
  py_scores<-et_to_r(source$fit$scores)
  r_scores<-native$fit$scores
  # Score sign is not identified; compare invariant pairwise geometry.
  expect_equal(unname(tcrossprod(py_scores)),
    unname(tcrossprod(r_scores)),tolerance=1e-8)
  expect_false(native$provenance$source_schema_equivalent)
  # A second direct W3 Python workflow exercises the observed-grid
  # function-on-scalar regression, including its HC1 inference output.
  native_fos<-etr_run_function_on_scalar_workflow(
    z$x,z$design,
    list(predictors="treatment",unit="curve",preprocessing=list()))
  source_fos<-reticulate::py_call(
    etpy_get_export("run_function_on_scalar_workflow",
      .namespace="workflows"),
    trajectories=reticulate::py_eval("w3_x",convert=FALSE),
    design=reticulate::py_eval("w3_design",convert=FALSE),
    config=reticulate::py_eval("w3_fos_cfg",convert=FALSE))
  expect_identical(reticulate::py_to_r(source_fos$workflow_contract),
    native_fos$workflow_contract)
  expect_equal(unname(et_to_r(source_fos$fit$coefficients)),
    unname(native_fos$fit$coefficients),tolerance=1e-9)
  expect_equal(unname(et_to_r(source_fos$fit$standard_errors)),
    unname(native_fos$fit$standard_errors),tolerance=1e-8)
  expect_equal(as.integer(reticulate::py_to_r(
    source_fos$fit$residual_degrees_of_freedom)),
    native_fos$fit$residual_degrees_of_freedom)
  expect_false(native_fos$provenance$source_schema_equivalent)
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
