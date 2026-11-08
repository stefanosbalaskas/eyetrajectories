# Frozen eyetrajectoriespy 1.2.0 analysis.py dynamic-programming contracts.
# Developer numerical source comparisons; NOT independent certification.

.etr_source_test_a <- function() matrix(c(0,0, 1,0, 2,1, 3,1),ncol=2L,byrow=TRUE)
.etr_source_test_b <- function() matrix(c(0,1, 1,1, 2,1),ncol=2L,byrow=TRUE)

test_that("Fréchet optional coupling is zero-based, monotone and audited",{
  a<-.etr_source_test_a();b<-.etr_source_test_b();dw<-c(1,2)
  simple<-etr_frechet(a,b,dw)
  detailed<-etr_frechet(a,b,dw,return_coupling=TRUE)
  expect_s3_class(detailed,"etr_frechet_result")
  expect_equal(detailed$distance,simple,tolerance=0)
  expect_identical(detailed$coupling[1L,],c(0L,0L))
  expect_identical(detailed$coupling[nrow(detailed$coupling),],c(3L,2L))
  expect_true(all(diff(detailed$coupling[,1L])>=0L))
  expect_true(all(diff(detailed$coupling[,2L])>=0L))
  expect_equal(max(detailed$local_distances),detailed$distance,tolerance=1e-12)
  expect_identical(detailed$provenance$tie_break_order,
                   c("diagonal","advance_a","advance_b"))
  expect_error(etr_frechet(a,b,dw,return_coupling=1),"boolean")
  expect_error(etr_frechet(a,b,c(0,0),return_coupling=TRUE),"positive")
})

test_that("DTW symmetric2 path, window and normalization are numerically audited",{
  a<-.etr_source_test_a();b<-.etr_source_test_b();dw<-c(1,2)
  original<-etr_dtw(a,b,dw)
  detailed<-etr_dtw(a,b,dw,window_radius=1L,
    step_pattern="symmetric2",normalize=TRUE,return_path=TRUE)
  expect_s3_class(detailed,"etr_dtw_result")
  expect_identical(detailed$path[1L,],c(0L,0L))
  expect_identical(detailed$path[nrow(detailed$path),],c(3L,2L))
  expect_true(all(abs(detailed$path[,1L]-detailed$path[,2L])<=1L))
  expect_equal(sum(detailed$weighted_local_costs),detailed$raw_distance,
               tolerance=1e-12)
  expect_equal(detailed$normalized_distance,detailed$raw_distance/7,
               tolerance=1e-12)
  expect_equal(detailed$distance,detailed$normalized_distance,tolerance=0)
  expect_equal(etr_dtw(a,b,dw),original,tolerance=0)
  expect_equal(etr_dtw(a,b,dw,window_radius=1L),
               etr_dtw(a,b,dw,window_radius=1L,return_path=TRUE)$distance,
               tolerance=0)
  expect_error(etr_dtw(a,b,window_radius=0L),"too small")
  expect_error(etr_dtw(a,b,window_radius=1),"integer")
  expect_error(etr_dtw(a,b,normalize=TRUE),"symmetric2")
  expect_error(etr_dtw(a,b,step_pattern="symmetric3"),"step_pattern")
  expect_error(etr_dtw(a,b,c(0,0),return_path=TRUE),"positive")
})

test_that("Frozen Python 1.2 Fréchet coupling and DTW path agree exactly",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 source numerical oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  a<-.etr_source_test_a();b<-.etr_source_test_b();dw<-c(1,2)
  py_fr<-reticulate::py_call(etpy_get_export("discrete_frechet_distance"),
    a=reticulate::r_to_py(a),b=reticulate::r_to_py(b),
    dimension_weights=reticulate::r_to_py(dw),return_coupling=TRUE)
  r_fr<-etr_frechet(a,b,dw,return_coupling=TRUE)
  expect_equal(as.numeric(et_to_r(py_fr$distance)),r_fr$distance,tolerance=1e-12)
  expect_equal(unname(as.matrix(et_to_r(py_fr$coupling))),
               unname(r_fr$coupling),tolerance=0)
  expect_equal(as.numeric(et_to_r(py_fr$local_distances)),
               r_fr$local_distances,tolerance=1e-12)
  py_dt<-reticulate::py_call(etpy_get_export("dynamic_time_warping_distance"),
    a=reticulate::r_to_py(a),b=reticulate::r_to_py(b),
    dimension_weights=reticulate::r_to_py(dw),
    window_radius=as.integer(1L),step_pattern="symmetric2",
    normalize=TRUE,return_path=TRUE)
  r_dt<-etr_dtw(a,b,dw,window_radius=1L,
    step_pattern="symmetric2",normalize=TRUE,return_path=TRUE)
  expect_equal(as.numeric(et_to_r(py_dt$distance)),r_dt$distance,tolerance=1e-12)
  expect_equal(as.numeric(et_to_r(py_dt$raw_distance)),r_dt$raw_distance,
               tolerance=1e-12)
  expect_equal(unname(as.matrix(et_to_r(py_dt$path))),
               unname(r_dt$path),tolerance=0)
  expect_equal(as.numeric(et_to_r(py_dt$step_weights)),
               r_dt$step_weights,tolerance=0)
  expect_equal(as.numeric(et_to_r(py_dt$weighted_local_costs)),
               r_dt$weighted_local_costs,tolerance=1e-12)
})

test_that("source recurrence tie-breaking is diagonal first",{
  a<-matrix(rep(0,6),ncol=2L)
  b<-matrix(rep(0,6),ncol=2L)
  fr<-etr_frechet(a,b,return_coupling=TRUE)
  dt<-etr_dtw(a,b,return_path=TRUE)
  expected<-cbind(0:2,0:2)
  expect_equal(unname(fr$coupling),unname(expected),tolerance=0)
  expect_equal(unname(dt$path),unname(expected),tolerance=0)
})

test_that("multiple frozen Python DTW numerical and path contracts match", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 repeated source comparisons opt-in")
  expect_identical(et_python_version(),"1.2.0")
  pyfun<-etpy_get_export("dynamic_time_warping_distance")
  set.seed(20261105L)
  for(k in seq_len(4L)) {
    m<-if(k%%2L==0L)4L else 3L
    n<-if(k%%2L==0L)3L else 4L
    a<-matrix(rnorm(m*2L),nrow=m,ncol=2L)
    b<-matrix(rnorm(n*2L),nrow=n,ncol=2L)
    dw<-c(1,.5+k/10)
    for(pattern in c("symmetric1","symmetric2")) {
      r<-etr_dtw(a,b,dw,window_radius=1L,
        step_pattern=pattern,return_path=TRUE)
      py<-reticulate::py_call(pyfun,
        a=reticulate::r_to_py(a),b=reticulate::r_to_py(b),
        dimension_weights=reticulate::r_to_py(dw),
        window_radius=as.integer(1L),step_pattern=pattern,
        return_path=TRUE)
      expect_equal(r$distance,as.numeric(et_to_r(py$distance)),tolerance=1e-10)
      expect_equal(unname(r$path),unname(as.matrix(et_to_r(py$path))),
        tolerance=0)
      expect_equal(r$step_weights,as.numeric(et_to_r(py$step_weights)),
        tolerance=0)
    }
  }
})
