# Stage 3: faithful Python-free R preprocessing, geometry and distances.
# Contracts inspected from published eyetrajectoriespy v1.2.0:
# preprocessing.py, kinematics.py, analysis.py.
# Python remains optional ONLY for independently run oracle tests.

.etr_preprocessing_scalar <- function(x,label,strict_positive=FALSE) {
  .etr_assert(is.numeric(x) && !is.logical(x) && length(x)==1L &&
                !is.na(x) && is.finite(x) &&
                (!strict_positive || x>0),
              paste(label,"must be a finite numeric scalar",
                    if(strict_positive) "> 0" else ""))
  as.numeric(x)
}

.etr_preprocessing_landmarks <- function(values,n,label) {
  .etr_assert(is.numeric(values) && !is.logical(values) &&
    length(values) %in% c(1L,n) && all(is.finite(values)),
    paste(label,"must be a finite scalar or one finite value per curve"))
  rep_len(as.numeric(values),n)
}

.etr_preprocessing_copy <- function(x,values=x$values,time=x$time,
                         coordinate_system=x$coordinate_system,
                         time_unit=x$time_unit,provenance_update=NULL) {
  etr_with_values(x,values=values,time=time,
    coordinate_system=coordinate_system,time_unit=time_unit,
    provenance_update=provenance_update)
}

#' Native coordinate normalization of the first two trajectory channels
#'
#' The published Python 1.2 algorithm simply divides the first two
#' coordinates by the supplied width and height. It does NOT clamp gaze
#' locations into [0,1] or change other channels. This is Python-free R code.
#' @param x Native trajectory set with at least two channels.
#' @param width,height Strictly positive finite coordinate extents.
#' @return Native trajectory set with normalized coordinate system.
#' @export
etr_normalize_coordinates <- function(x,width,height) {
  etr_validate(x)
  width <- .etr_preprocessing_scalar(width,"width",strict_positive=TRUE)
  height <- .etr_preprocessing_scalar(height,"height",strict_positive=TRUE)
  .etr_assert(dim(x$values)[3L]>=2L,"At least two channels required")
  values <- x$values
  values[,,1L] <- values[,,1L]/width
  values[,,2L] <- values[,,2L]/height
  .etr_preprocessing_copy(x,values=values,coordinate_system="normalized",
    provenance_update=list(coordinate_normalization=list(
      width=width,height=height)))
}

#' Native per-curve landmark centering (Python center_on_landmark counterpart)
#'
#' Independent of the older etr_center(), which centers each channel by its
#' own first point or mean, not by explicit supplied planar landmarks.
#' @param x Native trajectory set with at least two channels.
#' @param landmark_x,landmark_y Finite scalars or one landmark per curve.
#' @return Native trajectory set with landmark_relative coordinate system.
#' @export
etr_center_on_landmark <- function(x,landmark_x,landmark_y) {
  etr_validate(x)
  n <- dim(x$values)[1L]
  .etr_assert(dim(x$values)[3L]>=2L,"At least two channels required")
  lx <- .etr_preprocessing_landmarks(landmark_x,n,"landmark_x")
  ly <- .etr_preprocessing_landmarks(landmark_y,n,"landmark_y")
  values <- x$values
  for (i in seq_len(n)) {
    values[i,,1L] <- values[i,,1L]-lx[i]
    values[i,,2L] <- values[i,,2L]-ly[i]
  }
  .etr_preprocessing_copy(x,values=values,coordinate_system="landmark_relative",
    provenance_update=list(landmark_centering=list(per_curve=TRUE)))
}

#' Native normalization to an explicit time interval
#'
#' Mirrors published Python normalize_time(start,end), unlike the older
#' R etr_normalize_time(method = "unit"|"origin") convenience function.
#' @param x Native trajectory set.
#' @param start,end Finite endpoints with end greater than start.
#' @return Native trajectory set with time_unit="normalized".
#' @export
etr_normalize_time_interval <- function(x,start=0,end=1) {
  etr_validate(x)
  start <- .etr_preprocessing_scalar(start,"start")
  end <- .etr_preprocessing_scalar(end,"end")
  .etr_assert(end>start,"end must be greater than start")
  old <- x$time
  time <- start+(old-old[1L])/(old[length(old)]-old[1L])*(end-start)
  .etr_preprocessing_copy(x,time=time,time_unit="normalized",
    provenance_update=list(time_normalization=list(
      original_start=as.numeric(old[1L]),
      original_end=as.numeric(old[length(old)]),
      original_unit=x$time_unit,
      new_start=start,new_end=end)))
}

#' Native heading function with explicit low-speed/undefined policy
#'
#' Uses the same NumPy-gradient-compatible edge order as Python's
#' heading_function; has defined NA-vs-error behavior at stationary gaze.
#' Older etr_heading() does not expose the Python min_speed policy.
#' @param x Native complete trajectory set with >=3 time samples.
#' @param dimensions Two named planar channels (defaults to x/y).
#' @param min_speed Non-negative speed threshold.
#' @param undefined_policy Python "nan" maps to R NA; "raise" errors.
#' @return Native single-channel trajectory set containing wrapped heading.
#' @export
etr_heading_function <- function(x,dimensions=NULL,min_speed=0,
                                 undefined_policy=c("nan","raise")) {
  d <- .etr_geometry_derivatives(x,dimensions)
  values <- atan2(d$vy,d$vx)
  values <- .etr_geometry_policy(values,d$speed,min_speed,
                                 undefined_policy,x$curve_ids,"heading")
  .etr_geometry_result(x,values,"heading",coordinate_system="unknown")
}

#' Native trajectory tortuosity table with Python-style definition
#'
#' Produces path-length, endpoint displacement, ratio and undefined flag
#' for selected named planar dimensions. Undefined 0/0 ratios map to R NA.
#' Python DataFrame.attrs provenance is not yet expressible in the native
#' R trajectory schema, and is deliberately not fabricated.
#' @param x Native complete trajectory set.
#' @param dimensions Two named planar channels (defaults to x/y).
#' @param min_displacement Non-negative endpoint displacement threshold.
#' @param undefined_policy "nan" (R NA) or "raise".
#' @return One-row-per-curve base R data.frame with key metrics/metadata.
#' @export
etr_trajectory_tortuosity_frame <- function(
    x,dimensions=NULL,min_displacement=0,
    undefined_policy=c("nan","raise")) {
  idx <- .etr_geometry_planar_indices(
    x,dimensions,require_complete=TRUE)
  threshold <- .etr_geometry_scalar(
    min_displacement,"min_displacement",nonnegative=TRUE)
  policy <- match.arg(undefined_policy)
  n <- dim(x$values)[1L]
  nt <- length(x$time)
  path <- displacement <- numeric(n)
  for(i in seq_len(n)){
    xx <- x$values[i,,idx[1L]]
    yy <- x$values[i,,idx[2L]]
    path[i] <- sum(sqrt(diff(xx)^2+diff(yy)^2))
    displacement[i] <- sqrt((xx[nt]-xx[1L])^2+
                              (yy[nt]-yy[1L])^2)
  }
  undefined <- displacement<=threshold
  if(any(undefined) && policy=="raise")
    stop("trajectory tortuosity is undefined where endpoint displacement ",
         "<= min_displacement=",threshold,"; affected curves: ",
         paste(utils::head(x$curve_ids[undefined],8L),collapse=", "),
         call.=FALSE)
  ratios <- path/displacement
  ratios[undefined] <- NA_real_
  out <- data.frame(
    curve_id=x$curve_ids,
    path_length=as.numeric(path),
    endpoint_displacement=as.numeric(displacement),
    tortuosity=as.numeric(ratios),
    undefined=as.logical(undefined),
    stringsAsFactors=FALSE)
  for (name in names(x$metadata)) if (!name %in% names(out))
    out[[name]] <- x$metadata[[name]]
  out
}

.etr_preprocessing_dimensions <- function(x,dimensions=NULL) {
  etr_validate(x,require_complete=TRUE)
  if(is.null(dimensions)) return(seq_along(x$dimension_names))
  .etr_assert(is.character(dimensions) && length(dimensions)>=1L &&
              !anyNA(dimensions) && all(nzchar(dimensions)) &&
              !anyDuplicated(dimensions),
              "dimensions must be distinct nonempty named channels")
  out <- match(dimensions,x$dimension_names)
  .etr_assert(!anyNA(out),"Unknown trajectory dimensions")
  out
}

#' Native pairwise discrete Frechet distances for selected channels
#'
#' The elapsed time grid does not appear in the discrete Frechet recurrence.
#' @param x Complete native common-grid trajectories.
#' @param dimensions Optional ordered named channel selection.
#' @param dimension_weights Optional non-negative weights, at least one > 0.
#' @return Symmetric numeric n_curves by n_curves matrix with zero diagonal,
#'   without labels (matching the Python NumPy array contract).
#' @export
etr_pairwise_frechet <- function(x,dimensions=NULL,
                                 dimension_weights=NULL) {
  idx <- .etr_preprocessing_dimensions(x,dimensions)
  if(is.null(dimension_weights)) {
    weights <- rep(1,length(idx))
  } else {
    .etr_assert(is.numeric(dimension_weights) &&
                !is.logical(dimension_weights) &&
                length(dimension_weights)==length(idx) &&
                all(is.finite(dimension_weights)) &&
                all(dimension_weights>=0) &&
                any(dimension_weights>0),
                "dimension_weights require finite nonnegative values and at least one positive value")
    weights <- as.numeric(dimension_weights)
  }
  n <- dim(x$values)[1L]
  ans <- matrix(0,n,n)
  if(n>=2L) for(i in seq_len(n-1L)) for(j in (i+1L):n) {
    a <- matrix(x$values[i,,idx,drop=FALSE],
                nrow=length(x$time),ncol=length(idx))
    b <- matrix(x$values[j,,idx,drop=FALSE],
                nrow=length(x$time),ncol=length(idx))
    ans[i,j] <- etr_frechet(a,b,weights)
    ans[j,i] <- ans[i,j]
  }
  ans
}

#' Python-index-compatible nearest trajectories under native functional L2
#'
#' @param x Complete native trajectories.
#' @param index Zero-based curve index, matching Python's public function.
#' @param n_neighbors Positive requested neighbor count.
#' @param python_boundary_mode Opt in to the frozen Python 1.2 NumPy
#'   slice-index contract for n_neighbors: Python Boolean TRUE acts as
#'   one and integer-valued doubles are rejected. The default native R
#'   contract accepts finite integer-valued numeric counts.
#' @return Zero-based integer indices in increasing distance order.
#' @details Ties use ascending original index deterministically. The Python
#'   NumPy default sort makes tie ordering platform/version-dependent, so
#'   equivalence is only asserted for tests with unique distances.
#' @export
etr_nearest_trajectory_indices <- function(x,index,n_neighbors=5L,
    python_boundary_mode=FALSE) {
  .etr_assert(is.logical(python_boundary_mode) &&
    length(python_boundary_mode)==1L&&!is.na(python_boundary_mode),
    "python_boundary_mode must be a nonmissing logical scalar")
  etr_validate(x,require_complete=TRUE)
  n <- dim(x$values)[1L]
  .etr_assert(is.numeric(index) && !is.logical(index) &&
                length(index)==1L && is.finite(index) &&
                index==as.integer(index) && index>=0L && index<n,
              "index must be a valid zero-based curve index")
  if(isTRUE(python_boundary_mode)){
    # Python analysis.py validates >0 then slices np.ndarray[:n_neighbors].
    # NumPy accepts bool (via __index__) but rejects even float 1.0.
    .etr_assert((is.integer(n_neighbors)||is.logical(n_neighbors)) &&
      length(n_neighbors)==1L&&!is.na(n_neighbors),
      "n_neighbors must be a Python integer or Boolean slice index")
    n_neighbors<-as.integer(n_neighbors)
  }
  .etr_assert(is.numeric(n_neighbors) && !is.logical(n_neighbors) &&
                length(n_neighbors)==1L && is.finite(n_neighbors) &&
                n_neighbors==as.integer(n_neighbors) &&
                n_neighbors>=1L,
              "n_neighbors must be a positive integer")
  d <- etr_pairwise_l2(x)
  row <- as.integer(index)+1L
  eligible <- setdiff(seq_len(n),row)
  ord <- eligible[order(d[row,eligible],eligible,method="radix")]
  as.integer(utils::head(ord,as.integer(n_neighbors))-1L)
}
