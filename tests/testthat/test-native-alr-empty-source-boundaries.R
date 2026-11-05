# Frozen Python 1.2: compositional.py::alr_transform and inverse_alr
# Empty curve and empty time axes are valid NumPy 3-D array shapes.
# This suite is required in both first-party qualification modes.

test_that("native source ALR preserves zero-curve and zero-time axes", {
  shapes <- list(c(0L,3L,3L), c(2L,0L,3L),
    c(0L,0L,3L), c(0L,3L,1L), c(2L,0L,1L))
  for(shape in shapes) {
    values <- array(numeric(0), dim=shape)
    z <- etr_alr_transform(values, reference_dimension=-1L,
      python_boundary_mode=TRUE)
    expect_identical(dim(z),c(shape[1L],shape[2L],shape[3L]-1L))
    expect_length(z,0L)
    restored <- etr_inverse_alr(z,reference_dimension=-1L,
      n_dimensions=as.integer(shape[3L]),python_boundary_mode=TRUE)
    expect_identical(dim(restored),shape)
    expect_length(restored,0L)
  }
  expect_error(etr_alr_transform(array(numeric(0),c(0L,3L,0L)),
    python_boundary_mode=TRUE),"at least one simplex dimension")
  expect_error(etr_alr_transform(array(numeric(0),c(0L,3L,3L)),
    reference_dimension=1,python_boundary_mode=TRUE),
    "Python integer/Boolean index")
  expect_error(etr_inverse_alr(array(numeric(0),c(0L,3L,2L)),
    reference_dimension=0L,n_dimensions=3,
    python_boundary_mode=TRUE),"Python integer shape")
})

test_that("direct pinned Python 1.2 ALR empty-axis output shapes agree", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 ALR zero-axis oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  np <- reticulate::import("numpy",convert=FALSE)
  py_alr <- etpy_get_export("alr_transform",.namespace="root")
  py_inverse <- etpy_get_export("inverse_alr",.namespace="root")
  shapes <- list(c(0L,3L,3L), c(2L,0L,3L),
    c(0L,0L,3L), c(0L,3L,1L), c(2L,0L,1L))
  for(shape in shapes) {
    py_values <- np$zeros(reticulate::tuple(shape[1L],shape[2L],shape[3L]),
      dtype="float64")
    py_z <- reticulate::py_call(py_alr,
      values=py_values,reference_dimension=as.integer(-1L))
    native_z <- etr_alr_transform(array(numeric(0),dim=shape),
      reference_dimension=-1L,python_boundary_mode=TRUE)
    source_shape <- as.integer(unlist(reticulate::py_to_r(py_z$shape),
      use.names=FALSE))
    expect_identical(source_shape,dim(native_z))
    py_back <- reticulate::py_call(py_inverse,
      transformed=py_z,
      reference_dimension=as.integer(-1L),
      n_dimensions=as.integer(shape[3L]))
    native_back <- etr_inverse_alr(native_z,-1L,
      as.integer(shape[3L]),python_boundary_mode=TRUE)
    restored_shape <- as.integer(unlist(reticulate::py_to_r(py_back$shape),
      use.names=FALSE))
    expect_identical(restored_shape,dim(native_back))
    expect_length(native_back,0L)
  }
  # A successful empty-shape source replay does not close full contracts.
  expect_false(any(etr_native_parity_catalog()$one_to_one_native_contract_complete))
})
