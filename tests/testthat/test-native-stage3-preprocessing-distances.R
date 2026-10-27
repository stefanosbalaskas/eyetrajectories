# Stage 3: native R preprocessing + geometry + distance contracts.
# All tests outside explicit ET_RUN_PYTHON_TESTS opt-in run without Python.

test_that("native coordinate normalization preserves extra channels and missing values", {
  time <- c(0,.4,1,2)
  v <- array(0,dim=c(2L,4L,3L))
  v[1L,,1L] <- c(0,1920,960,480)
  v[1L,,2L] <- c(1080,540,0,270)
  v[2L,,1L] <- c(192,384,576,768)
  v[2L,,2L] <- c(108,216,324,432)
  v[1L,,3L] <- c(5,6,7,8)
  v[2L,,3L] <- c(8,7,6,5)
  m <- data.frame(trial=c("a","b"))
  x <- etr_trajectory_set(time,v,c("a","b"),c("x","y","pupil"),
                          metadata=m,coordinate_system="pixels",
                          time_unit="ms")
  z <- etr_normalize_coordinates(x,width=1920,height=1080)
  expect_equal(z$values[1L,,1L],c(0,1,.5,.25))
  expect_equal(z$values[1L,,2L],c(1,.5,0,.25))
  expect_equal(z$values[,,3L],v[,,3L])
  expect_identical(z$coordinate_system,"normalized")
  expect_identical(z$metadata,m)
  expect_identical(z$time_unit,"ms")
  expect_equal(x$values,v)   # no mutation
  expect_error(etr_normalize_coordinates(x,width=0,height=1),"width")
  expect_error(etr_normalize_coordinates(x,width=Inf,height=1),"width")
  expect_error(etr_normalize_coordinates(x,width=1,height=-1),"height")
  expect_error(etr_normalize_coordinates(x,width=TRUE,height=1),"width")
  x$values[2L,2L,1L] <- NA_real_
  expect_true(is.na(etr_normalize_coordinates(x,1920,1080)$values[2L,2L,1L]))
})

test_that("native per-curve landmark centering differs from centering by first point",{
  time <- c(0,1,2)
  v <- array(0,dim=c(2L,3L,3L))
  v[1L,,1L] <- c(4,6,8)
  v[1L,,2L] <- c(5,10,15)
  v[2L,,1L] <- c(12,14,16)
  v[2L,,2L] <- c(25,30,35)
  v[,,3L] <- 7
  x <- etr_trajectory_set(time,v,c("a","b"),c("x","y","pupil"))
  z <- etr_center_on_landmark(x,landmark_x=c(3,10),
                              landmark_y=c(5,20))
  expect_equal(z$values[1L,,1L],c(1,3,5))
  expect_equal(z$values[2L,,1L],c(2,4,6))
  expect_equal(z$values[2L,,2L],c(5,10,15))
  expect_equal(z$values[,,3L],v[,,3L])
  expect_identical(z$coordinate_system,"landmark_relative")
  expect_equal(etr_center_on_landmark(x,3,5)$values[2L,,1L],
               c(9,11,13))
  expect_error(etr_center_on_landmark(x,1:3,0),"landmark_x")
  expect_error(etr_center_on_landmark(x,1,NA_real_),"landmark_y")
})

test_that("explicit native time interval matches affine mathematical contract",{
  tt <- c(3,3.5,5,6.5)
  a <- array(2,dim=c(1L,4L,2L))
  x <- etr_trajectory_set(tt,a,dimension_names=c("x","y"),
                          time_unit="ms")
  z <- etr_normalize_time_interval(x,start=-1,end=3)
  expect_equal(z$time,c(-1,-1+2/3,-1+8/3,3))
  expect_identical(z$time_unit,"normalized")
  expect_identical(z$values,a)
  expect_identical(x$time,tt)
  expect_error(etr_normalize_time_interval(x,2,2),"end must")
  expect_error(etr_normalize_time_interval(x,3,2),"end must")
  expect_error(etr_normalize_time_interval(x,NA_real_,1),"start")
})

test_that("native heading follows wrapped atan2 and low-speed masking",{
  time <- c(0,.1,.4,1,2)
  v <- array(0,dim=c(2L,length(time),2L))
  v[1L,,1L] <- time
  v[1L,,2L] <- time^2
  v[2L,,1L] <- 2
  v[2L,,2L] <- -3
  x <- etr_trajectory_set(time,v,c("moving","stationary"),c("x","y"))
  h <- etr_heading_function(x)
  expect_equal(h$values[1L,,1L],atan2(2*time,1),tolerance=1e-10)
  expect_true(all(is.na(h$values[2L,,1L])))
  expect_identical(h$dimension_names,"heading")
  expect_identical(h$coordinate_system,"unknown")
  expect_error(etr_heading_function(x,undefined_policy="raise"),
               "undefined")
  expect_error(etr_heading_function(x,min_speed=-.2),"non-negative")
})

test_that("native trajectory tortuosity frame preserves key values and metadata",{
  tt <- 0:3
  v <- array(0,dim=c(2L,4L,2L))
  v[1L,,1L] <- c(0,3,3,6)
  v[1L,,2L] <- c(0,0,4,4)
  v[2L,,1L] <- c(0,1,0,0)
  v[2L,,2L] <- c(0,0,1,0)
  m <- data.frame(subject=c("first","second"))
  x <- etr_trajectory_set(tt,v,c("A","B"),c("x","y"),m)
  z <- etr_trajectory_tortuosity_frame(x)
  expect_s3_class(z,"data.frame")
  expect_equal(z$path_length[1L],10)
  expect_equal(z$endpoint_displacement[1L],sqrt(52))
  expect_equal(z$tortuosity[1L],10/sqrt(52))
  expect_false(z$undefined[1L])
  expect_true(z$undefined[2L])
  expect_true(is.na(z$tortuosity[2L]))
  expect_equal(z$subject,c("first","second"))
  expect_equal(z$curve_id,c("A","B"))
  expect_error(etr_trajectory_tortuosity_frame(x,undefined_policy="raise"),
               "undefined")
  expect_error(etr_trajectory_tortuosity_frame(x,min_displacement=-1),
               "non-negative")
  expect_equal(etr_trajectory_tortuosity_frame(x,min_displacement=9)$undefined,
               c(TRUE,TRUE))
})

test_that("native pairwise Frechet uses selected channels and validates weights",{
  tt <- 0:4
  v <- array(0,dim=c(3L,5L,3L))
  v[2L,,1L] <- 1
  v[3L,,2L] <- 2
  v[1L,,3L] <- 100
  v[2L,,3L] <- -100
  x <- etr_trajectory_set(tt,v,c("a","b","c"),
                          c("x","y","pupil"))
  d <- etr_pairwise_frechet(x,dimensions=c("x","y"),
                            dimension_weights=c(1,4))
  expect_identical(dim(d),c(3L,3L))
  expect_equal(diag(d),c(0,0,0))
  expect_equal(d[1L,2L],1)
  expect_equal(d[1L,3L],4)
  expect_equal(d[2L,3L],sqrt(17))
  expect_equal(d,t(d))
  expect_null(dimnames(d))
  expect_error(etr_pairwise_frechet(x,dimensions=c("x","x")),
               "distinct")
  expect_error(etr_pairwise_frechet(x,dimensions="not_a_channel"),
               "Unknown trajectory dimensions")
  expect_error(etr_pairwise_frechet(x,dimension_weights=c(0,0,0)),
               "positive")
  expect_error(etr_pairwise_frechet(x,dimensions="x",
                                   dimension_weights=c(1,2)),"positive")
})

test_that("nearest functional neighbors return Python-style zero-based indices",{
  tt <- 0:4
  v <- array(0,dim=c(4L,5L,1L))
  v[1L,,1L] <- 0
  v[2L,,1L] <- 1
  v[3L,,1L] <- 3
  v[4L,,1L] <- 9
  x <- etr_trajectory_set(tt,v,c("a","b","c","d"),"x")
  expect_identical(etr_nearest_trajectory_indices(x,index=0L,
                                                   n_neighbors=2L),
                   c(1L,2L))
  expect_identical(etr_nearest_trajectory_indices(x,index=3L,
                                                   n_neighbors=4L),
                   c(2L,1L,0L))
  expect_error(etr_nearest_trajectory_indices(x,index=4L),"index")
  expect_error(etr_nearest_trajectory_indices(x,index=0L,n_neighbors=0L),
               "positive integer")
})

test_that("stage3 randomized Python reference checks match on complete and incomplete inputs",{
  if (!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Stage 3 independent Python 1.2 numerical oracle is opt-in")
  expect_identical(as.character(et_python_version()),"1.2.0")

  had_seed <- exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE)
  if(had_seed) old_seed <- get(".Random.seed",envir=.GlobalEnv,inherits=FALSE)
  on.exit({
    if (had_seed) assign(".Random.seed",old_seed,envir=.GlobalEnv)
    else if (exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE))
      rm(".Random.seed",envir=.GlobalEnv)
  },add=TRUE)
  set.seed(20261027L)
  ctor <- etpy_get_export("TrajectorySet")
  compare_array <- function(a,b,label) {
    native <- a$values
    python <- et_to_r(b$values)
    expect_identical(dim(native),dim(python),info=label)
    expect_identical(is.na(native),is.na(python),
                     info=paste(label,"missing mask"))
    good <- !is.na(native)&!is.na(python)
    if(any(good)) expect_equal(
      as.numeric(native[good]),as.numeric(python[good]),
      tolerance=1e-8,info=label)
    expect_equal(a$time,as.numeric(et_to_r(b$time)),
                 info=paste(label,"time"))
    expect_identical(a$coordinate_system,
                     as.character(et_to_r(b$coordinate_system)),
                     info=paste(label,"coordinate system"))
    expect_identical(a$time_unit,as.character(et_to_r(b$time_unit)),
                     info=paste(label,"time unit"))
  }
  for (scenario in seq_len(8L)) {
    nc <- 3L+(scenario%%3L)
    nt <- 6L+scenario
    time <- c(0,cumsum(stats::runif(nt-1L,.1,.6)))
    values <- array(stats::rnorm(nc*nt*3L,sd=2),
                    dim=c(nc,nt,3L))
    if(scenario%%3L==0L) {
      values[1L,,1L] <- 2
      values[1L,,2L] <- -1
    }
    ids <- paste0("curve",seq_len(nc))
    x <- etr_trajectory_set(time,values,ids,c("x","y","pupil"),
         coordinate_system="pixels",time_unit="ms")
    py <- reticulate::py_call(ctor,
      time=time,values=reticulate::r_to_py(values),
      curve_ids=ids,dimension_names=c("x","y","pupil"),
      coordinate_system="pixels",time_unit="ms")
    landmarks_x <- stats::runif(nc,-2,2)
    landmarks_y <- stats::runif(nc,-2,2)
    compare_array(
      etr_normalize_coordinates(x,1920,1080),
      etpy_normalize_coordinates(py,width=1920,height=1080),
      paste("scenario",scenario,"coordinate normalization"))
    compare_array(
      etr_center_on_landmark(x,landmarks_x,landmarks_y),
      etpy_center_on_landmark(py,
                             landmark_x=landmarks_x,landmark_y=landmarks_y),
      paste("scenario",scenario,"landmark centering"))
    compare_array(
      etr_normalize_time_interval(x,start=-1,end=3),
      etpy_normalize_time(py,start=-1,end=3),
      paste("scenario",scenario,"normalized time"))
    compare_array(
      etr_heading_function(x,min_speed=if(scenario%%3L==0L) .3 else 0),
      etpy_heading_function(py,min_speed=if(scenario%%3L==0L) .3 else 0),
      paste("scenario",scenario,"heading"))
    d_r <- etr_pairwise_frechet(x,dimensions=c("x","y"),
                                dimension_weights=c(1,2))
    d_py <- et_to_r(etpy_pairwise_discrete_frechet_distances(
      py,dimensions=c("x","y"),dimension_weights=c(1,2)))
    expect_equal(as.vector(d_r),as.vector(d_py),
                 tolerance=1e-8,
                 info=paste("scenario",scenario,"pairwise Frechet"))
    # Python nearest indexes are zero-based; use a unique random fixture
    # so default NumPy equal-distance tie policy does not affect order.
    expect_identical(
      etr_nearest_trajectory_indices(x,0L,nc-1L),
      as.integer(et_to_r(etpy_nearest_trajectory_indices(
        py,index=0L,n_neighbors=nc-1L))),
      info=paste("scenario",scenario,"nearest neighbors"))
    tort_r <- etr_trajectory_tortuosity_frame(x,
      min_displacement=if(scenario%%3L==0L) .3 else 0)
    tort_py <- et_to_r(etpy_trajectory_tortuosity(py,
      min_displacement=if(scenario%%3L==0L) .3 else 0))
    for (column in c("path_length","endpoint_displacement","tortuosity")) {
      native <- tort_r[[column]]
      python <- tort_py[[column]]
      expect_identical(is.na(native),is.na(python),
                       info=paste("scenario",scenario,column,"undefined"))
      present <- !is.na(native)&!is.na(python)
      if(any(present)) expect_equal(as.numeric(native[present]),
                                  as.numeric(python[present]),
                                  tolerance=1e-8,
                                  info=paste("scenario",scenario,column))
    }
    expect_identical(tort_r$undefined,as.logical(tort_py$undefined))
  }

  # Native R preserves explicit incomplete gaze in arithmetic without
  # interpolating it: coordinate scaling and landmark centering.
  incomplete <- array(0,dim=c(1L,4L,2L))
  incomplete[1L,,1L] <- c(0,NA_real_,2,3)
  incomplete[1L,,2L] <- c(1,2,3,4)
  x_na <- etr_trajectory_set(c(0,1,2,3),incomplete,
                             dimension_names=c("x","y"))
  py_na <- reticulate::py_call(ctor,
    time=x_na$time,values=reticulate::r_to_py(incomplete),
    curve_ids=x_na$curve_ids,dimension_names=x_na$dimension_names)
  compare_array(etr_normalize_coordinates(x_na,5,10),
                etpy_normalize_coordinates(py_na,width=5,height=10),
                "incomplete coordinate normalization")
  compare_array(etr_center_on_landmark(x_na,2,3),
                etpy_center_on_landmark(py_na,landmark_x=2,landmark_y=3),
                "incomplete landmark centering")
})
