# Frozen Python 1.2 workflow source: workflows/_dense_regression.py.
# Developer tests for a bounded native scientific workflow route, not
# all-domain Python result/dataclass or optimizer certification.

.etr_joint_source_workflow_fixture <- function() {
  time <- seq(0,1,length.out=11L)
  nc <- 12L
  values <- array(0,c(nc,length(time),1L))
  design <- data.frame(curve_id=sprintf("c%02d",seq_len(nc)),
    stimulus=rep(c(0,0,1),4L),stringsAsFactors=FALSE)
  for(i in seq_len(nc))
    values[i,,1L] <- 0.2+0.03*i+
      0.12*design$stimulus[i]+0.07*sin(pi*time)+0.001*i*time
  x <- etr_trajectory_set(time,values,design$curve_id,
    "response",metadata=data.frame(
      participant_id=rep(sprintf("P%02d",seq_len(4L)),each=3L),
      trial_id=rep(sprintf("T%02d",seq_len(3L)),4L)),
    coordinate_system="unknown",time_unit="s")
  list(trajectories=x,design=design)
}

.etr_joint_source_cfg <- function(...) {
  utils::modifyList(list(predictors="stimulus",
    participant_column="participant_id",dimension="response",
    estimator="native_joint_bspline_gaussian"),list(...))
}

test_that("native joint workflow routes all four declared covariance families", {
  a <- .etr_joint_source_workflow_fixture()
  c0 <- .etr_joint_workflow_config(.etr_joint_source_cfg(),
    a$trajectories,a$design)
  expect_identical(.etr_joint_workflow_route(c0),
    "etr_fit_joint_bspline_functional_mixed_effects")
  c1 <- .etr_joint_workflow_config(.etr_joint_source_cfg(
    random_slope_predictor="stimulus"),a$trajectories,a$design)
  expect_identical(.etr_joint_workflow_route(c1),
    "etr_fit_joint_bspline_functional_random_slope")
  c2 <- .etr_joint_workflow_config(.etr_joint_source_cfg(
    trial_column="trial_id",trial_random_effect="functional_intercept",
    residual_correlation="ar1"),a$trajectories,a$design)
  expect_identical(.etr_joint_workflow_route(c2),
    "etr_fit_joint_bspline_functional_nested_trial")
  c3 <- .etr_joint_workflow_config(.etr_joint_source_cfg(
    random_slope_predictor="stimulus",trial_column="trial_id",
    trial_random_effect="functional_intercept",
    residual_correlation="exponential"),a$trajectories,a$design)
  expect_identical(.etr_joint_workflow_route(c3),
    "etr_fit_joint_bspline_functional_nested_slope")
  expect_identical(c3$method,"nlme::lme")
  expect_true(isTRUE(c3$reml))
})

test_that("invalid and unimplemented source combinations fail before fitting", {
  a <- .etr_joint_source_workflow_fixture()
  check <- function(x)
    .etr_joint_workflow_config(x,a$trajectories,a$design)
  expect_error(check(.etr_joint_source_cfg(
    residual_correlation="exponential")),"requires.*nested trial")
  expect_error(check(.etr_joint_source_cfg(
    trial_column="trial_id")),"trial_random_effect")
  expect_error(check(.etr_joint_source_cfg(
    trial_random_effect="functional_intercept")),"trial_column")
  expect_error(check(.etr_joint_source_cfg(
    random_slope_predictor="unregistered")),"declared predictor")
  expect_error(check(.etr_joint_source_cfg(
    method="lbfgs")),"Python lbfgs")
  expect_error(check(.etr_joint_source_cfg(
    estimator="native_joint_bspline_gaussian",
    preprocessing=list(list(kind="smooth")))),"empty preprocessing")
  expect_error(check(.etr_joint_source_cfg(
    covariance_ridge=1e-6)),"unsupported fields")
  expect_error(check(.etr_joint_source_cfg(
    trial_column="trial_id",trial_random_effect="functional_intercept",
    trial_random_basis_size=3L)),"trial_random_basis_size")
  expect_error(check(.etr_joint_source_cfg(
    fixed_basis_size=2L)),"basis sizes")
  expect_error(check(.etr_joint_source_cfg(
    reml=NA)),"reml")
  expect_error(check(.etr_joint_source_cfg(
    maxiter=5L)),"maxiter")
})

test_that("opt-in branch does not replace the old moments workflow", {
  a <- .etr_joint_source_workflow_fixture()
  old <- list(predictors="stimulus",participant_column="participant_id",
    dimension="response",estimator="two_level_functional_method_of_moments")
  r <- etr_run_functional_mixed_effects_workflow(
    a$trajectories,a$design,old)
  expect_identical(r$workflow_contract,
    "functional_mixed_effects:native_moments_only")
  expect_identical(r$provenance$source_python_equivalent,FALSE)
  expect_error(etr_run_functional_mixed_effects_workflow(
    a$trajectories,a$design,utils::modifyList(old,list(
      estimator="Python_MixedLM"))),"not implemented")
  expect_error(etr_run_functional_mixed_effects_workflow(
    a$trajectories,a$design,utils::modifyList(old,list(reml=TRUE))),
    "unsupported fields")
})

test_that("source-shaped pointwise coefficient frame keeps Python row ordering", {
  x <- list(time=c(0,0.5,1),
    fixed_coefficient_functions=matrix(c(1,2,3,4,5,6),
      nrow=2L,byrow=TRUE,
      dimnames=list(c("(Intercept)","stimulus"),NULL)),
    fixed_standard_errors=matrix(rep(.1,6),nrow=2L))
  class(x) <- "etr_joint_bspline_mixed"
  tab <- .etr_joint_workflow_coefficient_frame(x,"response")
  expect_identical(names(tab),c("coefficient","time","dimension",
    "estimate","standard_error","lower_95_wald","upper_95_wald"))
  expect_identical(as.character(tab$coefficient),
    rep(c("(Intercept)","stimulus"),each=3L))
  expect_equal(tab$time,rep(c(0,.5,1),2L))
  expect_equal(tab$estimate,c(1,2,3,4,5,6))
  expect_equal(tab$lower_95_wald,tab$estimate-
    stats::qnorm(.975)*tab$standard_error,tolerance=1e-12)
})

# Deterministic, previously exercised Batch 35 likelihood fixture.
# Eight participants meet the native random-basis identifiability guard.
.etr_joint_workflow_live_fixture <- function() {
  time <- seq(0,1,length.out=7L)
  nc <- 24L
  ids <- sprintf("c%02d",seq_len(nc))
  groups <- rep(sprintf("P%02d",seq_len(8L)),each=3L)
  stim <- rep(c(-1,0,1),8L)
  values <- array(0,c(nc,7L,1L))
  for(g in seq_len(8L))for(j in seq_len(3L)){
    i <- (g-1L)*3L+j
    values[i,,1L] <- .7+.2*time+stim[i]*(.5-.15*time)+
      .6*sin(1.1*g)+.3*cos(2*g)*time+
      .07*sin(.7*(g*3+j)*(time+.3))+
      .035*cos((g+j)*time)
  }
  trajectories <- etr_trajectory_set(time,values,ids,
    "gaze_x",metadata=data.frame(participant_id=groups),
    coordinate_system="degrees",time_unit="s")
  design <- data.frame(curve_id=rev(ids),
    stimulus=rev(stim),stringsAsFactors=FALSE)
  list(trajectories=trajectories,design=design)
}

test_that("native likelihood workflow executes actual IID nlme fit", {
  if(!identical(Sys.getenv("ET_RUN_NATIVE_JOINT_WORKFLOW_INTEGRATION"),
      "true"))
    skip("opt-in integration requires nlme and the deterministic Batch35 fit")
  skip_if_not_installed("nlme")
  a <- .etr_joint_workflow_live_fixture()
  result <- etr_run_functional_mixed_effects_workflow(
    a$trajectories,a$design,
    .etr_joint_source_cfg(
      dimension="gaze_x",
      fixed_basis_size=2L,random_basis_size=2L,
      spline_degree=1L,reml=TRUE,maxiter=500L))
  expect_s3_class(result,"etr_functional_mixed_effects_workflow")
  expect_s3_class(result$fit,"etr_joint_bspline_mixed")
  expect_identical(result$fit$backend,"nlme::lme")
  expect_identical(result$fit$n_participants,8L)
  expect_identical(result$fit$n_curves,24L)
  expect_identical(result$workflow_contract,
    "functional_mixed_effects:native_joint_bspline_gaussian")
  expect_true(result$provenance$likelihood_optimized)
  expect_true(result$provenance$REML)
  expect_false(result$provenance$source_python_equivalent)
  expect_false(result$provenance$full_source_contract_certified)
  expect_identical(result$steps[[1L]][["function"]],
    "etr_fit_joint_bspline_functional_mixed_effects")
  expect_true(is.data.frame(result$tables$coefficients))
  expect_identical(nrow(result$tables$coefficients),14L)
  expect_identical(names(result$tables$coefficients),
    c("coefficient","time","dimension","estimate",
      "standard_error","lower_95_wald","upper_95_wald"))
  expect_lt(max(abs(result$fit$fitted_functions+
    result$fit$residual_functions-result$fit$observed_functions)),1e-8)
  expect_gt(result$fit$residual_variance,0)
})
