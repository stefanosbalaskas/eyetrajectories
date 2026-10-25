# Piecewise-linear landmark time registration (not elastic SRVF alignment).
#' Prespecified landmark alignment of complete functional trajectories
#' @param x Complete common-grid native trajectory set.
#' @param source_landmarks Matrix: curves by ordered source landmark times.
#' @param target_landmarks Strictly increasing common target times.
#' @return An etr_landmark_registration list including registered trajectories.
#' @export
etr_register_landmarks <- function(x, source_landmarks, target_landmarks) {
  etr_validate(x, require_complete = TRUE)
  n <- dim(x$values)[1L]; nt <- length(x$time)
  nd <- dim(x$values)[3L]
  .etr_assert(nt >= 3L, "landmark registration requires >= 3 grid points")
  .etr_assert(is.matrix(source_landmarks) &&
                is.numeric(source_landmarks) &&
                nrow(source_landmarks) == n &&
                ncol(source_landmarks) >= 1L &&
                all(is.finite(source_landmarks)),
              "source_landmarks must be finite numeric matrix (curves x landmarks)")
  nl <- ncol(source_landmarks)
  .etr_assert(is.numeric(target_landmarks) &&
                length(target_landmarks) == nl &&
                all(is.finite(target_landmarks)),
              "target_landmarks must match the number of source landmarks")
  t0 <- x$time[1L]; t1 <- x$time[nt]
  .etr_assert(all(target_landmarks > t0 & target_landmarks < t1) &&
                all(diff(target_landmarks) > 0),
              "target landmarks must increase strictly within domain")
  .etr_assert(all(source_landmarks > t0 & source_landmarks < t1) &&
                all(apply(source_landmarks, 1L, function(z)
                  all(diff(z) > 0))),
              "source landmarks must increase strictly within domain")
  knots_target <- c(t0, target_landmarks, t1)
  inverse_warps <- matrix(NA_real_, nrow = n, ncol = nt)
  values <- array(NA_real_, c(n, nt, nd))
  for (i in seq_len(n)) {
    inverse_warps[i, ] <- stats::approx(
      knots_target, c(t0, source_landmarks[i, ], t1),
      xout = x$time, rule = 1, ties = "ordered")$y
    .etr_assert(all(is.finite(inverse_warps[i, ])) &&
                  all(diff(inverse_warps[i, ]) > 0),
                "inverse warp is not strictly increasing")
    for (j in seq_len(nd)) {
      values[i, , j] <- stats::approx(
        x$time, x$values[i, , j], xout = inverse_warps[i, ],
        rule = 1, ties = "ordered")$y
    }
  }
  .etr_assert(all(is.finite(values)), "registration produced nonfinite data")
  aligned <- etr_trajectory_set(
    x$time, values, x$curve_ids, x$dimension_names,
    x$metadata, x$coordinate_system, x$time_unit)
  dimnames(inverse_warps) <- list(x$curve_ids, NULL)
  structure(list(registered = aligned, inverse_warps = inverse_warps,
                 original_landmarks = source_landmarks,
                 target_landmarks = target_landmarks,
                 fixed_endpoints = c(t0, t1),
                 method = "prespecified_linear_landmarks"),
            class = "etr_landmark_registration")
}

#' Long-format inverse piecewise registration warps
#' @param registration Native landmark-registration output.
#' @return Data frame of target times and observed source times.
#' @export
etr_registration_warp_frame <- function(registration) {
  .etr_assert(inherits(registration, "etr_landmark_registration"),
              "registration must be a landmark-registration object")
  x <- registration$registered
  data.frame(curve_id = rep(x$curve_ids, each = length(x$time)),
             target_time = rep(x$time, times = length(x$curve_ids)),
             observed_source_time = as.vector(t(registration$inverse_warps)),
             row.names = NULL)
}
