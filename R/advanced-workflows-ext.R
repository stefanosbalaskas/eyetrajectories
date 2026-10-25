#' Validate that an advanced workflow retains explicit modelling decisions
#' @param x An etr_advanced_workflow.
#' @export
etr_validate_advanced_workflow <- function(x) {
  .etr_assert(inherits(x, "etr_advanced_workflow") && is.list(x),
              "x must be etr_advanced_workflow")
  .etr_assert(is.character(x$workflow) && length(x$workflow) == 1L &&
                nzchar(x$workflow) && is.list(x$declared) &&
                is.list(x$diagnostics),
              "workflow must contain named method, declarations and diagnostics")
  .etr_assert(identical(x$scientific_status, "experimental_not_coverage_qualified"),
              "advanced workflow scientific status is missing or invalid")
  invisible(TRUE)
}

#' Run participant-stratified mean difference workflow
#' @inheritParams etr_bootstrap_group_contrast
#' @export
etr_run_group_contrast_workflow <- function(x, participant, group,
                                            B = 399L, alpha = 0.05, seed = 3L) {
  fit <- etr_bootstrap_group_contrast(x, participant, group, B, alpha, seed)
  .etr_workflow("group_mean_function_difference", fit,
                list(contrast = fit$contrast,
                     participants_per_group = fit$participants_per_group,
                     max_t_critical = fit$critical),
                list(B = B, alpha = alpha, seed = seed,
                     group_levels = fit$group_levels,
                     resampling_unit = "participant"))
}

#' Run native scalar-on-FPCA Gaussian regression workflow
#' @param x Complete common-grid trajectories.
#' @param outcome Finite scalar outcome, one per curve.
#' @param n_components Fixed number of FPCA components to retain.
#' @export
etr_run_scalar_fpca_workflow <- function(x, outcome, n_components = 2L) {
  fpca <- etr_fit_fpca(x, n_components = as.integer(n_components))
  fit <- etr_fit_scalar_on_fpca(fpca, outcome, n_components = as.integer(n_components))
  pred <- as.numeric(stats::fitted(fit$model))
  .etr_workflow("scalar_on_function_score_regression", fit,
                list(training_rmse = sqrt(mean((outcome - pred)^2)),
                     r_squared = unname(summary(fit$model)$r.squared),
                     n_curves = length(x$curve_ids)),
                list(n_components = n_components,
                     fpca_fit_on_training_sample = TRUE,
                     score_uncertainty = "conditional"))
}

#' Run marginal channel-wise sparse PACE without joint covariance
#' @inheritParams etr_fit_marginal_sparse_pace
#' @export
etr_run_marginal_sparse_workflow <- function(channels, max_components = 3L,
                                             fve = 0.95, options = list()) {
  fit <- etr_fit_marginal_sparse_pace(channels, max_components, fve, options)
  .etr_workflow("channelwise_marginal_sparse_pace", fit,
                list(scores = etr_marginal_sparse_scores(fit),
                     channels = fit$channels),
                list(max_components = max_components, fve = fve, options = options,
                     shared_latent_covariance = FALSE))
}

#' Run optional refund functional mixed-effects workflow
#' @inheritParams etr_fit_functional_mixed
#' @export
etr_run_functional_mixed_workflow <- function(x, participant = NULL,
                                              method = "REML", basis_k = 10L) {
  fit <- etr_fit_functional_mixed(x, participant, method, basis_k)
  .etr_workflow("refund_univariate_functional_mixed", fit,
                list(fitted = etr_functional_mixed_fitted(fit)),
                list(backend = "refund::pffr", method = method,
                     basis_k = basis_k, n_participants = length(fit$participants)))
}

#' Short advanced-workflow audit summary for results reports
#' @param x etr_advanced_workflow object.
#' @export
etr_workflow_summary <- function(x) {
  etr_validate_advanced_workflow(x)
  data.frame(workflow = x$workflow,
             scientific_status = x$scientific_status,
             declarations = paste(names(x$declared), collapse = ", "),
             diagnostic_fields = paste(names(x$diagnostics), collapse = ", "),
             stringsAsFactors = FALSE)
}
