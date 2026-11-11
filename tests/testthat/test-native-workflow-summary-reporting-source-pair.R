# Native-language source-semantic review of frozen Python 1.2 workflows/_core.py.
# Python oracle commit c1cd95ad718327550f7e55393ff38582872f7a94.
# Python dataclass and pandas runtime identities remain language-specific.

.etr_workflow_summary_pair_fixture <- function(n=4L,
    identifier="source-pair",version=1L) {
  statuses<-c("completed","failed","skipped","completed")
  sources<-c("analyst","audited_selector","workflow_contract","derived")
  steps<-lapply(seq_len(n),function(i) {
    j<-i-1L
    list(name=paste0("step",j),`function`="fit",status=statuses[j%%4L+1L],
      parameters=list(trial=as.integer(j)),elapsed_seconds=j/8,
      warnings=rep("w",j%%3L))
  })
  decisions<-lapply(seq_along(sources),function(i) {
    s<-sources[[i]]
    list(value=as.integer(i-1L),source=s,
      criterion=if(s=="audited_selector") "criterion" else NULL)
  })
  names(decisions)<-paste0("d",0:3)
  out<-etr_workflow_audit_result(identifier,steps,decisions,
    config=list(),provenance=list())
  out$workflow_schema_version<-version
  out
}

test_that("source workflow summary preserves 12 ordered columns across all status categories",{
  expected<-c("workflow_schema_version","workflow_contract","step_count",
    "completed_steps","failed_steps","skipped_steps","warning_count",
    "decision_count","analyst_decisions","audited_selector_decisions",
    "workflow_contract_decisions","derived_decisions")
  for(n in c(0L,1L,2L,3L,4L,7L,13L)){
    x<-.etr_workflow_summary_pair_fixture(n)
    z<-etr_workflow_summary_frame(x)
    expect_identical(names(z),expected)
    expect_identical(nrow(z),1L)
    expect_identical(z$workflow_schema_version,1L)
    expect_identical(z$step_count,as.integer(n))
    statuses<-vapply(x$steps,function(v)v$status,character(1L))
    expect_equal(z$completed_steps,sum(statuses=="completed"))
    expect_equal(z$failed_steps,sum(statuses=="failed"))
    expect_equal(z$skipped_steps,sum(statuses=="skipped"))
    expect_equal(z$warning_count,sum(vapply(x$steps,
      function(v) length(v$warnings),integer(1L))))
    expect_identical(z$decision_count,4L)
    for(field in c("analyst_decisions","audited_selector_decisions",
                   "workflow_contract_decisions","derived_decisions"))
      expect_identical(z[[field]],1L)
    expect_match(etr_workflow_reporting_text(x),
      sprintf("%d ordered steps",n),fixed=TRUE)
  }
})

test_that("source int(schema_version) boundary tolerates Python scalar analogues",{
  cases<-list(
    list(value=1L,report="1"),
    list(value=1.0,report="1.0"),
    list(value=1.9,report="1.9"),
    list(value=TRUE,report="True"),
    list(value="1",report="1"),
    list(value=" 1 ",report=" 1 "))
  for(case in cases){
    x<-.etr_workflow_summary_pair_fixture(0L,version=case$value)
    expect_identical(etr_workflow_summary_frame(x)$workflow_schema_version,1L)
    expect_match(etr_workflow_reporting_text(x),
      paste0("used schema ",case$report," and retained"),fixed=TRUE)
  }
  for(version in list(0L,2L,2.0,FALSE,NA_integer_,NaN,Inf,
                     "1.9","two",integer(),c(1L,1L),list(1L))){
    x<-.etr_workflow_summary_pair_fixture(0L)
    x$workflow_schema_version<-version
    expect_error(etr_workflow_summary_frame(x),"schema version 1")
    expect_error(etr_workflow_reporting_text(x),"schema version 1")
  }
})

test_that("summary/report pair validates malformed and mutated native audit inputs",{
  x<-.etr_workflow_summary_pair_fixture(4L)
  x$steps[[1L]]$status<-"auto"
  expect_error(etr_workflow_summary_frame(x),"requires")
  x<-.etr_workflow_summary_pair_fixture(4L)
  x$decisions$d1$criterion<-NULL
  expect_error(etr_workflow_reporting_text(x),"criterion")
  x<-.etr_workflow_summary_pair_fixture(4L)
  x$config$nested<-list(value=Inf)
  expect_error(etr_workflow_summary_frame(x),"config.*nonfinite")
  x<-.etr_workflow_summary_pair_fixture(4L)
  x$provenance$nested<-list(value=NaN)
  expect_error(etr_workflow_reporting_text(x),"provenance.*missing|provenance.*nonfinite")
  x<-.etr_workflow_summary_pair_fixture(4L)
  x$workflow_contract<-""
  expect_error(etr_workflow_reporting_text(x),"nonempty")
  expect_error(etr_workflow_summary_frame(list()),"native workflow audit")
  expect_error(etr_workflow_reporting_text(list()),"native workflow audit")
})

test_that("published Python 1.2 typed result agrees across summary and exact report text",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 typed dataclass direct oracle is opt in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "from dataclasses import dataclass",
    "from eyetrajectoriespy.workflows._core import WorkflowStepRecord, WorkflowDecisionRecord, workflow_summary_frame, workflow_reporting_text",
    "@dataclass",
    "class WorkflowPairConfig:",
    "    alpha: int = 1",
    "@dataclass",
    "class WorkflowPairResult:",
    "    workflow_schema_version: object",
    "    workflow_contract: str",
    "    config: WorkflowPairConfig",
    "    steps: tuple",
    "    decisions: dict",
    "    provenance: dict",
    "def workflow_pair_fixture(n, identifier, version=1):",
    "    statuses=('completed','failed','skipped','completed')",
    "    sources=('analyst','audited_selector','workflow_contract','derived')",
    "    steps=tuple(WorkflowStepRecord(name=f'step{i}', function='fit', status=statuses[i%4], parameters={'trial':i}, elapsed_seconds=i/8, warnings=tuple('w' for _ in range(i%3))) for i in range(n))",
    "    decisions={f'd{i}': WorkflowDecisionRecord(value=i, source=s, criterion='criterion' if s=='audited_selector' else None) for i,s in enumerate(sources)}",
    "    return WorkflowPairResult(version,identifier,WorkflowPairConfig(),steps,decisions,{})"
  ),collapse="\n"),convert=FALSE)
  py<-reticulate::py
  cases<-list(
    list(n=0L,id="empty",version=1L),
    list(n=1L,id="single",version=1L),
    list(n=3L,id="mixed'audit",version=1L),
    list(n=4L,id="a\"quote",version=1L),
    list(n=7L,id="Greek-αβ newline\nand tabs\t",version=1L),
    list(n=13L,id="unicode-\u00a0\u200b\ue000\U0001fffe",version=1L),
    list(n=2L,id="integer-coercion",version=1.9),
    list(n=5L,id="bool-version",version=TRUE)
  )
  for(case in cases) {
    source<-reticulate::py_call(py$workflow_pair_fixture,
      as.integer(case$n),case$id,case$version)
    native<-.etr_workflow_summary_pair_fixture(case$n,case$id,case$version)
    p<-as.data.frame(et_to_r(reticulate::py_call(
      py$workflow_summary_frame,source)),check.names=FALSE)
    r<-etr_workflow_summary_frame(native)
    expect_identical(names(r),names(p),info=case$id)
    expect_identical(nrow(r),nrow(p),info=case$id)
    for(field in names(r)) {
      if(is.numeric(p[[field]]))expect_equal(
        unname(r[[field]]),unname(p[[field]]),tolerance=0,
        info=paste(case$id,field))
      else expect_identical(as.character(r[[field]]),
        as.character(p[[field]]),info=paste(case$id,field))
    }
    source_text<-as.character(et_to_r(reticulate::py_call(
      py$workflow_reporting_text,source)))
    expect_identical(etr_workflow_reporting_text(native),source_text,
      info=paste(case$id,"report"))
  }
  # These are developer-verifiable R representations, never independent audit.
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
