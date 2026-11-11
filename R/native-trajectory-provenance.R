# Stage 5: provenance-preserving native trajectory objects and R snapshots.
# Does not import Python. Python 1.2 TrajectorySet source: types.py.
# The R snapshot is NOT the Python JSON/NPZ portable scientific-result format.

#' Inspect native trajectory provenance without initializing Python
#' @param x A native etr_trajectory_set.
#' @return JSON-like named R list, empty if created by an older R version.
#' @export
etr_trajectory_provenance <- function(x) {
  etr_validate(x)
  if(is.null(x$provenance)) list() else x$provenance
}

#' Transform trajectory data while preserving its provenance and metadata
#'
#' Mirrors the semantics of Python TrajectorySet.with_values(): shallowly
#' append/replace named provenance keys and retain source identifiers.
#' Keys absent from provenance_update remain unchanged; nested mappings
#' under updated keys are replaced, NOT recursively merged.
#' @param x Native trajectory object.
#' @param values Numeric 3D replacement array; defaults to current values.
#' @param time Optional replacement common increasing time grid.
#' @param provenance_update Optional named JSON-like list of replacements.
#' @param time_unit,coordinate_system Optional updated units; NULL retains.
#' @return New native trajectory object without mutating x.
#' @export
etr_with_values <- function(x,values=x$values,time=NULL,
                            provenance_update=NULL,time_unit=NULL,
                            coordinate_system=NULL) {
  etr_validate(x)
  if(!is.null(provenance_update))
    .etr_assert(is.list(provenance_update) &&
      !is.object(provenance_update) &&
      .etr_provenance_valid(provenance_update),
      "provenance_update must be a JSON-like named R list")
  prov <- etr_trajectory_provenance(x)
  if(length(provenance_update)>0L) {
    # Assign by [] <- to preserve R NULL entries as Python None values.
    prov[names(provenance_update)] <- provenance_update
  }
  etr_trajectory_set(
    if(is.null(time)) x$time else time,
    values,x$curve_ids,x$dimension_names,x$metadata,
    if(is.null(coordinate_system))x$coordinate_system else coordinate_system,
    if(is.null(time_unit))x$time_unit else time_unit,
    provenance=prov,
    python_boundary_mode=isTRUE(attr(x,"python_boundary_mode")))
}

#' Freeze native scientific trajectory state in a versioned R snapshot
#'
#' Snapshot fields intentionally use R data representations. They can
#' round-trip losslessly via base saveRDS/readRDS on supported R versions;
#' they are NOT Python portable scientific-result JSON+NPZ bundles.
#' @param x Native trajectory collection.
#' @return A version-one etr_trajectory_snapshot with explicit source
#'  package name, array dimensions, metadata, unit semantics, provenance.
#' @export
etr_trajectory_snapshot <- function(x) {
  etr_validate(x)
  snapshot <- list(
    format="eyetrajectories-native-r-trajectory-snapshot",
    schema_version=1L,
    package="eyetrajectories",
    time=x$time,
    values=x$values,
    curve_ids=x$curve_ids,
    dimension_names=x$dimension_names,
    metadata=x$metadata,
    coordinate_system=x$coordinate_system,
    time_unit=x$time_unit,
    provenance=etr_trajectory_provenance(x),
    shape=as.integer(dim(x$values))
  )
  if (isTRUE(attr(x, "python_boundary_mode"))) snapshot$python_boundary_mode <- TRUE
  structure(snapshot, class="etr_trajectory_snapshot")
}

#' Restore a validated native R trajectory snapshot
#'
#' Reconstructs with the current native R constructor and rejects
#' unsupported snapshot versions, inconsistent shape and malformed metadata.
#' Only use readRDS on files from trusted sources: like other native R
#' serialization, an RDS payload must not be treated as sandboxed data.
#' @param snapshot A version-one etr_trajectory_snapshot.
#' @return Validated native etr_trajectory_set.
#' @export
etr_restore_trajectory_snapshot <- function(snapshot) {
  .etr_assert(inherits(snapshot,"etr_trajectory_snapshot") &&
    is.list(snapshot),"snapshot must be a native R trajectory snapshot")
  .etr_assert(identical(snapshot$format,
               "eyetrajectories-native-r-trajectory-snapshot"),
              "unsupported native trajectory snapshot format")
  .etr_assert(identical(snapshot$schema_version,1L),
              "unsupported native trajectory snapshot schema_version")
  .etr_assert(identical(snapshot$package,"eyetrajectories"),
              "unexpected native trajectory snapshot source package")
  .etr_assert(is.array(snapshot$values) &&
    identical(as.integer(dim(snapshot$values)),snapshot$shape),
    "snapshot array shape does not match manifest")
  boundary <- snapshot[["python_boundary_mode", exact = TRUE]]
  if (is.null(boundary)) boundary <- FALSE
  etr_trajectory_set(
    snapshot$time,snapshot$values,snapshot$curve_ids,
    snapshot$dimension_names,snapshot$metadata,
    snapshot$coordinate_system,snapshot$time_unit,
    provenance=snapshot$provenance, python_boundary_mode=boundary)
}
