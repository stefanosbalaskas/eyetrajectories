# Frozen Python 1.2 analysis.py source boundary tests (developer-side, unsigned).
# No software certification is claimed by these tests.

.etr_pair_point_matrix <- function() {
  matrix(c("0","1", "1","0", "2","1", "3","1"),
    ncol=2L,byrow=TRUE)
}
.etr_pair_point_matrix_b <- function() {
  matrix(c("0","0", "1","1", "2","1"),ncol=2L,byrow=TRUE)
}

test_that("Fréchet and DTW preserve strict defaults and accept bounded source matrices",{
  a<-.etr_pair_point_matrix(); b<-.etr_pair_point_matrix_b()
  expect_error(etr_frechet(a,b),"complete numeric")
  expect_error(etr_dtw(a,b),"complete numeric")
  fr<-etr_frechet(a,b,dimension_weights=c("1","2"),
    return_coupling=TRUE,python_boundary_mode=TRUE)
  dt<-etr_dtw(a,b,dimension_weights=c("1","2"),
    window_radius=1L,step_pattern="symmetric2",normalize=TRUE,
    return_path=TRUE,python_boundary_mode=TRUE)
  numeric_a<-matrix(as.numeric(a),nrow=nrow(a),ncol=ncol(a))
  numeric_b<-matrix(as.numeric(b),nrow=nrow(b),ncol=ncol(b))
  expect_equal(fr$distance,etr_frechet(numeric_a,numeric_b,c(1,2)),
    tolerance=0)
  expect_equal(dt$distance,etr_dtw(numeric_a,numeric_b,c(1,2),
    window_radius=1L,step_pattern="symmetric2",normalize=TRUE),tolerance=0)
  expect_identical(fr$coupling[1L,],c(0L,0L))
  expect_identical(dt$path[1L,],c(0L,0L))
  expect_equal(sum(dt$weighted_local_costs),dt$raw_distance,tolerance=1e-12)
})

test_that("source 2D list and Boolean matrix conversions remain geometry-preserving",{
  a<-list(c("0","1"),c("1","0"),c("2","1"))
  b<-list(c("0","0"),c("1","1"),c("2","1"))
  from_list<-etr_frechet(a,b,python_boundary_mode=TRUE)
  numeric_a<-do.call(rbind,lapply(a,as.numeric))
  numeric_b<-do.call(rbind,lapply(b,as.numeric))
  expect_equal(from_list,etr_frechet(numeric_a,numeric_b),tolerance=0)
  expect_equal(etr_dtw(a,b,python_boundary_mode=TRUE),
    etr_dtw(numeric_a,numeric_b),tolerance=0)
  bool_a<-matrix(c(TRUE,FALSE,TRUE,FALSE,TRUE,FALSE),nrow=3L)
  bool_b<-matrix(c(FALSE,TRUE,FALSE,FALSE,TRUE,FALSE),nrow=3L)
  expect_equal(etr_frechet(bool_a,bool_b,python_boundary_mode=TRUE),
    etr_frechet(matrix(as.numeric(bool_a),nrow=3L),
                matrix(as.numeric(bool_b),nrow=3L)),tolerance=0)
  expect_equal(etr_dtw(bool_a,bool_b,python_boundary_mode=TRUE),
    etr_dtw(matrix(as.numeric(bool_a),nrow=3L),
            matrix(as.numeric(bool_b),nrow=3L)),tolerance=0)
})

test_that("source NumPy finite, shape and weights domain remains fail-closed",{
  a<-.etr_pair_point_matrix(); b<-.etr_pair_point_matrix_b()
  expect_error(etr_frechet(a,b,dimension_weights=c("0","0"),
    python_boundary_mode=TRUE),"positive")
  expect_error(etr_dtw(a,b,dimension_weights=c("0","0"),
    python_boundary_mode=TRUE),"positive")
  expect_error(etr_frechet(a,b,dimension_weights=c("1","Inf"),
    python_boundary_mode=TRUE),"finite")
  expect_error(etr_dtw(a,b,dimension_weights=c("1","NaN"),
    python_boundary_mode=TRUE),"finite")
  expect_error(etr_frechet(a,b,dimension_weights=matrix(c(1,2),1L),
    python_boundary_mode=TRUE),"1D")
  expect_error(etr_dtw(a,b,dimension_weights=c("1","oops"),
    python_boundary_mode=TRUE),"nonnumeric")
  expect_error(etr_frechet(list(c(1,2),c(1)),b,
    python_boundary_mode=TRUE),"rectangular")
  expect_error(etr_dtw(a,b,python_boundary_mode=NA),"logical scalar")
  expect_error(etr_frechet(matrix(c(0,NA_real_),ncol=1L),
    matrix(c(1,2),ncol=1L),python_boundary_mode=TRUE),"finite")
  # Source mode refuses all-zero weights even for a scalar-only call;
  # the original native mode deliberately maintains backwards compatibility.
  expect_equal(etr_frechet(matrix(0,1,1),matrix(0,1,1),0),0)
  expect_equal(etr_dtw(matrix(0,1,1),matrix(0,1,1),0),0)
})

test_that("frozen Python 1.2 direct Fréchet and DTW source comparisons",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("direct frozen Python 1.2 numerical source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  a<-.etr_pair_point_matrix();b<-.etr_pair_point_matrix_b()
  dw<-c("1","2")
  py_f<-reticulate::py_call(etpy_get_export("discrete_frechet_distance"),
    a=reticulate::r_to_py(a),b=reticulate::r_to_py(b),
    dimension_weights=reticulate::r_to_py(dw),return_coupling=TRUE)
  r_f<-etr_frechet(a,b,dw,return_coupling=TRUE,
    python_boundary_mode=TRUE)
  expect_equal(as.numeric(et_to_r(py_f$distance)),r_f$distance,tolerance=1e-12)
  expect_equal(unname(as.matrix(et_to_r(py_f$coupling))),
    unname(r_f$coupling),tolerance=0)
  py_d<-reticulate::py_call(etpy_get_export("dynamic_time_warping_distance"),
    a=reticulate::r_to_py(a),b=reticulate::r_to_py(b),
    dimension_weights=reticulate::r_to_py(dw),window_radius=1L,
    step_pattern="symmetric2",normalize=TRUE,return_path=TRUE)
  r_d<-etr_dtw(a,b,dw,window_radius=1L,step_pattern="symmetric2",
    normalize=TRUE,return_path=TRUE,python_boundary_mode=TRUE)
  expect_equal(as.numeric(et_to_r(py_d$distance)),r_d$distance,tolerance=1e-12)
  expect_equal(unname(as.matrix(et_to_r(py_d$path))),
    unname(r_d$path),tolerance=0)
  expect_equal(as.numeric(et_to_r(py_d$step_weights)),r_d$step_weights,
    tolerance=0)
  a_nested<-list(c("0","1"),c("1","0"),c("2","1"))
  b_nested<-list(c("0","0"),c("1","1"),c("2","1"))
  for(fn in c("discrete_frechet_distance","dynamic_time_warping_distance")) {
    ref<-reticulate::py_call(etpy_get_export(fn),
      a=reticulate::r_to_py(a_nested),b=reticulate::r_to_py(b_nested))
    native<-if(fn=="discrete_frechet_distance")
      etr_frechet(a_nested,b_nested,python_boundary_mode=TRUE)
      else etr_dtw(a_nested,b_nested,python_boundary_mode=TRUE)
    expect_equal(as.numeric(et_to_r(ref)),native,tolerance=1e-12)
  }
  # ndarray complex casts real under source; Python lists of complex fail.
  np<-reticulate::import("numpy",convert=FALSE)
  a_complex<-matrix(as.complex(as.numeric(a))+10i,nrow=nrow(a),ncol=ncol(a))
  b_complex<-matrix(as.complex(as.numeric(b))-7i,nrow=nrow(b),ncol=ncol(b))
  py_a<-np$asarray(reticulate::r_to_py(a_complex),dtype="complex128")
  py_b<-np$asarray(reticulate::r_to_py(b_complex),dtype="complex128")
  py_complex<-suppressWarnings(reticulate::py_call(
    etpy_get_export("discrete_frechet_distance"),a=py_a,b=py_b))
  expect_equal(as.numeric(et_to_r(py_complex)),
    etr_frechet(a_complex,b_complex,python_boundary_mode=TRUE),
    tolerance=1e-12)
  py_complex_dt<-suppressWarnings(reticulate::py_call(
    etpy_get_export("dynamic_time_warping_distance"),a=py_a,b=py_b))
  expect_equal(as.numeric(et_to_r(py_complex_dt)),
    etr_dtw(a_complex,b_complex,python_boundary_mode=TRUE),
    tolerance=1e-12)
  expect_false(any(etr_native_parity_catalog()$one_to_one_native_contract_complete))
})
