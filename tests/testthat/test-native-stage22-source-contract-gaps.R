# Stage 22 source-contract gap register: published Python 1.2 source is
# explicitly NOT certified by matching scientific plot geometry alone.
test_that("508-contract certificate gate rejects known unresolved source differences",{
  before<-reticulate::py_available(initialize=FALSE)
  z<-etr_native_parity_catalog()
  expect_equal(nrow(z),508L)
  expect_equal(sum(z$source_contract_gap_known),46L)
  expect_equal(sum(z$source_contract_gap_unresolved),46L)
  expect_true(all(z$source_contract_gap_unresolved[
    z$contract_certification_candidate]))
  expect_true(all(z$contract_numerical_fixture_pass[
    z$contract_certification_candidate]))
  expect_false(any(z$one_to_one_native_contract_complete))
  expect_equal(sum(z$contract_certification_candidate),4L)
  expect_error(etr_native_parity_catalog(require_complete=TRUE),
    "NOT complete")
  plot_names<-c("plot_embedding_delay_diagnostics",
    "plot_embedding_dimension_diagnostics",
    "plot_recurrence_network_degree","plot_recurrence_rate_curve",
    "plot_windowed_rqa","plot_local_divergence",
    "plot_surrogate_nonlinearity","plot_poincare_return_map")
  for(p in plot_names) {
    row<-z[z$python_name==p,]
    expect_equal(nrow(row),1L)
    expect_true(row$source_contract_gap_unresolved)
    expect_identical(row$source_contract_gap_kind,
      if(p=="plot_surrogate_nonlinearity")
        "backend_and_histogram" else "backend_return_type")
    expect_false(row$one_to_one_native_contract_complete)
  }
  row<-z[z$python_name=="functional_trapezoid_weights",]
  expect_equal(nrow(row),1L)
  expect_true(row$source_contract_gap_unresolved)
  expect_identical(row$source_contract_gap_kind,
    "accepted_input_containers")
  expect_identical(before,reticulate::py_available(initialize=FALSE))
})

test_that("source Python 1.2 trapezoid sequence inputs now align but truthiness does not",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned public Python 1.2 source acceptance witness is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  py<-reticulate::py_call(etpy_get_export("functional_trapezoid_weights"),
    time=reticulate::r_to_py(list(0,1,3)))
  expect_equal(as.numeric(et_to_r(py)),c(.5,1.5,1),tolerance=0)
  expect_equal(etr_trapezoid_weights(c(0,1,3)),
    c(.5,1.5,1),tolerance=0)
  expect_equal(etr_trapezoid_weights(list(0,1,3)),
    c(.5,1.5,1),tolerance=0)
  expect_equal(etr_trapezoid_weights(c("0","1","3")),
    c(.5,1.5,1),tolerance=0)
  expect_error(etr_trapezoid_weights(matrix(c(0,1,3),ncol=1)),
    "one-dimensional")
  # The published Python function tests truthiness, not logical identity:
  # normalize=1 is accepted and normalizes in Python, but native R
  # intentionally requires an explicit logical TRUE in scientific use.
  py_norm<-reticulate::py_call(
    etpy_get_export("functional_trapezoid_weights"),
    time=reticulate::r_to_py(c(0,1,3)),
    normalize=as.integer(1L))
  expect_equal(as.numeric(et_to_r(py_norm)),
    c(.5,1.5,1)/3,tolerance=1e-15)
  expect_equal(etr_trapezoid_weights(c(0,1,3),normalize=1L),
    c(.5,1.5,1),tolerance=0)
  expect_true(etr_native_parity_catalog()$source_contract_gap_unresolved[
    etr_native_parity_catalog()$python_name==
      "functional_trapezoid_weights"])
})

test_that("published Python 1.2 graphics return Matplotlib axes not R data",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python Matplotlib backend boundary witness is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  mpl<-reticulate::import("matplotlib")
  mpl$use("Agg")
  plt<-reticulate::import("matplotlib.pyplot")
  on.exit(plt$close("all"),add=TRUE)
  types<-reticulate::import("types")
  pd<-reticulate::import("pandas")
  table<-pd$DataFrame(reticulate::r_to_py(list(
    embedding_dimension=c(2L,3L,4L),
    false_neighbor_fraction=c(.5,.3,.1))))
  obj<-types$SimpleNamespace(table=table,curve_id="example",
    dimension="x")
  py_plot<-reticulate::py_call(
    etpy_get_export("plot_embedding_dimension_diagnostics"),
    result=obj)
  expect_true(reticulate::py_has_attr(py_plot,"figure"))
  expect_true(reticulate::py_has_attr(py_plot,"plot"))
  r_obj<-structure(list(table=data.frame(
    embedding_dimension=c(2L,3L,4L),
    false_neighbor_fraction=c(.5,.3,.1)),
    curve_id="example",dimension="x"),
    class="etr_embedding_dimension_diagnostics")
  grDevices::pdf(tempfile(fileext=".pdf"))
  on.exit(grDevices::dev.off(),add=TRUE)
  r_plot<-etr_plot_embedding_dimension_diagnostics(r_obj)
  expect_true(is.data.frame(r_plot))
  expect_false(inherits(r_plot,"python.builtin.object"))
  expect_true(all(etr_native_parity_catalog()$
    one_to_one_native_contract_complete==FALSE))
})
