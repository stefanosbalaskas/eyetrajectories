test_that("split-conformal rank yields exact combinatorial false flags", {
  # For a frozen scoring rule and 20 distinct exchangeable scores, every
  # possible future rank is equally likely. Enumerate all 20 placements.
  universe <- seq_len(20L)
  for (alpha in c(.05, .10, .20)) {
    rejected <- vapply(seq_along(universe), function(i) {
      calibration <- universe[-i]
      threshold <- etr_split_conformal_threshold(calibration, alpha)
      universe[i] > threshold$threshold
    }, logical(1))
    expected <- (20L - ceiling(20 * (1-alpha)))
    expect_equal(sum(rejected), expected)
    expect_lte(sum(rejected)/20, alpha + 1e-12)
  }
})

test_that("split-conformal is unchanged by calibration score ordering", {
  scores <- c(0.31, 0.15, 0.17, 0.11, 0.82, 0.56, 0.09, 0.77, 0.33,
              0.15, 0.27, 0.24, 0.18, 0.40, 0.66, 0.73, 0.45,
              0.58, 0.72)
  original <- etr_split_conformal_threshold(scores, .10)
  permutation <- etr_split_conformal_threshold(rev(scores), .10)
  expect_equal(original$threshold, permutation$threshold)
  expect_equal(original$rank, 18L)
  # Weak inequality treats equal heldout/calibration scores conservatively;
  # finite-sample exact equality of the null FPR needs a no-ties condition.
  expect_false(0.15 > etr_split_conformal_threshold(rep(.15, 19L), .10)$threshold)
})

test_that("heldout native FPCA conformal flags preserve ID separation", {
  time <- seq(0, 1, length.out = 21L)
  set.seed(314159L)
  draw <- function(ids, deviation = 0) {
    n <- length(ids)
    values <- array(NA_real_, c(n, length(time), 1L))
    for (i in seq_len(n)) {
      values[i, , 1L] <- sin(2*pi*time) +
        stats::rnorm(1L, sd=.25) * cos(2*pi*time) +
        stats::rnorm(1L, sd=.12) * sin(4*pi*time) +
        stats::rnorm(length(time), sd=.06) +
        deviation * sin(6*pi*time)
    }
    etr_trajectory_set(time, values, ids, "x")
  }
  train <- draw(paste0("train_", seq_len(10L)))
  cal <- draw(paste0("cal_", seq_len(19L)))
  test <- draw("test_independent")
  fit <- etr_fit_fpca(train, n_components=1L)
  screen <- etr_split_conformal_fpca_anomalies(fit, cal, test, alpha=.10)
  expect_equal(length(screen$training_ids), 10L)
  expect_equal(screen$cutoff$n_calibration, 19L)
  expect_equal(screen$cutoff$rank, 18L)
  expect_true(is.finite(screen$cutoff$threshold))
  expect_gte(screen$cutoff$threshold, 0)
  expect_true(is.logical(screen$test$is_anomaly))
  expect_equal(nrow(screen$test), 1L)
  # No guarantee can be inferred for this one observed realization.
})
