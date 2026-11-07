# Native joint Gaussian functional B-spline random intercept AND one random slope.
# Frozen Python reference: eyetrajectoriespy 1.2.0 c1cd95ad, functional_mixed_effects.py
# Bounded model: participant only, iid residuals, one varying numeric slope.
# Uses nlme, never Python. A distinct additive scientific method: no full
# Python 1.2 result class, optimizer or domain equivalence is asserted.

#' Joint B-spline Gaussian functional random-intercept and random-slope model
#'
#' Fits smooth fixed coefficient functions and participant-specific random
#' intercept AND one participant-specific random slope over a common time grid.
#' Random B-spline coefficients share a single fully unstructured covariance;
#' its off-diagonal blocks estimate intercept-slope dependence. The estimator
#' uses nlme::lme with independent, homoscedastic Gaussian observation errors.
#'
#' @param trajectories Finite complete native etr_trajectory_set.
#' @param design Data frame with one distinct curve_id per source curve.
#' @param predictors Explicit fixed numerical predictor names.
#' @param participant_column Column in trajectories$metadata identifying participants.
#' @param dimension One existing response dimension name.
#' @param random_slope_predictor One name in predictors that varies within
#'   every participant. One random slope is fitted; no automatic selection.
#' @param fixed_basis_size,random_basis_size Positive B-spline basis sizes.
#' @param spline_degree Nonnegative spline degree (supported: 1 to 5).
#' @param reml TRUE for REML; FALSE for ML.
#' @param maxiter Maximum optimizer iterations (>=10).
#' @return Native joint mixed model with fixed coefficient curves, their
#'   pointwise SEs, participant intercept/slope functions, joint random-effect
#'   covariance, conditional fitted curves, residuals and the nlme backend fit.
#' @export
etr_fit_joint_bspline_functional_random_slope <- function(
    trajectories, design, predictors, participant_column, dimension,
    random_slope_predictor, fixed_basis_size = 6L,
    random_basis_size = 4L, spline_degree = 3L,
    reml = TRUE, maxiter = 500L) {
  if (!requireNamespace("nlme", quietly = TRUE))
    stop("The optional R package 'nlme' is required for joint B-spline random slopes", call. = FALSE)
  etr_validate(trajectories, require_complete = TRUE)
  .etr_assert(all(is.finite(trajectories$values)),
    "joint mixed-effects regression requires finite complete observations")
  .etr_assert(!identical(trajectories$coordinate_system, "probability_simplex"),
    "direct Gaussian mixed effects is unsupported for probability_simplex")
  .etr_assert(is.numeric(spline_degree) && length(spline_degree) == 1L &&
      is.finite(spline_degree) && spline_degree == floor(spline_degree) &&
      spline_degree >= 1L && spline_degree <= 5L,
    "spline_degree must be an integer from 1 to 5")
  .etr_assert(is.numeric(maxiter) && length(maxiter) == 1L &&
      is.finite(maxiter) && maxiter == floor(maxiter) && maxiter >= 10L,
    "maxiter must be an integer >= 10")
  .etr_assert(is.logical(reml) && length(reml) == 1L && !is.na(reml),
    "reml must be a nonmissing logical scalar")
  .etr_assert(is.character(participant_column) &&
      length(participant_column) == 1L && !is.na(participant_column) &&
      participant_column %in% names(trajectories$metadata),
    "participant_column must be a known metadata field")
  .etr_assert(is.character(dimension) && length(dimension) == 1L &&
      !is.na(dimension) && dimension %in% trajectories$dimension_names,
    "dimension must identify a known response channel")
  .etr_assert(is.data.frame(design) && "curve_id" %in% names(design) &&
      nrow(design) == length(trajectories$curve_ids) &&
      !anyNA(design$curve_id) &&
      !anyDuplicated(as.character(design$curve_id)),
    "design requires one unique curve_id row per trajectory")
  .etr_assert(is.character(predictors) && length(predictors) >= 1L &&
      !anyNA(predictors) && !anyDuplicated(predictors) &&
      !any(predictors == "curve_id") && all(predictors %in% names(design)),
    "predictors must be distinct declared fixed numeric predictors")
  .etr_assert(is.character(random_slope_predictor) &&
      length(random_slope_predictor) == 1L &&
      !is.na(random_slope_predictor) && nzchar(random_slope_predictor) &&
      random_slope_predictor %in% predictors,
    "random_slope_predictor must name one declared fixed predictor")
  ids <- trajectories$curve_ids
  align <- match(ids, as.character(design$curve_id))
  .etr_assert(!anyNA(align), "design omits source curve identifiers")
  design <- design[align, , drop = FALSE]
  n_curves <- length(ids)
  time <- trajectories$time
  n_time <- length(time)
  .etr_assert(is.numeric(fixed_basis_size) && length(fixed_basis_size) == 1L &&
      is.finite(fixed_basis_size) && fixed_basis_size == floor(fixed_basis_size) &&
      fixed_basis_size >= spline_degree + 1L && fixed_basis_size <= n_time &&
      is.numeric(random_basis_size) && length(random_basis_size) == 1L &&
      is.finite(random_basis_size) && random_basis_size == floor(random_basis_size) &&
      random_basis_size >= spline_degree + 1L && random_basis_size <= n_time,
    "basis sizes must be integers between degree+1 and observed time count")
  nf <- as.integer(fixed_basis_size)
  nr <- as.integer(random_basis_size)
  nd <- 2L * nr
  degree <- as.integer(spline_degree)
  participant <- as.character(trajectories$metadata[[participant_column]])
  .etr_assert(length(participant) == n_curves &&
      !anyNA(participant) && all(nzchar(participant)),
    "participant identifiers must be nonmissing")
  participants <- unique(participant)
  n_groups <- length(participants)
  covariance_parameters <- as.integer(nd * (nd + 1L) / 2L)
  .etr_assert(n_groups >= max(4L, nd + 1L) &&
      n_groups > covariance_parameters,
    "random-slope model requires participant count exceeding free covariance parameters")
  .etr_assert(all(tabulate(match(participant, participants)) >= 2L),
    "random slope requires >=2 source curves per participant")
  n_obs <- n_curves * n_time
  n_fixed <- (length(predictors) + 1L) * nf
  .etr_assert(n_obs > n_fixed + nd &&
      as.double(n_obs) * as.double(n_groups) * as.double(nd) <= 8e6,
    "random-slope design is underdetermined or exceeds dense safety limit")

  scalar_names <- c("Intercept", predictors)
  scalar <- matrix(1, n_curves, length(scalar_names),
    dimnames = list(NULL, scalar_names))
  for (j in seq_along(predictors)) {
    v <- design[[predictors[j]]]
    .etr_assert(is.numeric(v) && is.null(dim(v)) &&
        length(v) == n_curves && all(is.finite(v)),
      paste("predictor", predictors[j], "must have finite numeric scalar values"))
    scalar[, j + 1L] <- v
  }
  slope_values <- as.numeric(design[[random_slope_predictor]])
  for (g in seq_along(participants)) {
    z <- slope_values[participant == participants[g]]
    scale <- max(1, max(abs(z)))
    .etr_assert(diff(range(z)) > 1e-12 * scale,
      paste("random_slope_predictor must vary within every participant; failing participant",
        participants[g]))
  }
  .etr_assert(qr(scalar)$rank == ncol(scalar),
    "fixed scalar design is rank deficient")
  fixed_basis <- .etr_joint_bspline_basis(time, nf, degree)
  random_basis <- .etr_joint_bspline_basis(time, nr, degree)
  fixed_names <- unlist(lapply(seq_along(scalar_names),
    function(j) paste0(".etr_sfx", j, "_", seq_len(nf))), use.names = FALSE)
  random_names <- c(paste0(".etr_ri", seq_len(nr)),
    paste0(".etr_rs", seq_len(nr)))
  X <- matrix(NA_real_, n_obs, n_fixed,
    dimnames = list(NULL, fixed_names))
  for (j in seq_along(scalar_names)) for (k in seq_len(nf)) {
    X[, (j - 1L) * nf + k] <- rep(scalar[, j], each = n_time) *
      rep(fixed_basis[, k], times = n_curves)
  }
  .etr_assert(qr(X)$rank == n_fixed,
    "joint fixed-effects spline design is rank deficient")
  R <- matrix(NA_real_, n_obs, nd,
    dimnames = list(NULL, random_names))
  for (k in seq_len(nr)) {
    R[, k] <- rep(random_basis[, k], times = n_curves)
    R[, nr + k] <- R[, k] * rep(slope_values, each = n_time)
  }
  .etr_assert(qr(R)$rank == nd,
    "expanded random slope design is rank deficient")
  Y <- matrix(trajectories$values[, , match(dimension,
    trajectories$dimension_names), drop = FALSE],
    nrow = n_curves, ncol = n_time)
  observed <- as.vector(t(Y))
  dat <- data.frame(.etr_y = observed,
    .etr_pid = factor(rep(participant, each = n_time),
      levels = participants))
  for (k in seq_along(fixed_names)) dat[[fixed_names[k]]] <- X[, k]
  for (k in seq_along(random_names)) dat[[random_names[k]]] <- R[, k]
  fixed_formula <- stats::reformulate(fixed_names,
    response = ".etr_y", intercept = FALSE)
  random_formula <- stats::reformulate(random_names, intercept = FALSE)
  fit <- tryCatch(
    nlme::lme(fixed = fixed_formula,
      random = list(.etr_pid = nlme::pdSymm(random_formula)),
      data = dat, method = if (reml) "REML" else "ML",
      control = nlme::lmeControl(maxIter = as.integer(maxiter),
        msMaxIter = as.integer(maxiter), returnObject = FALSE)),
    error = function(e) stop(paste("joint B-spline random slope did not converge:",
      conditionMessage(e)), call. = FALSE))
  fe <- nlme::fixef(fit)
  .etr_assert(all(fixed_names %in% names(fe)),
    "joint fit omitted fixed-effect spline coefficients")
  fixed_coefficients <- matrix(as.numeric(fe[fixed_names]),
    nrow = length(scalar_names), ncol = nf, byrow = TRUE,
    dimnames = list(scalar_names, NULL))
  coefficient_functions <- fixed_coefficients %*% t(fixed_basis)
  dimnames(coefficient_functions) <- list(scalar_names, NULL)
  vc <- as.matrix(stats::vcov(fit))
  .etr_assert(all(fixed_names %in% rownames(vc)) &&
      all(fixed_names %in% colnames(vc)),
    "fitted fixed-effect covariance is missing declared names")
  vc <- vc[fixed_names, fixed_names, drop = FALSE]
  coefficient_se <- matrix(NA_real_, length(scalar_names), n_time,
    dimnames = list(scalar_names, NULL))
  for (j in seq_along(scalar_names)) {
    ii <- (j - 1L) * nf + seq_len(nf)
    block <- vc[ii, ii, drop = FALSE]
    coefficient_se[j, ] <- sqrt(pmax(0,
      rowSums((fixed_basis %*% block) * fixed_basis)))
  }
  re <- as.matrix(nlme::ranef(fit))
  .etr_assert(all(random_names %in% colnames(re)) &&
      !is.null(rownames(re)) && all(participants %in% rownames(re)),
    "fitted random effects have unexpected participant schema")
  random_coefficients <- re[participants, random_names, drop = FALSE]
  random_intercept_functions <- random_coefficients[, seq_len(nr),
    drop = FALSE] %*% t(random_basis)
  random_slope_functions <- random_coefficients[, nr + seq_len(nr),
    drop = FALSE] %*% t(random_basis)
  rownames(random_intercept_functions) <- participants
  rownames(random_slope_functions) <- participants
  group_index <- match(participant, participants)
  slope_matrix <- matrix(slope_values, nrow = n_curves,
    ncol = n_time)
  fitted_values <- scalar %*% coefficient_functions +
    random_intercept_functions[group_index, , drop = FALSE] +
    random_slope_functions[group_index, , drop = FALSE] * slope_matrix
  residuals <- Y - fitted_values
  sigma2 <- as.numeric(fit$sigma)^2
  re_covariance <- tryCatch(as.matrix(nlme::getVarCov(fit,
    type = "random.effects")), error = function(e) NULL)
  if (is.null(re_covariance) || !identical(dim(re_covariance), c(nd, nd)))
    re_covariance <- as.matrix(nlme::pdMatrix(
      fit$modelStruct$reStruct[[1L]])) * sigma2
  .etr_assert(identical(dim(re_covariance), c(nd, nd)) &&
      all(is.finite(re_covariance)) && is.finite(sigma2) && sigma2 > 0 &&
      max(abs(re_covariance - t(re_covariance))) < 1e-7 &&
      min(eigen(re_covariance, symmetric = TRUE,
        only.values = TRUE)$values) > -1e-7,
    "random intercept/slope covariance matrix is invalid")
  structure(list(
    method = if (reml) "joint_bspline_slope_REML" else "joint_bspline_slope_ML",
    estimator = "nlme_unstructured_participant_random_bspline_intercept_slope_iid",
    backend = "nlme::lme", source_python_full_parity = FALSE,
    dimension = dimension, time = time, curve_ids = ids,
    participant_ids = participants, curve_participant_ids = participant,
    predictor_names = scalar_names, random_slope_predictor = random_slope_predictor,
    random_slope_values = slope_values, fixed_basis = fixed_basis,
    random_basis = random_basis, fixed_basis_coefficients = fixed_coefficients,
    fixed_coefficient_functions = coefficient_functions,
    fixed_standard_errors = coefficient_se,
    fixed_parameter_covariance = vc,
    random_effect_coefficients = random_coefficients,
    random_effect_functions = random_intercept_functions,
    random_slope_effect_functions = random_slope_functions,
    random_effect_covariance = re_covariance,
    intercept_slope_covariance = re_covariance[
      seq_len(nr), nr + seq_len(nr), drop = FALSE],
    residual_variance = sigma2, fitted_functions = fitted_values,
    residual_functions = residuals, observed_functions = Y,
    fixed_long_design = X, random_long_design = R, scalar_design = scalar,
    n_participants = n_groups, n_curves = n_curves,
    n_time = n_time, spline_degree = degree, reml = reml,
    fitted_model = fit,
    provenance = list(
      scientific_scope = "iid_one_random_slope_unstructured_joint_bspline",
      random_slope_supported = TRUE,
      trial_random_effect_supported = FALSE,
      residual_correlation = "iid", independent_source_certificate = FALSE)),
    class = c("etr_joint_bspline_mixed_slope", "etr_joint_bspline_mixed"))
}
