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
  fit_functional_mixed_effects_regression="etr_fit_functional_mixed",
  discrete_transfer_entropy="etr_transfer_entropy",
  transfer_entropy_circular_shift_test="etr_transfer_entropy_shift_test",
  fit_scalar_on_function_regression="etr_fit_scalar_on_fpca",
  register_to_landmarks="etr_register_landmarks",
  delay_embed_trajectory="etr_delay_embedding",
  poincare_crossings="etr_poincare_return_map",
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
  split_conformal_fpca_anomaly="etr_split_conformal_fpca_anomalies",
  # These four new native methods are experimentally implemented here.
  acceleration_magnitude_function="etr_acceleration_magnitude",
  distance_to_landmark_function="etr_distance_to_landmark",
  signed_curvature_function="etr_signed_curvature",
  turning_rate_function="etr_turning_rate"
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
  stage2_names <- c("acceleration_magnitude_function",
                    "distance_to_landmark_function",
                    "signed_curvature_function","turning_rate_function")
  stage3_names <- c("normalize_coordinates","center_on_landmark",
                    "normalize_time","heading_function",
                    "trajectory_tortuosity",
                    "pairwise_discrete_frechet_distances",
                    "nearest_trajectory_indices")
  stage4_names <- c("discrete_frechet_distance",
                    "dynamic_time_warping_distance",
                    "pairwise_dynamic_time_warping_distances")
  stage6_names <- "load_portable_result"
  stage7_names <- c(
    "validate_common_grid","validate_simplex",
    "validate_no_long_missing_runs",
    "from_irregular_long_dataframe_native",
    "common_overlap_interval","make_common_grid",
    "resample_irregular_to_grid",
    "resample_irregular_to_common_grid",
    "irregular_sampling_summary","phase_landmark_frame")
  stage8_names <- c(
    "recurrence_network","recurrence_network_node_frame",
    "recurrence_network_summary_frame",
    "joint_recurrence_matrix","joint_recurrence_component_frame",
    "joint_rqa_metrics","cross_rqa_metrics",
    "recurrence_radius_profile","windowed_rqa",
    "windowed_rqa_trajectory_set")
  api$native_implementation_stage <- ifelse(
      api$is_python_function & api$python_name %in% stage2_names,2L,
      ifelse(api$is_python_function & api$python_name %in% stage3_names,3L,
        ifelse(api$is_python_function & api$python_name %in% stage4_names,4L,
          ifelse(api$is_python_function & api$python_name %in% stage6_names,
            6L,ifelse(api$is_python_function &
              api$python_name %in% stage7_names,7L,
              ifelse(api$is_python_function &
                api$python_name %in% stage8_names,8L,NA_integer_))))))
  s9 <- c("alr_transform","inverse_alr","component_trajectories",
    "select_n_components","fpca_score_frame","score_distance_matrix",
    "pairwise_functional_distances","sparse_dimension_summary",
    "warping_displacement","phase_summary","phase_trajectory_set",
    "fit_phase_fpca")
  api$native_implementation_stage[api$python_name %in% s9 &
    api$is_python_function] <- 9L
  stage10_names <- c("fit_compositional_fpca","reconstruct_compositional_fpca",
    "component_similarity_matrix","match_fpca_components",
    "reconstruction_error_by_curve","fpca_reconstruction_curve",
    "compare_registered_unregistered_fpca","registration_sensitivity_frame",
    "summarise_trajectory_set","summarise_fpca","fpca_reporting_text",
    "fpca_eigenvalue_gap_table","fpca_eigengap_reporting_text",
    "registration_sensitivity_reporting_text","functional_mean_band_frame")
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% stage10_names] <- 10L
  stage11_names <- c("joint_recurrence_reporting_text","recurrence_network_reporting_text","recurrence_radius_profile_reporting_text","rqa_reporting_text","rqa_metric_mean_bootstrap_reporting_text","windowed_rqa_reporting_text","windowed_rqa_functional_reporting_text","windowed_rqa_sensitivity_reporting_text","windowed_rqa_mean_band_reporting_text","rqa_parameter_sensitivity_reporting_text","kantz_parameter_sensitivity_reporting_text","lyapunov_parameter_sensitivity_reporting_text","largest_lyapunov_reporting_text","surrogate_nonlinearity_reporting_text","return_map_stability_reporting_text")
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% stage11_names] <- 11L
  stage12_names <- c("cross_validate_fpca_reconstruction","summarise_fpca_cross_validation","select_fpca_components_cv","summarise_fpca_regression_cv","select_fpca_regression_components","fpca_score_uncertainty_frame","fpca_spectrum_uncertainty_frame","conformal_fpca_anomaly_frame","trajectory_distance_comparison_frame","trajectory_distance_neighbor_frame","fpca_regression_slope_band_frame","fpca_regression_slope_uncertainty_frame","fpca_regression_prediction_uncertainty_frame","fpca_regression_future_prediction_frame")
  api$native_implementation_stage[api$is_python_function &
    api$python_name %in% stage12_names] <- 12L
  api$native_implementation_started <-
    !is.na(api$native_implementation_stage)
  # Stage 5 represents key TrajectorySet fields and with_values/subset
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
  # No numerical oracle can be marked PASS solely through a source-census
  # report. The independent opt-in test fixture is separate evidence.
  api$independent_numeric_parity_pass <- FALSE
  api$behavioral_schema_parity_pass <- FALSE
  api$scientific_inference_qualified <- FALSE
  api$one_to_one_native_contract_complete <- FALSE
  if (require_complete && !all(api$one_to_one_native_contract_complete))
    stop("Full 508-export one-to-one native R parity is NOT complete: ",
         sum(!api$one_to_one_native_contract_complete),
         " source contracts remain unqualified.",call.=FALSE)
  rownames(api) <- NULL
  api
}

# Stage 9 implementation inventory pending registration.
