# Research-only observation-process fixture for eyetrajectories.
# No package exports or production estimators are changed.
# Source directly: source("scripts/observation_process_fixture.R")
#
# Every curve is generated completely BEFORE its observation mechanism.
# True values for masked gaze are kept only in the sealed simulation fixture.
# This module provides POINT ESTIMATES and support diagnostics, NOT confidence bands.

et_obs_scoped_seed <- function(seed, fun) {
  if (length(seed) != 1L || !is.finite(seed) || seed != as.integer(seed) ||
      seed < 1L || seed > .Machine$integer.max)
    stop("Invalid generating seed.", call. = FALSE)
  had <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had) prior <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (had) assign(".Random.seed", prior, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(as.integer(seed))
  fun()
}

et_obs_clip <- function(x, lower = .05, upper = .95) {
  pmin(upper, pmax(lower, x))
}

et_obs_generate_complete <- function(n_subjects, seed,
    family = "gaussian_baseline", n_trials = 3L, n_time = 41L) {
  families <- c("gaussian_baseline", "heavy_t3",
                "heteroskedastic_groups", "skewed_lognormal")
  if (!family %in% families) stop("Unknown latent family.", call. = FALSE)
  if (length(n_subjects) != 1L || is.na(n_subjects) ||
      n_subjects != as.integer(n_subjects) || n_subjects < 8L ||
      n_subjects %% 2L != 0L)
    stop("n_subjects must be an even integer >= 8.", call. = FALSE)
  if (length(n_trials) != 1L || n_trials < 1L ||
      n_trials != as.integer(n_trials) ||
      length(n_time) != 1L || n_time < 5L ||
      n_time != as.integer(n_time))
    stop("Invalid trial/time design.", call. = FALSE)
  et_obs_scoped_seed(seed, function() {
    n <- as.integer(n_subjects)
    J <- as.integer(n_trials)
    nt <- as.integer(n_time)
    time <- seq(0, 1, length.out = nt)
    truth_mean <- cbind(x = sin(2 * pi * time),
                        y = cos(2 * pi * time))
    truth_contrast <- matrix(0, nt, 2L,
                             dimnames = list(NULL, c("x", "y")))
    Z <- stats::rnorm(n)  # fully observed for all eligible participants
    group <- as.integer(seq_len(n) > n / 2L)
    residual <- switch(family,
      gaussian_baseline = matrix(stats::rnorm(n * 2L, sd = .25), n, 2L),
      heavy_t3 = matrix(stats::rt(n * 2L, df = 3L) * (.25 / sqrt(3)), n, 2L),
      heteroskedastic_groups = {
        sd_by_group <- ifelse(group == 0L, .13, .40)
        matrix(stats::rnorm(n * 2L), n, 2L) * sd_by_group
      },
      skewed_lognormal = {
        s <- .65
        raw <- exp(stats::rnorm(n * 2L, sd = s))
        centered <- (raw - exp(s * s / 2)) /
          sqrt((exp(s * s) - 1) * exp(s * s))
        matrix(.25 * centered, n, 2L)
      })
    effect <- residual + matrix(rep(.22 * Z, 2L), n, 2L)
    trial_effect <- array(stats::rnorm(n * J * 2L, sd = .15),
                          dim = c(n, J, 2L))
    values <- array(NA_real_, dim = c(n, J, nt, 2L))
    for (ch in seq_len(2L)) {
      basis <- if (ch == 1L) sin(pi * time) else cos(pi * time)
      for (i in seq_len(n)) for (j in seq_len(J)) {
        values[i, j, , ch] <- truth_mean[, ch] +
          (effect[i, ch] + trial_effect[i, j, ch]) * basis +
          stats::rnorm(nt, sd = .05)
      }
    }
    list(values = values, time = time, truth_mean = truth_mean,
         truth_contrast = truth_contrast, participant_effect = effect,
         registry = data.frame(participant = seq_len(n), group = group,
                               Z = Z), family = family, seed = as.integer(seed))
  })
}

et_obs_make_mask <- function(latent, mechanism, seed,
                             severity = "moderate") {
  mechanisms <- c("complete", "mcar_gaze", "mar_gaze", "mnar_gaze",
                  "mar_dropout", "mnar_dropout", "unequal_density",
                  "sparse_asynchronous")
  if (!mechanism %in% mechanisms)
    stop("Unknown observation mechanism.", call. = FALSE)
  levels <- c(mild = .80, moderate = .60, severe = .40)
  if (!severity %in% names(levels))
    stop("Unknown missingness severity.", call. = FALSE)
  target <- unname(levels[[severity]])
  et_obs_scoped_seed(seed, function() {
    d <- dim(latent$values)
    n <- d[1L]; J <- d[2L]; nt <- d[3L]
    times <- latent$time
    Z <- latent$registry$Z
    p <- array(1, dim = d)
    pS <- rep(1, n)
    selected <- rep(TRUE, n)
    selected_pi_known_from_registry <- mechanism == "mar_dropout"
    pi_point_known_from_observed <- mechanism %in%
      c("complete", "mcar_gaze", "mar_gaze", "mar_dropout")
    if (mechanism == "mcar_gaze") {
      p[] <- target
    } else if (mechanism %in% c("mar_gaze", "mnar_gaze")) {
      for (i in seq_len(n)) for (ch in seq_len(2L)) {
        eta <- stats::qlogis(target) + .65 * Z[i] +
          .50 * cos(2 * pi * times) + .12 * (ch == 2L)
        if (mechanism == "mar_gaze") {
          probs <- et_obs_clip(stats::plogis(eta))
          p[i, , , ch] <- matrix(rep(probs, each = J), J, nt)
        } else {
          # Uses unobserved current gaze: intentionally non-identifiable.
          centered <- latent$values[i, , , ch] -
            matrix(rep(latent$truth_mean[, ch], each = J), J, nt)
          p[i, , , ch] <- et_obs_clip(stats::plogis(
            matrix(rep(eta, each = J), J, nt) + 1.15 * centered / .35))
        }
      }
    } else if (mechanism %in% c("mar_dropout", "mnar_dropout")) {
      eta <- stats::qlogis(target) + .70 * Z
      if (mechanism == "mnar_dropout")
        eta <- eta + 1.15 * latent$participant_effect[, 1L] / .35
      pS <- et_obs_clip(stats::plogis(eta))
      selected <- stats::runif(n) < pS
    } else if (mechanism == "unequal_density") {
      for (i in seq_len(n)) {
        density <- .20 + .80 * (i - 1) / max(1, n - 1)
        probs <- et_obs_clip(target * density *
                             (.65 + .35 * sin(pi * times)^2))
        for (ch in seq_len(2L))
          p[i, , , ch] <- matrix(rep(probs, each = J), J, nt)
      }
    }
    if (mechanism == "sparse_asynchronous") {
      keep <- array(FALSE, dim = d)
      for (i in seq_len(n)) for (j in seq_len(J))
        for (ch in seq_len(2L)) {
          # Sparse, participant/trial-specific subsets of a 41-point grid.
          # No off-grid continuous-time interpolation is implied.
          k <- max(1L, min(nt,
            as.integer(round(nt * target * stats::runif(1L, .30, .95)))))
          shift <- stats::runif(1L)
          weights <- if (shift < .5)
            stats::dbeta(times * .98 + .01, 2, 5) else
            stats::dbeta(times * .98 + .01, 5, 2)
          indices <- sample.int(nt, size = k, replace = FALSE,
                                prob = weights)
          keep[i, j, indices, ch] <- TRUE
        }
      p[] <- NA_real_  # Not a Bernoulli cellwise design.
    } else {
      keep <- array(stats::runif(length(p)) < as.vector(p), dim = d)
    }
    if (mechanism %in% c("mar_dropout", "mnar_dropout"))
      for (i in which(!selected)) keep[i, , , ] <- FALSE
    list(keep = keep, point_probability = p, selection_probability = pS,
         selected = selected, mechanism = mechanism, severity = severity,
         seed = as.integer(seed),
         known_point_propensity = pi_point_known_from_observed,
         known_selection_propensity = selected_pi_known_from_registry,
         oracle_only = mechanism %in% c("mnar_gaze", "mnar_dropout"),
         grid_limitation = mechanism == "sparse_asynchronous")
  })
}

et_obs_observed_only <- function(latent, mask) {
  d <- dim(latent$values)
  idx <- expand.grid(participant = seq_len(d[1L]),
                     trial = seq_len(d[2L]),
                     time_index = seq_len(d[3L]),
                     channel = seq_len(d[4L]))
  stopifnot(nrow(idx) == length(mask$keep),
            identical(dim(mask$keep), d))
  idx <- idx[as.vector(mask$keep), , drop = FALSE]
  idx$time <- latent$time[idx$time_index]
  idx$channel <- c("x", "y")[idx$channel]
  # Only the actually observed Y values enter the observed-data object.
  idx$Y <- latent$values[mask$keep]
  idx$group <- latent$registry$group[idx$participant]
  idx$Z <- latent$registry$Z[idx$participant]
  registry <- latent$registry
  registry$selected <- mask$selected
  list(samples = idx, registry = registry,
       n_time = length(latent$time), n_trials = d[2L],
       time = latent$time, mechanism = mask$mechanism)
}

et_obs_naive_diagnostic <- function(observed, truth_mean, truth_contrast) {
  nt <- observed$n_time
  n <- nrow(observed$registry)
  mean_est <- matrix(NA_real_, nt, 2L)
  contrast_est <- matrix(NA_real_, nt, 2L)
  ng0 <- matrix(0L, nt, 2L)
  ng1 <- matrix(0L, nt, 2L)
  all_samples <- observed$samples
  for (ch in seq_len(2L)) for (t in seq_len(nt)) {
    z <- all_samples[all_samples$channel == c("x", "y")[ch] &
                       all_samples$time_index == t, , drop = FALSE]
    if (!nrow(z)) next
    # Average observed trials inside each participant BEFORE aggregation.
    by_person <- stats::aggregate(Y ~ participant + group,
                                   data = z, FUN = mean)
    g0 <- by_person$Y[by_person$group == 0L]
    g1 <- by_person$Y[by_person$group == 1L]
    ng0[t, ch] <- length(g0)
    ng1[t, ch] <- length(g1)
    mean_est[t, ch] <- mean(by_person$Y)
    if (length(g0) && length(g1))
      contrast_est[t, ch] <- mean(g1) - mean(g0)
  }
  mean_support <- is.finite(mean_est)
  contrast_support <- is.finite(contrast_est)
  # Point estimates only: no interval construction or coverage claims.
  status <- if (all(ng0 >= 2L & ng1 >= 2L)) "success" else
    "no_observation_support"
  metric <- function(est, truth, supported) {
    if (!any(supported)) return(c(bias = NA_real_, rmse = NA_real_))
    error <- est[supported] - truth[supported]
    c(bias = mean(error), rmse = sqrt(mean(error^2)))
  }
  m <- metric(mean_est, truth_mean, mean_support)
  ct <- metric(contrast_est, truth_contrast, contrast_support)
  list(status = status, full_grid_supported = all(ng0 >= 2 & ng1 >= 2),
       mean_supported_fraction = mean(mean_support),
       contrast_supported_fraction = mean(contrast_support),
       minimum_group_participants_per_coordinate =
         min(c(ng0, ng1)),
       mean_bias_supported = unname(m["bias"]),
       mean_rmse_supported = unname(m["rmse"]),
       contrast_bias_supported = unname(ct["bias"]),
       contrast_rmse_supported = unname(ct["rmse"]),
       mean_estimate = mean_est, contrast_estimate = contrast_est,
       observed_participants = length(unique(all_samples$participant)),
       eligible_participants = n, observed_gaze_samples = nrow(all_samples),
       observed_fraction = nrow(all_samples) /
         (n * observed$n_trials * nt * 2L))
}
