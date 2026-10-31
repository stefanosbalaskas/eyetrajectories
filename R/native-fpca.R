#' Trapezoidal weights on an irregular, strictly increasing grid
#' @param time Finite increasing one-dimensional vector or list of scalar values coercible to numeric time.
#' @param normalize Divide weights by their sum when TRUE.
#' @export
etr_trapezoid_weights <- function(time, normalize = FALSE) {
  # Python 1.2 np.asarray accepts a 1-D sequence of scalar numeric
  # elements. Preserve this common scientific input domain in native R,
  # without allowing a matrix/data.frame or automatic time interpolation.
  if (is.list(time) && !is.data.frame(time)) {
    .etr_assert(length(time) >= 2L && all(vapply(time,
      function(x) is.atomic(x) && is.null(dim(x)) &&
        length(x) == 1L && !is.factor(x) &&
        (is.numeric(x) || is.logical(x) || is.character(x)),
      logical(1L))),
      "time must be a one-dimensional sequence of numeric scalars")
    time <- unlist(time, use.names = FALSE)
  }
  .etr_assert(is.atomic(time) && is.null(dim(time)) &&
                !is.factor(time) &&
                (is.numeric(time) || is.logical(time) ||
                 is.character(time)),
              "time must be a one-dimensional numeric sequence")
  time <- suppressWarnings(as.numeric(time))
  .etr_assert(length(time) >= 2L && all(is.finite(time)) &&
                all(diff(time) > 0),
              "time must be strictly increasing and finite")
  d <- diff(time); n <- length(time)
  w <- c(d[1] / 2, if (n > 2L) (d[-1] + d[-length(d)]) / 2,
         utils::tail(d, 1) / 2)
  # Match Python's bool/numeric scalar truthiness for this bounded
  # scientific domain. Arbitrary Python object truthiness is NOT ported.
  .etr_assert(length(normalize)==1L && !is.na(normalize) &&
    ((is.logical(normalize)) ||
     (is.numeric(normalize) && is.finite(normalize))),
    "normalize must be a finite numeric or logical scalar")
  if (isTRUE(normalize!=0)) w <- w / sum(w)
  w
}

#' Fit native quadrature-weighted dense FPCA
#'
#' The common-grid, no-hidden-interpolation contract matches Python 1.2.0.
#' Eigenvector signs may differ, so parity tests compare sign-invariant results.
#' @param x Complete native trajectory set.
#' @param n_components Positive integer component count, or fraction strictly in (0, 1).
#' @param scaling "none" or "dimension_sd".
#' @export
etr_fit_fpca <- function(x, n_components = 0.95,
                         scaling = c("none", "dimension_sd")) {
  etr_validate(x, require_complete = TRUE)
  scaling <- match.arg(scaling)
  n <- dim(x$values)[1]; nt <- length(x$time); nd <- dim(x$values)[3]
  .etr_assert(n >= 2L, "at least two curves are needed for FPCA")
  p <- nt * nd
  .etr_assert(is.numeric(n_components) && length(n_components) == 1L &&
                is.finite(n_components), "n_components must be finite scalar")
  if (typeof(n_components) == "integer") {
    .etr_assert(n_components >= 1L && n_components <= min(n, p),
                "integer n_components outside admissible range")
  } else {
    .etr_assert(n_components > 0 && n_components < 1,
                "numeric n_components must be a variance fraction in (0, 1)")
  }
  w <- etr_trapezoid_weights(x$time)
  mu <- array(0, c(nt, nd))
  scales <- rep(1, nd)
  for (j in seq_len(nd)) {
    channel <- etr_dimension(x, j)
    mu[, j] <- colMeans(channel)
    centered <- sweep(channel, 2L, mu[, j], "-")
    if (scaling == "dimension_sd") {
      scales[j] <- sqrt(sum(colMeans(centered^2) * w))
    }
  }
  .etr_assert(all(is.finite(scales) & scales > .Machine$double.eps),
              "cannot scale constant or degenerate dimensions")
  mat <- matrix(0, n, p)
  for (j in seq_len(nd)) for (t in seq_len(nt)) {
    mat[, (t - 1L) * nd + j] <-
      (x$values[, t, j] - mu[t, j]) / scales[j] * sqrt(w[t])
  }
  # Centering is already explicit above; avoid changing the scientific contract.
  dec <- svd(mat, nu = min(n, p), nv = min(n, p))
  eig <- dec$d^2 / (n - 1L)
  .etr_assert(sum(eig) > .Machine$double.eps, "FPCA requires nonzero between-curve variation")
  prop <- eig / sum(eig)
  k <- if (typeof(n_components) == "integer") as.integer(n_components) else
    which(cumsum(prop) >= n_components)[1]
  .etr_assert(!is.na(k) && k >= 1L, "cannot determine retained component count")
  scores <- sweep(dec$u[, seq_len(k), drop = FALSE], 2L, dec$d[seq_len(k)], "*")
  comp <- array(0, c(k, nt, nd))
  for (a in seq_len(k)) for (j in seq_len(nd)) for (t in seq_len(nt)) {
    comp[a, t, j] <- dec$v[(t - 1L) * nd + j, a] * scales[j] / sqrt(w[t])
  }
  structure(list(time = x$time, curve_ids = x$curve_ids,
                 dimension_names = x$dimension_names,
                 coordinate_system = x$coordinate_system, time_unit = x$time_unit,
                 mean = mu, components = comp, scores = scores, weights = w,
                 scale = scales, explained_variance = eig[seq_len(k)],
                 explained_variance_ratio = prop[seq_len(k)],
                 total_variance = sum(eig), n_components = k,
                 scaling = scaling),
            class = "etr_fpca")
}

#' Native multivariate dense functional PCA
#' @inheritParams etr_fit_fpca
#' @export
etr_fit_mfpca <- function(x, n_components = 0.95,
                          scaling = c("none", "dimension_sd")) {
  etr_validate(x, require_complete = TRUE)
  .etr_assert(dim(x$values)[3] >= 2L, "MFPCA requires >= 2 dimensions")
  etr_fit_fpca(x, n_components, match.arg(scaling))
}

#' Tidy component score frame
#' @param fit Native FPCA result.
#' @export
etr_fpca_scores <- function(fit) {
  .etr_assert(inherits(fit, "etr_fpca"), "fit must be a native etr_fpca")
  out <- as.data.frame(fit$scores)
  names(out) <- paste0("FPC", seq_len(ncol(fit$scores)))
  data.frame(curve_id = fit$curve_ids, out, row.names = NULL, check.names = FALSE)
}

#' Native variance-explained summary
#' @param fit Native FPCA result.
#' @export
etr_fpca_variance_frame <- function(fit) {
  .etr_assert(inherits(fit, "etr_fpca"), "fit must be a native etr_fpca")
  data.frame(component = seq_len(fit$n_components),
             eigenvalue = fit$explained_variance,
             variance_ratio = fit$explained_variance_ratio,
             cumulative_variance_ratio = cumsum(fit$explained_variance_ratio))
}

#' Project compatible native trajectories into a fitted FPCA basis
#' @param fit Native FPCA model.
#' @param x Complete trajectories sharing the exact time/channel definitions.
#' @export
etr_transform_fpca <- function(fit, x) {
  .etr_assert(inherits(fit, "etr_fpca"), "fit must be a native etr_fpca")
  etr_validate(x, require_complete = TRUE)
  .etr_assert(identical(x$time, fit$time) &&
                identical(x$dimension_names, fit$dimension_names),
              "time grid and channel names/order must match fitted FPCA")
  n <- dim(x$values)[1]; nt <- length(fit$time)
  nd <- length(fit$dimension_names); k <- fit$n_components
  centered <- matrix(0, n, nt * nd); basis <- matrix(0, k, nt * nd)
  for (j in seq_len(nd)) for (t in seq_len(nt)) {
    q <- (t - 1L) * nd + j
    centered[, q] <- (x$values[, t, j] - fit$mean[t, j]) /
      fit$scale[j] * sqrt(fit$weights[t])
    basis[, q] <- fit$components[, t, j] / fit$scale[j] *
      sqrt(fit$weights[t])
  }
  centered %*% t(basis)
}

#' Reconstruct original curves from native FPCA components
#' @param fit Native FPCA result.
#' @param n_components Number of retained components to reconstruct.
#' @export
etr_reconstruct_fpca <- function(fit, n_components = NULL) {
  .etr_assert(inherits(fit, "etr_fpca"), "fit must be a native etr_fpca")
  if (is.null(n_components)) n_components <- fit$n_components
  .etr_assert(is.numeric(n_components) && length(n_components) == 1L &&
                !is.na(n_components) && n_components == as.integer(n_components) &&
                n_components >= 1 && n_components <= fit$n_components,
              "n_components must be between 1 and retained component count")
  n <- nrow(fit$scores); nt <- length(fit$time); nd <- length(fit$dimension_names)
  y <- array(NA_real_, c(n, nt, nd))
  for (j in seq_len(nd)) for (t in seq_len(nt)) {
    y[, t, j] <- fit$mean[t, j] +
      as.vector(fit$scores[, seq_len(n_components), drop = FALSE] %*%
                  fit$components[seq_len(n_components), t, j])
  }
  etr_trajectory_set(fit$time, y, fit$curve_ids, fit$dimension_names,
                     coordinate_system = fit$coordinate_system, time_unit = fit$time_unit)
}
