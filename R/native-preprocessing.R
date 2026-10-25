#' Explicit common-grid interpolation (no extrapolation)
#' @param x Native trajectories.
#' @param new_time New strictly increasing observation grid.
#' @param max_gap Maximum allowed gap between two observed times to interpolate.
#' @export
etr_resample <- function(x, new_time, max_gap = Inf) {
  etr_validate(x)
  .etr_assert(is.numeric(new_time) && length(new_time) >= 2L &&
                all(is.finite(new_time)) && all(diff(new_time) > 0),
              "new_time must be a finite, increasing numeric grid")
  .etr_assert(is.numeric(max_gap) && length(max_gap) == 1L && !is.na(max_gap) &&
                max_gap > 0, "max_gap must be positive")
  v <- array(NA_real_, c(dim(x$values)[1], length(new_time), dim(x$values)[3]))
  for (i in seq_len(dim(v)[1])) for (j in seq_len(dim(v)[3])) {
    y <- x$values[i, , j]; good <- which(!is.na(y))
    if (length(good) < 2L) next
    for (k in seq_len(length(good) - 1L)) {
      a <- good[k]; b <- good[k + 1L]
      if (x$time[b] - x$time[a] > max_gap) next
      at <- which(new_time >= x$time[a] & new_time <= x$time[b])
      if (length(at)) {
        v[i, at, j] <- y[a] + (y[b] - y[a]) *
          (new_time[at] - x$time[a]) / (x$time[b] - x$time[a])
      }
    }
  }
  etr_trajectory_set(new_time, v, x$curve_ids, x$dimension_names, x$metadata,
                     x$coordinate_system, x$time_unit)
}

#' Fill short internal missing runs using explicit linear interpolation
#' @param x Native trajectories.
#' @param max_gap Maximum time gap bridged, including missing samples.
#' @export
etr_interpolate_gaps <- function(x, max_gap) {
  etr_validate(x)
  .etr_assert(is.numeric(max_gap) && length(max_gap) == 1L &&
                is.finite(max_gap) && max_gap > 0, "max_gap must be positive and finite")
  v <- x$values
  for (i in seq_len(dim(v)[1])) for (j in seq_len(dim(v)[3])) {
    y <- v[i, , j]; good <- which(!is.na(y))
    if (length(good) < 2L) next
    for (k in seq_len(length(good) - 1L)) {
      a <- good[k]; b <- good[k + 1L]
      if (b <= a + 1L || x$time[b] - x$time[a] > max_gap) next
      mid <- (a + 1L):(b - 1L)
      v[i, mid, j] <- y[a] + (y[b] - y[a]) *
        (x$time[mid] - x$time[a]) / (x$time[b] - x$time[a])
    }
  }
  etr_trajectory_set(x$time, v, x$curve_ids, x$dimension_names, x$metadata,
                     x$coordinate_system, x$time_unit)
}

#' Normalize times to unit interval or subtract start time
#' @param x Native trajectories.
#' @param method "unit" or "origin".
#' @export
etr_normalize_time <- function(x, method = c("unit", "origin")) {
  etr_validate(x)
  method <- match.arg(method)
  t <- x$time - x$time[1]
  if (method == "unit") t <- t / max(t)
  etr_trajectory_set(t, x$values, x$curve_ids, x$dimension_names, x$metadata,
                     x$coordinate_system, if (method == "unit") "normalized" else x$time_unit)
}

#' Center each curve, explicitly, by first position or mean
#' @param x Native trajectories.
#' @param method "first" (requires observed first point) or "mean".
#' @export
etr_center <- function(x, method = c("first", "mean")) {
  etr_validate(x)
  method <- match.arg(method)
  v <- x$values
  for (i in seq_len(dim(v)[1])) for (j in seq_len(dim(v)[3])) {
    yy <- v[i, , j]
    origin <- if (method == "first") yy[1] else mean(yy, na.rm = TRUE)
    .etr_assert(is.finite(origin), "cannot center a missing/undefined reference point")
    v[i, , j] <- yy - origin
  }
  etr_trajectory_set(x$time, v, x$curve_ids, x$dimension_names, x$metadata,
                     x$coordinate_system, x$time_unit)
}

#' Apply explicit running-mean smoothing
#' @param x Native, complete trajectory collection.
#' @param window Odd positive integer length of symmetric window.
#' @export
etr_smooth <- function(x, window = 5L) {
  etr_validate(x, require_complete = TRUE)
  .etr_assert(is.numeric(window) && length(window) == 1L &&
                is.finite(window) && window == as.integer(window) &&
                window >= 1L && window %% 2L == 1L,
              "window must be an odd positive integer")
  half <- (window - 1L) %/% 2L; n <- length(x$time); v <- x$values
  for (i in seq_len(dim(v)[1])) for (j in seq_len(dim(v)[3])) {
    yy <- v[i, , j]
    for (k in seq_len(n)) {
      ix <- seq.int(max(1L, k - half), min(n, k + half))
      v[i, k, j] <- mean(yy[ix])
    }
  }
  etr_trajectory_set(x$time, v, x$curve_ids, x$dimension_names, x$metadata,
                     x$coordinate_system, x$time_unit)
}

#' Standardize each functional channel across curves with declared scales
#' @param x Native complete trajectories.
#' @param scaling "none" or integrated standard deviation.
#' @export
etr_scale_channels <- function(x, scaling = c("none", "dimension_sd")) {
  etr_validate(x, require_complete = TRUE)
  scaling <- match.arg(scaling)
  if (scaling == "none") return(x)
  w <- etr_trapezoid_weights(x$time); n <- dim(x$values)[1]; nd <- dim(x$values)[3]
  scales <- numeric(nd)
  for (j in seq_len(nd)) {
    z <- etr_dimension(x, j); cent <- sweep(z, 2L, colMeans(z), "-")
    scales[j] <- sqrt(sum(colMeans(cent^2) * w))
  }
  .etr_assert(all(scales > .Machine$double.eps), "cannot scale constant dimensions")
  v <- x$values
  for (j in seq_len(nd)) v[, , j] <- v[, , j] / scales[j]
  ans <- etr_trajectory_set(x$time, v, x$curve_ids, x$dimension_names, x$metadata,
                            x$coordinate_system, x$time_unit)
  attr(ans, "scale") <- setNames(scales, x$dimension_names)
  ans
}
