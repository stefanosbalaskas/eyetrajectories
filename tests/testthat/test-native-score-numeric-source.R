# Pinned eyetrajectoriespy 1.2.0 analysis.py score_distance_matrix.
# Frozen source SHA c1cd95ad718327550f7e55393ff38582872f7a94.
# Developer numerical evidence only; this is NOT independent certification.

.etr_score_numeric_fixture<-function() {
  matrix(c(0,0,3,4,5,12),nrow=3L,ncol=2L,byrow=TRUE)
}

test_that("finite source-mode score distances retain symmetric Euclidean geometry", {
  scores<-.etr_score_numeric_fixture()
  fit<-list(scores=scores,n_components=2L)
  stable<-unname(as.matrix(stats::dist(scores)))
  native<-etr_score_distance_matrix(fit)
  source<-etr_score_distance_matrix(fit,python_boundary_mode=TRUE)
  expect_equal(unname(native),stable,tolerance=0)
  expect_equal(unname(source),stable,tolerance=1e-12)
  expect_identical(dim(source),c(3L,3L))
  expect_equal(unname(diag(source)),rep(0,3L),tolerance=0)
  expect_equal(unname(source),unname(t(source)),tolerance=0)
  expect_true(etr_native_parity_catalog()$source_contract_gap_unresolved[
    etr_native_parity_catalog()$python_name=="score_distance_matrix"])
})

test_that("source-mode dense score overflow follows frozen sklearn output domain", {
  distinct<-matrix(c(1e200,0,0,1e200),nrow=2L,byrow=TRUE)
  result<-suppressWarnings(etr_score_distance_matrix(
    list(scores=distinct,n_components=2L),python_boundary_mode=TRUE))
  expect_identical(dim(result),c(2L,2L))
  expect_equal(unname(diag(result)),c(0,0),tolerance=0)
  expect_true(is.infinite(result[1L,2L]))
  expect_true(is.infinite(result[2L,1L]))

  identical_large<-matrix(c(1e200,0,1e200,0),nrow=2L,byrow=TRUE)
  output<-suppressWarnings(etr_score_distance_matrix(
    list(scores=identical_large,n_components=2L),
    python_boundary_mode=TRUE))
  expect_true(is.nan(output[1L,2L]))
  expect_true(is.nan(output[2L,1L]))
  expect_equal(unname(diag(output)),c(0,0),tolerance=0)
  # Native scientific mode remains the direct-distance calculation.
  expect_equal(unname(etr_score_distance_matrix(
    list(scores=identical_large,n_components=2L))),
    matrix(0,2L,2L),tolerance=0)
})

test_that("source-mode sparse score overflow matches dense source category", {
  skip_if_not_installed("Matrix")
  matrices<-list(
    matrix(c(1e200,0,0,1e200),nrow=2L,byrow=TRUE),
    matrix(c(1e200,0,1e200,0),nrow=2L,byrow=TRUE))
  for(i in seq_along(matrices)){
    m<-matrices[[i]]
    fit<-list(scores=Matrix::Matrix(m,sparse=TRUE),n_components=2L)
    got<-suppressWarnings(etr_score_distance_matrix(fit,
      python_boundary_mode=TRUE))
    expect_identical(dim(got),c(2L,2L))
    expect_equal(unname(diag(got)),c(0,0),tolerance=0)
    if(i==1L)expect_true(is.infinite(got[1L,2L]))
    if(i==2L)expect_true(is.nan(got[1L,2L]))
  }
})

test_that("frozen Python 1.2 score numerical and nonfinite outputs agree", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 sklearn numerical oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  types<-reticulate::import("types",convert=FALSE)
  oracle<-etpy_get_export("score_distance_matrix")
  matrices<-list(
    .etr_score_numeric_fixture(),
    matrix(c(1e200,0,0,1e200),nrow=2L,byrow=TRUE),
    matrix(c(1e200,0,1e200,0),nrow=2L,byrow=TRUE))
  for(scores in matrices){
    py_fit<-types$SimpleNamespace(scores=reticulate::r_to_py(scores),
      n_components=as.integer(ncol(scores)))
    expected<-suppressWarnings(et_to_r(reticulate::py_call(oracle,
      fpca=py_fit,n_components=as.integer(ncol(scores)))))
    native<-suppressWarnings(etr_score_distance_matrix(
      list(scores=scores,n_components=as.integer(ncol(scores))),
      n_components=as.integer(ncol(scores)),python_boundary_mode=TRUE))
    expect_identical(dim(native),dim(expected))
    expect_identical(is.infinite(native),is.infinite(expected))
    expect_identical(is.nan(native),is.nan(expected))
    finite<-is.finite(native)&is.finite(expected)
    expect_equal(unname(native[finite]),unname(expected[finite]),
      tolerance=1e-12)
    if(requireNamespace("Matrix",quietly=TRUE)){
      sparse<-reticulate::import("scipy.sparse",convert=FALSE)
      py_sp<-types$SimpleNamespace(
        scores=sparse$csr_matrix(reticulate::r_to_py(scores)),
        n_components=as.integer(ncol(scores)))
      expected_sp<-suppressWarnings(et_to_r(reticulate::py_call(oracle,
        fpca=py_sp,n_components=as.integer(ncol(scores)))))
      native_sp<-suppressWarnings(etr_score_distance_matrix(
        list(scores=Matrix::Matrix(scores,sparse=TRUE),
          n_components=as.integer(ncol(scores))),
        python_boundary_mode=TRUE))
      expect_identical(is.infinite(native_sp),is.infinite(expected_sp))
      expect_identical(is.nan(native_sp),is.nan(expected_sp))
      finite_sp<-is.finite(native_sp)&is.finite(expected_sp)
      expect_equal(unname(native_sp[finite_sp]),
        unname(expected_sp[finite_sp]),tolerance=1e-12)
    }
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
