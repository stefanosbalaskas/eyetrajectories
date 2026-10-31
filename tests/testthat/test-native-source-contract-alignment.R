# Stage 25: direct source-schema improvements for minimal FPCA-score objects.
# Matching these finite fixtures is not full public source certification.

test_that("minimal score-bearing R list matches native FPCA geometry",{
  sc<-matrix(c(0,1,2,3,4,5),nrow=3L,ncol=2L)
  source_like<-list(scores=sc,n_components=2L)
  result<-etr_score_distance_matrix(source_like)
  expected<-unname(as.matrix(stats::dist(sc)))
  expect_identical(dim(result),c(3L,3L))
  expect_equal(result,expected,tolerance=0)
  expect_equal(diag(result),rep(0,3),tolerance=0)
  expect_equal(result,t(result),tolerance=0)
  expect_equal(etr_score_distance_matrix(source_like,n_components=1L),
    unname(as.matrix(stats::dist(sc[,1L,drop=FALSE]))),tolerance=0)
  expect_error(etr_score_distance_matrix(source_like,n_components=3L),
    "outside the fitted range")
  expect_error(etr_score_distance_matrix(source_like,n_components=0L),
    "outside the fitted range")
  invalid<-source_like;invalid$scores[1L,1L]<-NA_real_
  expect_error(etr_score_distance_matrix(invalid),"finite scores")
  invalid<-source_like;invalid$n_components<-3L
  expect_error(etr_score_distance_matrix(invalid),"compatible")
  expect_error(etr_score_distance_matrix(
    list(scores=sc,n_components=1.5)),"compatible")
  expect_error(etr_score_distance_matrix(
    list(scores=c(1,2),n_components=1L)),"compatible")
  expect_error(etr_score_distance_matrix(list()),"compatible")
  # sklearn converts valid numeric strings to floating-point scores.
  text_scores<-matrix(c("0","3","1","5"),nrow=2L)
  expect_equal(
    etr_score_distance_matrix(list(scores=text_scores,n_components=2L)),
    matrix(c(0,5,5,0),2L,2L),tolerance=1e-12)
  bad_scores<-text_scores;bad_scores[1L,1L]<-"not-a-number"
  expect_error(etr_score_distance_matrix(
    list(scores=bad_scores,n_components=2L)),"finite scores")
})

test_that("source certification remains strict despite repaired fixture",{
  before<-reticulate::py_available(initialize=FALSE)
  z<-etr_native_parity_catalog()
  row<-z[z$python_name=="score_distance_matrix",,drop=FALSE]
  expect_equal(nrow(row),1L)
  expect_true(row$contract_certification_candidate)
  expect_true(row$contract_numerical_fixture_pass)
  expect_true(row$source_contract_gap_unresolved)
  expect_false(row$independent_numeric_parity_pass)
  expect_false(row$behavioral_schema_parity_pass)
  expect_false(row$scientific_inference_qualified)
  expect_false(row$independent_contract_review_pass)
  expect_false(row$one_to_one_native_contract_complete)
  expect_equal(sum(z$one_to_one_native_contract_complete),0L)
  expect_gte(sum(z$source_contract_gap_unresolved),57L)
  expect_equal(sum(z$contract_certification_candidate),4L)
  expect_identical(before,reticulate::py_available(initialize=FALSE))
})

test_that("published Python 1.2 score object oracle is opt-in",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Published Python 1.2 score-container oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  sc<-matrix(c(0,1,2,3,4,5),nrow=3L,ncol=2L)
  ns<-reticulate::import("types")$SimpleNamespace(
    scores=reticulate::r_to_py(sc),
    n_components=as.integer(2L))
  for(k in c(1L,2L)){
    py<-reticulate::py_call(
      etpy_get_export("score_distance_matrix"),
      fpca=ns,n_components=as.integer(k))
    native<-etr_score_distance_matrix(
      list(scores=sc,n_components=2L),n_components=k)
    expect_equal(unname(native),unname(et_to_r(py)),
      tolerance=1e-12)
  }
  text_scores<-matrix(c("0","3","1","5"),nrow=2L)
  py_text<-reticulate::import("numpy")$array(
    reticulate::r_to_py(text_scores))
  text_object<-reticulate::import("types")$SimpleNamespace(
    scores=py_text,n_components=as.integer(2L))
  py_distance<-reticulate::py_call(
    etpy_get_export("score_distance_matrix"),fpca=text_object)
  expect_equal(unname(etr_score_distance_matrix(
      list(scores=text_scores,n_components=2L))),
    unname(et_to_r(py_distance)),tolerance=1e-12)
  # Numerical witness only; broad duck-typing/scikit-learn semantics open.
  expect_equal(sum(etr_native_parity_catalog()$
    one_to_one_native_contract_complete),0L)
})

test_that("Boolean score matrices coerce like frozen Python sklearn input",{
  scores<-matrix(c(TRUE,FALSE,TRUE,FALSE,TRUE,FALSE),
    nrow=3L,ncol=2L)
  source_like<-list(scores=scores,n_components=2L)
  native<-etr_score_distance_matrix(source_like)
  numeric_scores<-matrix(as.numeric(scores),nrow=3L)
  expected<-unname(as.matrix(stats::dist(numeric_scores)))
  expect_equal(unname(native),expected,tolerance=1e-14)
  expect_identical(dim(native),c(3L,3L))
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python Boolean FPCA score oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  source_fit<-reticulate::import("types")$SimpleNamespace(
    scores=reticulate::r_to_py(scores),
    n_components=as.integer(2L))
  published<-reticulate::py_call(
    etpy_get_export("score_distance_matrix"),fpca=source_fit)
  expect_equal(unname(native),unname(et_to_r(published)),
    tolerance=1e-12)
  expect_true(etr_native_parity_catalog()$source_contract_gap_unresolved[
    etr_native_parity_catalog()$python_name=="score_distance_matrix"])
})
