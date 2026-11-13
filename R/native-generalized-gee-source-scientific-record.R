# Frozen Python 1.2 GeneralizedFunctionOnScalarResult scientific boundary.
# Source pin c1cd95ad718327550f7e55393ff38582872f7a94:
# generalized_function_on_scalar.py, types.py and workflows/_dense_regression.py.
#
# The native R model is a genuine fitted numerical GEE scientific record,
# NOT a false claim of having executed or returned statsmodels.GEE objects.
# Source-backend identity and exceptions are explicitly different.

.etr_generalized_gee_source_scientific_record<-function(fit,trajectories){
  .etr_assert(inherits(fit,"etr_generalized_function_on_scalar")&&
    is.list(fit$provenance)&&
    is.matrix(fit$coefficient_functions)&&
    is.matrix(fit$parameter_covariance)&&
    is.matrix(fit$basis_coefficients)&&
    is.matrix(fit$scalar_design_matrix),
    "strict generalized GEE source record requires a real fitted native model")
  audit<-fit$provenance
  grouped<-!is.null(fit$binomial_denominators)
  exposed<-!is.null(fit$exposure)
  source_provenance<-list(
    method="marginal_function_on_scalar_gee",
    # The original Python source says statsmodels.GEE. Since R does not
    # execute statsmodels, the actual executed backend MUST be disclosed.
    backend="native_R_source_score_GEE",
    family=fit$family,
    link=fit$link,
    response_dimension=fit$dimension_name,
    participant_column=fit$participant_column,
    n_participants=as.integer(length(fit$participant_ids)),
    n_source_curves=as.integer(length(fit$source_curve_ids)),
    n_grid_observations=as.integer(length(fit$source_curve_ids)*length(fit$time)),
    coefficient_names=as.list(fit$coefficient_names),
    predictors=as.list(fit$predictor_names),
    design_alignment=audit$design_alignment,
    coefficient_basis="clamped_bspline",
    basis_size=fit$basis_size,
    spline_degree=fit$spline_degree,
    basis_size_selected_automatically=FALSE,
    smoothing_penalty=FALSE,
    working_correlation="independence",
    working_correlation_selected_automatically=FALSE,
    covariance_type="robust_sandwich",
    independent_cluster="participant",
    trial_varying_predictors_supported=TRUE,
    random_effects=FALSE,
    conditional_effect_interpretation=FALSE,
    marginal_population_averaged_interpretation=TRUE,
    categorical_encoding=FALSE,
    predictor_centering=FALSE,
    predictor_scaling=FALSE,
    interaction_construction=FALSE,
    automatic_family_selection=FALSE,
    automatic_link_selection=FALSE,
    automatic_model_selection=FALSE,
    cluster_count_guard="require n_participants > expanded_coefficient_parameter_count",
    expanded_coefficient_parameter_count=as.integer(ncol(fit$scalar_design_matrix)*fit$basis_size),
    cluster_count_guard_is_adequacy_theorem=FALSE,
    grouped_binomial_success_denominator_supported=TRUE,
    grouped_binomial_supplied=grouped,
    grouped_binomial_response_representation=if(grouped)
      "integer_successes_plus_integer_denominator" else NULL,
    grouped_binomial_backend_representation=if(grouped)
      "proportion_plus_gee_weights" else NULL,
    binomial_denominator_shape=if(grouped)
      as.list(as.integer(dim(fit$binomial_denominators))) else NULL,
    binomial_denominator_expanded_from_curve=
      fit$binomial_denominator_expanded_from_curve,
    binomial_denominator_inferred=FALSE,
    binomial_denominator_observed_and_fixed=grouped,
    binomial_denominator_measurement_uncertainty=FALSE,
    generic_proportion_input_supported=FALSE,
    generic_offset_supported=FALSE,
    poisson_exposure_supported=TRUE,
    exposure_supplied=exposed,
    exposure_shape=if(exposed)as.list(as.integer(dim(fit$exposure))) else NULL,
    exposure_units=fit$exposure_units,
    exposure_expanded_from_curve=fit$exposure_expanded_from_curve,
    exposure_inferred_from_time_grid=FALSE,
    exposure_inferred_from_trial_duration=FALSE,
    exposure_inferred_from_metadata=FALSE,
    exposure_observed_and_fixed=exposed,
    exposure_measurement_uncertainty=FALSE,
    converged=isTRUE(fit$converged),
    backend_warnings=as.list(fit$backend_warnings))
  provenance<-trajectories$provenance
  if(is.null(provenance))provenance<-list()
  .etr_assert(is.list(provenance),
    "native GEE strict source mode requires list source provenance")
  provenance$generalized_function_on_scalar_regression<-source_provenance
  # A genuine native equivalent to the scientific fitted coefficients,
  # covariance and link. Do not fabricate an opaque Python model handle.
  model<-structure(list(
    parameter_coefficients=as.numeric(t(fit$basis_coefficients)),
    parameter_covariance=fit$parameter_covariance,
    scale=fit$scale,
    converged=fit$converged,
    family=fit$family,link=fit$link,
    backend="native_R_source_score_GEE"),
    class="etr_native_gee_scientific_model")
  order<-c(
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
  fit$provenance<-provenance
  fit$model<-model
  .etr_assert(length(order)==47L&&setequal(names(fit),order),
    "strict GEE source record requires exactly 47 scientific fields")
  # Base-R list subsetting drops the S3 class of a fitted native model.
  # Keep the source field order without discarding the class required by
  # the bootstrap and downstream strict GEE scientific workflows.
  fit<-structure(fit[order],class="etr_generalized_function_on_scalar")
  # Preserve native convergence diagnostics as an attribute for downstream
  # R calculations, never impersonate an executed Python backend.
  attr(fit,"native_audit")<-audit
  fit
}
