# Frozen source: eyetrajectoriespy 1.2.0 functional mixed-effects
# variance decomposition / coefficient frame. Native estimator and typed
# result parity remain open. These tests certify deterministic arithmetic,
# not the Python full numerical optimization contract.

.etr_joint_variance_fixture <- function(slope=FALSE,trial=FALSE) {
  B <- rbind(c(1,0),c(.5,.5),c(0,1))
  G0 <- matrix(c(1.5,.1,.1,.9),nrow=2L)
  Gs <- matrix(c(.6,.05,.05,.4),nrow=2L)
  cross <- matrix(c(.12,-.03,.04,.08),nrow=2L,byrow=TRUE)
  G <- if(slope)rbind(cbind(G0,cross),cbind(t(cross),Gs)) else G0
  x <- list(time=c(0,.5,1),dimension="response",
    random_basis=B,random_effect_covariance=G,
    residual_variance=.25,
    fixed_coefficient_functions=matrix(c(.1,.2,.3,.4,.5,.6),
      nrow=2L,byrow=TRUE,
      dimnames=list(c("Intercept","stimulus"),NULL)),
    fixed_standard_errors=matrix(c(.1,.1,.2,.1,.2,.2),
      nrow=2L,byrow=TRUE))
  classes <- c("etr_joint_bspline_mixed")
  if(slope){
    x$random_slope_predictor <- "stimulus"
    classes <- c("etr_joint_bspline_mixed_slope",classes)
  }
  if(trial){
    x$trial_random_effect <- "functional_intercept"
    x$trial_random_basis <- B
    x$trial_random_effect_covariance <-
      matrix(c(.8,.05,.05,.3),nrow=2L)
    classes <- c(if(slope)"etr_joint_bspline_mixed_nested_slope"
      else "etr_joint_bspline_mixed_nested_trial",classes)
  }
  class(x) <- classes
  x
}

.etr_joint_expected_quadratic <- function(B,G)
  rowSums((B%*%G)*B)

test_that("public decomposition supports participant-only native likelihood fit",{
  x <- .etr_joint_variance_fixture()
  d <- etr_functional_mixed_effects_variance_decomposition(
    x,model_label="intercept")
  expect_identical(names(d),c("model","component",
    "component_type","time","value"))
  expect_identical(unique(d$component),
    c("participant_intercept_variance","residual_variance"))
  expect_equal(nrow(d),6L)
  expect_identical(unique(d$model),"intercept")
  expect_equal(d$value[seq_len(3L)],
    .etr_joint_expected_quadratic(x$random_basis,
      x$random_effect_covariance),tolerance=1e-12)
  expect_equal(tail(d$value,3L),rep(.25,3L))
  expect_true(all(d$component_type=="variance"))
})

test_that("public source decomposition preserves slope cross-covariance",{
  x <- .etr_joint_variance_fixture(slope=TRUE)
  d <- etr_functional_mixed_effects_variance_decomposition(x)
  expect_identical(unique(d$component),
    c("participant_intercept_variance",
      "participant_slope_variance",
      "participant_intercept_slope_cross_covariance",
      "residual_variance"))
  expect_equal(nrow(d),12L)
  G <- x$random_effect_covariance
  B <- x$random_basis
  expect_equal(d$value[1:3],
    .etr_joint_expected_quadratic(B,G[1:2,1:2]),tolerance=1e-12)
  expect_equal(d$value[4:6],
    .etr_joint_expected_quadratic(B,G[3:4,3:4]),tolerance=1e-12)
  expect_equal(d$value[7:9],
    .etr_joint_expected_quadratic(B,G[1:2,3:4]),tolerance=1e-12)
  expect_true(all(d$component_type[7:9]=="covariance"))
  expect_equal(d$value[10:12],rep(.25,3L))
})

test_that("nested trial and slope plus trial include trial covariance",{
  for(slope in c(FALSE,TRUE)){
    x <- .etr_joint_variance_fixture(slope=slope,trial=TRUE)
    d <- etr_functional_mixed_effects_variance_decomposition(x)
    names <- unique(d$component)
    expect_true("trial_variance"%in%names)
    expect_equal(tail(d$value,3L),rep(.25,3L))
    trial <- d[d$component=="trial_variance",,drop=FALSE]
    expect_equal(trial$value,
      .etr_joint_expected_quadratic(x$trial_random_basis,
        x$trial_random_effect_covariance),tolerance=1e-12)
    expect_true(all(trial$component_type=="variance"))
    if(slope)expect_equal(nrow(d),15L)
    else expect_equal(nrow(d),9L)
  }
})

test_that("source coefficient frame accepts native joint fits directly",{
  for(slope in c(FALSE,TRUE)){
    x <- .etr_joint_variance_fixture(slope=slope)
    tab <- etr_functional_mixed_effects_coefficient_frame(x)
    expect_identical(names(tab),c("coefficient","time",
      "dimension","estimate","standard_error",
      "lower_95_wald","upper_95_wald"))
    expect_identical(as.character(tab$coefficient),
      rep(c("Intercept","stimulus"),each=3L))
    expect_equal(tab$estimate,c(.1,.2,.3,.4,.5,.6))
    expect_equal(tab$time,rep(c(0,.5,1),2L))
    expect_equal(tab$lower_95_wald,
      tab$estimate-1.959963984540054*tab$standard_error,
      tolerance=1e-12)
    expect_error(etr_functional_mixed_effects_coefficient_frame(
      x,band=list()),"not verified")
  }
})

test_that("native joint covariance adaptation rejects malformed dimensions",{
  x <- .etr_joint_variance_fixture()
  x$random_effect_covariance <- matrix(1,3L,3L)
  expect_error(etr_functional_mixed_effects_variance_decomposition(x),
    "covariance")
  x <- .etr_joint_variance_fixture(slope=TRUE,trial=TRUE)
  x$trial_random_effect_covariance <- diag(3L)
  expect_error(etr_functional_mixed_effects_variance_decomposition(x),
    "trial covariance")
  x <- .etr_joint_variance_fixture()
  x$residual_variance <- -1
  expect_error(etr_functional_mixed_effects_variance_decomposition(x),
    "residual variance")
  x <- .etr_joint_variance_fixture()
  x$random_basis[2L,1L] <- Inf
  expect_error(etr_functional_mixed_effects_variance_decomposition(x),
    "basis")
})

test_that("live B-spline fit can feed both public source numerical frames",{
  if(!identical(Sys.getenv("ET_RUN_NATIVE_JOINT_WORKFLOW_INTEGRATION"),
      "true"))
    skip("opt-in nlme live fit uses the prior qualified Batch35 fixture")
  skip_if_not_installed("nlme")
  tt <- seq(0,1,length.out=7L)
  ids <- sprintf("c%02d",seq_len(24L))
  groups <- rep(sprintf("P%02d",1:8),each=3L)
  stimulus <- rep(c(-1,0,1),8L)
  a <- array(0,c(24L,7L,1L))
  for(i in seq_len(8L))for(j in seq_len(3L)){
    ci <- (i-1L)*3L+j
    a[ci,,1L] <- .7+.2*tt+stimulus[ci]*(.5-.15*tt)+
      .6*sin(1.1*i)+.3*cos(2*i)*tt+
      .07*sin(.7*(i*3+j)*(tt+.3))+
      .035*cos((i+j)*tt)
  }
  trajectories <- etr_trajectory_set(tt,a,
    curve_ids=ids,dimension_names="gaze_x",
    metadata=data.frame(participant_id=groups),
    coordinate_system="degrees",time_unit="s")
  design <- data.frame(curve_id=rev(ids),stimulus=rev(stimulus))
  workflow <- etr_run_functional_mixed_effects_workflow(
    trajectories,design,list(predictors="stimulus",
      participant_column="participant_id",dimension="gaze_x",
      estimator="native_joint_bspline_gaussian",
      fixed_basis_size=2L,random_basis_size=2L,
      spline_degree=1L,reml=TRUE))
  fit <- workflow$fit
  d <- etr_functional_mixed_effects_variance_decomposition(fit)
  c <- etr_functional_mixed_effects_coefficient_frame(fit)
  expect_equal(nrow(d),2L*length(tt))
  expect_equal(nrow(c),2L*length(tt))
  expect_equal(c$estimate,workflow$tables$coefficients$estimate,
    tolerance=1e-12)
  expect_true(all(is.finite(d$value)))
  expect_true(all(d$value>=0))
})
