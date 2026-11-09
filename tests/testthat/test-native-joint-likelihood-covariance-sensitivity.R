# Source: pinned Python 1.2 covariance sensitivity numerical definitions.
# Actual native nlme joint Gaussian likelihood; no Python parity certification.

test_that("joint mixed sensitivity uses actual REML likelihood and source IC counts",{
  skip_if_not_installed("nlme")
  time<-seq(0,1,length.out=7L)
  ids<-sprintf("curve%02d",seq_len(24L))
  pid<-rep(sprintf("P%02d",seq_len(8L)),each=3L)
  x<-rep(c(-1,0,1),8L)
  values<-array(0,c(24L,7L,1L))
  for(i in seq_len(24L)){
    g<-ceiling(i/3)
    values[i,,1L]<-.7+.23*time+x[i]*(.25-.15*time)+
      .18*sin(g*.6)+.13*cos(g*.31)*time+
      .06*sin(i*.7+time*4)+.035*cos(1.5*i*time)
  }
  trajectories<-etr_trajectory_set(time,values,curve_ids=ids,
    dimension_names="signal",metadata=data.frame(pid=pid),
    coordinate_system="degrees",time_unit="s")
  design<-data.frame(curve_id=rev(ids),x=rev(x))
  fit<-etr_fit_joint_bspline_functional_mixed_effects(
    trajectories,design,"x","pid","signal",
    fixed_basis_size=2L,random_basis_size=2L,
    spline_degree=1L,reml=TRUE)
  z<-etr_functional_mixed_effects_covariance_sensitivity(
    list(reference=fit,replica=fit),reference="reference",max_lag=2L)
  expect_s3_class(z,"etr_joint_likelihood_covariance_sensitivity")
  expect_true(z$information_criterion_available)
  expect_false(z$model_selected)
  expect_false(z$likelihood_ratio_tests_performed)
  expect_false(z$independent_full_source_certified)
  expect_identical(nrow(z$model_summary),2L)
  expect_equal(z$model_summary$log_likelihood,
    rep(as.numeric(stats::logLik(fit$fitted_model)),2L))
  # p=2 coefficient functions, k=2 fixed basis, G=2x2 unstructured,
  # sigma^2=1: four covariance parameters; REML uses only those in IC.
  expect_equal(z$model_summary$n_fixed_parameters,c(4L,4L))
  expect_equal(z$model_summary$n_covariance_parameters,c(4L,4L))
  expect_equal(z$model_summary$information_criterion_parameter_count,
    c(4L,4L))
  expect_equal(z$model_summary$delta_aic,c(0,0),tolerance=1e-12)
  expect_equal(z$model_summary$delta_bic,c(0,0),tolerance=1e-12)
  expect_equal(z$coefficient_summary$sup_abs_difference_from_reference,
    rep(0,4),tolerance=0)
  expect_equal(nrow(z$variance_decomposition),2L*2L*7L)
  expect_equal(nrow(z$residual_diagnostics),2L*2L*3L)
  expect_equal(
    z$variance_decomposition$value[
      z$variance_decomposition$component=="residual_variance"],
    rep(fit$residual_variance,14L),tolerance=1e-12)
})

test_that("joint sensitivity validates source comparability and rejects mixed estimators",{
  skip_if_not_installed("nlme")
  f<-.etr_mixed_sensitivity_fixture()
  fit<-etr_fit_joint_bspline_functional_mixed_effects(
    f$tr,f$design,"x","participant_id","y",
    fixed_basis_size=2L,random_basis_size=2L,
    spline_degree=1L,reml=TRUE)
  run<-function(other)etr_functional_mixed_effects_covariance_sensitivity(
    list(reference=fit,other=other),"reference",2L)
  altered<-fit
  altered$observed_functions[1L,1L]<-
    altered$observed_functions[1L,1L]+.1
  expect_error(run(altered),"identical observed_functions")
  altered<-fit;altered$reml<-FALSE
  expect_error(run(altered),"identical reml")
  altered<-fit;altered$fixed_basis[1L,1L]<-.5
  expect_error(run(altered),"identical fixed_basis")
  moment<-etr_fit_functional_mixed_effects_regression(
    f$tr,f$design,"x","participant_id","y")
  expect_error(run(moment),"cannot combine moments and joint")
  z<-etr_functional_mixed_effects_covariance_sensitivity(
    list(reference=fit),"reference",2L,
    failures=list(rejected="failed convergence"),
    specifications=list(
      reference=list(random_slope_predictor=NULL,
        trial_random_effect=NULL,residual_correlation="iid"),
      rejected=list(random_slope_predictor="x",
        trial_random_effect=NULL,residual_correlation="iid")))
  expect_identical(z$model_summary$status,c("success","failed"))
  expect_true(is.na(z$model_summary$aic[2L]))
  expect_identical(nrow(z$coefficient_frame),2L*length(fit$time))
})
