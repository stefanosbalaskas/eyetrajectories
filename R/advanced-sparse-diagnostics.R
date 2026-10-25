# Support diagnostics are independent of PACE fitting. Missing times are never
# interpreted as zeros and unobserved intervals are not imputed.
#' Audit observation support before sparse PACE
#' @param x An etr_sparse_curves collection.
#' @param bins Positive integer number of equal-width support bins.
#' @export
etr_sparse_design_diagnostics <- function(x, bins = 10L) {
  .etr_assert(inherits(x, "etr_sparse_curves"), "x must be etr_sparse_curves")
  .etr_assert(is.numeric(bins) && length(bins) == 1L && is.finite(bins) &&
    bins == as.integer(bins) && bins >= 2L && bins <= 100L,
    "bins must be an integer between 2 and 100")
  for (i in seq_along(x$times)) {
    .etr_assert(is.numeric(x$times[[i]]) && length(x$times[[i]]) >= 3L &&
      all(is.finite(x$times[[i]])) && all(diff(x$times[[i]]) > 0) &&
      length(x$values[[i]]) == length(x$times[[i]]) &&
      all(is.finite(x$values[[i]])), "invalid sparse collection observations")
  }
  all_t <- unlist(x$times, use.names = FALSE)
  support <- range(all_t)
  .etr_assert(diff(support) > 0, "support range must have positive width")
  edges <- seq(support[1], support[2], length.out = bins + 1L)
  within_bin <- vapply(x$times, function(t) {
    as.integer(tabulate(findInterval(t, edges, all.inside = TRUE),
                        nbins = bins) > 0L)
  }, integer(bins))
  if (is.null(dim(within_bin))) within_bin <- matrix(within_bin, nrow = bins)
  visits <- lengths(x$times)
  curve <- data.frame(curve_id = x$curve_ids, visits = as.integer(visits),
                      start = vapply(x$times, min, numeric(1)),
                      end = vapply(x$times, max, numeric(1)),
                      largest_gap = vapply(x$times, function(t) max(diff(t)), numeric(1)))
  bins_df <- data.frame(bin = seq_len(bins), start = utils::head(edges, -1L),
                        end = utils::tail(edges, -1L),
                        participants_observed = rowSums(within_bin),
                        fraction_observed = rowMeans(within_bin))
  list(curves = curve, support = bins_df,
       summary = list(n_curves = length(x$curve_ids),
                      n_observations = sum(visits),
                      minimum_visits = min(visits),
                      median_visits = stats::median(visits),
                      max_gap = max(curve$largest_gap),
                      minimum_bin_coverage = min(bins_df$fraction_observed),
                      support_range = support),
       provenance = "observed_support_only_no_interpolation")
}

#' Fitted sparse PACE trajectories at recorded observation times
#'
#' Linearly interpolates fitted work-grid estimates for evaluation only.
#' It does not fill or alter original observations. Out-of-support predictions
#' are NA, with no extrapolation.
#' @param fit etr_sparse_pace object.
#' @param x Original sparse collection, in the fitted curve-ID order.
#' @export
etr_sparse_pace_at_observed <- function(fit, x) {
  .etr_assert(inherits(fit, "etr_sparse_pace"), "fit must be etr_sparse_pace")
  .etr_assert(inherits(x, "etr_sparse_curves"), "x must be etr_sparse_curves")
  .etr_assert(identical(fit$curve_ids, x$curve_ids),
              "sparse curve identifiers/order must match fitted model")
  rec <- etr_sparse_pace_fitted(fit)
  .etr_assert(length(rec$time) >= 2L && all(diff(rec$time) > 0),
              "fitted PACE work grid must be strictly increasing")
  vals <- lapply(seq_along(x$times), function(i) {
    stats::approx(rec$time, rec$fitted[i, ], xout = x$times[[i]],
                  rule = 1, ties = "ordered")$y
  })
  data.frame(curve_id = rep(x$curve_ids, lengths(x$times)),
             time = unlist(x$times, use.names = FALSE),
             observed = unlist(x$values, use.names = FALSE),
             fitted = unlist(vals, use.names = FALSE),
             within_work_grid = is.finite(unlist(vals, use.names = FALSE)),
             row.names = NULL)
}

#' Marginal channel-wise sparse PACE models (not joint MFPCA)
#'
#' Channels may have different observation times. Each channel has its own
#' sparse PACE model and scores; cross-channel covariance is NOT estimated.
#' @param channels Named list of etr_sparse_curves with identical curve ID/order.
#' @param max_components Maximum principal components per channel.
#' @param fve Variance threshold.
#' @param options Optional fdapace settings for each channel.
#' @export
etr_fit_marginal_sparse_pace <- function(channels, max_components = 3L,
                                         fve = 0.95, options = list()) {
  .etr_assert(is.list(channels) && length(channels) >= 2L &&
    !is.null(names(channels)) && all(nzchar(names(channels))) &&
    !anyDuplicated(names(channels)), "channels must be a uniquely named list of >= 2")
  .etr_assert(all(vapply(channels, inherits, logical(1), "etr_sparse_curves")),
              "each channel must be an etr_sparse_curves object")
  ids <- channels[[1L]]$curve_ids
  .etr_assert(all(vapply(channels, function(z) identical(z$curve_ids, ids), logical(1))),
              "channel curve IDs and order must match exactly")
  models <- lapply(channels, etr_fit_sparse_pace, max_components = max_components,
                   fve = fve, options = options)
  structure(list(models = models, curve_ids = ids,
                 channels = names(channels), shared_latent_covariance = FALSE,
                 estimator = "marginal_sparse_pace_no_joint_cross_channel_model"),
            class = "etr_marginal_sparse_pace")
}

#' Return marginal sparse PACE score tables
#' @param fit An etr_marginal_sparse_pace fit.
#' @export
etr_marginal_sparse_scores <- function(fit) {
  .etr_assert(inherits(fit, "etr_marginal_sparse_pace"),
              "fit must be etr_marginal_sparse_pace")
  lapply(fit$models, etr_sparse_pace_scores)
}
