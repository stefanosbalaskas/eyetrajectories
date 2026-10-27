# Native, Python-independent correctness contracts for four additional
# public Python 1.2.0 kinematics algorithms. Numerical parity to Python
# requires the additional explicitly opt-in Python test below.

test_that("native planar geometry obeys quadratic analytic derivatives on irregular grids",{
  time <- c(0,.25,.8,1.4,2)
  v <- array(0,dim=c(2L,length(time),2L))
  v[1L,,1L] <- time
  v[1L,,2L] <- time^2
  v[2L,,1L] <- -time
  v[2L,,2L] <- time^2
  metadata <- data.frame(condition=c("forward","reversed"))
  x <- etr_trajectory_set(time,v,c("one","two"),
                          c("x","y"),metadata,
                          coordinate_system="pixels",time_unit="s")
  acc <- etr_acceleration_magnitude(x)
  curv <- etr_signed_curvature(x)
  turn <- etr_turning_rate(x)
  expect_s3_class(acc,"etr_trajectory_set")
  expect_identical(acc$dimension_names,"acceleration_magnitude")
  expect_identical(curv$dimension_names,"signed_curvature")
  expect_identical(turn$dimension_names,"turning_rate")
  expect_equal(acc$values[1L,,1L],rep(2,length(time)),tolerance=1e-10)
  expect_equal(acc$values[2L,,1L],rep(2,length(time)),tolerance=1e-10)
  expected_curvature <- 2/(1+4*time^2)^(3/2)
  expected_turning <- 2/(1+4*time^2)
  expect_equal(curv$values[1L,,1L],expected_curvature,tolerance=1e-10)
  expect_equal(turn$values[1L,,1L],expected_turning,tolerance=1e-10)
  expect_equal(curv$values[2L,,1L],-expected_curvature,tolerance=1e-10)
  expect_equal(turn$values[2L,,1L],-expected_turning,tolerance=1e-10)
  expect_identical(curv$coordinate_system,"unknown")
  expect_identical(turn$coordinate_system,"unknown")
  expect_identical(acc$coordinate_system,"pixels")
  expect_equal(curv$metadata,metadata)
})

test_that("distance-to-landmark accepts scalar and per-curve values",{
  time <- c(0,1,2)
  v <- array(0,dim=c(2L,3L,2L))
  v[1L,,1L] <- c(3,0,5)
  v[1L,,2L] <- c(4,0,12)
  v[2L,,1L] <- c(4,4,4)
  v[2L,,2L] <- c(0,3,6)
  x <- etr_trajectory_set(time,v,c("a","b"),c("x","y"))
  origin <- etr_distance_to_landmark(x,0,0)
  expect_equal(origin$values[1L,,1L],c(5,0,13))
  expect_equal(origin$values[2L,,1L],c(4,5,sqrt(52)))
  custom <- etr_distance_to_landmark(x,c(0,4),c(0,3))
  expect_equal(custom$values[1L,,1L],c(5,0,13))
  expect_equal(custom$values[2L,,1L],c(3,0,3))
  expect_error(etr_distance_to_landmark(x,1:3,0),
               "finite numeric scalars or per-curve")
  x$values[1L,2L,1L] <- NA_real_
  expect_true(is.na(etr_distance_to_landmark(x,0,0)$values[1L,2L,1L]))
})

test_that("curvature refuses absent planar names unless dimensions specified",{
  time <- c(0,1,2,3,4)
  v <- array(0,dim=c(1L,5L,2L))
  v[1L,,1L] <- time
  v[1L,,2L] <- time^2
  x <- etr_trajectory_set(time,v,dimension_names=c("horizontal","vertical"))
  expect_error(etr_signed_curvature(x),"Specify dimensions explicitly")
  expect_error(etr_turning_rate(x),"Specify dimensions explicitly")
  alt <- etr_signed_curvature(x,dimensions=c("horizontal","vertical"))
  expect_equal(alt$values[1L,,1L],
               2/(1+4*time^2)^(3/2),tolerance=1e-10)
  expect_error(etr_signed_curvature(x,dimensions=c("horizontal","horizontal")),
               "distinct named planar")
  expect_error(etr_signed_curvature(x,dimensions=c("x","y")),
               "Unknown planar dimension")
})

test_that("low-speed undefined semantics fail closed or return native NA",{
  time <- c(0,1,2,3,4)
  v <- array(2,dim=c(2L,5L,2L))
  v[2L,,1L] <- time
  v[2L,,2L] <- time^2
  x <- etr_trajectory_set(time,v,dimension_names=c("x","y"))
  curv <- etr_signed_curvature(x)
  turning <- etr_turning_rate(x)
  expect_true(all(is.na(curv$values[1L,,1L])))
  expect_true(all(is.na(turning$values[1L,,1L])))
  expect_true(all(is.finite(curv$values[2L,,1L])))
  expect_error(etr_signed_curvature(x,undefined_policy="raise"),
               "undefined")
  expect_error(etr_turning_rate(x,undefined_policy="raise"),
               "undefined")
  expect_error(etr_turning_rate(x,min_speed=-1),"non-negative")
  expect_error(etr_signed_curvature(x,min_speed=Inf),"finite numeric")
  expect_error(etr_signed_curvature(x,min_speed=TRUE),"finite numeric")
  expect_error(etr_turning_rate(x,undefined_policy="ignore"),
               "arg")
  threshold <- etr_signed_curvature(x,min_speed=2)
  expect_true(all(is.na(threshold$values[1L,,1L])))
  expect_true(any(is.na(threshold$values[2L,,1L])))
})

test_that("geometry rejects incomplete derivatives, preserving optional observed distances",{
  time <- c(0,1,2)
  v <- array(0,dim=c(1L,3L,2L))
  v[1L,,1L] <- time
  v[1L,,2L] <- time^2
  v[1L,2L,1L] <- NA_real_
  x <- etr_trajectory_set(time,v,dimension_names=c("x","y"))
  expect_error(etr_acceleration_magnitude(x),"complete observations")
  expect_error(etr_signed_curvature(x),"complete observations")
  expect_error(etr_turning_rate(x),"complete observations")
  expect_true(is.na(etr_distance_to_landmark(x,0,0)$values[1L,2L,1L]))
})

test_that("numerical outputs match the Python v1.2 implementations when opted in",{
  if (!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Independent Python/R numerical parity is opt-in")
  time <- c(0,.25,.8,1.4,2)
  v <- array(0,dim=c(2L,length(time),2L))
  v[1L,,1L] <- time
  v[1L,,2L] <- time^2
  v[2L,,1L] <- -time
  v[2L,,2L] <- time^2
  x <- etr_trajectory_set(time,v,c("one","two"),
                          c("x","y"),coordinate_system="pixels",time_unit="s")
  py <- etpy_get_export("TrajectorySet")
  xp <- reticulate::py_call(py,
    time=as.numeric(x$time),values=reticulate::r_to_py(x$values),
    curve_ids=as.character(x$curve_ids),
    dimension_names=as.character(x$dimension_names),
    coordinate_system="pixels",time_unit="s")
  ops <- list(
    list(native=etr_acceleration_magnitude(x),
         python=etpy_acceleration_magnitude_function(xp)),
    list(native=etr_distance_to_landmark(x,c(0,1),c(0,-1)),
         python=etpy_distance_to_landmark_function(
           xp,landmark_x=c(0,1),landmark_y=c(0,-1))),
    list(native=etr_signed_curvature(x),
         python=etpy_signed_curvature_function(xp)),
    list(native=etr_turning_rate(x),
         python=etpy_turning_rate_function(xp))
  )
  for (case in ops){
    expect_equal(case$native$time,as.numeric(et_to_r(case$python$time)))
    py_values <- et_to_r(case$python$values)
    expect_identical(dim(case$native$values),dim(py_values))
    expect_equal(as.vector(case$native$values),as.vector(py_values),
                 tolerance=1e-9)
    expect_equal(case$native$dimension_names,
                 as.character(unlist(et_to_r(case$python$dimension_names))))
  }
})
