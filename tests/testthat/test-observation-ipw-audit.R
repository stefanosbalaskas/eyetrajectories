# Regression for the 27 Oct 2026 trial/summary IPW audit mismatch.
helper <- file.path("scripts","audit_missing_gaze_ipw_helpers.R")
if (!file.exists(helper)) {
  helper <- file.path("..","..","scripts",
                      "audit_missing_gaze_ipw_helpers.R")
}
source(helper,local=TRUE)

testthat::test_that("observed_fraction is reconciled to mean_observed_fraction",{
  testthat::expect_identical(
    unname(et_ipw_summary_metric_map[["observed_fraction"]]),
    "mean_observed_fraction")
  z <- data.frame(observed_fraction=c(.40,.60))
  r <- data.frame(mean_observed_fraction=.50)
  testthat::expect_invisible(
    et_ipw_verify_metric(z,r,"observed_fraction",
                         "mean_observed_fraction"))
})

testthat::test_that("absent summary metrics fail with a diagnostic",{
  z <- data.frame(observed_fraction=c(.4,.6))
  r <- data.frame(not_observed_fraction=.5)
  testthat::expect_error(
    et_ipw_verify_metric(z,r,"observed_fraction",
                         "mean_observed_fraction"),
    "Missing summary metric: mean_observed_fraction")
})

testthat::test_that("incorrect cell aggregates fail, rather than passing NA",{
  z <- data.frame(observed_fraction=c(.4,.6))
  r <- data.frame(mean_observed_fraction=.45)
  testthat::expect_error(
    et_ipw_verify_metric(z,r,"observed_fraction",
                         "mean_observed_fraction"),
    "Metric mismatch")
})

testthat::test_that("all missing values reconcile only with explicit missing",{
  z <- data.frame(ht_mean_rmse_supported=c(NA_real_,NA_real_))
  testthat::expect_invisible(et_ipw_verify_metric(
    z,data.frame(ht_mean_rmse_supported=NA_real_),
    "ht_mean_rmse_supported","ht_mean_rmse_supported"))
  testthat::expect_error(et_ipw_verify_metric(
    z,data.frame(ht_mean_rmse_supported=0),
    "ht_mean_rmse_supported","ht_mean_rmse_supported"),
    "Metric mismatch")
})

testthat::test_that("invalid actual dimensions and nonfinite inputs fail",{
  z <- data.frame(observed_fraction=c(.4,.6))
  testthat::expect_error(et_ipw_verify_metric(
    z,data.frame(mean_observed_fraction="bad"),
    "observed_fraction","mean_observed_fraction"),
    "Invalid metric type")
  z$observed_fraction[1L] <- Inf
  testthat::expect_error(et_ipw_verify_metric(
    z,data.frame(mean_observed_fraction=.5),
    "observed_fraction","mean_observed_fraction"),
    "Nonfinite metric")
})
