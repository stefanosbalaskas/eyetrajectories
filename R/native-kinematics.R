# Internal three-point derivative equals numpy.gradient(edge_order=2)
.etr_gradient <- function(time, y) {
  n <- length(time)
  .etr_assert(n >= 3L && length(y) == n && all(is.finite(y)),
              "derivatives require >= 3 complete time samples")
  h <- diff(time); ans <- numeric(n)
  a <- h[1]; b <- h[2]
  ans[1] <- -(2*a+b)/(a*(a+b))*y[1] + (a+b)/(a*b)*y[2] -
    a/(b*(a+b))*y[3]
  for (k in 2:(n-1L)) {
    a <- h[k-1L]; b <- h[k]
    ans[k] <- -b/(a*(a+b))*y[k-1L] + (b-a)/(a*b)*y[k] +
      a/(b*(a+b))*y[k+1L]
  }
  a <- h[n-2L]; b <- h[n-1L]
  ans[n] <- b/(a*(a+b))*y[n-2L] - (a+b)/(a*b)*y[n-1L] +
    (a+2*b)/(b*(a+b))*y[n]
  ans
}

#' Native derivative of functional trajectory channels
#' @param x Complete trajectory set with >= 3 time points.
#' @export
etr_velocity <- function(x) {
  etr_validate(x, require_complete = TRUE)
  .etr_assert(length(x$time) >= 3L, "velocity requires >= 3 samples")
  v <- x$values
  for (i in seq_len(dim(v)[1])) for (j in seq_len(dim(v)[3]))
    v[i, , j] <- .etr_gradient(x$time, x$values[i, , j])
  etr_trajectory_set(x$time, v, x$curve_ids,
                     paste0(x$dimension_names, "_velocity"), x$metadata,
                     x$coordinate_system, x$time_unit)
}

#' Native second derivative (acceleration)
#' @inheritParams etr_velocity
#' @export
etr_acceleration <- function(x) {
  v <- etr_velocity(x)
  a <- v$values
  for (i in seq_len(dim(a)[1])) for (j in seq_len(dim(a)[3]))
    a[i, , j] <- .etr_gradient(x$time, v$values[i, , j])
  etr_trajectory_set(x$time, a, x$curve_ids,
                     paste0(x$dimension_names, "_acceleration"), x$metadata,
                     x$coordinate_system, x$time_unit)
}

#' Planar speed function
#' @inheritParams etr_velocity
#' @export
etr_speed <- function(x) {
  etr_validate(x, require_complete = TRUE)
  .etr_assert(dim(x$values)[3] >= 2L, "planar x/y channels required")
  v <- etr_velocity(x)$values
  sp <- sqrt(v[, , 1]^2 + v[, , 2]^2)
  etr_trajectory_set(x$time, array(sp, c(dim(v)[1], length(x$time), 1L)),
                     x$curve_ids, "speed", x$metadata, x$coordinate_system, x$time_unit)
}

#' Planar heading angle in radians
#' @inheritParams etr_velocity
#' @export
etr_heading <- function(x) {
  etr_validate(x, require_complete = TRUE)
  .etr_assert(dim(x$values)[3] >= 2L, "planar x/y channels required")
  v <- etr_velocity(x)$values
  angles <- atan2(v[, , 2], v[, , 1])
  etr_trajectory_set(x$time, array(angles, c(dim(v)[1], length(x$time), 1L)),
                     x$curve_ids, "heading_rad", x$metadata, x$coordinate_system, x$time_unit)
}

#' Total sampled planar path length for each curve
#' @inheritParams etr_velocity
#' @export
etr_path_length <- function(x) {
  etr_validate(x, require_complete = TRUE)
  .etr_assert(dim(x$values)[3] >= 2L, "planar x/y channels required")
  vapply(seq_len(dim(x$values)[1]), function(i) {
    dx <- diff(x$values[i, , 1]); dy <- diff(x$values[i, , 2])
    sum(sqrt(dx^2 + dy^2))
  }, numeric(1))
}

#' Cumulative sampled planar path length as a native trajectory
#' @inheritParams etr_velocity
#' @export
etr_cumulative_path_length <- function(x) {
  etr_validate(x, require_complete = TRUE)
  .etr_assert(dim(x$values)[3] >= 2L, "planar x/y channels required")
  n <- dim(x$values)[1]; nt <- length(x$time)
  v <- array(0, c(n, nt, 1L))
  for (i in seq_len(n)) {
    dx <- diff(x$values[i, , 1]); dy <- diff(x$values[i, , 2])
    v[i, , 1] <- c(0, cumsum(sqrt(dx^2 + dy^2)))
  }
  etr_trajectory_set(x$time, v, x$curve_ids, "cumulative_path_length",
                     x$metadata, x$coordinate_system, x$time_unit)
}

#' Planar tortuosity: total path length divided by end-point displacement
#' @inheritParams etr_velocity
#' @export
etr_tortuosity <- function(x) {
  etr_validate(x, require_complete = TRUE)
  .etr_assert(dim(x$values)[3] >= 2L, "planar x/y channels required")
  n <- dim(x$values)[1]; nt <- length(x$time)
  displacement <- vapply(seq_len(n), function(i) {
    sqrt(sum((x$values[i, nt, 1:2] - x$values[i, 1, 1:2])^2))
  }, numeric(1))
  len <- etr_path_length(x)
  ifelse(displacement > 0, len / displacement, NA_real_)
}
