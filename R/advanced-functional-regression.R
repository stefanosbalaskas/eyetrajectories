# Functional response models are optional R-native refund integrations.
#' Fit an experimental univariate functional-response mixed model
#'
#' Calls refund::pffr() for a univariate complete common-grid response, with
#' a smooth functional intercept and an optional participant random functional
#' intercept. No automatic covariance or coverage qualification is claimed.
#' @param x Native complete trajectory collection with ONE response channel.
#' @param participant Optional participant IDs or name of metadata column.
#' @param method Method passed to refund::pffr, typically "REML".
#' @param basis_k Basis dimension for functional intercept (>= 4).
#' @export
etr_fit_functional_mixed <- function(x, participant = NULL,
                                     method = "REML", basis_k = 10L) {
  etr_validate(x, require_complete = TRUE)
  .etr_assert(dim(x$values)[3] == 1L, "functional mixed adapter is univariate only")
  .etr_assert(requireNamespace("refund", quietly = TRUE),
              "optional R package 'refund' is required")
  .etr_assert(is.character(method) && identical(method, "REML"),
              "Phase 3 functional mixed adapter currently supports REML only")
  .etr_assert(is.numeric(basis_k) && length(basis_k) == 1L &&
    is.finite(basis_k) && basis_k == as.integer(basis_k) &&
    basis_k >= 4L && basis_k < length(x$time),
    "basis_k must be integer >= 4 and less than time-grid length")
  Y <- etr_dimension(x, 1L)
  .etr_assert(nrow(Y) >= 8L, "functional mixed model requires >= 8 curves")
  data <- list(Y = unname(Y))
  if (is.null(participant)) {
    fit <- refund::pffr(Y ~ 1, yind = x$time, data = data,
                        method = method,
                        bs.int = list(bs = "ps", k = as.integer(basis_k), m = c(2, 1)))
    grouping <- NULL
  } else {
    if (length(participant) == 1L && is.character(participant) &&
        participant %in% names(x$metadata)) participant <- x$metadata[[participant]]
    .etr_assert(length(participant) == nrow(Y) && !anyNA(participant),
                "participant labels must identify every curve")
    ids <- unique(as.character(participant))
    .etr_assert(length(ids) >= 4L && length(ids) < nrow(Y) &&
      all(tabulate(match(as.character(participant), ids)) >= 2L),
      "random functional intercept requires >= 4 groups with >= 2 trials each")
    data$participant <- factor(as.character(participant), levels = ids)
    # Explicit refund syntax: s(g, bs='re') is a functional random intercept.
    fit <- refund::pffr(Y ~ s(participant, bs = "re"),
                        yind = x$time, data = data, method = method,
                        bs.int = list(bs = "ps", k = as.integer(basis_k), m = c(2, 1)))
    grouping <- ids
  }
  structure(list(model = fit, backend = "refund::pffr",
                 dimension = x$dimension_names[1L], time = x$time,
                 curve_ids = x$curve_ids, participants = grouping,
                 method = method, basis_k = as.integer(basis_k),
                 scientific_status = "experimental_model_unqualified"),
            class = "etr_functional_mixed")
}

#' Predict fitted experimental functional mixed response
#' @param fit An etr_functional_mixed fit.
#' @export
etr_functional_mixed_fitted <- function(fit) {
  .etr_assert(inherits(fit, "etr_functional_mixed"),
              "fit must be etr_functional_mixed")
  fitted <- stats::fitted(fit$model)
  .etr_assert(is.matrix(fitted) || is.numeric(fitted),
              "refund returned an unexpected fitted-response type")
  list(fitted = fitted, time = fit$time, curve_ids = fit$curve_ids,
       method = fit$method, status = fit$scientific_status)
}

#' Native scalar-on-function score regression (Gaussian only)
#'
#' Fits a Gaussian least-squares model on retained native FPCA scores.
#' This is conditional on the estimated FPCA basis and is not a joint
#' measurement-error model. Use subject holdouts for predictive validation.
#' @param fit Native etr_fpca result.
#' @param outcome Numeric response per curve, no missing values.
#' @param n_components Number of retained scores used as predictors.
#' @export
etr_fit_scalar_on_fpca <- function(fit, outcome, n_components = NULL) {
  .etr_assert(inherits(fit, "etr_fpca"), "fit must be a native etr_fpca")
  if (is.null(n_components)) n_components <- fit$n_components
  .etr_assert(is.numeric(n_components) && length(n_components) == 1L &&
    is.finite(n_components) && n_components == as.integer(n_components) &&
    n_components >= 1L && n_components <= fit$n_components,
    "n_components must be between 1 and fitted component count")
  n <- length(fit$curve_ids)
  .etr_assert(is.numeric(outcome) && length(outcome) == n && all(is.finite(outcome)),
              "outcome must have one finite numeric value per curve")
  .etr_assert(n >= n_components + 3L, "too few independent curves for score regression")
  scores <- fit$scores[, seq_len(n_components), drop = FALSE]
  dat <- as.data.frame(scores)
  names(dat) <- paste0("FPC", seq_len(ncol(dat)))
  dat$outcome <- outcome
  model <- stats::lm(outcome ~ ., data = dat)
  structure(list(model = model, curve_ids = fit$curve_ids,
                 n_components = as.integer(n_components),
                 score_basis = fit,
                 method = "gaussian_scalar_on_fpca_scores",
                 uncertainty = "conditional_on_fitted_scores"),
            class = "etr_scalar_on_fpca")
}

#' Predict outcomes from a fitted scalar-on-FPCA regression
#' @param fit A native etr_scalar_on_fpca regression.
#' @param x A compatible complete trajectory set.
#' @export
etr_predict_scalar_on_fpca <- function(fit, x) {
  .etr_assert(inherits(fit, "etr_scalar_on_fpca"),
              "fit must be etr_scalar_on_fpca")
  scores <- etr_transform_fpca(fit$score_basis, x)
  mat <- as.data.frame(scores[, seq_len(fit$n_components), drop = FALSE])
  names(mat) <- paste0("FPC", seq_len(ncol(mat)))
  stats::predict(fit$model, newdata = mat)
}
