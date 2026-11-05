# Research-only independent-study paired comparison regression checks.
helper <- testthat::test_path("fixtures",
  "analyze_missing_gaze_ipw_helpers.R")
stopifnot(file.exists(helper))
source(helper,local=TRUE)

make_ipw_pair_fixture <- function(){
  data.frame(generator_seed=c(101L,102L,103L),
             mask_seed=c(201L,202L,203L),
             status=c("success","success","no_observation_support"),
             naive_mean_rmse_supported=c(2,3,4),
             ht_mean_rmse_supported=c(1,2,3),
             naive_mean_signed_supported=c(.4,.2,-.1),
             ht_mean_signed_supported=c(.1,.1,0),
             naive_contrast_rmse_supported=c(4,5,6),
             ht_contrast_rmse_supported=c(3,4,5),
             naive_contrast_signed_supported=c(.1,.2,.3),
             ht_contrast_signed_supported=c(0,0,0))
}

testthat::test_that("paired differences resample generating studies, not gaze",{
  x <- make_ipw_pair_fixture()
  set.seed(19L)
  rng <- get(".Random.seed",envir=.GlobalEnv)
  a <- et_ipw_paired_accuracy(x,"mean","available_coordinates",
                              6701L,B=99L)
  b <- et_ipw_paired_accuracy(x,"mean","available_coordinates",
                              6701L,B=99L)
  testthat::expect_identical(a,b)
  testthat::expect_identical(get(".Random.seed",envir=.GlobalEnv),rng)
  testthat::expect_equal(a$requested_datasets,3)
  testthat::expect_equal(a$paired_datasets,3)
  testthat::expect_equal(a$unsupported_full_grid,1)
  testthat::expect_equal(a$mean_paired_rmse_difference,-1)
  testthat::expect_equal(a$naive_mean_functional_rmse,3)
  testthat::expect_equal(a$ht_mean_functional_rmse,2)
  testthat::expect_equal(a$ht_naive_mean_rmse_ratio,2/3)
  testthat::expect_equal(a$paired_difference_lower_95,-1)
  testthat::expect_equal(a$paired_difference_upper_95,-1)
  testthat::expect_equal(a$ht_better_dataset_fraction,1)
})

testthat::test_that("full-grid conditional subset excludes unsupported datasets",{
  x <- make_ipw_pair_fixture()
  a <- et_ipw_paired_accuracy(x,"contrast","full_grid_only",
                              6702L,B=99L)
  testthat::expect_equal(a$requested_datasets,3)
  testthat::expect_equal(a$eligible_datasets,2)
  testthat::expect_equal(a$paired_datasets,2)
  testthat::expect_equal(a$excluded_from_pair,1)
  testthat::expect_equal(a$mean_paired_rmse_difference,-1)
})

testthat::test_that("missing one method excludes its entire matched pair",{
  x <- make_ipw_pair_fixture()
  x$ht_mean_rmse_supported[2L] <- NA_real_
  a <- et_ipw_paired_accuracy(x,"mean","available_coordinates",
                              6703L,B=99L)
  testthat::expect_equal(a$paired_datasets,2)
  testthat::expect_equal(a$excluded_from_pair,1)
  testthat::expect_equal(a$mean_paired_rmse_difference,-1)
})

testthat::test_that("all missing pairs return defined counts and NA metrics",{
  x <- make_ipw_pair_fixture()
  x$ht_mean_rmse_supported[] <- NA_real_
  a <- et_ipw_paired_accuracy(x,"mean","available_coordinates",
                              6704L,B=99L)
  testthat::expect_equal(a$paired_datasets,0)
  testthat::expect_true(is.na(a$mean_paired_rmse_difference))
  testthat::expect_true(is.na(a$paired_difference_lower_95))
})

testthat::test_that("duplicate seeds and undeclared errors fail closed",{
  x <- make_ipw_pair_fixture()
  x$generator_seed[2L] <- x$generator_seed[1L]
  testthat::expect_error(
    et_ipw_paired_accuracy(x,"mean","full_grid_only",6705L,B=99L),
    "Duplicate seed")
  x <- make_ipw_pair_fixture()
  x$status[2L] <- "unexpected"
  testthat::expect_error(
    et_ipw_paired_accuracy(x,"mean","full_grid_only",6705L,B=99L),
    "Unexpected study status")
})

testthat::test_that("no pseudo-replication when a study numerically fails",{
  x <- make_ipw_pair_fixture()
  x$status[1L] <- "numerical_failure"
  x$naive_mean_rmse_supported[1L] <- NA_real_
  x$ht_mean_rmse_supported[1L] <- NA_real_
  a <- et_ipw_paired_accuracy(x,"mean","available_coordinates",
                              6706L,B=99L)
  testthat::expect_equal(a$requested_datasets,3)
  testthat::expect_equal(a$numerical_failures,1)
  testthat::expect_equal(a$paired_datasets,2)
  testthat::expect_equal(a$mean_paired_rmse_difference,-1)
})
