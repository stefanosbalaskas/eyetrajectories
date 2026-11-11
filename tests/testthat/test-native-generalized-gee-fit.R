# Frozen source: eyetrajectoriespy 1.2.0 generalized_function_on_scalar.py
# Native R GLM score solver with participant-cluster sandwich covariance.
test_that("source-order generalized designs and workflow audits are explicit",{
  f<-.etr_native_gee_fixture()
  d<-f$design[match(f$x$curve_ids,f$design$curve_id),,drop=FALSE]
  config<-list(predictors="treatment",participant_column="participant_id",
    dimension="outcome",family=" PoIsSoN ",basis_size=4L,
    exposure=rep("2_0",nrow(d)),exposure_units=" person-hours ")
  ordered<-data.frame(treatment=as.character(d$treatment))
  w<-etr_run_generalized_functional_workflow(f$x,ordered,config,
    python_boundary_mode=TRUE)
  expect_s3_class(w,"etr_workflow_audit_result")
  expect_identical(w$workflow_contract,"generalized_functional:v1")
  expect_identical(w$fit$family,"poisson")
  expect_identical(w$fit$exposure_units,"person-hours")
  expect_equal(as.numeric(w$fit$exposure),rep(20,length(w$fit$exposure)))
  expect_identical(w$decisions$exposure_supplied$value,TRUE)
  expect_true(is.finite(etr_workflow_steps_frame(w$steps)$elapsed_seconds))
  expect_error(etr_run_generalized_functional_workflow(f$x,ordered,config),
    "without curve_id")
  rownames(ordered)<-paste0("row",seq_len(nrow(ordered)))
  expect_error(etr_run_generalized_functional_workflow(f$x,ordered,config,
    python_boundary_mode=TRUE),"default row names")
  expect_error(etr_run_generalized_functional_workflow(f$x,f$design,config,
    python_boundary_mode=TRUE),"same order")
})

test_that("grouped counts use the source integer tolerance",{
  f<-.etr_native_gee_fixture("binomial",grouped=TRUE)
  fit<-function(den)etr_fit_generalized_function_on_scalar_regression(
    f$x,f$design,"treatment",participant_column="participant_id",
    dimension="outcome",family="binomial",basis_size=4L,
    binomial_denominator=den)
  within<-f$den+5e-13
  expect_identical(unname(fit(within)$binomial_denominators),within)
  expect_error(fit(f$den+2e-12),"integer")
})

test_that("source mode separates GLM initialization from GEE score control",{
  fit<-function(key)do.call(etr_fit_generalized_function_on_scalar_regression,
    .etr_native_gee_boundary_case(key))
  p<-fit("one_update")
  expect_identical(p$maxiter,1L)
  expect_identical(p$provenance$gee_score_iterations,1L)
  expect_gt(p$provenance$glm_initialization_iterations,1L)
  expect_lt(p$provenance$gee_score_norm,p$ctol)
  a<-.etr_native_gee_boundary_case("one_update")
  a$python_boundary_mode<-FALSE
  expect_error(do.call(etr_fit_generalized_function_on_scalar_regression,a),
    "did not converge")
  expect_error(fit("score_too_large"),"GEE did not converge")
  expect_error(fit("subthreshold_rank"),"scalar design matrix rank deficient")
  expect_error(fit("rank_deficient"),"scalar design matrix rank deficient")
  expect_error(fit("zero_counts"),"first guess on the deviance")
  s<-fit("nearly_rank_deficient")
  expect_identical(s$expanded_design_rank,8L)
  expect_equal(s$mean_functions,s$rate_functions*s$exposure,tolerance=1e-12)
  expect_true(all(is.finite(s$parameter_covariance)))
  expect_identical(fit("numeric_curve_id")$coefficient_names,
    c("Intercept","curve_id"))
  z<-fit("separated")
  expect_true(length(z$backend_warnings)>0L)
  expect_true(all(grepl("Perfect separation",z$backend_warnings,fixed=TRUE)))
})

test_that("native Poisson GEE fits real expanded spline and participant sandwich",{
  f<-.etr_native_gee_fixture()
  model<-etr_fit_generalized_function_on_scalar_regression(
    f$x,f$design,predictors="treatment",
    participant_column="participant_id",dimension="outcome",
    family="poisson",basis_size=4L,spline_degree=3L)
  expect_s3_class(model,"etr_generalized_function_on_scalar")
  expect_identical(dim(model$coefficient_functions),c(2L,7L))
  expect_identical(dim(model$parameter_covariance),c(8L,8L))
  expect_identical(dim(model$mean_functions),c(36L,7L))
  expect_identical(model$expanded_design_rank,8L)
  expect_equal(rowSums(model$basis),rep(1,7),tolerance=1e-12)
  expect_true(all(is.finite(model$coefficient_functions)))
  expect_true(all(model$coefficient_standard_errors>=0))
  expect_equal(model$parameter_covariance,t(model$parameter_covariance),
    tolerance=1e-12)
  expect_equal(unname(model$mean_functions),
    unname(exp(model$scalar_design_matrix%*%model$coefficient_functions)),
    tolerance=1e-8)
  expect_false(model$provenance$full_source_contract_certified)
  w<-etr_run_generalized_functional_workflow(
    f$x,f$design,list(predictors="treatment",
      participant_column="participant_id",
      dimension="outcome",family="poisson",
      basis_size=4L,spline_degree=3L))
  expect_s3_class(w,"etr_generalized_functional_workflow")
  expect_equal(w$fit$coefficient_functions,model$coefficient_functions)
  expect_equal(nrow(w$tables$coefficients),14L)
  expect_false(w$provenance$independently_certified_full_contract)
  expect_true(w$provenance$automatic_model_selection_performed==FALSE)
})

test_that("native grouped binomial and Poisson exposure are explicit",{
  f<-.etr_native_gee_fixture("binomial",grouped=TRUE)
  z<-etr_fit_generalized_function_on_scalar_regression(f$x,f$design,
    "treatment",participant_column="participant_id",
    dimension="outcome",family="binomial",
    binomial_denominator=f$den,basis_size=4L,spline_degree=3L)
  expect_equal(z$binomial_expected_successes,
    z$mean_functions*f$den,tolerance=1e-12)
  expect_true(all(z$mean_functions>0&z$mean_functions<1))
  expect_identical(z$binomial_denominators,f$den)
  f<-.etr_native_gee_fixture()
  exposure<-rep(2,36L)
  p<-etr_fit_generalized_function_on_scalar_regression(
    f$x,f$design,"treatment",
    participant_column="participant_id",dimension="outcome",
    family="poisson",exposure=exposure,
    exposure_units="person_hours",basis_size=4L,spline_degree=3L)
  expect_equal(unname(p$mean_functions),unname(p$rate_functions*2),
    tolerance=1e-8)
  expect_identical(p$exposure_units,"person_hours")
  expect_true(p$exposure_expanded_from_curve)
  expect_error(etr_fit_generalized_function_on_scalar_regression(
    f$x,f$design,"treatment",participant_column="participant_id",
    dimension="outcome",family="poisson",
    binomial_denominator=rep(2,36L),basis_size=4L),
    "must match declared family")
})

test_that("native generalized estimator rejects unsupported or invalid source domains",{
  f<-.etr_native_gee_fixture()
  call<-function(...)etr_fit_generalized_function_on_scalar_regression(
    f$x,f$design,"treatment",
    participant_column="participant_id",dimension="outcome",
    family="poisson",basis_size=4L,spline_degree=3L,...)
  expect_error(call(working_correlation="exchangeable"),"independence")
  expect_error(call(covariance_type="naive"),"robust")
  expect_error(call(basis_size=2L),"basis_size")
  expect_error(etr_fit_generalized_function_on_scalar_regression(
    f$x,f$design,"treatment",
    participant_column="participant_id",dimension="outcome",
    family="gaussian",basis_size=4L,spline_degree=3L),"family")
  expect_error(call(exposure=rep(-1,36L)),"positive")
  expect_error(etr_run_generalized_functional_workflow(
    f$x,f$design,list(predictors="treatment",
      participant_column="participant_id",dimension="outcome",
      family="poisson",preprocessing=list(normalize=TRUE))),
    "empty preprocessing")
})

test_that("published Python 1.2 direct GEE Poisson spline and robust SE agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("published Python 1.2 generalized GEE numerical oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import pandas as pd
from eyetrajectoriespy.types import TrajectorySet
from eyetrajectoriespy.generalized_function_on_scalar import fit_generalized_function_on_scalar_regression
n=36
t=np.linspace(0,1,7)
idx=np.arange(1,n+1)[:,None]
j=np.arange(1,8)[None,:]
y=((idx+2*j+(idx*j)%3)%6).astype(float)
ids=tuple(f'curve{i:02d}' for i in range(1,n+1))
tr=TrajectorySet(time=t,values=y[:,:,None],curve_ids=ids,
 dimension_names=('outcome',),
 metadata=pd.DataFrame({'participant_id':[f'P{i:02d}' for i in range(1,13) for _ in range(3)]}),
 coordinate_system='unknown',time_unit='s')
ordered=np.arange(1,n+1)
design=pd.DataFrame({'curve_id':[f'curve{i:02d}' for i in ordered],
 'treatment':(ordered%4<2).astype(float)})
pygee=fit_generalized_function_on_scalar_regression(tr,design,
 ['treatment'],participant_column='participant_id',
 dimension='outcome',family='poisson',basis_size=4,spline_degree=3)
try:
 fit_generalized_function_on_scalar_regression(tr,design.iloc[::-1].reset_index(drop=True),
  ['treatment'],participant_column='participant_id',
  dimension='outcome',family='poisson',basis_size=4,spline_degree=3)
 _pygee_reordered_rejected=False
except ValueError:
 _pygee_reordered_rejected=True
_pygee_oracle={'basis':pygee.basis,
 'coef':pygee.coefficient_functions,
 'se':pygee.coefficient_standard_errors,
 'mean':pygee.mean_functions,
 'cov':pygee.parameter_covariance}
")
  expect_true(reticulate::py_to_r(reticulate::py_eval(
    "_pygee_reordered_rejected",convert=FALSE)))
  # A second execution through the frozen Python public export is
  # checked against the independently retained published-source fit.
  direct<-reticulate::py_call(
    etpy_get_export("fit_generalized_function_on_scalar_regression"),
    trajectories=reticulate::py_eval("tr",convert=FALSE),
    design=reticulate::py_eval("design",convert=FALSE),
    predictors=reticulate::py_eval("['treatment']",convert=FALSE),
    participant_column="participant_id",dimension="outcome",
    family="poisson",basis_size=4L,spline_degree=3L)
  fields<-c(basis="basis",coef="coefficient_functions",
    se="coefficient_standard_errors",mean="mean_functions",
    cov="parameter_covariance")
  for(key in names(fields)){
    expected<-reticulate::py_eval(
      paste0("_pygee_oracle['",key,"']"),convert=TRUE)
    observed<-et_to_r(reticulate::py_get_attr(direct,fields[[key]]))
    expect_equal(observed,expected,tolerance=1e-12,
      ignore_attr=TRUE,info=paste("direct source GEE",key))
  }
  py<-reticulate::py_to_r(reticulate::py_eval("_pygee_oracle",
    convert=FALSE))
  f<-.etr_native_gee_fixture()
  r<-etr_fit_generalized_function_on_scalar_regression(
    f$x,f$design,"treatment",
    participant_column="participant_id",dimension="outcome",
    family="poisson",basis_size=4L,spline_degree=3L)
  expect_equal(unname(r$basis),unname(py$basis),tolerance=1e-9)
  expect_equal(unname(r$coefficient_functions),unname(py$coef),
    tolerance=1e-5)
  expect_equal(unname(r$coefficient_standard_errors),unname(py$se),
    tolerance=1e-4)
  expect_equal(unname(r$mean_functions),unname(py$mean),tolerance=1e-5)
  expect_equal(unname(r$parameter_covariance),unname(py$cov),tolerance=1e-4)
})

# Actual frozen-Python 1.2 source-symbol inspection on published exports.
# For alternate R estimands/backends this is NOT numerical source parity.
test_that("unreviewed Python 1.2 source symbols are inspectable: run_generalized_functional_workflow",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python source-symbol audit requires source runtime")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("run_generalized_functional_workflow",.namespace="workflows"),"run_generalized_functional_workflow")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
