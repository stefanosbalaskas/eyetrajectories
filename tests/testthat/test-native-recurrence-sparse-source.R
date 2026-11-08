# Frozen eyetrajectoriespy 1.2.0 recurrence_networks.py numerical oracle.
# Native Matrix::lgCMatrix is an R analogue, NOT Python SciPy CSR identity.

.etr_sparse_net_fixture <- function() {
  values <- array(c(0,0,0,5,5,11), c(1L,6L,1L))
  x <- etr_trajectory_set(as.numeric(0:5), values, "curve", "x",
    coordinate_system="unknown", time_unit="s")
  list(x=x, rec=etr_recurrence_matrix(x,curve=1L,radius=.01,theiler=0L))
}

test_that("native sparse adjacency preserves full graph statistics and frames", {
  testthat::skip_if_not_installed("Matrix")
  z <- .etr_sparse_net_fixture()
  dense <- etr_recurrence_network(z$rec)
  sparse <- etr_recurrence_network(z$rec,adjacency_storage="sparse")
  expect_true(inherits(sparse$adjacency,"sparseMatrix"))
  expect_true(is.logical(as.matrix(sparse$adjacency)))
  expect_identical(as.matrix(sparse$adjacency),dense$adjacency)
  for(nm in c("degree","normalized_degree","local_clustering",
      "component_labels","component_sizes","edge_count","graph_density",
      "transitivity","mean_local_clustering","n_connected_components",
      "largest_component_fraction","isolated_node_fraction"))
    expect_equal(sparse[[nm]],dense[[nm]],tolerance=0,info=nm)
  expect_identical(sparse$provenance$dense_adjacency_materialized,FALSE)
  expect_identical(sparse$provenance$native_adjacency_storage,"sparse")
  expect_identical(sparse$provenance$scipy_csr_identity_claimed,FALSE)
  expect_identical(dense$provenance$dense_adjacency_materialized,TRUE)
  expect_equal(etr_recurrence_network_node_frame(sparse),
    etr_recurrence_network_node_frame(dense),tolerance=0)
  expect_equal(etr_recurrence_network_summary_frame(sparse),
    etr_recurrence_network_summary_frame(dense),tolerance=0)
  expect_error(etr_recurrence_network(z$rec,adjacency_storage="graph"),
    "arg")
})

test_that("sparse storage extends native graph domain beyond dense cap", {
  testthat::skip_if_not_installed("Matrix")
  n <- 2501L
  rec <- structure(list(matrix=matrix(FALSE,n,n),kind="auto",
    time=as.numeric(seq_len(n)),time_unit="s",theiler=0L,
    radius=.5,recurrence_rate=0,provenance=list(),state_dimension=1L),
    class="etr_recurrence")
  expect_error(etr_recurrence_network(rec),"2500 nodes")
  graph <- etr_recurrence_network(rec,adjacency_storage="sparse")
  expect_true(inherits(graph$adjacency,"sparseMatrix"))
  expect_identical(dim(graph$adjacency),c(n,n))
  expect_identical(graph$edge_count,0L)
  expect_identical(graph$n_connected_components,n)
  expect_identical(graph$component_sizes,rep(1L,n))
  expect_true(is.nan(graph$transitivity))
  expect_equal(graph$isolated_node_fraction,1,tolerance=0)
})

test_that("published Python 1.2 sparse CSR network numerical oracle agrees", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Pinned Python 1.2 graph source replay is opt-in")
  testthat::skip_if_not_installed("Matrix")
  expect_identical(et_python_version(),"1.2.0")
  z <- .etr_sparse_net_fixture()
  ctor <- etpy_get_export("TrajectorySet")
  py_x <- reticulate::py_call(ctor,time=z$x$time,
    values=reticulate::r_to_py(z$x$values),
    curve_ids=as.list(z$x$curve_ids),
    dimension_names=as.list(z$x$dimension_names),
    coordinate_system="unknown",time_unit="s")
  py_rec <- reticulate::py_call(etpy_get_export("recurrence_matrix"),
    source=py_x,curve=as.integer(0L),radius=.01,
    theiler_window=as.integer(0L),dimensions=as.list("x"))
  py_net <- reticulate::py_call(etpy_get_export("recurrence_network"),
    recurrence=py_rec)
  net <- etr_recurrence_network(z$rec,adjacency_storage="sparse")
  py_adj <- et_to_r(py_net$adjacency$toarray())
  expect_equal(unname(as.matrix(net$adjacency)*1L),
    unname(as.matrix(py_adj)*1L),tolerance=0)
  for(nm in c("degree","normalized_degree","local_clustering",
      "component_labels","component_sizes","edge_count","graph_density",
      "transitivity","mean_local_clustering","n_connected_components",
      "largest_component_fraction","isolated_node_fraction"))
    expect_equal(as.numeric(net[[nm]]),
      as.numeric(et_to_r(reticulate::py_get_attr(py_net,nm))),
      tolerance=1e-12,info=nm)
  for(spec in list(c("recurrence_network_node_frame","node"),
                   c("recurrence_network_summary_frame","summary"))){
    source <- et_to_r(reticulate::py_call(etpy_get_export(spec[1L]),
      result=py_net))
    native <- if(identical(spec[2L],"node"))
      etr_recurrence_network_node_frame(net) else
      etr_recurrence_network_summary_frame(net)
    expect_identical(names(native),names(source))
    for(nm in names(native)) {
      if(is.numeric(native[[nm]]))
        expect_equal(as.numeric(native[[nm]]),as.numeric(source[[nm]]),
          tolerance=1e-12,info=nm)
      else expect_identical(as.character(native[[nm]]),
        as.character(source[[nm]]))
    }
  }
  # This test covers a fixed scientific domain; source contracts stay open.
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
