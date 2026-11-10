# Additive source-dataframe acceptance for the actual native joint fits.
# Explicit R S3 objects are not Python dataclasses. No source-gap closure.

test_that("public participant BLUP frame accepts real native field layout", {
  fit <- structure(list(
    participant_ids=c("p2","p1"),time=c(0,.5,1),
    dimension="response",
    random_effect_functions=matrix(1:6/10,nrow=2L,byrow=TRUE),
    random_slope_effect_functions=matrix(11:16/10,nrow=2L,byrow=TRUE),
    random_slope_predictor="stimulus"),
    class=c("etr_joint_bspline_mixed_slope","etr_joint_bspline_mixed"))
  intercept <- etr_functional_random_effect_frame(fit)
  expect_identical(names(intercept),c("participant_id","time",
    "dimension","effect","random_slope_predictor","estimate"))
  expect_identical(intercept$participant_id,
    c(rep("p2",3L),rep("p1",3L)))
  expect_equal(intercept$estimate,c(.1,.2,.3,.4,.5,.6))
  expect_true(all(is.na(intercept$random_slope_predictor)))
  slope <- etr_functional_random_effect_frame(fit,"slope")
  expect_equal(slope$estimate,c(1.1,1.2,1.3,1.4,1.5,1.6))
  expect_identical(unique(slope$random_slope_predictor),"stimulus")
  fit$random_slope_effect_functions <- NULL
  expect_error(etr_functional_random_effect_frame(fit,"slope"),
    "random functional slope")
})

test_that("public trial BLUP frame directly accepts native nested source fit", {
  fit <- structure(list(n_curves=2L,time=c(0,.5,1),
    trial_random_effect="functional_intercept",
    curve_ids=c("c2","c1"),
    curve_participant_ids=c("p2","p1"),
    curve_trial_ids=c("T2","T1"),
    trial_ids=c("p2::T2","p1::T1"),
    trial_random_effect_functions=matrix(
      c(.1,.2,.3,.4,.5,.6),nrow=2L,byrow=TRUE)),
    class=c("etr_joint_bspline_mixed_nested_trial",
      "etr_joint_bspline_mixed"))
  frame <- etr_functional_trial_random_effect_frame(fit)
  expect_identical(names(frame),c("curve_index","curve_id",
    "participant_id","source_trial_id","trial_id","time",
    "effect","value"))
  expect_identical(frame$curve_index,c(0L,0L,0L,1L,1L,1L))
  expect_identical(frame$trial_id,
    c(rep("p2::T2",3L),rep("p1::T1",3L)))
  expect_equal(frame$value,c(.1,.2,.3,.4,.5,.6))
  expect_identical(frame,
    etr_nested_source_trial_effect_frame(fit))
  fit$trial_random_effect <- NULL
  expect_error(etr_functional_trial_random_effect_frame(fit),
    "trial functional random intercept")
})

test_that("ordinary source-shaped audit lists still have unchanged dispatch", {
  x <- list(participant_ids=c("p2","p1"),time=c(0,1),
    dimension_name="y",
    random_intercept_functions=matrix(c(.1,.3,.2,.4),2L,
      byrow=TRUE))
  actual <- etr_functional_random_effect_frame(x)
  expect_equal(actual$estimate,c(.1,.3,.2,.4))
  y <- list(source_curve_ids=c("c1","c2"),
    curve_participant_ids=c("p1","p2"),
    curve_trial_ids=c("T1","T2"),
    trial_ids=c("p1::T1","p2::T2"),time=c(0,1),
    trial_random_effect="functional_intercept",
    trial_random_effect_functions=matrix(c(.1,.2,.3,.4),
      nrow=2L,byrow=TRUE))
  expect_equal(etr_functional_trial_random_effect_frame(y)$value,
    c(.1,.2,.3,.4))
})
