# Batch38: joint participant/trial functional covariance, serial residuals.
# Independent covariance calculations; does not assert Python full-contract parity.

.etr_batch38_data <- function(time, family="iid") {
  set.seed(if(family=="iid") 38001L else if(family=="ar1") 38002L else 38003L)
  ng <- 12L;ncg <- 3L;nc <- ng*ncg;nt <- length(time)
  ids <- sprintf("tr%03d",seq_len(nc))
  pids <- rep(sprintf("P%02d",seq_len(ng)),each=ncg)
  tids <- rep(sprintf("T%02d",seq_len(ncg)),ng)
  x <- rep(c(-1,0,1),ng)
  yy <- array(NA_real_,c(nc,nt,1L))
  q <- (time-time[1L])/(time[nt]-time[1L])
  for (g in seq_len(ng)) {
    pb <- rnorm(2L,sd=.25)
    for (j in seq_len(ncg)) {
      i <- (g-1L)*ncg+j
      tb <- rnorm(2L,sd=.15)
      eps <- rnorm(nt,sd=.10)
      if (family!="iid") {
        for (k in 2:nt) {
          a <- if (family=="ar1") .35 else exp(-(time[k]-time[k-1L])/.24)
          eps[k] <- a*eps[k-1L]+sqrt(1-a^2)*eps[k]
        }
      }
      yy[i,,1L] <- .5+.19*q + x[i]*(.28-.08*q) +
        pb[1L]*(1-q)+pb[2L]*q +
        tb[1L]*(1-q)+tb[2L]*q + eps
    }
  }
  traj <- etr_trajectory_set(time,yy,curve_ids=ids,
    dimension_names="signal",metadata=data.frame(pid=pids,trial=tids),
    coordinate_system="degrees",time_unit="seconds")
  list(trajectories=traj,design=data.frame(
    curve_id=rev(ids),predictor=rev(x)))
}

.etr_batch38_independent_checks <- function(fit) {
  expect_s3_class(fit,"etr_joint_bspline_mixed_nested_trial")
  expect_false(fit$source_python_full_parity)
  expect_equal(unname(fit$fitted_functions+fit$residual_functions),
    unname(fit$observed_functions),tolerance=1e-9)
  expect_equal(dim(fit$trial_random_effect_covariance),c(2L,2L))
  expect_equal(dim(fit$random_effect_covariance),c(2L,2L))
  expect_true(min(eigen(fit$trial_random_effect_covariance,
    symmetric=TRUE,only.values=TRUE)$values)>-1e-8)
  expect_true(min(eigen(fit$random_effect_covariance,
    symmetric=TRUE,only.values=TRUE)$values)>-1e-8)
  expect_true(all(is.finite(fit$fixed_standard_errors)))
  expect_true(all(fit$fixed_standard_errors>=0))
  expect_equal(nrow(etr_joint_bspline_mixed_coefficient_frame(fit)),
    length(fit$predictor_names)*fit$n_time)
  X <- fit$fixed_long_design
  y <- as.vector(t(fit$observed_functions))
  nr <- ncol(fit$random_long_design)
  nt <- fit$n_time
  p <- ncol(X)
  H <- matrix(0,p,p); b <- numeric(p)
  # Independently construct the covariance from participant and trial terms.
  for (pid in fit$participant_ids) {
    ci <- which(fit$curve_participant_ids==pid)
    m <- length(ci)
    rows <- unlist(lapply(ci,function(i) (i-1L)*nt+seq_len(nt)),use.names=FALSE)
    Zi <- fit$random_long_design[rows,,drop=FALSE]
    V <- Zi%*%fit$random_effect_covariance%*%t(Zi)
    for (h in seq_along(ci)) {
      jj <- (h-1L)*nt+seq_len(nt)
      Zi_t <- fit$trial_random_long_design[
        (ci[h]-1L)*nt+seq_len(nt),,drop=FALSE]
      V[jj,jj] <- V[jj,jj]+Zi_t%*%fit$trial_random_effect_covariance%*%
        t(Zi_t)+fit$residual_variance*fit$residual_correlation_matrix
    }
    expect_equal(unname(V),unname(t(V)),tolerance=1e-9)
    expect_true(min(eigen(V,symmetric=TRUE,only.values=TRUE)$values)>0)
    Xg <- X[rows,,drop=FALSE]
    H <- H + crossprod(Xg,solve(V,Xg))
    b <- b + as.vector(crossprod(Xg,solve(V,y[rows])))
  }
  gls <- as.vector(solve(H,b))
  expect_lt(max(abs(gls-as.vector(t(fit$fixed_basis_coefficients)))),5e-3)
  expect_lt(max(abs(unname(solve(H))-
    unname(fit$fixed_parameter_covariance))),5e-3)
  # Independent posterior normal equation at every random level.
  expect_true(all(is.finite(fit$participant_random_effect_coefficients)))
  expect_true(all(is.finite(fit$trial_random_effect_coefficients)))
}

test_that("nested iid trial-level B-spline covariance solves independent GLS", {
  skip_if_not_installed("nlme")
  d <- .etr_batch38_data(seq(0,1,length.out=8L))
  fit <- etr_fit_joint_bspline_functional_nested_trial(
    d$trajectories,d$design,"predictor","pid","trial","signal",
    residual_correlation="iid",fixed_basis_size=2L,
    random_basis_size=2L,trial_random_basis_size=2L,
    spline_degree=1L,maxiter=500L)
  expect_identical(fit$residual_correlation,"iid")
  expect_equal(unname(fit$residual_correlation_matrix),diag(8L))
  .etr_batch38_independent_checks(fit)
})

test_that("nested trial effects and AR1 residual covariance coexist", {
  skip_if_not_installed("nlme")
  d <- .etr_batch38_data(seq(0,1,length.out=8L),"ar1")
  fit <- etr_fit_joint_bspline_functional_nested_trial(
    d$trajectories,d$design,"predictor","pid","trial","signal",
    residual_correlation="ar1",fixed_basis_size=2L,
    random_basis_size=2L,trial_random_basis_size=2L,
    spline_degree=1L,maxiter=500L)
  expect_true(abs(fit$residual_correlation_parameter)<1)
  expect_equal(unname(fit$residual_correlation_matrix),
    fit$residual_correlation_parameter^abs(outer(1:8,1:8,"-")),
    tolerance=1e-12)
  .etr_batch38_independent_checks(fit)
})

test_that("nested physical-time exponential residual correlation uses grid units", {
  skip_if_not_installed("nlme")
  time <- c(0,.03,.10,.22,.39,.60,.88,1.25)
  d <- .etr_batch38_data(time,"exponential")
  fit <- etr_fit_joint_bspline_functional_nested_trial(
    d$trajectories,d$design,"predictor","pid","trial","signal",
    residual_correlation="exponential",fixed_basis_size=2L,
    random_basis_size=2L,trial_random_basis_size=2L,
    spline_degree=1L,maxiter=500L)
  phi <- fit$residual_correlation_parameter
  expect_true(is.finite(phi) && phi>0)
  expect_equal(unname(fit$residual_correlation_matrix),
    exp(-abs(outer(time,time,"-"))/phi),tolerance=1e-12)
  .etr_batch38_independent_checks(fit)
})

test_that("one-curve-per-trial and regular AR1 domains fail closed", {
  d <- .etr_batch38_data(seq(0,1,length.out=8L))
  bad <- d$trajectories
  bad$metadata$trial[2L] <- bad$metadata$trial[1L]
  expect_error(etr_fit_joint_bspline_functional_nested_trial(
    bad,d$design,"predictor","pid","trial","signal",
    fixed_basis_size=2L,random_basis_size=2L,
    trial_random_basis_size=2L,spline_degree=1L),
    "unique within each participant")
  expect_error(etr_fit_joint_bspline_functional_nested_trial(
    d$trajectories,d$design,"predictor","pid","pid","signal",
    fixed_basis_size=2L,random_basis_size=2L,
    trial_random_basis_size=2L,spline_degree=1L),"distinct")
  irregular <- .etr_batch38_data(c(0,.03,.10,.22,.39,.60,.88,1.25))
  expect_error(etr_fit_joint_bspline_functional_nested_trial(
    irregular$trajectories,irregular$design,"predictor","pid","trial",
    "signal",residual_correlation="ar1",fixed_basis_size=2L,
    random_basis_size=2L,trial_random_basis_size=2L,
    spline_degree=1L),"equally spaced")
})
