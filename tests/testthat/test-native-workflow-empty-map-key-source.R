# Frozen Python 1.2 workflows/_core.py _jsonable allows empty string
# keys in mappings; native R maps must follow the same value semantics.

.etr_empty_map_source_step <- function(payload) {
  step<-list(name="inspect",fn="inspect",status="completed",
    parameters=payload,elapsed_seconds=0,warnings=character())
  names(step)[2L]<-"function"
  step
}

test_that("workflow frames and config preserve empty-string mapping keys", {
  skip_if_not_installed("jsonlite")
  payload<-stats::setNames(list(1L),"")
  steps<-etr_workflow_steps_frame(list(.etr_empty_map_source_step(payload)))
  decisions<-stats::setNames(
    list(list(value=payload,source="analyst",criterion=NULL)),"")
  frame<-etr_workflow_decisions_frame(decisions)
  expect_identical(steps$parameters_json,'{"":1}')
  expect_identical(frame$name,"")
  expect_identical(frame$value_json,'{"":1}')

  config<-etr_workflow_config(list(payload=payload))
  expect_identical(names(etr_workflow_config_to_dict(config)$payload),"")
  preprocessing<-etr_preprocessing_step_config(
    function_name="identity",parameters=payload,
    scientific_effect="No change to observations")
  expect_identical(names(
    etr_workflow_config_to_dict(preprocessing)$parameters),"")
  audit<-etr_workflow_audit_result("empty-map-keys",
    steps=list(.etr_empty_map_source_step(payload)),
    decisions=decisions,config=list(payload=payload),
    provenance=list(meta=payload))
  expect_identical(etr_workflow_summary_frame(audit)$decision_count,1L)
  expect_identical(etr_workflow_summary_frame(audit)$analyst_decisions,1L)

  nested<-list(z=stats::setNames(list(TRUE),""),a=1L)
  expect_identical(
    etr_workflow_steps_frame(list(.etr_empty_map_source_step(nested)))$parameters_json,
    '{"a":1,"z":{"":true}}')
  decisions[[1L]]$value<-nested
  expect_identical(etr_workflow_decisions_frame(decisions)$value_json,
    '{"a":1,"z":{"":true}}')
  duplicate<-stats::setNames(list(1L,2L),c("",""))
  expect_error(etr_workflow_steps_frame(
    list(.etr_empty_map_source_step(duplicate))),"unique character keys")
  expect_error(etr_workflow_config(list(payload=duplicate)),
    "invalid mapping keys")
})

test_that("empty string workflow mapping keys match frozen Python oracle", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 workflow oracle is opt-in")
  skip_if_not_installed("jsonlite")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
from eyetrajectoriespy.workflows._core import (
  WorkflowStepRecord, WorkflowDecisionRecord, PreprocessingStepConfig,
  workflow_steps_frame, workflow_decisions_frame, workflow_config_to_dict
)
_s = WorkflowStepRecord(name='inspect',status='completed',
  parameters={'':1},elapsed_seconds=0, **{'function':'inspect'})
_d = {'':WorkflowDecisionRecord(value={'':1},source='analyst')}
_src_step = workflow_steps_frame((_s,))
_src_decision = workflow_decisions_frame(_d)
_p = PreprocessingStepConfig(parameters={'':1},
  scientific_effect='No change to observations',**{'function':'identity'})
_src_preproc = workflow_config_to_dict(_p)
")
  payload<-stats::setNames(list(1L),"")
  native_steps<-etr_workflow_steps_frame(
    list(.etr_empty_map_source_step(payload)))
  native_decisions<-etr_workflow_decisions_frame(
    stats::setNames(list(list(value=payload,source="analyst")),""))
  py_steps<-as.character(reticulate::py_eval(
    "_src_step['parameters_json'].iloc[0]",convert=TRUE))
  py_decisions<-as.character(reticulate::py_eval(
    "_src_decision['value_json'].iloc[0]",convert=TRUE))
  py_name<-as.character(reticulate::py_eval(
    "_src_decision['name'].iloc[0]",convert=TRUE))
  expect_identical(native_steps$parameters_json,py_steps)
  expect_identical(native_decisions$value_json,py_decisions)
  expect_identical(native_decisions$name,py_name)
  native_preproc<-etr_workflow_config_to_dict(etr_preprocessing_step_config(
    function_name="identity",parameters=payload,
    scientific_effect="No change to observations"))
  source_keys<-reticulate::py_to_r(reticulate::py_eval(
    "list(_src_preproc['parameters'].keys())",convert=FALSE))
  expect_identical(names(native_preproc$parameters),
    as.character(unlist(source_keys,use.names=FALSE)))
  expect_equal(as.numeric(native_preproc$parameters[[1L]]),
    as.numeric(reticulate::py_eval(
      "_src_preproc['parameters']['']",convert=TRUE)),tolerance=0)
})
