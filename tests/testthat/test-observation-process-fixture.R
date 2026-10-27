# Research-only tests; exercise fixture semantics, not inferential coverage.
fixture_path <- file.path("scripts", "observation_process_fixture.R")
if (!file.exists(fixture_path))
  fixture_path <- file.path("..", "..", "scripts",
                            "observation_process_fixture.R")
source(fixture_path, local = TRUE)

testthat::test_that("latent population truth and registered covariates are distinct", {
  x <- et_obs_generate_complete(12L, 1241L)
  testthat::expect_identical(dim(x$values), c(12L, 3L, 41L, 2L))
  testthat::expect_equal(x$truth_mean[, 1L], sin(2 * pi * x$time))
  testthat::expect_equal(x$truth_mean[, 2L], cos(2 * pi * x$time))
  testthat::expect_true(all(x$truth_contrast == 0))
  testthat::expect_equal(unname(as.integer(table(x$registry$group))),
                         c(6L, 6L))
  testthat::expect_true(all(is.finite(x$registry$Z)))
  testthat::expect_error(et_obs_generate_complete(11L, 1241L),
                         "even integer")
})

testthat::test_that("generation and masking are deterministic without RNG leakage", {
  set.seed(123L)
  prior <- get(".Random.seed", .GlobalEnv)
  a <- et_obs_generate_complete(12L, 8001L)
  b <- et_obs_generate_complete(12L, 8001L)
  testthat::expect_identical(a$values, b$values)
  testthat::expect_identical(prior, get(".Random.seed", .GlobalEnv))
  m1 <- et_obs_make_mask(a, "mar_gaze", 8002L)
  m2 <- et_obs_make_mask(a, "mar_gaze", 8002L)
  testthat::expect_identical(m1$keep, m2$keep)
  testthat::expect_identical(prior, get(".Random.seed", .GlobalEnv))
  testthat::expect_false(identical(m1$keep,
                                   et_obs_make_mask(a, "mar_gaze",
                                                    8003L)$keep))
})

testthat::test_that("complete and MCAR observations never invent missing gaze", {
  x <- et_obs_generate_complete(12L, 8050L)
  m <- et_obs_make_mask(x, "complete", 8051L)
  obs <- et_obs_observed_only(x, m)
  testthat::expect_equal(nrow(obs$samples), length(x$values))
  testthat::expect_false(anyNA(obs$samples$Y))
  testthat::expect_false(any(c("truth_mean", "participant_effect") %in%
                               names(obs)))
  d <- et_obs_naive_diagnostic(obs, x$truth_mean, x$truth_contrast)
  testthat::expect_identical(d$status, "success")
  mc <- et_obs_make_mask(x, "mcar_gaze", 8052L, "moderate")
  testthat::expect_equal(range(mc$point_probability), c(.6, .6))
  o <- et_obs_observed_only(x, mc)
  testthat::expect_equal(nrow(o$samples), sum(mc$keep))
  testthat::expect_identical(o$samples$Y, as.numeric(x$values[mc$keep]))
})

testthat::test_that("MAR uses observed baseline/time, MNAR uses latent gaze", {
  x <- et_obs_generate_complete(12L, 8100L)
  mar <- et_obs_make_mask(x, "mar_gaze", 8101L)
  mn <- et_obs_make_mask(x, "mnar_gaze", 8102L)
  testthat::expect_true(mar$known_point_propensity)
  testthat::expect_false(mn$known_point_propensity)
  testthat::expect_true(mn$oracle_only)
  testthat::expect_equal(mar$point_probability[1L, 1L, , 1L],
                         mar$point_probability[1L, 2L, , 1L])
  testthat::expect_true(any(abs(mn$point_probability[1L, 1L, , 1L] -
                                mn$point_probability[1L, 2L, , 1L]) > 1e-9))
})

testthat::test_that("whole participant dropout is not pointwise gaze thinning", {
  x <- et_obs_generate_complete(48L, 8200L)
  m <- et_obs_make_mask(x, "mar_dropout", 8201L, "severe")
  o <- et_obs_observed_only(x, m)
  testthat::expect_true(m$known_selection_propensity)
  testthat::expect_true(all(m$keep[m$selected, , , ]))
  testthat::expect_false(any(m$keep[!m$selected, , , ]))
  testthat::expect_identical(o$registry$selected, m$selected)
  testthat::expect_true(all(o$samples$participant %in%
                            which(m$selected)))
  mn <- et_obs_make_mask(x, "mnar_dropout", 8202L)
  testthat::expect_true(mn$oracle_only)
  testthat::expect_false(mn$known_selection_propensity)
})

testthat::test_that("sparse irregular grids are subsets and have no fake propensity", {
  x <- et_obs_generate_complete(12L, 8300L)
  m <- et_obs_make_mask(x, "sparse_asynchronous", 8301L, "severe")
  o <- et_obs_observed_only(x, m)
  testthat::expect_true(m$grid_limitation)
  testthat::expect_true(all(is.na(m$point_probability)))
  testthat::expect_equal(nrow(o$samples), sum(m$keep))
  testthat::expect_true(all(o$samples$time %in% x$time))
  testthat::expect_true(all(is.finite(o$samples$Y)))
})

testthat::test_that("no-data and partial-support paths remain explicit", {
  x <- et_obs_generate_complete(12L, 8400L, n_trials = 2L)
  m <- et_obs_make_mask(x, "complete", 8401L)
  m$keep[] <- FALSE
  o <- et_obs_observed_only(x, m)
  z <- et_obs_naive_diagnostic(o, x$truth_mean, x$truth_contrast)
  testthat::expect_identical(z$status, "no_observation_support")
  testthat::expect_equal(z$mean_supported_fraction, 0)
  testthat::expect_true(is.na(z$mean_rmse_supported))
  testthat::expect_true(all(is.na(z$mean_estimate)))
})
