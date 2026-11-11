# Frozen Python 1.2 generalized_function_on_scalar.py and
# workflows/_dense_regression.py, commit:
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Native R source-scientific model is not a fake statsmodels object.

.etr_gee_strict_fields<-c(
  "coefficient_functions","coefficient_standard_errors",
  "basis_coefficients","parameter_covariance","basis","basis_knots",
  "linear_predictor_functions","mean_functions","observed_functions",
  "scalar_design_matrix","expanded_design_rank","coefficient_names",
  "predictor_names","participant_column","participant_ids",
  "curve_participant_ids","curves_per_participant","source_curve_ids",
  "time","dimension_name","coordinate_system","time_unit","family",
  "link","basis_size","spline_degree","working_correlation",
  "covariance_type","scale","maxiter","ctol","converged",
  "backend_warnings","exposure","log_exposure","rate_functions",
  "linear_predictor_rate","linear_predictor_count","exposure_units",
  "exposure_expanded_from_curve","binomial_successes",
  "binomial_denominators","binomial_observed_proportions",
  "binomial_expected_successes",
  "binomial_denominator_expanded_from_curve","provenance","model")
.etr_gee_strict_provenance<-c(
  "method","backend","family","link","response_dimension",
  "participant_column","n_participants","n_source_curves",
  "n_grid_observations","coefficient_names","predictors",
  "design_alignment","coefficient_basis","basis_size","spline_degree",
  "basis_size_selected_automatically","smoothing_penalty",
  "working_correlation","working_correlation_selected_automatically",
  "covariance_type","independent_cluster",
  "trial_varying_predictors_supported","random_effects",
  "conditional_effect_interpretation",
  "marginal_population_averaged_interpretation",
  "categorical_encoding","predictor_centering","predictor_scaling",
  "interaction_construction","automatic_family_selection",
  "automatic_link_selection","automatic_model_selection",
  "cluster_count_guard","expanded_coefficient_parameter_count",
  "cluster_count_guard_is_adequacy_theorem",
  "grouped_binomial_success_denominator_supported",
  "grouped_binomial_supplied",
  "grouped_binomial_response_representation",
  "grouped_binomial_backend_representation",
  "binomial_denominator_shape",
  "binomial_denominator_expanded_from_curve",
  "binomial_denominator_inferred",
  "binomial_denominator_observed_and_fixed",
  "binomial_denominator_measurement_uncertainty",
  "generic_proportion_input_supported","generic_offset_supported",
  "poisson_exposure_supported","exposure_supplied","exposure_shape",
  "exposure_units","exposure_expanded_from_curve",
  "exposure_inferred_from_time_grid",
  "exposure_inferred_from_trial_duration",
  "exposure_inferred_from_metadata",
  "exposure_observed_and_fixed","exposure_measurement_uncertainty",
  "converged","backend_warnings")

.etr_gee_strict_case<-function(family="poisson",grouped=FALSE,exposed=FALSE){
  f<-.etr_native_gee_fixture(family,grouped)
  d<-f$design[match(f$x$curve_ids,f$design$curve_id),,drop=FALSE]
  exposure<-if(exposed)rep(1.6,nrow(d)) else NULL
  config<-list(predictors="treatment",participant_column="participant_id",
    dimension="outcome",family=family,
    basis_size=4L,spline_degree=3L,
    binomial_denominator=f$den,exposure=exposure,
    exposure_units=if(exposed)"person-hours" else NULL)
  args<-c(list(trajectories=f$x,design=d),
    config[c("predictors","participant_column","dimension","family",
      "binomial_denominator","exposure","exposure_units",
      "basis_size","spline_degree")])
  list(x=f$x,d=d,config=config,args=args)
}

test_that("strict native GEE source record has 47 scientific fields and 58 honest provenance keys",{
  for(spec in list(
    list(family="poisson",grouped=FALSE,exposed=FALSE),
    list(family="poisson",grouped=FALSE,exposed=TRUE),
    list(family="binomial",grouped=TRUE,exposed=FALSE),
    list(family="binomial",grouped=FALSE,exposed=FALSE))){
    f<-do.call(.etr_gee_strict_case,spec)
    strict<-do.call(etr_fit_generalized_function_on_scalar_regression,
      c(f$args,list(python_boundary_mode=TRUE,
        strict_source_record=TRUE)))
    expect_s3_class(strict,"etr_generalized_function_on_scalar")
    expect_identical(names(strict),.etr_gee_strict_fields)
    expect_identical(names(strict$provenance),
      "generalized_function_on_scalar_regression")
    p<-strict$provenance$generalized_function_on_scalar_regression
    expect_identical(names(p),.etr_gee_strict_provenance)
    expect_identical(length(p),58L)
    expect_identical(p$backend,"native_R_source_score_GEE")
    expect_true(p$converged)
    expect_false(p$automatic_model_selection)
    expect_identical(p$expanded_coefficient_parameter_count,8L)
    expect_identical(p$n_participants,12L)
    expect_identical(p$n_source_curves,36L)
    expect_identical(p$n_grid_observations,252L)
    expect_identical(p$grouped_binomial_supplied,spec$grouped)
    expect_identical(p$exposure_supplied,spec$exposed)
    expect_s3_class(strict$model,"etr_native_gee_scientific_model")
    expect_identical(strict$model$backend,"native_R_source_score_GEE")
    expect_equal(strict$model$parameter_covariance,
      strict$parameter_covariance,tolerance=0)
    expect_identical(attr(strict,"native_audit")$native_solver,
      "native_irls_gee_score_sandwich")
    legacy<-do.call(etr_fit_generalized_function_on_scalar_regression,
      c(f$args,list(python_boundary_mode=TRUE)))
    expect_true(is.null(legacy$model))
    expect_identical(legacy$provenance$native_solver,
      "native_irls_gee_score_sandwich")
    for(field in c("coefficient_functions","coefficient_standard_errors",
      "basis_coefficients","parameter_covariance","mean_functions"))
      expect_equal(strict[[field]],legacy[[field]],tolerance=0)
  }
})

test_that("strict source GEE workflow composes the real model with source W3 audit",{
  for(spec in list(
    list(family="poisson",grouped=FALSE,exposed=FALSE),
    list(family="poisson",grouped=FALSE,exposed=TRUE),
    list(family="binomial",grouped=TRUE,exposed=FALSE))){
    f<-do.call(.etr_gee_strict_case,spec)
    ans<-etr_run_generalized_functional_workflow(
      f$x,f$d,f$config,python_boundary_mode=TRUE,
      strict_source_record=TRUE)
    expect_s3_class(ans,"etr_generalized_functional_workflow")
    expect_identical(names(ans),c("workflow_schema_version",
      "workflow_contract","config","fit","steps",
      "decisions","provenance","reports","tables"))
    expect_identical(ans$workflow_contract,"generalized_functional:v1")
    expect_identical(names(ans$config$preprocessing),"steps")
    expect_length(ans$config$preprocessing$steps,0L)
    expect_identical(names(ans$fit),.etr_gee_strict_fields)
    expect_identical(ans$fit$provenance$
      generalized_function_on_scalar_regression$backend,
      "native_R_source_score_GEE")
    expect_identical(ans$steps[[1L]][["function"]],
      "fit_generalized_function_on_scalar_regression")
    expect_true(is.finite(ans$steps[[1L]]$elapsed_seconds))
    expect_gte(ans$steps[[1L]]$elapsed_seconds,0)
    expect_identical(names(ans$provenance),c(
      "input_layout","preprocessing_executed",
      "automatic_family_selection","binomial_denominator_inferred",
      "poisson_exposure_inferred",
      "automatic_working_correlation_selection",
      "automatic_model_selection_performed"))
    expect_true("fit"%in%names(ans$reports))
    expect_true("coefficients"%in%names(ans$tables))
    expect_equal(ans$tables$coefficients$estimate,
      as.vector(t(ans$fit$coefficient_functions)),tolerance=1e-12)
    if(spec$grouped)
      expect_match(ans$reports$fit,
        "grouped-binomial integer success counts",fixed=TRUE)
    if(spec$exposed)
      expect_match(ans$reports$fit,
        "strictly positive observed exposure",fixed=TRUE)
  }
})

test_that("strict GEE science records reject invalid flags while default is stable",{
  f<-.etr_gee_strict_case()
  expect_error(do.call(etr_fit_generalized_function_on_scalar_regression,
    c(f$args,list(strict_source_record=TRUE))),
    "requires python_boundary_mode")
  expect_error(do.call(etr_fit_generalized_function_on_scalar_regression,
    c(f$args,list(strict_source_record=1L))),
    "strict_source_record")
  expect_error(etr_run_generalized_functional_workflow(
    f$x,f$d,f$config,strict_source_record=TRUE),
    "requires python_boundary_mode")
  expect_error(etr_run_generalized_functional_workflow(
    f$x,f$d,f$config,strict_source_record=NA),
    "strict_source_record")
  legacy<-etr_run_generalized_functional_workflow(f$x,f$d,f$config)
  expect_identical(legacy$workflow_contract,
    "generalized_functional:native_independence_gee")
})

test_that("real frozen Python 1.2 statsmodels GEE numerically validates native source science",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("requires frozen Python 1.2 statsmodels GEE typed oracle")
  expect_identical(et_python_version(),"1.2.0")
  for(spec in list(
    list(family="poisson",grouped=FALSE,exposed=FALSE),
    list(family="poisson",grouped=FALSE,exposed=TRUE),
    list(family="binomial",grouped=TRUE,exposed=FALSE),
    list(family="binomial",grouped=FALSE,exposed=FALSE))){
    f<-do.call(.etr_gee_strict_case,spec)
    native<-do.call(etr_fit_generalized_function_on_scalar_regression,
      c(f$args,list(python_boundary_mode=TRUE,
        strict_source_record=TRUE)))
    py_args<-f$args;py_args$python_boundary_mode<-TRUE
    py<-do.call(.etr_python_gee_boundary_call,list(py_args))
    for(field in c("coefficient_functions","coefficient_standard_errors",
      "basis_coefficients","parameter_covariance","basis","basis_knots",
      "linear_predictor_functions","mean_functions","scalar_design_matrix",
      "rate_functions","binomial_expected_successes")){
      expected<-et_to_r(reticulate::py_get_attr(py,field))
      if(is.null(expected)){
        expect_null(native[[field]],info=paste(spec$family,field))
      }else{
        expect_equal(native[[field]],expected,
          tolerance=if(field=="parameter_covariance")5e-5 else 1e-6,
          ignore_attr=TRUE,info=paste(spec$family,field))
      }
    }
    py_prov<-et_to_r(py$provenance)$generalized_function_on_scalar_regression
    native_prov<-native$provenance$generalized_function_on_scalar_regression
    expect_identical(names(native_prov),names(py_prov))
    for(field in setdiff(names(native_prov),c("backend","backend_warnings")))
      expect_equal(native_prov[[field]],py_prov[[field]],
        ignore_attr=TRUE,info=paste(spec$family,"provenance",field))
    expect_identical(native_prov$backend,
      "native_R_source_score_GEE")
    expect_true(inherits(native$model,"etr_native_gee_scientific_model"))
  }
})

test_that("actual frozen Python generalized workflow matches report and numerical W3 tables",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("requires frozen Python 1.2 statsmodels W3 generalized workflow oracle")
  expect_identical(et_python_version(),"1.2.0")
  pd<-reticulate::import("pandas",convert=FALSE)
  builtins<-reticulate::import_builtins(convert=FALSE)
  pycore<-reticulate::import("eyetrajectoriespy.workflows._dense_regression",
    convert=FALSE)
  source_fun<-etpy_get_export("run_generalized_functional_workflow",
    .namespace="workflows")
  for(spec in list(
    list(family="poisson",grouped=FALSE,exposed=FALSE),
    list(family="poisson",grouped=FALSE,exposed=TRUE),
    list(family="binomial",grouped=TRUE,exposed=FALSE))){
    f<-do.call(.etr_gee_strict_case,spec)
    native<-etr_run_generalized_functional_workflow(
      f$x,f$d,f$config,python_boundary_mode=TRUE,
      strict_source_record=TRUE)
    pyx<-reticulate::py_call(etpy_get_export("TrajectorySet"),
      time=f$x$time,values=f$x$values,
      curve_ids=builtins$tuple(as.list(f$x$curve_ids)),
      dimension_names=builtins$tuple(as.list(f$x$dimension_names)),
      metadata=pd$DataFrame(lapply(f$x$metadata,as.list)),
      coordinate_system=f$x$coordinate_system,time_unit=f$x$time_unit)
    pyd<-pd$DataFrame(lapply(f$d,as.list))
    pycfg<-reticulate::py_call(
      pycore$GeneralizedFunctionalWorkflowConfig,
      predictors=builtins$tuple("treatment"),
      participant_column="participant_id",dimension="outcome",
      family=spec$family,basis_size=4L,spline_degree=3L,
      exposure=f$config$exposure,exposure_units=f$config$exposure_units,
      binomial_denominator=f$config$binomial_denominator)
    py<-reticulate::py_call(source_fun,
      trajectories=pyx,design=pyd,config=pycfg)
    expect_equal(native$fit$coefficient_functions,
      et_to_r(py$fit$coefficient_functions),tolerance=1e-6,
      ignore_attr=TRUE)
    expect_equal(native$fit$coefficient_standard_errors,
      et_to_r(py$fit$coefficient_standard_errors),tolerance=1e-5,
      ignore_attr=TRUE)
    expect_identical(native$reports$fit,et_to_r(py$reports[["fit"]]))
    expected_table<-et_to_r(py$tables[["coefficients"]])
    expect_identical(names(native$tables$coefficients),
      names(expected_table))
    for(field in names(expected_table))
      expect_equal(native$tables$coefficients[[field]],
        expected_table[[field]],tolerance=1e-6,
        ignore_attr=TRUE,info=paste(spec$family,field))
    expect_identical(names(native$decisions),
      names(et_to_r(py$decisions)))
    expect_identical(names(native$provenance),
      names(et_to_r(py$provenance)))
    expect_identical(native$steps[[1L]][["function"]],
      "fit_generalized_function_on_scalar_regression")
  }
})
