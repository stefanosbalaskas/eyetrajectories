# Full source-semantic post-calibration contracts.
# Frozen Python eyetrajectoriespy==1.2.0 at
# c1cd95ad718327550f7e55393ff38582872f7a94:
# wild_simultaneous.py and wild_testing.py.
.etr_two_wild_source_fixture <- function() {
  roots <- rbind(c(.1,.2,.3),c(.5,.4,.1),c(.9,.6,.7),c(.2,.8,.3))
  projection <- list(
    target_curve_ids=c("curveβ","two","curve-3"),
    bootstrap_projections=matrix(0,4,3),
    studentized_roots=roots,
    reference_projection=c(.3,-.2,.1),
    reference_se=c(.1,.2,.05),
    confidence_level=.95,
    multiplier="rademacher",
    residual_components=2L,
    inference_components=3L,
    provenance=list(
      study="source-wild-audit",
      fpca_wild_bootstrap_projection=list(studentization="full_fit")))
  family <- list(
    projection_result=projection,
    observed_statistics=c(.4,.5,.25),
    max_statistics=c(.3,.5,.9,.8),
    global_statistic=.7,
    reject_targetwise=c(FALSE,FALSE,FALSE),
    reject_familywise=c(FALSE,FALSE,FALSE),
    reject_global=FALSE,
    significance_level=.05,
    pvalue_correction="plus_one",
    provenance=list(study="source-wild-audit"))
  list(projection=projection,family=family)
}

test_that("two source post-calibrators retain complete numerical and provenance semantics", {
  f <- .etr_two_wild_source_fixture()
  s <- etr_fpca_wild_bootstrap_projection_simultaneous_interval(
    f$projection,confidence_level=.5)
  expect_identical(names(s),c("projection_result",
    "targetwise_critical_values","critical_value","max_statistics",
    "lower","upper","confidence_level","provenance"))
  expect_equal(s$targetwise_critical_values,c(.5,.6,.3),tolerance=0)
  expect_equal(s$critical_value,.8,tolerance=0)
  expect_equal(s$max_statistics,c(.3,.5,.9,.8),tolerance=0)
  expect_equal(s$lower,c(.22,-.36,.06),tolerance=1e-12)
  expect_equal(s$upper,c(.38,-.04,.14),tolerance=1e-12)
  m <- s$provenance$fpca_wild_bootstrap_simultaneous
  expect_identical(names(m),c(
    "method","family","estimand","confidence_level","n_targets",
    "family_definition","bootstrap_roots_reused","bootstrap_rerun",
    "studentization","multiplier","residual_components_k",
    "pseudo_truth_components_g","inference_components_h",
    "simultaneous_across_targets","future_outcome_prediction_interval",
    "clustered_wild_bootstrap","component_selection_uncertainty_included"))
  expect_identical(m$studentization,"full_fit")
  expect_identical(m$multiplier,"rademacher")
  expect_identical(m$residual_components_k,2L)
  expect_identical(m$pseudo_truth_components_g,2L)
  expect_identical(m$inference_components_h,3L)
  expect_identical(s$provenance$study,"source-wild-audit")
  expect_identical(s$projection_result$target_curve_ids,
    c("curveβ","two","curve-3"))

  d <- etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(
    f$family,confidence_level=.75)
  expect_identical(names(d),c("family_test_result","confidence_level",
    "targetwise_exceedances","adjusted_exceedances",
    "global_exceedances","targetwise_tail_probabilities",
    "adjusted_tail_probabilities","global_tail_probability",
    "targetwise_mcse","adjusted_mcse","global_mcse",
    "targetwise_interval_lower","targetwise_interval_upper",
    "adjusted_interval_lower","adjusted_interval_upper",
    "global_interval_lower","global_interval_upper",
    "targetwise_decision_stable","adjusted_decision_stable",
    "global_decision_stable","provenance"))
  expect_identical(d$targetwise_exceedances,c(2L,2L,3L))
  expect_identical(d$adjusted_exceedances,c(3L,3L,4L))
  expect_identical(d$global_exceedances,2L)
  expect_equal(d$targetwise_tail_probabilities,c(.5,.5,.75))
  expect_equal(d$adjusted_tail_probabilities,c(.75,.75,1))
  expect_equal(d$global_tail_probability,.5)
  expect_equal(d$global_mcse,.25)
  expect_equal(d$adjusted_interval_upper[3],1)
  expect_identical(d$provenance$study,"source-wild-audit")
  expect_identical(d$provenance$
    fpca_wild_bootstrap_monte_carlo_diagnostics$
    reported_test_pvalue_correction,"plus_one")
  expect_equal(d$provenance$
    fpca_wild_bootstrap_monte_carlo_diagnostics$
    reported_test_minimum_attainable_p,1/5)
  expect_false(d$provenance$
    fpca_wild_bootstrap_monte_carlo_diagnostics$additional_bootstrap_draws)
  expect_identical(d$family_test_result$projection_result$target_curve_ids,
    c("curveβ","two","curve-3"))
})

test_that("wild postcalibrators handle one-root, zero and all-exceedance boundaries", {
  f <- .etr_two_wild_source_fixture()
  single <- f$projection
  single$target_curve_ids <- "only"
  single$bootstrap_projections <- matrix(0,1,1)
  single$studentized_roots <- matrix(-.9,1,1)
  single$reference_projection <- .4
  single$reference_se <- .2
  s <- etr_fpca_wild_bootstrap_projection_simultaneous_interval(
    single,confidence_level=.9)
  expect_equal(s$critical_value,.9,tolerance=0)
  expect_equal(s$targetwise_critical_values,.9,tolerance=0)
  expect_equal(s$lower,.22,tolerance=1e-12)
  expect_equal(s$upper,.58,tolerance=1e-12)

  zero <- f$family
  zero$observed_statistics <- rep(10,3)
  zero$global_statistic <- 10
  z <- etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(zero)
  expect_identical(z$targetwise_exceedances,rep(0L,3))
  expect_identical(z$adjusted_exceedances,rep(0L,3))
  expect_identical(z$global_exceedances,0L)
  expect_equal(z$targetwise_interval_lower,rep(0,3))
  expect_equal(z$global_interval_lower,0)

  all <- f$family
  all$observed_statistics <- rep(0,3)
  all$global_statistic <- 0
  a <- etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(all)
  expect_identical(a$targetwise_exceedances,rep(4L,3))
  expect_identical(a$adjusted_exceedances,rep(4L,3))
  expect_identical(a$global_exceedances,4L)
  expect_equal(a$targetwise_interval_upper,rep(1,3))
  expect_equal(a$global_interval_upper,1)
})

test_that("post-calibration invalid scientific domains fail before recording closure", {
  f <- .etr_two_wild_source_fixture()
  bad <- f$projection
  bad$studentized_roots[1L,2L] <- Inf
  expect_error(
    etr_fpca_wild_bootstrap_projection_simultaneous_interval(bad),
    "studentized_roots")
  bad <- f$projection
  bad$provenance <- list("unnamed")
  expect_error(
    etr_fpca_wild_bootstrap_projection_simultaneous_interval(bad),
    "provenance")
  bad <- f$projection
  bad$reference_se[1L] <- -1
  expect_error(
    etr_fpca_wild_bootstrap_projection_simultaneous_interval(bad),
    "reference standard errors")
  bad <- f$family
  bad$max_statistics <- c(0,0)
  expect_error(
    etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(bad),
    "max_statistics")
  bad <- f$family
  bad$reject_global <- NA
  expect_error(
    etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(bad),
    "reject_global")
  bad <- f$family
  bad$pvalue_correction <- "unknown"
  expect_error(
    etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(bad),
    "pvalue_correction")
})

test_that("full frozen Python 1.2 typed wild postcalibration results agree field by field", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
def _pwild_obj(cls, **attrs):
    obj = object.__new__(cls)
    for key, value in attrs.items():
        object.__setattr__(obj, key, value)
    return obj
_pwild_base = _pwild_obj(
    et.FPCAWildBootstrapProjectionResult,
    target_curve_ids=('curveβ','two','curve-3'),
    bootstrap_projections=np.zeros((4,3)),
    studentized_roots=np.array([
        [.1,.2,.3],[.5,.4,.1],[.9,.6,.7],[.2,.8,.3]]),
    reference_projection=np.array([.3,-.2,.1]),
    reference_se=np.array([.1,.2,.05]),
    confidence_level=.95,
    multiplier='rademacher',
    residual_components=2,
    inference_components=3,
    provenance={
        'study':'source-wild-audit',
        'fpca_wild_bootstrap_projection':{'studentization':'full_fit'}})
_pwild_family = _pwild_obj(
    et.FPCAWildBootstrapFamilyTestResult,
    projection_result=_pwild_base,
    observed_statistics=np.array([.4,.5,.25]),
    max_statistics=np.array([.3,.5,.9,.8]),
    global_statistic=.7,
    reject_targetwise=np.array([False,False,False]),
    reject_familywise=np.array([False,False,False]),
    reject_global=False,significance_level=.05,
    pvalue_correction='plus_one',provenance={'study':'source-wild-audit'})
_pwild_sim = et.fpca_wild_bootstrap_projection_simultaneous_interval(
    _pwild_base,confidence_level=.5)
_pwild_mc = et.fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(
    _pwild_family,confidence_level=.75)
")
  f <- .etr_two_wild_source_fixture()
  native_sim <- etr_fpca_wild_bootstrap_projection_simultaneous_interval(
    f$projection,confidence_level=.5)
  native_mc <- etr_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics(
    f$family,confidence_level=.75)
  source_sim <- reticulate::py_get_attr(reticulate::py,"_pwild_sim")
  source_mc <- reticulate::py_get_attr(reticulate::py,"_pwild_mc")
  for(field in setdiff(names(native_sim),c("projection_result","provenance"))) {
    got <- native_sim[[field]]
    ref <- et_to_r(reticulate::py_get_attr(source_sim,field))
    expect_equal(got,ref,tolerance=2e-12,ignore_attr=TRUE,
      info=paste("simultaneous full source",field))
  }
  for(field in setdiff(names(native_mc),c("family_test_result","provenance"))) {
    got <- native_mc[[field]]
    ref <- et_to_r(reticulate::py_get_attr(source_mc,field))
    expect_equal(got,ref,tolerance=2e-10,ignore_attr=TRUE,
      info=paste("Monte Carlo full source",field))
  }
  expect_equal(native_sim$provenance,
    et_to_r(reticulate::py_get_attr(source_sim,"provenance")),
    ignore_attr=TRUE)
  expect_equal(native_mc$provenance,
    et_to_r(reticulate::py_get_attr(source_mc,"provenance")),
    ignore_attr=TRUE)
  # Frozen constructor/source identity is intentionally not claimed:
  # R S3 records and conditions are not Python dataclasses/exceptions.
  expect_false(any(etr_native_parity_catalog()$one_to_one_native_contract_complete))
})
