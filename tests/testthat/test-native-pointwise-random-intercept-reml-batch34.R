# No Python bridge is used by these R scientific tests.
.etr_reml34_fixture <- function() {
  tt <- seq(0,1,length.out=7L)
  n <- 18L
  ids <- paste0("c",seq_len(n))
  participant <- rep(paste0("G",seq_len(6L)),each=3L)
  predictor <- rep(c(-1,0,1),6L)
  b <- rep(c(-1.0,.55,1.25,-.7,.2,.75),each=3L)
  val <- array(0,c(n,length(tt),1L))
  for(j in seq_along(tt)) {
    i <- seq_len(n)
    val[,j,1L] <- .5+.3*tt[j] + (1.2-.2*tt[j])*predictor +
      (1+.15*tt[j])*b + .16*sin(i*1.14+j*.45) +
      .09*cos(i*.32-j*.2)
  }
  list(x=etr_trajectory_set(tt,val,curve_ids=ids,
        dimension_names="gaze",metadata=data.frame(
          participant=participant,stringsAsFactors=FALSE)),
       design=data.frame(curve_id=ids,x=predictor),
       participant=participant)
}

test_that("pointwise REML fits an identified participant random intercept", {
  dat <- .etr_reml34_fixture()
  fit <- etr_fit_functional_random_intercept_reml(dat$x,
    dimension="gaze",participant_column="participant",
    design=dat$design,predictors="x")
  expect_s3_class(fit,"etr_functional_random_intercept_reml")
  expect_identical(dim(fit$fixed_coefficients),c(2L,7L))
  expect_identical(dim(fit$random_intercepts),c(6L,7L))
  expect_identical(dim(fit$fitted),c(18L,7L))
  expect_identical(fit$participant_ids,paste0("G",seq_len(6L)))
  expect_true(all(is.finite(fit$fixed_coefficients)))
  expect_true(all(is.finite(fit$fixed_se)))
  expect_true(all(fit$residual_variance>0))
  expect_true(all(fit$random_intercept_variance>=0))
  expect_true(all(fit$intraclass_correlation>=0 &
                  fit$intraclass_correlation<1))
  expect_true(all(abs(fit$fixed_coefficients["x",]-
                    (1.2-.2*dat$x$time))<.25))
  expect_true(all(abs(fit$fitted+fit$residuals-
                   matrix(dat$x$values[,,1L],18L,7L))<1e-9))
  frame <- etr_functional_random_intercept_reml_frame(fit)
  expect_equal(nrow(frame),14L)
  expect_identical(names(frame),c("term","time","estimate",
    "pointwise_se","lower","upper","confidence_level"))
  expect_true(all(frame$lower<=frame$estimate &
                  frame$upper>=frame$estimate))
  expect_true(isFALSE(fit$provenance$scientific_python_joint_bspline_equivalence))
  # Frozen, independently optimized SciPy dense-REML reference values.
  expect_equal(as.numeric(fit$fixed_coefficients[,1L]),
    c(.67897239495,1.19412459724),tolerance=1e-4)
  expect_equal(fit$residual_variance[1L],.01873301566,tolerance=1e-4)
  expect_equal(fit$random_intercept_variance[1L],
    .71384279180,tolerance=1e-3)
})

test_that("low rank REML agrees with independent dense Gaussian likelihood", {
  dat <- .etr_reml34_fixture()
  fit <- etr_fit_functional_random_intercept_reml(dat$x,
    dimension="gaze",participant_column="participant",
    design=dat$design,predictors="x")
  X <- cbind(Intercept=1, x=dat$design$x)
  group_index <- match(dat$participant,unique(dat$participant))
  Z <- matrix(0,nrow(X),6L)
  Z[cbind(seq_len(nrow(X)),group_index)] <- 1
  for(j in seq_len(7L)) {
    lambda <- fit$variance_ratio[j]
    Y <- dat$x$values[,j,1L]
    W <- diag(18L) + lambda * tcrossprod(Z)
    W_inv <- solve(W)
    information <- crossprod(X,W_inv%*%X)
    coef <- solve(information,crossprod(X,W_inv%*%Y))
    r <- as.numeric(Y-X%*%coef)
    sigma2 <- as.numeric(crossprod(r,W_inv%*%r))/(18L-ncol(X))
    expect_equal(as.numeric(fit$fixed_coefficients[,j]),
                 as.numeric(coef),tolerance=1e-6)
    expect_equal(fit$residual_variance[j],sigma2,tolerance=1e-6)
    expect_equal(fit$random_intercept_variance[j],
                 lambda*sigma2,tolerance=1e-6)
    expect_equal(as.numeric(fit$fixed_se[,j]),
                 as.numeric(sqrt(diag(solve(information))*sigma2)),tolerance=1e-6)
    group_residual <- as.numeric(crossprod(Z,r))
    blup <- lambda/(1+3*lambda)*group_residual
    expect_equal(as.numeric(fit$random_intercepts[,j]),
                 blup,tolerance=1e-6)
  }
})

test_that("invalid scientific inputs fail explicitly", {
  dat <- .etr_reml34_fixture()
  run <- function(...) etr_fit_functional_random_intercept_reml(
    dat$x, dimension="gaze",participant_column="participant",...)
  expect_error(run(predictors="x"),"design required")
  expect_error(run(design=dat$design,predictors=c("x","x")),"distinct")
  expect_error(run(design=dat$design,predictors="unknown"),"design")
  expect_error(run(lambda_bounds=c(-1,10)),"lambda_bounds")
  expect_error(etr_fit_functional_random_intercept_reml(dat$x,
    dimension="unknown",participant_column="participant"),"dimension")
  expect_error(etr_fit_functional_random_intercept_reml(dat$x,
    dimension="gaze",participant_column="missing"),"participant_column")
  bad <- dat$x
  bad$metadata$participant <- rep("only_one_group",18L)
  expect_error(etr_fit_functional_random_intercept_reml(bad,
    dimension="gaze",participant_column="participant"),"three participants")
  fit <- run(design=dat$design,predictors="x")
  expect_error(etr_functional_random_intercept_reml_frame(fit,
    confidence_level=1.5),"confidence_level")
  expect_equal(nrow(etr_functional_random_intercept_reml_frame(fit,
    confidence_level=.9)),14L)
})

test_that("no between-participant signal supports zero random-variance boundary", {
  dat <- .etr_reml34_fixture()
  n <- length(dat$x$curve_ids)
  # Every participant has the same three residual observations at each t.
  # There is independent within-participant variation but no group signal.
  for(j in seq_along(dat$x$time)) {
    dat$x$values[,j,1L] <- rep(c(-1,0,1),6L)+j*.2
  }
  fit <- etr_fit_functional_random_intercept_reml(dat$x,
    dimension="gaze",participant_column="participant")
  expect_true(all(fit$random_intercept_variance<1e-5))
  expect_true(all(fit$intraclass_correlation<1e-5))
  expect_true(all(is.finite(fit$fixed_coefficients)))
  expect_identical(dim(fit$fixed_coefficients),c(1L,7L))
  expect_true(all(fit$residual_variance>0))
})
