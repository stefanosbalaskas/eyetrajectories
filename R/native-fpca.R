#' Trapezoidal weights on an irregular, strictly increasing grid
#' @param time Finite increasing one-dimensional vector or list of scalar
#'   values coercible to numeric time. In opt-in Python boundary mode,
#'   a complex atomic vector is cast to its real part as NumPy casts a
#'   complex ndarray to dtype=float; regular R use rejects complex grids.
#' @param normalize Divide weights when truthy under Python 1.2 scalar
#'   semantics (FALSE, 0 and the empty string are false; nonempty strings
#'   and nonzero finite numeric scalars are true). In explicit Python
#'   boundary mode, nonzero, infinite and NaN-valued complex scalar flags
#'   follow Python bool(complex); empty/nonempty lists use container truthiness.
#' @param python_boundary_mode When TRUE, reproduce inspected Python 1.2
#'   edge behavior for infinite strictly increasing grid endpoints and
#'   NaN/Inf scalar and complex normalization flags, including casting
#'   a complex atomic grid to its real part as NumPy does. Default FALSE
#'   retains finite-only scientific validation. This is NOT a full-source
#'   parity assertion.
#' @export
etr_trapezoid_weights <- function(time, normalize = FALSE,
    python_boundary_mode = FALSE) {
  .etr_assert(is.logical(python_boundary_mode) &&
    length(python_boundary_mode)==1L && !is.na(python_boundary_mode),
    "python_boundary_mode must be a nonmissing logical scalar")
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
    # np.asarray(list(...), dtype=float) converts each scalar before
    # constructing the homogeneous array. R's unlist() first promotes
    # mixed (character, logical, numeric) values to character, turning
    # TRUE into "TRUE" and then NA. Preserve NumPy's elementwise coercion.
    time <- vapply(time, function(value)
      suppressWarnings(as.numeric(value)), numeric(1L),
      USE.NAMES = FALSE)
  }
  .etr_assert(is.atomic(time) && is.null(dim(time)) &&
                !is.factor(time) &&
                (is.numeric(time) || is.logical(time) ||
                 is.character(time) ||
                 (isTRUE(python_boundary_mode)&&is.complex(time))),
              "time must be a one-dimensional numeric sequence")
  time <- suppressWarnings(as.numeric(time))
  d <- diff(time); n <- length(time)
  if(isTRUE(python_boundary_mode)) {
    # Python 1.2 validates only np.diff(time)>0: +/-Inf endpoints can
    # pass, while NaN differences still fail.
    .etr_assert(n>=2L && all(!is.na(d)) && all(d>0),
      "time must be strictly increasing and one-dimensional")
  } else {
    .etr_assert(n>=2L && all(is.finite(time)) &&
      all(!is.na(d)) && all(d>0),
      "time must be strictly increasing and finite")
  }
  w <- c(d[1] / 2, if (n > 2L) (d[-1] + d[-length(d)]) / 2,
         utils::tail(d, 1) / 2)
  # Match Python bool(scalar) on finite numeric, logical and string
  # scalar values, including bool("")=False and bool("0")=True.
  # Arbitrary Python user objects and nonfinite time grids remain outside
  # this intentionally bounded native scientific contract.
  # Python bool([])=FALSE and bool([anything])=TRUE. A list argument
  # is accepted ONLY in explicit Python boundary mode: ordinary native R
  # uses a scalar normalization flag, avoiding accidental list coercion.
  list_flag <- is.list(normalize) && !is.data.frame(normalize) &&
    is.null(dim(normalize))
  if(list_flag) {
    .etr_assert(isTRUE(python_boundary_mode),
      "list normalize requires python_boundary_mode=TRUE")
    truthy <- length(normalize)>0L
  } else {
    .etr_assert(length(normalize)==1L &&
      (is.logical(normalize) || is.character(normalize) ||
        is.numeric(normalize) ||
        (isTRUE(python_boundary_mode)&&is.complex(normalize))) &&
      (if(isTRUE(python_boundary_mode))
        (if(is.complex(normalize)) {
          parts<-c(Re(normalize),Im(normalize))
          all(!is.na(parts)|is.nan(parts))
         } else (!is.na(normalize) || is.nan(normalize)))
       else (!is.na(normalize) &&
         (!is.numeric(normalize) || is.finite(normalize)))),
      "normalize must be a valid numeric, logical or character scalar")
    # Python's bool(complex) is true when either the real or imaginary part
    # is nonzero. This is distinct from R's default logical coercion.
    truthy <- if(is.character(normalize))nzchar(normalize) else
      if(is.complex(normalize)) {
        # In Python, bool(complex(nan,0)) and bool(complex(inf,0))
        # are TRUE, while both signed zeros are FALSE.
        parts<-c(Re(normalize),Im(normalize))
        any(is.nan(parts))||any(parts!=0)
      } else
      if(is.nan(normalize))TRUE else normalize!=0
  }
  if(isTRUE(truthy))w<-w/sum(w)
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

#' Reconstruct fitted or externally scored curves from native FPCA components
#' @param fit Native FPCA result.
#' @param n_components Number of retained components to reconstruct. With
#'   external scores, defaults to the lesser of supplied score columns and
#'   fitted components, matching the frozen Python 1.2 source.
#' @param scores Optional finite numeric score vector (one curve) or matrix
#'   (curves by components). Unlike an original fitted curve, an externally
#'   scored curve has no known source curve ID.
#' @return A native trajectory set when `scores` is NULL, preserving the
#'   existing R API. When external `scores` are supplied, an unlabelled
#'   numeric array of shape curves by time by dimensions, matching the Python
#'   1.2 `reconstruct_fpca` numerical return contract.
#' @export
etr_reconstruct_fpca <- function(fit, n_components = NULL, scores = NULL) {
  .etr_assert(inherits(fit, "etr_fpca"), "fit must be a native etr_fpca")
  external <- !is.null(scores)
  if (!external) {
    score_matrix <- fit$scores
  } else {
    # Source np.asarray(..., dtype=float) accepts 1D or 2D score arrays.
    # Native R stays fail-closed on nonfinite and nonnumeric score data.
    .etr_assert(is.numeric(scores) && !is.object(scores) &&
                  (is.null(dim(scores)) || length(dim(scores)) == 2L) &&
                  length(scores) > 0L && all(is.finite(scores)),
                "scores must be a finite numeric vector or two-dimensional matrix")
    score_matrix <- if(is.null(dim(scores)))
      matrix(as.numeric(scores),nrow=1L) else scores
    .etr_assert(nrow(score_matrix) >= 1L && ncol(score_matrix) >= 1L,
                "scores must contain at least one curve and component")
  }
  if (is.null(n_components))
    n_components <- if(external)
      min(ncol(score_matrix),fit$n_components) else fit$n_components
  .etr_assert(is.numeric(n_components) && length(n_components) == 1L &&
                is.finite(n_components) &&
                n_components == as.integer(n_components) &&
                n_components >= 1L && n_components <= fit$n_components,
              "n_components must be between 1 and retained component count")
  .etr_assert(ncol(score_matrix) >= n_components,
              "scores contain fewer columns than requested components")
  n <- nrow(score_matrix)
  nt <- length(fit$time)
  nd <- length(fit$dimension_names)
  y <- array(NA_real_, c(n, nt, nd))
  for (j in seq_len(nd)) for (t in seq_len(nt)) {
    y[, t, j] <- fit$mean[t, j] +
      as.vector(score_matrix[, seq_len(n_components), drop = FALSE] %*%
                  as.numeric(fit$components[seq_len(n_components), t, j]))
  }
  if (external) return(y)
  etr_trajectory_set(fit$time, y, fit$curve_ids, fit$dimension_names,
                     coordinate_system = fit$coordinate_system, time_unit = fit$time_unit)
}
