# Native analogue for frozen Python 1.2 TrajectorySet.with_values().
# This is a first-party partial R class contract, not independently approved
# full-source parity. Native NA and NumPy NaN acceptance are still distinct.

#' Return a native trajectory copy with updated values and provenance
#'
#' Mirrors the ordinary scientific copy/metadata/provenance behavior of the
#' frozen Python 1.2 TrajectorySet.with_values method. Constructor-level
#' NumPy dtype coercions, arbitrary Python mappings, zero-curve objects and
#' Python-specific errors are not claimed to be fully equivalent.
#'
#' @param x A native etr_trajectory_set.
#' @param values Replacement numeric three-dimensional curve/time/channel array.
#' @param time Optional replacement finite strictly increasing numeric grid.
#' @param provenance_update Optional named JSON-like list of provenance changes.
#'   Existing entries are preserved except for identically named updates.
#' @param time_unit Optional new time-unit label.
#' @param coordinate_system Optional new coordinate-system label.
#' @return A new etr_trajectory_set with metadata and curve identifiers kept.
#' @export
etr_with_values <- function(x,values,time=NULL,provenance_update=NULL,
    time_unit=NULL,coordinate_system=NULL){
  etr_validate(x)
  .etr_assert(is.array(values)&&is.numeric(values)&&
    length(dim(values))==3L,
    "values must be a numeric three-dimensional array")
  .etr_assert(dim(values)[1L]==length(x$curve_ids)&&
    dim(values)[3L]==length(x$dimension_names),
    "replacement values must retain curve and channel dimensions")
  new_time<-if(is.null(time))x$time else time
  .etr_assert(is.numeric(new_time)&&is.null(dim(new_time))&&
    length(new_time)>=2L&&all(is.finite(new_time))&&
    all(diff(new_time)>0),
    "replacement time must be finite, strictly increasing, length >= 2")
  .etr_assert(dim(values)[2L]==length(new_time),
    "replacement time and values time dimension must match")
  new_provenance<-if(is.null(x$provenance))list() else x$provenance
  if(!is.null(provenance_update)){
    .etr_assert(.etr_provenance_valid(provenance_update),
      "provenance_update must be a named JSON-like mapping")
    new_provenance[names(provenance_update)]<-provenance_update
  }
  .etr_assert(.etr_provenance_valid(new_provenance),
    "merged provenance must be a valid JSON-like mapping")
  new_unit<-if(is.null(time_unit))x$time_unit else time_unit
  new_coord<-if(is.null(coordinate_system))
    x$coordinate_system else coordinate_system
  etr_trajectory_set(time=new_time,values=values,
    curve_ids=x$curve_ids,dimension_names=x$dimension_names,
    metadata=x$metadata,coordinate_system=new_coord,
    time_unit=new_unit,provenance=new_provenance)
}
