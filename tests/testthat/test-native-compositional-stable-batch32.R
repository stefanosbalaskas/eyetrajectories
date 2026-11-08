test_that("stable native inverse ALR preserves simplex and reference placement", {
  set.seed(32)
  z <- array(stats::rnorm(4L*7L*3L),c(4L,7L,3L))
  for(ref in c(-1L,0L,1L,2L,3L)) {
    p <- etr_inverse_alr_stable(z,ref,4L)
    expect_identical(dim(p),c(4L,7L,4L))
    expect_true(all(is.finite(p)))
    expect_true(all(p>=0 & p<=1))
    expect_equal(apply(p,c(1L,2L),sum),
      matrix(1,4L,7L),tolerance=1e-13)
    ri <- (ref %% 4L)+1L
    other <- setdiff(seq_len(4L),ri)
    expect_equal(log(p[,,other[1L]]/p[,,ri]),z[,,1L],
      tolerance=1e-12)
    expect_equal(log(p[,,other[3L]]/p[,,ri]),z[,,3L],
      tolerance=1e-12)
  }
})

test_that("extreme finite ALR scores do not overflow", {
  z <- array(0,c(2L,3L,2L))
  z[1L,1L,] <- c(1000,-1000)
  z[1L,2L,] <- c(-1000,-1000)
  z[1L,3L,] <- c(1000,1000)
  z[2L,1L,] <- c(1e307,-1e307)
  z[2L,2L,] <- c(-1e307,-1e307)
  z[2L,3L,] <- c(0,0)
  p <- etr_inverse_alr_stable(z,reference_dimension=-1L)
  expect_true(all(is.finite(p)))
  expect_equal(apply(p,c(1L,2L),sum),matrix(1,2L,3L),
    tolerance=1e-15)
  expect_equal(as.numeric(p[1L,1L,]),c(1,0,0))
  expect_equal(as.numeric(p[1L,2L,]),c(0,0,1))
  expect_equal(as.numeric(p[1L,3L,]),c(0.5,0.5,0))
  expect_equal(as.numeric(p[2L,3L,]),rep(1/3,3L),
    tolerance=1e-15)
})

test_that("declared nonfinite policy handles +Inf limits, rejects NaN", {
  z <- array(c(Inf,Inf,-Inf,-Inf),c(1L,2L,2L))
  expect_error(etr_inverse_alr_stable(z),"nonfinite")
  p <- etr_inverse_alr_stable(z,infinite_policy="limit")
  expect_equal(sum(p[1L,1L,]),1,tolerance=1e-15)
  expect_equal(sum(p[1L,2L,]),1,tolerance=1e-15)
  expect_true(all(is.finite(p)))
  expect_error(etr_inverse_alr_stable(array(NaN,c(1L,1L,1L))),
    "NA or NaN")
})

test_that("native inverse ALR rejects scientifically malformed inputs", {
  expect_error(etr_inverse_alr_stable(matrix(1,2,2)),"three-dimensional")
  expect_error(etr_inverse_alr_stable(array(1,c(1,2,2)),
    n_dimensions=2L),"incompatible")
  expect_error(etr_inverse_alr_stable(array(1,c(1,2,2)),
    reference_dimension=0.5),"finite integer")
  expect_error(etr_inverse_alr_stable(array(1,c(1,2,2)),
    reference_dimension=NA_real_),"finite integer")
  expect_error(etr_inverse_alr_stable(array(1,c(1,2,2)),
    infinite_policy="silently_allow"),"arg")
})

test_that("stable inverse matches frozen Python 1.2 for finite source domain", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("direct Python oracle is opt-in")
  skip_if_not_installed("reticulate")
  py <- tryCatch(reticulate::import("eyetrajectoriespy",convert=FALSE),
    error=function(e)NULL)
  skip_if(is.null(py),"Python 1.2 package unavailable")
  if(!identical(et_python_version(),"1.2.0"))
    skip("requires frozen eyetrajectoriespy 1.2.0")
  set.seed(320)
  for(k in c(3L,4L)) {
    z <- array(stats::rnorm(5L*4L*(k-1L),sd=2),
      c(5L,4L,k-1L))
    for(ref in c(0L,1L,-1L)) {
      expected <- reticulate::py_to_r(py$inverse_alr(
        reticulate::r_to_py(z),reference_dimension=as.integer(ref),
        n_dimensions=as.integer(k)))
      actual <- etr_inverse_alr_stable(z,ref,k)
      expect_equal(unname(actual),unname(expected),tolerance=2e-13)
    }
  }
})

test_that("stable compositional FPCA reconstruction stays native and finite", {
  time <- seq(0,1,length.out=11L)
  values <- array(0,c(8L,11L,3L))
  for(i in seq_len(8L))for(t in seq_len(11L)) {
    logits <- c(0.15*i+sin(time[t]*2*pi),
      cos(time[t]*2*pi)+0.08*i,0)
    weights <- exp(logits-max(logits))
    values[i,t,] <- weights/sum(weights)
  }
  x <- etr_trajectory_set(time,values,
    curve_ids=paste0("curve",seq_len(8L)),
    dimension_names=c("AOI_A","AOI_B","AOI_C"))
  fit <- etr_fit_compositional_fpca(x,n_components=2L)
  p <- etr_reconstruct_compositional_fpca_stable(fit)
  expect_identical(dim(p),dim(values))
  expect_true(all(is.finite(p)))
  expect_true(all(p>=0 & p<=1))
  expect_equal(apply(p,c(1L,2L),sum),matrix(1,8L,11L),
    tolerance=1e-12)
  expect_equal(p,etr_reconstruct_compositional_fpca(fit),
    tolerance=2e-12)
  expect_error(etr_reconstruct_compositional_fpca_stable(list()),
    "compositional FPCA")
})
