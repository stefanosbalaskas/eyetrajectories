# One-to-one native R source analogue for frozen Python 1.2
# kinematics.py::differentiate_trajectories(trajectories, *, order=1).
# This is a pure-R numerical implementation; no runtime Python bridge.
# Python source: c1cd95ad718327550f7e55393ff38582872f7a94.

#' Differentiate functional trajectories with the frozen Python 1.2 contract
#'
#' Applies a NumPy edge_order=2 compatible derivative to each curve/channel
#' on the recorded, possibly nonuniform common time grid. order=2 computes
#' a second derivative by differentiating the first derivative again.
#' No smoothing, resampling, interpolation or source time conversion occurs.
#' A named derivative provenance record is added while other source metadata
#' and provenance remain intact. Python bool TRUE is accepted as order=1.
#' @param x Native trajectory set with at least three complete time samples.
#' @param order Source-compatible derivative order: 1 or 2.
#' @return Native trajectory set with channel suffix _velocity or _acceleration.
#' @export
etr_differentiate_trajectories <- function(x,order=1L) {
  etr_validate(x,require_complete=TRUE)
  .etr_assert(length(x$time)>=3L,
    "numerical differentiation with edge_order=2 requires at least three time samples")
  .etr_assert((is.numeric(order)||is.logical(order))&&
    length(order)==1L&&!is.na(order)&&is.finite(order)&&
    order%in%c(1,2),
    "order must be 1 or 2 in the frozen Python source")
  k<-as.integer(order)
  values<-x$values
  for(iteration in seq_len(k)) {
    next_values<-values
    for(i in seq_len(dim(values)[1L]))
      for(j in seq_len(dim(values)[3L]))
        next_values[i,,j]<-.etr_gradient(x$time,values[i,,j])
    values<-next_values
  }
  prov<-etr_trajectory_provenance(x)
  prov["derivative"]<-list(list(order=k,method="numpy_gradient",
    smoothing=FALSE))
  suffix<-if(k==1L)"_velocity" else "_acceleration"
  etr_trajectory_set(x$time,values,curve_ids=x$curve_ids,
    dimension_names=paste0(x$dimension_names,suffix),
    metadata=x$metadata,coordinate_system=x$coordinate_system,
    time_unit=x$time_unit,provenance=prov)
}
