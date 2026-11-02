# Frozen Python 1.2 analysis.py integrated L2/nearest trajectory contracts.
# Python source: c1cd95ad718327550f7e55393ff38582872f7a94.
# These are author-side source witnesses, not independent certifications.

.etr_functional_distance_source_fixture <- function(){
  tt<-seq(0,1,length.out=7L)
  values<-array(0,c(5L,length(tt),2L))
  offsets<-c(0,.3,1.2,2.7,5)
  for(i in seq_len(5L)){
    values[i,,1L]<-sin(2*pi*tt)+offsets[i]
    values[i,,2L]<-cos(2*pi*tt)+.2*offsets[i]
  }
  etr_trajectory_set(tt,values,
    curve_ids=paste0("curve_",seq_len(5L)),
    dimension_names=c("x","y"),
    coordinate_system="arbitrary",time_unit="s")
}

test_that("functional L2 Python numeric-string and Boolean states are opt-in",{
  x<-.etr_functional_distance_source_fixture()
  a<-matrix(x$values[1L,,,drop=FALSE],
    nrow=length(x$time),ncol=2L)
  b<-matrix(x$values[3L,,,drop=FALSE],
    nrow=length(x$time),ncol=2L)
  d<-etr_l2_distance(a,b,x$time,dimension_weights=c(1,.25))
  expect_true(is.finite(d)&&d>0)
  text_a<-matrix(as.character(a),nrow=nrow(a),ncol=ncol(a))
  text_b<-matrix(as.character(b),nrow=nrow(b),ncol=ncol(b))
  expect_error(etr_l2_distance(text_a,text_b,x$time),"complete numeric")
  expect_equal(etr_l2_distance(text_a,text_b,x$time,
    dimension_weights=c("1","0.25"),python_boundary_mode=TRUE),
    d,tolerance=1e-12)
  aa<-matrix(rep(c(TRUE,FALSE),each=7L),7L,2L)
  bb<-matrix(rep(c(FALSE,TRUE),each=7L),7L,2L)
  expect_equal(etr_l2_distance(aa,bb,x$time,
    python_boundary_mode=TRUE),sqrt(2),tolerance=1e-12)
  expect_error(etr_l2_distance(aa,bb,x$time),"complete numeric")
  text_bad<-text_a
  text_bad[1L,1L]<-"not-a-number"
  expect_error(etr_l2_distance(text_bad,text_b,x$time,
    python_boundary_mode=TRUE),"finite numeric-compatible")
  expect_error(etr_l2_distance(text_a,text_b,x$time,
    dimension_weights=c("-1","1"),python_boundary_mode=TRUE),
    "dimension_weights")
})

test_that("nearest trajectory source numeric ranks and optional Boolean slicing",{
  x<-.etr_functional_distance_source_fixture()
  complete<-etr_pairwise_functional_distances(x)
  expect_equal(complete,t(complete),tolerance=0)
  expect_equal(diag(complete),rep(0,5L),tolerance=0)
  expect_identical(etr_nearest_trajectory_indices(x,index=0L,
    n_neighbors=4L),as.integer(c(1,2,3,4)))
  expect_identical(etr_nearest_trajectory_indices(x,index=0L,
    n_neighbors=TRUE,python_boundary_mode=TRUE),1L)
  expect_error(etr_nearest_trajectory_indices(x,index=0L,
    n_neighbors=TRUE),"positive integer")
  expect_error(etr_nearest_trajectory_indices(x,index=0L,
    n_neighbors=1,python_boundary_mode=TRUE),
    "Python integer or Boolean")
  expect_identical(etr_nearest_trajectory_indices(x,index=0L,
    n_neighbors=1),1L)
  expect_error(etr_nearest_trajectory_indices(x,index=0L,
    n_neighbors=FALSE,python_boundary_mode=TRUE),"positive integer")
  expect_error(etr_nearest_trajectory_indices(x,index=0L,
    n_neighbors=0L,python_boundary_mode=TRUE),"positive integer")
  expect_error(etr_nearest_trajectory_indices(x,index=5L),
    "zero-based curve index")
})

test_that("all three frozen Python functional distance exports match finite R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 functional distances source oracles opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_functional_distance_source_fixture()
  py_x<-reticulate::py_call(etpy_get_export("TrajectorySet"),
    time=reticulate::r_to_py(x$time),
    values=reticulate::r_to_py(x$values),
    curve_ids=as.list(x$curve_ids),
    dimension_names=as.list(x$dimension_names),
    coordinate_system=x$coordinate_system,time_unit=x$time_unit)
  a<-matrix(x$values[1L,,,drop=FALSE],nrow=length(x$time),ncol=2L)
  b<-matrix(x$values[3L,,,drop=FALSE],nrow=length(x$time),ncol=2L)
  for(weights in list(NULL,c(1,.25),c(0,3))){
    args<-list(a=reticulate::r_to_py(a),b=reticulate::r_to_py(b),
      time=reticulate::r_to_py(x$time))
    if(!is.null(weights))args$dimension_weights<-
      reticulate::r_to_py(weights)
    py<-do.call(reticulate::py_call,c(list(
      etpy_get_export("functional_l2_distance")),args))
    native<-etr_l2_distance(a,b,x$time,dimension_weights=weights)
    expect_equal(native,as.numeric(et_to_r(py)),tolerance=1e-12)
    py_pw<-reticulate::py_call(
      etpy_get_export("pairwise_functional_distances"),
      trajectories=py_x,
      dimension_weights=if(is.null(weights))NULL else
        reticulate::r_to_py(weights))
    native_pw<-etr_pairwise_functional_distances(x,
      dimension_weights=weights)
    expect_equal(unname(native_pw),unname(et_to_r(py_pw)),
      tolerance=1e-12)
  }
  for(k in c(1L,3L,10L)){
    py<-reticulate::py_call(
      etpy_get_export("nearest_trajectory_indices"),
      trajectories=py_x,index=as.integer(0L),n_neighbors=k)
    native<-etr_nearest_trajectory_indices(x,index=0L,
      n_neighbors=k)
    expect_identical(native,as.integer(et_to_r(py)))
  }
  py_bool<-reticulate::py_call(
    etpy_get_export("nearest_trajectory_indices"),
    trajectories=py_x,index=as.integer(0L),n_neighbors=TRUE)
  expect_identical(
    etr_nearest_trajectory_indices(x,index=0L,
      n_neighbors=TRUE,python_boundary_mode=TRUE),
    as.integer(et_to_r(py_bool)))
  expect_error(reticulate::py_call(
    etpy_get_export("nearest_trajectory_indices"),
    trajectories=py_x,index=as.integer(0L),n_neighbors=1.0),
    "slice indices")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("frozen Python numeric-string functional L2 coercion agrees",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 numeric-string L2 oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-.etr_functional_distance_source_fixture()
  a<-matrix(x$values[1L,,,drop=FALSE],nrow=length(x$time),ncol=2L)
  b<-matrix(x$values[3L,,,drop=FALSE],nrow=length(x$time),ncol=2L)
  ta<-matrix(as.character(a),nrow=nrow(a),ncol=ncol(a))
  tb<-matrix(as.character(b),nrow=nrow(b),ncol=ncol(b))
  py<-reticulate::py_call(
    etpy_get_export("functional_l2_distance"),
    a=reticulate::r_to_py(ta),b=reticulate::r_to_py(tb),
    time=reticulate::r_to_py(x$time),
    dimension_weights=reticulate::r_to_py(c("1","0.25")))
  native<-etr_l2_distance(ta,tb,x$time,
    dimension_weights=c("1","0.25"),python_boundary_mode=TRUE)
  expect_equal(native,as.numeric(et_to_r(py)),tolerance=1e-12)
})
