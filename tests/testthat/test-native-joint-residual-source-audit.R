# Frozen source: eyetrajectoriespy 1.2.0
# functional_mixed_effects_diagnostics.py @
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Tests target mathematical/scientific behavior and explicit source boundaries;
# they are not independent full-domain Python source certification.

.etr_joint_source_residual_test_fit <- function(serial=FALSE) {
  time <- c(0,.2,.7,1.5,2.2)
  residual <- rbind(
    c(1,2,0,3,1),
    c(.3,.1,.4,-.2,.5),
    rep(2,5))
  rho <- .35
  corr <- if(serial)outer(seq_len(5),seq_len(5),
    function(a,b)rho^abs(a-b)) else diag(5)
  x <- list(backend="nlme::lme",
    time=time,time_unit="s",dimension_name="gaze_x",
    source_curve_ids=c("c3","c1","c2"),
    curve_participant_ids=c("p2","p1","p2"),
    residual_functions=residual,
    residual_variance=.25,
    residual_correlation_matrix=corr)
  class(x) <- c(if(serial)"etr_joint_bspline_mixed_nested_trial"
    else "etr_joint_bspline_mixed","etr_joint_bspline_mixed")
  x
}

test_that("native joint source whitening matches independent triangular solve", {
  for(serial in c(FALSE,TRUE)) {
    fit <- .etr_joint_source_residual_test_fit(serial)
    raw <- fit$residual_functions
    V <- fit$residual_variance*fit$residual_correlation_matrix
    expected <- base::t(forwardsolve(base::t(chol(V)),base::t(raw)))
    actual <- etr_functional_mixed_effects_whitened_residuals(fit)
    expect_equal(unname(actual),unname(expected),tolerance=1e-12)
    if(!serial)
      expect_equal(unname(actual),unname(raw/.5),tolerance=1e-12)
  }
})

test_that("joint trial lag diagnostics match direct raw finite means", {
  fit <- .etr_joint_source_residual_test_fit(TRUE)
  result <- etr_functional_mixed_effects_residual_diagnostics(
    fit,max_lag=2L,residual_scale="raw")
  expect_s3_class(result,"etr_functional_mixed_residual_diagnostics")
  expect_identical(result$reference$time,fit$time)
  expect_identical(result$reference$time_unit,"s")
  expect_identical(result$provenance$residual_model,
    "native_joint_nlme_likelihood_not_python_optimizer")
  trial <- result$trial_diagnostics
  expect_identical(nrow(trial),9L)
  first <- trial[trial$curve_id=="c3" & trial$lag_index==1L,,drop=FALSE]
  r <- fit$residual_functions[1L,]
  z <- r-mean(r)
  expected_acov <- mean(z[1:4]*z[2:5])
  expect_equal(first$autocovariance,expected_acov,tolerance=1e-12)
  expect_equal(first$autocorrelation,
    expected_acov/mean(z^2),tolerance=1e-12)
  expect_equal(first$semivariance,
    .5*mean((r[2:5]-r[1:4])^2),tolerance=1e-12)
  expect_equal(first$lag_time_mean,mean(diff(fit$time)))
  expect_equal(first$lag_time_min,min(diff(fit$time)))
  expect_equal(first$lag_time_max,max(diff(fit$time)))
  expect_identical(trial$zero_residual_variance[7L],TRUE)
  expect_true(is.nan(trial$autocorrelation[8L]))
  expect_identical(nrow(result$participant_diagnostics),6L)
  expect_identical(nrow(result$overall_diagnostics),3L)
  expect_equal(etr_functional_mixed_effects_residual_diagnostic_frame(
    result,"overall")$n_pairs,c(15L,12L,9L))
})

test_that("source residual pair frame keeps irregular observed lag offsets", {
  fit <- .etr_joint_source_residual_test_fit(TRUE)
  diagnostics <- etr_functional_mixed_effects_residual_diagnostics(
    fit,max_lag=2L,residual_scale="whitened")
  pairs <- etr_functional_mixed_effects_residual_pair_frame(
    diagnostics,lag_index=1L,curve_id="c3")
  expect_identical(nrow(pairs),4L)
  expect_identical(pairs$start_index,0:3)
  expect_identical(pairs$end_index,1:4)
  expect_equal(pairs$physical_lag,diff(fit$time))
  expected <- etr_functional_mixed_effects_whitened_residuals(fit)
  expect_equal(pairs$residual_start,expected[1L,1:4])
  expect_equal(pairs$residual_end,expected[1L,2:5])
  expect_equal(pairs$semivariance_contribution,
    .5*(pairs$residual_end-pairs$residual_start)^2)
  expect_error(etr_functional_mixed_effects_residual_pair_frame(
    diagnostics,1L,curve_id="unknown"),"Unknown curve_id")
})

test_that("residual model comparisons enforce matched source IDs and time", {
  a <- .etr_joint_source_residual_test_fit(FALSE)
  b <- .etr_joint_source_residual_test_fit(TRUE)
  b$residual_functions <- b$residual_functions+.02
  x <- etr_compare_functional_mixed_effects_residual_diagnostics(
    a,b,max_lag=2L,reference_label="iid",comparison_label="ar1")
  expect_identical(nrow(x),3L)
  expect_identical(names(x)[1:3],
    c("reference_label","comparison_label","residual_scale"))
  expect_true(all(x$reference_label=="iid"))
  expect_true(all(x$comparison_label=="ar1"))
  expect_true(all(x$delta_autocovariance==x$autocovariance_comparison-
    x$autocovariance_reference))
  c <- b;c$time[2L] <- .25
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    a,c,max_lag=1L),"same observed time grid")
  c <- b;c$source_curve_ids[1L] <- "different"
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    a,c,max_lag=1L),"same source curves")
  c <- b;c$dimension_name <- "pressure"
  expect_error(etr_compare_functional_mixed_effects_residual_diagnostics(
    a,c,max_lag=1L),"response dimension")
})

test_that("malformed joint source records fail closed without model fallback", {
  fit <- .etr_joint_source_residual_test_fit()
  fit$residual_correlation_matrix <- matrix(1,4L,4L)
  expect_error(etr_functional_mixed_effects_whitened_residuals(fit),
    "correlation matrix")
  fit <- .etr_joint_source_residual_test_fit()
  fit$residual_variance <- 0
  expect_error(etr_functional_mixed_effects_residual_diagnostics(
    fit,1L),"positive")
  fit <- .etr_joint_source_residual_test_fit()
  fit$time_unit <- NULL
  expect_error(etr_functional_mixed_effects_residual_diagnostics(
    fit,1L),"time unit")
  fit <- .etr_joint_source_residual_test_fit()
  fit$residual_functions[1L,1L] <- Inf
  expect_error(etr_functional_mixed_effects_whitened_residuals(fit),
    "finite")
  fit <- .etr_joint_source_residual_test_fit()
  fit$backend <- "statsmodels"
  expect_error(etr_functional_mixed_effects_whitened_residuals(fit),
    "actual native nlme")
})

test_that("real native Gaussian fit supplies time metadata and residual diagnostics",{
  if(!identical(Sys.getenv("ET_RUN_NATIVE_JOINT_WORKFLOW_INTEGRATION"),
      "true"))
    skip("live likelihood integration is explicitly opt-in")
  skip_if_not_installed("nlme")
  tt <- seq(0,1,length.out=7L)
  ids <- sprintf("c%02d",seq_len(24L))
  group <- rep(sprintf("P%02d",1:8),each=3L)
  cue <- rep(c(-1,0,1),8L)
  y <- array(0,c(24L,7L,1L))
  for(g in seq_len(8L))for(j in seq_len(3L)){
    i <- (g-1L)*3L+j
    y[i,,1L] <- .7+.2*tt+cue[i]*(.5-.15*tt)+
      .6*sin(1.1*g)+.3*cos(2*g)*tt+
      .07*sin(.7*(g*3+j)*(tt+.3))+
      .035*cos((g+j)*tt)
  }
  trajectories <- etr_trajectory_set(tt,y,
    curve_ids=ids,dimension_names="gaze_x",
    metadata=data.frame(participant_id=group),
    coordinate_system="degrees",time_unit="s")
  design <- data.frame(curve_id=rev(ids),cue=rev(cue))
  fit <- etr_fit_joint_bspline_functional_mixed_effects(
    trajectories,design,predictors="cue",
    participant_column="participant_id",dimension="gaze_x",
    fixed_basis_size=2L,random_basis_size=2L,spline_degree=1L)
  expect_identical(fit$time_unit,"s")
  expect_identical(fit$source_curve_ids,fit$curve_ids)
  expected <- fit$residual_functions/sqrt(fit$residual_variance)
  expect_equal(unname(etr_functional_mixed_effects_whitened_residuals(fit)),
    unname(expected),tolerance=1e-10)
  diagnostics <- etr_functional_mixed_effects_residual_diagnostics(
    fit,2L)
  expect_identical(nrow(diagnostics$trial_diagnostics),24L*3L)
  expect_true(all(is.finite(diagnostics$trial_diagnostics$autocovariance)))
  pairs <- etr_functional_mixed_effects_residual_pair_frame(
    diagnostics,1L,curve_id=fit$curve_ids[1L])
  expect_identical(nrow(pairs),6L)
})
