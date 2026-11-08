# Frozen Python 1.2 root compositional.py / validation.py source comparisons.
# All source oracles are direct public exports, not inferred R-only fixtures.
# R scientific default does not silently accept fully nested leaf lists.

.etr_mixed_simplex_fixture <- function() {
  list(
    list(list("0.25", FALSE, "0.75"),
         list(TRUE, "0", 0L),
         list("0.1", 0.2, 0.7)),
    list(list(FALSE, "0.3", 0.7),
         list("0.6", TRUE, "-0.6"),
         list(0.15, "0.35", 0.5))
  )
}

.etr_mixed_logits_fixture <- function() {
  list(
    list(list("0.25", TRUE), list(FALSE, "-1.5"),
         list("NaN", "0.2")),
    list(list(TRUE, "0.5"), list("-0.2", FALSE),
         list("1.5", "-Inf"))
  )
}

test_that("ALR source mode coerces nested heterogeneous leaf scalars", {
  nested <- .etr_mixed_simplex_fixture()
  values <- array(0,dim=c(2L,3L,3L))
  values[1L,1L,] <- c(.25,0,.75)
  values[1L,2L,] <- c(1,0,0)
  values[1L,3L,] <- c(.1,.2,.7)
  values[2L,1L,] <- c(0,.3,.7)
  # The second curve's middle cell deliberately has a negative simplex
  # component and must fail validation even after successful coercion.
  values[2L,2L,] <- c(.6,1,-.6)
  values[2L,3L,] <- c(.15,.35,.5)
  expect_error(etr_alr_transform(nested,0L),"simplex nested")
  expect_error(etr_alr_transform(nested,0L,
    python_boundary_mode=TRUE),"non-negative")
  nested[[2L]][[2L]] <- list("0.6", FALSE, "0.4")
  values[2L,2L,] <- c(.6,0,.4)
  local <- etr_alr_transform(nested,reference_dimension=0L,
    python_boundary_mode=TRUE)
  reference <- etr_alr_transform(values,reference_dimension=0L)
  expect_equal(local,reference,tolerance=1e-13)
  expect_identical(dim(local),c(2L,3L,2L))
  expect_equal(sum(exp(local[1L,1L,])),
    sum(exp(reference[1L,1L,])),tolerance=1e-14)
})

test_that("inverse ALR accepts numeric text, Boolean and nonfinite leaves", {
  nested <- .etr_mixed_logits_fixture()
  expect_error(etr_inverse_alr(nested,0L,3L),"simplex nested")
  local <- suppressWarnings(etr_inverse_alr(nested,0L,3L,
    python_boundary_mode=TRUE))
  expect_identical(dim(local),c(2L,3L,3L))
  expect_true(is.nan(local[1L,3L,1L]))
  expect_true(is.nan(local[1L,3L,2L]))
  expect_true(is.nan(local[1L,3L,3L]))
  expect_equal(sum(local[2L,3L,]),1,tolerance=1e-14)
  expect_equal(sum(local[1L,1L,]),1,tolerance=1e-14)
  expect_error(etr_inverse_alr(
    list(list(list("bad","0"))),0L,3L,
    python_boundary_mode=TRUE),"incompatible dimensions|nonfinite")
})

test_that("source simplex validation accepts dtype=float compatible containers", {
  values <- .etr_mixed_simplex_fixture()
  values[[2L]][[2L]] <- list("0.6", FALSE, "0.4")
  expect_error(etr_validate_simplex(values),"shape")
  expect_null(etr_validate_simplex(values,
    python_boundary_mode=TRUE))
  expect_null(etr_validate_simplex(array(character(0),
    c(0L,4L,0L)),python_boundary_mode=TRUE))
  expect_null(etr_validate_simplex(array(logical(0),
    c(2L,0L,0L)),python_boundary_mode=TRUE))
  expect_error(etr_validate_simplex(array(numeric(0),c(2L,3L,0L)),
    python_boundary_mode=TRUE),"sum to one")
  expect_error(etr_validate_simplex(array(c("bad","0","1"),
    c(1L,1L,3L)),python_boundary_mode=TRUE),"missing")
  expect_null(etr_validate_simplex(array(c(0.3,0.7)+1i,
    c(1L,1L,2L)),python_boundary_mode=TRUE))
  expect_error(etr_validate_simplex(array(c(.3,.7)+1i,
    c(1L,1L,2L))),"shape")
})

test_that("direct frozen Python 1.2 mixed-nested oracles agree", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 compositional source oracles are opt-in")
  expect_identical(et_python_version(),"1.2.0")
  np <- reticulate::import("numpy",convert=FALSE)
  alr <- etpy_get_export("alr_transform",.namespace="root")
  inverse <- etpy_get_export("inverse_alr",.namespace="root")
  validate <- etpy_get_export("validate_simplex",.namespace="root")
  source_values <- .etr_mixed_simplex_fixture()
  source_values[[2L]][[2L]] <- list("0.6",FALSE,"0.4")
  # Preserve each scalar type rather than coercing the entire R object.
  py_values <- reticulate::r_to_py(source_values)
  py_float <- np$asarray(py_values,dtype="float64")
  source_z <- reticulate::py_call(alr,values=py_float,
    reference_dimension=as.integer(0L))
  local_z <- etr_alr_transform(source_values,0L,
    python_boundary_mode=TRUE)
  expect_equal(unname(local_z),unname(et_to_r(source_z)),
    tolerance=1e-12)
  expect_null(etr_validate_simplex(source_values,
    python_boundary_mode=TRUE))
  expect_null(et_to_r(reticulate::py_call(validate,values=py_float)))
  py_logits <- np$asarray(
    reticulate::r_to_py(.etr_mixed_logits_fixture()),dtype="float64")
  py_out <- with(np$errstate(over="ignore",invalid="ignore"),
    reticulate::py_call(inverse,transformed=py_logits,
      reference_dimension=as.integer(0L),n_dimensions=as.integer(3L)))
  native_out <- suppressWarnings(etr_inverse_alr(
    .etr_mixed_logits_fixture(),0L,3L,python_boundary_mode=TRUE))
  expected <- et_to_r(py_out)
  expect_identical(dim(native_out),dim(expected))
  expect_identical(is.nan(native_out),is.nan(expected))
  finite <- is.finite(expected)&is.finite(native_out)
  expect_equal(native_out[finite],expected[finite],tolerance=1e-12)
  for(shape in list(c(0L,3L,0L),c(2L,0L,0L))) {
    py_empty <- np$zeros(reticulate::tuple(shape[1L],shape[2L],
      shape[3L]),dtype="float64")
    expect_null(et_to_r(reticulate::py_call(validate,values=py_empty)))
    expect_null(etr_validate_simplex(array(numeric(0),shape),
      python_boundary_mode=TRUE))
  }
  expect_false(any(etr_native_parity_catalog()$one_to_one_native_contract_complete))
})
