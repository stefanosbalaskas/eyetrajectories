test_that("candidate-sample diagnostics retain distinct support and risk denominators",{
  frame<-.etr_obs_fixture_frame()
  process<-do.call(etr_observation_process_data,.etr_obs_fixture_input(frame))
  result<-do.call(etr_diagnose_observation_process,c(list(process),.etr_obs_fixture_options()))
  expect_identical(process$n_candidates,17L)
  expect_identical(process$n_observed,7L)
  expect_identical(result$global_summary$risk_candidate_count,6L)
  expect_equal(sum(result$time_summary$candidate_count),6)
  expect_equal(sum(result$support_summary$candidate_count[result$support_summary$scope=="curve"]),17)
  expect_true(any(result$support_summary$no_candidate_support))
  expect_true(any(result$support_summary$zero_observed_support))
  expect_identical(result$curve_summary$longest_missing_run,c(2L,1L,5L))
  expect_equal(result$candidate_frame$previous_observed_x[4L],frame$x[2L])
  expect_equal(result$candidate_frame$time_since_last_observed[4L],2)
  expect_true(is.na(result$candidate_frame$previous_observed_x[7L]))
  expect_equal(result$candidate_frame$x,frame$x)
  expect_identical(etr_observation_process_frame(result,"support"),result$support_summary)
  expect_true(any(result$failures$item=="fixed"))
  expect_false(result$provenance$inverse_probability_weighting_performed)
})

test_that("candidate constructor and risk diagnostics reject unsupported denominators",{
  input<-.etr_obs_fixture_input()
  bad<-input
  bad$frame$time[2L]<-bad$frame$time[1L]
  expect_error(do.call(etr_observation_process_data,bad),"unique within curve/time")
  bad<-input
  bad$frame$observed[2L]<-2
  expect_error(do.call(etr_observation_process_data,bad),"binary")
  bad<-input
  bad$frame$design[3L]<-NA_real_
  expect_error(do.call(etr_observation_process_data,bad),"unavailable")
  bad<-input
  bad$frame$x[3L]<-99
  expect_error(do.call(etr_observation_process_data,bad),"unobserved rows")
  process<-do.call(etr_observation_process_data,input)
  expect_error(etr_diagnose_observation_process(process,predictors="undeclared"),"declared")
  expect_error(etr_diagnose_observation_process(process,time_bins=c(1,3,5)),"cover all")
  expect_error(etr_diagnose_observation_process(process,history_predictors="future_x"),"unknown")
  input$coordinate_columns<-character()
  input$frame$observed<-0L
  process<-do.call(etr_observation_process_data,input)
  expect_error(etr_diagnose_observation_process(process,risk_set="after_observed"),"no candidate rows")
  result<-etr_diagnose_observation_process(process,history_predictors="previous_observed_x")
  expect_true("history_coordinates_unavailable"%in%result$failures$status_code)
  expect_equal(nrow(result$time_summary),0L)
})

test_that("the sparse workflow requires a declared diagnostic and preserves the fitted estimator",{
  trajectories<-.etr_spn_source_fixture()
  process<-do.call(etr_observation_process_data,.etr_obs_fixture_input())
  cfg<-list(backend="native_covariance",dimension="signal",n_components=1L,
    evaluation_grid=seq(.08,.92,length.out=9L),mean_bandwidth=.5,covariance_bandwidth=.85,
    analysis_support_action="restrict",noise_variance_method="fixed",
    measurement_error_variance=.07,psd_action="project")
  baseline<-etr_run_sparse_fpca_workflow(trajectories,cfg)
  expect_error(etr_run_sparse_fpca_workflow(trajectories,cfg,process),"requires explicit")
  cfg$observation_diagnostics<-.etr_obs_fixture_options()
  expect_error(etr_run_sparse_fpca_workflow(trajectories,cfg),"explicit observation_process")
  audited<-etr_run_sparse_fpca_workflow(trajectories,cfg,process)
  expect_identical(audited$fit,baseline$fit)
  expect_identical(audited$steps[[2L]]$name,"observation_process_diagnostics")
  expect_true(audited$decisions$observation_diagnostics_requested$value)
  expect_identical(audited$tables$observation_associations,audited$observation_diagnostics$associations)
})
