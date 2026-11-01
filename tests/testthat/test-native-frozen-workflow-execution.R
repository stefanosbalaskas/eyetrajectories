# Real native scientific executions via frozen Python 1.2 config records.
# This tests actual computation and strict no-hidden-preprocessing dispatch.
# No external reviewer approval or full-domain source equivalence is inferred.
.etr_frozen_execution_fixture<-function(){
  times<-seq(0,1,length.out=15L)
  n<-12L
  arr<-array(0,c(n,length(times),1L))
  for(i in seq_len(n))
    arr[i,,1]<-sin(pi*times)*(1+i/19)+
      .13*cos(2*pi*times)*(i%%3)+times*i/15
  x<-etr_trajectory_set(times,arr,sprintf("c%02d",seq_len(n)),
    "gaze",coordinate_system="normalized",time_unit="s")
  list(x=x,design=data.frame(curve_id=x$curve_ids,
    treatment=seq_len(n)/n))
}

test_that("three source-config constructors preserve source field schema",{
  fp<-etr_frozen_fpca_workflow_config(1L,"none")
  fos<-etr_frozen_function_on_scalar_workflow_config("treatment")
  rec<-etr_frozen_recurrence_workflow_config(0L,"gaze",2L,1L,.5)
  cases<-list(FPCAWorkflowConfig=fp,
    FunctionOnScalarWorkflowConfig=fos,
    RecurrenceWorkflowConfig=rec)
  for(nm in names(cases)){
    expect_s3_class(cases[[nm]],paste0("etr_frozen_py12_",nm))
    expect_identical(names(cases[[nm]]),
      etr_frozen_workflow_schema(nm)$field_name)
    expect_s3_class(cases[[nm]]$preprocessing,
      "etr_frozen_py12_PreprocessingPlan")
    expect_identical(cases[[nm]]$preprocessing$steps,list())
    expect_false(attr(cases[[nm]],"source_scientific_parity_certified"))
  }
  expect_error(etr_frozen_fpca_workflow_config(0L),"n_components")
  expect_error(etr_frozen_fpca_workflow_config(TRUE),"n_components")
  expect_error(etr_frozen_fpca_workflow_config(1.01),"n_components")
  expect_error(etr_frozen_fpca_workflow_config(1L,"invalid"),"scaling")
  expect_error(etr_frozen_function_on_scalar_workflow_config(
    c("dose","dose")),"predictors")
  expect_error(etr_frozen_function_on_scalar_workflow_config(
    "dose",unit="participant"),"participant_column")
  expect_error(etr_frozen_recurrence_workflow_config(
    0L,"gaze",2L,1L,-.5),"radius")
  expect_error(etr_frozen_recurrence_workflow_config(
    0L,c("gaze","gaze"),2L,1L,.5),"dimensions")
})

test_that("real native FPCA and FOS estimators execute from source records",{
  z<-.etr_frozen_execution_fixture()
  fp_cfg<-etr_frozen_fpca_workflow_config(1L)
  fp<-etr_run_frozen_native_workflow(z$x,fp_cfg)
  direct_fp<-etr_run_fpca_workflow(z$x,
    config=list(n_components=1L,scaling="none",preprocessing=list()))
  expect_s3_class(fp,"etr_fpca_workflow")
  expect_identical(fp$workflow_contract,"fpca:v1")
  expect_equal(fp$fit$mean,direct_fp$fit$mean,tolerance=0)
  expect_equal(fp$fit$scores,direct_fp$fit$scores,tolerance=0)
  expect_s3_class(etr_native_workflow_result_view(fp),
    "etr_frozen_py12_FPCAWorkflowResult")
  fos_cfg<-etr_frozen_function_on_scalar_workflow_config(
    predictors="treatment")
  fos<-etr_run_frozen_native_workflow(z$x,fos_cfg,design=z$design)
  direct_fos<-etr_run_function_on_scalar_workflow(z$x,z$design,
    config=list(predictors="treatment",unit="curve",
      preprocessing=list()))
  expect_s3_class(fos,"etr_function_on_scalar_workflow")
  expect_equal(fos$fit$coefficients,direct_fos$fit$coefficients,
    tolerance=0)
  expect_equal(fos$fit$standard_errors,direct_fos$fit$standard_errors,
    tolerance=0)
  expect_s3_class(etr_native_workflow_result_view(fos),
    "etr_frozen_py12_FunctionOnScalarWorkflowResult")
  expect_error(etr_run_frozen_native_workflow(z$x,fos_cfg),
    "requires design")
  expect_error(etr_run_frozen_native_workflow(z$x,fp_cfg,
    design=z$design),"does not accept design")
})

test_that("native recurrence runs and unsupported source domains fail closed",{
  z<-.etr_frozen_execution_fixture()
  rec_cfg<-etr_frozen_recurrence_workflow_config(
    curve=0L,dimensions="gaze",embedding_dimension=2L,
    delay=1L,radius=0.5)
  native<-etr_run_frozen_native_workflow(z$x,rec_cfg)
  direct<-etr_run_recurrence_workflow(z$x,
    config=list(curve=0L,dimensions="gaze",
      embedding_dimension=2L,delay=1L,radius=.5,
      preprocessing=list()))
  expect_s3_class(native,"etr_recurrence_workflow")
  expect_identical(native$workflow_contract,"recurrence:v1")
  expect_equal(native$recurrence$matrix,direct$recurrence$matrix,
    tolerance=0)
  expect_equal(native$metrics,direct$metrics,tolerance=0)
  wrong_metric<-etr_frozen_recurrence_workflow_config(
    curve=0L,dimensions="gaze",embedding_dimension=2L,
    delay=1L,radius=.5,metric="manhattan")
  expect_error(etr_run_frozen_native_workflow(z$x,wrong_metric),
    "only Euclidean")
  one_as_float<-etr_frozen_fpca_workflow_config(1.0)
  expect_error(etr_run_frozen_native_workflow(z$x,one_as_float),
    "floating 1.0")
  step<-etr_frozen_workflow_record("PreprocessingStepConfig",
    list(function="interpolate",parameters=list(),
      scientific_effect="changes the observed time support"))
  plan<-etr_frozen_workflow_record("PreprocessingPlan",list(steps=list(step)))
  imp<-etr_frozen_fpca_workflow_config(1L,preprocessing=plan)
  expect_error(etr_run_frozen_native_workflow(z$x,imp),
    "empty explicit preprocessing")
  expect_error(etr_run_frozen_native_workflow(z$x,
    etr_frozen_workflow_record("ScoreUncertaintyConfig",
      list(condition_limit=NULL,failure_action="error"))),
    "no executable native R adapter")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("scientific workflow step and decision records have guarded source schema",{
  d<-etr_frozen_workflow_decision_record(
    value=1L,source="audited_selector",criterion="cross-validated mean loss")
  expect_identical(names(d),
    etr_frozen_workflow_schema("WorkflowDecisionRecord")$field_name)
  expect_error(etr_frozen_workflow_decision_record(
    value=1L,source="audited_selector"),"criterion")
  expect_error(etr_frozen_workflow_decision_record(
    value=1L,source="unknown"),"accepted source")
  s<-etr_frozen_workflow_step_record("fit","fit_fpca","completed",
    parameters=list(n_components=1L),elapsed_seconds=0.1,
    warnings=character())
  expect_identical(names(s),
    etr_frozen_workflow_schema("WorkflowStepRecord")$field_name)
  expect_identical(s[["function"]],"fit_fpca")
  expect_error(etr_frozen_workflow_step_record("fit","fit_fpca","completed",
    elapsed_seconds=-1),"time and warnings")
  expect_error(etr_frozen_workflow_step_record("fit","fit_fpca","unknown",
    elapsed_seconds=0),"time and warnings")
  expect_false(attr(s,"independent_full_domain_certification"))
})

test_that("pinned Python config objects agree on declared source fields and defaults",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Python 1.2 workflow constructor and source-class oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  fp<-reticulate::py_call(
    etpy_get_export("FPCAWorkflowConfig",.namespace="workflows"),
    n_components=1L,scaling="none")
  native_fp<-etr_frozen_fpca_workflow_config(1L)
  expect_equal(as.integer(reticulate::py_to_r(fp$n_components)),
    native_fp$n_components)
  expect_identical(reticulate::py_to_r(fp$scaling),native_fp$scaling)
  expect_equal(length(reticulate::py_to_r(fp$preprocessing$steps)),
    length(native_fp$preprocessing$steps))
  fos<-reticulate::py_call(
    etpy_get_export("FunctionOnScalarWorkflowConfig",
      .namespace="workflows"),
    predictors=reticulate::r_to_py(list("treatment")))
  native_fos<-etr_frozen_function_on_scalar_workflow_config("treatment")
  expect_identical(as.character(unlist(
    reticulate::py_to_r(fos$predictors))),native_fos$predictors)
  expect_identical(reticulate::py_to_r(fos$unit),native_fos$unit)
  rec<-reticulate::py_call(
    etpy_get_export("RecurrenceWorkflowConfig",.namespace="workflows"),
    curve=0L,dimensions=reticulate::r_to_py(list("gaze")),
    embedding_dimension=2L,delay=1L,radius=.5)
  native_rec<-etr_frozen_recurrence_workflow_config(0L,"gaze",2L,1L,.5)
  expect_equal(as.integer(reticulate::py_to_r(rec$embedding_dimension)),
    native_rec$embedding_dimension)
  expect_equal(as.numeric(reticulate::py_to_r(rec$radius)),
    native_rec$radius)
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
