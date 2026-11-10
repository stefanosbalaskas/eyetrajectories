.etr_recovery_modes_fixture <- function(kind, mode = "distinct", grid_size = 7L) {
  grid <- seq(0, 1, length.out = grid_size)
  if (mode != "equal_cost") grid <- grid^1.3
  w <- etr_trapezoid_weights(grid)
  nd <- if (kind == "sparse_fpca") 1L else 2L
  dimensions <- c("x", "y")[seq_len(nd)]
  modes <- array(0, c(3L, grid_size, nd))
  for (i in seq_len(3L)) modes[i, i + 1L, ] <- seq_len(nd) /
    sqrt(sum(seq_len(nd)^2) * w[i + 1L])
  id <- seq_len(6L)
  scores <- cbind(id - 3, sin(id), cos(id))
  mean <- matrix(rep(grid, nd), grid_size, nd) / 5
  latent <- array(0, c(length(id), grid_size, nd))
  for (i in id) latent[i, , ] <- mean +
    matrix(scores[i, ] %*% matrix(modes, nrow = 3L), grid_size, nd)

  eigenvalues <- if (mode == "near_tied") c(4, 4 - 1e-9, 1) else
    if (mode %in% c("tied", "split_tie", "unretained_tie", "limited_pairs")) c(4, 4, 1) else
      c(4, 2, 1)
  truth <- list(truth_grid = grid, dimension_names = dimensions, mean = mean,
    eigenfunctions = modes, eigenvalues = eigenvalues, scores = scores,
    latent_on_truth_grid = latent, measurement_noise_covariance = diag(.04, nd))
  keep <- switch(mode, equal_cost = 1:2, tied = 1:2, near_tied = 1:2, limited_pairs = 1:2,
    split_tie = c(1L, 3L), unretained_tie = 3L, c(3L, 1L))
  fitted <- modes[keep, , , drop = FALSE]
  fitted_scores <- scores[, keep, drop = FALSE]
  if (mode %in% c("equal_cost", "tied", "near_tied", "limited_pairs")) {
    rotation <- if (mode == "equal_cost") matrix(c(1, 1, 1, -1), 2L) / sqrt(2) else
      matrix(c(.8, .6, -.6, .8), 2L)
    fitted <- array(crossprod(rotation, matrix(fitted, nrow = 2L)), dim(fitted))
    fitted_scores <- fitted_scores %*% rotation
  } else {
    fitted[1L, , ] <- -fitted[1L, , ]
    fitted_scores[, 1L] <- -fitted_scores[, 1L]
  }
  if (mode %in% c("failed", "limited_pairs"))
    fitted_scores[if (mode == "failed") id else id[-1L], ] <- NA_real_
  if (mode == "partial_scores") fitted_scores[c(2L, 4L), 1L] <- NA_real_
  if (mode == "constant") fitted_scores[, 1L] <- 2
  fit_mean <- mean
  fit_mean[2L, 1L] <- fit_mean[2L, 1L] + .02
  if (kind == "dense") {
    fit <- list(time = grid, dimension_names = dimensions,
      scale = rep(1, nd), provenance = list(fpca = list(scaling = "none")),
      mean = fit_mean, components = fitted, explained_variance = eigenvalues[keep],
      scores = fitted_scores, weights = w)
  } else {
    fit <- list(evaluation_grid = grid, mean = fit_mean, eigenfunctions = fitted,
      eigenvalues = eigenvalues[keep], scores = fitted_scores, quadrature_weights = w,
      score_diagnostics = data.frame(), covariance_diagnostics = list(),
      provenance = list())
    if (kind == "sparse_fpca") {
      fit$mean <- as.numeric(fit$mean)
      fit$eigenfunctions <- matrix(fitted, nrow = length(keep))
      fit$dimension <- "x"
      fit$noise_variance <- .05
      fit$covariance <- crossprod(matrix(modes, nrow = 3L),
        matrix(modes, nrow = 3L) * eigenvalues) + diag(.01, grid_size)
      fit$quadrature_weights <- NULL
    } else {
      fit$dimensions <- dimensions
      fit$measurement_error_covariance <- truth$measurement_noise_covariance
      x <- matrix(modes[, , 1L], nrow = 3L)
      y <- matrix(modes[, , 2L], nrow = 3L)
      fit$covariance_cxx <- crossprod(x * eigenvalues, x)
      fit$covariance_cxy <- crossprod(x * eigenvalues, y)
      fit$covariance_cyx <- crossprod(y * eigenvalues, x)
      fit$covariance_cyy <- crossprod(y * eigenvalues, y)
      fit$covariance_cxy[2L, 3L] <- .025
    }
  }
  list(fit = fit, truth = truth)
}

.etr_recovery_custom_assessment_fixture <- function() {
  list(values = list(
    list(metric = list(name = " custom_loss ", quantity = "sample discrepancy",
      direction = "lower_is_better", units = "score units", scope = "replicate",
      description = "Per-replicate squared error."), value = .25,
      component = 1L, source = " participant "),
    list(metric = etr_functional_recovery_metric_catalog()[["mean_ise"]],
      value = .1, component = NULL, source = NULL)),
    provenance = list(estimator = "subject's \"fit\"\\validation"))
}

.etr_recovery_repeated_warp_fixture <- function() {
  grid <- seq(0, 1, by = .25)
  generated <- rbind(c(0, .25, .25, .6, 1), c(.05, .2, .5, .9, .94))
  list(fit = list(original = list(time = grid),
    warping_functions = rbind(grid, grid)),
    truth = list(truth_grid = grid, phase_warps_on_truth_grid = generated))
}
