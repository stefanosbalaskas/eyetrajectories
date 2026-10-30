# Pure R nonlinear geometry and undirected binary recurrence graphs.
#' Time delay embedding of a complete sampled numeric series
#' @param series Finite complete numeric sequence.
#' @param dimension Embedding dimension (positive integer).
#' @param delay Sample lag (positive integer).
#' @return Numeric matrix with row target sample index attribute.
#' @export
etr_delay_embedding <- function(series, dimension = 2L, delay = 1L) {
  .etr_assert(is.numeric(series) && length(series) >= 3L &&
                all(is.finite(series)), "series must be complete finite numeric data")
  .etr_assert(is.numeric(dimension) && length(dimension) == 1L &&
                is.finite(dimension) && dimension >= 1L &&
                dimension == as.integer(dimension),
              "dimension must be positive integer")
  .etr_assert(is.numeric(delay) && length(delay) == 1L &&
                is.finite(delay) && delay >= 1L && delay == as.integer(delay),
              "delay must be positive integer")
  .etr_assert(dimension <= 100L &&
                as.double(dimension - 1L) * delay < length(series),
              "not enough samples for embedding or dimension exceeds 100")
  idx <- seq.int(1L + as.integer((dimension - 1L) * delay), length(series))
  out <- vapply(seq.int(0L, dimension - 1L),
                function(j) series[idx - j * delay], numeric(length(idx)))
  if (is.null(dim(out))) out <- matrix(out, ncol = 1L)
  colnames(out) <- paste0("lag_", seq.int(0L, dimension - 1L) * delay)
  attr(out, "target_sample_index") <- idx
  out
}

#' One-dimensional threshold-event Poincare return map
#' @param series Finite numeric observed series.
#' @param threshold Scalar event threshold.
#' @param direction Up or down crossings.
#' @param time Optional increasing numeric measurement times.
#' @return List with crossing times and consecutive return intervals.
#' @export
etr_poincare_return_map <- function(series, threshold = 0,
                                    direction = c("up", "down"), time = NULL) {
  .etr_assert(is.numeric(series) && length(series) >= 3L &&
                all(is.finite(series)), "series must be complete finite numeric data")
  .etr_assert(is.numeric(threshold) && length(threshold) == 1L &&
                is.finite(threshold), "threshold must be a finite scalar")
  direction <- match.arg(direction)
  if (is.null(time)) time <- seq_along(series)
  .etr_assert(is.numeric(time) && length(time) == length(series) &&
                all(is.finite(time)) && all(diff(time) > 0),
              "time must be finite, strictly increasing, and aligned")
  prev <- utils::head(series, -1L)
  next_value <- utils::tail(series, -1L)
  hit <- if (direction == "up") {
    prev < threshold & next_value >= threshold
  } else {
    prev > threshold & next_value <= threshold
  }
  at <- which(hit)
  crossings <- if (length(at)) {
    time[at] + (threshold - series[at]) /
      (series[at + 1L] - series[at]) * (time[at + 1L] - time[at])
  } else numeric()
  ret <- if (length(crossings) > 1L) {
    data.frame(t_n = utils::head(crossings, -1L),
               t_next = utils::tail(crossings, -1L),
               return_interval = diff(crossings))
  } else {
    data.frame(t_n = numeric(), t_next = numeric(),
               return_interval = numeric())
  }
  list(crossing_times = crossings, return_map = ret,
       threshold = threshold, direction = direction,
       method = "linearly_interpolated_threshold_crossings")
}

# The canonical source-aligned etr_recurrence_network() lives only in
# native-nonlinear-recurrence.R. Do not re-declare it here: duplicated public
# functions silently changed graph fields, isolates and report provenance.

#' Per-node descriptive recurrence-network table
#' @param network A native etr_recurrence_network result.
#' @return Data frame of degrees, clustering, component memberships.
#' @export
etr_recurrence_network_nodes <- function(network) {
  .etr_assert(inherits(network, "etr_recurrence_network"),
              "network must be etr_recurrence_network")
  .etr_assert(is.numeric(network$degree) &&
                length(network$degree) >= 2L,
              "network must carry source-aligned node degrees")
  n <- length(network$degree)
  # Compatibility adapter for the older R-only table. This differs from
  # the published Python 1.2 node_frame, which uses zero clustering for
  # degrees <2 and zero-based component labels.
  clustering <- as.numeric(network$local_clustering)
  clustering[network$degree < 2L] <- NA_real_
  data.frame(node = seq_len(n), degree = as.numeric(network$degree),
             normalized_degree = as.numeric(network$normalized_degree),
             clustering = clustering,
             component = as.integer(network$component_labels) + 1L)
}
