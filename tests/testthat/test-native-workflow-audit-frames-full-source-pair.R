# Frozen Python 1.2 workflow frames; commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Native R field/dataframe analogues, NOT Python dataclass or pandas identity.

.etr_source_frames_step<-function(name,fn,status,parameters,elapsed,warnings=character()){
  z<-list(name=name,fn=fn,status=status,parameters=parameters,
    elapsed_seconds=elapsed,warnings=warnings)
  names(z)[[2L]]<-"function"
  z
}

.etr_source_workflow_frames_fixture<-function(case) {
  if(case=="empty")return(list(steps=list(),decisions=list()))
  if(case=="mixed") {
    steps<-list(
      .etr_source_frames_step("α","inspect","completed",
        list(z=list(0L,1L),a=list(k=TRUE)),.25,
        c("warning one","warning β")),
      .etr_source_frames_step("retry","fit","failed",
        list(negative=-0.0,none=NULL),TRUE),
      .etr_source_frames_step("skip","noop","skipped",
        stats::setNames(list(0L),""),0L,"line\nnext"))
    decisions<-list(
      alpha=list(value=list(z=list(0L,1L),a=list(k=TRUE)),source="analyst"),
      empty=list(value=stats::setNames(list(),character()),source="derived"),
      zero=list(value=0.0,source="workflow_contract"),
      selector=list(value=TRUE,source="audited_selector",criterion="criterion β"))
    return(list(steps=steps,decisions=decisions))
  }
  if(case=="tensor") {
    grid<-matrix(c(0L,2L,1L,3L),2L,2L)
    steps<-list(.etr_source_frames_step("matrix","transform","completed",
      list(grid=grid,values=list(FALSE,NULL)),FALSE))
    decisions<-stats::setNames(
      list(list(value=list(grid=grid,beta="β"),source="analyst")),"")
    return(list(steps=steps,decisions=decisions))
  }
  stop("unknown frozen fixture",call.=FALSE)
}

test_that("paired workflow frames preserve all source columns and numeric/JSON fields",{
  empty_steps<-etr_workflow_steps_frame(list())
  empty_decisions<-etr_workflow_decisions_frame(list())
  expect_identical(names(empty_steps),c("order","name","function","status",
    "elapsed_seconds","parameters_json","warning_count","warnings"))
  expect_identical(names(empty_decisions),
    c("name","value_json","source","criterion"))
  expect_identical(nrow(empty_steps),0L)
  expect_identical(nrow(empty_decisions),0L)
  for(case in c("mixed","tensor")){
    x<-.etr_source_workflow_frames_fixture(case)
    s<-etr_workflow_steps_frame(x$steps)
    d<-etr_workflow_decisions_frame(x$decisions)
    expect_identical(s$order,seq_len(length(x$steps)))
    expect_identical(d$name,names(x$decisions))
    expect_identical(s$warning_count,
      vapply(x$steps,function(z)length(z$warnings),integer(1L)))
    expect_identical(s$warnings,
      vapply(x$steps,function(z)paste(z$warnings,collapse="\n"),character(1L)))
  }
  a<-.etr_source_workflow_frames_fixture("mixed")
  native<-etr_workflow_steps_frame(a$steps)
  expect_equal(native$elapsed_seconds,c(.25,1,0),tolerance=0)
  expect_identical(native$status,c("completed","failed","skipped"))
  expect_identical(native$parameters_json[[1L]],
    '{"a":{"k":true},"z":[0,1]}')
  expect_identical(native$parameters_json[[2L]],
    '{"negative":-0.0,"none":null}')
  expect_identical(native$parameters_json[[3L]],'{"":0}')
  dec<-etr_workflow_decisions_frame(a$decisions)
  expect_identical(dec$value_json,
    c('{"a":{"k":true},"z":[0,1]}','{}','0.0','true'))
  expect_true(is.na(dec$criterion[[1L]]))
  expect_identical(dec$criterion[[4L]],"criterion β")
})

test_that("paired workflow frames fail closed on invalid source boundaries",{
  x<-.etr_source_workflow_frames_fixture("mixed")
  a<-x$steps[[1L]]
  a$elapsed_seconds<-Inf
  expect_error(etr_workflow_steps_frame(list(a)),"requires")
  a$elapsed_seconds<--1
  expect_error(etr_workflow_steps_frame(list(a)),"requires")
  a$elapsed_seconds<-NA_real_
  expect_error(etr_workflow_steps_frame(list(a)),"requires")
  a$elapsed_seconds<-0
  a$status<-"automatic"
  expect_error(etr_workflow_steps_frame(list(a)),"requires")
  a$status<-"completed"
  a$parameters<-stats::setNames(list(0L,1L),c("k","k"))
  expect_error(etr_workflow_steps_frame(list(a)),"unique character")
  a$parameters<-list(x=NaN)
  expect_error(etr_workflow_steps_frame(list(a)),"nonfinite")
  for(source in c("automatic","SELECTOR","")) {
    b<-list(value=1L,source=source)
    expect_error(etr_workflow_decisions_frame(list(x=b)),"decision requires")
  }
  expect_error(etr_workflow_decisions_frame(
    list(x=list(value=2L,source="audited_selector",criterion=""))),
    "selector criterion")
  expect_error(etr_workflow_decisions_frame(
    list(x=list(value=Inf,source="derived"))),"nonfinite")
  expect_error(etr_workflow_decisions_frame(
    stats::setNames(list(list(value=1L,source="analyst"),
      list(value=2L,source="analyst")),c("k","k"))),"uniquely named")
})

test_that("frozen Python 1.2 typed workflow frames match every native cell",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 direct source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "from eyetrajectoriespy.workflows._core import WorkflowStepRecord, WorkflowDecisionRecord, workflow_steps_frame, workflow_decisions_frame",
    "import numpy as np",
    "def etr_frames_source_fixture(case):",
    "    if case == 'empty': return [], {}",
    "    if case == 'mixed':",
    "        steps=[",
    "          WorkflowStepRecord('α','inspect','completed',{'z':[0,1],'a':{'k':True}},.25,('warning one','warning β')),",
    "          WorkflowStepRecord('retry','fit','failed',{'negative':-0.0,'none':None},True),",
    "          WorkflowStepRecord('skip','noop','skipped',{'':0},0,('line\\nnext',))]",
    "        decisions={",
    "          'alpha':WorkflowDecisionRecord(value={'z':[0,1],'a':{'k':True}},source='analyst'),",
    "          'empty':WorkflowDecisionRecord(value={},source='derived'),",
    "          'zero':WorkflowDecisionRecord(value=0.0,source='workflow_contract'),",
    "          'selector':WorkflowDecisionRecord(value=True,source='audited_selector',criterion='criterion β')}",
    "        return steps, decisions",
    "    if case == 'tensor':",
    "        steps=[WorkflowStepRecord('matrix','transform','completed',{'grid':np.array([[0,1],[2,3]],dtype=np.int64),'values':[False,None]},False)]",
    "        decisions={'':WorkflowDecisionRecord(value={'grid':np.array([[0,1],[2,3]],dtype=np.int64),'beta':'β'},source='analyst')}",
    "        return steps, decisions",
    "    raise ValueError(case)",
    "def etr_frames_source_output(case):",
    "    steps, decisions = etr_frames_source_fixture(case)",
    "    return workflow_steps_frame(steps),workflow_decisions_frame(decisions)"
  ),collapse="\n"),convert=FALSE)
  for(case in c("empty","mixed","tensor")) {
    native<-.etr_source_workflow_frames_fixture(case)
    source<-reticulate::py_call(reticulate::py$etr_frames_source_output,case)
    pairs<-list(
      list(name="steps",a=as.data.frame(et_to_r(source[[1L]]),
        check.names=FALSE),b=etr_workflow_steps_frame(native$steps)),
      list(name="decisions",a=as.data.frame(et_to_r(source[[2L]]),
        check.names=FALSE),b=etr_workflow_decisions_frame(native$decisions)))
    for(pair in pairs) {
      expect_identical(names(pair$a),names(pair$b),
        info=paste(case,pair$name,"columns"))
      expect_identical(nrow(pair$a),nrow(pair$b),
        info=paste(case,pair$name,"nrow"))
      for(field in names(pair$a)) {
        a<-pair$a[[field]]
        b<-pair$b[[field]]
        if(is.numeric(a)) {
          expect_equal(as.numeric(a),as.numeric(b),tolerance=0,
            info=paste(case,pair$name,field))
        } else {
          expect_identical(as.character(b),as.character(a),
            info=paste(case,pair$name,field))
        }
      }
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
