# Generated from https://github.com/stefanosbalaskas/eyetrajectoriespy
# Source main Git commit: 7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed
# These wrappers delegate to Python; they are not native R estimators.
.etpy_upstream_commit <- "7bb9b8c74c0e708efe0669aa7e4265ea8ff13eed"
.etpy_root_exports <- c(
  "PortableScientificResultSnapshot",
  "capture_environment",
  "export_portable_result",
  "load_portable_result",
  "GeneralizedFunctionOnScalarPredictionResult",
  "GeneralizedFunctionOnScalarPredictionBootstrapResult",
  "GeneralizedFunctionOnScalarPredictionBandResult",
  "GeneralizedFunctionOnScalarMeanDifferenceResult",
  "generalized_function_on_scalar_predict",
  "bootstrap_generalized_function_on_scalar_predictions",
  "generalized_function_on_scalar_prediction_bands",
  "generalized_function_on_scalar_mean_difference_band",
  "generalized_function_on_scalar_prediction_frame",
  "generalized_function_on_scalar_mean_difference_frame",
  "plot_generalized_function_on_scalar_predictions",
  "plot_generalized_function_on_scalar_mean_difference",
  "generalized_function_on_scalar_prediction_reporting_text",
  "generalized_function_on_scalar_mean_difference_reporting_text",
  "GeneralizedFunctionOnScalarResult",
  "GeneralizedFunctionOnScalarBootstrapResult",
  "GeneralizedFunctionOnScalarBandResult",
  "fit_generalized_function_on_scalar_regression",
  "bootstrap_generalized_function_on_scalar_coefficients",
  "generalized_function_on_scalar_simultaneous_bands",
  "generalized_function_on_scalar_coefficient_frame",
  "generalized_function_on_scalar_exposure_frame",
  "plot_generalized_function_on_scalar_coefficients",
  "generalized_function_on_scalar_reporting_text",
  "FunctionalMixedEffectsCovarianceSpecification",
  "FunctionalMixedEffectsCovarianceSensitivityResult",
  "functional_mixed_effects_covariance_sensitivity",
  "functional_mixed_effects_covariance_sensitivity_reporting_text",
  "functional_mixed_effects_variance_decomposition",
  "plot_covariance_sensitivity_coefficients",
  "plot_covariance_sensitivity_band_widths",
  "plot_functional_variance_decomposition",
  "functional_mixed_effects_whitened_residuals",
  "functional_trial_random_effect_frame",
  "plot_functional_trial_random_effects",
  "functional_mixed_effects_full_refit_trial_audit_frame",
  "FunctionalMixedEffectsResidualDiagnosticsResult",
  "functional_mixed_effects_residual_diagnostics",
  "functional_mixed_effects_residual_diagnostic_frame",
  "functional_mixed_effects_residual_pair_frame",
  "compare_functional_mixed_effects_residual_diagnostics",
  "plot_functional_mixed_effects_residual_acf",
  "plot_functional_mixed_effects_residual_variogram",
  "functional_mixed_effects_residual_reporting_text",
  "FunctionalMixedEffectsFullRefitBootstrapResult",
  "bootstrap_functional_mixed_effects_full_refit",
  "functional_mixed_effects_full_refit_audit_frame",
  "functional_mixed_effects_variance_bootstrap_frame",
  "compare_functional_mixed_effects_bootstraps",
  "plot_functional_mixed_effects_bootstrap_comparison",
  "FunctionalMixedEffectsBootstrapResult",
  "FunctionalMixedEffectsBandResult",
  "bootstrap_functional_mixed_effects_coefficients",
  "functional_mixed_effects_simultaneous_bands",
  "functional_random_effect_frame",
  "plot_functional_random_effects",
  "ConditionalTransferEntropyResult",
  "ConditionalTransferEntropyCircularShiftTestResult",
  "conditional_transfer_entropy",
  "conditional_transfer_entropy_local_frame",
  "conditional_transfer_entropy_circular_shift_test",
  "plot_conditional_transfer_entropy_circular_shift_test",
  "conditional_transfer_entropy_reporting_text",
  "conditional_transfer_entropy_circular_shift_reporting_text",
  "TransferEntropySensitivityResult",
  "transfer_entropy_parameter_sensitivity",
  "plot_transfer_entropy_sensitivity",
  "transfer_entropy_parameter_sensitivity_reporting_text",
  "DiscreteTransferEntropyResult",
  "TransferEntropyCircularShiftTestResult",
  "discrete_transfer_entropy",
  "transfer_entropy_local_frame",
  "transfer_entropy_circular_shift_test",
  "plot_transfer_entropy_circular_shift_test",
  "transfer_entropy_reporting_text",
  "transfer_entropy_circular_shift_reporting_text",
  "recurrence_radius_profile_reporting_text",
  "rqa_metric_mean_bootstrap_reporting_text",
  "rqa_reporting_text",
  "rqa_parameter_sensitivity_reporting_text",
  "windowed_rqa_reporting_text",
  "windowed_rqa_functional_reporting_text",
  "windowed_rqa_sensitivity_reporting_text",
  "windowed_rqa_mean_band_reporting_text",
  "kantz_parameter_sensitivity_reporting_text",
  "largest_lyapunov_reporting_text",
  "lyapunov_parameter_sensitivity_reporting_text",
  "surrogate_nonlinearity_reporting_text",
  "return_map_stability_reporting_text",
  "plot_embedding_delay_diagnostics",
  "plot_embedding_dimension_diagnostics",
  "plot_recurrence",
  "plot_recurrence_rate_curve",
  "plot_rqa_metric_mean_bootstrap",
  "plot_rqa_sensitivity",
  "plot_windowed_rqa",
  "plot_windowed_rqa_trajectories",
  "plot_windowed_rqa_sensitivity",
  "plot_kantz_sensitivity",
  "plot_local_divergence",
  "plot_lyapunov_sensitivity",
  "plot_surrogate_nonlinearity",
  "plot_poincare_return_map",
  "DelayEmbeddingResult",
  "EmbeddingDelayDiagnosticResult",
  "EmbeddingDimensionDiagnosticResult",
  "RecurrenceNetworkResult",
  "RecurrenceRadiusProfileResult",
  "JointRecurrenceResult",
  "RecurrenceResult",
  "RQAResult",
  "RQAMeanBootstrapResult",
  "RQAParameterSensitivityResult",
  "WindowedRQAResult",
  "WindowedRQAFunctionalResult",
  "WindowedRQASensitivityResult",
  "WindowedRQAMeanBandResult",
  "LocalDivergenceResult",
  "KantzDivergenceResult",
  "KantzParameterSensitivityResult",
  "LargestLyapunovResult",
  "LyapunovParameterSensitivityResult",
  "MultivariateIAAFTResult",
  "MultivariateSurrogateNonlinearityResult",
  "SurrogateNonlinearityResult",
  "PoincareCrossingResult",
  "LocalReturnMapResult",
  "ReturnMapStabilityResult",
  "delay_embed_trajectory",
  "embedding_delay_diagnostics",
  "embedding_dimension_diagnostics",
  "joint_recurrence_matrix",
  "joint_recurrence_component_frame",
  "joint_rqa_metrics",
  "plot_joint_recurrence",
  "joint_recurrence_reporting_text",
  "recurrence_matrix",
  "recurrence_network",
  "recurrence_network_node_frame",
  "recurrence_network_summary_frame",
  "plot_recurrence_network_degree",
  "recurrence_network_reporting_text",
  "recurrence_radius_profile",
  "rqa_metrics",
  "rqa_parameter_sensitivity",
  "bootstrap_rqa_metric_means",
  "windowed_rqa",
  "windowed_rqa_trajectory_set",
  "windowed_rqa_sensitivity",
  "windowed_rqa_functional_mean_band",
  "cross_recurrence_matrix",
  "cross_rqa_metrics",
  "local_divergence_curve",
  "kantz_divergence_curve",
  "kantz_parameter_sensitivity",
  "estimate_largest_lyapunov_rosenstein",
  "estimate_largest_lyapunov_kantz",
  "lyapunov_parameter_sensitivity",
  "generate_multivariate_iaaft_surrogates",
  "multivariate_iaaft_diagnostics_frame",
  "multivariate_surrogate_nonlinearity_test",
  "plot_multivariate_iaaft_diagnostics",
  "plot_multivariate_surrogate_nonlinearity",
  "multivariate_iaaft_reporting_text",
  "multivariate_surrogate_nonlinearity_reporting_text",
  "surrogate_nonlinearity_test",
  "poincare_crossings",
  "fit_local_return_map",
  "return_map_stability",
  "MathematicalContract",
  "get_mathematical_contract",
  "list_mathematical_contracts",
  "mathematical_contract_frame",
  "TrajectoryDistanceSensitivityResult",
  "TrajectorySet",
  "DiscreteFrechetResult",
  "DynamicTimeWarpingResult",
  "FunctionalMixedEffectsResult",
  "FunctionOnScalarResult",
  "FunctionOnScalarBootstrapResult",
  "FunctionOnScalarBandResult",
  "IrregularTrajectorySet",
  "FPCAResult",
  "FPCAScoreUncertaintyResult",
  "FPCASpectrumUncertaintyResult",
  "FPCAStabilityResult",
  "FPCAInfluenceResult",
  "RegistrationResult",
  "RegistrationSensitivityResult",
  "CompositionalFPCAResult",
  "MultilevelFPCAResult",
  "ElasticFPCAResult",
  "FunctionalRegressionResult",
  "ConformalFunctionalAnomalyResult",
  "FunctionalOutlierResult",
  "ClusterResult",
  "BasisProjectionResult",
  "from_long_dataframe",
  "from_irregular_long_dataframe",
  "from_irregular_long_dataframe_native",
  "irregular_sampling_summary",
  "common_overlap_interval",
  "make_common_grid",
  "resample_irregular_to_grid",
  "resample_irregular_to_common_grid",
  "validate_trajectory_set",
  "validate_common_grid",
  "validate_simplex",
  "validate_no_long_missing_runs",
  "resample_to_grid",
  "interpolate_short_gaps",
  "smooth_trajectories",
  "normalize_time",
  "normalize_coordinates",
  "center_on_landmark",
  "functional_trapezoid_weights",
  "fit_fpca",
  "fit_mfpca",
  "transform_fpca",
  "reconstruct_fpca",
  "component_trajectories",
  "select_n_components",
  "fpca_score_frame",
  "register_to_landmarks",
  "warping_displacement",
  "phase_summary",
  "alr_transform",
  "inverse_alr",
  "fit_compositional_fpca",
  "reconstruct_compositional_fpca",
  "fit_multilevel_fpca",
  "phase_trajectory_set",
  "fit_phase_fpca",
  "phase_landmark_frame",
  "compare_registered_unregistered_fpca",
  "registration_sensitivity_frame",
  "fit_elastic_fpca",
  "differentiate_trajectories",
  "speed_function",
  "acceleration_magnitude_function",
  "distance_to_landmark_function",
  "cumulative_path_length",
  "heading_function",
  "signed_curvature_function",
  "turning_rate_function",
  "trajectory_tortuosity",
  "functional_l2_distance",
  "discrete_frechet_distance",
  "pairwise_discrete_frechet_distances",
  "dynamic_time_warping_distance",
  "pairwise_dynamic_time_warping_distances",
  "plot_dynamic_time_warping_alignment",
  "dynamic_time_warping_reporting_text",
  "fit_functional_mixed_effects_regression",
  "functional_mixed_effects_coefficient_frame",
  "plot_functional_mixed_effects_coefficient",
  "functional_mixed_effects_reporting_text",
  "fit_function_on_scalar_regression",
  "bootstrap_function_on_scalar_coefficients",
  "function_on_scalar_simultaneous_bands",
  "function_on_scalar_coefficient_frame",
  "plot_function_on_scalar_coefficients",
  "function_on_scalar_reporting_text",
  "pairwise_functional_distances",
  "trajectory_distance_sensitivity",
  "trajectory_distance_comparison_frame",
  "trajectory_distance_neighbor_frame",
  "plot_trajectory_distance_rank_correlations",
  "trajectory_distance_sensitivity_reporting_text",
  "nearest_trajectory_indices",
  "score_distance_matrix",
  "cluster_fpca_scores",
  "fit_scalar_on_function_regression",
  "split_conformal_fpca_anomaly",
  "conformal_fpca_anomaly_frame",
  "plot_conformal_fpca_anomaly",
  "conformal_fpca_anomaly_reporting_text",
  "diagnose_fpca_outliers",
  "leave_one_group_out_fpca_influence",
  "component_similarity_matrix",
  "match_fpca_components",
  "bootstrap_fpca_stability",
  "summarise_fpca_stability",
  "reconstruction_error_by_curve",
  "fpca_reconstruction_curve",
  "FunctionalSimulationResult",
  "FunctionalSimulationTruth",
  "FunctionalSimulationScenario",
  "FunctionalRecoveryRecord",
  "FunctionalRecoveryResult",
  "FunctionalRecoveryMetric",
  "FunctionalRecoveryValue",
  "FunctionalRecoveryAssessment",
  "simulate_functional_scenario",
  "expand_functional_simulation_scenarios",
  "run_functional_recovery_scenarios",
  "functional_simulation_scenario_frame",
  "functional_recovery_frame",
  "functional_recovery_failure_frame",
  "functional_recovery_summary_frame",
  "functional_recovery_metric_catalog",
  "functional_recovery_metric_catalog_frame",
  "functional_recovery_reporting_text",
  "plot_functional_recovery_summary",
  "functional_recovery_assessment_frame",
  "evaluate_fpca_recovery",
  "evaluate_functional_mixed_effects_recovery",
  "evaluate_sparse_fpca_recovery",
  "evaluate_sparse_mfpca_recovery",
  "evaluate_hierarchy_truth_recovery",
  "evaluate_registration_recovery",
  "functional_recovery_qualification_scenarios",
  "functional_recovery_stress_scenarios",
  "functional_recovery_scenario_catalog_frame",
  "plot_functional_simulation_curve",
  "plot_functional_simulation_phase_warps",
  "plot_functional_simulation_score_variances",
  "functional_simulation_reporting_text",
  "functional_simulation_truth_frame",
  "simulate_functional_process",
  "simulate_planar_trajectories",
  "simulate_aoi_probability_trajectories",
  "summarise_trajectory_set",
  "summarise_fpca",
  "fpca_reporting_text",
  "bootstrap_fpca_score_uncertainty",
  "fpca_score_uncertainty_frame",
  "fpca_score_uncertainty_reporting_text",
  "bootstrap_fpca_spectrum_uncertainty",
  "fpca_spectrum_uncertainty_frame",
  "fpca_spectrum_uncertainty_reporting_text",
  "fpca_influence_reporting_text",
  "fpca_outlier_reporting_text",
  "fpca_stability_reporting_text",
  "registration_sensitivity_reporting_text",
  "multilevel_fpca_reporting_text",
  "plot_trajectory_overlay",
  "plot_planar_trajectories",
  "plot_fpca_variance",
  "plot_fpca_score_uncertainty",
  "plot_fpca_spectrum_uncertainty",
  "plot_fpca_stability",
  "plot_reconstruction_curve",
  "plot_fpca_component",
  "plot_fpca_influence",
  "plot_fpca_outlier_diagnostics",
  "plot_registration",
  "plot_warping_functions",
  "to_skfda_grid",
  "detect_functional_outliers_skfda",
  "FPCACrossValidationResult",
  "FPCAComponentBandResult",
  "FPCAComponentEnvelopeResult",
  "cross_validate_fpca_reconstruction",
  "summarise_fpca_cross_validation",
  "select_fpca_components_cv",
  "bootstrap_fpca_component_bands",
  "fpca_component_band_frame",
  "bootstrap_fpca_component_envelopes",
  "plot_fpca_cross_validation",
  "plot_fpca_component_band",
  "plot_fpca_component_envelope",
  "fpca_cross_validation_reporting_text",
  "fpca_component_band_reporting_text",
  "fpca_component_envelope_reporting_text",
  "plot_fpca_subspace_stability",
  "fpca_eigengap_reporting_text",
  "fpca_subspace_stability_reporting_text",
  "FPCASubspaceComparisonResult",
  "FPCASubspaceStabilityResult",
  "fpca_eigenvalue_gap_table",
  "compare_fpca_subspaces",
  "bootstrap_fpca_subspace_stability",
  "summarise_fpca_subspace_stability",
  "FunctionalMeanBandResult",
  "multiplier_functional_mean_band",
  "functional_mean_band_frame",
  "plot_functional_mean_band",
  "functional_mean_band_reporting_text",
  "SparseFPCAResult",
  "SparseMFPCAResult",
  "plot_sparse_mfpca_component",
  "plot_sparse_mfpca_covariance_blocks",
  "plot_sparse_mfpca_cross_covariance",
  "plot_sparse_mfpca_score_diagnostics",
  "fit_sparse_mfpca",
  "sparse_mfpca_score_frame",
  "sparse_mfpca_reporting_text",
  "sparse_dimension_summary",
  "to_fdapy_irregular",
  "fit_sparse_fpca",
  "fit_sparse_fpca_fdapy",
  "sparse_fpca_score_frame",
  "sparse_fpca_reporting_text",
  "plot_sparse_irregular_dimension",
  "plot_sparse_fpca_score_diagnostics",
  "plot_sparse_fpca_covariance",
  "plot_sparse_fpca_component",
  "FPCARegressionCVResult",
  "FPCARegressionPredictionIntervalResult",
  "FPCARegressionSlopeBandResult",
  "FPCARegressionUncertaintyResult",
  "FPCAWildBootstrapProjectionResult",
  "FPCAWildBootstrapFamilyTestResult",
  "FPCAWildBootstrapMonteCarloDiagnosticResult",
  "FPCAWildBootstrapSimultaneousResult",
  "FPCAWildBootstrapTruncationScanResult",
  "FPCAWildBootstrapTruncationSelectionResult",
  "FPCANestedRegressionCVResult",
  "bootstrap_fpca_regression_uncertainty",
  "wild_bootstrap_fpca_projection",
  "scan_wild_bootstrap_fpca_truncations",
  "select_fpca_wild_bootstrap_truncation",
  "fpca_wild_bootstrap_truncation_scan_frame",
  "fpca_wild_bootstrap_truncation_selection_frame",
  "plot_fpca_wild_bootstrap_truncation_scan",
  "fpca_wild_bootstrap_truncation_reporting_text",
  "fpca_wild_bootstrap_projection_frame",
  "plot_fpca_wild_bootstrap_projection",
  "fpca_wild_bootstrap_projection_family_test",
  "fpca_wild_bootstrap_family_test_frame",
  "fpca_wild_bootstrap_family_test_monte_carlo_diagnostics",
  "fpca_wild_bootstrap_monte_carlo_diagnostic_frame",
  "plot_fpca_wild_bootstrap_family_test",
  "plot_fpca_wild_bootstrap_monte_carlo_diagnostics",
  "fpca_wild_bootstrap_family_test_reporting_text",
  "fpca_wild_bootstrap_monte_carlo_reporting_text",
  "fpca_wild_bootstrap_projection_simultaneous_interval",
  "fpca_wild_bootstrap_simultaneous_frame",
  "plot_fpca_wild_bootstrap_simultaneous_interval",
  "fpca_wild_bootstrap_simultaneous_reporting_text",
  "fpca_wild_bootstrap_projection_reporting_text",
  "fpca_regression_future_prediction_interval",
  "fpca_regression_future_prediction_frame",
  "plot_fpca_regression_future_prediction_interval",
  "fpca_regression_future_prediction_reporting_text",
  "fpca_regression_slope_simultaneous_band",
  "fpca_regression_slope_band_frame",
  "plot_fpca_regression_slope_band",
  "fpca_regression_slope_band_reporting_text",
  "fpca_regression_slope_uncertainty_frame",
  "fpca_regression_prediction_uncertainty_frame",
  "plot_fpca_regression_slope_uncertainty",
  "plot_fpca_regression_mean_prediction_uncertainty",
  "fpca_regression_uncertainty_reporting_text",
  "cross_validate_fpca_regression",
  "summarise_fpca_regression_cv",
  "select_fpca_regression_components",
  "nested_cross_validate_fpca_regression",
  "plot_fpca_regression_cv",
  "plot_nested_fpca_regression_cv",
  "fpca_regression_cv_reporting_text",
  "fpca_nested_regression_cv_reporting_text",
  "to_skfda_basis"
)
.etpy_workflow_exports <- c(
  "FPCAWorkflowConfig",
  "FPCAWorkflowResult",
  "FunctionOnScalarWorkflowConfig",
  "FunctionOnScalarWorkflowResult",
  "FunctionalMixedEffectsWorkflowConfig",
  "FunctionalMixedEffectsWorkflowResult",
  "GeneralizedFunctionalWorkflowConfig",
  "GeneralizedFunctionalWorkflowResult",
  "RecurrenceWorkflowConfig",
  "RecurrenceWorkflowResult",
  "SUPPORTED_WORKFLOW_PLOTS",
  "ObservationDiagnosticConfig",
  "PreprocessingPlan",
  "PreprocessingStepConfig",
  "ScoreUncertaintyConfig",
  "SparseFPCABandwidthSelectionConfig",
  "SparseFPCAWorkflowConfig",
  "SparseFPCAWorkflowResult",
  "SparseMFPCABandwidthSelectionConfig",
  "SparseMFPCAAsyncWorkflowConfig",
  "SparseMFPCAAsyncWorkflowResult",
  "SparseMFPCAWorkflowConfig",
  "SparseMFPCAWorkflowResult",
  "SparseMultilevelWorkflowConfig",
  "SparseMultilevelWorkflowResult",
  "SparsePredictionWorkflowConfig",
  "SparsePredictionWorkflowResult",
  "WORKFLOW_BUNDLE_FORMAT",
  "WORKFLOW_BUNDLE_SCHEMA_VERSION",
  "WORKFLOW_SCHEMA_VERSION",
  "WorkflowDecisionRecord",
  "WorkflowStepRecord",
  "export_workflow_bundle",
  "run_fpca_workflow",
  "run_function_on_scalar_workflow",
  "run_functional_mixed_effects_workflow",
  "run_generalized_functional_workflow",
  "run_recurrence_workflow",
  "plot_workflow_result",
  "save_workflow_figure",
  "run_sparse_fpca_workflow",
  "run_sparse_mfpca_async_workflow",
  "run_sparse_mfpca_workflow",
  "run_sparse_multilevel_workflow",
  "run_sparse_prediction_workflow",
  "workflow_config_to_dict",
  "workflow_decisions_frame",
  "workflow_reporting_text",
  "workflow_steps_frame",
  "workflow_summary_frame"
)
#' @rdname etpy_python_functions
#' @export
etpy_capture_environment <- function(..., .convert = FALSE) {
  et_call("capture_environment", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_export_portable_result <- function(..., .convert = FALSE) {
  et_call("export_portable_result", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_load_portable_result <- function(..., .convert = FALSE) {
  et_call("load_portable_result", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_generalized_function_on_scalar_predict <- function(..., .convert = FALSE) {
  et_call("generalized_function_on_scalar_predict", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_bootstrap_generalized_function_on_scalar_predictions <- function(..., .convert = FALSE) {
  et_call("bootstrap_generalized_function_on_scalar_predictions", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_generalized_function_on_scalar_prediction_bands <- function(..., .convert = FALSE) {
  et_call("generalized_function_on_scalar_prediction_bands", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_generalized_function_on_scalar_mean_difference_band <- function(..., .convert = FALSE) {
  et_call("generalized_function_on_scalar_mean_difference_band", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_generalized_function_on_scalar_prediction_frame <- function(..., .convert = FALSE) {
  et_call("generalized_function_on_scalar_prediction_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_generalized_function_on_scalar_mean_difference_frame <- function(..., .convert = FALSE) {
  et_call("generalized_function_on_scalar_mean_difference_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_generalized_function_on_scalar_predictions <- function(..., .convert = FALSE) {
  et_call("plot_generalized_function_on_scalar_predictions", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_generalized_function_on_scalar_mean_difference <- function(..., .convert = FALSE) {
  et_call("plot_generalized_function_on_scalar_mean_difference", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_generalized_function_on_scalar_prediction_reporting_text <- function(..., .convert = FALSE) {
  et_call("generalized_function_on_scalar_prediction_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_generalized_function_on_scalar_mean_difference_reporting_text <- function(..., .convert = FALSE) {
  et_call("generalized_function_on_scalar_mean_difference_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fit_generalized_function_on_scalar_regression <- function(..., .convert = FALSE) {
  et_call("fit_generalized_function_on_scalar_regression", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_bootstrap_generalized_function_on_scalar_coefficients <- function(..., .convert = FALSE) {
  et_call("bootstrap_generalized_function_on_scalar_coefficients", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_generalized_function_on_scalar_simultaneous_bands <- function(..., .convert = FALSE) {
  et_call("generalized_function_on_scalar_simultaneous_bands", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_generalized_function_on_scalar_coefficient_frame <- function(..., .convert = FALSE) {
  et_call("generalized_function_on_scalar_coefficient_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_generalized_function_on_scalar_exposure_frame <- function(..., .convert = FALSE) {
  et_call("generalized_function_on_scalar_exposure_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_generalized_function_on_scalar_coefficients <- function(..., .convert = FALSE) {
  et_call("plot_generalized_function_on_scalar_coefficients", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_generalized_function_on_scalar_reporting_text <- function(..., .convert = FALSE) {
  et_call("generalized_function_on_scalar_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_mixed_effects_covariance_sensitivity <- function(..., .convert = FALSE) {
  et_call("functional_mixed_effects_covariance_sensitivity", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_mixed_effects_covariance_sensitivity_reporting_text <- function(..., .convert = FALSE) {
  et_call("functional_mixed_effects_covariance_sensitivity_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_mixed_effects_variance_decomposition <- function(..., .convert = FALSE) {
  et_call("functional_mixed_effects_variance_decomposition", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_covariance_sensitivity_coefficients <- function(..., .convert = FALSE) {
  et_call("plot_covariance_sensitivity_coefficients", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_covariance_sensitivity_band_widths <- function(..., .convert = FALSE) {
  et_call("plot_covariance_sensitivity_band_widths", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_functional_variance_decomposition <- function(..., .convert = FALSE) {
  et_call("plot_functional_variance_decomposition", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_mixed_effects_whitened_residuals <- function(..., .convert = FALSE) {
  et_call("functional_mixed_effects_whitened_residuals", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_trial_random_effect_frame <- function(..., .convert = FALSE) {
  et_call("functional_trial_random_effect_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_functional_trial_random_effects <- function(..., .convert = FALSE) {
  et_call("plot_functional_trial_random_effects", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_mixed_effects_full_refit_trial_audit_frame <- function(..., .convert = FALSE) {
  et_call("functional_mixed_effects_full_refit_trial_audit_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_mixed_effects_residual_diagnostics <- function(..., .convert = FALSE) {
  et_call("functional_mixed_effects_residual_diagnostics", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_mixed_effects_residual_diagnostic_frame <- function(..., .convert = FALSE) {
  et_call("functional_mixed_effects_residual_diagnostic_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_mixed_effects_residual_pair_frame <- function(..., .convert = FALSE) {
  et_call("functional_mixed_effects_residual_pair_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_compare_functional_mixed_effects_residual_diagnostics <- function(..., .convert = FALSE) {
  et_call("compare_functional_mixed_effects_residual_diagnostics", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_functional_mixed_effects_residual_acf <- function(..., .convert = FALSE) {
  et_call("plot_functional_mixed_effects_residual_acf", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_functional_mixed_effects_residual_variogram <- function(..., .convert = FALSE) {
  et_call("plot_functional_mixed_effects_residual_variogram", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_mixed_effects_residual_reporting_text <- function(..., .convert = FALSE) {
  et_call("functional_mixed_effects_residual_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_bootstrap_functional_mixed_effects_full_refit <- function(..., .convert = FALSE) {
  et_call("bootstrap_functional_mixed_effects_full_refit", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_mixed_effects_full_refit_audit_frame <- function(..., .convert = FALSE) {
  et_call("functional_mixed_effects_full_refit_audit_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_mixed_effects_variance_bootstrap_frame <- function(..., .convert = FALSE) {
  et_call("functional_mixed_effects_variance_bootstrap_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_compare_functional_mixed_effects_bootstraps <- function(..., .convert = FALSE) {
  et_call("compare_functional_mixed_effects_bootstraps", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_functional_mixed_effects_bootstrap_comparison <- function(..., .convert = FALSE) {
  et_call("plot_functional_mixed_effects_bootstrap_comparison", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_bootstrap_functional_mixed_effects_coefficients <- function(..., .convert = FALSE) {
  et_call("bootstrap_functional_mixed_effects_coefficients", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_mixed_effects_simultaneous_bands <- function(..., .convert = FALSE) {
  et_call("functional_mixed_effects_simultaneous_bands", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_random_effect_frame <- function(..., .convert = FALSE) {
  et_call("functional_random_effect_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_functional_random_effects <- function(..., .convert = FALSE) {
  et_call("plot_functional_random_effects", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_conditional_transfer_entropy <- function(..., .convert = FALSE) {
  et_call("conditional_transfer_entropy", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_conditional_transfer_entropy_local_frame <- function(..., .convert = FALSE) {
  et_call("conditional_transfer_entropy_local_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_conditional_transfer_entropy_circular_shift_test <- function(..., .convert = FALSE) {
  et_call("conditional_transfer_entropy_circular_shift_test", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_conditional_transfer_entropy_circular_shift_test <- function(..., .convert = FALSE) {
  et_call("plot_conditional_transfer_entropy_circular_shift_test", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_conditional_transfer_entropy_reporting_text <- function(..., .convert = FALSE) {
  et_call("conditional_transfer_entropy_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_conditional_transfer_entropy_circular_shift_reporting_text <- function(..., .convert = FALSE) {
  et_call("conditional_transfer_entropy_circular_shift_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_transfer_entropy_parameter_sensitivity <- function(..., .convert = FALSE) {
  et_call("transfer_entropy_parameter_sensitivity", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_transfer_entropy_sensitivity <- function(..., .convert = FALSE) {
  et_call("plot_transfer_entropy_sensitivity", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_transfer_entropy_parameter_sensitivity_reporting_text <- function(..., .convert = FALSE) {
  et_call("transfer_entropy_parameter_sensitivity_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_discrete_transfer_entropy <- function(..., .convert = FALSE) {
  et_call("discrete_transfer_entropy", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_transfer_entropy_local_frame <- function(..., .convert = FALSE) {
  et_call("transfer_entropy_local_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_transfer_entropy_circular_shift_test <- function(..., .convert = FALSE) {
  et_call("transfer_entropy_circular_shift_test", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_transfer_entropy_circular_shift_test <- function(..., .convert = FALSE) {
  et_call("plot_transfer_entropy_circular_shift_test", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_transfer_entropy_reporting_text <- function(..., .convert = FALSE) {
  et_call("transfer_entropy_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_transfer_entropy_circular_shift_reporting_text <- function(..., .convert = FALSE) {
  et_call("transfer_entropy_circular_shift_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_recurrence_radius_profile_reporting_text <- function(..., .convert = FALSE) {
  et_call("recurrence_radius_profile_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_rqa_metric_mean_bootstrap_reporting_text <- function(..., .convert = FALSE) {
  et_call("rqa_metric_mean_bootstrap_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_rqa_reporting_text <- function(..., .convert = FALSE) {
  et_call("rqa_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_rqa_parameter_sensitivity_reporting_text <- function(..., .convert = FALSE) {
  et_call("rqa_parameter_sensitivity_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_windowed_rqa_reporting_text <- function(..., .convert = FALSE) {
  et_call("windowed_rqa_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_windowed_rqa_functional_reporting_text <- function(..., .convert = FALSE) {
  et_call("windowed_rqa_functional_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_windowed_rqa_sensitivity_reporting_text <- function(..., .convert = FALSE) {
  et_call("windowed_rqa_sensitivity_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_windowed_rqa_mean_band_reporting_text <- function(..., .convert = FALSE) {
  et_call("windowed_rqa_mean_band_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_kantz_parameter_sensitivity_reporting_text <- function(..., .convert = FALSE) {
  et_call("kantz_parameter_sensitivity_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_largest_lyapunov_reporting_text <- function(..., .convert = FALSE) {
  et_call("largest_lyapunov_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_lyapunov_parameter_sensitivity_reporting_text <- function(..., .convert = FALSE) {
  et_call("lyapunov_parameter_sensitivity_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_surrogate_nonlinearity_reporting_text <- function(..., .convert = FALSE) {
  et_call("surrogate_nonlinearity_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_return_map_stability_reporting_text <- function(..., .convert = FALSE) {
  et_call("return_map_stability_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_embedding_delay_diagnostics <- function(..., .convert = FALSE) {
  et_call("plot_embedding_delay_diagnostics", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_embedding_dimension_diagnostics <- function(..., .convert = FALSE) {
  et_call("plot_embedding_dimension_diagnostics", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_recurrence <- function(..., .convert = FALSE) {
  et_call("plot_recurrence", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_recurrence_rate_curve <- function(..., .convert = FALSE) {
  et_call("plot_recurrence_rate_curve", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_rqa_metric_mean_bootstrap <- function(..., .convert = FALSE) {
  et_call("plot_rqa_metric_mean_bootstrap", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_rqa_sensitivity <- function(..., .convert = FALSE) {
  et_call("plot_rqa_sensitivity", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_windowed_rqa <- function(..., .convert = FALSE) {
  et_call("plot_windowed_rqa", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_windowed_rqa_trajectories <- function(..., .convert = FALSE) {
  et_call("plot_windowed_rqa_trajectories", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_windowed_rqa_sensitivity <- function(..., .convert = FALSE) {
  et_call("plot_windowed_rqa_sensitivity", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_kantz_sensitivity <- function(..., .convert = FALSE) {
  et_call("plot_kantz_sensitivity", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_local_divergence <- function(..., .convert = FALSE) {
  et_call("plot_local_divergence", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_lyapunov_sensitivity <- function(..., .convert = FALSE) {
  et_call("plot_lyapunov_sensitivity", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_surrogate_nonlinearity <- function(..., .convert = FALSE) {
  et_call("plot_surrogate_nonlinearity", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_poincare_return_map <- function(..., .convert = FALSE) {
  et_call("plot_poincare_return_map", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_delay_embed_trajectory <- function(..., .convert = FALSE) {
  et_call("delay_embed_trajectory", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_embedding_delay_diagnostics <- function(..., .convert = FALSE) {
  et_call("embedding_delay_diagnostics", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_embedding_dimension_diagnostics <- function(..., .convert = FALSE) {
  et_call("embedding_dimension_diagnostics", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_joint_recurrence_matrix <- function(..., .convert = FALSE) {
  et_call("joint_recurrence_matrix", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_joint_recurrence_component_frame <- function(..., .convert = FALSE) {
  et_call("joint_recurrence_component_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_joint_rqa_metrics <- function(..., .convert = FALSE) {
  et_call("joint_rqa_metrics", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_joint_recurrence <- function(..., .convert = FALSE) {
  et_call("plot_joint_recurrence", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_joint_recurrence_reporting_text <- function(..., .convert = FALSE) {
  et_call("joint_recurrence_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_recurrence_matrix <- function(..., .convert = FALSE) {
  et_call("recurrence_matrix", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_recurrence_network <- function(..., .convert = FALSE) {
  et_call("recurrence_network", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_recurrence_network_node_frame <- function(..., .convert = FALSE) {
  et_call("recurrence_network_node_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_recurrence_network_summary_frame <- function(..., .convert = FALSE) {
  et_call("recurrence_network_summary_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_recurrence_network_degree <- function(..., .convert = FALSE) {
  et_call("plot_recurrence_network_degree", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_recurrence_network_reporting_text <- function(..., .convert = FALSE) {
  et_call("recurrence_network_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_recurrence_radius_profile <- function(..., .convert = FALSE) {
  et_call("recurrence_radius_profile", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_rqa_metrics <- function(..., .convert = FALSE) {
  et_call("rqa_metrics", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_rqa_parameter_sensitivity <- function(..., .convert = FALSE) {
  et_call("rqa_parameter_sensitivity", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_bootstrap_rqa_metric_means <- function(..., .convert = FALSE) {
  et_call("bootstrap_rqa_metric_means", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_windowed_rqa <- function(..., .convert = FALSE) {
  et_call("windowed_rqa", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_windowed_rqa_trajectory_set <- function(..., .convert = FALSE) {
  et_call("windowed_rqa_trajectory_set", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_windowed_rqa_sensitivity <- function(..., .convert = FALSE) {
  et_call("windowed_rqa_sensitivity", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_windowed_rqa_functional_mean_band <- function(..., .convert = FALSE) {
  et_call("windowed_rqa_functional_mean_band", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_cross_recurrence_matrix <- function(..., .convert = FALSE) {
  et_call("cross_recurrence_matrix", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_cross_rqa_metrics <- function(..., .convert = FALSE) {
  et_call("cross_rqa_metrics", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_local_divergence_curve <- function(..., .convert = FALSE) {
  et_call("local_divergence_curve", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_kantz_divergence_curve <- function(..., .convert = FALSE) {
  et_call("kantz_divergence_curve", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_kantz_parameter_sensitivity <- function(..., .convert = FALSE) {
  et_call("kantz_parameter_sensitivity", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_estimate_largest_lyapunov_rosenstein <- function(..., .convert = FALSE) {
  et_call("estimate_largest_lyapunov_rosenstein", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_estimate_largest_lyapunov_kantz <- function(..., .convert = FALSE) {
  et_call("estimate_largest_lyapunov_kantz", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_lyapunov_parameter_sensitivity <- function(..., .convert = FALSE) {
  et_call("lyapunov_parameter_sensitivity", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_generate_multivariate_iaaft_surrogates <- function(..., .convert = FALSE) {
  et_call("generate_multivariate_iaaft_surrogates", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_multivariate_iaaft_diagnostics_frame <- function(..., .convert = FALSE) {
  et_call("multivariate_iaaft_diagnostics_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_multivariate_surrogate_nonlinearity_test <- function(..., .convert = FALSE) {
  et_call("multivariate_surrogate_nonlinearity_test", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_multivariate_iaaft_diagnostics <- function(..., .convert = FALSE) {
  et_call("plot_multivariate_iaaft_diagnostics", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_multivariate_surrogate_nonlinearity <- function(..., .convert = FALSE) {
  et_call("plot_multivariate_surrogate_nonlinearity", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_multivariate_iaaft_reporting_text <- function(..., .convert = FALSE) {
  et_call("multivariate_iaaft_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_multivariate_surrogate_nonlinearity_reporting_text <- function(..., .convert = FALSE) {
  et_call("multivariate_surrogate_nonlinearity_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_surrogate_nonlinearity_test <- function(..., .convert = FALSE) {
  et_call("surrogate_nonlinearity_test", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_poincare_crossings <- function(..., .convert = FALSE) {
  et_call("poincare_crossings", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fit_local_return_map <- function(..., .convert = FALSE) {
  et_call("fit_local_return_map", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_return_map_stability <- function(..., .convert = FALSE) {
  et_call("return_map_stability", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_get_mathematical_contract <- function(..., .convert = FALSE) {
  et_call("get_mathematical_contract", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_list_mathematical_contracts <- function(..., .convert = FALSE) {
  et_call("list_mathematical_contracts", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_mathematical_contract_frame <- function(..., .convert = FALSE) {
  et_call("mathematical_contract_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_from_long_dataframe <- function(..., .convert = FALSE) {
  et_call("from_long_dataframe", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_from_irregular_long_dataframe <- function(..., .convert = FALSE) {
  et_call("from_irregular_long_dataframe", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_from_irregular_long_dataframe_native <- function(..., .convert = FALSE) {
  et_call("from_irregular_long_dataframe_native", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_irregular_sampling_summary <- function(..., .convert = FALSE) {
  et_call("irregular_sampling_summary", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_common_overlap_interval <- function(..., .convert = FALSE) {
  et_call("common_overlap_interval", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_make_common_grid <- function(..., .convert = FALSE) {
  et_call("make_common_grid", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_resample_irregular_to_grid <- function(..., .convert = FALSE) {
  et_call("resample_irregular_to_grid", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_resample_irregular_to_common_grid <- function(..., .convert = FALSE) {
  et_call("resample_irregular_to_common_grid", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_validate_trajectory_set <- function(..., .convert = FALSE) {
  et_call("validate_trajectory_set", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_validate_common_grid <- function(..., .convert = FALSE) {
  et_call("validate_common_grid", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_validate_simplex <- function(..., .convert = FALSE) {
  et_call("validate_simplex", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_validate_no_long_missing_runs <- function(..., .convert = FALSE) {
  et_call("validate_no_long_missing_runs", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_resample_to_grid <- function(..., .convert = FALSE) {
  et_call("resample_to_grid", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_interpolate_short_gaps <- function(..., .convert = FALSE) {
  et_call("interpolate_short_gaps", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_smooth_trajectories <- function(..., .convert = FALSE) {
  et_call("smooth_trajectories", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_normalize_time <- function(..., .convert = FALSE) {
  et_call("normalize_time", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_normalize_coordinates <- function(..., .convert = FALSE) {
  et_call("normalize_coordinates", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_center_on_landmark <- function(..., .convert = FALSE) {
  et_call("center_on_landmark", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_trapezoid_weights <- function(..., .convert = FALSE) {
  et_call("functional_trapezoid_weights", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fit_fpca <- function(..., .convert = FALSE) {
  et_call("fit_fpca", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fit_mfpca <- function(..., .convert = FALSE) {
  et_call("fit_mfpca", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_transform_fpca <- function(..., .convert = FALSE) {
  et_call("transform_fpca", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_reconstruct_fpca <- function(..., .convert = FALSE) {
  et_call("reconstruct_fpca", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_component_trajectories <- function(..., .convert = FALSE) {
  et_call("component_trajectories", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_select_n_components <- function(..., .convert = FALSE) {
  et_call("select_n_components", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_score_frame <- function(..., .convert = FALSE) {
  et_call("fpca_score_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_register_to_landmarks <- function(..., .convert = FALSE) {
  et_call("register_to_landmarks", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_warping_displacement <- function(..., .convert = FALSE) {
  et_call("warping_displacement", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_phase_summary <- function(..., .convert = FALSE) {
  et_call("phase_summary", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_alr_transform <- function(..., .convert = FALSE) {
  et_call("alr_transform", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_inverse_alr <- function(..., .convert = FALSE) {
  et_call("inverse_alr", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fit_compositional_fpca <- function(..., .convert = FALSE) {
  et_call("fit_compositional_fpca", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_reconstruct_compositional_fpca <- function(..., .convert = FALSE) {
  et_call("reconstruct_compositional_fpca", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fit_multilevel_fpca <- function(..., .convert = FALSE) {
  et_call("fit_multilevel_fpca", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_phase_trajectory_set <- function(..., .convert = FALSE) {
  et_call("phase_trajectory_set", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fit_phase_fpca <- function(..., .convert = FALSE) {
  et_call("fit_phase_fpca", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_phase_landmark_frame <- function(..., .convert = FALSE) {
  et_call("phase_landmark_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_compare_registered_unregistered_fpca <- function(..., .convert = FALSE) {
  et_call("compare_registered_unregistered_fpca", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_registration_sensitivity_frame <- function(..., .convert = FALSE) {
  et_call("registration_sensitivity_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fit_elastic_fpca <- function(..., .convert = FALSE) {
  et_call("fit_elastic_fpca", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_differentiate_trajectories <- function(..., .convert = FALSE) {
  et_call("differentiate_trajectories", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_speed_function <- function(..., .convert = FALSE) {
  et_call("speed_function", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_acceleration_magnitude_function <- function(..., .convert = FALSE) {
  et_call("acceleration_magnitude_function", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_distance_to_landmark_function <- function(..., .convert = FALSE) {
  et_call("distance_to_landmark_function", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_cumulative_path_length <- function(..., .convert = FALSE) {
  et_call("cumulative_path_length", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_heading_function <- function(..., .convert = FALSE) {
  et_call("heading_function", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_signed_curvature_function <- function(..., .convert = FALSE) {
  et_call("signed_curvature_function", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_turning_rate_function <- function(..., .convert = FALSE) {
  et_call("turning_rate_function", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_trajectory_tortuosity <- function(..., .convert = FALSE) {
  et_call("trajectory_tortuosity", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_l2_distance <- function(..., .convert = FALSE) {
  et_call("functional_l2_distance", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_discrete_frechet_distance <- function(..., .convert = FALSE) {
  et_call("discrete_frechet_distance", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_pairwise_discrete_frechet_distances <- function(..., .convert = FALSE) {
  et_call("pairwise_discrete_frechet_distances", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_dynamic_time_warping_distance <- function(..., .convert = FALSE) {
  et_call("dynamic_time_warping_distance", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_pairwise_dynamic_time_warping_distances <- function(..., .convert = FALSE) {
  et_call("pairwise_dynamic_time_warping_distances", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_dynamic_time_warping_alignment <- function(..., .convert = FALSE) {
  et_call("plot_dynamic_time_warping_alignment", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_dynamic_time_warping_reporting_text <- function(..., .convert = FALSE) {
  et_call("dynamic_time_warping_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fit_functional_mixed_effects_regression <- function(..., .convert = FALSE) {
  et_call("fit_functional_mixed_effects_regression", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_mixed_effects_coefficient_frame <- function(..., .convert = FALSE) {
  et_call("functional_mixed_effects_coefficient_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_functional_mixed_effects_coefficient <- function(..., .convert = FALSE) {
  et_call("plot_functional_mixed_effects_coefficient", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_mixed_effects_reporting_text <- function(..., .convert = FALSE) {
  et_call("functional_mixed_effects_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fit_function_on_scalar_regression <- function(..., .convert = FALSE) {
  et_call("fit_function_on_scalar_regression", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_bootstrap_function_on_scalar_coefficients <- function(..., .convert = FALSE) {
  et_call("bootstrap_function_on_scalar_coefficients", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_function_on_scalar_simultaneous_bands <- function(..., .convert = FALSE) {
  et_call("function_on_scalar_simultaneous_bands", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_function_on_scalar_coefficient_frame <- function(..., .convert = FALSE) {
  et_call("function_on_scalar_coefficient_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_function_on_scalar_coefficients <- function(..., .convert = FALSE) {
  et_call("plot_function_on_scalar_coefficients", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_function_on_scalar_reporting_text <- function(..., .convert = FALSE) {
  et_call("function_on_scalar_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_pairwise_functional_distances <- function(..., .convert = FALSE) {
  et_call("pairwise_functional_distances", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_trajectory_distance_sensitivity <- function(..., .convert = FALSE) {
  et_call("trajectory_distance_sensitivity", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_trajectory_distance_comparison_frame <- function(..., .convert = FALSE) {
  et_call("trajectory_distance_comparison_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_trajectory_distance_neighbor_frame <- function(..., .convert = FALSE) {
  et_call("trajectory_distance_neighbor_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_trajectory_distance_rank_correlations <- function(..., .convert = FALSE) {
  et_call("plot_trajectory_distance_rank_correlations", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_trajectory_distance_sensitivity_reporting_text <- function(..., .convert = FALSE) {
  et_call("trajectory_distance_sensitivity_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_nearest_trajectory_indices <- function(..., .convert = FALSE) {
  et_call("nearest_trajectory_indices", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_score_distance_matrix <- function(..., .convert = FALSE) {
  et_call("score_distance_matrix", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_cluster_fpca_scores <- function(..., .convert = FALSE) {
  et_call("cluster_fpca_scores", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fit_scalar_on_function_regression <- function(..., .convert = FALSE) {
  et_call("fit_scalar_on_function_regression", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_split_conformal_fpca_anomaly <- function(..., .convert = FALSE) {
  et_call("split_conformal_fpca_anomaly", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_conformal_fpca_anomaly_frame <- function(..., .convert = FALSE) {
  et_call("conformal_fpca_anomaly_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_conformal_fpca_anomaly <- function(..., .convert = FALSE) {
  et_call("plot_conformal_fpca_anomaly", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_conformal_fpca_anomaly_reporting_text <- function(..., .convert = FALSE) {
  et_call("conformal_fpca_anomaly_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_diagnose_fpca_outliers <- function(..., .convert = FALSE) {
  et_call("diagnose_fpca_outliers", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_leave_one_group_out_fpca_influence <- function(..., .convert = FALSE) {
  et_call("leave_one_group_out_fpca_influence", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_component_similarity_matrix <- function(..., .convert = FALSE) {
  et_call("component_similarity_matrix", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_match_fpca_components <- function(..., .convert = FALSE) {
  et_call("match_fpca_components", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_bootstrap_fpca_stability <- function(..., .convert = FALSE) {
  et_call("bootstrap_fpca_stability", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_summarise_fpca_stability <- function(..., .convert = FALSE) {
  et_call("summarise_fpca_stability", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_reconstruction_error_by_curve <- function(..., .convert = FALSE) {
  et_call("reconstruction_error_by_curve", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_reconstruction_curve <- function(..., .convert = FALSE) {
  et_call("fpca_reconstruction_curve", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_simulate_functional_scenario <- function(..., .convert = FALSE) {
  et_call("simulate_functional_scenario", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_expand_functional_simulation_scenarios <- function(..., .convert = FALSE) {
  et_call("expand_functional_simulation_scenarios", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_run_functional_recovery_scenarios <- function(..., .convert = FALSE) {
  et_call("run_functional_recovery_scenarios", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_simulation_scenario_frame <- function(..., .convert = FALSE) {
  et_call("functional_simulation_scenario_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_recovery_frame <- function(..., .convert = FALSE) {
  et_call("functional_recovery_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_recovery_failure_frame <- function(..., .convert = FALSE) {
  et_call("functional_recovery_failure_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_recovery_summary_frame <- function(..., .convert = FALSE) {
  et_call("functional_recovery_summary_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_recovery_metric_catalog <- function(..., .convert = FALSE) {
  et_call("functional_recovery_metric_catalog", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_recovery_metric_catalog_frame <- function(..., .convert = FALSE) {
  et_call("functional_recovery_metric_catalog_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_recovery_reporting_text <- function(..., .convert = FALSE) {
  et_call("functional_recovery_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_functional_recovery_summary <- function(..., .convert = FALSE) {
  et_call("plot_functional_recovery_summary", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_recovery_assessment_frame <- function(..., .convert = FALSE) {
  et_call("functional_recovery_assessment_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_evaluate_fpca_recovery <- function(..., .convert = FALSE) {
  et_call("evaluate_fpca_recovery", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_evaluate_functional_mixed_effects_recovery <- function(..., .convert = FALSE) {
  et_call("evaluate_functional_mixed_effects_recovery", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_evaluate_sparse_fpca_recovery <- function(..., .convert = FALSE) {
  et_call("evaluate_sparse_fpca_recovery", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_evaluate_sparse_mfpca_recovery <- function(..., .convert = FALSE) {
  et_call("evaluate_sparse_mfpca_recovery", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_evaluate_hierarchy_truth_recovery <- function(..., .convert = FALSE) {
  et_call("evaluate_hierarchy_truth_recovery", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_evaluate_registration_recovery <- function(..., .convert = FALSE) {
  et_call("evaluate_registration_recovery", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_recovery_qualification_scenarios <- function(..., .convert = FALSE) {
  et_call("functional_recovery_qualification_scenarios", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_recovery_stress_scenarios <- function(..., .convert = FALSE) {
  et_call("functional_recovery_stress_scenarios", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_recovery_scenario_catalog_frame <- function(..., .convert = FALSE) {
  et_call("functional_recovery_scenario_catalog_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_functional_simulation_curve <- function(..., .convert = FALSE) {
  et_call("plot_functional_simulation_curve", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_functional_simulation_phase_warps <- function(..., .convert = FALSE) {
  et_call("plot_functional_simulation_phase_warps", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_functional_simulation_score_variances <- function(..., .convert = FALSE) {
  et_call("plot_functional_simulation_score_variances", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_simulation_reporting_text <- function(..., .convert = FALSE) {
  et_call("functional_simulation_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_simulation_truth_frame <- function(..., .convert = FALSE) {
  et_call("functional_simulation_truth_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_simulate_functional_process <- function(..., .convert = FALSE) {
  et_call("simulate_functional_process", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_simulate_planar_trajectories <- function(..., .convert = FALSE) {
  et_call("simulate_planar_trajectories", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_simulate_aoi_probability_trajectories <- function(..., .convert = FALSE) {
  et_call("simulate_aoi_probability_trajectories", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_summarise_trajectory_set <- function(..., .convert = FALSE) {
  et_call("summarise_trajectory_set", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_summarise_fpca <- function(..., .convert = FALSE) {
  et_call("summarise_fpca", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_bootstrap_fpca_score_uncertainty <- function(..., .convert = FALSE) {
  et_call("bootstrap_fpca_score_uncertainty", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_score_uncertainty_frame <- function(..., .convert = FALSE) {
  et_call("fpca_score_uncertainty_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_score_uncertainty_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_score_uncertainty_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_bootstrap_fpca_spectrum_uncertainty <- function(..., .convert = FALSE) {
  et_call("bootstrap_fpca_spectrum_uncertainty", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_spectrum_uncertainty_frame <- function(..., .convert = FALSE) {
  et_call("fpca_spectrum_uncertainty_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_spectrum_uncertainty_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_spectrum_uncertainty_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_influence_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_influence_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_outlier_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_outlier_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_stability_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_stability_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_registration_sensitivity_reporting_text <- function(..., .convert = FALSE) {
  et_call("registration_sensitivity_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_multilevel_fpca_reporting_text <- function(..., .convert = FALSE) {
  et_call("multilevel_fpca_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_trajectory_overlay <- function(..., .convert = FALSE) {
  et_call("plot_trajectory_overlay", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_planar_trajectories <- function(..., .convert = FALSE) {
  et_call("plot_planar_trajectories", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_variance <- function(..., .convert = FALSE) {
  et_call("plot_fpca_variance", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_score_uncertainty <- function(..., .convert = FALSE) {
  et_call("plot_fpca_score_uncertainty", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_spectrum_uncertainty <- function(..., .convert = FALSE) {
  et_call("plot_fpca_spectrum_uncertainty", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_stability <- function(..., .convert = FALSE) {
  et_call("plot_fpca_stability", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_reconstruction_curve <- function(..., .convert = FALSE) {
  et_call("plot_reconstruction_curve", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_component <- function(..., .convert = FALSE) {
  et_call("plot_fpca_component", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_influence <- function(..., .convert = FALSE) {
  et_call("plot_fpca_influence", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_outlier_diagnostics <- function(..., .convert = FALSE) {
  et_call("plot_fpca_outlier_diagnostics", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_registration <- function(..., .convert = FALSE) {
  et_call("plot_registration", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_warping_functions <- function(..., .convert = FALSE) {
  et_call("plot_warping_functions", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_to_skfda_grid <- function(..., .convert = FALSE) {
  et_call("to_skfda_grid", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_detect_functional_outliers_skfda <- function(..., .convert = FALSE) {
  et_call("detect_functional_outliers_skfda", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_cross_validate_fpca_reconstruction <- function(..., .convert = FALSE) {
  et_call("cross_validate_fpca_reconstruction", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_summarise_fpca_cross_validation <- function(..., .convert = FALSE) {
  et_call("summarise_fpca_cross_validation", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_select_fpca_components_cv <- function(..., .convert = FALSE) {
  et_call("select_fpca_components_cv", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_bootstrap_fpca_component_bands <- function(..., .convert = FALSE) {
  et_call("bootstrap_fpca_component_bands", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_component_band_frame <- function(..., .convert = FALSE) {
  et_call("fpca_component_band_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_bootstrap_fpca_component_envelopes <- function(..., .convert = FALSE) {
  et_call("bootstrap_fpca_component_envelopes", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_cross_validation <- function(..., .convert = FALSE) {
  et_call("plot_fpca_cross_validation", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_component_band <- function(..., .convert = FALSE) {
  et_call("plot_fpca_component_band", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_component_envelope <- function(..., .convert = FALSE) {
  et_call("plot_fpca_component_envelope", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_cross_validation_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_cross_validation_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_component_band_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_component_band_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_component_envelope_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_component_envelope_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_subspace_stability <- function(..., .convert = FALSE) {
  et_call("plot_fpca_subspace_stability", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_eigengap_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_eigengap_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_subspace_stability_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_subspace_stability_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_eigenvalue_gap_table <- function(..., .convert = FALSE) {
  et_call("fpca_eigenvalue_gap_table", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_compare_fpca_subspaces <- function(..., .convert = FALSE) {
  et_call("compare_fpca_subspaces", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_bootstrap_fpca_subspace_stability <- function(..., .convert = FALSE) {
  et_call("bootstrap_fpca_subspace_stability", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_summarise_fpca_subspace_stability <- function(..., .convert = FALSE) {
  et_call("summarise_fpca_subspace_stability", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_multiplier_functional_mean_band <- function(..., .convert = FALSE) {
  et_call("multiplier_functional_mean_band", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_mean_band_frame <- function(..., .convert = FALSE) {
  et_call("functional_mean_band_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_functional_mean_band <- function(..., .convert = FALSE) {
  et_call("plot_functional_mean_band", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_functional_mean_band_reporting_text <- function(..., .convert = FALSE) {
  et_call("functional_mean_band_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_sparse_mfpca_component <- function(..., .convert = FALSE) {
  et_call("plot_sparse_mfpca_component", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_sparse_mfpca_covariance_blocks <- function(..., .convert = FALSE) {
  et_call("plot_sparse_mfpca_covariance_blocks", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_sparse_mfpca_cross_covariance <- function(..., .convert = FALSE) {
  et_call("plot_sparse_mfpca_cross_covariance", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_sparse_mfpca_score_diagnostics <- function(..., .convert = FALSE) {
  et_call("plot_sparse_mfpca_score_diagnostics", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fit_sparse_mfpca <- function(..., .convert = FALSE) {
  et_call("fit_sparse_mfpca", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_sparse_mfpca_score_frame <- function(..., .convert = FALSE) {
  et_call("sparse_mfpca_score_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_sparse_mfpca_reporting_text <- function(..., .convert = FALSE) {
  et_call("sparse_mfpca_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_sparse_dimension_summary <- function(..., .convert = FALSE) {
  et_call("sparse_dimension_summary", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_to_fdapy_irregular <- function(..., .convert = FALSE) {
  et_call("to_fdapy_irregular", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fit_sparse_fpca <- function(..., .convert = FALSE) {
  et_call("fit_sparse_fpca", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fit_sparse_fpca_fdapy <- function(..., .convert = FALSE) {
  et_call("fit_sparse_fpca_fdapy", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_sparse_fpca_score_frame <- function(..., .convert = FALSE) {
  et_call("sparse_fpca_score_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_sparse_fpca_reporting_text <- function(..., .convert = FALSE) {
  et_call("sparse_fpca_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_sparse_irregular_dimension <- function(..., .convert = FALSE) {
  et_call("plot_sparse_irregular_dimension", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_sparse_fpca_score_diagnostics <- function(..., .convert = FALSE) {
  et_call("plot_sparse_fpca_score_diagnostics", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_sparse_fpca_covariance <- function(..., .convert = FALSE) {
  et_call("plot_sparse_fpca_covariance", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_sparse_fpca_component <- function(..., .convert = FALSE) {
  et_call("plot_sparse_fpca_component", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_bootstrap_fpca_regression_uncertainty <- function(..., .convert = FALSE) {
  et_call("bootstrap_fpca_regression_uncertainty", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_wild_bootstrap_fpca_projection <- function(..., .convert = FALSE) {
  et_call("wild_bootstrap_fpca_projection", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_scan_wild_bootstrap_fpca_truncations <- function(..., .convert = FALSE) {
  et_call("scan_wild_bootstrap_fpca_truncations", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_select_fpca_wild_bootstrap_truncation <- function(..., .convert = FALSE) {
  et_call("select_fpca_wild_bootstrap_truncation", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_wild_bootstrap_truncation_scan_frame <- function(..., .convert = FALSE) {
  et_call("fpca_wild_bootstrap_truncation_scan_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_wild_bootstrap_truncation_selection_frame <- function(..., .convert = FALSE) {
  et_call("fpca_wild_bootstrap_truncation_selection_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_wild_bootstrap_truncation_scan <- function(..., .convert = FALSE) {
  et_call("plot_fpca_wild_bootstrap_truncation_scan", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_wild_bootstrap_truncation_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_wild_bootstrap_truncation_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_wild_bootstrap_projection_frame <- function(..., .convert = FALSE) {
  et_call("fpca_wild_bootstrap_projection_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_wild_bootstrap_projection <- function(..., .convert = FALSE) {
  et_call("plot_fpca_wild_bootstrap_projection", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_wild_bootstrap_projection_family_test <- function(..., .convert = FALSE) {
  et_call("fpca_wild_bootstrap_projection_family_test", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_wild_bootstrap_family_test_frame <- function(..., .convert = FALSE) {
  et_call("fpca_wild_bootstrap_family_test_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_wild_bootstrap_family_test_monte_carlo_diagnostics <- function(..., .convert = FALSE) {
  et_call("fpca_wild_bootstrap_family_test_monte_carlo_diagnostics", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_wild_bootstrap_monte_carlo_diagnostic_frame <- function(..., .convert = FALSE) {
  et_call("fpca_wild_bootstrap_monte_carlo_diagnostic_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_wild_bootstrap_family_test <- function(..., .convert = FALSE) {
  et_call("plot_fpca_wild_bootstrap_family_test", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_wild_bootstrap_monte_carlo_diagnostics <- function(..., .convert = FALSE) {
  et_call("plot_fpca_wild_bootstrap_monte_carlo_diagnostics", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_wild_bootstrap_family_test_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_wild_bootstrap_family_test_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_wild_bootstrap_monte_carlo_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_wild_bootstrap_monte_carlo_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_wild_bootstrap_projection_simultaneous_interval <- function(..., .convert = FALSE) {
  et_call("fpca_wild_bootstrap_projection_simultaneous_interval", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_wild_bootstrap_simultaneous_frame <- function(..., .convert = FALSE) {
  et_call("fpca_wild_bootstrap_simultaneous_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_wild_bootstrap_simultaneous_interval <- function(..., .convert = FALSE) {
  et_call("plot_fpca_wild_bootstrap_simultaneous_interval", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_wild_bootstrap_simultaneous_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_wild_bootstrap_simultaneous_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_wild_bootstrap_projection_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_wild_bootstrap_projection_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_regression_future_prediction_interval <- function(..., .convert = FALSE) {
  et_call("fpca_regression_future_prediction_interval", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_regression_future_prediction_frame <- function(..., .convert = FALSE) {
  et_call("fpca_regression_future_prediction_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_regression_future_prediction_interval <- function(..., .convert = FALSE) {
  et_call("plot_fpca_regression_future_prediction_interval", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_regression_future_prediction_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_regression_future_prediction_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_regression_slope_simultaneous_band <- function(..., .convert = FALSE) {
  et_call("fpca_regression_slope_simultaneous_band", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_regression_slope_band_frame <- function(..., .convert = FALSE) {
  et_call("fpca_regression_slope_band_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_regression_slope_band <- function(..., .convert = FALSE) {
  et_call("plot_fpca_regression_slope_band", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_regression_slope_band_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_regression_slope_band_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_regression_slope_uncertainty_frame <- function(..., .convert = FALSE) {
  et_call("fpca_regression_slope_uncertainty_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_regression_prediction_uncertainty_frame <- function(..., .convert = FALSE) {
  et_call("fpca_regression_prediction_uncertainty_frame", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_regression_slope_uncertainty <- function(..., .convert = FALSE) {
  et_call("plot_fpca_regression_slope_uncertainty", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_regression_mean_prediction_uncertainty <- function(..., .convert = FALSE) {
  et_call("plot_fpca_regression_mean_prediction_uncertainty", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_regression_uncertainty_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_regression_uncertainty_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_cross_validate_fpca_regression <- function(..., .convert = FALSE) {
  et_call("cross_validate_fpca_regression", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_summarise_fpca_regression_cv <- function(..., .convert = FALSE) {
  et_call("summarise_fpca_regression_cv", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_select_fpca_regression_components <- function(..., .convert = FALSE) {
  et_call("select_fpca_regression_components", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_nested_cross_validate_fpca_regression <- function(..., .convert = FALSE) {
  et_call("nested_cross_validate_fpca_regression", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_fpca_regression_cv <- function(..., .convert = FALSE) {
  et_call("plot_fpca_regression_cv", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_plot_nested_fpca_regression_cv <- function(..., .convert = FALSE) {
  et_call("plot_nested_fpca_regression_cv", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_regression_cv_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_regression_cv_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_fpca_nested_regression_cv_reporting_text <- function(..., .convert = FALSE) {
  et_call("fpca_nested_regression_cv_reporting_text", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_to_skfda_basis <- function(..., .convert = FALSE) {
  et_call("to_skfda_basis", ..., .namespace = "root",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_export_workflow_bundle <- function(..., .convert = FALSE) {
  et_call("export_workflow_bundle", ..., .namespace = "workflows",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_run_fpca_workflow <- function(..., .convert = FALSE) {
  et_call("run_fpca_workflow", ..., .namespace = "workflows",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_run_function_on_scalar_workflow <- function(..., .convert = FALSE) {
  et_call("run_function_on_scalar_workflow", ..., .namespace = "workflows",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_run_functional_mixed_effects_workflow <- function(..., .convert = FALSE) {
  et_call("run_functional_mixed_effects_workflow", ..., .namespace = "workflows",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_run_generalized_functional_workflow <- function(..., .convert = FALSE) {
  et_call("run_generalized_functional_workflow", ..., .namespace = "workflows",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_run_recurrence_workflow <- function(..., .convert = FALSE) {
  et_call("run_recurrence_workflow", ..., .namespace = "workflows",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_plot_workflow_result <- function(..., .convert = FALSE) {
  et_call("plot_workflow_result", ..., .namespace = "workflows",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_save_workflow_figure <- function(..., .convert = FALSE) {
  et_call("save_workflow_figure", ..., .namespace = "workflows",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_run_sparse_fpca_workflow <- function(..., .convert = FALSE) {
  et_call("run_sparse_fpca_workflow", ..., .namespace = "workflows",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_run_sparse_mfpca_async_workflow <- function(..., .convert = FALSE) {
  et_call("run_sparse_mfpca_async_workflow", ..., .namespace = "workflows",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_run_sparse_mfpca_workflow <- function(..., .convert = FALSE) {
  et_call("run_sparse_mfpca_workflow", ..., .namespace = "workflows",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_run_sparse_multilevel_workflow <- function(..., .convert = FALSE) {
  et_call("run_sparse_multilevel_workflow", ..., .namespace = "workflows",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_run_sparse_prediction_workflow <- function(..., .convert = FALSE) {
  et_call("run_sparse_prediction_workflow", ..., .namespace = "workflows",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_workflow_config_to_dict <- function(..., .convert = FALSE) {
  et_call("workflow_config_to_dict", ..., .namespace = "workflows",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_workflow_decisions_frame <- function(..., .convert = FALSE) {
  et_call("workflow_decisions_frame", ..., .namespace = "workflows",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_workflow_reporting_text <- function(..., .convert = FALSE) {
  et_call("workflow_reporting_text", ..., .namespace = "workflows",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_workflow_steps_frame <- function(..., .convert = FALSE) {
  et_call("workflow_steps_frame", ..., .namespace = "workflows",
          .convert = .convert)
}

#' @rdname etpy_python_functions
#' @export
etpy_workflow_workflow_summary_frame <- function(..., .convert = FALSE) {
  et_call("workflow_summary_frame", ..., .namespace = "workflows",
          .convert = .convert)
}


#' Catalog of upstream Python publicly exported symbols
#'
#' The catalog is static and does not initialize Python. The source snapshot
#' has 362 root functions, 18 workflow functions and 128 other public symbols.
#' @param include_nonfunctions Include public Python classes and constants.
#' @return A data.frame describing the recorded Python exports.
#' @export
etpy_catalog <- function(include_nonfunctions = FALSE) {
  if (!is.logical(include_nonfunctions) || length(include_nonfunctions) != 1L ||
      is.na(include_nonfunctions))
    stop("include_nonfunctions must be TRUE or FALSE", call. = FALSE)
  nm <- c(.etpy_root_exports, .etpy_workflow_exports)
  ns <- c(rep("root", length(.etpy_root_exports)),
          rep("workflows", length(.etpy_workflow_exports)))
  kind <- ifelse(grepl("^[a-z]", nm), "function", "other_export")
  r_name <- ifelse(kind == "function",
    ifelse(ns == "root", paste0("etpy_", nm), paste0("etpy_workflow_", nm)),
    NA_character_)
  result <- data.frame(namespace = ns, python_name = nm, kind = kind,
                       r_wrapper = r_name,
                       source_git_sha = .etpy_upstream_commit,
                       stringsAsFactors = FALSE)
  if (!include_nonfunctions)
    result <- result[result$kind == "function", , drop = FALSE]
  rownames(result) <- NULL
  result
}

#' Compare the recorded Python API with the installed Python distribution
#'
#' This initializes Python. It checks structural callability but does not
#' execute any scientific algorithm or qualify inferential calibration.
#' @param include_nonfunctions Verify classes/constants too.
#' @param strict Stop when an export is absent or noncallable.
#' @return A catalog with available, callable and Python version columns.
#' @export
etpy_verify_api <- function(include_nonfunctions = FALSE, strict = FALSE) {
  if (!is.logical(strict) || length(strict) != 1L || is.na(strict))
    stop("strict must be TRUE or FALSE", call. = FALSE)
  result <- etpy_catalog(include_nonfunctions = include_nonfunctions)
  result$available <- FALSE
  result$callable <- NA
  for (ns in c("root", "workflows")) {
    module <- .et_import(ns)
    exports <- reticulate::py_to_r(reticulate::py_get_attr(module, "__all__"))
    which_ns <- which(result$namespace == ns)
    result$available[which_ns] <- vapply(result$python_name[which_ns],
      function(n) n %in% exports && reticulate::py_has_attr(module, n),
      logical(1))
    active <- which_ns[result$available[which_ns] &
                       result$kind[which_ns] == "function"]
    if (length(active)) {
      # Python's builtins.callable() is stable across supported reticulate
      # versions; reticulate::py_is_callable() is not a public export.
      py_callable <- reticulate::import_builtins(convert = FALSE)$callable
      result$callable[active] <- vapply(result$python_name[active],
        function(n) isTRUE(reticulate::py_to_r(
          py_callable(reticulate::py_get_attr(module, n)))), logical(1))
    }
  }
  result$installed_python_version <- et_python_version()
  bad <- !result$available |
    (result$kind == "function" & !is.na(result$callable) & !result$callable)
  if (strict && any(bad))
    stop("Installed Python export mismatch: ",
         paste(utils::head(result$python_name[bad], 12L), collapse = ", "),
         if (sum(bad) > 12L) " ...", call. = FALSE)
  result
}

#' Return any installed Python public class, constant or function without calling it
#' @param name Public Python symbol name.
#' @param .namespace Either root or workflows.
#' @param .convert Explicit conversion of the result into R.
#' @return A Python object or an explicitly converted R object.
#' @export
etpy_get_export <- function(name, .namespace = c("root", "workflows"),
                            .convert = FALSE) {
  if (!is.character(name) || length(name) != 1L || is.na(name) ||
      !grepl("^[A-Za-z][A-Za-z0-9_]*$", name))
    stop("name must be a single public Python identifier", call. = FALSE)
  .namespace <- match.arg(.namespace)
  if (!is.logical(.convert) || length(.convert) != 1L || is.na(.convert))
    stop(".convert must be TRUE or FALSE", call. = FALSE)
  module <- .et_import(.namespace)
  exports <- reticulate::py_to_r(reticulate::py_get_attr(module, "__all__"))
  if (!name %in% exports)
    stop("Python symbol '", name, "' not in installed public exports", call. = FALSE)
  value <- reticulate::py_get_attr(module, name)
  if (.convert) reticulate::py_to_r(value) else value
}
