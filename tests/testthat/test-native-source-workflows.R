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
