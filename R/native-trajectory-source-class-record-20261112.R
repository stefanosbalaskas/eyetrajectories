# Frozen Python 1.2 public TrajectorySet dataclass, types.py.
# Native R opt-in scientific class-field record; does not instantiate,
# subclass, monkey-patch or claim Python dataclass identity.
# It records the source-constructor fields and method-equivalent
# R scientific surfaces that are already implemented natively:
# etr_trajectory_set(python_boundary_mode=TRUE), etr_subset(...,TRUE),
# etr_dimension and etr_with_values.

#' Inspect native TrajectorySet as the frozen Python 1.2 scientific class
#'
#' @description Returns a source-field-ordered typed R record for a native
#'   etr_trajectory_set constructed in Python-boundary mode. This is a
#'   source scientific data and method-domain review, never a Python
#'   dataclass instance or a general NumPy/pandas coercion emulator.
#' @param x Native `etr_trajectory_set` object with
#'   `python_boundary_mode=TRUE`.
#' @return A typed R source scientific record with frozen Python field order,
#'   normalized curve-indexed metadata, shape, observed values, unit/provenance
#'   and native method-function references.
#' @export
etr_trajectory_source_class_record <- function(x) {
  .etr_assert(inherits(x,"etr_trajectory_set")&&
    isTRUE(attr(x,"python_boundary_mode")),
    "frozen TrajectorySet source class record requires python_boundary_mode=TRUE")
  etr_validate(x)
  original_fields<-c("time","values","curve_ids","dimension_names",
    "metadata","coordinate_system","time_unit","provenance")
  .etr_assert(all(original_fields%in%names(x)),
    "native trajectory lacks frozen Python TrajectorySet field names")
  .etr_assert(is.data.frame(x$metadata)&&
    nrow(x$metadata)==length(x$curve_ids)&&
    identical(rownames(x$metadata),as.character(x$curve_ids)),
    "frozen Python metadata index must match ordered curve IDs")
  shape<-dim(x$values)
  .etr_assert(length(shape)==3L&&
    identical(as.integer(shape[1]),as.integer(length(x$curve_ids)))&&
    identical(as.integer(shape[2]),as.integer(length(x$time)))&&
    identical(as.integer(shape[3]),as.integer(length(x$dimension_names))),
    "frozen Python TrajectorySet observed array and class schema inconsistent")
  f<-x[original_fields]
  record<-c(f,list(
    metadata_index=list(
      name="curve_id",
      labels=as.character(x$curve_ids),
      source_semantics="pandas.Index labels by frozen curve identifiers"),
    n_curves=as.integer(shape[1]),
    n_time=as.integer(shape[2]),
    n_dimensions=as.integer(shape[3]),
    source_shape=as.integer(shape),
    source_field_order=original_fields,
    source_class="eyetrajectoriespy.types.TrajectorySet",
    source_native_methods=list(
      dimension="etr_dimension",
      subset="etr_subset(python_boundary_mode=TRUE)",
      with_values="etr_with_values"),
    native_metadata_storage="R_data_frame_with_unique_character_rownames",
    frozen_python_class_identity=FALSE,
    native_r_record_mutable=TRUE,
    source_equivalent=FALSE,
    independently_source_certified=FALSE))
  structure(record,class=c(
    "etr_native_trajectory_source_class_scientific_record",
    "etr_trajectory_scientific_record","list"))
}
