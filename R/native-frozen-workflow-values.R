# Native source VALUE representation of three frozen Python 1.2 workflow
# scalars. This is NOT a scientific method, not an independent certification,
# and must never be confused with the native workflow bundle's own format.
# Source: eyetrajectoriespy/workflows/_core.py, frozen c1cd95ad718327550f7e55393ff38582872f7a94.
#
# Python workflow export_workflow_bundle writes a different portable format
# from native R's etr_native_r_workflow_bundle_v1. The source constant values
# are for auditing source compatibility, NOT for advertising native bundle
# interchangeability.

#' Frozen Python 1.2 workflow public scalar values
#'
#' Return copies of three scalar objects exposed by the pinned Python
#' `eyetrajectoriespy.workflows` namespace. The frozen-source values
#' are recorded separately from R-specific workflow bundle formats.
#'
#' @return Named list with integer WORKFLOW_SCHEMA_VERSION and
#'   WORKFLOW_BUNDLE_SCHEMA_VERSION and character WORKFLOW_BUNDLE_FORMAT.
#' @export
etr_frozen_workflow_values <- function() {
  list(
    WORKFLOW_SCHEMA_VERSION=1L,
    WORKFLOW_BUNDLE_SCHEMA_VERSION=1L,
    WORKFLOW_BUNDLE_FORMAT="eyetrajectoriespy-workflow-bundle"
  )
}
