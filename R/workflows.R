#' Run a declared common-grid FPCA workflow
#'
#' Constructs the Python FPCAWorkflowConfig explicitly, then runs
#' eyetrajectoriespy.workflows.run_fpca_workflow(). This does not perform
#' hidden preprocessing or offer independently calibrated inference.
#' @param trajectories A Python TrajectorySet.
#' @param n_components Component count or fraction of explained variance.
#' @param scaling "none" or "dimension_sd".
#' @export
et_run_fpca_workflow <- function(trajectories, n_components = 0.95,
                                 scaling = c("none", "dimension_sd")) {
  config <- et_call(
    "FPCAWorkflowConfig",
    n_components = n_components,
    scaling = match.arg(scaling),
    .namespace = "workflows"
  )
  et_call(
    "run_fpca_workflow",
    trajectories,
    config = config,
    .namespace = "workflows"
  )
}
