# Internal Euclidean recurrence distances.
.etr_distance_matrix <- function(a, b) {
  z <- matrix(0, nrow(a), nrow(b))
  for (i in seq_len(nrow(a))) for (j in seq_len(nrow(b)))
    z[i, j] <- sqrt(sum((a[i, ] - b[j, ])^2))
  z
}

#' Native auto-recurrence matrix with explicit Theiler exclusion
#'
#' Main diagonal and all sample lags <= theiler are ineligible.
#' Recurrence rate is computed over eligible unordered off-diagonal pairs.
#' The matrix is dense and intended for modest single-trial samples.
#' @param x Complete native trajectory collection.
#' @param curve 1-based curve index or curve identifier.
#' @param radius Finite non-negative Euclidean radius.
#' @param theiler Non-negative integer number of excluded adjacent sample lags.
#' @export
etr_recurrence_matrix <- function(x, curve = 1L, radius, theiler = 0L) {
  etr_validate(x, require_complete = TRUE)
  if (is.character(curve)) curve <- match(curve, x$curve_ids)
  .etr_assert(length(curve) == 1L && !is.na(curve) && is.numeric(curve) &&
                curve == as.integer(curve) && curve %in% seq_along(x$curve_ids),
              "curve must be an existing 1-based index or ID")
  .etr_assert(is.numeric(radius) && length(radius) == 1L &&
                is.finite(radius) && radius >= 0,
              "radius must be non-negative and finite")
  .etr_assert(is.numeric(theiler) && length(theiler) == 1L &&
                is.finite(theiler) && theiler >= 0 &&
                theiler == as.integer(theiler),
              "theiler must be a non-negative integer")
  a <- .etr_curve(x, curve); n <- nrow(a)
  .etr_assert(n <= 2500L, "dense recurrence exceeds 2500 samples; use a sparse backend")
  .etr_assert(theiler < n - 1L, "Theiler window leaves no eligible pairs")
  m <- .etr_distance_matrix(a, a) <= radius
  eligible <- abs(row(m) - col(m)) > theiler
  diag(eligible) <- FALSE
  m <- m & eligible
  upper <- upper.tri(m) & eligible
  rate <- sum(m[upper]) / sum(upper)
  structure(list(matrix = m, kind = "auto", curve_ids = x$curve_ids[curve],
                 radius = radius, theiler = as.integer(theiler),
                 eligible_pairs = sum(upper), recurrence_rate = rate,
                 time = x$time), class = "etr_recurrence")
}

#' Native cross-recurrence matrix for two point sequences
#'
#' Timestamps and Theiler exclusions are not applied to cross-recurrence.
#' @param a Complete points-by-channels numeric matrix.
#' @param b Complete points-by-channels numeric matrix.
#' @param radius Finite, non-negative Euclidean recurrence radius.
#' @export
etr_cross_recurrence_matrix <- function(a, b, radius) {
  a <- .etr_points(a, "a"); b <- .etr_points(b, "b")
  .etr_assert(ncol(a) == ncol(b), "channel count mismatch")
  .etr_assert(is.numeric(radius) && length(radius) == 1L &&
                is.finite(radius) && radius >= 0,
              "radius must be finite and non-negative")
  .etr_assert(as.double(nrow(a)) * as.double(nrow(b)) <= 5e6,
              "dense cross-recurrence exceeds 5 million pairs")
  m <- .etr_distance_matrix(a, b) <= radius
  structure(list(matrix = m, kind = "cross", curve_ids = NULL, radius = radius,
                 theiler = NA_integer_, eligible_pairs = length(m),
                 recurrence_rate = mean(m), time = NULL),
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
