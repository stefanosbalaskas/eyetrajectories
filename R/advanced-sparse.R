# Native R sparse-PACE adapter. Delegates estimation to fdapace (optional).
# Does not use reticulate or Python.
#' Construct an explicitly irregular, univariate functional collection
#' @param times List of finite, strictly increasing observation-time vectors.
#' @param values List of numeric vectors, one per curve, with complete observations.
#' @param curve_ids Unique curve identifiers.
#' @param time_unit Recorded time units.
#' @export
etr_sparse_curves <- function(times, values, curve_ids = NULL, time_unit = "unknown") {
  .etr_assert(is.list(times) && is.list(values) && length(times) == length(values) &&
                length(times) >= 3L, "times and values must be matching lists of >= 3 curves")
  for (i in seq_along(times)) {
    t <- times[[i]]; y <- values[[i]]
    .etr_assert(is.numeric(t) && length(t) >= 3L && all(is.finite(t)) &&
                  all(diff(t) > 0), "each time vector must have >= 3 strictly increasing points")
    .etr_assert(is.numeric(y) && length(y) == length(t) && all(is.finite(y)),
                "values must be finite and match observed times; handle missingness explicitly")
  }
  if (is.null(curve_ids)) curve_ids <- paste0("curve_", seq_along(times))
  .etr_assert(is.character(curve_ids) && length(curve_ids) == length(times) &&
                !anyNA(curve_ids) && all(nzchar(curve_ids)) && !anyDuplicated(curve_ids),
              "curve IDs must be unique nonempty strings")
  structure(list(times = times, values = values, curve_ids = curve_ids,
                 time_unit = time_unit), class = "etr_sparse_curves")
}

#' Fit univariate sparse PACE using the R fdapace package
#'
#' Uses conditional-expectation scores and a sparse design. This is an R-native
#' adapter around fdapace::FPCA, NOT an independently coded PACE estimator
#' and NOT an asynchronous multivariate joint PACE implementation.
#' @param x An etr_sparse_curves collection.
#' @param max_components Maximum retained FPCA components.
#' @param fve Fraction of variance explained selection threshold.
#' @param options Additional fdapace options; core design options are fixed.
#' @export
etr_fit_sparse_pace <- function(x, max_components = 3L, fve = 0.95, options = list()) {
  .etr_assert(inherits(x, "etr_sparse_curves"), "x must be etr_sparse_curves")
  .etr_assert(requireNamespace("fdapace", quietly = TRUE),
              "optional R package 'fdapace' is required for sparse PACE")
  .etr_assert(length(x$times) >= 10L, "sparse PACE requires >= 10 curves in this experimental adapter")
  .etr_assert(is.numeric(max_components) && length(max_components) == 1L &&
                is.finite(max_components) && max_components >= 1L &&
                max_components == as.integer(max_components), "max_components must be integer >= 1")
  .etr_assert(is.numeric(fve) && length(fve) == 1L && is.finite(fve) &&
                fve > 0 && fve <= 1, "fve must be in (0, 1]")
  .etr_assert(is.list(options) && (length(options) == 0L ||
                (!is.null(names(options)) && all(nzchar(names(options))))),
              "options must be an optionally empty named list")
  locked <- c("dataType", "methodXi", "plot", "lean", "FVEthreshold", "maxK")
  .etr_assert(!any(names(options) %in% locked), "core PACE estimator options cannot be overridden")
  opts <- c(options, list(dataType = "Sparse", methodXi = "CE", plot = FALSE,
                           lean = TRUE, FVEthreshold = fve,
                           maxK = as.integer(max_components)))
  fit <- fdapace::FPCA(Ly = x$values, Lt = x$times, optns = opts)
  .etr_assert(is.matrix(fit$xiEst) && nrow(fit$xiEst) == length(x$times) &&
                ncol(fit$xiEst) >= 1L, "fdapace returned no usable sparse scores")
  structure(list(backend = "fdapace", model = fit, curve_ids = x$curve_ids,
                 time_unit = x$time_unit, design = "sparse_univariate",
                 n_observations = lengths(x$times), options = opts),
            class = "etr_sparse_pace")
}

#' Return conditional-expectation sparse FPCA scores
#' @param fit A native R fdapace-backed sparse fit.
#' @export
etr_sparse_pace_scores <- function(fit) {
  .etr_assert(inherits(fit, "etr_sparse_pace"), "fit must be etr_sparse_pace")
  z <- as.data.frame(fit$model$xiEst)
  names(z) <- paste0("FPC", seq_len(ncol(z)))
  data.frame(curve_id = fit$curve_ids, z, row.names = NULL, check.names = FALSE)
}

#' Return fitted sparse-curve trajectories on the PACE work grid
#' @param fit A native R fdapace-backed sparse fit.
#' @export
etr_sparse_pace_fitted <- function(fit) {
  .etr_assert(inherits(fit, "etr_sparse_pace"), "fit must be etr_sparse_pace")
  m <- fit$model
  .etr_assert(is.matrix(m$phi) && ncol(m$phi) == ncol(m$xiEst) &&
                nrow(m$phi) == length(m$workGrid), "PACE basis dimensions are inconsistent")
  curves <- sweep(m$xiEst %*% t(m$phi), 2L, m$mu, "+")
  list(time = m$workGrid, fitted = curves, curve_ids = fit$curve_ids,
       backend = "fdapace", score_method = "conditional_expectation")
}
