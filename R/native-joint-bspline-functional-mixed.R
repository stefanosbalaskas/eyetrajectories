# Native R joint B-spline functional mixed effects, basic participant-only model.
# Frozen Python reference: eyetrajectoriespy 1.2.0 c1cd95a,
# src/eyetrajectoriespy/functional_mixed_effects.py.
# This is the corresponding *scientific model* under the restricted options
# random intercept only, iid residuals; no assertion of full Python API parity.

.etr_joint_bspline_basis <- function(time, size, degree) {
  .etr_assert(is.numeric(size) && length(size) == 1L &&
      is.finite(size) && size == floor(size) &&
      size >= degree + 1L, "basis size must be >= degree + 1")
  n_inner <- as.integer(size - degree - 1L)
  interior <- if (n_inner) {
    seq(time[1L], time[length(time)], length.out = n_inner + 2L)[
      seq_len(n_inner) + 1L]
  } else numeric(0)
  basis <- splines::bs(time, knots = interior, degree = degree,
    intercept = TRUE, Boundary.knots = range(time))
  basis <- unclass(basis)
  .etr_assert(is.matrix(basis) && ncol(basis) == size &&
      all(is.finite(basis)), "joint B-spline basis could not be constructed")
  basis
}

#' Joint B-spline Gaussian functional mixed model (restricted native scope)
#'
#' Fits functional fixed-effect coefficient splines and a participant-level
#' random-intercept function *jointly* across the observed time grid, using an
#' unstructured covariance for participant B-spline random coefficients and
#' independent Gaussian residuals. Uses the R package nlme, never Python.
#'
#' This implements the basic source model in a different optimizer. It does
#' not implement random slopes, nested trials, structured residual covariance,
#' or exact statsmodels optimizer and result-object contracts.
#' @param trajectories Finite complete native etr_trajectory_set.
#' @param design A data.frame with unique curve_id rows and numeric predictors.
#' @param predictors Names of explicitly declared numeric fixed predictors;
#'   character(0) gives a functional intercept-only model.
#' @param participant_column Column in trajectories$metadata identifying groups.
#' @param dimension One named response dimension.
#' @param fixed_basis_size,random_basis_size B-spline basis sizes.
#' @param spline_degree Nonnegative B-spline polynomial degree.
#' @param reml TRUE for restricted maximum likelihood; FALSE for ML.
#' @param maxiter Maximum optimizer iterations.
#' @return S3 etr_joint_bspline_mixed model with coefficient functions,
#'   standard errors, random-intercept functions, fitted functions, residuals,
#'   variance components and the fitted nlme model.
#' @export
etr_fit_joint_bspline_functional_mixed_effects <- function(
    trajectories, design, predictors, participant_column, dimension,
    fixed_basis_size = 6L, random_basis_size = 4L,
    spline_degree = 3L, reml = TRUE, maxiter = 500L) {
  if (!requireNamespace("nlme", quietly = TRUE))
    stop("The optional R package 'nlme' must be installed for joint mixed-effects fitting", call. = FALSE)
  etr_validate(trajectories, require_complete = TRUE)
  .etr_assert(all(is.finite(trajectories$values)),
    "joint Gaussian functional mixed effects requires finite complete data")
  .etr_assert(!identical(trajectories$coordinate_system, "probability_simplex"),
    "direct Gaussian mixed effects is not supported for probability_simplex data")
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
    "participant_column must identify a trajectory metadata column")
  .etr_assert(is.character(dimension) && length(dimension) == 1L &&
      !is.na(dimension) && dimension %in% trajectories$dimension_names,
    "dimension must identify one existing response channel")
  .etr_assert(is.data.frame(design) && "curve_id" %in% names(design) &&
      nrow(design) == length(trajectories$curve_ids) &&
      !anyNA(design$curve_id) &&
      !anyDuplicated(as.character(design$curve_id)),
    "design requires one unique curve_id row per trajectory")
  .etr_assert(is.character(predictors) && !anyNA(predictors) &&
      !anyDuplicated(predictors) && !any(predictors == "curve_id") &&
      all(predictors %in% names(design)),
    "predictors must be unique declared design columns")
  ids <- trajectories$curve_ids
  align <- match(ids, as.character(design$curve_id))
  .etr_assert(!anyNA(align), "design does not include all source curve IDs")
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
    "basis sizes must be finite integers between degree+1 and number of time points")
  nf <- as.integer(fixed_basis_size)
  nr <- as.integer(random_basis_size)
  degree <- as.integer(spline_degree)
  .etr_assert(n_time >= max(nf, nr),
    "common time grid must contain at least as many points as each spline basis")
  participant <- as.character(trajectories$metadata[[participant_column]])
  .etr_assert(length(participant) == n_curves &&
      !anyNA(participant) && all(nzchar(participant)),
    "participant identifiers must be complete")
  participants <- unique(participant)
  n_groups <- length(participants)
  .etr_assert(n_groups >= max(4L, nr + 1L),
    "joint mixed effects requires at least max(4, random_basis_size+1) participants")
  n_obs <- n_curves * n_time
  n_fixed <- (length(predictors) + 1L) * nf
  .etr_assert(n_obs > n_fixed + nr &&
      as.double(n_obs) * as.double(n_groups) * as.double(nr) <= 4e6,
    "joint mixed effects design is underdetermined or exceeds dense safety limit")
  scalar <- matrix(1, n_curves, length(predictors) + 1L)
  scalar_names <- c("Intercept", predictors)
  colnames(scalar) <- scalar_names
  if (length(predictors)) for (j in seq_along(predictors)) {
    val <- design[[predictors[j]]]
    .etr_assert(is.numeric(val) && is.null(dim(val)) &&
        length(val) == n_curves && all(is.finite(val)),
      paste("predictor", predictors[j], "must be a finite numeric scalar variable"))
    scalar[, j + 1L] <- val
  }
  fixed_basis <- .etr_joint_bspline_basis(time, nf, degree)
  random_basis <- .etr_joint_bspline_basis(time, nr, degree)
  .etr_assert(qr(scalar)$rank == ncol(scalar),
    "fixed scalar design is rank deficient")
  fixed_names <- as.vector(unlist(lapply(seq_along(scalar_names),
    function(j) paste0(".etr_fx", j, "_", seq_len(nf)))))
  random_names <- paste0(".etr_re", seq_len(nr))
  X <- matrix(NA_real_, n_obs, n_fixed,
    dimnames = list(NULL, fixed_names))
  for (j in seq_along(scalar_names)) for (k in seq_len(nf)) {
    X[, (j - 1L) * nf + k] <-
      rep(scalar[, j], each = n_time) * rep(fixed_basis[, k], times = n_curves)
  }
  .etr_assert(qr(X)$rank == n_fixed, "joint fixed-effects spline design is rank deficient")
  R <- matrix(NA_real_, n_obs, nr, dimnames = list(NULL, random_names))
  for (k in seq_len(nr))
    R[, k] <- rep(random_basis[, k], times = n_curves)
  Y <- matrix(trajectories$values[, , match(dimension,
    trajectories$dimension_names), drop = FALSE],
    nrow = n_curves, ncol = n_time)
  observed <- as.vector(t(Y))
  dat <- data.frame(.etr_y = observed,
    .etr_pid = factor(rep(participant, each = n_time), levels = participants))
  for (k in seq_along(fixed_names)) dat[[fixed_names[k]]] <- X[, k]
  for (k in seq_along(random_names)) dat[[random_names[k]]] <- R[, k]
  fixed_formula <- stats::reformulate(fixed_names, response = ".etr_y", intercept = FALSE)
  random_formula <- stats::reformulate(random_names, intercept = FALSE)
  fit <- tryCatch(
    nlme::lme(fixed = fixed_formula,
      random = list(.etr_pid = nlme::pdSymm(random_formula)),
      data = dat, method = if (reml) "REML" else "ML",
      control = nlme::lmeControl(maxIter = as.integer(maxiter),
        msMaxIter = as.integer(maxiter), returnObject = FALSE)),
    error = function(e) stop(paste("joint B-spline mixed model did not converge:",
      conditionMessage(e)), call. = FALSE))
  fe <- nlme::fixef(fit)
  .etr_assert(all(fixed_names %in% names(fe)),
    "fitted model did not return all spline fixed effects")
  fixed_coefficients <- matrix(as.numeric(fe[fixed_names]),
    nrow = length(scalar_names), ncol = nf, byrow = TRUE,
    dimnames = list(scalar_names, NULL))
  coefficient_functions <- fixed_coefficients %*% t(fixed_basis)
  dimnames(coefficient_functions) <- list(scalar_names, NULL)
  vc <- as.matrix(stats::vcov(fit))
  .etr_assert(all(fixed_names %in% rownames(vc)) &&
      all(fixed_names %in% colnames(vc)),
    "fitted fixed-effect covariance lacks expected source columns")
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
    "fitted participant random-effects table has unexpected schema")
  random_coefficients <- re[participants, random_names, drop = FALSE]
  random_functions <- random_coefficients %*% t(random_basis)
  rownames(random_functions) <- participants
  group_index <- match(participant, participants)
  fitted_values <- scalar %*% coefficient_functions +
    random_functions[group_index, , drop = FALSE]
  residuals <- Y - fitted_values
  sigma2 <- as.numeric(fit$sigma)^2
  re_covariance <- tryCatch(
    as.matrix(nlme::getVarCov(fit, type = "random.effects")),
    error = function(e) NULL)
  if (is.null(re_covariance) ||
      !identical(dim(re_covariance), c(nr, nr))) {
    re_covariance <- as.matrix(nlme::pdMatrix(
      fit$modelStruct$reStruct[[1L]])) * sigma2
  }
  .etr_assert(identical(dim(re_covariance), c(nr, nr)) &&
      all(is.finite(re_covariance)) && is.finite(sigma2) && sigma2 > 0,
    "mixed-effects variance component extraction failed")
  structure(list(
    method = if (reml) "joint_bspline_REML" else "joint_bspline_ML",
    estimator = "nlme_unstructured_participant_random_bspline_intercept_iid",
    backend = "nlme::lme", source_python_full_parity = FALSE,
    dimension = dimension, time = time, curve_ids = ids,
    participant_ids = participants, curve_participant_ids = participant,
    predictor_names = scalar_names, fixed_basis = fixed_basis,
    random_basis = random_basis, fixed_basis_coefficients = fixed_coefficients,
    fixed_coefficient_functions = coefficient_functions,
    fixed_standard_errors = coefficient_se,
    fixed_parameter_covariance = vc,
    random_effect_coefficients = random_coefficients,
    random_effect_functions = random_functions,
    random_effect_covariance = re_covariance,
    residual_variance = sigma2, fitted_functions = fitted_values,
    residual_functions = residuals,
    observed_functions = Y, fixed_long_design = X,
    random_long_design = R, scalar_design = scalar,
    n_participants = n_groups, n_curves = n_curves,
    n_time = n_time, spline_degree = degree, reml = reml,
    fitted_model = fit,
    provenance = list(
      scientific_scope = "basic_iid_random_intercept_unstructured_bspline",
      random_slope_supported = FALSE, trial_random_effect_supported = FALSE,
      residual_correlation = "iid", independent_source_certificate = FALSE)),
    class = "etr_joint_bspline_mixed")
}

#' Pointwise functional coefficient table for the joint B-spline mixed fit
#' @param fit A joint B-spline functional mixed model.
#' @param confidence_level Pointwise normal confidence level in (0, 1).
#' @return data.frame with coefficient, time, estimate, se, lower, upper.
#' @export
etr_joint_bspline_mixed_coefficient_frame <- function(fit,
    confidence_level = .95) {
  .etr_assert(inherits(fit, "etr_joint_bspline_mixed") &&
      is.matrix(fit$fixed_coefficient_functions) &&
      is.matrix(fit$fixed_standard_errors),
    "fit must be a native joint B-spline mixed model")
  .etr_assert(is.numeric(confidence_level) && length(confidence_level) == 1L &&
      is.finite(confidence_level) && confidence_level > 0 && confidence_level < 1,
    "confidence_level must lie in (0, 1)")
  crit <- stats::qnorm((1 + confidence_level) / 2)
  estimates <- as.vector(t(fit$fixed_coefficient_functions))
  ses <- as.vector(t(fit$fixed_standard_errors))
  data.frame(
    coefficient = rep(rownames(fit$fixed_coefficient_functions),
      each = length(fit$time)),
    time = rep(fit$time, times = nrow(fit$fixed_coefficient_functions)),
    estimate = estimates, se = ses,
    lower = estimates - crit * ses,
    upper = estimates + crit * ses,
    stringsAsFactors = FALSE)
}
