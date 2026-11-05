# Full Python 1.2 sequence-distance contracts, implemented entirely in R.
# Source of record: eyetrajectoriespy v1.2.0, analysis.py and types.py.
# Python/reticulate are used only by opt-in tests, not any function here.

# Bounded native analogue of Python 1.2 np.asarray(..., dtype=float)
# for 2D point sequences: each element is converted separately, never
# after R's unlist() has promoted mixed bool/string scalars to text.
.etr_distance_source_points <- function(value,label) {
  candidate <- value
  if(is.list(value)&&!is.data.frame(value)&&is.null(dim(value))) {
    .etr_assert(length(value)>0L,
      paste(label,"must contain at least one point"))
    rows <- lapply(value,function(row) {
      if(is.list(row)&&is.null(dim(row))&&!is.data.frame(row)) {
        .etr_assert(length(row)>0L&&all(vapply(row,function(z)
          is.atomic(z)&&is.null(dim(z))&&!is.factor(z)&&
          length(z)==1L&&
          (is.numeric(z)||is.logical(z)||is.character(z)),
          logical(1L))),
          paste(label,"requires numeric-compatible point rows"))
        return(vapply(row,function(z)
          suppressWarnings(as.numeric(z)),numeric(1L),
          USE.NAMES=FALSE))
      }
      .etr_assert(is.atomic(row)&&is.null(dim(row))&&!is.factor(row)&&
        (is.numeric(row)||is.logical(row)||is.character(row))&&
        length(row)>0L,
        paste(label,"requires numeric-compatible point rows"))
      suppressWarnings(as.numeric(row))
    })
    d <- length(rows[[1L]])
    .etr_assert(all(lengths(rows)==d),
      paste(label,"point rows must have equal dimensions"))
    candidate <- matrix(unlist(rows,use.names=FALSE),
      nrow=length(rows),ncol=d,byrow=TRUE)
  } else {
    .etr_assert(is.matrix(value)&&!is.factor(value)&&
      (is.numeric(value)||is.logical(value)||is.character(value)),
      paste(label,"must be a 2D numeric-compatible point matrix"))
    candidate <- matrix(suppressWarnings(as.numeric(value)),
      nrow=nrow(value),ncol=ncol(value))
  }
  .etr_assert(nrow(candidate)>=1L&&ncol(candidate)>=1L&&
    all(is.finite(candidate)),
    paste(label,"must be a finite complete point-by-dimension matrix"))
  candidate
}

.etr_distance_source_weights <- function(w,d) {
  if(is.list(w)&&!is.data.frame(w)&&is.null(dim(w))) {
    .etr_assert(length(w)==d&&all(vapply(w,function(z)
      is.atomic(z)&&is.null(dim(z))&&!is.factor(z)&&
      length(z)==1L&&(is.numeric(z)||is.logical(z)||is.character(z)),
      logical(1L))),
      "dimension_weights must contain one numeric-compatible scalar per dimension")
    w <- vapply(w,function(z)suppressWarnings(as.numeric(z)),
      numeric(1L),USE.NAMES=FALSE)
  } else {
    .etr_assert(is.atomic(w)&&is.null(dim(w))&&!is.factor(w)&&
      (is.numeric(w)||is.logical(w)||is.character(w))&&
      length(w)==d,
      "dimension_weights must be a numeric-compatible vector")
    w <- suppressWarnings(as.numeric(w))
  }
  .etr_assert(all(is.finite(w))&&all(w>=0)&&any(w>0),
    "dimension_weights must be finite non-negative and contain at least one positive value")
  w
}

.etr_distances_inputs <- function(a,b,dimension_weights=NULL,
                                  operation="distance",
                                  python_boundary_mode=FALSE) {
  .etr_assert(is.logical(python_boundary_mode)&&
    length(python_boundary_mode)==1L&&!is.na(python_boundary_mode),
    "python_boundary_mode must be a nonmissing logical scalar")
  if(isTRUE(python_boundary_mode)) {
    a <- .etr_distance_source_points(a,"a")
    b <- .etr_distance_source_points(b,"b")
  } else {
    a <- .etr_points(a,"a")
    b <- .etr_points(b,"b")
  }
  .etr_assert(ncol(a)==ncol(b),
              paste(operation,": a and b must have the same number of dimensions"))
  d <- ncol(a)
  if (is.null(dimension_weights)) {
    w <- rep(1,d)
  } else if(isTRUE(python_boundary_mode)) {
    w <- .etr_distance_source_weights(dimension_weights,d)
  } else {
    .etr_assert(is.numeric(dimension_weights) &&
      !is.logical(dimension_weights) && length(dimension_weights)==d &&
      all(is.finite(dimension_weights)) && all(dimension_weights>=0) &&
      any(dimension_weights>0),
      "dimension_weights must be finite non-negative and contain at least one positive value")
    w <- as.numeric(dimension_weights)
  }
  # Bound memory for full dynamic-programming predecessor and path audit.
  # This explicit R resource limit is stricter than the upstream Python API.
  .etr_assert(as.double(nrow(a))*as.double(nrow(b))<=5e6,
              paste(operation,": too many sample pairs for dense R dynamic programming"))
  list(a=a,b=b,weights=w,n_a=nrow(a),n_b=nrow(b),d=d)
}

.etr_dtw_local_cost <- function(a,b,weights) {
  m <- nrow(a); n <- nrow(b)
  out <- matrix(0,m,n)
  for(i in seq_len(m)) for(j in seq_len(n)) {
    out[i,j] <- sqrt(sum((a[i,]-b[j,])^2*weights))
  }
  out
}

.etr_dtw_backtrack <- function(pi,pj,local,weights=NULL) {
  i <- nrow(pi); j <- ncol(pi)
  out <- list()
  w <- numeric()
  repeat {
    out[[length(out)+1L]] <- c(i-1L,j-1L) # Python zero-based indices
    if(!is.null(weights)) w <- c(w,weights[i,j])
    if(i==1L && j==1L) break
    i_new <- pi[i,j]; j_new <- pj[i,j]
    .etr_assert(i_new>=1L && j_new>=1L &&
      i_new<=i && j_new<=j && (i_new<i || j_new<j),
      "incomplete monotone predecessor chain")
    i <- i_new; j <- j_new
  }
  path <- do.call(rbind,rev(out))
  storage.mode(path) <- "integer"
  colnames(path) <- NULL
  aligned <- as.numeric(local[cbind(path[,1L]+1L,path[,2L]+1L)])
  list(path=path,local_distances=aligned,
       step_weights=if(is.null(weights))NULL else rev(w))
}

#' Native full discrete Frechet distance, with an optimal coupling
#'
#' Implements Python 1.2's deterministic tie preference
#' diagonal, advance a, advance b, with zero-based coupling indices.
#' @param a,b Complete numeric point-by-dimension matrices.
#' @param dimension_weights Nonnegative weights, at least one positive.
#' @param return_coupling Logical; return a scalar if FALSE, or a native
#'   result with full coupling, local distances and provenance if TRUE.
#' @param python_boundary_mode When TRUE, accept source NumPy-like finite
#'   2D point matrices and nested scalar rows with numeric strings and
#'   logical values, and numeric-compatible nonnegative dimension weights.
#'   FALSE preserves strict native R matrix/weight validation.
#'   Other Python coercion classes and >5e6 point pairs are not promised.
#' @return Distance scalar or an etr_discrete_frechet_result list.
#' @export
etr_discrete_frechet <- function(a,b,dimension_weights=NULL,
                                 return_coupling=FALSE,
                                 python_boundary_mode=FALSE) {
  .etr_assert(is.logical(return_coupling) &&
    length(return_coupling)==1L && !is.na(return_coupling),
    "return_coupling must be TRUE or FALSE")
  x <- .etr_distances_inputs(a,b,dimension_weights,"discrete Frechet",
    python_boundary_mode=python_boundary_mode)
  local <- .etr_dtw_local_cost(x$a,x$b,x$weights)
  n <- x$n_a; m <- x$n_b
  cum <- matrix(Inf,n,m)
  pi <- pj <- matrix(0L,n,m)
  cum[1L,1L] <- local[1L,1L]
  if(n>1L) for(i in 2L:n) {
    cum[i,1L] <- max(cum[i-1L,1L],local[i,1L])
    pi[i,1L] <- i-1L; pj[i,1L] <- 1L
  }
  if(m>1L) for(j in 2L:m) {
    cum[1L,j] <- max(cum[1L,j-1L],local[1L,j])
    pi[1L,j] <- 1L; pj[1L,j] <- j-1L
  }
  if(n>1L && m>1L) for(i in 2L:n) for(j in 2L:m) {
    candidates <- c(cum[i-1L,j-1L],cum[i-1L,j],cum[i,j-1L])
    chosen <- which.min(candidates)
    cum[i,j] <- max(local[i,j],candidates[chosen])
    if(chosen==1L) {
      pi[i,j] <- i-1L; pj[i,j] <- j-1L
    } else if(chosen==2L) {
      pi[i,j] <- i-1L; pj[i,j] <- j
    } else {
      pi[i,j] <- i; pj[i,j] <- j-1L
    }
  }
  distance <- as.numeric(cum[n,m])
  if(!return_coupling) return(distance)
  coupling <- .etr_dtw_backtrack(pi,pj,local)
  .etr_assert(isTRUE(all.equal(max(coupling$local_distances),distance,
                                 tolerance=1e-11)),
              "Frechet coupling maximum does not match distance")
  structure(list(
    distance=distance,coupling=coupling$path,
    local_distances=coupling$local_distances,
    n_points_a=as.integer(n),n_points_b=as.integer(m),
    n_dimensions=as.integer(x$d),
    provenance=list(
      operation="discrete_frechet_distance",
      local_metric="weighted_euclidean",
      dimension_weights=as.numeric(x$weights),
      continuous_frechet=FALSE,elapsed_time_used=FALSE,
      sample_order_preserved=TRUE,backtracking_allowed=FALSE,
      interpolation=FALSE,resampling=FALSE,
      coordinate_normalization=FALSE,path_simplification=FALSE,
      tie_break_order=c("diagonal","advance_a","advance_b"),
      optimal_coupling_not_necessarily_unique=TRUE)
  ),class="etr_discrete_frechet_result")
}

#' Native dynamic time warping with Sakoe-Chiba window and full path audit
#'
#' Implements the published Python 1.2 symmetric1/symmetric2 recursions,
#' deterministic diagonal-first tie breaking and path-independent
#' normalization for symmetric2 only. Recorded sample times are unused.
#' @inheritParams etr_discrete_frechet
#' @param window_radius NULL or non-negative integer Sakoe-Chiba band width
#'   in sample indices. Must connect both sequence endpoints.
#' @param step_pattern "symmetric1" (raw cost) or "symmetric2" (diagonal
#'   weights 2, horizontal/vertical weights 1).
#' @param normalize Whether to return raw distance divided by n_a+n_b,
#'   supported only for symmetric2.
#' @param return_path Logical; return scalar or an etr_dtw_result with
#'   zero-based path, local and weighted costs, and explicit provenance.
#' @return Numeric scalar or native etr_dtw_result list.
#' @export
etr_dynamic_time_warping <- function(
    a,b,dimension_weights=NULL,window_radius=NULL,
    step_pattern="symmetric1",normalize=FALSE,return_path=FALSE,
    python_boundary_mode=FALSE) {
  .etr_assert(is.character(step_pattern) && length(step_pattern)==1L &&
    !is.na(step_pattern) && step_pattern %in% c("symmetric1","symmetric2"),
    "step_pattern must be 'symmetric1' or 'symmetric2'")
  .etr_assert(is.logical(normalize) && length(normalize)==1L &&
    !is.na(normalize),"normalize must be TRUE or FALSE")
  .etr_assert(is.logical(return_path) && length(return_path)==1L &&
    !is.na(return_path),"return_path must be TRUE or FALSE")
  .etr_assert(!normalize || step_pattern=="symmetric2",
              "normalize=TRUE is available only for symmetric2")
  x <- .etr_distances_inputs(a,b,dimension_weights,"DTW",
    python_boundary_mode=python_boundary_mode)
  n <- x$n_a; m <- x$n_b
  if(!is.null(window_radius)){
    .etr_assert(is.numeric(window_radius) && !is.logical(window_radius) &&
      length(window_radius)==1L && is.finite(window_radius) &&
      window_radius>=0 && window_radius==as.integer(window_radius),
      "window_radius must be a non-negative integer or NULL")
    window_radius <- as.integer(window_radius)
    .etr_assert(window_radius>=abs(n-m),
                "window_radius is too small to connect the sequence endpoints")
  }
  local <- .etr_dtw_local_cost(x$a,x$b,x$weights)
  cum <- matrix(Inf,n,m)
  pi <- pj <- matrix(0L,n,m)
  trans <- matrix(NA_real_,n,m)
  initial_weight <- if(step_pattern=="symmetric2")2 else 1
  cum[1L,1L] <- initial_weight*local[1L,1L]
  trans[1L,1L] <- initial_weight
  for(i in seq_len(n)){
    j_start <- if(is.null(window_radius))1L else max(1L,i-window_radius)
    j_end <- if(is.null(window_radius))m else min(m,i+window_radius)
    if(j_start>j_end) next
    for(j in seq.int(j_start,j_end)){
      if(i==1L && j==1L) next
      candidate <- numeric(0)
      p_i <- p_j <- integer(0)
      weights <- numeric(0)
      if(i>1L && j>1L && is.finite(cum[i-1L,j-1L])){
        w <- if(step_pattern=="symmetric2")2 else 1
        candidate <- c(candidate,cum[i-1L,j-1L]+w*local[i,j])
        p_i <- c(p_i,i-1L);p_j <- c(p_j,j-1L)
        weights <- c(weights,w)
      }
      if(i>1L && is.finite(cum[i-1L,j])){
        candidate <- c(candidate,cum[i-1L,j]+local[i,j])
        p_i <- c(p_i,i-1L);p_j <- c(p_j,j)
        weights <- c(weights,1)
      }
      if(j>1L && is.finite(cum[i,j-1L])){
        candidate <- c(candidate,cum[i,j-1L]+local[i,j])
        p_i <- c(p_i,i);p_j <- c(p_j,j-1L)
        weights <- c(weights,1)
      }
      if(!length(candidate)) next
      choose <- which.min(candidate)
      cum[i,j] <- candidate[choose]
      pi[i,j] <- p_i[choose];pj[i,j] <- p_j[choose]
      trans[i,j] <- weights[choose]
    }
  }
  raw <- as.numeric(cum[n,m])
  .etr_assert(is.finite(raw),
              "No admissible DTW path reaches the endpoint under window_radius")
  denom <- if(step_pattern=="symmetric2")as.numeric(n+m) else NULL
  scaled <- if(is.null(denom))NULL else raw/denom
  dist <- if(normalize)scaled else raw
  if(!return_path) return(as.numeric(dist))
  alignment <- .etr_dtw_backtrack(pi,pj,local,trans)
  weighted <- alignment$local_distances*alignment$step_weights
  .etr_assert(isTRUE(all.equal(sum(weighted),raw,tolerance=1e-10)),
              "DTW path audit does not reproduce cumulative cost")
  structure(list(
    distance=as.numeric(dist),
    path=alignment$path,
    local_distances=alignment$local_distances,
    path_length=as.integer(nrow(alignment$path)),
    mean_local_distance=mean(alignment$local_distances),
    n_points_a=as.integer(n),n_points_b=as.integer(m),
    n_dimensions=as.integer(x$d),
    window_radius=window_radius,
    raw_distance=raw,
    normalized_distance=scaled,
    step_pattern=step_pattern,
    normalization_denominator=denom,
    step_weights=as.numeric(alignment$step_weights),
    weighted_local_costs=as.numeric(weighted),
    provenance=list(
      operation="dynamic_time_warping_distance",
      local_metric="weighted_euclidean",
      dimension_weights=as.numeric(x$weights),
      distance_aggregation="weighted_sum",
      step_pattern=step_pattern,
      normalizable=step_pattern=="symmetric2",
      normalization_requested=normalize,
      normalization_denominator=denom,
      distance_returned=if(normalize)"normalized" else "raw_cumulative",
      recorded_time_used=FALSE,sequence_index_warping=TRUE,
      sample_order_preserved=TRUE,backtracking_allowed=FALSE,
      window_constraint=if(is.null(window_radius))"unconstrained" else
        "sakoe_chiba_index_band",
      window_radius=window_radius,
      interpolation=FALSE,resampling=FALSE,smoothing=FALSE,
      coordinate_normalization=FALSE,path_simplification=FALSE,
      missing_value_deletion=FALSE,
      automatic_step_pattern_selection=FALSE,
      automatic_window_selection=FALSE,
      tie_break_order=c("diagonal","advance_a","advance_b"),
      optimal_path_not_necessarily_unique=TRUE)
  ),class="etr_dtw_result")
}

#' Full native pairwise DTW over selected functional channels
#'
#' Matches Python's pairwise_dynamic_time_warping_distances source contract
#' and returns an unlabeled numeric matrix. Does not calculate a pairwise
#' alignment path since the upstream pairwise function returns distances.
#' @param x Complete native trajectory collection.
#' @param dimensions NULL (all channels) or distinct ordered channel names.
#' @inheritParams etr_dynamic_time_warping
#' @return Symmetric numeric matrix, with zero diagonal and no labels.
#' @export
etr_pairwise_dtw_full <- function(
    x,dimensions=NULL,dimension_weights=NULL,window_radius=NULL,
    step_pattern="symmetric1",normalize=FALSE,
    python_boundary_mode=FALSE) {
  idx <- .etr_preprocessing_dimensions(x,dimensions)
  .etr_assert(is.logical(python_boundary_mode)&&
    length(python_boundary_mode)==1L&&!is.na(python_boundary_mode),
    "python_boundary_mode must be a nonmissing logical scalar")
  .etr_assert(is.character(step_pattern) &&
    length(step_pattern)==1L && !is.na(step_pattern) &&
    step_pattern %in% c("symmetric1","symmetric2"),
    "step_pattern must be 'symmetric1' or 'symmetric2'")
  .etr_assert(is.logical(normalize) && length(normalize)==1L &&
    !is.na(normalize),"normalize must be TRUE or FALSE")
  .etr_assert(!normalize || step_pattern=="symmetric2",
              "normalize=TRUE is available only for symmetric2")
  # Validate the corner cases even for a one-curve collection, matching
  # Python's pairwise preflight (which checks values[0] against itself).
  sample_a <- matrix(x$values[1L,,idx,drop=FALSE],
                     nrow=length(x$time),ncol=length(idx))
  etr_dynamic_time_warping(
    sample_a,sample_a,dimension_weights=dimension_weights,
    window_radius=window_radius,step_pattern=step_pattern,
    normalize=normalize,python_boundary_mode=python_boundary_mode)
  n <- dim(x$values)[1L]
  out <- matrix(0,n,n)
  if(n>=2L) for(i in seq_len(n-1L)) for(j in (i+1L):n) {
    a <- matrix(x$values[i,,idx,drop=FALSE],
                nrow=length(x$time),ncol=length(idx))
    b <- matrix(x$values[j,,idx,drop=FALSE],
                nrow=length(x$time),ncol=length(idx))
    out[i,j] <- etr_dynamic_time_warping(
      a,b,dimension_weights=dimension_weights,
      window_radius=window_radius,step_pattern=step_pattern,
      normalize=normalize,python_boundary_mode=python_boundary_mode)
    out[j,i] <- out[i,j]
  }
  out
}
