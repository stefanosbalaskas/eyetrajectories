# Source: eyetrajectoriespy==1.2.0, pinned c1cd95ad718327550f7e55393ff38582872f7a94.
# The API names and numeric/semantic fixtures are NOT independent full-domain approval.

.etr_workflow_audit_fixture <- function() {
  etr_workflow_audit_result("dense_fpca",
    steps=list(
      list(name="validate",`function`="inspect",status="completed",
        parameters=list(alpha=1L),elapsed_seconds=0.125,
        warnings=c("source warning")),
      list(name="fit",`function`="fit_fpca",status="skipped",
        parameters=list(),elapsed_seconds=0,warnings=character())),
    decisions=list(
      alpha=list(value=1L,source="analyst",criterion=NULL),
      k=list(value=2L,source="audited_selector",
        criterion="held-out score")))
}

test_that("native workflow summary and text have no optional JSON dependency",{
  result <- .etr_workflow_audit_fixture()
  out <- etr_workflow_summary_frame(result)
  expect_equal(out$step_count,2L)
  expect_equal(out$warning_count,1L)
  expect_true(grepl("scientific decisions",
    etr_workflow_reporting_text(result),fixed=TRUE))
})

test_that("workflow reporting preserves ordered steps, statuses and decisions",{
  skip_if_not_installed("jsonlite")
  result <- .etr_workflow_audit_fixture()
  steps <- etr_workflow_steps_frame(result$steps)
  decisions <- etr_workflow_decisions_frame(result$decisions)
  summary <- etr_workflow_summary_frame(result)
  expect_identical(names(steps),c("order","name","function","status",
    "elapsed_seconds","parameters_json","warning_count","warnings"))
  expect_identical(steps$order,c(1L,2L))
  expect_identical(steps[["function"]],c("inspect","fit_fpca"))
  expect_identical(steps$status,c("completed","skipped"))
  expect_equal(steps$elapsed_seconds,c(.125,0),tolerance=0)
  expect_identical(steps$parameters_json,c('{"alpha":1}','{}'))
  expect_identical(steps$warning_count,c(1L,0L))
  expect_identical(steps$warnings,c("source warning",""))
  expect_identical(names(decisions),c("name","value_json","source","criterion"))
  expect_identical(decisions$name,c("alpha","k"))
  expect_identical(decisions$value_json,c("1","2"))
  expect_identical(decisions$source,c("analyst","audited_selector"))
  expect_true(is.na(decisions$criterion[1L]))
  expect_identical(decisions$criterion[2L],"held-out score")
  expect_identical(names(summary),c("workflow_schema_version",
    "workflow_contract","step_count","completed_steps","failed_steps",
    "skipped_steps","warning_count","decision_count","analyst_decisions",
    "audited_selector_decisions","workflow_contract_decisions",
    "derived_decisions"))
  expect_equal(summary$step_count,2L)
  expect_equal(summary$completed_steps,1L)
  expect_equal(summary$failed_steps,0L)
  expect_equal(summary$skipped_steps,1L)
  expect_equal(summary$warning_count,1L)
  expect_equal(summary$decision_count,2L)
  expect_equal(summary$analyst_decisions,1L)
  expect_equal(summary$audited_selector_decisions,1L)
  report <- etr_workflow_reporting_text(result)
  expect_true(grepl("Workflow 'dense_fpca' used schema 1",report,fixed=TRUE))
  expect_true(grepl("2 ordered steps (1 completed, 0 failed, 1 skipped)",report,
    fixed=TRUE))
  expect_true(grepl("does not itself authorize hidden preprocessing",report,
    fixed=TRUE))
  expect_identical(names(etr_workflow_steps_frame(list())),names(steps))
  expect_identical(names(etr_workflow_decisions_frame(list())),names(decisions))
})

test_that("workflow audit records reject hidden decisions and invalid values",{
  skip_if_not_installed("jsonlite")
  expect_error(etr_workflow_steps_frame(list(list(name="bad",
    `function`="fit",status="automatic",parameters=list(),
    elapsed_seconds=0,warnings=character()))),"requires")
  expect_error(etr_workflow_steps_frame(list(list(name="bad",
    `function`="fit",status="completed",parameters=list(),
    elapsed_seconds=-1,warnings=character()))),"requires")
  expect_error(etr_workflow_steps_frame(list(list(name="bad",
    `function`="fit",status="completed",parameters=list(a=Inf),
    elapsed_seconds=0,warnings=character()))),"nonfinite")
  expect_error(etr_workflow_decisions_frame(
    list(k=list(value=2L,source="audited_selector"))),"criterion")
  expect_error(etr_workflow_decisions_frame(
    list(k=list(value=NaN,source="analyst"))),"nonfinite")
  expect_error(etr_workflow_audit_result(""),"nonempty")
  expect_error(etr_workflow_summary_frame(list()),"native workflow audit")
  expect_error(etr_workflow_reporting_text(list()),"native workflow audit")
})

test_that("workflow JSON recursively sorts mapping keys and preserves step order",{
  skip_if_not_installed("jsonlite")
  z<-etr_workflow_decisions_frame(list(a=list(
    value=list(z=1L,a=list(y=2L,b=3L)),source="analyst")))
  expect_identical(z$value_json,'{"a":{"b":3,"y":2},"z":1}')
  step<-list(name="inspect",`function`="inspect",status="completed",
    parameters=list(z=1L,a=list(y=2L,b=3L)),
    elapsed_seconds=0,warnings=character())
  f<-etr_workflow_steps_frame(list(step))
  expect_identical(f$parameters_json,'{"a":{"b":3,"y":2},"z":1}')
})

test_that("all 128 nonfunction source symbols require independent review",{
  path <- system.file("extdata","native_nonfunction_contract_review_v1.csv",
    package="eyetrajectories")
  expect_true(nzchar(path))
  other <- utils::read.csv(path,stringsAsFactors=FALSE)
  expect_equal(nrow(other),128L)
  expect_equal(length(unique(paste(other$namespace,other$python_name))),128L)
  expect_true(all(other$evidence_state=="not_reviewed"))
  for(key in c("numerical_or_value_approved","schema_boundary_approved",
               "scientific_scope_approved","independent_reviewer_approved"))
    expect_false(any(other[[key]]))
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("workflow integration stays uncertified until independent full review",{
  z <- etr_native_parity_catalog()
  expect_equal(nrow(z),508L)
  expect_gte(sum(z$is_python_function & z$named_native_candidate),337L)
  expect_gte(sum(z$native_implementation_started),313L)
  expect_gte(sum(z$source_contract_gap_unresolved),160L)
  for(name in c("workflow_steps_frame","workflow_decisions_frame",
                "workflow_summary_frame","workflow_reporting_text")){
    row <- z[z$python_name==name & z$is_python_function,,drop=FALSE]
    expect_equal(nrow(row),1L)
    expect_true(row$native_implementation_started)
    expect_true(row$source_contract_gap_known)
    expect_true(row$source_contract_gap_unresolved)
    expect_false(row$one_to_one_native_contract_complete)
  }
  queue <- etr_native_source_contract_review_queue()
  expect_equal(nrow(queue),508L)
  expect_gte(sum(queue$mapped & queue$kind=="function"),337L)
  expect_equal(sum(queue$targeted_numerical_fixture_pass),4L)
  expect_gte(sum(queue$source_gap_unresolved),160L)
  expect_false(any(queue$full_numeric_approved))
  expect_false(any(queue$schema_boundary_approved))
  expect_false(any(queue$scientific_scope_approved))
  expect_false(any(queue$independent_reviewer_approved))
  expect_false(any(queue$fully_certified))
  expect_true(all(nzchar(queue$next_action)))
  expect_error(etr_native_parity_catalog(require_complete=TRUE),"NOT complete")
  exports <- getNamespaceExports("eyetrajectories")
  expect_false(any(grepl("stage",exports,ignore.case=TRUE)))
})

test_that("pinned published Python 1.2 workflow step and decision frames match common fixtures",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Published Python 1.2 workflow dataclass oracle is opt-in")
  skip_if_not_installed("jsonlite")
  expect_identical(et_python_version(),"1.2.0")
  wf <- reticulate::import("eyetrajectoriespy.workflows",convert=FALSE)
  source_step <- do.call(reticulate::py_call,
    c(list(wf$WorkflowStepRecord),list(name="validate",
      `function`="inspect",status="completed",
      parameters=reticulate::dict(alpha=1L),
      elapsed_seconds=0.125,
      # A one-element R character vector converts to a Python str; the
      # frozen dataclass then tuple(str) splits it into 14 characters.
      # Pass a Python list containing one warning string instead.
      warnings=reticulate::r_to_py(list("source warning")))))
  py_steps <- reticulate::py_to_r(reticulate::py_call(
    wf$workflow_steps_frame,
    steps=reticulate::r_to_py(list(source_step))))
  native_steps <- etr_workflow_steps_frame(list(
    list(name="validate",`function`="inspect",status="completed",
      parameters=list(alpha=1L),elapsed_seconds=0.125,
      warnings="source warning")))
  expect_identical(names(py_steps),names(native_steps))
  for(name in names(native_steps))
    expect_equal(unname(py_steps[[name]]),unname(native_steps[[name]]),
      tolerance=1e-12,info=name)
  py_decision <- reticulate::py_call(wf$WorkflowDecisionRecord,
    value=1L,source="analyst")
  py <- reticulate::dict()
  py[["alpha"]] <- py_decision
  py_decisions <- reticulate::py_to_r(reticulate::py_call(
    wf$workflow_decisions_frame,decisions=py))
  native_decisions <- etr_workflow_decisions_frame(
    list(alpha=list(value=1L,source="analyst")))
  expect_identical(names(py_decisions),names(native_decisions))
  expect_identical(as.character(py_decisions$value_json),
    as.character(native_decisions$value_json))
  expect_identical(as.character(py_decisions$source),
    as.character(native_decisions$source))
  py_map<-reticulate::dict(z=as.integer(1L),
    a=reticulate::dict(y=as.integer(2L),b=as.integer(3L)))
  py_nested<-reticulate::py_call(wf$WorkflowDecisionRecord,
    value=py_map,source="analyst")
  py_items<-reticulate::dict()
  py_items[["nested"]]<-py_nested
  py_sorted<-reticulate::py_to_r(reticulate::py_call(
    wf$workflow_decisions_frame,decisions=py_items))
  r_sorted<-etr_workflow_decisions_frame(list(nested=list(
    value=list(z=1L,a=list(y=2L,b=3L)),source="analyst")))
  expect_identical(as.character(py_sorted$value_json),
    as.character(r_sorted$value_json))
  expect_false(any(etr_native_parity_catalog()$one_to_one_native_contract_complete))
})
