# Stage 4 native R / Python 1.2 complete-contract sequence-distance tests.
# Native tests import no Python; reference tests are opt-in.

test_that("native discrete Frechet coupling follows deterministic diagonal ties",{
  a <- matrix(c(0,1,2),ncol=1)
  b <- matrix(c(.1,1.1,2.1),ncol=1)
  r <- etr_discrete_frechet(a,b,return_coupling=TRUE)
  expect_s3_class(r,"etr_discrete_frechet_result")
  expect_equal(etr_discrete_frechet(a,b),.1,tolerance=1e-12)
  expect_equal(r$distance,.1,tolerance=1e-12)
  expect_identical(r$coupling,cbind(0:2,0:2))
  expect_equal(r$local_distances,rep(.1,3),tolerance=1e-12)
  expect_identical(r$n_points_a,3L)
  expect_identical(r$n_points_b,3L)
  expect_identical(r$n_dimensions,1L)
  expect_identical(r$provenance$tie_break_order,
                   c("diagonal","advance_a","advance_b"))
  expect_false(r$provenance$continuous_frechet)
  expect_equal(max(r$local_distances),r$distance)

  # All costs exactly zero: many optimal paths exist, but Python selects
  # diagonal first, then one vertical step for unequal lengths.
  z <- etr_discrete_frechet(matrix(0,4,1),matrix(0,3,1),
                            return_coupling=TRUE)
  expect_equal(z$distance,0)
  expect_identical(z$coupling,
    matrix(c(0L,0L,1L,0L,2L,1L,3L,2L),ncol=2,byrow=TRUE))
  expect_equal(z$local_distances,rep(0,4))
  expect_equal(etr_discrete_frechet(matrix(1,1,1),
                                   matrix(4,1,1)),3)
})

test_that("native discrete Frechet preserves weighted channel definitions",{
  a <- rbind(c(0,0),c(1,1),c(2,2))
  b <- a+matrix(rep(c(1,2),3),ncol=2,byrow=TRUE)
  raw <- etr_discrete_frechet(a,b,dimension_weights=c(1,0),
                              return_coupling=TRUE)
  expect_equal(raw$distance,1)
  expect_equal(raw$provenance$dimension_weights,c(1,0))
  expect_error(etr_discrete_frechet(a,b,
               dimension_weights=c(0,0)),"positive")
  expect_error(etr_discrete_frechet(a,b,
               dimension_weights=c(-1,2)),"non-negative|nonnegative")
  expect_error(etr_discrete_frechet(a,b,
               dimension_weights=c(1,2,3)),"dimension_weights")
  expect_error(etr_discrete_frechet(a,as.matrix(1:3)),
               "same number of dimensions")
  expect_error(etr_discrete_frechet(a,b,return_coupling=1),
               "TRUE or FALSE")
  incomplete <- a
  incomplete[1L,1L] <- NA_real_
  expect_error(etr_discrete_frechet(incomplete,b),"complete")
})

test_that("native full DTW defaults preserve symmetric1 and exposes symmetric2",{
  a <- matrix(0:2,ncol=1)
  b <- matrix(c(.1,1.1,2.1),ncol=1)
  old <- etr_dtw(a,b)
  one <- etr_dynamic_time_warping(a,b,return_path=TRUE)
  two <- etr_dynamic_time_warping(
    a,b,step_pattern="symmetric2",normalize=TRUE,
    window_radius=0L,return_path=TRUE)
  expect_s3_class(one,"etr_dtw_result")
  expect_s3_class(two,"etr_dtw_result")
  expect_equal(old,.3,tolerance=1e-12)
  expect_equal(one$distance,old)
  expect_identical(one$path,cbind(0:2,0:2))
  expect_equal(one$step_weights,rep(1,3))
  expect_equal(one$raw_distance,.3,tolerance=1e-12)
  expect_null(one$normalized_distance)
  expect_null(one$normalization_denominator)
  expect_equal(two$raw_distance,.6,tolerance=1e-12)
  expect_equal(two$normalized_distance,.1,tolerance=1e-12)
  expect_equal(two$distance,.1,tolerance=1e-12)
  expect_equal(two$step_weights,rep(2,3))
  expect_identical(two$window_radius,0L)
  expect_equal(two$normalization_denominator,6)
  expect_equal(two$path_length,3L)
  expect_equal(two$weighted_local_costs,
               two$local_distances*two$step_weights)
  expect_equal(sum(two$weighted_local_costs),two$raw_distance)
  expect_identical(two$provenance$step_pattern,"symmetric2")
  expect_identical(two$provenance$window_constraint,
                   "sakoe_chiba_index_band")
  expect_false(two$provenance$recorded_time_used)
})

test_that("native DTW window, normalization and missing contracts fail closed",{
  a <- matrix(0:3,ncol=1)
  b <- matrix(0:2,ncol=1)
  expect_equal(etr_dynamic_time_warping(a,b,window_radius=1L),
               etr_dynamic_time_warping(
                 a,b,window_radius=1L,return_path=TRUE)$distance)
  expect_error(etr_dynamic_time_warping(
    a,b,window_radius=0L),"too small")
  expect_error(etr_dynamic_time_warping(
    a,b,window_radius=-1L),"non-negative integer")
  expect_error(etr_dynamic_time_warping(
    a,b,window_radius=TRUE),"non-negative integer")
  expect_error(etr_dynamic_time_warping(
    a,b,window_radius=1.5),"non-negative integer")
  expect_error(etr_dynamic_time_warping(
    a,b,step_pattern="symmetric1",normalize=TRUE),"only for symmetric2")
  expect_error(etr_dynamic_time_warping(
    a,b,step_pattern="wrong"),"step_pattern")
  expect_error(etr_dynamic_time_warping(
    a,b,return_path=1),"TRUE or FALSE")
  expect_error(etr_dynamic_time_warping(
    a,b,normalize=1),"TRUE or FALSE")
  expect_error(etr_dynamic_time_warping(
    a,b,dimension_weights=0),"positive")
  incomplete <- a
  incomplete[2L,1L] <- NA_real_
  expect_error(etr_dynamic_time_warping(incomplete,b),"complete")
})

test_that("native full pairwise DTW keeps subset weights and Python-like matrix",{
  tt <- c(0,.2,.5,1,1.5)
  values <- array(0,dim=c(3L,length(tt),3L))
  values[1L,,1L] <- 1:5
  values[2L,,1L] <- 2:6
  values[3L,,1L] <- 4:8
  values[1L,,2L] <- c(0,1,2,3,4)
  values[2L,,2L] <- c(0,1,3,3,4)
  values[3L,,2L] <- c(1,1,2,4,4)
  values[1L,,3L] <- 100
  values[2L,,3L] <- -100
  x <- etr_trajectory_set(
    tt,values,c("one","two","three"),c("x","y","pupil"))
  result <- etr_pairwise_dtw_full(
    x,dimensions=c("x","y"),dimension_weights=c(1,2),
    window_radius=1L,step_pattern="symmetric2",normalize=TRUE)
  expect_identical(dim(result),c(3L,3L))
  expect_null(dimnames(result))
  expect_equal(result,t(result))
  expect_equal(diag(result),rep(0,3))
  expect_equal(result[1L,2L],
    etr_dynamic_time_warping(
      matrix(values[1L,,1:2],nrow=length(tt)),
      matrix(values[2L,,1:2],nrow=length(tt)),
      dimension_weights=c(1,2),window_radius=1L,
      step_pattern="symmetric2",normalize=TRUE))
  expect_error(etr_pairwise_dtw_full(
    x,dimensions=c("x","x")),"distinct")
  expect_error(etr_pairwise_dtw_full(
    x,dimensions=c("missing")),"Unknown")
  expect_error(etr_pairwise_dtw_full(
    x,dimensions=c("x","y"),dimension_weights=c(0,0)),
    "positive")
  expect_error(etr_pairwise_dtw_full(
    x,normalize=TRUE),"only for symmetric2")
})

test_that("seeded Python 1.2 Fréchet/DTW numeric values and exact paths agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Independent Python 1.2 full-distance numerical oracle is opt-in")
  expect_identical(as.character(et_python_version()),"1.2.0")
  had_seed <- exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE)
  if(had_seed) saved_seed <- get(".Random.seed",envir=.GlobalEnv)
  on.exit({
    if(had_seed) assign(".Random.seed",saved_seed,envir=.GlobalEnv)
    else if(exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE))
      rm(".Random.seed",envir=.GlobalEnv)
  },add=TRUE)
  set.seed(20261027L)

  compare_scalar <- function(actual,py_ref,tag){
    expected <- as.numeric(et_to_r(py_ref))
    expect_equal(as.numeric(actual),expected,tolerance=1e-9,info=tag)
  }
  compare_path <- function(native,python,native_path,tag){
    py_path <- et_to_r(python[[native_path]])
    expect_identical(dim(native[[native_path]]),dim(py_path),
                     info=paste(tag,native_path,"shape"))
    expect_equal(unname(native[[native_path]]),
                 unname(py_path),info=paste(tag,native_path))
    expect_equal(native$distance,as.numeric(et_to_r(python$distance)),
                 tolerance=1e-9,info=paste(tag,"distance"))
    expect_equal(native$local_distances,
                 as.numeric(et_to_r(python$local_distances)),
                 tolerance=1e-9,info=paste(tag,"local costs"))
  }
  for (scenario in seq_len(10L)){
    m <- 3L+(scenario%%5L)
    n <- 2L+(scenario%%6L)
    a <- matrix(stats::rnorm(m*2),nrow=m,ncol=2L)
    b <- matrix(stats::rnorm(n*2),nrow=n,ncol=2L)
    if(scenario%%4L==0L) {
      # Duplicates and equal-cost edges challenge tie selection.
      a[2L,] <- a[1L,]
      b[2L,] <- b[1L,]
    }
    weights <- c(1,(scenario%%3L)+.5)
    pa <- reticulate::r_to_py(a)
    pb <- reticulate::r_to_py(b)
    f_native <- etr_discrete_frechet(
      a,b,weights,return_coupling=TRUE)
    f_python <- etpy_discrete_frechet_distance(
      pa,pb,dimension_weights=weights,return_coupling=TRUE)
    compare_path(f_native,f_python,"coupling",
                 paste("scenario",scenario,"Frechet"))
    compare_scalar(
      etr_discrete_frechet(a,b,weights),
      etpy_discrete_frechet_distance(
        pa,pb,dimension_weights=weights),
      paste("scenario",scenario,"Frechet scalar"))
    for(pattern in c("symmetric1","symmetric2")){
      for(window in list(NULL,as.integer(max(abs(m-n),2L)))){
        for(normalized in if(pattern=="symmetric2")c(FALSE,TRUE) else FALSE){
          tag <- paste("scenario",scenario,"DTW",pattern,
                       "window",if(is.null(window))"none" else window,
                       "normalize",normalized)
          native <- etr_dynamic_time_warping(
            a,b,weights,window,pattern,normalized,return_path=TRUE)
          python <- etpy_dynamic_time_warping_distance(
            pa,pb,dimension_weights=weights,window_radius=window,
            step_pattern=pattern,normalize=normalized,
            return_path=TRUE)
          compare_path(native,python,"path",tag)
          compare_scalar(
            etr_dynamic_time_warping(
              a,b,weights,window,pattern,normalized),
            etpy_dynamic_time_warping_distance(
              pa,pb,dimension_weights=weights,window_radius=window,
              step_pattern=pattern,normalize=normalized),
            paste(tag,"scalar"))
          expect_equal(native$raw_distance,
                       as.numeric(et_to_r(python$raw_distance)),
                       tolerance=1e-9,info=paste(tag,"raw"))
          if(pattern=="symmetric2"){
            expect_equal(native$normalized_distance,
                         as.numeric(et_to_r(python$normalized_distance)),
                         tolerance=1e-9,info=paste(tag,"normalized"))
          } else {
            expect_null(native$normalized_distance)
          }
          expect_equal(native$step_weights,
                       as.numeric(et_to_r(python$step_weights)),
                       info=paste(tag,"transition weights"))
          expect_equal(native$weighted_local_costs,
                       as.numeric(et_to_r(python$weighted_local_costs)),
                       tolerance=1e-9,info=paste(tag,"weighted local"))
          expect_equal(sum(native$weighted_local_costs),
                       native$raw_distance,tolerance=1e-9,
                       info=paste(tag,"path audit"))
        }
      }
    }
  }
})

test_that("seeded Python 1.2 pairwise constrained/normalized DTW matches",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Independent Python 1.2 pairwise DTW oracle is opt-in")
  set.seed(12042L)
  ctor <- etpy_get_export("TrajectorySet")
  for(scenario in seq_len(6L)){
    nt <- 4L+scenario
    ncurves <- 3L
    v <- array(stats::rnorm(ncurves*nt*3L),
               dim=c(ncurves,nt,3L))
    time <- c(0,cumsum(stats::runif(nt-1L,.1,.4)))
    curve_ids <- paste0("curve",seq_len(ncurves))
    x <- etr_trajectory_set(time,v,curve_ids,c("x","y","pupil"))
    py <- reticulate::py_call(
      ctor,time=time,values=reticulate::r_to_py(v),
      curve_ids=as.list(curve_ids),dimension_names=c("x","y","pupil"))
    for(pattern in c("symmetric1","symmetric2")){
      for(normalized in if(pattern=="symmetric2")c(FALSE,TRUE) else FALSE){
        r <- etr_pairwise_dtw_full(
          x,dimensions=c("x","y"),dimension_weights=c(2,1),
          window_radius=1L,step_pattern=pattern,normalize=normalized)
        p <- etpy_pairwise_dynamic_time_warping_distances(
          py,dimensions=c("x","y"),dimension_weights=c(2,1),
          window_radius=1L,step_pattern=pattern,normalize=normalized)
        expect_equal(as.vector(r),as.vector(et_to_r(p)),tolerance=1e-9)
      }
    }
  }
})
