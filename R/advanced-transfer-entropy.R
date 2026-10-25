# Discrete plug-in information estimators. Observed prediction, not causality.
.etr_validate_states <- function(x, label) {
  .etr_assert((is.numeric(x) || is.character(x) || is.factor(x)) &&
                length(x) >= 8L && !anyNA(x),
              paste(label, "must be a complete discrete vector of length >= 8"))
  if (is.numeric(x)) .etr_assert(all(is.finite(x)), paste(label, "must be finite"))
  .etr_assert(length(unique(x)) <= min(32L, floor(length(x)/2L)),
              paste(label, "contains too many distinct states; discretize explicitly"))
  as.character(x)
}
.etr_entropy_columns <- function(z, cols) {
  if (!length(cols)) return(0)
  factors <- lapply(z[cols], factor)
  key <- do.call(interaction, c(factors, list(drop = TRUE, lex.order = TRUE)))
  p <- as.vector(table(key))
  p <- p[p > 0]; p <- p / sum(p)
  -sum(p * log2(p))
}

#' Plug-in discrete transfer entropy in bits
#'
#' Estimates I(Y_t; X_{t-lag:(t-lag-k_source+1)} | Y_{t-1:(t-k_target)},
#' Z_{t-1} [when supplied]). User must discretize source, target and optional
#' conditioning states before calling this function. Finite-sample positive
#' bias and sensitivity to binning must be evaluated separately.
#' @param source Discrete driving-state sequence.
#' @param target Discrete response-state sequence of equal length.
#' @param k_target Number of lagged target states.
#' @param k_source Number of lagged source states.
#' @param lag Positive source-to-future lag in samples.
#' @param conditioning Optional aligned discrete conditioning-state sequence (lag 1).
#' @export
etr_transfer_entropy <- function(source, target, k_target = 1L, k_source = 1L,
                                 lag = 1L, conditioning = NULL) {
  x <- .etr_validate_states(source, "source")
  y <- .etr_validate_states(target, "target")
  n <- length(y)
  .etr_assert(length(x) == n, "source and target lengths must match")
  p <- c(k_target, k_source, lag)
  .etr_assert(is.numeric(p) && all(is.finite(p)) &&
                all(p >= 1L) && all(p == as.integer(p)) &&
                k_target <= 4L && k_source <= 4L && lag <= 20L,
              "k_target/k_source must be 1-4 and lag 1-20 integer samples")
  if (!is.null(conditioning)) {
    z <- .etr_validate_states(conditioning, "conditioning")
    .etr_assert(length(z) == n, "conditioning length must match")
  }
  first <- max(k_target + 1L, lag + k_source, if (!is.null(conditioning)) 2L else 1L)
  idx <- seq.int(first, n)
  .etr_assert(length(idx) >= 5L, "insufficient transitions for declared history")
  frame <- data.frame(future = y[idx], stringsAsFactors = FALSE)
  yh <- paste0("y", seq_len(k_target))
  xh <- paste0("x", seq_len(k_source))
  for (j in seq_len(k_target)) frame[[yh[j]]] <- y[idx - j]
  for (j in seq_len(k_source)) frame[[xh[j]]] <- x[idx - lag - j + 1L]
  conditioning_cols <- character()
  if (!is.null(conditioning)) {
    frame[["z1"]] <- z[idx - 1L]
    conditioning_cols <- "z1"
  }
  hist <- c(yh, conditioning_cols)
  allx <- c(xh, hist)
  estimate <- .etr_entropy_columns(frame, c("future", hist)) +
    .etr_entropy_columns(frame, allx) -
    .etr_entropy_columns(frame, hist) -
    .etr_entropy_columns(frame, c("future", allx))
  # Floating point roundoff can produce tiny negative CMI values.
  list(transfer_entropy_bits = max(0, estimate), n_transitions = nrow(frame),
       k_target = as.integer(k_target), k_source = as.integer(k_source),
       lag = as.integer(lag), conditioning = !is.null(conditioning),
       estimator = "discrete_plug_in_conditional_mutual_information")
}

#' Circular-shift sensitivity test for discrete transfer entropy
#'
#' Rotates the source while keeping target and optional conditioning fixed.
#' The surrogate reference is not exchangeable under all observational
#' designs, so the p-value is a descriptive diagnostic, not a universal
#' randomization-valid hypothesis test.
#' @inheritParams etr_transfer_entropy
#' @param n_surrogates Number of shifts, >= 19.
#' @param seed Deterministic seed with global RNG restored.
#' @export
etr_transfer_entropy_shift_test <- function(source, target,
                                            k_target = 1L, k_source = 1L,
                                            lag = 1L, conditioning = NULL,
                                            n_surrogates = 99L, seed = 1L) {
  .etr_assert(is.numeric(n_surrogates) && length(n_surrogates) == 1L &&
                is.finite(n_surrogates) && n_surrogates >= 19L &&
                n_surrogates == as.integer(n_surrogates),
              "n_surrogates must be integer >= 19")
  .etr_assert(length(source) >= 30L && length(source) == length(target),
              "shift test needs >= 30 aligned observations")
  observed <- etr_transfer_entropy(source, target, k_target, k_source,
                                    lag, conditioning)$transfer_entropy_bits
  n <- length(source)
  avoid <- max(as.integer(k_target), as.integer(k_source) + as.integer(lag), 3L)
  shifts <- seq.int(avoid, n - avoid)
  .etr_assert(length(shifts) >= 5L, "series too short for separated circular shifts")
  null <- .etr_seed_scope(seed, function() {
    selected <- sample(shifts, n_surrogates, replace = TRUE)
    vapply(selected, function(s) {
      rotated <- source[c(seq.int(s+1L, n), seq_len(s))]
      etr_transfer_entropy(rotated, target, k_target, k_source,
                            lag, conditioning)$transfer_entropy_bits
    }, numeric(1))
  })
  list(observed_bits = observed, null_bits = null,
       null_mean_bits = mean(null), adjusted_bits = observed - mean(null),
       diagnostic_p = (1 + sum(null >= observed)) / (length(null) + 1),
       n_surrogates = length(null), seed = seed, method = "circular_source_shift",
       inferential_scope = "descriptive_only")
}

#' Bidirectional discrete transfer entropy comparison
#' @inheritParams etr_transfer_entropy
#' @export
etr_transfer_entropy_directions <- function(source, target,
                                            k_target = 1L, k_source = 1L,
                                            lag = 1L) {
  forward <- etr_transfer_entropy(source, target, k_target, k_source, lag)
  reverse <- etr_transfer_entropy(target, source, k_target, k_source, lag)
  data.frame(direction = c("source_to_target", "target_to_source"),
             transfer_entropy_bits = c(forward$transfer_entropy_bits,
                                       reverse$transfer_entropy_bits),
             difference_from_reverse = c(forward$transfer_entropy_bits -
                                            reverse$transfer_entropy_bits,
                                           reverse$transfer_entropy_bits -
                                            forward$transfer_entropy_bits),
             stringsAsFactors = FALSE)
}
