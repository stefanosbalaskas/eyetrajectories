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
  discrete_frechet_distance="etr_frechet",
  dynamic_time_warping_distance="etr_dtw",
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
  api$native_implementation_stage <- ifelse(
      api$is_python_function & api$python_name %in% stage2_names,2L,
      ifelse(api$is_python_function & api$python_name %in% stage3_names,3L,
             NA_integer_))
  api$native_implementation_started <-
    !is.na(api$native_implementation_stage)
  api$status <- ifelse(!api$is_python_function,
    "class_or_constant_native_representation_not_reviewed",
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
