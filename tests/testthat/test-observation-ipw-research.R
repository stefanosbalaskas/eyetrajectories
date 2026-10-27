# Research-only test coverage for design-known missingness point diagnostics.
fx <- file.path("scripts","observation_process_fixture.R")
ipw <- file.path("scripts","observation_ipw_research.R")
if (!file.exists(fx)) {
  fx <- file.path("..","..","scripts","observation_process_fixture.R")
  ipw <- file.path("..","..","scripts","observation_ipw_research.R")
}
source(fx,local=TRUE)
source(ipw,local=TRUE)

testthat::test_that("complete-data HT equals participant-balanced naive and oracle",{
  latent <- et_obs_generate_complete(12L,420101L)
  mask <- et_obs_make_mask(latent,"complete",420102L)
  ob <- et_obs_observed_only(latent,mask)
  s <- et_obs_ipw_point_diagnostics(ob,latent$truth_mean,
                                     latent$truth_contrast)
  naive <- et_obs_naive_diagnostic(ob,latent$truth_mean,
                                   latent$truth_contrast)
  testthat::expect_identical(s$status,"success")
  testthat::expect_equal(s$mean_estimate,naive$mean_estimate,
                         tolerance=1e-12)
  testthat::expect_equal(s$contrast_estimate,naive$contrast_estimate,
                         tolerance=1e-12)
  testthat::expect_equal(s$mean_coordinate_support,1)
  testthat::expect_equal(s$max_observed_ipw,1)
})

testthat::test_that("MCAR probability is constant and HT uses eligible N x J",{
  x <- et_obs_generate_complete(12L,420201L)
  mask <- et_obs_make_mask(x,"mcar_gaze",420202L,severity="moderate")
  ob <- et_obs_observed_only(x,mask)
  p <- et_obs_public_retention_probability(ob,"moderate")
  testthat::expect_true(length(p)==nrow(ob$samples))
  testthat::expect_equal(unique(p),.6)
  result <- et_obs_ipw_point_diagnostics(ob,x$truth_mean,
                                         x$truth_contrast)
  subset <- ob$samples[ob$samples$time_index==1L &
                         ob$samples$channel=="x",,drop=FALSE]
  actual <- sum(subset$Y/.6)/(12*3)
  testthat::expect_equal(result$mean_estimate[1L,1L],actual)
  testthat::expect_true(is.finite(result$ht_mean_signed_all_grid))
})

testthat::test_that("MAR cosine uses mathematical pi, not a local probability vector",{
  synthetic <- list(
    mechanism="mar_gaze",
    registry=data.frame(participant=1L,group=0L,Z=0),
    samples=data.frame(participant=c(1L,1L,1L),trial=c(1L,1L,1L),
      time_index=1:3,channel=c("x","x","y"),
      time=c(0,.25,.5),Y=c(.2,.1,-.2),group=0L,Z=0))
  expected <- stats::plogis(stats::qlogis(.6)+
                             c(.5,0,-.5+.12))
  testthat::expect_equal(
    et_obs_public_retention_probability(synthetic,"moderate"),
    expected,tolerance=1e-12)
})

testthat::test_that("MAR gaze probabilities use observed Z time channel only",{
  x <- et_obs_generate_complete(12L,420301L)
  mask <- et_obs_make_mask(x,"mar_gaze",420302L)
  ob <- et_obs_observed_only(x,mask)
  p <- et_obs_public_retention_probability(ob)
  observed_idx <- ob$samples
  ch <- match(observed_idx$channel,c("x","y"))
  archived <- mask$point_probability[cbind(
    observed_idx$participant,observed_idx$trial,
    observed_idx$time_index,ch)]
  testthat::expect_equal(p,as.numeric(archived),tolerance=1e-12)
  # Changing the sealed, UNobserved truth cannot change this estimator:
  # only the observed object is ever passed to the weighting function.
  latent_altered <- x
  latent_altered$values[!mask$keep] <- 999999
  ob2 <- et_obs_observed_only(latent_altered,mask)
  testthat::expect_identical(ob$samples$Y,ob2$samples$Y)
  testthat::expect_equal(et_obs_public_retention_probability(ob2),p)
  a <- et_obs_ipw_point_diagnostics(ob,x$truth_mean,x$truth_contrast)
  b <- et_obs_ipw_point_diagnostics(ob2,x$truth_mean,x$truth_contrast)
  testthat::expect_equal(a$mean_estimate,b$mean_estimate)
  testthat::expect_equal(a$contrast_estimate,b$contrast_estimate)
})

testthat::test_that("MAR dropout uses known participant inclusion probabilities",{
  x <- et_obs_generate_complete(24L,420401L)
  mask <- et_obs_make_mask(x,"mar_dropout",420402L,"moderate")
  ob <- et_obs_observed_only(x,mask)
  p <- et_obs_public_retention_probability(ob,"moderate")
  testthat::expect_equal(p,
    as.numeric(mask$selection_probability[ob$samples$participant]),
    tolerance=1e-12)
  testthat::expect_true(all(ob$samples$participant %in%
                            which(mask$selected)))
  result <- et_obs_ipw_point_diagnostics(ob,x$truth_mean,
                                         x$truth_contrast)
  testthat::expect_true(is.finite(result$ht_contrast_rmse_all_grid))
})

testthat::test_that("MNAR and sparse masks are intentionally not valid IPW inputs",{
  x <- et_obs_generate_complete(12L,420501L)
  for (method in c("mnar_gaze","mnar_dropout",
                   "unequal_density","sparse_asynchronous")) {
    mask <- et_obs_make_mask(x,method,420502L)
    ob <- et_obs_observed_only(x,mask)
    testthat::expect_error(et_obs_public_retention_probability(ob),
                           "Unsupported mechanism")
    testthat::expect_error(
      et_obs_ipw_point_diagnostics(ob,x$truth_mean,x$truth_contrast),
      "Unsupported mechanism")
  }
})

testthat::test_that("unsupported sparse cells are not silently called successful",{
  x <- et_obs_generate_complete(12L,420601L,n_trials=2L)
  mask <- et_obs_make_mask(x,"mcar_gaze",420602L)
  mask$keep[] <- FALSE
  ob <- et_obs_observed_only(x,mask)
  result <- et_obs_ipw_point_diagnostics(ob,x$truth_mean,x$truth_contrast)
  testthat::expect_identical(result$status,"no_observation_support")
  testthat::expect_equal(result$mean_coordinate_support,0)
  testthat::expect_true(is.na(result$naive_mean_rmse_supported))
  testthat::expect_equal(result$mean_estimate,
                         matrix(0,nrow=41L,ncol=2L))
  testthat::expect_true(is.finite(result$ht_mean_rmse_all_grid))
})
