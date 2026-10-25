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

#' Undirected binary recurrence network and descriptive graph metrics
#' @param recurrence Native auto-recurrence result with Theiler exclusions.
#' @return An etr_recurrence_network list of network characteristics.
#' @export
etr_recurrence_network <- function(recurrence) {
  .etr_assert(inherits(recurrence, "etr_recurrence") &&
                identical(recurrence$kind, "auto"),
              "recurrence must be a native auto-recurrence result")
  a <- recurrence$matrix
  .etr_assert(is.matrix(a) && is.logical(a) &&
                nrow(a) == ncol(a) && !anyNA(a) &&
                identical(a, t(a)) && !any(diag(a)),
              "binary adjacency must be symmetric, loop-free, and complete")
  n <- nrow(a)
  .etr_assert(n >= 3L && n <= 400L,
              "network diagnostics support only 3-400 nodes")
  degree <- as.numeric(rowSums(a))
  n_edges <- sum(degree) / 2
  local <- rep(NA_real_, n)
  for (i in which(degree >= 2L)) {
    near <- which(a[i, ])
    local[i] <- sum(a[near, near, drop = FALSE]) /
      (degree[i] * (degree[i] - 1L))
  }
  triangles <- sum(vapply(which(degree >= 2L), function(i) {
    near <- which(a[i, ])
    sum(a[near, near, drop = FALSE]) / 2
  }, numeric(1))) / 3
  connected_triples <- sum(degree * (degree - 1) / 2)
  component <- integer(n)
  count <- 0L
  for (i in seq_len(n)) {
    if (component[i] != 0L) next
    count <- count + 1L
    queue <- i
    component[i] <- count
    while (length(queue)) {
      current <- queue[1L]
      queue <- queue[-1L]
      discovered <- which(a[current, ] & component == 0L)
      if (length(discovered)) {
        component[discovered] <- count
        queue <- c(queue, discovered)
      }
    }
  }
  structure(list(adjacency = a, n_nodes = n, n_edges = n_edges,
                 density = n_edges / choose(n, 2L),
                 degrees = degree, local_clustering = local,
                 triangles = triangles,
                 transitivity = if (connected_triples > 0)
                   3 * triangles / connected_triples else NA_real_,
                 component = component, n_components = count,
                 theiler = recurrence$theiler,
                 method = "undirected_binary_recurrence_network"),
            class = "etr_recurrence_network")
}

#' Per-node descriptive recurrence-network table
#' @param network A native etr_recurrence_network result.
#' @return Data frame of degrees, clustering, component memberships.
#' @export
etr_recurrence_network_nodes <- function(network) {
  .etr_assert(inherits(network, "etr_recurrence_network"),
              "network must be etr_recurrence_network")
  data.frame(node = seq_len(network$n_nodes), degree = network$degrees,
             normalized_degree = network$degrees / (network$n_nodes - 1L),
             clustering = network$local_clustering,
             component = network$component)
}
