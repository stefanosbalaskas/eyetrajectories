# Research-only direct specification tests for participant-normalized Hájek.
fixture <- testthat::test_path("fixtures","observation_process_fixture.R")
ipw <- testthat::test_path("fixtures","observation_ipw_research.R")
hajek <- testthat::test_path("fixtures","observation_hajek_research.R")
stopifnot(file.exists(fixture),file.exists(ipw),file.exists(hajek))
source(fixture,local=TRUE)
source(ipw,local=TRUE)
source(hajek,local=TRUE)

testthat::test_that("complete-data Hájek equals naive and HT at every grid cell",{
  x <- et_obs_generate_complete(12L,710001L)
  mask <- et_obs_make_mask(x,"complete",710002L)
  z <- et_obs_observed_only(x,mask)
  h <- et_obs_participant_hajek(z)
  na <- et_obs_naive_diagnostic(z,x$truth_mean,x$truth_contrast)
  ip <- et_obs_ipw_point_diagnostics(z,x$truth_mean,x$truth_contrast)
  testthat::expect_identical(h$status,"success")
  testthat::expect_true(all(h$support))
  testthat::expect_equal(h$mean_estimate,na$mean_estimate,tolerance=1e-12)
  testthat::expect_equal(h$contrast_estimate,na$contrast_estimate,
                         tolerance=1e-12)
  testthat::expect_equal(h$mean_estimate,ip$mean_estimate,
                         tolerance=1e-12)
  testthat::expect_equal(h$contrast_estimate,ip$contrast_estimate,
                         tolerance=1e-12)
})

testthat::test_that("MCAR participant inclusion is at-least-one-trial rule",{
  x <- et_obs_generate_complete(12L,710101L)
  z <- et_obs_observed_only(x,et_obs_make_mask(x,"mcar_gaze",710102L))
  q <- et_obs_public_participant_inclusion(z,.25,"x")
  testthat::expect_equal(unique(q),1-(1-.60)^3,tolerance=1e-12)
  h <- et_obs_participant_hajek(z)
  testthat::expect_true(is.matrix(h$mean_estimate))
  testthat::expect_true(all(h$observed_group0>=0))
})

testthat::test_that("MAR gaze q matches public design at varying time/Z",{
  x <- et_obs_generate_complete(12L,710201L)
  z <- et_obs_observed_only(x,et_obs_make_mask(x,"mar_gaze",710202L))
  t <- .25
  prob <- pmax(.05,pmin(.95,stats::plogis(
    stats::qlogis(.6)+.65*z$registry$Z+
      .50*cos(2*base::pi*t)+.12)))
  expected <- 1-(1-prob)^3
  testthat::expect_equal(
    et_obs_public_participant_inclusion(z,t,"y"),
    expected,tolerance=1e-12)
})

testthat::test_that("MAR dropout uses once-per-participant selection",{
  x <- et_obs_generate_complete(24L,710301L)
  mask <- et_obs_make_mask(x,"mar_dropout",710302L)
  z <- et_obs_observed_only(x,mask)
  testthat::expect_equal(
    et_obs_public_participant_inclusion(z,.25,"x"),
    as.numeric(mask$selection_probability),tolerance=1e-12)
  h <- et_obs_participant_hajek(z)
  testthat::expect_identical(h$status,
    if(all(h$support)) "success" else "no_observation_support")
})

testthat::test_that("missing gaze cannot leak unobserved Y into estimates",{
  x <- et_obs_generate_complete(12L,710401L)
  mask <- et_obs_make_mask(x,"mar_gaze",710402L)
  a <- et_obs_observed_only(x,mask)
  xa <- x
  xa$values[!mask$keep] <- 77777
  b <- et_obs_observed_only(xa,mask)
  ha <- et_obs_participant_hajek(a)
  hb <- et_obs_participant_hajek(b)
  testthat::expect_equal(ha$mean_estimate,hb$mean_estimate)
  testthat::expect_equal(ha$contrast_estimate,hb$contrast_estimate)
})

testthat::test_that("MNAR and unequal sampling are not silently 'corrected'",{
  x <- et_obs_generate_complete(12L,710501L)
  for (mechanism in c("mnar_gaze","mnar_dropout",
                      "unequal_density","sparse_asynchronous")) {
    ob <- et_obs_observed_only(
      x,et_obs_make_mask(x,mechanism,710502L))
    testthat::expect_error(et_obs_participant_hajek(ob),
                           "Unknown/unsupported mechanism")
  }
})

testthat::test_that("zero observed samples produce missing estimates",{
  x <- et_obs_generate_complete(12L,710601L)
  mask <- et_obs_make_mask(x,"mcar_gaze",710602L)
  mask$keep[] <- FALSE
  z <- et_obs_observed_only(x,mask)
  h <- et_obs_participant_hajek(z)
  testthat::expect_identical(h$status,"no_observation_support")
  testthat::expect_equal(h$fraction_supported,0)
  testthat::expect_true(all(is.na(h$mean_estimate)))
  testthat::expect_true(all(is.na(h$contrast_estimate)))
  testthat::expect_equal(h$undefined_coordinates,82)
})
