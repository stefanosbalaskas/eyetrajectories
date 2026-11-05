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
  # NumPy sums an empty (n_time, 0) weighted square array to 0.
  # Avoid R sweep's zero-width recycling warning on that source domain.
  if(isTRUE(python_boundary_mode) && ncol(a)==0L)return(0)
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
#' @param return_coupling When TRUE, return a deterministic optimal 0-based
#'   coupling path, local distances, geometry and source provenance, matching
#'   the frozen Python 1.2 recursion. The default returns only distance.
#' @export
etr_frechet <- function(a, b, dimension_weights = NULL,
                        return_coupling = FALSE) {
  .etr_assert(is.logical(return_coupling) && length(return_coupling)==1L &&
                !is.na(return_coupling),
              "return_coupling must be boolean")
  a <- .etr_points(a, "a"); b <- .etr_points(b, "b")
  .etr_assert(ncol(a) == ncol(b), "channel count mismatch")
  dw <- .etr_dimweights(ncol(a), dimension_weights)
  # Do not break existing native scalar all-zero-weight results; a source
  # coupling requires the Python validator's at-least-one-positive rule.
  if(isTRUE(return_coupling))
    .etr_assert(any(dw>0),"dimension_weights must contain at least one positive value")
  m <- nrow(a); n <- nrow(b)
  .etr_assert(as.double(m) * as.double(n) <= 5e6,
              "discrete Frechet input too long for dense dynamic programming")
  z <- matrix(Inf, m, n)
  if(isTRUE(return_coupling)) {
    predecessor_i <- matrix(NA_integer_,m,n)
    predecessor_j <- matrix(NA_integer_,m,n)
  }
  for (i in seq_len(m)) for (j in seq_len(n)) {
    cost <- .etr_point_cost(a[i, ], b[j, ], dw)
    if (i == 1L && j == 1L) {
      z[i, j] <- cost
    } else {
      # Frozen Python source chooses diagonal before advance_a before
      # advance_b, retaining the first candidate in a cost tie.
      predecessors <- numeric(0)
      pi <- integer(0); pj <- integer(0)
      if (i > 1L && j > 1L) {
        predecessors<-c(predecessors,z[i-1L,j-1L]);
        pi<-c(pi,i-1L); pj<-c(pj,j-1L)
      }
      if (i > 1L) {
        predecessors<-c(predecessors,z[i-1L,j]);
        pi<-c(pi,i-1L); pj<-c(pj,j)
      }
      if (j > 1L) {
        predecessors<-c(predecessors,z[i,j-1L]);
        pi<-c(pi,i); pj<-c(pj,j-1L)
      }
      winner<-which.min(predecessors)
      z[i,j] <- max(cost,predecessors[winner])
      if (isTRUE(return_coupling)) {
        predecessor_i[i,j]<-pi[winner]
        predecessor_j[i,j]<-pj[winner]
      }
    }
  }
  distance <- as.numeric(z[m,n])
  if (!isTRUE(return_coupling)) return(distance)
  # The published coupling uses zero-based indices and includes endpoints.
  i<-m; j<-n
  path<-matrix(integer(0),ncol=2L)
  repeat {
    path<-rbind(path,c(i-1L,j-1L))
    if(i==1L && j==1L)break
    ii<-predecessor_i[i,j]; jj<-predecessor_j[i,j]
    i<-ii; j<-jj
  }
  path<-path[rev(seq_len(nrow(path))),,drop=FALSE]
  storage.mode(path)<-"integer"
  local_distances<-vapply(seq_len(nrow(path)),function(k)
    .etr_point_cost(a[path[k,1L]+1L,],b[path[k,2L]+1L,],dw),numeric(1L))
  structure(list(
    distance=distance,coupling=path,local_distances=local_distances,
    n_points_a=m,n_points_b=n,n_dimensions=ncol(a),
    provenance=list(operation="discrete_frechet_distance",
      local_metric="weighted_euclidean",dimension_weights=unname(dw),
      continuous_frechet=FALSE,elapsed_time_used=FALSE,
      sample_order_preserved=TRUE,backtracking_allowed=FALSE,
      interpolation=FALSE,resampling=FALSE,
      coordinate_normalization=FALSE,path_simplification=FALSE,
      tie_break_order=c("diagonal","advance_a","advance_b"),
      optimal_coupling_not_necessarily_unique=TRUE)
  ),class=c("etr_frechet_result","list"))
}

#' Dynamic time warping with symmetric1 or symmetric2 step weighting
#'
#' The default symmetric1 recursion retains the original native scalar
#' behavior. Explicit Python 1.2 options allow constrained paths, deterministic
#' backtracking, symmetric2 weights and normalization by n_points_a+n_points_b.
#' @inheritParams etr_frechet
#' @param window_radius Optional non-negative integer Sakoe-Chiba index band.
#'   Must be at least the difference in sequence lengths.
#' @param step_pattern Exactly "symmetric1" (default) or "symmetric2".
#' @param normalize Logical scalar, available only for symmetric2.
#' @param return_path When TRUE, return a deterministic 0-based path, step
#'   weights, local/weighted costs, denominators and provenance.
#' @export
etr_dtw <- function(a, b, dimension_weights = NULL,
                    window_radius = NULL,step_pattern = "symmetric1",
                    normalize = FALSE,return_path = FALSE) {
  .etr_assert(is.character(step_pattern) && length(step_pattern)==1L &&
                !is.na(step_pattern) && step_pattern %in% c("symmetric1","symmetric2"),
              "step_pattern must be 'symmetric1' or 'symmetric2'")
  .etr_assert(is.logical(normalize) && length(normalize)==1L &&
                !is.na(normalize),"normalize must be boolean")
  .etr_assert(is.logical(return_path) && length(return_path)==1L &&
                !is.na(return_path),"return_path must be boolean")
  .etr_assert(!isTRUE(normalize) || identical(step_pattern,"symmetric2"),
              "normalize=TRUE is available only for symmetric2")
  a <- .etr_points(a, "a"); b <- .etr_points(b, "b")
  .etr_assert(ncol(a) == ncol(b), "channel count mismatch")
  m <- nrow(a); n <- nrow(b)
  if(!is.null(window_radius)) {
    .etr_assert(is.integer(window_radius) && length(window_radius)==1L &&
                  !is.na(window_radius),"window_radius must be an integer or NULL")
    .etr_assert(window_radius>=0L,"window_radius must be non-negative")
    .etr_assert(window_radius>=abs(m-n),
                "window_radius is too small to connect sequence endpoints")
  }
  dw <- .etr_dimweights(ncol(a), dimension_weights)
  is_default <- is.null(window_radius) && identical(step_pattern,"symmetric1") &&
    !normalize && !return_path
  # Preserve the pre-existing all-zero-weight scalar default. All source
  # extension calls require at least one positive weight, as Python does.
  if(!is_default)
    .etr_assert(any(dw>0),"dimension_weights must contain at least one positive value")
  .etr_assert((as.double(m) + 1) * (as.double(n) + 1) <= 5e6,
              "DTW input too long for dense dynamic programming")
  z<-matrix(Inf,m,n)
  if(isTRUE(return_path)) {
    predecessor_i<-matrix(NA_integer_,m,n)
    predecessor_j<-matrix(NA_integer_,m,n)
    transition_weight<-matrix(NA_real_,m,n)
  }
  initial_weight<-if(step_pattern=="symmetric2") 2 else 1
  z[1L,1L]<-initial_weight*.etr_point_cost(a[1L,],b[1L,],dw)
  if(isTRUE(return_path))transition_weight[1L,1L]<-initial_weight
  for(i in seq_len(m)) {
    lower<-if(is.null(window_radius))1L else max(1L,i-window_radius)
    upper<-if(is.null(window_radius))n else min(n,i+window_radius)
    if(lower>upper)next
    for(j in seq.int(lower,upper)) {
      if(i==1L && j==1L)next
      local<-.etr_point_cost(a[i,],b[j,],dw)
      candidates<-numeric(0); pi<-integer(0); pj<-integer(0); ww<-numeric(0)
      # Python order: diagonal, advancing a, advancing b.
      if(i>1L && j>1L && is.finite(z[i-1L,j-1L])) {
        weight<-if(step_pattern=="symmetric2")2 else 1
        candidates<-c(candidates,z[i-1L,j-1L]+weight*local)
        pi<-c(pi,i-1L);pj<-c(pj,j-1L);ww<-c(ww,weight)
      }
      if(i>1L && is.finite(z[i-1L,j])) {
        candidates<-c(candidates,z[i-1L,j]+local)
        pi<-c(pi,i-1L);pj<-c(pj,j);ww<-c(ww,1)
      }
      if(j>1L && is.finite(z[i,j-1L])) {
        candidates<-c(candidates,z[i,j-1L]+local)
        pi<-c(pi,i);pj<-c(pj,j-1L);ww<-c(ww,1)
      }
      if(!length(candidates))next
      winner<-which.min(candidates)
      z[i,j]<-candidates[winner]
      if(isTRUE(return_path)) {
        predecessor_i[i,j]<-pi[winner]
        predecessor_j[i,j]<-pj[winner]
        transition_weight[i,j]<-ww[winner]
      }
    }
  }
  raw_distance<-as.numeric(z[m,n])
  .etr_assert(is.finite(raw_distance),
              "No admissible DTW path reaches the endpoint under window_radius")
  denominator<-if(step_pattern=="symmetric2")as.double(m+n) else NULL
  normalized_distance<-if(!is.null(denominator))raw_distance/denominator else NULL
  distance<-if(isTRUE(normalize))normalized_distance else raw_distance
  if(!isTRUE(return_path))return(distance)
  i<-m;j<-n
  path<-matrix(integer(0),ncol=2L)
  path_weights<-numeric(0)
  repeat {
    path<-rbind(path,c(i-1L,j-1L))
    path_weights<-c(path_weights,transition_weight[i,j])
    if(i==1L && j==1L)break
    ii<-predecessor_i[i,j];jj<-predecessor_j[i,j]
    .etr_assert(!is.na(ii) && !is.na(jj),
                "DTW predecessor chain is incomplete")
    i<-ii;j<-jj
  }
  path<-path[rev(seq_len(nrow(path))),,drop=FALSE]
  storage.mode(path)<-"integer"
  path_weights<-rev(path_weights)
  local_distances<-vapply(seq_len(nrow(path)),function(k)
    .etr_point_cost(a[path[k,1L]+1L,],b[path[k,2L]+1L,],dw),numeric(1L))
  weighted_local_costs<-local_distances*path_weights
  .etr_assert(isTRUE(all.equal(sum(weighted_local_costs),raw_distance,
                   tolerance=1e-8)),
              "DTW path audit does not reproduce the cumulative cost")
  structure(list(distance=distance,path=path,
    local_distances=local_distances,path_length=nrow(path),
    mean_local_distance=mean(local_distances),
    n_points_a=m,n_points_b=n,n_dimensions=ncol(a),
    window_radius=window_radius,raw_distance=raw_distance,
    normalized_distance=normalized_distance,step_pattern=step_pattern,
    normalization_denominator=denominator,step_weights=path_weights,
    weighted_local_costs=weighted_local_costs,
    provenance=list(operation="dynamic_time_warping_distance",
      local_metric="weighted_euclidean",dimension_weights=unname(dw),
      distance_aggregation="weighted_sum",step_pattern=step_pattern,
      normalizable=step_pattern=="symmetric2",
      normalization_requested=normalize,
      normalization_denominator=denominator,
      distance_returned=if(normalize)"normalized" else "raw_cumulative",
      recorded_time_used=FALSE,sequence_index_warping=TRUE,
      sample_order_preserved=TRUE,backtracking_allowed=FALSE,
      window_constraint=if(is.null(window_radius))"unconstrained"
      else "sakoe_chiba_index_band",window_radius=window_radius,
      interpolation=FALSE,resampling=FALSE,smoothing=FALSE,
      coordinate_normalization=FALSE,path_simplification=FALSE,
      missing_value_deletion=FALSE,automatic_step_pattern_selection=FALSE,
      automatic_window_selection=FALSE,
      tie_break_order=c("diagonal","advance_a","advance_b"),
      optimal_path_not_necessarily_unique=TRUE)
  ),class=c("etr_dtw_result","list"))
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
