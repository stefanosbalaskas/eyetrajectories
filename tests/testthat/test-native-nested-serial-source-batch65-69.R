# Independent Gaussian covariance reconstruction for joint nested random slope.
# Baseline: Batch38 b8a5b4f -> 8d17c18, complete qualifications passed.

.etr_batch65_data <- function(time,family="iid") {
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

# Source-residual diagnostic contracts; frozen Python nested source 1.2.0.
test_that("source residual IID, AR1 and exponential use physical-time kernels", {
  t <- seq(0,1,length.out=8L)
  r <- matrix(seq(-.4,.4,length.out=16L),2L,8L)
  iid <- .etr_nested_source_residual_contract(t,"iid",NA_real_,diag(8L),r,.16,"seconds")
  expect_equal(iid$residual_correlation_eigenvalues,rep(1,8L))
  expect_identical(iid$residual_correlation_condition_number,1)
  expect_false(iid$residual_correlation_boundary_fit)
  expect_false(iid$residual_correlation_independence_limit_fit)
  expect_true(iid$residual_correlation_grid_regular)
  expect_null(iid$residual_correlation_optimizer_bounds)
  expect_equal(unname(iid$whitened_residual_functions),unname(r/.4),tolerance=1e-12)
  rho <- -.35
  C <- rho^abs(outer(seq_len(8),seq_len(8),"-"))
  ar <- .etr_nested_source_residual_contract(t,"ar1",rho,C,r,.16,"seconds")
  expect_equal(ar$residual_correlation_optimizer_bounds,tanh(c(-7,7)))
  expect_equal(ar$residual_correlation_eigenvalues,
    sort(eigen(C,symmetric=TRUE)$values),tolerance=1e-12)
  expect_identical(ar$residual_correlation_parameter_unit,"dimensionless")
  expect_equal(ar$residual_correlation_grid_interval,1/7,tolerance=1e-12)
  expect_equal(as.vector(t(chol(.16*C))%*%t(ar$whitened_residual_functions)),
    as.vector(t(r)),tolerance=1e-12)
  irregular <- c(0,.03,.10,.22,.39,.60,.88,1.25)
  phi <- .21
  E <- exp(-abs(outer(irregular,irregular,"-"))/phi)
  expd <- .etr_nested_source_residual_contract(irregular,"exponential",phi,E,r,.16,"seconds")
  expect_false(expd$residual_correlation_grid_regular)
  expect_true(is.na(expd$residual_correlation_grid_interval))
  expect_equal(expd$residual_correlation_optimizer_bounds,
    c(min(diff(irregular))*1e-4,(tail(irregular,1L)-irregular[1L])*1e4))
  expect_identical(expd$residual_correlation_parameter_unit,"seconds")
})

test_that("residual source flags never regularize source parameter bounds", {
  t <- 0:7
  r <- matrix(0,2,8)
  d <- .etr_nested_source_residual_contract(t,"ar1",tanh(8),
    tanh(8)^abs(outer(1:8,1:8,"-")),r,.1,"seconds")
  expect_true(d$residual_correlation_boundary_fit)
  expect_true(d$residual_correlation_outside_python_optimizer_bounds)
  expect_error(.etr_nested_source_residual_contract(c(0,.2,.9,1),
    "ar1",.3,diag(4),matrix(0,1,4),.1,"seconds"),"regular")
  expect_error(.etr_nested_source_residual_contract(t,"iid",NA_real_,
    diag(8),matrix(NA_real_,1,8),.1,"seconds"),"finite")
})
