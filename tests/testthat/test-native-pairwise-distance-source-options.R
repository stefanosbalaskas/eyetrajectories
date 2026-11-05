# Frozen eyetrajectoriespy==1.2.0 analysis.py pairwise distance source checks.
# Author-side numerical comparisons only; no independent certification.

.etr_pairwise_batch05_fixture <- function() {
  time<-c(0,0.25,0.5,0.75,1)
  vals<-array(0,c(4L,length(time),2L))
  for(i in seq_len(4L)) for(t in seq_along(time))
    vals[i,t,]<-c(sin((time[t]+i/9)*3),
                 cos((time[t]+i/7)*5)+i/12)
  etr_trajectory_set(time,vals,curve_ids=c("a","b","c","d"),
    dimension_names=c("x","y"),coordinate_system="pixels")
}

.test_batch05_matrix <- function(py) unname(as.matrix(et_to_r(py)))

.test_batch05_py_set <- function(x) {
  py_ctor<-etpy_get_export("TrajectorySet",.namespace="root")
  reticulate::py_call(py_ctor,
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=reticulate::r_to_py(x$curve_ids),
    dimension_names=reticulate::r_to_py(x$dimension_names),
    coordinate_system=x$coordinate_system)
}

test_that("pairwise DTW source options retain default matrix and symmetry",{
  x<-.etr_pairwise_batch05_fixture()
  old<-etr_pairwise_dtw(x)
  expect_identical(dim(old),c(4L,4L))
  expect_identical(rownames(old),x$curve_ids)
  expect_equal(old,t(old),tolerance=0)
  expect_equal(unname(diag(old)),rep(0,4L),tolerance=0)
  expect_equal(old[1L,3L],etr_dtw(.etr_curve(x,1L),.etr_curve(x,3L)),tolerance=0)
  # Preserve the old all-zero native weighting contract for default calls.
  expect_equal(etr_pairwise_dtw(x,c(0,0)),matrix(0,4L,4L,
    dimnames=list(x$curve_ids,x$curve_ids)),tolerance=0)
  expect_error(etr_pairwise_dtw(x,normalize=TRUE),"symmetric2")
  expect_error(etr_pairwise_dtw(x,step_pattern="symmetric3"),"step_pattern")
  expect_error(etr_pairwise_dtw(x,normalize=1),"boolean")
})

test_that("ordered dimension selection controls pairwise DTW weights and paths",{
  x<-.etr_pairwise_batch05_fixture()
  selected<-etr_pairwise_dtw(x,dimensions=c("y","x"),
    dimension_weights=c(2,.25),window_radius=1L,
    step_pattern="symmetric2",normalize=TRUE)
  expect_equal(selected,t(selected),tolerance=0)
  expect_true(all(diag(selected)==0))
  ai<-matrix(x$values[1L,,c(2L,1L),drop=FALSE],nrow=5L,ncol=2L)
  bi<-matrix(x$values[3L,,c(2L,1L),drop=FALSE],nrow=5L,ncol=2L)
  expect_equal(selected[1L,3L],etr_dtw(ai,bi,c(2,.25),
    window_radius=1L,step_pattern="symmetric2",normalize=TRUE),tolerance=1e-12)
  one<-etr_pairwise_dtw(x,dimensions="y",dimension_weights=2)
  expect_identical(dim(one),c(4L,4L))
  expect_error(etr_pairwise_dtw(x,dimensions=character()),"ordered character")
  expect_error(etr_pairwise_dtw(x,dimensions=c("x","x")),"duplicates")
  expect_error(etr_pairwise_dtw(x,dimensions="unknown"),"Unknown")
  expect_error(etr_pairwise_dtw(x,dimensions=1:2),"character")
  expect_error(etr_pairwise_dtw(x,dimensions=c("y","x"),
    dimension_weights=c(1,2,3)),"match dimensions")
  expect_error(etr_pairwise_dtw(x,dimensions="x",dimension_weights=0),"positive")
  expect_error(etr_pairwise_dtw(x,window_radius=-1L),"non-negative")
  expect_error(etr_pairwise_dtw(x,window_radius=1.5),"integer")
})

test_that("source mode validates pairwise weights even with one curve",{
  x<-.etr_pairwise_batch05_fixture()
  one<-etr_subset(x,"a")
  expect_error(etr_pairwise_dtw(one,dimension_weights=c(0,0),
    python_boundary_mode=TRUE),"positive")
  expect_error(etr_pairwise_dtw(one,dimension_weights=c("1","NaN"),
    python_boundary_mode=TRUE),"finite")
  expect_error(etr_pairwise_dtw(one,window_radius=-1L,
    python_boundary_mode=TRUE),"non-negative")
  expect_equal(etr_pairwise_dtw(one,dimension_weights=c("1","2"),
    python_boundary_mode=TRUE),matrix(0,1L,1L,
      dimnames=list("a","a")),tolerance=0)
})

test_that("pairwise distances preserve valid source empty-trajectory behavior",{
  empty<-etr_trajectory_set(c(0,1,2,3),
    array(numeric(),c(0L,4L,2L)),
    curve_ids=character(),dimension_names=c("x","y"),
    coordinate_system="pixels",python_boundary_mode=TRUE)
  pair<-etr_pairwise_dtw(empty,dimension_weights=c("-1","NaN"),
    window_radius=-1L,python_boundary_mode=TRUE)
  expect_identical(dim(pair),c(0L,0L))
  expect_identical(dim(etr_pairwise_l2(empty,python_boundary_mode=TRUE)),c(0L,0L))
  expect_error(etr_pairwise_dtw(empty,normalize=TRUE),"symmetric2")
})

test_that("pairwise L2 source mode accepts Inf observations without NaN repair",{
  values<-array(c(0,1,2,3,Inf,5),c(2L,3L,1L))
  x<-etr_trajectory_set(c(0,1,2),values,c("a","b"),"x",
    coordinate_system="pixels",python_boundary_mode=TRUE)
  expect_error(etr_pairwise_l2(x),"complete numeric")
  z<-etr_pairwise_l2(x,python_boundary_mode=TRUE)
  expect_true(is.infinite(z[1L,2L]))
  expect_true(is.infinite(z[2L,1L]))
  expect_true(all(diag(z)==0))
  expect_error(etr_pairwise_l2(x,python_boundary_mode=NA),"logical scalar")
})

test_that("pinned Python 1.2 pairwise DTW matches native source options",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 pairwise distance oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_pairwise_batch05_fixture();py_x<-.test_batch05_py_set(x)
  pyfun<-etpy_get_export("pairwise_dynamic_time_warping_distances")
  scenarios<-list(
    list(dimensions=NULL,weights=NULL,radius=NULL,pattern="symmetric1",norm=FALSE),
    list(dimensions=c("y","x"),weights=c(2,.25),radius=1L,
         pattern="symmetric2",norm=TRUE),
    list(dimensions=c("x"),weights=c("1"),radius=0L,
         pattern="symmetric1",norm=FALSE))
  for(case in scenarios){
    native<-etr_pairwise_dtw(x,
      dimensions=case$dimensions,dimension_weights=case$weights,
      window_radius=case$radius,step_pattern=case$pattern,
      normalize=case$norm,python_boundary_mode=TRUE)
    args<-list(
      trajectories=py_x,
      dimension_weights=if(is.null(case$weights))NULL else
        reticulate::r_to_py(as.list(case$weights)),
      window_radius=case$radius,
      step_pattern=case$pattern,
      normalize=case$norm)
    if(!is.null(case$dimensions))
      args$dimensions<-reticulate::r_to_py(as.list(case$dimensions))
    source<-do.call(reticulate::py_call,c(list(pyfun),args))
    expect_equal(unname(native),.test_batch05_matrix(source),tolerance=1e-10)
  }
})

test_that("frozen Python pairwise L2 nonfinite boundary and empty sets agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 pairwise L2 oracle opt-in")
  vals<-array(c(0,1,2,3,Inf,5),c(2L,3L,1L))
  x<-etr_trajectory_set(c(0,1,2),vals,c("a","b"),"x",
    coordinate_system="pixels",python_boundary_mode=TRUE)
  py_x<-.test_batch05_py_set(x)
  pyfun<-etpy_get_export("pairwise_functional_distances")
  py<-reticulate::py_call(pyfun,trajectories=py_x)
  native<-etr_pairwise_l2(x,python_boundary_mode=TRUE)
  expect_identical(is.infinite(unname(as.matrix(et_to_r(py)))),
    is.infinite(unname(native)))
  expect_equal(unname(diag(native)),c(0,0),tolerance=0)
})
