# Shared recovery geometry from frozen Python 1.2 recovery.py. Components
# flatten in time-major order so every time weight repeats over channels.

.etr_recovery_require_grid <- function(grid, truth_grid, message) {
  .etr_assert(is.numeric(truth_grid) && is.null(dim(truth_grid)) &&
    length(truth_grid) >= 2L && all(is.finite(truth_grid)) &&
    all(diff(truth_grid) > 0), "truth_grid must be finite and strictly increasing")
  .etr_assert(is.numeric(grid) && is.null(dim(grid)) &&
    identical(as.numeric(grid), as.numeric(truth_grid)), message)
}

.etr_fpca_recovery_rows <- function(array) {
  matrix(aperm(array, c(1L, 3L, 2L)), nrow = dim(array)[1L])
}

.etr_fpca_recovery_normalize <- function(modes, weights) {
  norms <- sqrt(rowSums(sweep(modes^2, 2L, weights, "*")))
  .etr_assert(all(is.finite(norms) & norms > 0),
    "functional components contain an invalid norm")
  modes / norms
}

.etr_fpca_recovery_multi_assignment <- function(similarity) {
  # Rectangular shortest augmenting paths (Crouse, 2016,
  # doi:10.1109/TAES.2016.140952), with SciPy's equal-cost sink priority.
  # Padding the matrix can change the matched modes when costs tie.
  cost <- -similarity
  rows <- nrow(cost)
  columns <- ncol(cost)
  row_price <- numeric(rows)
  column_price <- numeric(columns)
  assigned_column <- integer(rows)
  assigned_row <- integer(columns)
  for (start in seq_len(rows)) {
    distance <- rep(Inf, columns)
    predecessor <- integer(columns)
    visited_rows <- logical(rows)
    visited_columns <- logical(columns)
    remaining <- rev(seq_len(columns))
    minimum <- 0
    row <- start
    repeat {
      visited_rows[row] <- TRUE
      offer <- minimum + cost[row, remaining] - row_price[row] - column_price[remaining]
      better <- offer < distance[remaining]
      distance[remaining[better]] <- offer[better]
      predecessor[remaining[better]] <- row
      minimum <- min(distance[remaining])
      nearest <- which(distance[remaining] == minimum)
      free <- nearest[assigned_row[remaining[nearest]] == 0L]
      index <- if (length(free)) free[length(free)] else nearest[1L]
      column <- remaining[index]
      visited_columns[column] <- TRUE
      if (assigned_row[column] == 0L) break
      row <- assigned_row[column]
      remaining[index] <- remaining[length(remaining)]
      remaining <- head(remaining, -1L)
    }
    row_price[start] <- row_price[start] + minimum
    visited_rows[start] <- FALSE
    row_price[visited_rows] <- row_price[visited_rows] +
      (minimum - distance[assigned_column[visited_rows]])
    column_price[visited_columns] <- column_price[visited_columns] -
      (minimum - distance[visited_columns])
    repeat {
      row <- predecessor[column]
      assigned_row[column] <- row
      previous <- assigned_column[row]
      assigned_column[row] <- column
      if (row == start) break
      column <- previous
    }
  }
  assigned_column
}

.etr_fpca_recovery_cosines <- function(estimated, truth, weights) {
  q <- function(rows) qr.Q(qr(t(rows) * sqrt(weights), tol = 0))
  pmax(0, pmin(1, svd(crossprod(q(estimated), q(truth)), nu = 0L, nv = 0L)$d))
}

.etr_fpca_recovery_angles <- function(cosines, value, source = NULL) {
  values <- lapply(seq_along(cosines), function(i) list(
    value("subspace_principal_cosine", cosines[i], i - 1L, source),
    value("subspace_principal_angle_degrees", acos(cosines[i]) * 180 / pi,
      i - 1L, source)))
  unlist(values, recursive = FALSE)
}

.etr_fpca_recovery_covariance_ise <- function(estimated, target, eigenvalues,
    truth_eigenvalues, weights, covariance) {
  # Evaluate the dense covariance difference in columns of bounded memory.
  # Subtract before squaring to retain accuracy for almost identical operators.
  width <- length(weights)
  target_scaled <- target * truth_eigenvalues
  estimated_scaled <- estimated * eigenvalues
  if (!is.null(covariance)) {
    .etr_assert(is.matrix(covariance) && is.numeric(covariance) &&
      identical(dim(covariance), c(width, width)) && all(is.finite(covariance)),
      "sparse covariance must match the observed source grid")
  }
  total <- 0
  block_size <- max(1L, min(256L, floor(2^20 / width)))
  for (start in seq.int(1L, width, by = block_size)) {
    columns <- seq.int(start, min(width, start + block_size - 1L))
    actual <- if (is.null(covariance)) {
      crossprod(estimated_scaled, estimated[, columns, drop = FALSE])
    } else covariance[, columns, drop = FALSE]
    reference <- crossprod(target_scaled, target[, columns, drop = FALSE])
    total <- total + sum((actual - reference)^2 * outer(weights, weights[columns]))
  }
  total
}

.etr_fpca_recovery_ties <- function(eigenvalues, tolerance) {
  previous <- head(eigenvalues, -1L)
  next_value <- tail(eigenvalues, -1L)
  scale <- pmax(previous, next_value, .Machine$double.xmin)
  tied <- abs(previous - next_value) <= tolerance * scale
  groups <- split(seq_along(eigenvalues), cumsum(c(TRUE, !tied)))
  unname(groups[lengths(groups) > 1L])
}

.etr_fpca_recovery_procrustes <- function(scores, truth) {
  finite <- rowSums(!is.finite(scores) | !is.finite(truth)) == 0L
  if (sum(finite) < max(2L, ncol(scores))) return(NULL)
  scores <- scores[finite, , drop = FALSE]
  truth <- truth[finite, , drop = FALSE]
  rotation <- svd(crossprod(scores, truth))
  sqrt(mean((scores %*% tcrossprod(rotation$u, rotation$v) - truth)^2))
}

.etr_fpca_recovery_population <- function(fit, truth, value, covariance = NULL) {
  nt <- length(truth$truth_grid)
  nd <- length(truth$dimension_names)
  weights <- fit$weights
  .etr_assert(is.numeric(weights) && is.null(dim(weights)) &&
    length(weights) == nt && all(is.finite(weights) & weights > 0),
    "functional quadrature weights must be finite and positive")
  for (mean in list(fit$mean, truth$mean)) {
    .etr_assert(is.matrix(mean) && is.numeric(mean) &&
      identical(dim(mean), c(nt, nd)) && all(is.finite(mean)),
      "source fitted and generating means must match finite time/dimension geometry")
  }
  for (modes in list(fit$components, truth$eigenfunctions)) {
    .etr_assert(is.array(modes) && is.numeric(modes) && length(dim(modes)) == 3L &&
      dim(modes)[1L] >= 1L && identical(dim(modes)[2:3], c(nt, nd)),
      "functional components must match source mode by time/dimension geometry")
  }
  fitted_k <- dim(fit$components)[1L]
  truth_k <- dim(truth$eigenfunctions)[1L]
  .etr_assert(truth_k >= fitted_k, "truth contains fewer components than the fitted result")
  eigenvalues <- fit$explained_variance
  truth_eigenvalues <- truth$eigenvalues
  .etr_assert(is.numeric(eigenvalues) && is.null(dim(eigenvalues)) &&
    length(eigenvalues) == fitted_k && all(is.finite(eigenvalues)) &&
    is.numeric(truth_eigenvalues) && is.null(dim(truth_eigenvalues)) &&
    length(truth_eigenvalues) == truth_k && all(is.finite(truth_eigenvalues) &
      truth_eigenvalues > 0), "fitted and truth eigenvalues must match finite component geometry")
  scores <- fit$scores
  truth_scores <- truth$scores
  .etr_assert(is.matrix(scores) && is.numeric(scores) && nrow(scores) >= 1L &&
    ncol(scores) == fitted_k && is.matrix(truth_scores) && is.numeric(truth_scores) &&
    identical(dim(truth_scores), c(nrow(scores), truth_k)),
    "fitted and generating scores must match curve/component geometry")
  latent <- truth$latent_on_truth_grid
  .etr_assert(is.array(latent) && is.numeric(latent) &&
    identical(dim(latent), c(nrow(scores), nt, nd)),
    "latent source curves must match reconstruction geometry")

  flat_weights <- rep(weights, each = nd)
  estimated <- .etr_fpca_recovery_rows(fit$components)
  target <- .etr_fpca_recovery_rows(truth$eigenfunctions)
  normalized <- .etr_fpca_recovery_normalize(estimated, flat_weights)
  truth_normalized <- .etr_fpca_recovery_normalize(target, flat_weights)
  signed <- sweep(normalized, 2L, flat_weights, "*") %*% t(truth_normalized)
  matched <- .etr_fpca_recovery_multi_assignment(abs(signed))
  matched_signed <- signed[cbind(seq_len(fitted_k), matched)]
  signs <- ifelse(matched_signed >= 0, 1, -1)

  planar <- is.list(covariance)
  tie_tolerance <- 1e-8
  ties <- if (planar) .etr_fpca_recovery_ties(truth_eigenvalues, tie_tolerance) else list()
  complete_ties <- Filter(function(group) {
    retained <- group %in% matched
    .etr_assert(!any(retained) || all(retained),
      "retained components split a tied truth eigenspace")
    all(retained)
  }, ties)

  values <- list(value("mean_ise", sum((fit$mean - truth$mean)^2 * weights)))
  if (planar) {
    channels <- list(x = seq.int(1L, ncol(target), by = 2L),
      y = seq.int(2L, ncol(target), by = 2L))
    for (block in c("cxx", "cxy", "cyx", "cyy")) {
      actual <- covariance[[block]]
      .etr_assert(is.matrix(actual) && is.numeric(actual) &&
        identical(dim(actual), c(nt, nt)) && all(is.finite(actual)),
        paste("planar covariance block", block, "must be finite and match truth-grid geometry"))
      rows <- target[, channels[[substr(block, 2L, 2L)]], drop = FALSE]
      columns <- target[, channels[[substr(block, 3L, 3L)]], drop = FALSE]
      reference <- crossprod(rows * truth_eigenvalues, columns)
      error <- sum((actual - reference)^2 * outer(weights, weights))
      values[[length(values) + 1L]] <- value("covariance_block_ise", error, source = block)
    }
    covariance_ise <- sum(vapply(values[-1L], function(metric) metric$value, numeric(1L)))
  } else {
    covariance_ise <- .etr_fpca_recovery_covariance_ise(estimated, target, eigenvalues,
      truth_eigenvalues, flat_weights, covariance)
  }
  values[[length(values) + 1L]] <- value("covariance_ise", covariance_ise)

  tied_components <- unlist(ties, use.names = FALSE)
  for (i in seq_len(fitted_k)) {
    truth_index <- matched[i]
    reference <- truth_eigenvalues[truth_index]
    values[[length(values) + 1L]] <- value("eigenvalue_relative_error",
      abs(eigenvalues[i] - reference) / reference, i - 1L)
    if (truth_index %in% tied_components) next
    values[[length(values) + 1L]] <- value("component_absolute_similarity",
      abs(matched_signed[i]), i - 1L)
    estimate <- signs[i] * scores[, i]
    reference <- truth_scores[, truth_index]
    finite <- is.finite(estimate) & is.finite(reference)
    if (sum(finite) >= 2L) {
      correlation <- suppressWarnings(stats::cor(estimate[finite], reference[finite]))
      if (!planar || is.finite(correlation))
        values[[length(values) + 1L]] <- value("score_correlation", correlation, i - 1L)
      values[[length(values) + 1L]] <- value("score_rmse",
        sqrt(mean((estimate[finite] - reference[finite])^2)), i - 1L)
    }
  }
  cosines <- if (fitted_k == 1L) min(1, abs(matched_signed)) else
    .etr_fpca_recovery_cosines(normalized, truth_normalized[matched, , drop = FALSE],
      flat_weights)
  values <- c(values, .etr_fpca_recovery_angles(cosines, value))
  tied_sources <- lapply(complete_ties, function(group) paste0(
    "truth_components_", paste(group, collapse = "_")))
  for (i in seq_along(complete_ties)) {
    group <- complete_ties[[i]]
    retained <- which(matched %in% group)
    source <- tied_sources[[i]]
    cosines <- .etr_fpca_recovery_cosines(normalized[retained, , drop = FALSE],
      truth_normalized[group, , drop = FALSE], flat_weights)
    values <- c(values, .etr_fpca_recovery_angles(cosines, value, source))
    rmse <- .etr_fpca_recovery_procrustes(scores[, retained, drop = FALSE],
      truth_scores[, group, drop = FALSE])
    if (!is.null(rmse)) values[[length(values) + 1L]] <-
      value("score_subspace_procrustes_rmse", rmse, source = source)
  }
  reconstructed <- sweep(scores %*% estimated, 2L, as.vector(t(fit$mean)), "+")
  curve_ise <- rowSums(sweep((reconstructed - .etr_fpca_recovery_rows(latent))^2,
    2L, flat_weights, "*"))
  if (any(is.finite(curve_ise))) values[[length(values) + 1L]] <-
    value("reconstruction_ise", mean(curve_ise[is.finite(curve_ise)]))

  list(values = values, matched_truth_components = as.integer(matched - 1L),
    alignment_signs = as.numeric(signs), tie_tolerance = tie_tolerance,
    ties = ties, tied_sources = tied_sources)
}
