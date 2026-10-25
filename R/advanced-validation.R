# Known-truth designs are independent of the estimators being evaluated.
#' Simulate a randomized, participant-level functional treatment contrast
#'
#' Balanced randomized two-arm allocation. The treatment changes the expected
#' x(t) by effect_x*sin(pi*t) and y(t) by effect_y*cos(pi*t).
#' @param n_subjects Even number of independent participants, >= 8.
#' @param trials_per_subject Trials per participant, >= 2.
#' @param n_time Common grid points, >= 5.
#' @param effect_x Known x-channel treatment coefficient.
#' @param effect_y Known y-channel treatment coefficient.
#' @param seed Random seed.
#' @export
etr_simulate_group_contrast <- function(n_subjects = 20L,
                                        trials_per_subject = 3L, n_time = 41L,
                                        effect_x = 0.4, effect_y = -0.2,
                                        seed = 11L) {
  .etr_assert(is.numeric(n_subjects) && length(n_subjects) == 1L &&
    is.finite(n_subjects) && n_subjects == as.integer(n_subjects) &&
    n_subjects >= 8L && n_subjects %% 2L == 0L, "n_subjects must be even integer >= 8")
  .etr_assert(all(is.finite(c(effect_x, effect_y))) &&
    length(effect_x) == 1L && length(effect_y) == 1L,
    "effect_x and effect_y must be finite scalars")
  generated <- etr_simulate_hierarchical(n_subjects = n_subjects,
                    trials_per_subject = trials_per_subject,
                    n_time = n_time, seed = seed)
  alloc <- .etr_seed_scope(seed + 1L, function() {
    sample(rep(c("control","treatment"), each = n_subjects %/% 2L))
  })
  pid <- generated$participant
  level <- alloc[match(pid, unique(pid))]
  x <- generated$trajectories
  effect <- cbind(effect_x * sin(pi*x$time), effect_y * cos(pi*x$time))
  for (i in seq_along(pid)) {
    if (level[i] == "treatment") {
      x$values[i, , 1L] <- x$values[i, , 1L] + effect[, 1L]
      x$values[i, , 2L] <- x$values[i, , 2L] + effect[, 2L]
    }
  }
  x$metadata$treatment <- level
  list(trajectories = x, participant = pid, treatment = level,
       true_contrast = effect, n_subjects = n_subjects,
       randomization_unit = "participant", seed = seed)
}

#' Finite-sample known-truth group contrast coverage simulation
#'
#' Reports pointwise and whole-function simultaneous inclusion rates;
#' neither is asserted to achieve nominal coverage without evidence.
#' @param simulations Number of independently generated studies, >= 5.
#' @param n_subjects Independent participants per study.
#' @param B Bootstrap replicates per study (>= 39).
#' @param alpha Target miscoverage, strictly (0,1).
#' @param seed Initial deterministic seed.
#' @export
etr_evaluate_group_contrast_coverage <- function(simulations = 20L,
                                                  n_subjects = 20L,
                                                  B = 99L, alpha = .1,
                                                  seed = 100L) {
  .etr_assert(is.numeric(simulations) && length(simulations) == 1L &&
    is.finite(simulations) && simulations == as.integer(simulations) &&
    simulations >= 5L && simulations <= 500L, "simulations must be integer 5 to 500")
  results <- lapply(seq_len(simulations), function(i) {
    s <- etr_simulate_group_contrast(n_subjects = n_subjects, seed = seed + 2L*i)
    fit <- etr_bootstrap_group_contrast(s$trajectories, s$participant,
                                        s$treatment, B = B, alpha = alpha,
                                        seed = seed + 2L*i+1L)
    pointwise <- s$true_contrast >= fit$pointwise_lower &
      s$true_contrast <= fit$pointwise_upper
    allband <- s$true_contrast >= fit$simultaneous_lower &
      s$true_contrast <= fit$simultaneous_upper
    data.frame(simulation = i, simultaneous_inclusion = all(allband),
               mean_pointwise_inclusion = mean(pointwise),
               contrast_rmse = sqrt(mean((fit$difference - s$true_contrast)^2)))
  })
  tab <- do.call(rbind, results)
  p <- mean(tab$simultaneous_inclusion)
  list(results = tab, simultaneous_coverage = p,
       mean_pointwise_coverage = mean(tab$mean_pointwise_inclusion),
       monte_carlo_se = sqrt(p*(1-p)/simulations),
       simulations = simulations, alpha = alpha,
       source = "known_truth_participant_randomized_simulation",
       qualification = "empirical_diagnostic_only")
}

#' Participant-grouped cross-validation of scalar-on-FPCA prediction
#'
#' Fits both FPCA and Gaussian regression strictly inside each training fold.
#' No held-out participant contributes to PCA, standardization, or regression.
#' @param x Complete native common-grid collection.
#' @param outcome Finite scalar outcome per curve.
#' @param participant Participant IDs or metadata column.
#' @param folds Participant folds (2 to n_groups).
#' @param n_components Fixed integer PCA components.
#' @param seed Randomization seed.
#' @export
etr_grouped_fpca_crossval <- function(x, outcome, participant,
                                      folds = 5L, n_components = 2L,
                                      seed = 8L) {
  etr_validate(x, require_complete = TRUE)
  n <- dim(x$values)[1L]
  .etr_assert(is.numeric(outcome) && length(outcome) == n &&
                all(is.finite(outcome)), "outcome must be finite and match curves")
  if (length(participant) == 1L && is.character(participant) &&
      participant %in% names(x$metadata)) participant <- x$metadata[[participant]]
  .etr_assert(length(participant) == n && !anyNA(participant),
              "participant must label each curve")
  ids <- unique(as.character(participant))
  .etr_assert(is.numeric(folds) && length(folds) == 1L && is.finite(folds) &&
    folds == as.integer(folds) && folds >= 2L && folds <= length(ids),
    "folds must be integer from 2 to number of participants")
  .etr_assert(is.numeric(n_components) && length(n_components) == 1L &&
    is.finite(n_components) && n_components == as.integer(n_components) &&
    n_components >= 1L, "n_components must be integer >= 1")
  allocation <- .etr_seed_scope(seed, function() {
    sample(rep(seq_len(folds), length.out = length(ids)))
  })
  assigned <- allocation[match(as.character(participant), ids)]
  oof <- rep(NA_real_, n)
  for (f in seq_len(folds)) {
    test_idx <- which(assigned == f)
    train_idx <- which(assigned != f)
    .etr_assert(length(train_idx) >= n_components + 3L,
                "training fold lacks enough independent curves for PCA regression")
    fit <- etr_fit_fpca(etr_subset(x, train_idx),
                         n_components = as.integer(n_components))
    reg <- etr_fit_scalar_on_fpca(fit, outcome[train_idx],
                                  n_components = as.integer(n_components))
    oof[test_idx] <- etr_predict_scalar_on_fpca(reg, etr_subset(x, test_idx))
  }
  .etr_assert(all(is.finite(oof)), "out-of-fold predictions were not finite")
  data.frame(curve_id = x$curve_ids, participant = as.character(participant),
             fold = assigned, observed = outcome, predicted = oof,
             squared_error = (outcome - oof)^2,
             row.names = NULL)
}
