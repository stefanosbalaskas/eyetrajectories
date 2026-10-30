# Strict full-native R parity register: 508 distinct Python public exports.
# Native algorithm equivalence must be proven per contract and never
# inferred solely from a matching name, bridge, or callable R symbol.
# This catalog is offline: it does not initialize Python/reticulate.

.etr_known_native_analogues <- function() c(
  from_long_dataframe="etr_from_long",
  validate_trajectory_set="etr_validate",
  resample_to_grid="etr_resample",
  interpolate_short_gaps="etr_interpolate_gaps",
  smooth_trajectories="etr_smooth",
  normalize_time="etr_normalize_time_interval",
  normalize_coordinates="etr_normalize_coordinates",
  center_on_landmark="etr_center_on_landmark",
  differentiate_trajectories="etr_velocity",
  speed_function="etr_speed",
  heading_function="etr_heading_function",
  cumulative_path_length="etr_cumulative_path_length",
  trajectory_tortuosity="etr_trajectory_tortuosity_frame",
  functional_l2_distance="etr_l2_distance",
  discrete_frechet_distance="etr_discrete_frechet",
  dynamic_time_warping_distance="etr_dynamic_time_warping",
  pairwise_dynamic_time_warping_distances="etr_pairwise_dtw_full",
  load_portable_result="etr_read_python_portable_result",
  validate_common_grid="etr_validate_common_grid",
  validate_simplex="etr_validate_simplex",
  validate_no_long_missing_runs="etr_validate_no_long_missing_runs",
  from_irregular_long_dataframe_native="etr_from_irregular_long_native",
  common_overlap_interval="etr_common_overlap_interval",
  make_common_grid="etr_make_common_grid",
  resample_irregular_to_grid="etr_resample_irregular_to_grid",
  resample_irregular_to_common_grid="etr_resample_irregular_to_common_grid",
  irregular_sampling_summary="etr_irregular_sampling_summary",
  phase_landmark_frame="etr_phase_landmark_frame",
  pairwise_discrete_frechet_distances="etr_pairwise_frechet",
  nearest_trajectory_indices="etr_nearest_trajectory_indices",
  functional_trapezoid_weights="etr_trapezoid_weights",
  fit_fpca="etr_fit_fpca",
  fit_mfpca="etr_fit_mfpca",
  transform_fpca="etr_transform_fpca",
  reconstruct_fpca="etr_reconstruct_fpca",
  recurrence_matrix="etr_recurrence_matrix",
  cross_recurrence_matrix="etr_cross_recurrence_matrix",
  rqa_metrics="etr_rqa_metrics",
  plot_trajectory_overlay="etr_plot_trajectories",
  plot_fpca_variance="etr_plot_fpca_variance",
  plot_recurrence="etr_plot_recurrence",
  fit_sparse_fpca="etr_fit_sparse_pace",
  fit_multilevel_fpca="etr_fit_multilevel_fpca",
  fit_functional_mixed_effects_regression="etr_fit_functional_mixed_effects_regression",
  fit_scalar_on_function_regression="etr_fit_scalar_on_fpca",
  register_to_landmarks="etr_register_landmarks",
  delay_embed_trajectory="etr_delay_embed_trajectory",
  poincare_crossings="etr_poincare_crossings",
  recurrence_network="etr_recurrence_network",
  recurrence_network_node_frame="etr_recurrence_network_node_frame",
  recurrence_network_summary_frame="etr_recurrence_network_summary_frame",
  joint_recurrence_matrix="etr_joint_recurrence_matrix",
  joint_recurrence_component_frame="etr_joint_recurrence_component_frame",
  joint_rqa_metrics="etr_joint_rqa_metrics",
  cross_rqa_metrics="etr_cross_rqa_metrics",
  recurrence_radius_profile="etr_recurrence_radius_profile",
  windowed_rqa="etr_windowed_rqa",
  windowed_rqa_trajectory_set="etr_windowed_rqa_trajectory_set",
  alr_transform="etr_alr_transform",
  inverse_alr="etr_inverse_alr",
  component_trajectories="etr_component_trajectories",
  select_n_components="etr_select_n_components",
  fpca_score_frame="etr_fpca_score_frame",
  score_distance_matrix="etr_score_distance_matrix",
  pairwise_functional_distances="etr_pairwise_functional_distances",
  sparse_dimension_summary="etr_sparse_dimension_summary",
  warping_displacement="etr_warping_displacement",
  phase_summary="etr_phase_summary",
  phase_trajectory_set="etr_phase_trajectory_set",
  fit_phase_fpca="etr_fit_phase_fpca",
  fit_compositional_fpca="etr_fit_compositional_fpca",
  reconstruct_compositional_fpca="etr_reconstruct_compositional_fpca",
  component_similarity_matrix="etr_component_similarity_matrix",
  match_fpca_components="etr_match_fpca_components",
  reconstruction_error_by_curve="etr_reconstruction_error_by_curve",
  fpca_reconstruction_curve="etr_fpca_reconstruction_curve",
  compare_registered_unregistered_fpca="etr_compare_registered_unregistered_fpca",
  registration_sensitivity_frame="etr_registration_sensitivity_frame",
  summarise_trajectory_set="etr_summarise_trajectory_set",
  summarise_fpca="etr_summarise_fpca",
  fpca_reporting_text="etr_fpca_reporting_text",
  fpca_eigenvalue_gap_table="etr_fpca_eigenvalue_gap_table",
  fpca_eigengap_reporting_text="etr_fpca_eigengap_reporting_text",
  registration_sensitivity_reporting_text="etr_registration_sensitivity_reporting_text",
  functional_mean_band_frame="etr_functional_mean_band_frame",
  joint_recurrence_reporting_text="etr_joint_recurrence_reporting_text",
  recurrence_network_reporting_text="etr_recurrence_network_reporting_text",
  recurrence_radius_profile_reporting_text="etr_recurrence_radius_profile_reporting_text",
  rqa_reporting_text="etr_rqa_reporting_text",
  rqa_metric_mean_bootstrap_reporting_text="etr_rqa_metric_mean_bootstrap_reporting_text",
  windowed_rqa_reporting_text="etr_windowed_rqa_reporting_text",
  windowed_rqa_functional_reporting_text="etr_windowed_rqa_functional_reporting_text",
  windowed_rqa_sensitivity_reporting_text="etr_windowed_rqa_sensitivity_reporting_text",
  windowed_rqa_mean_band_reporting_text="etr_windowed_rqa_mean_band_reporting_text",
  rqa_parameter_sensitivity_reporting_text="etr_rqa_parameter_sensitivity_reporting_text",
  kantz_parameter_sensitivity_reporting_text="etr_kantz_parameter_sensitivity_reporting_text",
  lyapunov_parameter_sensitivity_reporting_text="etr_lyapunov_parameter_sensitivity_reporting_text",
  largest_lyapunov_reporting_text="etr_largest_lyapunov_reporting_text",
  surrogate_nonlinearity_reporting_text="etr_surrogate_nonlinearity_reporting_text",
  return_map_stability_reporting_text="etr_return_map_stability_reporting_text",
  cross_validate_fpca_reconstruction="etr_cross_validate_fpca_reconstruction",
  summarise_fpca_cross_validation="etr_summarise_fpca_cross_validation",
  select_fpca_components_cv="etr_select_fpca_components_cv",
  summarise_fpca_regression_cv="etr_summarise_fpca_regression_cv",
  select_fpca_regression_components="etr_select_fpca_regression_components",
  fpca_score_uncertainty_frame="etr_fpca_score_uncertainty_frame",
  fpca_spectrum_uncertainty_frame="etr_fpca_spectrum_uncertainty_frame",
  conformal_fpca_anomaly_frame="etr_conformal_fpca_anomaly_frame",
  trajectory_distance_comparison_frame="etr_trajectory_distance_comparison_frame",
  trajectory_distance_neighbor_frame="etr_trajectory_distance_neighbor_frame",
  fpca_regression_slope_band_frame="etr_fpca_regression_slope_band_frame",
  fpca_regression_slope_uncertainty_frame="etr_fpca_regression_slope_uncertainty_frame",
  fpca_regression_prediction_uncertainty_frame="etr_fpca_regression_prediction_uncertainty_frame",
  fpca_regression_future_prediction_frame="etr_fpca_regression_future_prediction_frame",
  fit_function_on_scalar_regression="etr_fit_function_on_scalar_regression",
  bootstrap_function_on_scalar_coefficients="etr_bootstrap_function_on_scalar_coefficients",
  function_on_scalar_simultaneous_bands="etr_function_on_scalar_simultaneous_bands",
  function_on_scalar_coefficient_frame="etr_function_on_scalar_coefficient_frame",
  embedding_delay_diagnostics="etr_embedding_delay_diagnostics",
  embedding_dimension_diagnostics="etr_embedding_dimension_diagnostics",
  return_map_stability="etr_return_map_stability",
  simulate_planar_trajectories="etr_simulate_planar_trajectories",
  simulate_aoi_probability_trajectories="etr_simulate_aoi_probability_trajectories",
  from_irregular_long_dataframe="etr_from_irregular_long_dataframe",
  fit_local_return_map="etr_fit_local_return_map",
  compare_fpca_subspaces="etr_compare_fpca_subspaces",
  bootstrap_fpca_subspace_stability="etr_bootstrap_fpca_subspace_stability",
  summarise_fpca_subspace_stability="etr_summarise_fpca_subspace_stability",
  leave_one_group_out_fpca_influence="etr_leave_one_group_out_fpca_influence",
  bootstrap_fpca_stability="etr_bootstrap_fpca_stability",
  summarise_fpca_stability="etr_summarise_fpca_stability",
  diagnose_fpca_outliers="etr_diagnose_fpca_outliers",
  multiplier_functional_mean_band="etr_multiplier_functional_mean_band",
  bootstrap_fpca_score_uncertainty="etr_bootstrap_fpca_score_uncertainty",
  bootstrap_fpca_spectrum_uncertainty="etr_bootstrap_fpca_spectrum_uncertainty",
  bootstrap_fpca_component_bands="etr_bootstrap_fpca_component_bands",
  fpca_component_band_frame="etr_fpca_component_band_frame",
  discrete_transfer_entropy="etr_discrete_transfer_entropy",
  transfer_entropy_local_frame="etr_transfer_entropy_local_frame",
  transfer_entropy_circular_shift_test="etr_transfer_entropy_circular_shift_test",
  conditional_transfer_entropy="etr_conditional_transfer_entropy",
  conditional_transfer_entropy_local_frame="etr_conditional_transfer_entropy_local_frame",
  conditional_transfer_entropy_circular_shift_test="etr_conditional_transfer_entropy_circular_shift_test",
  transfer_entropy_parameter_sensitivity="etr_transfer_entropy_parameter_sensitivity",
  transfer_entropy_reporting_text="etr_transfer_entropy_reporting_text",
  transfer_entropy_circular_shift_reporting_text="etr_transfer_entropy_circular_shift_reporting_text",
  conditional_transfer_entropy_reporting_text="etr_conditional_transfer_entropy_reporting_text",
  conditional_transfer_entropy_circular_shift_reporting_text="etr_conditional_transfer_entropy_circular_shift_reporting_text",
  transfer_entropy_parameter_sensitivity_reporting_text="etr_transfer_entropy_parameter_sensitivity_reporting_text",
  local_divergence_curve="etr_local_divergence_curve",
  kantz_divergence_curve="etr_kantz_divergence_curve",
  estimate_largest_lyapunov_rosenstein="etr_estimate_largest_lyapunov_rosenstein",
  estimate_largest_lyapunov_kantz="etr_estimate_largest_lyapunov_kantz",
  bootstrap_rqa_metric_means="etr_bootstrap_rqa_metric_means",
  functional_mixed_effects_whitened_residuals="etr_functional_mixed_effects_whitened_residuals",
  functional_mixed_effects_residual_diagnostics="etr_functional_mixed_effects_residual_diagnostics",
  functional_mixed_effects_residual_diagnostic_frame="etr_functional_mixed_effects_residual_diagnostic_frame",
  functional_mixed_effects_residual_pair_frame="etr_functional_mixed_effects_residual_pair_frame",
  functional_mixed_effects_variance_decomposition="etr_functional_mixed_effects_variance_decomposition",
  functional_mixed_effects_coefficient_frame="etr_functional_mixed_effects_coefficient_frame",
  lyapunov_parameter_sensitivity="etr_lyapunov_parameter_sensitivity",
  kantz_parameter_sensitivity="etr_kantz_parameter_sensitivity",
  rqa_parameter_sensitivity="etr_rqa_parameter_sensitivity",
  cluster_fpca_scores="etr_cluster_fpca_scores",
  trajectory_distance_sensitivity="etr_trajectory_distance_sensitivity",
  surrogate_nonlinearity_test="etr_surrogate_nonlinearity_test",
  plot_planar_trajectories="etr_plot_planar_trajectories",
  plot_fpca_component="etr_plot_fpca_component",
  plot_dynamic_time_warping_alignment="etr_plot_dynamic_time_warping_alignment",
  plot_trajectory_distance_rank_correlations="etr_plot_trajectory_distance_rank_correlations",
  plot_embedding_delay_diagnostics="etr_plot_embedding_delay_diagnostics",
  plot_embedding_dimension_diagnostics="etr_plot_embedding_dimension_diagnostics",
  plot_recurrence_network_degree="etr_plot_recurrence_network_degree",
  plot_recurrence_rate_curve="etr_plot_recurrence_rate_curve",
  plot_windowed_rqa="etr_plot_windowed_rqa",
  plot_local_divergence="etr_plot_local_divergence",
  plot_surrogate_nonlinearity="etr_plot_surrogate_nonlinearity",
  plot_poincare_return_map="etr_plot_poincare_return_map",
  dynamic_time_warping_reporting_text="etr_dynamic_time_warping_reporting_text",
  trajectory_distance_sensitivity_reporting_text="etr_trajectory_distance_sensitivity_reporting_text",
  fpca_stability_reporting_text="etr_fpca_stability_reporting_text",
  fpca_outlier_reporting_text="etr_fpca_outlier_reporting_text",
  fpca_influence_reporting_text="etr_fpca_influence_reporting_text",
  fpca_subspace_stability_reporting_text="etr_fpca_subspace_stability_reporting_text",
  fpca_cross_validation_reporting_text="etr_fpca_cross_validation_reporting_text",
  multilevel_fpca_reporting_text="etr_multilevel_fpca_reporting_text",
  plot_fpca_stability="etr_plot_fpca_stability",
  plot_fpca_influence="etr_plot_fpca_influence",
  plot_fpca_outlier_diagnostics="etr_plot_fpca_outlier_diagnostics",
  plot_fpca_cross_validation="etr_plot_fpca_cross_validation",
  plot_fpca_subspace_stability="etr_plot_fpca_subspace_stability",
  plot_functional_mean_band="etr_plot_functional_mean_band",
  plot_joint_recurrence="etr_plot_joint_recurrence",
  plot_windowed_rqa_trajectories="etr_plot_windowed_rqa_trajectories",
  plot_rqa_sensitivity="etr_plot_rqa_sensitivity",
  windowed_rqa_sensitivity="etr_windowed_rqa_sensitivity",
  windowed_rqa_functional_mean_band="etr_windowed_rqa_functional_mean_band",
  functional_recovery_metric_catalog="etr_functional_recovery_metric_catalog",
  functional_recovery_metric_catalog_frame="etr_functional_recovery_metric_catalog_frame",
  functional_recovery_reporting_text="etr_functional_recovery_reporting_text",
  fpca_score_uncertainty_reporting_text="etr_fpca_score_uncertainty_reporting_text",
  fpca_spectrum_uncertainty_reporting_text="etr_fpca_spectrum_uncertainty_reporting_text",
  functional_mean_band_reporting_text="etr_functional_mean_band_reporting_text",
  fpca_component_band_reporting_text="etr_fpca_component_band_reporting_text",
  plot_fpca_score_uncertainty="etr_plot_fpca_score_uncertainty",
  plot_fpca_spectrum_uncertainty="etr_plot_fpca_spectrum_uncertainty",
  plot_fpca_component_band="etr_plot_fpca_component_band",
  list_mathematical_contracts="etr_list_mathematical_contracts",
  get_mathematical_contract="etr_get_mathematical_contract",
  mathematical_contract_frame="etr_mathematical_contract_frame",
  plot_kantz_sensitivity="etr_plot_kantz_sensitivity",
  plot_lyapunov_sensitivity="etr_plot_lyapunov_sensitivity",
  plot_windowed_rqa_sensitivity="etr_plot_windowed_rqa_sensitivity",
  plot_transfer_entropy_sensitivity="etr_plot_transfer_entropy_sensitivity",
  plot_transfer_entropy_circular_shift_test="etr_plot_transfer_entropy_circular_shift_test",
  plot_conditional_transfer_entropy_circular_shift_test="etr_plot_conditional_transfer_entropy_circular_shift_test",
  plot_reconstruction_curve="etr_plot_reconstruction_curve",
  plot_registration="etr_plot_registration",
  plot_warping_functions="etr_plot_warping_functions",
  plot_function_on_scalar_coefficients="etr_plot_function_on_scalar_coefficients",
  function_on_scalar_reporting_text="etr_function_on_scalar_reporting_text",
  plot_functional_mixed_effects_coefficient="etr_plot_functional_mixed_effects_coefficient",
  plot_conformal_fpca_anomaly="etr_plot_conformal_fpca_anomaly",
  conformal_fpca_anomaly_reporting_text="etr_conformal_fpca_anomaly_reporting_text",
  plot_rqa_metric_mean_bootstrap="etr_plot_rqa_metric_mean_bootstrap",
  plot_functional_variance_decomposition="etr_plot_functional_variance_decomposition",
  functional_recovery_frame="etr_functional_recovery_frame",
  functional_recovery_failure_frame="etr_functional_recovery_failure_frame",
  functional_recovery_summary_frame="etr_functional_recovery_summary_frame",
  plot_functional_recovery_summary="etr_plot_functional_recovery_summary",
  functional_recovery_assessment_frame="etr_functional_recovery_assessment_frame",
  split_conformal_fpca_anomaly="etr_split_conformal_fpca_anomalies",
  # These four new native methods are experimentally implemented here.
  acceleration_magnitude_function="etr_acceleration_magnitude",
  distance_to_landmark_function="etr_distance_to_landmark",
  signed_curvature_function="etr_signed_curvature",
  turning_rate_function="etr_turning_rate",
  workflow_steps_frame="etr_workflow_steps_frame",
  workflow_decisions_frame="etr_workflow_decisions_frame",
  workflow_summary_frame="etr_workflow_summary_frame",
  workflow_reporting_text="etr_workflow_reporting_text",
  workflow_config_to_dict="etr_workflow_config_to_dict",
  functional_simulation_scenario_frame="etr_functional_simulation_scenario_frame",
  expand_functional_simulation_scenarios="etr_expand_functional_simulation_scenarios",
  functional_recovery_qualification_scenarios="etr_functional_recovery_qualification_scenarios",
  functional_recovery_stress_scenarios="etr_functional_recovery_stress_scenarios",
  functional_recovery_scenario_catalog_frame="etr_functional_recovery_scenario_catalog_frame",
  functional_simulation_truth_frame="etr_functional_simulation_truth_frame",
  functional_simulation_reporting_text="etr_functional_simulation_reporting_text",
  plot_functional_simulation_curve="etr_plot_functional_simulation_curve",
  plot_functional_simulation_phase_warps="etr_plot_functional_simulation_phase_warps",
  plot_functional_simulation_score_variances="etr_plot_functional_simulation_score_variances",
  functional_random_effect_frame="etr_functional_random_effect_frame",
  functional_trial_random_effect_frame="etr_functional_trial_random_effect_frame",
  functional_mixed_effects_full_refit_audit_frame="etr_functional_mixed_effects_full_refit_audit_frame",
  functional_mixed_effects_full_refit_trial_audit_frame="etr_functional_mixed_effects_full_refit_trial_audit_frame",
  fpca_wild_bootstrap_truncation_scan_frame="etr_fpca_wild_bootstrap_truncation_scan_frame",
  fpca_wild_bootstrap_truncation_selection_frame="etr_fpca_wild_bootstrap_truncation_selection_frame",
  plot_functional_random_effects="etr_plot_functional_random_effects",
  plot_functional_trial_random_effects="etr_plot_functional_trial_random_effects",
  plot_fpca_regression_cv="etr_plot_fpca_regression_cv",
  plot_nested_fpca_regression_cv="etr_plot_nested_fpca_regression_cv",
  plot_functional_mixed_effects_bootstrap_comparison="etr_plot_functional_mixed_effects_bootstrap_comparison",
  plot_fpca_wild_bootstrap_truncation_scan="etr_plot_fpca_wild_bootstrap_truncation_scan",
  plot_fpca_wild_bootstrap_projection="etr_plot_fpca_wild_bootstrap_projection",
  plot_fpca_regression_future_prediction_interval="etr_plot_fpca_regression_future_prediction_interval",
  plot_fpca_regression_mean_prediction_uncertainty="etr_plot_fpca_regression_mean_prediction_uncertainty",
  plot_fpca_regression_slope_band="etr_plot_fpca_regression_slope_band",
  plot_fpca_regression_slope_uncertainty="etr_plot_fpca_regression_slope_uncertainty",
  plot_sparse_fpca_score_diagnostics="etr_plot_sparse_fpca_score_diagnostics",
  select_fpca_wild_bootstrap_truncation="etr_select_fpca_wild_bootstrap_truncation",
  fpca_wild_bootstrap_projection_frame="etr_fpca_wild_bootstrap_projection_frame",
  fpca_wild_bootstrap_simultaneous_frame="etr_fpca_wild_bootstrap_simultaneous_frame",
  fpca_wild_bootstrap_family_test_frame="etr_fpca_wild_bootstrap_family_test_frame",
  fpca_wild_bootstrap_monte_carlo_diagnostic_frame="etr_fpca_wild_bootstrap_monte_carlo_diagnostic_frame",
  fpca_wild_bootstrap_projection_reporting_text="etr_fpca_wild_bootstrap_projection_reporting_text",
  fpca_regression_future_prediction_reporting_text="etr_fpca_regression_future_prediction_reporting_text",
  fpca_regression_uncertainty_reporting_text="etr_fpca_regression_uncertainty_reporting_text",
  fpca_regression_slope_band_reporting_text="etr_fpca_regression_slope_band_reporting_text",
  fpca_nested_regression_cv_reporting_text="etr_fpca_nested_regression_cv_reporting_text",
  fpca_wild_bootstrap_family_test_reporting_text="etr_fpca_wild_bootstrap_family_test_reporting_text",
  fpca_wild_bootstrap_monte_carlo_reporting_text="etr_fpca_wild_bootstrap_monte_carlo_reporting_text",
  fpca_wild_bootstrap_simultaneous_reporting_text="etr_fpca_wild_bootstrap_simultaneous_reporting_text",
  fpca_regression_cv_reporting_text="etr_fpca_regression_cv_reporting_text",
  fpca_component_envelope_reporting_text="etr_fpca_component_envelope_reporting_text",
  fpca_wild_bootstrap_truncation_reporting_text="etr_fpca_wild_bootstrap_truncation_reporting_text"
)

#' Audit one-to-one Python 1.2.0 versus independent native R coverage
#'
#' A conservative, non-Python-initializing registry covering all 508 public
#' Python root/workflow exports, including 380 functions and 128 classes,
#' constants and configuration types. Distinguishes the previously available
#' Python-backed R bridge from actual native R implementations and flags all
#' numerical/scientific equivalence as UNQUALIFIED pending independent tests.
#'
#' @param require_complete If TRUE, stop unless every public Python symbol
#'   has a fully verified native-R contract. This gate is expected to fail
#'   during ongoing porting work.
#' @return A 508-row data frame of public API records and native statuses.
#' @export
etr_native_parity_catalog <- function(require_complete=FALSE) {
  .etr_assert(is.logical(require_complete) &&
    length(require_complete)==1L && !is.na(require_complete),
    "require_complete must be TRUE or FALSE")
  api <- etpy_catalog(include_nonfunctions=TRUE)
  .etr_assert(nrow(api)==508L &&
    sum(api$kind=="function")==380L &&
    sum(api$kind!="function")==128L,
    "Unexpected frozen Python public API; refresh manifest before porting")
  analogues <- .etr_known_native_analogues()
  .etr_assert(!anyDuplicated(names(analogues)) &&
    all(names(analogues) %in% api$python_name[api$kind=="function"]),
    "Native analogy map contains duplicate or unknown public Python functions")
  exports <- getNamespaceExports("eyetrajectories")
  .etr_assert(all(unname(analogues) %in% exports),
    "A declared native candidate is not exported by the R package")

  api$native_r_candidate <- unname(analogues[api$python_name])
  api$native_r_candidate[is.na(api$native_r_candidate)] <- ""
  api$named_native_candidate <- nzchar(api$native_r_candidate)
  api$is_python_function <- api$kind=="function"
  api$python_bridge_available <-
    ifelse(api$is_python_function,
      nzchar(api$r_wrapper),TRUE)  # classes/constants use etpy_get_export
  integration_group_2_names <- c("acceleration_magnitude_function",
                    "distance_to_landmark_function",
                    "signed_curvature_function","turning_rate_function")
  integration_group_3_names <- c("normalize_coordinates","center_on_landmark",
                    "normalize_time","heading_function",
                    "trajectory_tortuosity",
                    "pairwise_discrete_frechet_distances",
                    "nearest_trajectory_indices")
  integration_group_4_names <- c("discrete_frechet_distance",
                    "dynamic_time_warping_distance",
                    "pairwise_dynamic_time_warping_distances")
  integration_group_6_names <- "load_portable_result"
  integration_group_7_names <- c(
    "validate_common_grid","validate_simplex",
    "validate_no_long_missing_runs",
    "from_irregular_long_dataframe_native",
    "common_overlap_interval","make_common_grid",
    "resample_irregular_to_grid",
    "resample_irregular_to_common_grid",
    "irregular_sampling_summary","phase_landmark_frame")
  integration_group_8_names <- c(
    "recurrence_network","recurrence_network_node_frame",
    "recurrence_network_summary_frame",
    "joint_recurrence_matrix","joint_recurrence_component_frame",
    "joint_rqa_metrics","cross_rqa_metrics",
    "recurrence_radius_profile","windowed_rqa",
    "windowed_rqa_trajectory_set")
  api$native_implementation_stage <- ifelse(
      api$is_python_function & api$python_name %in% integration_group_2_names,2L,
      ifelse(api$is_python_function & api$python_name %in% integration_group_3_names,3L,
        ifelse(api$is_python_function & api$python_name %in% integration_group_4_names,4L,
          ifelse(api$is_python_function & api$python_name %in% integration_group_6_names,
            6L,ifelse(api$is_python_function &
              api$python_name %in% integration_group_7_names,7L,
              ifelse(api$is_python_function &
                api$python_name %in% integration_group_8_names,8L,NA_integer_))))))
  composition_and_score_integration_names <- c("alr_transform","inverse_alr","component_trajectories",
    "select_n_components","fpca_score_frame","score_distance_matrix",
    "pairwise_functional_distances","sparse_dimension_summary",
    "warping_displacement","phase_summary","phase_trajectory_set",
    "fit_phase_fpca")
  api$native_implementation_stage[api$python_name %in% composition_and_score_integration_names &
    api$is_python_function] <- 9L
  integration_group_10_names <- c("fit_compositional_fpca","reconstruct_compositional_fpca",
    "component_similarity_matrix","match_fpca_components",
    "reconstruction_error_by_curve","fpca_reconstruction_curve",
    "compare_registered_unregistered_fpca","registration_sensitivity_frame",
    "summarise_trajectory_set","summarise_fpca","fpca_reporting_text",
    "fpca_eigenvalue_gap_table","fpca_eigengap_reporting_text",
    "registration_sensitivity_reporting_text","functional_mean_band_frame")
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_10_names] <- 10L
  integration_group_11_names <- c("joint_recurrence_reporting_text","recurrence_network_reporting_text","recurrence_radius_profile_reporting_text","rqa_reporting_text","rqa_metric_mean_bootstrap_reporting_text","windowed_rqa_reporting_text","windowed_rqa_functional_reporting_text","windowed_rqa_sensitivity_reporting_text","windowed_rqa_mean_band_reporting_text","rqa_parameter_sensitivity_reporting_text","kantz_parameter_sensitivity_reporting_text","lyapunov_parameter_sensitivity_reporting_text","largest_lyapunov_reporting_text","surrogate_nonlinearity_reporting_text","return_map_stability_reporting_text")
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_11_names] <- 11L
  integration_group_12_names <- c("cross_validate_fpca_reconstruction","summarise_fpca_cross_validation","select_fpca_components_cv","summarise_fpca_regression_cv","select_fpca_regression_components","fpca_score_uncertainty_frame","fpca_spectrum_uncertainty_frame","conformal_fpca_anomaly_frame","trajectory_distance_comparison_frame","trajectory_distance_neighbor_frame","fpca_regression_slope_band_frame","fpca_regression_slope_uncertainty_frame","fpca_regression_prediction_uncertainty_frame","fpca_regression_future_prediction_frame")
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_12_names] <- 12L
  integration_group_13_names <- c("poincare_crossings","fit_local_return_map","fit_function_on_scalar_regression","bootstrap_function_on_scalar_coefficients","function_on_scalar_simultaneous_bands","function_on_scalar_coefficient_frame","embedding_delay_diagnostics","embedding_dimension_diagnostics","return_map_stability","simulate_planar_trajectories","simulate_aoi_probability_trajectories","from_irregular_long_dataframe")
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_13_names] <- 13L
  integration_group_14_names <- c("compare_fpca_subspaces","bootstrap_fpca_subspace_stability","summarise_fpca_subspace_stability","leave_one_group_out_fpca_influence","bootstrap_fpca_stability","summarise_fpca_stability","diagnose_fpca_outliers")
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_14_names] <- 14L
  integration_group_15_names <- c("multiplier_functional_mean_band","bootstrap_fpca_score_uncertainty","bootstrap_fpca_spectrum_uncertainty","bootstrap_fpca_component_bands","fpca_component_band_frame")
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_15_names] <- 15L
  integration_group_16_names <- c("discrete_transfer_entropy","transfer_entropy_local_frame","transfer_entropy_circular_shift_test","conditional_transfer_entropy","conditional_transfer_entropy_local_frame","conditional_transfer_entropy_circular_shift_test","transfer_entropy_parameter_sensitivity","transfer_entropy_reporting_text","transfer_entropy_circular_shift_reporting_text","conditional_transfer_entropy_reporting_text","conditional_transfer_entropy_circular_shift_reporting_text","transfer_entropy_parameter_sensitivity_reporting_text")
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_16_names] <- 16L
  integration_group_17_names <- c("delay_embed_trajectory","local_divergence_curve","kantz_divergence_curve","estimate_largest_lyapunov_rosenstein","estimate_largest_lyapunov_kantz","bootstrap_rqa_metric_means")
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_17_names] <- 17L
  integration_group_18_names <- c("fit_functional_mixed_effects_regression","functional_mixed_effects_whitened_residuals","functional_mixed_effects_residual_diagnostics","functional_mixed_effects_residual_diagnostic_frame","functional_mixed_effects_residual_pair_frame","functional_mixed_effects_variance_decomposition","functional_mixed_effects_coefficient_frame")
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_18_names] <- 18L
  integration_group_19_names <- c("lyapunov_parameter_sensitivity","kantz_parameter_sensitivity","rqa_parameter_sensitivity","cluster_fpca_scores","trajectory_distance_sensitivity")
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_19_names] <- 19L
  integration_group_20_names <- "surrogate_nonlinearity_test"
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_20_names] <- 20L
  integration_group_21_names <- c("plot_planar_trajectories","plot_fpca_component",
    "plot_dynamic_time_warping_alignment",
    "plot_trajectory_distance_rank_correlations")
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_21_names] <- 21L
  integration_group_22_names <- c(
    "plot_embedding_delay_diagnostics",
    "plot_embedding_dimension_diagnostics",
    "plot_recurrence_network_degree",
    "plot_recurrence_rate_curve",
    "plot_windowed_rqa",
    "plot_local_divergence",
    "plot_surrogate_nonlinearity",
    "plot_poincare_return_map"
  )
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_22_names] <- 22L
  integration_group_23_names <- c(
    "dynamic_time_warping_reporting_text",
    "trajectory_distance_sensitivity_reporting_text",
    "fpca_stability_reporting_text",
    "fpca_outlier_reporting_text",
    "fpca_influence_reporting_text",
    "fpca_subspace_stability_reporting_text",
    "fpca_cross_validation_reporting_text",
    "multilevel_fpca_reporting_text"
  )
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_23_names] <- 23L
  integration_group_24_names <- c(
    "plot_fpca_stability",
    "plot_fpca_influence",
    "plot_fpca_outlier_diagnostics",
    "plot_fpca_cross_validation",
    "plot_fpca_subspace_stability",
    "plot_functional_mean_band",
    "plot_joint_recurrence",
    "plot_windowed_rqa_trajectories",
    "plot_rqa_sensitivity"
  )
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_24_names] <- 24L
  integration_group_26_names <- c(
    "windowed_rqa_sensitivity",
    "windowed_rqa_functional_mean_band",
    "functional_recovery_metric_catalog",
    "functional_recovery_metric_catalog_frame",
    "functional_recovery_reporting_text",
    "functional_recovery_assessment_frame"
  )
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_26_names] <- 26L
  integration_group_27_names <- c(
    "fpca_score_uncertainty_reporting_text",
    "fpca_spectrum_uncertainty_reporting_text",
    "functional_mean_band_reporting_text",
    "fpca_component_band_reporting_text",
    "plot_fpca_score_uncertainty",
    "plot_fpca_spectrum_uncertainty",
    "plot_fpca_component_band"
  )
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_27_names] <- 27L
  integration_group_28_names <- c(
    "list_mathematical_contracts",
    "get_mathematical_contract",
    "mathematical_contract_frame",
    "plot_kantz_sensitivity",
    "plot_lyapunov_sensitivity",
    "plot_windowed_rqa_sensitivity"
  )
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_28_names] <- 28L
  integration_group_29_names <- c(
    "plot_transfer_entropy_sensitivity",
    "plot_transfer_entropy_circular_shift_test",
    "plot_conditional_transfer_entropy_circular_shift_test"
  )
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% integration_group_29_names] <- 29L
  # Historical implementation provenance only: never part of public function names.
  registration_plot_names <- c("plot_reconstruction_curve",
    "plot_registration","plot_warping_functions")
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% registration_plot_names] <- 30L
  inference_visual_names <- c(
    "plot_function_on_scalar_coefficients",
    "function_on_scalar_reporting_text",
    "plot_functional_mixed_effects_coefficient",
    "plot_conformal_fpca_anomaly",
    "conformal_fpca_anomaly_reporting_text",
    "plot_rqa_metric_mean_bootstrap",
    "plot_functional_variance_decomposition"
  )
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% inference_visual_names] <- 31L
  recovery_evidence_names <- c(
    "functional_recovery_frame",
    "functional_recovery_failure_frame",
    "functional_recovery_summary_frame",
    "plot_functional_recovery_summary"
  )
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% recovery_evidence_names] <- 32L
  # Historical ledger provenance; public functions themselves are stage-free.
  workflow_audit_names <- c("workflow_steps_frame",
    "workflow_decisions_frame","workflow_summary_frame",
    "workflow_reporting_text")
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% workflow_audit_names] <- 33L
  api$native_implementation_stage[api$is_python_function &
    api$python_name=="workflow_config_to_dict"] <- 34L
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% c("functional_simulation_scenario_frame",
      "expand_functional_simulation_scenarios")] <- 35L
  api$native_implementation_stage[api$is_python_function &
    api$python_name=="functional_recovery_qualification_scenarios"] <- 36L
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% c("functional_recovery_stress_scenarios",
      "functional_recovery_scenario_catalog_frame")] <- 37L
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% c("functional_simulation_truth_frame",
      "functional_simulation_reporting_text")] <- 38L
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% c("plot_functional_simulation_curve",
      "plot_functional_simulation_phase_warps",
      "plot_functional_simulation_score_variances")] <- 39L
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% c(
      "functional_random_effect_frame",
      "functional_trial_random_effect_frame",
      "functional_mixed_effects_full_refit_audit_frame",
      "functional_mixed_effects_full_refit_trial_audit_frame",
      "fpca_wild_bootstrap_truncation_scan_frame",
      "fpca_wild_bootstrap_truncation_selection_frame")] <- 40L
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% c("plot_functional_random_effects",
      "plot_functional_trial_random_effects")] <- 41L
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% c("plot_fpca_regression_cv",
      "plot_nested_fpca_regression_cv",
      "plot_functional_mixed_effects_bootstrap_comparison",
      "plot_fpca_wild_bootstrap_truncation_scan")] <- 42L
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% c("plot_fpca_wild_bootstrap_projection",
      "plot_fpca_regression_future_prediction_interval",
      "plot_fpca_regression_mean_prediction_uncertainty",
      "plot_fpca_regression_slope_band",
      "plot_fpca_regression_slope_uncertainty",
      "plot_sparse_fpca_score_diagnostics")] <- 43L
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% c("select_fpca_wild_bootstrap_truncation",
      "fpca_wild_bootstrap_projection_frame",
      "fpca_wild_bootstrap_simultaneous_frame",
      "fpca_wild_bootstrap_family_test_frame",
      "fpca_wild_bootstrap_monte_carlo_diagnostic_frame")] <- 44L
  inference_reporting_names <- c(
    "fpca_wild_bootstrap_projection_reporting_text",
    "fpca_regression_future_prediction_reporting_text",
    "fpca_regression_uncertainty_reporting_text",
    "fpca_regression_slope_band_reporting_text",
    "fpca_nested_regression_cv_reporting_text",
    "fpca_wild_bootstrap_family_test_reporting_text",
    "fpca_wild_bootstrap_monte_carlo_reporting_text",
    "fpca_wild_bootstrap_simultaneous_reporting_text"
  )
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% inference_reporting_names] <- 45L
  descriptive_inference_reporting_names <- c(
    "fpca_regression_cv_reporting_text",
    "fpca_component_envelope_reporting_text",
    "fpca_wild_bootstrap_truncation_reporting_text"
  )
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% descriptive_inference_reporting_names] <- 46L
  api$native_implementation_started <-
    !is.na(api$native_implementation_stage)
  # TrajectorySet native representation covers key fields and with_values/subset
  # provenance behavior in R, but not all source class/schema contracts.
  api$native_representation_stage <- ifelse(
    !api$is_python_function & api$namespace=="root" &
      api$python_name=="TrajectorySet",5L,
    ifelse(!api$is_python_function & api$namespace=="root" &
      api$python_name=="IrregularTrajectorySet",7L,
      ifelse(!api$is_python_function & api$namespace=="root" &
        api$python_name %in% c(
          "RecurrenceNetworkResult","JointRecurrenceResult",
          "RecurrenceRadiusProfileResult","WindowedRQAResult",
          "WindowedRQAFunctionalResult"),8L,NA_integer_)))
  api$status <- ifelse(!api$is_python_function,
    ifelse(!is.na(api$native_representation_stage),
      "class_or_constant_native_representation_partial",
      "class_or_constant_native_representation_not_reviewed"),
    ifelse(api$native_implementation_started,
      "native_algorithm_implemented_qualification_pending",
      ifelse(api$named_native_candidate,
        "native_analog_present_behavior_unverified",
        "no_specific_native_function_mapped")))
  # Independently identified differences are hard blockers: a human/CI
  # approval flag cannot override a known unresolved published-source gap.
  # This audit is read offline and never initializes Python.
  gaps <- utils::read.csv(system.file("extdata",
    "native_source_contract_gaps_stage22.csv",
    package="eyetrajectories"),stringsAsFactors=FALSE)
  required_gap_columns <- c("python_name","native_r_candidate","gap_kind",
    "known_source_difference","source_witness","review_resolution",
    "unresolved_source_gap")
  .etr_assert(identical(names(gaps),required_gap_columns) &&
    !anyDuplicated(gaps$python_name) &&
    all(gaps$python_name %in% api$python_name[api$is_python_function]) &&
    all(gaps$native_r_candidate ==
      unname(analogues[gaps$python_name])) &&
    all(vapply(gaps[required_gap_columns[3:6]],function(x)
      is.character(x)&&all(!is.na(x)&nzchar(x)),logical(1L))) &&
    is.logical(gaps$unresolved_source_gap) &&
    !anyNA(gaps$unresolved_source_gap),
    "native published-source gap inventory is malformed")
  gap_idx<-match(api$python_name,gaps$python_name)
  api$source_contract_gap_known <- !is.na(gap_idx)
  api$source_contract_gap_unresolved <- ifelse(is.na(gap_idx),FALSE,
    gaps$unresolved_source_gap[gap_idx])
  api$source_contract_gap_kind <- ifelse(is.na(gap_idx),"",
    gaps$gap_kind[gap_idx])
  # Explicit signed-off source-contract evidence, NOT inferred from
  # implementation age, mapping, a standalone CI check, or a Python wrapper.
  # Candidate rows are locked to the frozen API source Git revision.
  register <- utils::read.csv(system.file("extdata",
    "native_contract_certification_pilots_v1.csv",
    package="eyetrajectories"),stringsAsFactors=FALSE)
  needed <- c("python_name","native_r_candidate","source_path",
    "frozen_catalog_snapshot_sha","published_tag",
    "published_tag_commit","independent_oracle_suite",
    "numerical_fixture_pass","numerical_fixture_evidence","evidence_state",
    "numerical_oracle_approved","schema_boundary_approved",
    "scientific_scope_approved","independent_reviewer_approved",
    "review_evidence")
  .etr_assert(identical(names(register),needed) &&
    !anyDuplicated(register$python_name) &&
    all(register$python_name %in% api$python_name[api$is_python_function]) &&
    all(register$native_r_candidate ==
      unname(analogues[register$python_name])) &&
    all(register$frozen_catalog_snapshot_sha ==
      api$source_git_sha[match(register$python_name,api$python_name)]) &&
    all(register$published_tag=="v1.2.0") &&
    all(register$published_tag_commit==
      "c1cd95ad718327550f7e55393ff38582872f7a94") &&
    all(nzchar(register$source_path)) &&
    all(nzchar(register$independent_oracle_suite)),
    "certification evidence register is malformed or mismatched to frozen API")
  .etr_assert(is.logical(register$numerical_fixture_pass) &&
    !anyNA(register$numerical_fixture_pass),
    "fixture evidence state must have explicit boolean values")
  fixture_link <- as.character(register$numerical_fixture_evidence)
  fixture_link_present <- !is.na(fixture_link) &
    grepl("^https://github\\.com/",fixture_link)
  .etr_assert(!any(register$numerical_fixture_pass &
    !fixture_link_present),
    "numeric fixture PASS requires a GitHub evidence link")
  approved <- c("numerical_oracle_approved","schema_boundary_approved",
    "scientific_scope_approved","independent_reviewer_approved")
  .etr_assert(all(vapply(register[approved],function(x)
    is.logical(x)&&!anyNA(x),logical(1L))),
    "certification evidence approvals must be explicit booleans")
  review <- as.character(register$review_evidence)
  evidence_linked <- !is.na(review) &
    grepl("^https://github\\.com/[^/]+/[^/]+/commit/[0-9a-f]{40}$",review)
  # A signed approval cannot bypass reproducible direct-source fixtures.
  # A passing fixture by itself never implies full-domain certification.
  pass <- register$numerical_fixture_pass &
    fixture_link_present &
    apply(register[approved],1L,all) &
    register$evidence_state=="approved_and_reproducible" &
    evidence_linked
  unresolved<-api$source_contract_gap_unresolved[
    match(register$python_name,api$python_name)]
  .etr_assert(!any(pass & unresolved),
    "cannot approve a fully certified public source contract while published-source differences remain unresolved")
  .etr_assert(!any(pass & !register$python_name %in%
    api$python_name[api$native_implementation_started]),
    "cannot certify a Python contract without an implemented native method")
  found <- match(api$python_name,register$python_name)
  api$contract_certification_candidate <- !is.na(found)
  api$contract_certification_evidence_state <- ifelse(is.na(found),
    "not_reviewed",register$evidence_state[found])
  api$contract_numerical_fixture_pass <- ifelse(is.na(found),FALSE,
    register$numerical_fixture_pass[found])
  api$independent_numeric_parity_pass <- ifelse(is.na(found),FALSE,
    register$numerical_oracle_approved[found])
  api$behavioral_schema_parity_pass <- ifelse(is.na(found),FALSE,
    register$schema_boundary_approved[found])
  api$scientific_inference_qualified <- ifelse(is.na(found),FALSE,
    register$scientific_scope_approved[found])
  api$independent_contract_review_pass <- ifelse(is.na(found),FALSE,
    register$independent_reviewer_approved[found])
  api$one_to_one_native_contract_complete <- FALSE
  api$one_to_one_native_contract_complete[match(register$python_name,
    api$python_name)] <- pass
  # The 508-symbol certificate includes 128 non-function exports.
  # Classes/constants have a separate FULL-domain schema/value and reviewer
  # evidence register. This never treats a class as an R callable mapping.
  other <- utils::read.csv(system.file("extdata",
    "native_nonfunction_contract_review_v1.csv",
    package="eyetrajectories"),stringsAsFactors=FALSE)
  expected_other_columns <- c("namespace","python_name","kind",
    "source_git_sha","native_representation","evidence_state",
    "numerical_or_value_approved","schema_boundary_approved",
    "scientific_scope_approved","independent_reviewer_approved",
    "review_evidence")
  other_key <- paste(other$namespace,other$python_name,sep="::")
  api_key <- paste(api$namespace,api$python_name,sep="::")
  other_idx <- match(other_key,api_key)
  .etr_assert(identical(names(other),expected_other_columns) &&
    nrow(other)==128L && !anyDuplicated(other_key) &&
    !anyNA(other_idx) && all(!api$is_python_function[other_idx]) &&
    all(other$kind==api$kind[other_idx]) &&
    all(other$source_git_sha==api$source_git_sha[other_idx]),
    "non-function source-contract review inventory must match 128 frozen exports")
  other_approvals <- c("numerical_or_value_approved",
    "schema_boundary_approved","scientific_scope_approved",
    "independent_reviewer_approved")
  .etr_assert(all(vapply(other[other_approvals],function(x)
    is.logical(x)&&!anyNA(x),logical(1L))),
    "class/constant certification approvals must be explicit booleans")
  other_representation <- as.character(other$native_representation)
  other_representation[is.na(other_representation)] <- ""
  other_links <- as.character(other$review_evidence)
  other_links[is.na(other_links)] <- ""
  # A full commit SHA in the review URL prevents an unpinned generic PR link
  # from being mistaken for complete independent source contract evidence.
  reviewed_commit <- grepl(
    "^https://github\\.com/[^/]+/[^/]+/commit/[0-9a-f]{40}$",
    other_links)
  other_pass <- apply(other[other_approvals],1L,all) &
    other$evidence_state=="approved_and_reproducible" &
    nzchar(other_representation) & reviewed_commit
  api$contract_certification_candidate[other_idx] <-
    other$evidence_state!="not_reviewed"
  api$contract_certification_evidence_state[other_idx] <-
    other$evidence_state
  api$independent_numeric_parity_pass[other_idx] <-
    other$numerical_or_value_approved
  api$behavioral_schema_parity_pass[other_idx] <-
    other$schema_boundary_approved
  api$scientific_inference_qualified[other_idx] <-
    other$scientific_scope_approved
  api$independent_contract_review_pass[other_idx] <-
    other$independent_reviewer_approved
  api$one_to_one_native_contract_complete[other_idx] <- other_pass

  if (require_complete && !all(api$one_to_one_native_contract_complete))
    stop("Full 508-export one-to-one native R parity is NOT complete: ",
         sum(!api$one_to_one_native_contract_complete),
         " source contracts remain unqualified.",call.=FALSE)
  rownames(api) <- NULL
  api
}

