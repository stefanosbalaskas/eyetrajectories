# Source-matched Minkowski distances: frozen Python 1.2 recurrence.py uses
# scipy.spatial.cKDTree query_pairs with p=1, 2, or Inf. This native dense
# implementation computes equivalent L1/L2/L-infinity state distances.
.etr_distance_matrix <- function(a, b, metric="euclidean") {
  .etr_assert(is.character(metric)&&length(metric)==1L&&
    !is.na(metric)&&metric%in%c("cityblock","euclidean","chebyshev"),
    "metric must be one of cityblock, euclidean, chebyshev")
  .etr_assert(is.matrix(a)&&is.matrix(b)&&ncol(a)==ncol(b)&&
    is.numeric(a)&&is.numeric(b)&&all(is.finite(a))&&all(is.finite(b)),
    "distance states must be complete numeric matrices of equal width")
  z <- matrix(0, nrow(a), nrow(b))
  for (i in seq_len(nrow(a))) for (j in seq_len(nrow(b))) {
    delta<-abs(a[i, ]-b[j, ])
    z[i,j]<-switch(metric,cityblock=sum(delta),
      euclidean=sqrt(sum(delta^2)),chebyshev=max(delta))
  }
  z
}

#' Native auto-recurrence matrix with explicit Theiler exclusion
#'
#' Main diagonal and all sample lags <= theiler are ineligible.
#' Recurrence rate is computed over eligible unordered off-diagonal pairs.
#' The matrix is dense and intended for modest single-trial samples.
#' @param x Complete native trajectory collection.
#' @param curve 1-based curve index or curve identifier.
#' @param radius Fixed non-negative distance radius, or NULL when a
#'   target_recurrence_rate is supplied. The legacy native zero-radius
#'   boundary is retained; Python 1.2 requires a strictly positive radius.
#' @param theiler Non-negative integer number of excluded adjacent sample lags.
#' @param metric One of cityblock (L1), euclidean (L2), chebyshev (L-infinity).
#' @param target_recurrence_rate Optional probability strictly between 0 and 1.
#'   Exactly one radius policy must be selected. The 48-step inclusive-radius
#'   bisection matches the frozen Python 1.2 source threshold algorithm on
#'   native numeric common-grid states.
#' @param dimensions Optional explicit ordered names of source trajectory
#'   channels to select. NULL retains the legacy native all-channel behavior.
#'   Already embedded source objects require dimensions=NULL.
#' @param theiler_window_units Source Theiler interval unit, "samples" by default,
#'   or a compatible physical unit resolved from the source time grid.
#' @export
etr_recurrence_matrix <- function(x, curve = 1L, radius = NULL, theiler = 0L,
                                  metric = "euclidean",
                                  target_recurrence_rate = NULL,
                                  dimensions = NULL,
                                  theiler_window_units = "samples") {
  # Frozen Python recurrence_matrix also accepts DelayEmbeddingResult.
  # Reuse the verified native common-grid recurrence kernel while recording
  # explicit embedding-specific source provenance; no Python bridge.
  if(inherits(x,"etr_delay_embedding_set")) {
    .etr_assert(is.null(dimensions),
      "dimensions cannot be supplied for an already embedded state space")
    .etr_assert(is.list(x)&&is.array(x$values)&&
      length(dim(x$values))==3L&&is.numeric(x$values)&&
      is.character(x$state_names)&&
      length(x$state_names)==dim(x$values)[3L]&&
      !anyNA(x$state_names)&&!anyDuplicated(x$state_names),
      "embedded recurrence requires complete numeric states and named dimensions")
    .etr_assert(is.numeric(x$embedding_dimension)&&
      length(x$embedding_dimension)==1L&&
      is.finite(x$embedding_dimension)&&
      x$embedding_dimension>=1&&
      x$embedding_dimension==as.integer(x$embedding_dimension)&&
      is.numeric(x$delay_samples)&&
      length(x$delay_samples)==1L&&
      is.finite(x$delay_samples)&&x$delay_samples>=1&&
      x$delay_samples==as.integer(x$delay_samples)&&
      is.numeric(x$delay_time)&&length(x$delay_time)==1L,
      "embedded recurrence requires valid delay and embedding metadata")
    # Python _state_from_source validates only the requested embedded
    # curve: missing values in another embedding must not invalidate it.
    if(is.character(curve))curve_index<-match(curve,x$curve_ids)
    else curve_index<-curve
    .etr_assert(is.numeric(curve_index)&&length(curve_index)==1L&&
      is.finite(curve_index)&&curve_index==as.integer(curve_index)&&
      curve_index %in% seq_along(x$curve_ids),
      "curve must identify an existing embedded trajectory")
    .etr_assert(all(is.finite(x$values[curve_index,,,drop=FALSE])),
      "recurrence analysis requires complete finite selected curve states")
    proxy<-etr_trajectory_set(x$time,
      x$values[curve_index,,,drop=FALSE],x$curve_ids[curve_index],
      dimension_names=x$state_names,
      coordinate_system=x$coordinate_system,
      time_unit=x$time_unit,provenance=list())
    rec<-etr_recurrence_matrix(proxy,curve=1L,radius=radius,
      theiler=theiler,metric=metric,
      target_recurrence_rate=target_recurrence_rate,
      theiler_window_units=theiler_window_units)
    rec$provenance$source_info<-list(
      source_kind="DelayEmbeddingResult",
      embedding_dimension=as.integer(x$embedding_dimension),
      delay_samples=as.integer(x$delay_samples),
      delay_time=as.numeric(x$delay_time),
      state_names=x$state_names,
      coordinate_system=x$coordinate_system,
      source_provenance=if(is.null(x$provenance))list() else x$provenance)
    return(rec)
  }
  # Python requires explicit dimensions for TrajectorySet source inputs.
  # R retains NULL=all channels for existing backwards-compatible calls.
  etr_validate(x, require_complete=is.null(dimensions))
  if(!is.null(dimensions)){
    .etr_assert(is.character(dimensions)&&length(dimensions)>0L&&
      !anyNA(dimensions)&&all(nzchar(dimensions))&&
      !anyDuplicated(dimensions)&&
      all(dimensions %in% x$dimension_names),
      "dimensions must select known, distinct trajectory channels")
    cols<-match(dimensions,x$dimension_names)
    # Python _state_from_source selects one curve and named channels before
    # checking finiteness. Keep unrelated missing gaze entirely outside the
    # recurrence calculation, including its target-density radius search.
    selected<-if(is.character(curve))match(curve,x$curve_ids) else curve
    .etr_assert(is.numeric(selected)&&length(selected)==1L&&
      is.finite(selected)&&selected==as.integer(selected)&&
      selected %in% seq_along(x$curve_ids),
      "curve must be an existing 1-based index or ID")
    .etr_assert(all(is.finite(x$values[selected,,cols,drop=FALSE])),
      "recurrence analysis requires complete finite selected curve states")
    proxy<-etr_trajectory_set(x$time,
      x$values[selected,,cols,drop=FALSE],x$curve_ids[selected],
      dimension_names=dimensions,
      metadata=x$metadata[selected,,drop=FALSE],
      coordinate_system=x$coordinate_system,
      time_unit=x$time_unit,provenance=x$provenance)
    rec<-etr_recurrence_matrix(proxy,curve=1L,radius=radius,
      theiler=theiler,metric=metric,
      target_recurrence_rate=target_recurrence_rate,
      theiler_window_units=theiler_window_units)
    rec$provenance$source_info<-list(
      source_kind="TrajectorySet",
      dimensions=dimensions,state_names=dimensions,
      coordinate_system=x$coordinate_system,
      source_provenance=x$provenance)
    return(rec)
  }
  if (is.character(curve)) curve <- match(curve, x$curve_ids)
  .etr_assert(length(curve) == 1L && !is.na(curve) && is.numeric(curve) &&
                curve == as.integer(curve) && curve %in% seq_along(x$curve_ids),
              "curve must be an existing 1-based index or ID")
  .etr_assert(xor(is.null(radius), is.null(target_recurrence_rate)),
    "supply exactly one of radius or target_recurrence_rate")
  if (!is.null(radius)) {
    .etr_assert(is.numeric(radius) && length(radius) == 1L &&
                  is.finite(radius) && radius >= 0,
                "radius must be non-negative and finite")
  } else {
    .etr_assert(is.numeric(target_recurrence_rate) &&
                  length(target_recurrence_rate) == 1L &&
                  is.finite(target_recurrence_rate) &&
                  target_recurrence_rate > 0 && target_recurrence_rate < 1,
                "target_recurrence_rate must be strictly between 0 and 1")
  }
  theiler <- .etr_source_time_unit_samples(
    x$time,theiler,theiler_window_units,x$time_unit,
    name="theiler_window",allow_zero=TRUE)
  .etr_assert(is.character(metric) && length(metric) == 1L &&
    !is.na(metric) && metric %in% c("euclidean","cityblock","chebyshev"),
    "metric must be one of cityblock, euclidean, chebyshev")
  a <- .etr_curve(x, curve); n <- nrow(a)
  .etr_assert(n <= 2500L, "dense recurrence exceeds 2500 samples; use a sparse backend")
  .etr_assert(theiler < n - 1L, "Theiler window leaves no eligible pairs")
  selected_policy <- if (is.null(radius)) "target_recurrence_rate" else "fixed"
  if (is.null(radius))
    radius <- .etr_windowed_rqa_source_target_radius(x,
      target_recurrence_rate, metric, as.integer(theiler), curve=curve)
  m <- .etr_distance_matrix(a, a, metric=metric) <= radius
  eligible <- abs(row(m) - col(m)) > theiler
  diag(eligible) <- FALSE
  m <- m & eligible
  upper <- upper.tri(m) & eligible
  rate <- sum(m[upper]) / sum(upper)
  structure(list(matrix = m, kind = "auto", curve_ids = x$curve_ids[curve],
                 radius = radius, theiler = as.integer(theiler),
                 eligible_pairs = sum(upper), recurrence_rate = rate,
                 time = x$time, time_unit = x$time_unit,
                 metric = metric, state_dimension = ncol(a),
                 target_recurrence_rate = target_recurrence_rate,
                 provenance = list(source="native_R_recurrence",
                   metric=metric,
                   radius_policy=selected_policy,
                   target_recurrence_rate=target_recurrence_rate,
                   target_rate_tie_policy=if (is.null(target_recurrence_rate))
                     NULL else paste("inclusive-radius bisection;",
                       "achieved recurrence rate is retained because",
                       "distance ties can prevent an exact target"),
                   recurrence_rate_denominator="eligible_off_diagonal_pairs_outside_theiler_window")),
            class = "etr_recurrence")
}

# Frozen eyetrajectoriespy 1.2 recurrence.py _cross_radius_for_target:
# pooled state-space spread gives the upper search bound; the exact source
# 48-step inclusive-radius bisection counts all source-a × source-b pairs.
# Deliberately native dense R and bounded to the existing 5e6 pair domain.
.etr_cross_recurrence_source_target_radius <- function(a,b,target,metric) {
  .etr_assert(is.numeric(target) && length(target) == 1L &&
    is.finite(target) && target > 0 && target < 1,
    "target_recurrence_rate must be strictly between 0 and 1")
  .etr_assert(nrow(a) > 0L && nrow(b) > 0L,
    "cross recurrence requires non-empty state spaces")
  .etr_assert(as.double(nrow(a)) * as.double(nrow(b)) <= 5e6,
    "dense cross-recurrence exceeds 5 million pairs")
  pooled_min <- pmin(apply(a,2L,min),apply(b,2L,min))
  pooled_max <- pmax(apply(a,2L,max),apply(b,2L,max))
  spread <- pooled_max - pooled_min
  high <- switch(metric,euclidean=sqrt(sum(spread^2)),
    cityblock=sum(abs(spread)),chebyshev=max(abs(spread)))
  .etr_assert(is.finite(high) && high > 0,
    "cross recurrence requires non-constant state vectors")
  distances <- as.numeric(.etr_distance_matrix(a,b,metric=metric))
  low <- 0
  for (iteration in seq_len(48L)) {
    mid <- (low + high) / 2
    density <- sum(distances <= mid) / length(distances)
    if (density < target) low <- mid else high <- mid
  }
  high
}

#' Native cross-recurrence matrix for two point sequences
#'
#' Timestamps and Theiler exclusions are not applied to cross-recurrence.
#' Native matrix inputs and dense output are distinct from frozen Python
#' TrajectorySet inputs and scipy sparse result-class contracts.
#' @param a Complete points-by-channels numeric matrix.
#' @param b Complete points-by-channels numeric matrix.
#' @param radius Fixed non-negative distance radius; NULL with a target
#'   recurrence rate. The legacy native zero-radius boundary is preserved.
#' @param metric One of cityblock (L1), euclidean (L2), chebyshev (L-infinity).
#' @param target_recurrence_rate Optional probability in (0,1). Selects a
#'   radius using the frozen Python 1.2 48-step inclusive-distance bisection,
#'   retaining the achieved rate because ties can prevent an exact target.
#' @param curve_a,curve_b Required named curve IDs or 1-based indices for
#'   native trajectory-set inputs; NULL for legacy numeric matrices.
#' @param dimensions_a,dimensions_b Required ordered state-channel names
#'   for trajectory-set inputs; NULL for legacy numeric matrices. State names,
#'   coordinate systems and time units must match in native trajectory mode.
#'   A native `etr_delay_embedding_set` can instead supply its state names,
#'   embedding dimension and delay metadata; for an embedded input its
#'   corresponding dimensions argument must be NULL. Two embedded inputs
#'   must also have compatible embedding and delay specifications.
#' @export
etr_cross_recurrence_matrix <- function(a, b, radius=NULL,
                                        metric = "euclidean",
                                        target_recurrence_rate=NULL,
                                        curve_a=NULL,curve_b=NULL,
                                        dimensions_a=NULL,dimensions_b=NULL) {
  # Frozen Python source also accepts DelayEmbeddingResult. Native
  # etr_delay_embedding_set supplies the same state-space geometry, but the
  # R interface intentionally retains a dense matrix result instead of
  # claiming identical Python scipy CSR or dataclass classes.
  embedded_a <- inherits(a,"etr_delay_embedding_set")
  embedded_b <- inherits(b,"etr_delay_embedding_set")
  if (embedded_a || embedded_b) {
    .etr_assert(
      (embedded_a || inherits(a,"etr_trajectory_set")) &&
      (embedded_b || inherits(b,"etr_trajectory_set")),
      "embedded cross-recurrence sources must both be native trajectory/embedding objects")
    .etr_assert(!embedded_a || is.null(dimensions_a),
      "dimensions_a cannot be supplied for an already embedded state space")
    .etr_assert(!embedded_b || is.null(dimensions_b),
      "dimensions_b cannot be supplied for an already embedded state space")
    as_trajectory_proxy <- function(x,embedded,side) {
      if (!embedded) return(x)
      .etr_assert(is.list(x)&&is.array(x$values)&&
        length(dim(x$values))==3L&&is.numeric(x$values),
        paste("embedded",side,"states must be numeric 3D arrays"))
      .etr_assert(is.character(x$state_names)&&
        length(x$state_names)==dim(x$values)[3L]&&
        !anyNA(x$state_names)&&!anyDuplicated(x$state_names),
        paste("embedded",side,"must carry unique named state variables"))
      .etr_assert(is.numeric(x$embedding_dimension)&&
        length(x$embedding_dimension)==1L&&
        is.finite(x$embedding_dimension)&&
        x$embedding_dimension>=1&&
        x$embedding_dimension==as.integer(x$embedding_dimension)&&
        is.numeric(x$delay_samples)&&
        length(x$delay_samples)==1L&&
        is.finite(x$delay_samples)&&x$delay_samples>=1&&
        x$delay_samples==as.integer(x$delay_samples)&&
        is.numeric(x$delay_time)&&length(x$delay_time)==1L,
        paste("embedded",side,"must retain valid embedding and delay metadata"))
      etr_trajectory_set(x$time,x$values,x$curve_ids,
        dimension_names=x$state_names,
        coordinate_system=x$coordinate_system,
        time_unit=x$time_unit,
        provenance=if(is.null(x$provenance))list() else x$provenance)
    }
    if (embedded_a && embedded_b) {
      .etr_assert(identical(as.integer(a$embedding_dimension),
        as.integer(b$embedding_dimension)),
        "cross-recurrence embeddings must use the same embedding_dimension")
      .etr_assert(identical(as.integer(a$delay_samples),
        as.integer(b$delay_samples)),
        "cross-recurrence embeddings must use the same delay_samples")
      .etr_assert(identical(is.finite(a$delay_time),is.finite(b$delay_time)),
        "cross-recurrence embeddings have incompatible delay-time semantics")
      if (is.finite(a$delay_time) && is.finite(b$delay_time))
        .etr_assert(isTRUE(all.equal(as.numeric(a$delay_time),
          as.numeric(b$delay_time),tolerance=1e-8)),
          "cross-recurrence embeddings must use the same physical delay")
    }
    source_a_original<-a
    source_b_original<-b
    resolved_dimensions_a<-if(embedded_a)a$state_names else dimensions_a
    resolved_dimensions_b<-if(embedded_b)b$state_names else dimensions_b
    answer<-etr_cross_recurrence_matrix(
      as_trajectory_proxy(a,embedded_a,"A"),
      as_trajectory_proxy(b,embedded_b,"B"),
      radius=radius,metric=metric,
      target_recurrence_rate=target_recurrence_rate,
      curve_a=curve_a,curve_b=curve_b,
      dimensions_a=resolved_dimensions_a,
      dimensions_b=resolved_dimensions_b)
    embed_provenance<-function(x)list(
      source_kind="DelayEmbeddingResult",
      embedding_dimension=as.integer(x$embedding_dimension),
      delay_samples=as.integer(x$delay_samples),
      delay_time=as.numeric(x$delay_time),
      state_names=x$state_names,
      coordinate_system=x$coordinate_system,
      source_provenance=if(is.null(x$provenance))list() else x$provenance)
    if(embedded_a)
      answer$provenance$source_a<-embed_provenance(source_a_original)
    if(embedded_b)
      answer$provenance$source_b<-embed_provenance(source_b_original)
    return(answer)
  }

  # The legacy matrix/matrix API remains unchanged. In the trajectory-set
  # path follow frozen Python _state_from_source/cross_recurrence_matrix's
  # explicit named-channel and coordinate/time compatibility contract.
  trajectory_input <- inherits(a,"etr_trajectory_set") &&
    inherits(b,"etr_trajectory_set")
  .etr_assert(trajectory_input ||
    (!inherits(a,"etr_trajectory_set") &&
     !inherits(b,"etr_trajectory_set")),
    "cross-recurrence sources must both be trajectory sets or both matrices")
  source_a <- NULL
  source_b <- NULL
  time_a <- NULL
  time_b <- NULL
  source_curve_ids <- NULL
  source_time_unit <- NULL
  if(trajectory_input) {
    # Match frozen Python: only the specifically requested curve/channel
    # state tensors need complete observations; other curves can be sparse.
    etr_validate(a,require_complete=FALSE)
    etr_validate(b,require_complete=FALSE)
    .etr_assert(!is.null(curve_a)&&!is.null(curve_b),
      "both source curve identifiers are required for trajectory inputs")
    .etr_assert(!is.null(dimensions_a)&&!is.null(dimensions_b),
      "both explicit dimension selections are required for trajectory inputs")
    resolve_curve<-function(x,id){
      if(is.character(id))id<-match(id,x$curve_ids)
      .etr_assert(length(id)==1L&&is.numeric(id)&&!is.na(id)&&
        is.finite(id)&&id==as.integer(id)&&
        id %in% seq_along(x$curve_ids),
        "curve ID must identify an existing trajectory (1-based index)")
      as.integer(id)
    }
    validate_dimensions<-function(x,names){
      .etr_assert(is.character(names)&&length(names)>0L&&
        !anyNA(names)&&all(nzchar(names))&&
        !anyDuplicated(names)&&all(names %in% x$dimension_names),
        "dimensions must select known, distinct named channels")
      match(names,x$dimension_names)
    }
    ia<-resolve_curve(a,curve_a)
    ib<-resolve_curve(b,curve_b)
    da<-validate_dimensions(a,dimensions_a)
    db<-validate_dimensions(b,dimensions_b)
    .etr_assert(identical(dimensions_a,dimensions_b),
      "cross-recurrence state spaces must use the same named state variables in the same order")
    .etr_assert(identical(a$coordinate_system,b$coordinate_system),
      "cross-recurrence state spaces must use the same coordinate_system")
    .etr_assert(identical(a$time_unit,b$time_unit),
      "cross-recurrence trajectories must use the same time_unit")
    .etr_assert(all(is.finite(a$values[ia,,da,drop=FALSE]))&&
      all(is.finite(b$values[ib,,db,drop=FALSE])),
      "cross recurrence requires complete finite selected curve states")
    source_a<-list(source_kind="TrajectorySet",
      dimensions=dimensions_a,state_names=dimensions_a,
      coordinate_system=a$coordinate_system,
      source_provenance=a$provenance)
    source_b<-list(source_kind="TrajectorySet",
      dimensions=dimensions_b,state_names=dimensions_b,
      coordinate_system=b$coordinate_system,
      source_provenance=b$provenance)
    time_a<-a$time
    time_b<-b$time
    source_curve_ids<-c(a$curve_ids[ia],b$curve_ids[ib])
    source_time_unit<-a$time_unit
    a<-matrix(a$values[ia,,da,drop=FALSE],nrow=length(time_a),
      ncol=length(da))
    b<-matrix(b$values[ib,,db,drop=FALSE],nrow=length(time_b),
      ncol=length(db))
  }else{
    .etr_assert(all(vapply(list(curve_a,curve_b,dimensions_a,dimensions_b),
      is.null,logical(1L))),
      "curve and dimension arguments require trajectory-set sources")
  }
  a <- .etr_points(a, "a"); b <- .etr_points(b, "b")
  .etr_assert(ncol(a) == ncol(b), "channel count mismatch")
  .etr_assert(xor(is.null(radius),is.null(target_recurrence_rate)),
    "supply exactly one of radius or target_recurrence_rate")
  if (!is.null(radius)) {
    .etr_assert(is.numeric(radius) && length(radius) == 1L &&
                  is.finite(radius) && radius >= 0,
              "radius must be finite and non-negative")
  } else {
    .etr_assert(is.numeric(target_recurrence_rate) &&
                  length(target_recurrence_rate) == 1L &&
                  is.finite(target_recurrence_rate) &&
                  target_recurrence_rate > 0 &&
                  target_recurrence_rate < 1,
              "target_recurrence_rate must be strictly between 0 and 1")
  }
  .etr_assert(as.double(nrow(a)) * as.double(nrow(b)) <= 5e6,
              "dense cross-recurrence exceeds 5 million pairs")
  if (is.null(radius))
    radius <- .etr_cross_recurrence_source_target_radius(a,b,
      target_recurrence_rate,metric)
  m <- .etr_distance_matrix(a, b, metric=metric) <= radius
  structure(list(matrix = m, kind = "cross", curve_ids = source_curve_ids,
                 radius = radius,
                 theiler = NA_integer_, eligible_pairs = length(m),
                 recurrence_rate = mean(m), time = NULL,
                 time_a=time_a,time_b=time_b,
                 state_dimension=as.integer(ncol(a)),time_unit=source_time_unit,
                 metric=metric,
                 target_recurrence_rate=target_recurrence_rate,
                 provenance=list(source="native_R_cross_recurrence",
                   source_a=source_a,source_b=source_b,
                   time_alignment="none",metric=metric,
                   radius_policy=if(is.null(target_recurrence_rate))
                     "fixed" else "target_recurrence_rate",
                   target_recurrence_rate=target_recurrence_rate,
                   target_rate_tie_policy=if(is.null(target_recurrence_rate))
                     NULL else paste("inclusive-radius bisection;",
                       "achieved recurrence rate is retained because",
                       "distance ties can prevent an exact target"),
                   recurrence_rate_denominator="all_cross_state_pairs")),
            class = "etr_recurrence")
}

.etr_run_lengths <- function(v) {
  if (!length(v)) return(integer())
  runs <- rle(as.logical(v))
  runs$lengths[runs$values]
}
.etr_rqa_entropy <- function(lengths) {
  if (!length(lengths)) return(NA_real_)
  p <- as.numeric(table(lengths))
  p <- p / sum(p)
  -sum(p * log(p))
}

#' Basic native recurrence-quantification metrics
#'
#' Matches the 1.2.0 auto-recurrence conventions for upper-triangle diagonal
#' lines and all-matrix vertical runs, without claim of full RQA feature parity.
#' @param recurrence A result of etr_recurrence_matrix() or cross variant.
#' @param min_diagonal_length Smallest counted diagonal line, >= 1.
#' @param min_vertical_length Smallest counted vertical line, >= 1.
#' @export
etr_rqa_metrics <- function(recurrence, min_diagonal_length = 2L,
                            min_vertical_length = 2L) {
  .etr_assert(inherits(recurrence, "etr_recurrence"),
              "recurrence must be a native etr_recurrence object")
  .etr_assert(is.numeric(min_diagonal_length) && length(min_diagonal_length) == 1L &&
                is.finite(min_diagonal_length) &&
                min_diagonal_length == as.integer(min_diagonal_length) &&
                min_diagonal_length >= 1L, "min_diagonal_length must be positive integer")
  .etr_assert(is.numeric(min_vertical_length) && length(min_vertical_length) == 1L &&
                is.finite(min_vertical_length) &&
                min_vertical_length == as.integer(min_vertical_length) &&
                min_vertical_length >= 1L, "min_vertical_length must be positive integer")
  m <- recurrence$matrix
  .etr_assert(is.matrix(m) && is.logical(m) && !anyNA(m),
              "recurrence matrix must be complete logical matrix")
  nr <- nrow(m); nc <- ncol(m)
  diag_lengths <- integer()
  offsets <- if (recurrence$kind == "auto") seq_len(max(nc - 1L, 0L)) else
    seq.int(-(nr - 1L), nc - 1L)
  for (offset in offsets) {
    rows <- seq_len(nr)
    cols <- rows + offset
    keep <- cols >= 1L & cols <= nc
    if (any(keep)) diag_lengths <- c(diag_lengths,
      .etr_run_lengths(m[cbind(rows[keep], cols[keep])]))
  }
  vertical <- unlist(lapply(seq_len(nc), function(j) .etr_run_lengths(m[, j])),
                     use.names = FALSE)
  qd <- diag_lengths[diag_lengths >= min_diagonal_length]
  qv <- vertical[vertical >= min_vertical_length]
  points <- if (recurrence$kind == "auto") sum(m[upper.tri(m)]) else sum(m)
  det <- if (points > 0) sum(qd) / points else NA_real_
  lam <- if (sum(m) > 0) sum(qv) / sum(m) else NA_real_
  list(recurrence_rate = recurrence$recurrence_rate,
       determinism = det, laminarity = lam,
       mean_diagonal_length = if (length(qd)) mean(qd) else NA_real_,
       max_diagonal_length = if (length(qd)) max(qd) else 0L,
       diagonal_entropy = .etr_rqa_entropy(qd),
       trapping_time = if (length(qv)) mean(qv) else NA_real_,
       max_vertical_length = if (length(qv)) max(qv) else 0L,
       n_recurrence_points = points,
       n_diagonal_lines = length(qd), n_vertical_lines = length(qv))
}
