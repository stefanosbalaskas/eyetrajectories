# Frozen Python 1.2 source contracts: workflows/_core.py, simulate.py,
# recovery_scenarios.py at c1cd95ad718327550f7e55393ff38582872f7a94.
# Semantic field checks do not establish identical pandas/dataclass classes.

test_that("native Python JSON serializer preserves source scalar/list/Unicode distinctions",{
  skip_if_not_installed("jsonlite")
  source_json<-eyetrajectories:::.etr_python_json_encode
  expect_identical(source_json(1L),"1")
  expect_identical(source_json(1.0),"1.0")
  expect_identical(source_json(-0.0),"-0.0")
  expect_identical(source_json(1e-5),"1e-05")
  expect_identical(source_json(1e5),"100000.0")
  expect_identical(source_json(TRUE),"true")
  expect_identical(source_json(NULL),"null")
  expect_identical(source_json(list()),"[]")
  expect_identical(source_json(list(),empty_mapping=TRUE),"{}")
  expect_identical(source_json(c(1,.35),compact=FALSE,force_array=TRUE),
    "[1.0, 0.35]")
  expect_identical(source_json(list(z=1.0,a=list(1L)),compact=TRUE),
    '{"a":[1],"z":1.0}')
  expect_identical(source_json(list(x="α")),
    '{"x":"\\u03b1"}')
  expect_identical(source_json(matrix(c(.04,.018,.018,.09),2L,byrow=TRUE),
    compact=FALSE),"[[0.04, 0.018], [0.018, 0.09]]")
  expect_error(source_json(Inf),"nonfinite")
  expect_error(source_json(NA_real_),"nonfinite|missing")
  expect_error(source_json(factor("A")),"supported")
})

test_that("workflow native frames preserve source ordered fields and typed JSON",{
  skip_if_not_installed("jsonlite")
  steps<-list(list(name="fit",`function`="fit_fpca",status="completed",
    parameters=list(z=list(1L),alpha=1.0,unicode="α"),
    elapsed_seconds=.125,warnings="source warning"))
  decisions<-list(alpha=list(value=list(z=list(2L),alpha=1.0),
    source="analyst",criterion=NULL))
  result<-etr_workflow_audit_result("two'quotes",steps=steps,
    decisions=decisions)
  native_steps<-etr_workflow_steps_frame(result$steps)
  native_decisions<-etr_workflow_decisions_frame(result$decisions)
  expect_identical(native_steps$parameters_json,
    '{"alpha":1.0,"unicode":"\\u03b1","z":[1]}')
  expect_identical(native_decisions$value_json,
    '{"alpha":1.0,"z":[2]}')
  expect_identical(etr_workflow_summary_frame(result)$step_count,1L)
  expect_true(grepl("Workflow \"two'quotes\"",etr_workflow_reporting_text(result),
    fixed=TRUE))
  expect_error(etr_workflow_decisions_frame(list(a=list(
    value=Inf,source="analyst"))),"nonfinite")
})

test_that("workflow JSON retains tensor axes and validates mutated audit records",{
  skip_if_not_installed("jsonlite")
  tensor<-array(seq_len(12L),c(2L,2L,3L))
  empty<-array(numeric(),c(2L,0L,3L))
  encode<-eyetrajectories:::.etr_python_json_encode
  expect_identical(encode(tensor),
    "[[[1,5,9],[3,7,11]],[[2,6,10],[4,8,12]]]")
  expect_identical(encode(array(1L,1L)),"[1]")
  expect_identical(encode(empty),"[[],[]]")
  expect_identical(encode("\u007f"),"\"\\u007f\"")
  config<-etr_workflow_config(list(tensor=tensor,empty=empty))
  projected<-etr_workflow_config_to_dict(config)
  expect_identical(projected$empty,list(list(),list()))
  expect_identical(projected$tensor[[2L]][[1L]],list(2L,6L,10L))
  expect_error(etr_workflow_config(list(array=array("string",1L))),
    "numeric or logical array")
  invalid_step<-list(name="fit",`function`="fit_fpca",status="completed",
    parameters=list(1L),elapsed_seconds=0)
  expect_error(etr_workflow_steps_frame(list(invalid_step)),
    "step.parameters.*unique character")
  result<-etr_workflow_audit_result("tensor",config=config)
  result$config$tensor[1L,1L,1L]<-Inf
  expect_error(etr_workflow_summary_frame(result),"config.*nonfinite")
  result$config<-config
  result$provenance$broken<-list(bad=NA_real_)
  expect_error(etr_workflow_reporting_text(result),"provenance.*missing")
})

test_that("pinned workflow config and frames retain NumPy ndarray shape",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Published Python 1.2 direct source oracle is opt in")
  skip_if_not_installed("jsonlite")
  expect_identical(et_python_version(),"1.2.0")
  wf<-reticulate::import("eyetrajectoriespy.workflows._core",convert=FALSE)
  np<-reticulate::import("numpy",convert=FALSE)
  json<-reticulate::import("json",convert=FALSE)
  reticulate::py_run_string(paste(c(
    "from dataclasses import dataclass",
    "from eyetrajectoriespy.workflows._core import WorkflowStepRecord, WorkflowDecisionRecord",
    "@dataclass",
    "class TensorWorkflowConfig:",
    "    values: dict",
    "@dataclass",
    "class TensorWorkflowResult:",
    "    workflow_schema_version: int",
    "    workflow_contract: str",
    "    config: TensorWorkflowConfig",
    "    steps: tuple",
    "    decisions: dict",
    "    provenance: dict",
    "def tensor_workflow_fixture(values):",
    "    step = WorkflowStepRecord('fit', 'fit_fpca', 'completed', values, 0.)",
    "    decision = WorkflowDecisionRecord(values, 'analyst')",
    "    return TensorWorkflowResult(1, 'tensor', TensorWorkflowConfig(values), (step,), {'array':decision}, {})",
    "def tensor_workflow_invalid(result, target):",
    "    mapping = result.config.values if target == 'config' else result.provenance",
    "    mapping['bad'] = float('inf')",
    "    return result"
  ),collapse="\n"),convert=FALSE)
  values<-list(tensor=array(seq_len(12L),c(2L,2L,3L)),singleton=array(1L,1L),
    empty=array(numeric(),c(2L,0L,3L)),mask=array(c(TRUE,FALSE),c(2L,1L,1L)),
    control="\u007f")
  py_values<-reticulate::dict(tensor=np$array(values$tensor,dtype="int64"),
    singleton=np$array(list(1L),dtype="int64"),
    empty=np$empty(reticulate::tuple(2L,0L,3L),dtype="float64"),
    mask=np$array(values$mask,dtype="bool"),control=values$control)
  py<-reticulate::py$tensor_workflow_fixture(py_values)
  call<-reticulate::py_call
  native<-etr_workflow_config(list(values=values))
  canonical<-eyetrajectories:::.etr_python_json_encode(
    etr_workflow_config_to_dict(native))
  expect_identical(canonical,et_to_r(call(json$dumps,
    call(wf$workflow_config_to_dict,py$config),sort_keys=TRUE,
    separators=reticulate::tuple(",",":"))))
  steps<-list(list(name="fit",`function`="fit_fpca",status="completed",
    parameters=values,elapsed_seconds=0))
  decisions<-list(array=list(value=values,source="analyst"))
  step<-et_to_r(call(wf$workflow_steps_frame,py$steps))
  decision<-et_to_r(call(wf$workflow_decisions_frame,py$decisions))
  expect_identical(etr_workflow_steps_frame(steps)$parameters_json,step$parameters_json)
  expect_identical(etr_workflow_decisions_frame(decisions)$value_json,decision$value_json)
  expect_error(call(wf$workflow_summary_frame,
    reticulate::py$tensor_workflow_invalid(py,"config")),"config.values.bad.*non-finite")
  source<-reticulate::py$tensor_workflow_fixture(reticulate::dict())
  expect_error(call(wf$workflow_reporting_text,
    reticulate::py$tensor_workflow_invalid(source,"provenance")),"provenance.bad.*non-finite")
})

test_that("pinned Python 1.2 six source APIs agree in entire reported fields",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Published Python 1.2 direct source oracle is opt in")
  skip_if_not_installed("jsonlite")
  expect_identical(et_python_version(),"1.2.0")
  py<-reticulate::import("eyetrajectoriespy.workflows._core",convert=FALSE)
  # The frozen API validates dataclass inputs; construct genuine dataclass
  # records on the Python side to avoid transparent auto-conversion pitfalls.
  reticulate::py_run_string(paste(c(
    "from dataclasses import dataclass",
    "from eyetrajectoriespy.workflows._core import WorkflowStepRecord, WorkflowDecisionRecord",
    "@dataclass",
    "class Batch28Config:",
    "    alpha: int = 1",
    "@dataclass",
    "class Batch28Result:",
    "    workflow_schema_version: int",
    "    workflow_contract: str",
    "    config: Batch28Config",
    "    steps: tuple",
    "    decisions: dict",
    "    provenance: dict",
    "def batch28_result(identifier):",
    "    s = WorkflowStepRecord(name='fit', function='fit_fpca', status='completed', parameters={'z':[1], 'alpha':1.0, 'unicode':'α'}, elapsed_seconds=0.125, warnings=('source warning',))",
    "    d = {'alpha': WorkflowDecisionRecord(value={'z':[2], 'alpha':1.0}, source='analyst')}",
    "    return Batch28Result(1, identifier, Batch28Config(), (s,), d, {})",
    "def batch28_join_scenarios(a,b):",
    "    return a+b"
  ),collapse="\n"),convert=FALSE)
  for(identifier in c("plain","two'quotes","a\\backslash","α","newline\ninside",
    "unicode\u00a0\u200b\ue000\U0001fffe")){
    source<-reticulate::py$batch28_result(identifier)
    native<-etr_workflow_audit_result(identifier,
      steps=list(list(name="fit",`function`="fit_fpca",status="completed",
        parameters=list(z=list(1L),alpha=1.0,unicode="α"),
        elapsed_seconds=.125,warnings="source warning")),
      decisions=list(alpha=list(value=list(z=list(2L),alpha=1.0),
        source="analyst")))
    pairs<-list(
      list(name="workflow_steps_frame",py=reticulate::py_call(py$workflow_steps_frame,
        source$steps),r=etr_workflow_steps_frame(native$steps)),
      list(name="workflow_decisions_frame",py=reticulate::py_call(py$workflow_decisions_frame,
        source$decisions),r=etr_workflow_decisions_frame(native$decisions)),
      list(name="workflow_summary_frame",py=reticulate::py_call(py$workflow_summary_frame,
        source),r=etr_workflow_summary_frame(native)))
    for(pair in pairs){
      p<-as.data.frame(et_to_r(pair$py),check.names=FALSE)
      expect_identical(names(p),names(pair$r),info=pair$name)
      expect_identical(nrow(p),nrow(pair$r),info=pair$name)
      for(field in names(p)){
        a<-p[[field]];b<-pair$r[[field]]
        if(is.numeric(a))expect_equal(unname(a),unname(b),tolerance=1e-12,
          info=paste(pair$name,field,identifier))
        else expect_identical(as.character(a),as.character(b),
          info=paste(pair$name,field,identifier))
      }
    }
    txt<-as.character(et_to_r(reticulate::py_call(
      py$workflow_reporting_text,source)))
    expect_identical(etr_workflow_reporting_text(native),txt,
      info=paste("workflow_reporting_text",identifier))
  }
  # Whole 18-row scenarios across all 26 fields and 3 declared replicate regimes.
  for(k in c(1L,3L,7L)){
    src<-as.data.frame(et_to_r(reticulate::py_call(
      etpy_get_export("functional_recovery_scenario_catalog_frame"),
      qualification_replicates=k,stress_replicates=k+1L)),
      check.names=FALSE)
    nr<-etr_functional_recovery_scenario_catalog_frame(
      qualification_replicates=k,stress_replicates=k+1L)
    expect_identical(names(nr),names(src))
    expect_identical(nrow(nr),18L)
    for(field in names(src)){
      a<-src[[field]];b<-nr[[field]]
      if(is.numeric(a))expect_equal(unname(a),unname(b),tolerance=1e-12,
        info=paste("scenario_catalog",field,k))
      else expect_identical(as.character(a),as.character(b),
        info=paste("scenario_catalog",field,k))
    }
    # Source simulation-frame contract across the same 18 source dataclasses.
    pqual<-reticulate::py_call(etpy_get_export(
      "functional_recovery_qualification_scenarios"),replicates=k)
    pstress<-reticulate::py_call(etpy_get_export(
      "functional_recovery_stress_scenarios"),replicates=k+1L)
    psrc<-as.data.frame(et_to_r(reticulate::py_call(
      etpy_get_export("functional_simulation_scenario_frame"),
      scenarios=reticulate::py$batch28_join_scenarios(pqual,pstress))),
      check.names=FALSE)
    nr2<-etr_functional_simulation_scenario_frame(c(
      etr_functional_recovery_qualification_scenarios(replicates=k),
      etr_functional_recovery_stress_scenarios(replicates=k+1L)))
    expect_identical(names(psrc),names(nr2))
    for(field in names(psrc)){
      a<-psrc[[field]];b<-nr2[[field]]
      if(is.numeric(a))expect_equal(unname(a),unname(b),tolerance=1e-12,
        info=paste("simulation_scenario",field,k))
      else expect_identical(as.character(a),as.character(b),
        info=paste("simulation_scenario",field,k))
    }
  }
})
