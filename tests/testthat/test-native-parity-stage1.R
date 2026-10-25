test_that("landmark registration preserves the identity and aligns declared events", {
  t <- seq(0, 1, length.out = 9L)
  v <- array(0, c(2L, length(t), 2L))
  v[1L, , 1L] <- t
  v[2L, , 1L] <- t^2
  v[, , 2L] <- 1
  x <- etr_trajectory_set(t, v, c("a", "b"), c("x", "y"))
  id <- etr_register_landmarks(x, matrix(.5, 2L, 1L), .5)
  expect_equal(id$registered$values, x$values, tolerance = 1e-12)
  expect_equal(id$inverse_warps[1L, ], t)
  reg <- etr_register_landmarks(x, matrix(c(.25, .75), ncol = 1L), .5)
  expect_equal(as.vector(reg$inverse_warps[, 5L]), c(.25, .75))
  expect_equal(reg$registered$values[1L, 5L, 1L], .25)
  expect_equal(reg$registered$values[2L, 5L, 1L], .75^2)
  expect_equal(nrow(etr_registration_warp_frame(reg)), 18L)
  expect_error(etr_register_landmarks(x, matrix(0, 2L, 1L), .5),
               "source landmarks")
  expect_error(etr_register_landmarks(x, matrix(.5, 2L, 1L), 1),
               "target landmarks")
})

test_that("delay embedding and return maps satisfy deterministic sequence oracles", {
  d <- etr_delay_embedding(1:6, dimension = 3L, delay = 2L)
  expect_equal(as.vector(d), c(5, 6, 3, 4, 1, 2))
  expect_equal(attr(d, "target_sample_index"), 5:6)
  expect_error(etr_delay_embedding(1:4, dimension = 4L, delay = 2L),
               "not enough samples")
  map <- etr_poincare_return_map(c(-1, 1, -1, 1, -1, 1))
  expect_equal(map$crossing_times, c(1.5, 3.5, 5.5))
  expect_equal(map$return_map$return_interval, c(2, 2))
  none <- etr_poincare_return_map(1:6, threshold = 0)
  expect_equal(nrow(none$return_map), 0L)
})

test_that("recurrence graph exactly counts one triangle plus isolated node", {
  adj <- matrix(FALSE, 4L, 4L)
  adj[1:3, 1:3] <- TRUE
  diag(adj) <- FALSE
  rec <- structure(list(matrix = adj, kind = "auto", theiler = 0L),
                   class = "etr_recurrence")
  graph <- etr_recurrence_network(rec)
  expect_equal(graph$n_edges, 3)
  expect_equal(graph$density, 0.5)
  expect_equal(graph$triangles, 1)
  expect_equal(graph$transitivity, 1)
  expect_equal(graph$n_components, 2L)
  nodes <- etr_recurrence_network_nodes(graph)
  expect_equal(nodes$degree, c(2, 2, 2, 0))
  expect_true(is.na(nodes$clustering[4L]))
  rec$matrix[,] <- FALSE
  expect_equal(etr_recurrence_network(rec)$n_components, 4L)
  rec$kind <- "cross"
  expect_error(etr_recurrence_network(rec), "auto-recurrence")
})

test_that("split conformal quantile reports finite-sample rank and infinity", {
  z <- etr_split_conformal_threshold(1:9, .10)
  expect_equal(z$rank, 9)
  expect_equal(z$threshold, 9)
  expect_true(is.infinite(etr_split_conformal_threshold(1:8, .10)$threshold))
  expect_equal(etr_split_conformal_threshold(1:9, .20)$rank, 8L + 1L)
  expect_error(etr_split_conformal_threshold(c(1, NA_real_)), "nonnegative")
  expect_error(etr_split_conformal_threshold(1:10, alpha = 0), "strictly between")
})

test_that("frozen FPCA heldout calibration/test IDs do not overlap", {
  t <- seq(0, 1, length.out = 21L)
  make_set <- function(ids, anomaly = FALSE) {
    n <- length(ids)
    z <- array(0, c(n, length(t), 1L))
    for (i in seq_len(n))
      z[i, , 1L] <- sin(2 * pi * t) +
        (i / (n + 2)) * cos(2 * pi * t) +
        (if (anomaly) 5 else 0) * sin(4 * pi * t)
    etr_trajectory_set(t, z, ids, "x")
  }
  train <- make_set(paste0("train", 1:8))
  cal <- make_set(paste0("cal", 1:10))
  check <- make_set(c("test1", "test2"), anomaly = TRUE)
  fit <- etr_fit_fpca(train, n_components = 1L)
  scores <- etr_fpca_reconstruction_scores(fit, cal)
  expect_equal(nrow(scores), 10L)
  expect_true(all(scores$score >= 0))
  ans <- etr_split_conformal_fpca_anomalies(fit, cal, check, alpha = .2)
  expect_equal(nrow(ans$test), 2L)
  expect_true(all(ans$test$is_anomaly))
  expect_error(etr_split_conformal_fpca_anomalies(fit, cal, cal),
               "mutually disjoint")
})

test_that("optional R dependency catalog never claims scientific parity", {
  x <- etr_r_backend_catalog()
  expect_equal(nrow(x), 26L)
  expect_true(all(c("MFPCA", "fdapace", "fdasrvf", "refund",
                    "SCBmeanfd", "clubSandwich", "RTransferEntropy") %in%
                  x$package))
  expect_false(any(x$scientific_parity_verified))
  expect_true(all(grepl("^https://CRAN.R-project.org/package=", x$url)))
})
