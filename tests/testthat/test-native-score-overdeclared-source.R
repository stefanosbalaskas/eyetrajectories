# Frozen eyetrajectoriespy 1.2.0 analysis.py::score_distance_matrix
# Source SHA: c1cd95ad718327550f7e55393ff38582872f7a94.
# Numerical and coercion witnesses only: no independent certification.

.etr_overdeclared_score_fixture<-function() {
  matrix(c(0,0,3,4,5,12),nrow=3L,ncol=2L,byrow=TRUE)
}

test_that("source mode caps duck-typed component slices to actual score width", {
  scores<-.etr_overdeclared_score_fixture()
  fit<-list(scores=scores,n_components=5L)
  expect_error(etr_score_distance_matrix(fit),"compatible")
  expected<-unname(as.matrix(stats::dist(scores)))
  for(k in c(2L,3L,5L)){
    actual<-etr_score_distance_matrix(fit,n_components=k,
      python_boundary_mode=TRUE)
    expect_identical(dim(actual),c(3L,3L))
    expect_equal(unname(actual),expected,tolerance=0)
    expect_equal(unname(diag(actual)),rep(0,3L),tolerance=0)
  }
  implicit<-etr_score_distance_matrix(fit,python_boundary_mode=TRUE)
  expect_equal(unname(implicit),expected,tolerance=0)
  expect_error(etr_score_distance_matrix(fit,n_components=6L,
    python_boundary_mode=TRUE),"outside the fitted range")
  # A one-column array is valid even if the duck-typed object claims many.
  one<-list(scores=scores[,1L,drop=FALSE],n_components=9L)
  expect_equal(unname(etr_score_distance_matrix(one,
      python_boundary_mode=TRUE)),
    unname(as.matrix(stats::dist(scores[,1L,drop=FALSE]))),
    tolerance=0)
})

test_that("fractional declared metadata requires an explicit Python integer slice", {
  scores<-.etr_overdeclared_score_fixture()
  fit<-list(scores=scores,n_components=2.5)
  expect_error(etr_score_distance_matrix(fit),"compatible")
  expect_error(etr_score_distance_matrix(fit,
    python_boundary_mode=TRUE),"Python integer/Boolean slice")
  expected<-unname(as.matrix(stats::dist(scores)))
  expect_equal(unname(etr_score_distance_matrix(fit,n_components=2L,
    python_boundary_mode=TRUE)),expected,tolerance=0)
  expect_error(etr_score_distance_matrix(fit,n_components=3L,
    python_boundary_mode=TRUE),"outside the fitted range")
  expect_error(etr_score_distance_matrix(fit,n_components=2.0,
    python_boundary_mode=TRUE),"Python integer/Boolean slice")
})

test_that("sparse source score slices cap columns without densifying input", {
  skip_if_not_installed("Matrix")
  scores<-.etr_overdeclared_score_fixture()
  sparse<-Matrix::Matrix(scores,sparse=TRUE)
  fit<-list(scores=sparse,n_components=8L)
  expect_error(etr_score_distance_matrix(fit),"compatible|finite scores")
  expected<-unname(as.matrix(stats::dist(scores)))
  for(k in c(2L,5L,8L)){
    out<-etr_score_distance_matrix(fit,n_components=k,
      python_boundary_mode=TRUE)
    expect_equal(unname(out),expected,tolerance=1e-12)
    expect_true(all(is.finite(out)))
    expect_identical(dim(out),c(3L,3L))
  }
  expect_true(etr_native_parity_catalog()$source_contract_gap_unresolved[
    etr_native_parity_catalog()$python_name=="score_distance_matrix"])
})

test_that("pinned Python 1.2 oversized declared FPCA score slices agree", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 overdeclared FPCA source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  types<-reticulate::import("types",convert=FALSE)
  scores<-.etr_overdeclared_score_fixture()
  oracle<-etpy_get_export("score_distance_matrix")
  fit<-types$SimpleNamespace(scores=reticulate::r_to_py(scores),
    n_components=as.integer(5L))
  for(k in c(2L,3L,5L)){
    expected<-reticulate::py_call(oracle,fpca=fit,
      n_components=as.integer(k))
    actual<-etr_score_distance_matrix(list(scores=scores,n_components=5L),
      n_components=k,python_boundary_mode=TRUE)
    expect_equal(unname(actual),unname(et_to_r(expected)),tolerance=1e-12)
  }
  implicit<-reticulate::py_call(oracle,fpca=fit)
  expect_equal(unname(etr_score_distance_matrix(
      list(scores=scores,n_components=5L),python_boundary_mode=TRUE)),
    unname(et_to_r(implicit)),tolerance=1e-12)
  # Python source allows nonintegral n_components metadata only when an
  # explicit valid integer slice is given; native strict mode rejects it.
  float_fit<-types$SimpleNamespace(scores=reticulate::r_to_py(scores),
    n_components=2.5)
  py_float<-reticulate::py_call(oracle,fpca=float_fit,
    n_components=as.integer(2L))
  expect_equal(unname(etr_score_distance_matrix(
      list(scores=scores,n_components=2.5),n_components=2L,
      python_boundary_mode=TRUE)),unname(et_to_r(py_float)),
    tolerance=1e-12)
  expect_error(reticulate::py_call(oracle,fpca=float_fit))
  if(requireNamespace("Matrix",quietly=TRUE)){
    scipy<-reticulate::import("scipy.sparse",convert=FALSE)
    py_sp<-types$SimpleNamespace(
      scores=scipy$csr_matrix(reticulate::r_to_py(scores)),
      n_components=as.integer(8L))
    sparse_fit<-list(scores=Matrix::Matrix(scores,sparse=TRUE),
      n_components=8L)
    for(k in c(2L,8L)){
      py_sp_out<-reticulate::py_call(oracle,fpca=py_sp,
        n_components=as.integer(k))
      expect_equal(unname(etr_score_distance_matrix(sparse_fit,
          n_components=k,python_boundary_mode=TRUE)),
        unname(et_to_r(py_sp_out)),tolerance=1e-12)
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
