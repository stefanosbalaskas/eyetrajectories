# Phase 3 native audit-friendly orchestration; each route declares its
# estimand, observational unit, and non-qualification status.
.etr_workflow <- function(family, estimate, diagnostics, declared) {
  structure(list(workflow = family, fit = estimate, diagnostics = diagnostics,
                 declared = declared,
                 scientific_status = "experimental_not_coverage_qualified"),
            class = "etr_advanced_workflow")
}

#' Run an explicitly configured sparse PACE workflow
#' @inheritParams etr_fit_sparse_pace
#' @export
etr_run_sparse_pace_workflow <- function(x, max_components = 3L,
                                         fve = 0.95, options = list()) {
  fit <- etr_fit_sparse_pace(x, max_components, fve, options)
  .etr_workflow("sparse_univariate_pace", fit,
                list(scores = etr_sparse_pace_scores(fit),
                     fitted = etr_sparse_pace_fitted(fit)),
                list(backend = "fdapace", max_components = max_components,
                     fve = fve, options = options))
}

#' Run an explicit two-level descriptive FPCA workflow
#' @inheritParams etr_fit_multilevel_fpca
#' @export
etr_run_multilevel_workflow <- function(x, participant, n_between = 2L,
                                        n_within = 2L) {
  fit <- etr_fit_multilevel_fpca(x, participant, n_between, n_within)
  .etr_workflow("two_level_descriptive_fpca", fit,
                list(scores = etr_multilevel_scores(fit),
                     variances = etr_multilevel_variance(fit)),
                list(n_between = n_between, n_within = n_within,
                     participants = fit$participants,
                     weighting = fit$allocation))
}

#' Run participant-cluster functional mean-band workflow
#' @inheritParams etr_bootstrap_mean_band
#' @export
etr_run_mean_band_workflow <- function(x, participant, B = 399L,
                                       alpha = 0.05, seed = 1L) {
  fit <- etr_bootstrap_mean_band(x, participant, B, alpha, seed)
  .etr_workflow("participant_cluster_mean_bands", fit,
                list(cluster_count = fit$independent_clusters,
                     max_standardized_cutoff = fit$cutoff),
                list(B = B, alpha = alpha, seed = seed,
                     resampling_unit = "participant"))
}

#' Run a finite-state directional transfer-entropy sensitivity workflow
#' @inheritParams etr_transfer_entropy_shift_test
#' @export
etr_run_transfer_entropy_workflow <- function(source, target,
                                              k_target = 1L, k_source = 1L,
                                              lag = 1L, conditioning = NULL,
                                              n_surrogates = 99L, seed = 1L) {
  fit <- etr_transfer_entropy_shift_test(source, target, k_target, k_source,
                                         lag, conditioning, n_surrogates, seed)
  direction <- etr_transfer_entropy_directions(source, target,
                                               k_target, k_source, lag)
  .etr_workflow("discrete_transfer_entropy_shift_sensitivity", fit,
                list(directions = direction),
                list(k_target = k_target, k_source = k_source, lag = lag,
                     conditioning = !is.null(conditioning),
                     n_surrogates = n_surrogates, seed = seed,
                     inferential_scope = "descriptive_only"))
}
