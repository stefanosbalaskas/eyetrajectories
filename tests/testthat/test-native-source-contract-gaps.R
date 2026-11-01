# Stage 22 source-contract gap register: published Python 1.2 source is
# explicitly NOT certified by matching scientific plot geometry alone.
test_that("508-contract certificate gate rejects known unresolved source differences",{
  before<-reticulate::py_available(initialize=FALSE)
  z<-etr_native_parity_catalog()
  expect_equal(nrow(z),508L)
  # Preserve the historical gap floor as later scientific methods add gaps.
  # The current exact count is independently checked by the full ledger.
  expect_gte(sum(z$source_contract_gap_known),53L)
  expect_gte(sum(z$source_contract_gap_unresolved),57L)
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

test_that("source Python 1.2 trapezoid scalar truthiness aligns but arbitrary objects and infinities do not",{
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
  # Python source numeric scalar truthiness now agrees with native R.
  # Arbitrary Python objects and extreme source input domains remain open.
  py_norm<-reticulate::py_call(
    etpy_get_export("functional_trapezoid_weights"),
    time=reticulate::r_to_py(c(0,1,3)),
    normalize=as.integer(1L))
  expect_equal(as.numeric(et_to_r(py_norm)),
    c(.5,1.5,1)/3,tolerance=1e-15)
  expect_equal(etr_trapezoid_weights(c(0,1,3),normalize=1L),
    c(.5,1.5,1)/3,tolerance=1e-15)
  expect_equal(etr_trapezoid_weights(c(0,1,3),normalize=.5),
    c(.5,1.5,1)/3,tolerance=1e-15)
  expect_equal(etr_trapezoid_weights(c(0,1,3),normalize=-1),
    c(.5,1.5,1)/3,tolerance=1e-15)
  expect_equal(etr_trapezoid_weights(c(0,1,3),normalize=0),
    c(.5,1.5,1),tolerance=0)
  for(flag in c("yes","0","", "FALSE")) {
    source_flag<-reticulate::py_call(
      etpy_get_export("functional_trapezoid_weights"),
      time=reticulate::r_to_py(c(0,1,3)),
      normalize=flag)
    expect_equal(etr_trapezoid_weights(c(0,1,3),
      normalize=flag),as.numeric(et_to_r(source_flag)),
      tolerance=1e-15)
  }
  expect_error(etr_trapezoid_weights(c(0,1,3),normalize=NA_real_),
    "normalize")
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


# Python-boundary-mode experiments are intentionally separate from the
# finite-only native scientific defaults. No independent approval is implied.
test_that("opt-in source boundary mode matches three known NumPy behaviors",{
  simplex<-array(0,c(2L,2L,3L))
  for(i in 1:2)for(j in 1:2)simplex[i,j,]<-c(.2,.35,.45)
  expect_error(etr_alr_transform(simplex,epsilon=NaN),"epsilon")
  nan_z<-etr_alr_transform(simplex,epsilon=NaN,
    python_boundary_mode=TRUE)
  expect_identical(dim(nan_z),c(2L,2L,2L))
  expect_true(all(is.nan(nan_z)))

  logits<-array(c(1000,-1),c(1L,1L,2L))
  expect_error(etr_inverse_alr(logits,0L,3L),"overflowed")
  extreme<-etr_inverse_alr(logits,0L,3L,
    python_boundary_mode=TRUE)
  expect_identical(dim(extreme),c(1L,1L,3L))
  expect_true(any(is.nan(extreme)))
  expect_true(any(is.finite(extreme)))

  grid<-c(0,1,Inf)
  expect_error(etr_trapezoid_weights(grid),"finite")
  w<-etr_trapezoid_weights(grid,python_boundary_mode=TRUE)
  expect_equal(w[1L],.5,tolerance=0)
  expect_true(all(is.infinite(w[-1L])))
  normalized<-etr_trapezoid_weights(grid,normalize=TRUE,
    python_boundary_mode=TRUE)
  expect_equal(normalized[1L],0,tolerance=0)
  expect_true(all(is.nan(normalized[-1L])))
  expect_equal(etr_trapezoid_weights(c(0,1,3),
    normalize=NaN,python_boundary_mode=TRUE),c(.5,1.5,1)/3,
    tolerance=0)

  expect_error(etr_alr_transform(simplex,
    python_boundary_mode=NA),"python_boundary_mode")
  expect_error(etr_inverse_alr(logits,0L,3L,
    python_boundary_mode=1),"python_boundary_mode")
  expect_error(etr_trapezoid_weights(c(0,1,3),
    python_boundary_mode=c(TRUE,FALSE)),"python_boundary_mode")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("opt-in score boundary mode accepts native duck-typed environment",{
  score<-matrix(c(0,1,2,3,4,5),nrow=3L,ncol=2L)
  obj<-new.env(parent=emptyenv())
  obj$scores<-score
  obj$n_components<-2L
  expect_error(etr_score_distance_matrix(obj),"fpca must provide")
  found<-etr_score_distance_matrix(obj,python_boundary_mode=TRUE)
  reference<-etr_score_distance_matrix(
    list(scores=score,n_components=2L))
  expect_equal(found,reference,tolerance=0)
  expect_true(all(is.finite(found)))
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})

test_that("pinned Python 1.2 exceptional source output agrees in opt-in mode",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python 1.2 boundary-mode paired oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  simplex<-array(0,c(2L,2L,3L))
  for(i in 1:2)for(j in 1:2)simplex[i,j,]<-c(.2,.35,.45)
  python_alr<-reticulate::py_call(etpy_get_export("alr_transform"),
    values=reticulate::r_to_py(simplex),epsilon=NaN)
  native_alr<-etr_alr_transform(simplex,epsilon=NaN,
    python_boundary_mode=TRUE)
  expect_equal(unname(native_alr),unname(et_to_r(python_alr)),
    tolerance=0)
  logits<-array(c(1000,-1),c(1L,1L,2L))
  np<-reticulate::import("numpy",convert=FALSE)
  python_inv<-with(np$errstate(over="ignore",invalid="ignore"),
    reticulate::py_call(etpy_get_export("inverse_alr"),
      transformed=reticulate::r_to_py(logits),
      reference_dimension=as.integer(0L),
      n_dimensions=as.integer(3L)))
  native_inv<-etr_inverse_alr(logits,0L,3L,python_boundary_mode=TRUE)
  expect_identical(is.nan(native_inv),is.nan(et_to_r(python_inv)))
  expect_equal(unname(native_inv),unname(et_to_r(python_inv)),
    tolerance=0)
  python_grid<-reticulate::py_call(
    etpy_get_export("functional_trapezoid_weights"),
    time=reticulate::r_to_py(c(0,1,Inf)))
  native_grid<-etr_trapezoid_weights(c(0,1,Inf),
    python_boundary_mode=TRUE)
  expect_equal(unname(native_grid),unname(et_to_r(python_grid)),
    tolerance=0)
  obj<-new.env(parent=emptyenv())
  obj$scores<-matrix(c(0,1,2,3,4,5),nrow=3L,ncol=2L)
  obj$n_components<-2L
  py_obj<-reticulate::import("types")$SimpleNamespace(
    scores=reticulate::r_to_py(obj$scores),
    n_components=as.integer(obj$n_components))
  python_dist<-reticulate::py_call(
    etpy_get_export("score_distance_matrix"),fpca=py_obj)
  native_dist<-etr_score_distance_matrix(obj,python_boundary_mode=TRUE)
  expect_equal(unname(native_dist),unname(et_to_r(python_dist)),
    tolerance=1e-12)
  # This only closes three particular input/output probes in an optional
  # mode; the frozen default source contracts and 508-wide gate remain open.
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
