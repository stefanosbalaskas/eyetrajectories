# Independent Gaussian covariance reconstruction for joint nested random slope.
# Baseline: Batch38 b8a5b4f -> 8d17c18, complete qualifications passed.

.etr_batch39_data <- function(time,family="iid") {
  set.seed(switch(family,iid=39001L,ar1=39002L,exponential=39003L))
  ng <- 24L;m <- 3L;nc <- ng*m;nt <- length(time)
  ids <- sprintf("ns%03d",seq_len(nc))
  pid <- rep(sprintf("P%02d",seq_len(ng)),each=m)
  trials <- rep(sprintf("T%02d",seq_len(m)),ng)
  slope <- rep(c(-1,0,1),ng)
  q <- (time-time[1L])/(tail(time,1L)-time[1L])
  y <- array(NA_real_,c(nc,nt,1L))
  for (g in seq_len(ng)) {
    u <- rnorm(4L)
    # Four participant spline coefficients with intercept-slope covariance.
    pb <- c(.35*u[1L],.22*u[2L]+.07*u[1L],
      .17*u[3L]+.04*u[1L],.15*u[4L]-.03*u[2L])
    for (j in seq_len(m)) {
      i <- (g-1L)*m+j
      v <- rnorm(2L)
      trialcoef <- c(.13*v[1L],.12*v[2L]+.02*v[1L])
      eps <- rnorm(nt,sd=.10)
      if (family!="iid") for (k in 2:nt) {
        a <- if(family=="ar1") .35 else exp(-(time[k]-time[k-1L])/.30)
        eps[k] <- a*eps[k-1L]+sqrt(1-a^2)*eps[k]
      }
      y[i,,1L] <- .4+.10*q+slope[i]*(.3-.12*q)+
        pb[1L]*(1-q)+pb[2L]*q+
        slope[i]*(pb[3L]*(1-q)+pb[4L]*q)+
        trialcoef[1L]*(1-q)+trialcoef[2L]*q+eps
    }
  }
  ts <- etr_trajectory_set(time,y,curve_ids=ids,
    dimension_names="signal",metadata=data.frame(pid=pid,trial=trials),
    coordinate_system="degrees",time_unit="seconds")
  list(trajectories=ts,design=data.frame(
    curve_id=rev(ids),predictor=rev(slope)))
}

.etr_batch39_check <- function(fit) {
  expect_s3_class(fit,"etr_joint_bspline_mixed_nested_slope")
  expect_false(fit$source_python_full_parity)
  expect_equal(unname(fit$fitted_functions+fit$residual_functions),
    unname(fit$observed_functions),tolerance=1e-9)
  nr <- ncol(fit$random_basis);ntr <- ncol(fit$trial_random_basis)
  expect_equal(dim(fit$random_effect_covariance),c(2L*nr,2L*nr))
  expect_equal(dim(fit$trial_random_effect_covariance),c(ntr,ntr))
  expect_equal(dim(fit$intercept_slope_covariance),c(nr,nr))
  expect_true(all(is.finite(fit$fixed_standard_errors)))
  expect_true(all(fit$fixed_standard_errors>=0))
  expect_equal(nrow(etr_joint_bspline_mixed_coefficient_frame(fit)),
    length(fit$predictor_names)*fit$n_time)
  X <- fit$fixed_long_design; Zp <- fit$random_long_design
  Zt <- fit$trial_random_long_design
  y <- as.vector(t(fit$observed_functions))
  nt <- fit$n_time;P <- ncol(X)
  H <- matrix(0,P,P); rhs <- numeric(P)
  for (g in seq_along(fit$participant_ids)) {
    ci <- which(fit$curve_participant_ids==fit$participant_ids[g])
    rows <- unlist(lapply(ci,function(i) (i-1L)*nt+seq_len(nt)),
      use.names=FALSE)
    Zg <- Zp[rows,,drop=FALSE]
    V <- Zg%*%fit$random_effect_covariance%*%t(Zg)
    for (h in seq_along(ci)) {
      rr <- (h-1L)*nt+seq_len(nt)
      Zth <- Zt[(ci[h]-1L)*nt+seq_len(nt),,drop=FALSE]
      V[rr,rr] <- V[rr,rr]+Zth%*%fit$trial_random_effect_covariance%*%
        t(Zth)+fit$residual_variance*fit$residual_correlation_matrix
    }
    expect_true(min(eigen(V,symmetric=TRUE,
      only.values=TRUE)$values)>0)
    Xg <- X[rows,,drop=FALSE]
    H <- H+crossprod(Xg,solve(V,Xg))
    rhs <- rhs+as.vector(crossprod(Xg,solve(V,y[rows])))
    # Direct independent conditional normal equations at both random levels.
    beta <- as.vector(t(fit$fixed_basis_coefficients))
    w <- solve(V,y[rows]-as.vector(Xg%*%beta))
    b_part <- as.vector(fit$random_effect_covariance%*%crossprod(Zg,w))
    expect_lt(max(abs(b_part-as.numeric(
      fit$participant_random_effect_coefficients[g,]))),1e-5)
    for (h in seq_along(ci)) {
      rr <- (h-1L)*nt+seq_len(nt)
      Zth <- Zt[(ci[h]-1L)*nt+seq_len(nt),,drop=FALSE]
      b_trial <- as.vector(fit$trial_random_effect_covariance%*%
        crossprod(Zth,w[rr]))
      expect_lt(max(abs(b_trial-as.numeric(
        fit$trial_random_effect_coefficients[ci[h],]))),1e-5)
    }
  }
  gls <- as.vector(solve(H,rhs))
  expect_lt(max(abs(gls-as.vector(t(fit$fixed_basis_coefficients)))),5e-3)
  expect_lt(max(abs(unname(solve(H))-
    unname(fit$fixed_parameter_covariance))),5e-3)
}

test_that("joint nested-slope iid random covariances solve independent GLS", {
  skip_if_not_installed("nlme")
  d <- .etr_batch39_data(seq(0,1,length.out=8L))
  fit <- etr_fit_joint_bspline_functional_nested_slope(
    d$trajectories,d$design,"predictor","pid","trial","signal",
    "predictor",residual_correlation="iid",fixed_basis_size=2L,
    random_basis_size=2L,trial_random_basis_size=2L,spline_degree=1L)
  expect_identical(fit$residual_correlation,"iid")
  expect_equal(unname(fit$residual_correlation_matrix),diag(8L))
  .etr_batch39_check(fit)
})

test_that("participant random slopes and trial AR1 covariance coexist", {
  skip_if_not_installed("nlme")
  d <- .etr_batch39_data(seq(0,1,length.out=8L),"ar1")
  fit <- etr_fit_joint_bspline_functional_nested_slope(
    d$trajectories,d$design,"predictor","pid","trial","signal",
    "predictor",residual_correlation="ar1",fixed_basis_size=2L,
    random_basis_size=2L,trial_random_basis_size=2L,spline_degree=1L)
  rho <- fit$residual_correlation_parameter
  expect_true(is.finite(rho) && abs(rho)<1)
  expect_equal(unname(fit$residual_correlation_matrix),
    rho^abs(outer(1:8,1:8,"-")),tolerance=1e-12)
  .etr_batch39_check(fit)
})

test_that("nested-slope exponential covariance is physical-time within trial", {
  skip_if_not_installed("nlme")
  time <- c(0,.03,.10,.22,.39,.60,.88,1.25)
  d <- .etr_batch39_data(time,"exponential")
  fit <- etr_fit_joint_bspline_functional_nested_slope(
    d$trajectories,d$design,"predictor","pid","trial","signal",
    "predictor",residual_correlation="exponential",fixed_basis_size=2L,
    random_basis_size=2L,trial_random_basis_size=2L,spline_degree=1L)
  phi <- fit$residual_correlation_parameter
  expect_true(is.finite(phi) && phi>0)
  expect_equal(unname(fit$residual_correlation_matrix),
    exp(-abs(outer(time,time,"-"))/phi),tolerance=1e-12)
  .etr_batch39_check(fit)
})

test_that("nested slope validation rejects trial duplication and invalid slope", {
  d <- .etr_batch39_data(seq(0,1,length.out=8L))
  bad <- d$trajectories
  bad$metadata$trial[2L] <- bad$metadata$trial[1L]
  expect_error(etr_fit_joint_bspline_functional_nested_slope(
    bad,d$design,"predictor","pid","trial","signal","predictor",
    fixed_basis_size=2L,random_basis_size=2L,
    trial_random_basis_size=2L,spline_degree=1L),"unique within")
  flat <- d$design
  flat$predictor <- rep(rep(c(1,1,1),24L),1L)
  expect_error(etr_fit_joint_bspline_functional_nested_slope(
    d$trajectories,flat,"predictor","pid","trial","signal","predictor",
    fixed_basis_size=2L,random_basis_size=2L,
    trial_random_basis_size=2L,spline_degree=1L),
    "random_slope_predictor|rank deficient")
  irregular <- .etr_batch39_data(c(0,.03,.10,.22,.39,.60,.88,1.25))
  expect_error(etr_fit_joint_bspline_functional_nested_slope(
    irregular$trajectories,irregular$design,"predictor","pid","trial",
    "signal","predictor",residual_correlation="ar1",fixed_basis_size=2L,
    random_basis_size=2L,trial_random_basis_size=2L,spline_degree=1L),
    "equally spaced")
})
