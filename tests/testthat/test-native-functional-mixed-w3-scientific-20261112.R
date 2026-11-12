# Frozen Python 1.2 workflows/_dense_regression.py mixed-effects W3
# workflow: pinned commit c1cd95ad718327550f7e55393ff38582872f7a94.
# This compares source-scientific workflow fields, configuration, execution
# semantics and numerical native Gaussian likelihood, NOT independent
# statsmodels optimization identity or all Python error classes.

test_that("mixed W3 source workflow preserves fifteen config fields and nine result fields",{
  skip_if_not_installed("nlme")
  f<-.etr_joint_workflow_live_fixture()
  cfg<-.etr_joint_source_cfg(
    dimension="gaze_x",
    fixed_basis_size=2L,random_basis_size=2L,
    spline_degree=1L,reml=TRUE,maxiter=500L)
  set.seed(197L)
  before<-.Random.seed
  out<-etr_run_functional_mixed_effects_workflow(
    f$trajectories,f$design,cfg,strict_source_record=TRUE)
  expect_identical(before,.Random.seed)
  expect_s3_class(out,"etr_functional_mixed_effects_w3_scientific_workflow")
  expect_s3_class(out$fit,"etr_joint_bspline_mixed")
  expect_identical(out$fit$backend,"nlme::lme")
  expect_true(inherits(out$fit$fitted_model,"lme"))
  expect_identical(names(out),.etr_joint_w3_workflow_fields)
  expect_identical(out$workflow_schema_version,1L)
  expect_identical(out$workflow_contract,"functional_mixed_effects:v1")
  expect_identical(names(out$config),.etr_joint_w3_config_fields)
  expect_false("estimator"%in%names(out$config))
  expect_identical(out$config$method,"nlme::lme")
  expect_identical(out$config$trial_random_basis_size,3L)
  expect_identical(out$config$preprocessing,list(steps=list()))
  expect_identical(out$config$predictors,"stimulus")
  expect_identical(out$config$participant_column,"participant_id")
  expect_identical(out$config$dimension,"gaze_x")
  expect_true(out$config$reml)
  expect_identical(names(out$provenance),.etr_joint_w3_provenance_fields)
  expect_identical(out$provenance$input_layout,"complete_common_grid")
  expect_false(out$provenance$preprocessing_executed)
  expect_false(out$provenance$automatic_optimizer_fallback)
  expect_false(out$provenance$automatic_model_selection_performed)
  expect_false(out$provenance$automatic_random_effect_selection)
  expect_false(out$provenance$automatic_residual_correlation_selection)
  expect_length(out$steps,1L)
  step<-out$steps[[1L]]
  expect_identical(names(step),.etr_joint_w3_step_fields)
  expect_identical(step$name,"fit")
  expect_identical(step$status,"completed")
  expect_identical(step[["function"]],
    "etr_fit_joint_bspline_functional_mixed_effects")
  expect_identical(names(step$parameters),
    .etr_joint_w3_config_fields[-15L])
  expect_true(is.numeric(step$elapsed_seconds)&&
    length(step$elapsed_seconds)==1L&&
    is.finite(step$elapsed_seconds)&&step$elapsed_seconds>=0)
  expect_true(is.character(step$warnings))
  expect_identical(names(out$decisions),names(step$parameters))
  for(key in names(out$decisions)){
    expect_identical(out$decisions[[key]]$source,"analyst")
    expect_identical(out$decisions[[key]]$value,step$parameters[[key]],
      info=paste("W3 source decision",key))
  }
  expect_identical(names(out$tables),"coefficients")
  tbl<-out$tables$coefficients
  expect_identical(names(tbl),c(
    "coefficient","time","dimension","estimate",
    "standard_error","lower_95_wald","upper_95_wald"))
  expect_identical(nrow(tbl),14L)
  expect_equal(tbl$estimate,
    as.vector(t(out$fit$fixed_coefficient_functions)),
    tolerance=1e-8,ignore_attr=TRUE)
  expect_equal(tbl$lower_95_wald,
    tbl$estimate-1.959963984540054*tbl$standard_error,
    tolerance=1e-10,ignore_attr=TRUE)
  expect_equal(tbl$upper_95_wald,
    tbl$estimate+1.959963984540054*tbl$standard_error,
    tolerance=1e-10,ignore_attr=TRUE)
  expect_true(all(tbl$dimension=="gaze_x"))
  expect_true(all(is.finite(out$fit$fixed_coefficient_functions)))
  expect_true(is.finite(out$fit$residual_variance)&&
    out$fit$residual_variance>0)
  expect_lt(max(abs(out$fit$fitted_functions+
    out$fit$residual_functions-
    out$fit$observed_functions)),1e-7)
  expect_match(out$reports$fit,"R/nlme")
  expect_match(out$reports$fit,"NOT claimed equivalent")
  expect_false(inherits(out$fit,"FunctionalMixedEffectsResult"))
})

test_that("mixed W3 strict mode refuses moments, Python optimizer impersonation and unrecorded transformations",{
  f<-.etr_joint_source_workflow_fixture()
  cfg<-.etr_joint_source_cfg()
  check<-function(configuration,strict=TRUE)
    etr_run_functional_mixed_effects_workflow(
      f$trajectories,f$design,configuration,
      strict_source_record=strict)
  expect_error(check(cfg,strict=1L),"strict_source_record")
  expect_error(check(cfg,strict=NA),"strict_source_record")
  moments<-list(predictors="stimulus",
    participant_column="participant_id",dimension="response",
    estimator="two_level_functional_method_of_moments")
  expect_error(check(moments),"requires native_joint_bspline_gaussian")
  expect_error(check(utils::modifyList(cfg,list(method="lbfgs"))),
    "Python lbfgs")
  expect_error(check(utils::modifyList(cfg,list(
    preprocessing=list(list(kind="smooth")))))),
    "empty preprocessing")
  expect_error(check(utils::modifyList(cfg,list(
    residual_correlation="ar1"))),
    "requires.*nested trial")
  expect_error(check(utils::modifyList(cfg,list(
    trial_column="trial_id"))),
    "trial_random_effect")
  expect_error(check(utils::modifyList(cfg,list(
    covariance_ridge=1e-6))),
    "unsupported fields")
  expect_identical(names(.etr_joint_w3_workflow_fields),NULL)
})

test_that("frozen Python 1.2 W3 dataclass fields and parameter map match R scientific envelope",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 W3 dataclass schema oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
from dataclasses import fields
from eyetrajectoriespy.workflows._dense_regression import (
  FunctionalMixedEffectsWorkflowConfig,
  FunctionalMixedEffectsWorkflowResult,
)
from eyetrajectoriespy.workflows._core import (
  WorkflowDecisionRecord,WorkflowStepRecord
)
def _etr_mixed_w3_oracle():
    return {
      'config':tuple(x.name for x in fields(FunctionalMixedEffectsWorkflowConfig)),
      'workflow':tuple(x.name for x in fields(FunctionalMixedEffectsWorkflowResult)),
      'step':tuple(x.name for x in fields(WorkflowStepRecord)),
      'decision':tuple(x.name for x in fields(WorkflowDecisionRecord)),
    }
")
  actual<-et_to_r(reticulate::py_call(
    reticulate::py_eval("_etr_mixed_w3_oracle",convert=FALSE)))
  expect_identical(as.character(actual$config),
    .etr_joint_w3_config_fields)
  expect_identical(as.character(actual$workflow),
    .etr_joint_w3_workflow_fields)
  expect_identical(as.character(actual$step),
    .etr_joint_w3_step_fields)
  expect_identical(as.character(actual$decision),
    c("value","source","criterion"))
})
