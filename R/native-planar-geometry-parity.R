# Native R implementations of four public Python 1.2 planar operations.
# No Python, reticulate, numerical backend or optional R dependencies.
# Source contracts: eyetrajectoriespy v1.2.0, kinematics.py.
# Experimental until independent Python/R numerical parity tests pass.

.etr_geometry_planar_indices <- function(x, dimensions=NULL,
                                         require_complete=TRUE) {
  etr_validate(x,require_complete=require_complete)
  if (is.null(dimensions)) {
    dimensions <- c("x","y")
    .etr_assert(all(dimensions %in% x$dimension_names),
      "Specify dimensions explicitly when there are no named x/y channels")
  } else {
    .etr_assert(is.character(dimensions) && length(dimensions)==2L &&
                !anyNA(dimensions) && all(nzchar(dimensions)) &&
                dimensions[1L]!=dimensions[2L],
                "dimensions must contain two distinct named planar channels")
  }
  idx <- match(dimensions,x$dimension_names)
  .etr_assert(!anyNA(idx),"Unknown planar dimension names")
  idx
}

.etr_geometry_scalar <- function(value,name,nonnegative=FALSE) {
  .etr_assert(is.numeric(value) && !is.logical(value) &&
    length(value)==1L && !is.na(value) && is.finite(value) &&
    (!nonnegative || value>=0),
    paste0(name," must be finite numeric",
           if(nonnegative) " and non-negative" else ""))
  as.numeric(value)
}

.etr_geometry_result <- function(x,values,name,
                                 coordinate_system=x$coordinate_system) {
  .etr_assert(is.matrix(values) && nrow(values)==dim(x$values)[1L] &&
              ncol(values)==length(x$time),
              "invalid native planar result shape")
  # Python records NumPy NaN on undefined samples, while the native R
  # TrajectorySet uses NA as the one supported missing-value sentinel.
  values[is.nan(values)] <- NA_real_
  out <- etr_trajectory_set(
    x$time,array(values,dim=c(nrow(values),ncol(values),1L)),
    x$curve_ids,name,x$metadata,coordinate_system,x$time_unit
  )
  out
}

.etr_geometry_derivatives <- function(x,dimensions) {
  idx <- .etr_geometry_planar_indices(x,dimensions,require_complete=TRUE)
  nt <- length(x$time); n <- dim(x$values)[1L]
  .etr_assert(nt>=3L,"planar differential geometry requires >=3 samples")
  vx <- vy <- ax <- ay <- matrix(NA_real_,n,nt)
  for(i in seq_len(n)) {
    vx[i,] <- .etr_gradient(x$time,x$values[i,,idx[1L]])
    vy[i,] <- .etr_gradient(x$time,x$values[i,,idx[2L]])
    ax[i,] <- .etr_gradient(x$time,vx[i,])
    ay[i,] <- .etr_gradient(x$time,vy[i,])
  }
  list(vx=vx,vy=vy,ax=ax,ay=ay,
       speed=sqrt(vx^2+vy^2),planar_dimensions=x$dimension_names[idx])
}

.etr_geometry_policy <- function(value,speed,min_speed,undefined_policy,
                                 curve_ids,quantity) {
  threshold <- .etr_geometry_scalar(min_speed,"min_speed",nonnegative=TRUE)
  policy <- match.arg(undefined_policy,c("nan","raise"))
  undefined <- speed <= threshold | !is.finite(value)
  if (policy=="raise" && any(undefined)) {
    affected <- curve_ids[rowSums(undefined)>0L]
    stop(quantity," undefined at speed <= min_speed or a nonfinite ",
         "derivative denominator; affected curves: ",
         paste(utils::head(affected,8L),collapse=", "),call.=FALSE)
  }
  value[undefined] <- NA_real_
  value
}

#' Native planar acceleration magnitude
#'
#' Mirrors the Python \code{acceleration_magnitude_function} numerical
#' definition on complete, common-grid trajectories: apply second-order
#' edge-aware NumPy-compatible gradients twice, then Euclidean norm of the
#' first two channels. No Python installation is required.
#' @param x Native \code{etr_trajectory_set}.
#' @return Native single-channel trajectory collection.
#' @export
etr_acceleration_magnitude <- function(x) {
  etr_validate(x,require_complete=TRUE)
  .etr_assert(dim(x$values)[3L]>=2L,"planar x/y channels required")
  a <- etr_acceleration(x)$values
  v <- sqrt(a[,,1L]^2+a[,,2L]^2)
  if(is.null(dim(v))) v <- matrix(v,nrow=dim(x$values)[1L])
  .etr_geometry_result(x,v,"acceleration_magnitude")
}

#' Native planar distance from per-curve or shared landmarks
#'
#' Mirrors Python \code{distance_to_landmark_function}: Euclidean distance
#' from the first two trajectory channels, with scalar or per-curve numeric
#' landmark locations; missing gaze remains NA.
#' @param x Native \code{etr_trajectory_set}.
#' @param landmark_x Scalar or numeric vector of length n_curves.
#' @param landmark_y Scalar or numeric vector of length n_curves.
#' @return Native single-channel trajectory set.
#' @export
etr_distance_to_landmark <- function(x,landmark_x,landmark_y) {
  etr_validate(x)
  n <- dim(x$values)[1L]; nt <- length(x$time)
  .etr_assert(dim(x$values)[3L]>=2L,"planar x/y channels required")
  .etr_assert(is.numeric(landmark_x) && is.numeric(landmark_y) &&
              !is.logical(landmark_x) && !is.logical(landmark_y) &&
              length(landmark_x) %in% c(1L,n) &&
              length(landmark_y) %in% c(1L,n) &&
              all(is.finite(landmark_x)) && all(is.finite(landmark_y)),
              "landmark coordinates must be finite numeric scalars or per-curve vectors")
  xx <- matrix(x$values[,,1L],nrow=n,ncol=nt)
  yy <- matrix(x$values[,,2L],nrow=n,ncol=nt)
  dx <- sweep(xx,1L,rep_len(landmark_x,n),"-")
  dy <- sweep(yy,1L,rep_len(landmark_y,n),"-")
  .etr_geometry_result(x,sqrt(dx^2+dy^2),"distance_to_landmark")
}

#' Native signed planar curvature
#'
#' \eqn{\kappa(t)=(x'(t)y''(t)-y'(t)x''(t))/
#'              (x'(t)^2+y'(t)^2)^{3/2}}.
#' Low-speed samples are NA by default; no hidden epsilon stabilization.
#' @param x Complete native \code{etr_trajectory_set} with >=3 samples.
#' @param dimensions Two named planar channels. Defaults to x/y when present.
#' @param min_speed Minimum allowed Euclidean speed (inclusive undefined rule).
#' @param undefined_policy \code{"nan"} maps undefined Python NaN to R NA;
#'   \code{"raise"} instead fails closed.
#' @return Native single-channel trajectory set, coordinate system unknown
#'   because the result has inverse length units.
#' @export
etr_signed_curvature <- function(x,dimensions=NULL,min_speed=0,
                                 undefined_policy=c("nan","raise")) {
  d <- .etr_geometry_derivatives(x,dimensions)
  numerator <- d$vx*d$ay-d$vy*d$ax
  speed2 <- d$vx^2+d$vy^2
  v <- suppressWarnings(numerator/(speed2^(3/2)))
  v <- .etr_geometry_policy(v,d$speed,min_speed,
                            undefined_policy,x$curve_ids,"signed curvature")
  .etr_geometry_result(x,v,"signed_curvature",coordinate_system="unknown")
}

#' Native signed turning rate in radians per source time unit
#'
#' \eqn{\omega(t)=(x'(t)y''(t)-y'(t)x''(t))/
#'              (x'(t)^2+y'(t)^2)}.
#' This is not the derivative of a wrapped heading angle.
#' @inheritParams etr_signed_curvature
#' @export
etr_turning_rate <- function(x,dimensions=NULL,min_speed=0,
                             undefined_policy=c("nan","raise")) {
  d <- .etr_geometry_derivatives(x,dimensions)
  numerator <- d$vx*d$ay-d$vy*d$ax
  speed2 <- d$vx^2+d$vy^2
  v <- suppressWarnings(numerator/speed2)
  v <- .etr_geometry_policy(v,d$speed,min_speed,
                            undefined_policy,x$curve_ids,"turning rate")
  .etr_geometry_result(x,v,"turning_rate",coordinate_system="unknown")
}
