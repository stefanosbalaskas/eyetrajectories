# Frozen eyetrajectoriespy 1.2.0 regression_inference.py source scientific
# prediction interval and typed FPCARegressionUncertaintyResult.
# Source commit c1cd95ad718327550f7e55393ff38582872f7a94.
# All Python oracle calculations are opt-in; native R numerical paths do
# not import Python or rely on a Python package at package runtime.

.etr_future_source_fixture <- function() {
  n <- 14L
  time <- seq(0,1,length.out=15L)
  x <- array(0,c(n,length(time),1L))
  for(i in seq_len(n)) {
    x[i,,1L] <- sin(pi*time)*(1+i/16) +
      .16*cos(2*pi*time)*(i%%4L)/3+time*i/18
  }
  outcome <- .2 + 1.2*seq_len(n)/n + .2*sin(seq_len(n))
  trajectories <- etr_trajectory_set(time,x,
    sprintf("c%02d",seq_len(n)),"gaze",
    metadata=data.frame(
      subject=rep(sprintf("p%02d",seq_len(7L)),each=2L)),
    coordinate_system="normalized",time_unit="s")
  list(x=trajectories,y=outcome)
}

test_that("source future intervals compose with actual native paired FPCR uncertainty",{
  fixture <- .etr_future_source_fixture()
  for(unit in c("curve","participant")){
    label <- if(unit=="participant")"subject" else NULL
    uncertainty <- etr_bootstrap_fpca_regression_uncertainty(
      fixture$x,fixture$y,n_bootstrap=20L,n_components=1L,
      resample_unit=unit,participant_column=label,random_state=41L,
      python_boundary_mode=TRUE)
    result <- etr_fpca_regression_future_prediction_interval(
      uncertainty,fixture$y,confidence_level=.9,random_state=121L,
      python_boundary_mode=TRUE)
    expect_s3_class(result,"etr_fpcr_future_prediction_interval")
    expect_identical(names(result),c(
      "regression_uncertainty","centered_residuals",
      "sampled_residuals","predictive_draws","lower","median",
      "upper","predictive_se","confidence_level",
      "residual_method","random_state","provenance"))
    expect_identical(result$regression_uncertainty,uncertainty)
    expect_identical(dim(result$sampled_residuals),c(20L,14L))
    expect_identical(dim(result$predictive_draws),c(20L,14L))
    expect_equal(result$predictive_draws,
      uncertainty$bootstrap_mean_predictions+result$sampled_residuals,
      tolerance=1e-12)
    expect_equal(result$centered_residuals,
      fixture$y-uncertainty$reference_regression$predictions-
        mean(fixture$y-uncertainty$reference_regression$predictions),
      tolerance=1e-13)
    expect_equal(mean(result$centered_residuals),0,tolerance=1e-12)
    expect_equal(result$lower,as.numeric(apply(result$predictive_draws,
      2L,stats::quantile,probs=.05,names=FALSE,type=7L)),tolerance=1e-12)
    expect_equal(result$median,as.numeric(apply(result$predictive_draws,
      2L,stats::quantile,probs=.5,names=FALSE,type=7L)),tolerance=1e-12)
    expect_equal(result$upper,as.numeric(apply(result$predictive_draws,
      2L,stats::quantile,probs=.95,names=FALSE,type=7L)),tolerance=1e-12)
    expect_equal(result$predictive_se,as.numeric(apply(
      result$predictive_draws,2L,stats::sd)),tolerance=1e-12)
    source_prov <- result$provenance$
      fpca_regression_future_prediction_interval
    expect_identical(names(source_prov),c(
      "method","family","confidence_level","residual_method",
      "residual_source","residuals_centered","residual_rng_stream",
      "residual_exchangeability_assumed","heteroscedasticity_robust",
      "future_outcome_prediction_interval","marginal_per_target",
      "simultaneous_across_targets","joint_target_distribution_claimed",
      "bootstrap_mean_predictions_reused","n_bootstrap",
      "n_training_residuals","target_source","random_state"))
    expect_true(source_prov$residual_exchangeability_assumed)
    expect_true(source_prov$future_outcome_prediction_interval)
    expect_false(source_prov$heteroscedasticity_robust)
    expect_false(source_prov$simultaneous_across_targets)
    expect_identical(source_prov$residual_rng_stream,
      "spawned_domain_separated_stream")
    expect_null(result$native_rng_source)
    repeated<-etr_fpca_regression_future_prediction_interval(
      uncertainty,fixture$y,confidence_level=.9,random_state=121L,
      python_boundary_mode=TRUE)
    expect_identical(result$sampled_residuals,repeated$sampled_residuals)
    expect_identical(result$predictive_draws,repeated$predictive_draws)
    expect_identical(length(result$lower),14L)
    expect_true(all(is.finite(result$predictive_se)))
  }
})

test_that("source-only input class and RNG boundary fail closed",{
  fixture<-.etr_future_source_fixture()
  native<-etr_bootstrap_fpca_regression_uncertainty(
    fixture$x,fixture$y,n_bootstrap=20L,n_components=1L,
    random_state=41L,python_boundary_mode=TRUE)
  expect_error(etr_fpca_regression_future_prediction_interval(
    unclass(native),fixture$y,python_boundary_mode=TRUE),
    "FPCARegressionUncertaintyResult analogue")
  expect_error(etr_fpca_regression_future_prediction_interval(
    native,fixture$y,python_boundary_mode=TRUE,
    residual_indices=matrix(0L,20L,14L)),
    "fixed residual_indices")
  expect_error(etr_fpca_regression_future_prediction_interval(
    native,fixture$y,python_boundary_mode=TRUE,random_engine="base_R"),
    "NumPy SeedSequence")
  expect_error(etr_fpca_regression_future_prediction_interval(
    native,fixture$y,python_boundary_mode=1),"python_boundary_mode")
  expect_error(etr_fpca_regression_future_prediction_interval(
    native,fixture$y,confidence_level=1,python_boundary_mode=TRUE),
    "confidence_level")
  expect_error(etr_fpca_regression_future_prediction_interval(
    native,fixture$y,residual_method="wild",python_boundary_mode=TRUE),
    "residual_method")
  expect_error(etr_fpca_regression_future_prediction_interval(
    native,fixture$y[-1L],python_boundary_mode=TRUE),
    "one value per training trajectory")
  bad<-native
  bad$reference_regression$family<-"binomial"
  expect_error(etr_fpca_regression_future_prediction_interval(
    bad,fixture$y,python_boundary_mode=TRUE),"Gaussian FPCR")
})

test_that("real frozen Python paired FPCR refit yields identical spawned predictive draws",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 FPCR future-outcome direct source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  fixture<-.etr_future_source_fixture()
  py_x<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=fixture$x$time,values=fixture$x$values,
    curve_ids=do.call(reticulate::tuple,as.list(fixture$x$curve_ids)),
    dimension_names=reticulate::tuple("gaze"),metadata=fixture$x$metadata,
    coordinate_system=fixture$x$coordinate_system,
    time_unit=fixture$x$time_unit)
  for(unit in c("curve","participant")){
    group<-if(unit=="participant")"subject"else NULL
    native_input<-etr_bootstrap_fpca_regression_uncertainty(
      fixture$x,fixture$y,n_bootstrap=20L,n_components=1L,
      random_state=41L,resample_unit=unit,participant_column=group,
      python_boundary_mode=TRUE)
    py_input<-reticulate::py_call(
      etpy_get_export("bootstrap_fpca_regression_uncertainty"),
      trajectories=py_x,outcome=fixture$y,n_bootstrap=20L,
      n_components=1L,random_state=41L,resample_unit=unit,
      participant_column=group)
    expect_equal(native_input$bootstrap_mean_predictions,
      et_to_r(reticulate::py_get_attr(py_input,"bootstrap_mean_predictions")),
      tolerance=1e-6,ignore_attr=TRUE)
    for(seed in c(0L,121L)){
      actual<-etr_fpca_regression_future_prediction_interval(
        native_input,fixture$y,confidence_level=.9,
        random_state=seed,python_boundary_mode=TRUE)
      oracle<-reticulate::py_call(
        etpy_get_export("fpca_regression_future_prediction_interval"),
        result=py_input,outcome=fixture$y,confidence_level=.9,
        random_state=seed)
      for(field in c("centered_residuals","sampled_residuals",
                     "predictive_draws","lower","median","upper",
                     "predictive_se")){
        expect_equal(actual[[field]],
          et_to_r(reticulate::py_get_attr(oracle,field)),
          tolerance=1e-6,ignore_attr=TRUE,
          info=paste("Python source future intervals",unit,seed,field))
      }
      src_prov<-et_to_r(reticulate::py_get_attr(oracle,"provenance"))
      expect_identical(names(actual$provenance),names(src_prov))
      rprov<-actual$provenance$
        fpca_regression_future_prediction_interval
      pprov<-src_prov$fpca_regression_future_prediction_interval
      expect_identical(names(rprov),names(pprov))
      for(field in names(pprov))
        expect_equal(rprov[[field]],pprov[[field]],
          tolerance=1e-12,ignore_attr=TRUE,
          info=paste("future provenance",unit,seed,field))
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
