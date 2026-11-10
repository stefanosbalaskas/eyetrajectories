# Source: eyetrajectoriespy 1.2.0, workflows/_core.py, pinned
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Native R S3 config is NOT asserted to be a Python dataclass source contract.

test_that("explicit native preprocessing plan does not invent steps", {
  plan <- etr_preprocessing_plan()
  expect_identical(names(etr_workflow_config_to_dict(plan)),"steps")
  expect_length(etr_workflow_config_to_dict(plan)$steps,0L)
  step <- etr_preprocessing_step_config(
    function_name="smooth_trajectories",
    parameters=list(window=3L,method="mean"),
    scientific_effect="Analyst-requested observed-grid smoothing")
  expect_identical(names(etr_workflow_config_to_dict(step)),
    c("function","parameters","scientific_effect"))
  expect_identical(etr_workflow_config_to_dict(step)[["function"]],
    "smooth_trajectories")
  plan <- etr_preprocessing_plan(list(step))
  out <- etr_workflow_config_to_dict(plan)
  expect_length(out$steps,1L)
  expect_identical(out$steps[[1L]]$parameters$window,3L)
  cfg <- etr_workflow_config(list(
    preprocessing=plan,
    select_components=FALSE,
    n_components=3L))
  projection <- etr_workflow_config_to_dict(cfg)
  expect_identical(projection$preprocessing$steps[[1L]]$scientific_effect,
    "Analyst-requested observed-grid smoothing")
  expect_identical(projection$select_components,FALSE)
  expect_identical(projection$n_components,3L)
  expect_false(requireNamespace("reticulate",quietly=TRUE) &&
    inherits(projection,"python.builtin.object"))
})

test_that("native workflow config validation refuses implicit scientific decisions",{
  expect_error(etr_workflow_config_to_dict(list()),"native workflow")
  expect_error(etr_workflow_config(list(1L)),"unique character")
  expect_error(etr_workflow_config(structure(list(1L,2L),
    names=c("a","a"))),"unique character")
  expect_error(etr_workflow_config(list(weight=NaN)),"nonfinite")
  expect_error(etr_preprocessing_step_config("",list(),"effect"),
    "nonempty")
  expect_error(etr_preprocessing_step_config("fit",list(),""),"effect")
  expect_error(etr_preprocessing_step_config("fit",list(x=Inf),"effect"),
    "nonfinite")
  expect_error(etr_preprocessing_plan(list(list("fit"))),
    "native preprocessing")
  expect_length(etr_workflow_config_to_dict(etr_workflow_config()),0L)
})

test_that("workflow configuration remains an unresolved, individually tracked source contract",{
  z <- etr_native_parity_catalog()
  row <- z[z$is_python_function &
    z$python_name=="workflow_config_to_dict",,drop=FALSE]
  expect_equal(nrow(row),1L)
  expect_identical(row$native_r_candidate,
    "etr_workflow_config_to_dict")
  expect_true(row$native_implementation_started)
  expect_true(row$source_contract_gap_unresolved)
  expect_false(row$one_to_one_native_contract_complete)
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$is_python_function & z$named_native_candidate),380L)
  expect_equal(sum(z$native_implementation_started),380L)
  gaps<-utils::read.csv(.etr_test_extdata("native_source_contract_gaps_stage22.csv"))
  expect_setequal(z$python_name[z$source_contract_gap_unresolved],
    gaps$python_name[gaps$unresolved_source_gap])
  exports <- getNamespaceExports("eyetrajectories")
  expect_false(any(grepl("stage[0-9]+|etr[0-9]+_",
    exports,ignore.case=TRUE)))
})

test_that("published Python 1.2 dataclass preprocessing plans match common semantic fields",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 typed preprocessing plan source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  wf <- reticulate::import("eyetrajectoriespy.workflows",convert=FALSE)
  py_step <- reticulate::py_call(wf$PreprocessingStepConfig,
    `function`="smooth_trajectories",
    parameters=reticulate::dict(window=as.integer(3L),method="mean"),
    scientific_effect="Analyst-requested observed-grid smoothing")
  py_plan <- reticulate::py_call(wf$PreprocessingPlan,
    steps=reticulate::r_to_py(list(py_step)))
  py <- reticulate::py_to_r(reticulate::py_call(
    wf$workflow_config_to_dict,config=py_plan))
  r_step <- etr_preprocessing_step_config("smooth_trajectories",
    list(window=3L,method="mean"),
    "Analyst-requested observed-grid smoothing")
  native <- etr_workflow_config_to_dict(etr_preprocessing_plan(list(r_step)))
  expect_identical(names(py),names(native))
  expect_length(py$steps,1L)
  for(field in c("function","scientific_effect"))
    expect_identical(py$steps[[1L]][[field]],native$steps[[1L]][[field]])
  expect_equal(py$steps[[1L]]$parameters$window,
    native$steps[[1L]]$parameters$window)
  expect_identical(py$steps[[1L]]$parameters$method,
    native$steps[[1L]]$parameters$method)
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
