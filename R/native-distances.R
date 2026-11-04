# Internal validator for ordered point sequence matrices.
.etr_points <- function(a, name = "trajectory") {
  .etr_assert(is.matrix(a) && is.numeric(a) && nrow(a) >= 1L &&
                ncol(a) >= 1L && all(is.finite(a)),
              paste(name, "must be a complete numeric points-by-dimensions matrix"))
  a
}
.etr_dimweights <- function(d, dimension_weights) {
  if (is.null(dimension_weights)) return(rep(1, d))
  .etr_assert(is.numeric(dimension_weights) && length(dimension_weights) == d &&
                all(is.finite(dimension_weights)) && all(dimension_weights >= 0),
              "dimension_weights must be finite, non-negative and match dimensions")
  dimension_weights
}
.etr_curve <- function(x, i) {
  z <- x$values[i, , , drop = FALSE]
  matrix(z, nrow = dim(z)[2], ncol = dim(z)[3])
}
.etr_point_cost <- function(a, b, weights) {
  sqrt(sum((a - b)^2 * weights))
}

#' Integrated functional L2 distance between complete curves
#' @param a Points-by-channels numeric matrix.
#' @param b Points-by-channels numeric matrix of same shape.
#' @param time Shared increasing time grid.
#' @param dimension_weights Optional dimension weights (non-negative).
#' @param python_boundary_mode Opt in to the frozen Python 1.2
#'   np.asarray(dtype=float) coercion of numeric-string, Boolean and
#'   complex two-dimensional point matrices, using only their real parts,
#'   and compatible one-dimensional dimension weights. Source mode permits
#'   infinity and source NaN arithmetic where Python does, but rejects NaN
#'   in the input point matrices. The default native validation remains
#'   strict and finite. Arbitrary Python objects remain unsupported.
#' @export
etr_l2_distance <- function(a, b, time, dimension_weights = NULL,
                            python_boundary_mode = FALSE) {
  .etr_assert(is.logical(python_boundary_mode) &&
    length(python_boundary_mode)==1L && !is.na(python_boundary_mode),
    "python_boundary_mode must be a nonmissing logical scalar")
  if(isTRUE(python_boundary_mode)) {
    # Python analysis.py::functional_l2_distance applies np.asarray to
    # both arguments before validating shape and missing data.
    coerce_states <- function(z,label){
      .etr_assert(is.matrix(z) && nrow(z)>=1L && ncol(z)>=0L &&
        (is.numeric(z)||is.character(z)||is.logical(z)||
          is.complex(z)),
        paste(label,"must be a 2D numeric-compatible state matrix"))
      converted<-suppressWarnings(as.numeric(z))
      .etr_assert(length(converted)==length(z) &&
        all(!is.na(converted)),
        paste(label,"must contain numeric-compatible states without NaN"))
      matrix(converted,nrow=nrow(z),ncol=ncol(z))
    }
    a<-coerce_states(a,"a")
    b<-coerce_states(b,"b")
    if(!is.null(dimension_weights)) {
      .etr_assert(is.atomic(dimension_weights) &&
        is.null(dim(dimension_weights)) &&
        (is.numeric(dimension_weights)||
          is.character(dimension_weights)||
          is.logical(dimension_weights)||
          is.complex(dimension_weights)),
        "dimension_weights must be a 1D numeric-compatible vector")
      dimension_weights<-suppressWarnings(as.numeric(dimension_weights))
    }
  } else {
    a <- .etr_points(a, "a"); b <- .etr_points(b, "b")
  }
  .etr_assert(identical(dim(a), dim(b)), "curve dimensions must be identical")
  .etr_assert(length(time) == nrow(a), "time length must equal number of samples")
  w <- etr_trapezoid_weights(time,
    python_boundary_mode=python_boundary_mode)
  if(isTRUE(python_boundary_mode) && !is.null(dimension_weights)) {
    # Published Python validates only shape and dw<0. Thus +Inf and
    # NaN weights are permitted in source mode and propagate through
    # arithmetic, whereas strict native R always rejects nonfinite dw.
    .etr_assert(length(dimension_weights)==ncol(a) &&
      all(!is.na(dimension_weights)|is.nan(dimension_weights)) &&
      !any(dimension_weights<0,na.rm=TRUE),
      "dimension_weights must be non-negative with one value per dimension")
    dw<-dimension_weights
  } else {
    dw <- .etr_dimweights(ncol(a), dimension_weights)
  }
  sqrt(sum(rowSums(sweep((a - b)^2, 2L, dw, "*")) * w))
}

#' Pairwise integrated L2 distances
#' @param x Complete trajectory collection.
#' @param dimension_weights Optional non-negative channel weights.
#' @export
etr_pairwise_l2 <- function(x, dimension_weights = NULL) {
  etr_validate(x, require_complete = TRUE)
  n <- dim(x$values)[1]
  d <- matrix(0, n, n, dimnames = list(x$curve_ids, x$curve_ids))
  for (i in seq_len(n)) for (j in seq_len(n)) if (i < j) {
    d[i, j] <- etr_l2_distance(.etr_curve(x, i), .etr_curve(x, j),
                               x$time, dimension_weights)
    d[j, i] <- d[i, j]
  }
  d
}

#' Discrete Fréchet distance for two ordered point sequences
#'
#' This is discrete, not continuous Fréchet distance; timestamps are not used.
#' @param a Numeric points-by-channels matrix.
#' @param b Numeric points-by-channels matrix.
#' @param dimension_weights Optional non-negative channel weights.
#' @export
etr_frechet <- function(a, b, dimension_weights = NULL) {
  a <- .etr_points(a, "a"); b <- .etr_points(b, "b")
  .etr_assert(ncol(a) == ncol(b), "channel count mismatch")
  dw <- .etr_dimweights(ncol(a), dimension_weights)
  m <- nrow(a); n <- nrow(b)
  .etr_assert(as.double(m) * as.double(n) <= 5e6,
              "discrete Frechet input too long for dense dynamic programming")
  z <- matrix(Inf, m, n)
  for (i in seq_len(m)) for (j in seq_len(n)) {
    cost <- .etr_point_cost(a[i, ], b[j, ], dw)
    if (i == 1L && j == 1L) z[i, j] <- cost else {
      prev <- c(if (i > 1L && j > 1L) z[i-1L, j-1L],
                if (i > 1L) z[i-1L, j],
                if (j > 1L) z[i, j-1L])
      z[i, j] <- max(cost, min(prev))
    }
  }
  z[m, n]
}

#' Dynamic time warping with symmetric1 step weighting
#'
#' Every visited point-pair adds its Euclidean local distance.
#' No normalization, interpolation, or timestamp weighting occurs.
#' @inheritParams etr_frechet
#' @export
etr_dtw <- function(a, b, dimension_weights = NULL) {
  a <- .etr_points(a, "a"); b <- .etr_points(b, "b")
  .etr_assert(ncol(a) == ncol(b), "channel count mismatch")
  dw <- .etr_dimweights(ncol(a), dimension_weights)
  m <- nrow(a); n <- nrow(b)
  .etr_assert((as.double(m) + 1) * (as.double(n) + 1) <= 5e6,
              "DTW input too long for dense dynamic programming")
  z <- matrix(Inf, m+1L, n+1L)
  z[1, 1] <- 0
  for (i in seq_len(m)) for (j in seq_len(n)) {
    cost <- .etr_point_cost(a[i, ], b[j, ], dw)
    z[i+1L, j+1L] <- cost + min(z[i, j], z[i, j+1L], z[i+1L, j])
  }
  z[m+1L, n+1L]
}

#' Pairwise DTW distances over complete curves
#' @inheritParams etr_pairwise_l2
#' @export
etr_pairwise_dtw <- function(x, dimension_weights = NULL) {
  etr_validate(x, require_complete = TRUE)
  n <- dim(x$values)[1]
  d <- matrix(0, n, n, dimnames = list(x$curve_ids, x$curve_ids))
  for (i in seq_len(n)) for (j in seq_len(n)) if (i < j) {
    d[i, j] <- etr_dtw(.etr_curve(x, i), .etr_curve(x, j), dimension_weights)
    d[j, i] <- d[i, j]
  }
  d
}
