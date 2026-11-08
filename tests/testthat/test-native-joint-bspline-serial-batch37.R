# Scientific native R tests for joint B-spline participant random effects
# plus explicitly modeled within-curve serial residual covariance.

.etr_batch37_data <- function(time, family) {
  set.seed(if (family == "ar1") 37001L else 37002L)
  ng <- 18L
  n_each <- 3L
  n <- ng*n_each
  nt <- length(time)
  ids <- sprintf("curve%03d",seq_len(n))
  participants <- rep(sprintf("participant%02d",seq_len(ng)),each=n_each)
  z <- rep(c(-1,0,1),ng)
  Y <- array(NA_real_,c(n,nt,1L))
  for (g in seq_len(ng)) {
    b <- rnorm(2L,sd=.27)
    for (j in seq_len(n_each)) {
      i <- (g-1L)*n_each+j
      u <- rnorm(nt,sd=.12)
      e <- numeric(nt)
      e[1L] <- u[1L]
      for (t in 2:nt) {
        rate <- if (family == "ar1") .45 else exp(-(time[t]-time[t-1L])/.28)
        e[t] <- rate*e[t-1L]+sqrt(1-rate^2)*u[t]
      }
      q <- (time-time[1L])/(time[nt]-time[1L])
      Y[i,,1L] <- .6+.2*q+z[i]*(.4-.1*q) +
        (1-q)*b[1L]+q*b[2L]+e
    }
  }
  tr <- etr_trajectory_set(time,Y,curve_ids=ids,
    dimension_names="x",metadata=data.frame(pid=participants),
    coordinate_system="degrees",time_unit="s")
  list(trajectories=tr,
       design=data.frame(curve_id=rev(ids),condition=rev(z)))
}

.etr_batch37_check_gls <- function(fit) {
  # Independent marginal covariance construction, not a backend call.
  n <- length(fit$observed_functions)
  nr <- ncol(fit$random_long_design)
  G <- fit$random_effect_covariance
  group_id <- rep(fit$curve_participant_ids,each=fit$n_time)
  Z <- matrix(0,n,length(fit$participant_ids)*nr)
  for (g in seq_along(fit$participant_ids)) {
    ii <- which(group_id == fit$participant_ids[g])
    jj <- (g-1L)*nr+seq_len(nr)
    Z[ii,jj] <- fit$random_long_design[ii,,drop=FALSE]
  }
  V <- Z%*%kronecker(diag(length(fit$participant_ids)),G)%*%t(Z)
  for (i in seq_len(fit$n_curves)) {
    ii <- (i-1L)*fit$n_time+seq_len(fit$n_time)
    V[ii,ii] <- V[ii,ii]+fit$residual_variance*fit$residual_correlation_matrix
  }
  X <- fit$fixed_long_design
  y <- as.vector(t(fit$observed_functions))
  information <- crossprod(X,solve(V,X))
  bhat <- as.vector(solve(information,crossprod(X,solve(V,y))))
  expect_lt(max(abs(bhat-as.vector(t(fit$fixed_basis_coefficients)))),3e-3)
  expect_lt(max(abs(unname(solve(information))-
    unname(fit$fixed_parameter_covariance))),3e-3)
  expect_true(all(is.finite(fit$fixed_standard_errors)))
  expect_true(all(fit$fixed_standard_errors>=0))
  expect_equal(unname(fit$fitted_functions+fit$residual_functions),
    unname(fit$observed_functions),tolerance=1e-9)
  expect_equal(dim(fit$random_effect_covariance),c(2L,2L))
  expect_true(min(eigen(G,symmetric=TRUE,only.values=TRUE)$values)>-1e-8)
  report <- etr_joint_bspline_mixed_coefficient_frame(fit)
  expect_equal(nrow(report),2L*fit$n_time)
}

test_that("AR(1) residuals are fitted within source curves with independent GLS identity", {
  skip_if_not_installed("nlme")
  dat <- .etr_batch37_data(seq(0,1,length.out=8L),"ar1")
  fit <- etr_fit_joint_bspline_functional_correlated(dat$trajectories,
    dat$design,"condition","pid","x",residual_correlation="ar1",
    fixed_basis_size=2L,random_basis_size=2L,spline_degree=1L,
    reml=TRUE,maxiter=400L)
  expect_s3_class(fit,"etr_joint_bspline_mixed_correlated")
  expect_false(fit$source_python_full_parity)
  expect_identical(fit$residual_correlation,"ar1")
  rho <- fit$residual_correlation_parameter
  expect_true(is.finite(rho) && abs(rho)<1)
  C <- rho^abs(outer(seq_len(fit$n_time),seq_len(fit$n_time),"-"))
  expect_equal(unname(fit$residual_correlation_matrix),C,tolerance=1e-12)
  .etr_batch37_check_gls(fit)
})

test_that("exponential residuals preserve physical-time distances on irregular grids", {
  skip_if_not_installed("nlme")
  tt <- c(0,.04,.11,.22,.38,.59,.82,1.20)
  dat <- .etr_batch37_data(tt,"exponential")
  fit <- etr_fit_joint_bspline_functional_correlated(dat$trajectories,
    dat$design,"condition","pid","x",residual_correlation="exponential",
    fixed_basis_size=2L,random_basis_size=2L,spline_degree=1L,
    reml=TRUE,maxiter=400L)
  expect_identical(fit$residual_correlation,"exponential")
  phi <- fit$residual_correlation_parameter
  expect_true(is.finite(phi) && phi>0)
  expect_identical(fit$residual_correlation_parameter_units,"s")
  C <- exp(-abs(outer(tt,tt,"-"))/phi)
  expect_equal(unname(fit$residual_correlation_matrix),C,tolerance=1e-12)
  .etr_batch37_check_gls(fit)
})

test_that("source-meaningful correlation domains are fail-closed", {
  time <- c(0,.1,.23,.5,.9)
  dat <- .etr_batch37_data(time,"exponential")
  expect_error(etr_fit_joint_bspline_functional_correlated(dat$trajectories,
    dat$design,"condition","pid","x",residual_correlation="ar1",
    fixed_basis_size=2L,random_basis_size=2L,spline_degree=1L),
    "equally spaced")
  expect_error(etr_fit_joint_bspline_functional_correlated(dat$trajectories,
    dat$design,"condition","pid","x",residual_correlation="matern",
    fixed_basis_size=2L,random_basis_size=2L,spline_degree=1L),
    "residual_correlation")
  expect_error(.etr_joint_serial_correlation_matrix(1:5,"ar1",1.01),
    "rho")
  expect_error(.etr_joint_serial_correlation_matrix(1:5,"exponential",0),
    "phi")
})
