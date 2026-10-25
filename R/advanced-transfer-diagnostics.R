#' Deterministically discretize a continuous series
#'
#' Uses fixed equal-width or empirical-quantile cutpoints. Quantile ties are
#' rejected instead of silently reducing the requested number of bins.
#' Discretization should be determined on training data in predictive studies
#' to avoid leakage.
#' @param x Finite continuous numeric series.
#' @param bins Number of bins (2 to 16).
#' @param method "quantile" or "equal_width".
#' @export
etr_discretize_states <- function(x, bins = 3L,
                                  method = c("quantile", "equal_width")) {
  .etr_assert(is.numeric(x) && length(x) >= 8L && all(is.finite(x)),
              "x must be complete finite numeric series length >= 8")
  .etr_assert(is.numeric(bins) && length(bins) == 1L && is.finite(bins) &&
                bins == as.integer(bins) && bins >= 2L && bins <= 16L,
              "bins must be integer 2 to 16")
  method <- match.arg(method)
  limits <- if (method == "quantile")
    as.numeric(stats::quantile(x, probs = seq(0,1,length.out=bins+1L),
                               names = FALSE, type = 7)) else
    seq(min(x), max(x), length.out = bins+1L)
  .etr_assert(all(diff(limits) > 0),
              "bin boundaries tied or constant; reduce bins or choose different method")
  states <- as.integer(cut(x, breaks = limits, labels = FALSE,
                           include.lowest = TRUE, right = TRUE))
  .etr_assert(!anyNA(states), "discretization produced missing states")
  attr(states, "breaks") <- limits
  attr(states, "method") <- method
  states
}

#' Shuffle-based effective transfer-entropy bias diagnostic
#'
#' Subtracts mean plug-in TE after permuting the source, destroying temporal
#' dependence as well as cross-series dependence. Results are descriptive and
#' do not provide universally calibrated significance tests.
#' @inheritParams etr_transfer_entropy
#' @param n_shuffles Number of independent source shuffles, >= 19.
#' @param seed RNG seed.
#' @export
etr_effective_transfer_entropy <- function(source, target,
                                            k_target = 1L, k_source = 1L,
                                            lag = 1L, conditioning = NULL,
                                            n_shuffles = 99L, seed = 1L) {
  .etr_assert(is.numeric(n_shuffles) && length(n_shuffles) == 1L &&
      is.finite(n_shuffles) && n_shuffles == as.integer(n_shuffles) &&
      n_shuffles >= 19L && n_shuffles <= 10000L,
      "n_shuffles must be integer 19 to 10000")
  observed <- etr_transfer_entropy(source, target, k_target, k_source, lag,
                                    conditioning)$transfer_entropy_bits
  shuffled <- .etr_seed_scope(seed, function() {
    vapply(seq_len(n_shuffles), function(i) {
      src <- source[sample.int(length(source), length(source), replace = FALSE)]
      etr_transfer_entropy(src, target, k_target, k_source, lag,
                           conditioning)$transfer_entropy_bits
    }, numeric(1))
  })
  list(transfer_entropy_bits = observed,
       mean_shuffled_bits = mean(shuffled),
       effective_bits = observed - mean(shuffled),
       shuffle_distribution = shuffled,
       n_shuffles = as.integer(n_shuffles), seed = seed,
       inferential_scope = "finite_sample_bias_sensitivity_not_causal")
}

#' Independent binary Markov-chain null generator for TE evaluation
#'
#' Produces two separately simulated autocorrelated processes with NO directed
#' cross-series effect. Uses independent innovations for each process.
#' @param n Series length, integer >= 40.
#' @param persistence Probability each chain stays in its prior state (0,1).
#' @param seed Deterministic integer seed.
#' @export
etr_simulate_te_null <- function(n = 400L, persistence = 0.80, seed = 42L) {
  .etr_assert(is.numeric(n) && length(n) == 1L && is.finite(n) &&
                n == as.integer(n) && n >= 40L && n <= 100000L,
              "n must be integer 40 to 100000")
  .etr_assert(is.numeric(persistence) && length(persistence) == 1L &&
                is.finite(persistence) && persistence > 0 && persistence < 1,
              "persistence must lie strictly within (0,1)")
  .etr_seed_scope(seed, function() {
    x <- integer(n); y <- integer(n)
    x[1L] <- stats::rbinom(1L, 1L, .5)
    y[1L] <- stats::rbinom(1L, 1L, .5)
    ix <- stats::runif(n-1L) >= persistence
    iy <- stats::runif(n-1L) >= persistence
    for (i in 2:n) {
      x[i] <- if (ix[i-1L]) 1L - x[i-1L] else x[i-1L]
      y[i] <- if (iy[i-1L]) 1L - y[i-1L] else y[i-1L]
    }
    list(source = x, target = y, truth_directed_effect = 0,
         generating_process = "two_independent_binary_markov_chains",
         persistence = persistence, seed = seed)
  })
}

#' Monte Carlo false-signal diagnostic under TE independent-chain null
#'
#' Tracks positive plug-in TE and surrogate-shift diagnostic thresholds. The
#' surrogate p-values are NOT guaranteed uniformly distributed under this null.
#' @param simulations Number of independent null datasets, >= 5.
#' @param n Samples per null dataset.
#' @param persistence Single-chain persistence.
#' @param n_surrogates Number of circular source shifts (>=19).
#' @param seed Initial seed.
#' @param nominal Reporting threshold for a diagnostic, not a valid test level.
#' @export
etr_evaluate_te_null <- function(simulations = 20L, n = 400L,
                                  persistence = .8, n_surrogates = 39L,
                                  seed = 100L, nominal = .05) {
  .etr_assert(is.numeric(simulations) && length(simulations) == 1L &&
                is.finite(simulations) && simulations == as.integer(simulations) &&
                simulations >= 5L && simulations <= 1000L,
              "simulations must be integer 5 to 1000")
  .etr_assert(is.numeric(nominal) && length(nominal) == 1L &&
                is.finite(nominal) && nominal > 0 && nominal < 1,
              "nominal must be in (0,1)")
  records <- lapply(seq_len(simulations), function(i) {
    z <- etr_simulate_te_null(n = n, persistence = persistence,
                              seed = seed + 2L*i)
    d <- etr_transfer_entropy_shift_test(z$source, z$target,
                               n_surrogates = n_surrogates, seed = seed+2L*i+1L)
    data.frame(simulation = i, plug_in_bits = d$observed_bits,
               corrected_bits = d$adjusted_bits, diagnostic_p = d$diagnostic_p,
               flagged = d$diagnostic_p <= nominal)
  })
  df <- do.call(rbind, records)
  p <- mean(df$flagged)
  list(results = df, diagnostic_flag_rate = p,
       monte_carlo_se = sqrt(p*(1-p)/simulations),
       nominal_reference = nominal, simulations = simulations,
       interpretation = "diagnostic_not_calibrated_type_i_error_test")
}
