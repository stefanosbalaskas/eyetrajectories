# Bounded source-compatible pairwise distance weights, frozen Python 1.2.
# Both numerical and representation contracts remain reviewable.

.etr_pairwise_source_weights_fixture<-function() {
  t<-c(0,1,2)
  values<-array(0,c(3L,3L,2L))
  for(i in seq_len(3L)){
    values[i,,1L]<-c(0,1,2)+i-1L
    values[i,,2L]<-c(0,0,1)+(i-1L)*.5
  }
  x<-etr_trajectory_set(t,values,c("one","two","three"),
    c("x","y"),coordinate_system="normalized",
    time_unit="normalized")
  x
}

test_that("source-style Boolean and numeric-string weights work in pairwise Fréchet",{
  x<-.etr_pairwise_source_weights_fixture()
  ref<-etr_pairwise_frechet(x,dimension_weights=c(1,1))
  source<-etr_pairwise_frechet(x,
    dimension_weights=list("1",TRUE),python_boundary_mode=TRUE)
  expect_identical(dim(source),c(3L,3L))
  expect_equal(source,ref,tolerance=1e-14)
  expect_equal(source,t(source),tolerance=0)
  expect_equal(diag(source),rep(0,3),tolerance=0)
  expect_error(etr_pairwise_frechet(x,
    dimension_weights=list("1",TRUE)))
  expect_error(etr_pairwise_frechet(x,dimension_weights=c("0","0"),
    python_boundary_mode=TRUE),"positive")
  expect_error(etr_pairwise_frechet(x,python_boundary_mode=NA),
    "python_boundary_mode")
  expect_error(etr_pairwise_frechet(x,
    dimension_weights=list("1",NA_character_),
    python_boundary_mode=TRUE),"finite")
})

test_that("source-style weights preserve pairwise DTW full scientific results",{
  x<-.etr_pairwise_source_weights_fixture()
  for(pattern in c("symmetric1","symmetric2")){
    ref<-etr_pairwise_dtw_full(x,dimension_weights=c(1,1),
      step_pattern=pattern,window_radius=1L,
      normalize=identical(pattern,"symmetric2"))
    source<-etr_pairwise_dtw_full(x,
      dimension_weights=list("1",TRUE),
      step_pattern=pattern,window_radius=1L,
      normalize=identical(pattern,"symmetric2"),
      python_boundary_mode=TRUE)
    expect_equal(source,ref,tolerance=1e-14)
    expect_equal(diag(source),rep(0,3),tolerance=0)
  }
  expect_error(etr_pairwise_dtw_full(x,
    dimension_weights=list("1",TRUE)))
  expect_error(etr_pairwise_dtw_full(x,
    dimension_weights=c("1","NaN"),
    python_boundary_mode=TRUE),"finite")
  expect_error(etr_pairwise_dtw_full(x,python_boundary_mode=1),
    "python_boundary_mode")
})

test_that("pinned Python 1.2 pairwise distance matrices match native bounded weights",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 pairwise source weight oracles opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np, pandas as pd, eyetrajectoriespy as et
_pw_time=np.array([0,1,2],dtype=float)
_pw_v=np.zeros((3,3,2),dtype=float)
for i in range(3):
 _pw_v[i,:,0]=np.array([0,1,2])+i
 _pw_v[i,:,1]=np.array([0,0,1])+i*.5
_pw_x=et.TrajectorySet(time=_pw_time,values=_pw_v,
 curve_ids=('one','two','three'),dimension_names=('x','y'),
 coordinate_system='normalized',time_unit='normalized',
 metadata=pd.DataFrame(index=range(3)))
_pw_f=et.pairwise_discrete_frechet_distances(
 _pw_x,dimension_weights=['1',True])
_pw_d1=et.pairwise_dynamic_time_warping_distances(
 _pw_x,dimension_weights=['1',True],window_radius=1,
 step_pattern='symmetric1',normalize=False)
_pw_d2=et.pairwise_dynamic_time_warping_distances(
 _pw_x,dimension_weights=['1',True],window_radius=1,
 step_pattern='symmetric2',normalize=True)
")
  z<-.etr_pairwise_source_weights_fixture()
  eq<-function(r,py){
    expect_equal(unname(r),
      unname(et_to_r(reticulate::py_eval(py,convert=FALSE))),
      tolerance=1e-12)
  }
  eq(etr_pairwise_frechet(z,dimension_weights=list("1",TRUE),
    python_boundary_mode=TRUE),"_pw_f")
  eq(etr_pairwise_dtw_full(z,dimension_weights=list("1",TRUE),
    window_radius=1L,step_pattern="symmetric1",
    python_boundary_mode=TRUE),"_pw_d1")
  eq(etr_pairwise_dtw_full(z,dimension_weights=list("1",TRUE),
    window_radius=1L,step_pattern="symmetric2",normalize=TRUE,
    python_boundary_mode=TRUE),"_pw_d2")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
