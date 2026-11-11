# Frozen eyetrajectoriespy==1.2.0 fpca.py::functional_trapezoid_weights
# and analysis.py::discrete_frechet_distance/dynamic_time_warping_distance.
# First-party bounded source tests; independent full-domain parity is OPEN.

test_that("trapezoid weights coerce heterogeneous Python scalar sequences", {
  time<-list("0",TRUE,2.5,"4")
  expected<-c(.5,1.25,1.5,.75)
  expect_equal(etr_trapezoid_weights(time),expected,tolerance=0)
  expect_equal(etr_trapezoid_weights(time,normalize=TRUE),
    expected/sum(expected),tolerance=1e-14)
  expect_equal(etr_trapezoid_weights(list(FALSE,1,3)),
    c(.5,1.5,1),tolerance=0)
  expect_error(etr_trapezoid_weights(list("0",FALSE,2)),
    "strictly increasing")
  expect_error(etr_trapezoid_weights(list("0","bad",2)),
    "strictly increasing")
  expect_error(etr_trapezoid_weights(list("0",NA_character_,2)),
    "strictly increasing")
  expect_error(etr_trapezoid_weights(list("0",factor("1"),2)),
    "numeric scalars")
  expect_error(etr_trapezoid_weights(list("0",c(1,2),3)),
    "numeric scalars")
  # The source-domain discrepancy was closed by six-category
  # SHA-verified author review, not independent certification.
  row<-etr_native_parity_catalog()
  row<-row[row$python_name=="functional_trapezoid_weights",]
  expect_false(row$source_contract_gap_unresolved)
  expect_false(row$one_to_one_native_contract_complete)
})

.etr_source_mixed_distance_fixture<-function() {
  a<-list(list("0",FALSE),list(TRUE,"2.5"),list("3",4))
  b<-list(list(1,1),list(2,"3"),list(4,5))
  w<-list("1",TRUE)
  aa<-matrix(c(0,0,1,2.5,3,4),ncol=2L,byrow=TRUE)
  bb<-matrix(c(1,1,2,3,4,5),ncol=2L,byrow=TRUE)
  list(a=a,b=b,w=w,aa=aa,bb=bb)
}

test_that("bounded NumPy input mode extends native Fréchet and DTW, not strict default",{
  z<-.etr_source_mixed_distance_fixture()
  expect_error(etr_discrete_frechet(z$a,z$b,dimension_weights=z$w))
  expect_error(etr_dynamic_time_warping(z$a,z$b,dimension_weights=z$w))
  source_f<-etr_discrete_frechet(z$a,z$b,dimension_weights=z$w,
    return_coupling=TRUE,python_boundary_mode=TRUE)
  strict_f<-etr_discrete_frechet(z$aa,z$bb,dimension_weights=c(1,1),
    return_coupling=TRUE)
  expect_equal(source_f$distance,strict_f$distance,tolerance=0)
  expect_equal(source_f$coupling,strict_f$coupling,tolerance=0)
  expect_equal(source_f$local_distances,strict_f$local_distances,tolerance=0)
  expect_true(all(source_f$coupling>=0L))
  expect_equal(etr_discrete_frechet(
      matrix(c("0","1","3","0","2.5","4"),3L,2L),
      z$bb,dimension_weights=c("1","1"),
      python_boundary_mode=TRUE),strict_f$distance,tolerance=1e-14)
  source_d<-etr_dynamic_time_warping(z$a,z$b,dimension_weights=z$w,
    window_radius=1L,step_pattern="symmetric2",normalize=TRUE,
    return_path=TRUE,python_boundary_mode=TRUE)
  strict_d<-etr_dynamic_time_warping(z$aa,z$bb,dimension_weights=c(1,1),
    window_radius=1L,step_pattern="symmetric2",normalize=TRUE,
    return_path=TRUE)
  expect_equal(source_d$distance,strict_d$distance,tolerance=0)
  expect_equal(source_d$path,strict_d$path,tolerance=0)
  expect_equal(source_d$weighted_local_costs,strict_d$weighted_local_costs,
    tolerance=0)
  expect_equal(source_d$raw_distance,strict_d$raw_distance,tolerance=0)
  expect_equal(source_d$normalization_denominator,6,tolerance=0)
})

test_that("NumPy-compatible distance mode rejects ragged, nonfinite and invalid weights",{
  z<-.etr_source_mixed_distance_fixture()
  expect_error(etr_discrete_frechet(list(c(0,1),c(2)),
    z$b,python_boundary_mode=TRUE),"equal dimensions")
  expect_error(etr_dynamic_time_warping(list(c(0,1),c(2)),
    z$b,python_boundary_mode=TRUE),"equal dimensions")
  expect_error(etr_discrete_frechet(list(c(0,1),c("bad",2)),
    z$b,python_boundary_mode=TRUE),"finite complete")
  expect_error(etr_discrete_frechet(z$a,z$b,
    dimension_weights=list("0",FALSE),
    python_boundary_mode=TRUE),"positive")
  expect_error(etr_discrete_frechet(z$a,z$b,
    dimension_weights=list("1",NA_character_),
    python_boundary_mode=TRUE),"finite")
  expect_error(etr_dynamic_time_warping(z$a,z$b,
    dimension_weights=c("1","Inf"),python_boundary_mode=TRUE),"finite")
  expect_error(etr_dynamic_time_warping(z$a,z$b,
    python_boundary_mode=NA),"python_boundary_mode")
  expect_error(etr_discrete_frechet(z$a,z$b,
    python_boundary_mode=c(TRUE,FALSE)),"python_boundary_mode")
  expect_error(etr_dynamic_time_warping(z$a,z$b,
    window_radius=0L,step_pattern="bad",
    python_boundary_mode=TRUE),"step_pattern")
  # Name mappings and independently reviewed scientific certificates
  # must never be upgraded from these bounded author-side test cases.
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("published Python 1.2 NumPy scalar containers agree with native R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 mixed scalar conversion oracles opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import eyetrajectoriespy as et
_mixed_t=['0',True,2.5,'4']
_mixed_a=[['0',False],[True,'2.5'],['3',4]]
_mixed_b=[[1,1],[2,'3'],[4,5]]
_mixed_w=['1',True]
_mixed_q=et.functional_trapezoid_weights(_mixed_t)
_mixed_qn=et.functional_trapezoid_weights(_mixed_t,normalize=True)
_mixed_f=et.discrete_frechet_distance(
 _mixed_a,_mixed_b,dimension_weights=_mixed_w,return_coupling=True)
_mixed_d=et.dynamic_time_warping_distance(
 _mixed_a,_mixed_b,dimension_weights=_mixed_w,
 window_radius=1,step_pattern='symmetric2',normalize=True,
 return_path=True)
")
  py<-function(expression)et_to_r(reticulate::py_eval(
    expression,convert=FALSE))
  local_time<-list("0",TRUE,2.5,"4")
  expect_equal(etr_trapezoid_weights(local_time),
    as.numeric(py("_mixed_q")),tolerance=1e-13)
  expect_equal(etr_trapezoid_weights(local_time,normalize=TRUE),
    as.numeric(py("_mixed_qn")),tolerance=1e-13)
  z<-.etr_source_mixed_distance_fixture()
  f<-etr_discrete_frechet(z$a,z$b,z$w,
    return_coupling=TRUE,python_boundary_mode=TRUE)
  expect_equal(f$distance,as.numeric(py("_mixed_f.distance")),
    tolerance=1e-12)
  expect_equal(unname(f$coupling),unname(py("_mixed_f.coupling")),
    tolerance=0)
  expect_equal(f$local_distances,
    as.numeric(py("_mixed_f.local_distances")),tolerance=1e-12)
  d<-etr_dynamic_time_warping(z$a,z$b,z$w,
    window_radius=1L,step_pattern="symmetric2",normalize=TRUE,
    return_path=TRUE,python_boundary_mode=TRUE)
  expect_equal(d$distance,as.numeric(py("_mixed_d.distance")),
    tolerance=1e-12)
  expect_equal(unname(d$path),unname(py("_mixed_d.path")),
    tolerance=0)
  expect_equal(d$weighted_local_costs,
    as.numeric(py("_mixed_d.weighted_local_costs")),tolerance=1e-12)
  expect_equal(d$raw_distance,as.numeric(py("_mixed_d.raw_distance")),
    tolerance=1e-12)
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
