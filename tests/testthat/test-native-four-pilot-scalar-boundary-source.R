# Additional bounded Python 1.2 boundary contracts, pinned to
# c1cd95ad718327550f7e55393ff38582872f7a94.
# These are first-party tests, not complete-source certification.

.etr_four_pilot_boolean_scores<-function() {
  list(scores=matrix(c(0,0,1,2,2,4),nrow=3L,byrow=TRUE),
    n_components=2L)
}

test_that("quadrature complex normalization is opt-in Python truthiness",{
  grid<-c(0,1,3)
  plain<-c(.5,1.5,1)
  # The scientific default continues to exclude complex flags.
  expect_error(etr_trapezoid_weights(grid,normalize=1i),"normalize")
  expect_equal(etr_trapezoid_weights(grid,normalize=0+0i,
      python_boundary_mode=TRUE),plain,tolerance=0)
  expect_equal(etr_trapezoid_weights(grid,normalize=1i,
      python_boundary_mode=TRUE),plain/sum(plain),tolerance=1e-14)
  expect_equal(etr_trapezoid_weights(grid,normalize=2+3i,
      python_boundary_mode=TRUE),plain/sum(plain),tolerance=1e-14)
  expect_error(etr_trapezoid_weights(grid,normalize=1i,
      python_boundary_mode=FALSE),"normalize")
})

test_that("ALR accepts Boolean epsilon in explicit Python scalar-boundary mode",{
  x<-array(0,c(2L,3L,3L))
  for(i in 1:2)for(t in 1:3)
    x[i,t,]<-c(.15+.02*i,.35+.01*t,.5-.02*i-.01*t)
  expect_error(etr_alr_transform(x,epsilon=TRUE),"epsilon")
  z<-etr_alr_transform(x,epsilon=TRUE,python_boundary_mode=TRUE)
  expect_identical(dim(z),c(2L,3L,2L))
  expect_equal(z,array(0,dim(z)),tolerance=0)
  expect_error(etr_alr_transform(x,epsilon=FALSE,
    python_boundary_mode=TRUE),"epsilon")
  expect_equal(etr_alr_transform(x,epsilon=1,
    python_boundary_mode=TRUE),z,tolerance=0)
})

test_that("inverse ALR NumPy nonfinite domain stays explicit and rejects Boolean shapes",{
  z<-array(c(1000,-2),c(1L,1L,2L))
  expect_error(etr_inverse_alr(z,0L,3L),"overflowed")
  py<-suppressWarnings(etr_inverse_alr(z,0L,3L,
    python_boundary_mode=TRUE))
  expect_true(any(is.nan(py)))
  expect_identical(dim(py),c(1L,1L,3L))
  # Python's np.ones((n_curve,n_time,True)) rejects Boolean shape sizes.
  expect_error(etr_inverse_alr(array(numeric(),c(1L,2L,0L)),
    reference_dimension=0L,n_dimensions=TRUE,
    python_boundary_mode=TRUE),"n_dimensions")
})

test_that("Python FPCA score slice indexing distinguishes bool and double",{
  x<-.etr_four_pilot_boolean_scores()
  expect_error(etr_score_distance_matrix(x,n_components=TRUE),
    "outside the fitted range")
  native<-etr_score_distance_matrix(x,n_components=TRUE,
    python_boundary_mode=TRUE)
  reference<-etr_score_distance_matrix(x,n_components=1L)
  expect_equal(native,reference,tolerance=0)
  expect_error(etr_score_distance_matrix(x,n_components=as.numeric(1),
    python_boundary_mode=TRUE),"Python integer/Boolean slice")
  # Legacy R still permits an integer-valued double count.
  expect_equal(etr_score_distance_matrix(x,n_components=as.numeric(1)),
    reference,tolerance=0)
  bool_fit<-list(scores=x$scores,n_components=TRUE)
  expect_equal(etr_score_distance_matrix(bool_fit,
    python_boundary_mode=TRUE),reference,tolerance=0)
  expect_error(etr_score_distance_matrix(bool_fit),
    "compatible n_components")
  expect_error(etr_score_distance_matrix(x,n_components=FALSE,
    python_boundary_mode=TRUE),"outside the fitted range")
})

test_that("frozen Python 1.2 scalar boundary oracles agree for all four pilots",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 boundary source oracles opt-in")
  expect_identical(et_python_version(),"1.2.0")
  grid<-c(0,1,3)
  for(value in c(0+0i,0+1i,2+3i)){
    py_flag<-reticulate::py_eval(
      sprintf("complex(%s,%s)",Re(value),Im(value)),convert=FALSE)
    source<-reticulate::py_call(
      etpy_get_export("functional_trapezoid_weights"),
      time=reticulate::r_to_py(grid),normalize=py_flag)
    local<-etr_trapezoid_weights(grid,normalize=value,
      python_boundary_mode=TRUE)
    expect_equal(local,as.numeric(et_to_r(source)),tolerance=1e-14)
  }
  x<-array(0,c(2L,3L,3L))
  for(i in 1:2)for(t in 1:3)
    x[i,t,]<-c(.15+.02*i,.35+.01*t,.5-.02*i-.01*t)
  source_alr<-reticulate::py_call(etpy_get_export("alr_transform"),
    values=reticulate::r_to_py(x),epsilon=TRUE)
  expect_equal(unname(etr_alr_transform(x,epsilon=TRUE,
    python_boundary_mode=TRUE)),unname(et_to_r(source_alr)),
    tolerance=1e-12)
  z<-array(c(1000,-2),c(1L,1L,2L))
  np<-reticulate::import("numpy",convert=FALSE)
  py_inverse<-with(np$errstate(over="ignore",invalid="ignore"),
    reticulate::py_call(etpy_get_export("inverse_alr"),
      transformed=reticulate::r_to_py(z),
      reference_dimension=as.integer(0L),
      n_dimensions=as.integer(3L)))
  local_inverse<-suppressWarnings(etr_inverse_alr(z,0L,3L,
    python_boundary_mode=TRUE))
  expect_identical(dim(local_inverse),dim(et_to_r(py_inverse)))
  expect_identical(is.nan(local_inverse),is.nan(et_to_r(py_inverse)))
  scores<-.etr_four_pilot_boolean_scores()$scores
  types<-reticulate::import("types",convert=FALSE)
  source_fpca<-types$SimpleNamespace(
    scores=reticulate::r_to_py(scores),n_components=as.integer(2L))
  source_dist<-reticulate::py_call(
    etpy_get_export("score_distance_matrix"),
    fpca=source_fpca,n_components=TRUE)
  local_dist<-etr_score_distance_matrix(
    list(scores=scores,n_components=2L),n_components=TRUE,
    python_boundary_mode=TRUE)
  expect_equal(unname(local_dist),unname(et_to_r(source_dist)),
    tolerance=1e-12)
  expect_error(reticulate::py_call(
    etpy_get_export("score_distance_matrix"),fpca=source_fpca,
    n_components=as.numeric(1)),"slice indices")
  source_bool<-types$SimpleNamespace(
    scores=reticulate::r_to_py(scores),n_components=TRUE)
  python_bool_default<-reticulate::py_call(
    etpy_get_export("score_distance_matrix"),fpca=source_bool)
  expect_equal(etr_score_distance_matrix(
    list(scores=scores,n_components=TRUE),
    python_boundary_mode=TRUE),
    unname(et_to_r(python_bool_default)),tolerance=1e-12)
})


# local batch #02: ALR reference integer and Python None normalization

test_that("frozen Python ALR index distinguishes integer from integral double", {
  x<-array(1/3,c(2L,3L,3L))
  ref<-etr_alr_transform(x,reference_dimension=1L,
    python_boundary_mode=TRUE)
  expect_identical(dim(ref),c(2L,3L,2L))
  expect_equal(ref,array(0,c(2L,3L,2L)),tolerance=1e-14)
  expect_error(etr_alr_transform(x,reference_dimension=1,
    python_boundary_mode=TRUE),"Python integer/Boolean")
  expect_error(etr_alr_transform(x,reference_dimension=-1,
    python_boundary_mode=TRUE),"Python integer/Boolean")
  # Preserve the pre-existing native R behavior for integral doubles.
  expect_equal(etr_alr_transform(x,reference_dimension=1),
    etr_alr_transform(x,reference_dimension=1L),tolerance=0)
  expect_equal(etr_alr_transform(x,reference_dimension=TRUE,
    python_boundary_mode=TRUE),ref,tolerance=0)
})

test_that("frozen Python trapezoid normalization accepts None only in source mode", {
  grid<-c(0,1,3)
  weights<-c(.5,1.5,1)
  expect_error(etr_trapezoid_weights(grid,normalize=NULL),"normalize")
  expect_equal(etr_trapezoid_weights(grid,normalize=NULL,
    python_boundary_mode=TRUE),weights,tolerance=0)
  expect_equal(etr_trapezoid_weights(grid,normalize=list(),
    python_boundary_mode=TRUE),weights,tolerance=0)
  expect_equal(etr_trapezoid_weights(grid,normalize=list(FALSE),
    python_boundary_mode=TRUE),weights/sum(weights),tolerance=1e-14)
})

test_that("pinned Python 1.2 ALR and quadrature exceptional source oracles", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Published Python 1.2 ALR and quadrature oracles are opt-in")
  expect_identical(et_python_version(),"1.2.0")
  x<-array(1/3,c(2L,3L,3L))
  py_alr<-etpy_get_export("alr_transform")
  expect_error(reticulate::py_call(py_alr,
    values=reticulate::r_to_py(x),reference_dimension=as.numeric(1)),
    "only integers")
  py_good<-reticulate::py_call(py_alr,
    values=reticulate::r_to_py(x),reference_dimension=as.integer(1L))
  expect_equal(unname(et_to_r(py_good)),
    unname(etr_alr_transform(x,reference_dimension=1L,
      python_boundary_mode=TRUE)),tolerance=1e-14)
  py_w<-reticulate::py_call(
    etpy_get_export("functional_trapezoid_weights"),
    time=reticulate::r_to_py(c(0,1,3)),
    normalize=reticulate::py_eval("None",convert=FALSE))
  expect_equal(as.numeric(et_to_r(py_w)),
    etr_trapezoid_weights(c(0,1,3),normalize=NULL,
      python_boundary_mode=TRUE),tolerance=1e-14)
})
