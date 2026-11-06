# Frozen Python 1.2 recurrence_networks.py / joint_recurrence.py:
# distinguish source-side sparse semantics from R Matrix/S3 representation.

.etr_sparse_input_fixture <- function() {
  n<-8L
  z<-array(0,c(2L,n,1L))
  z[1L,,1L]<-c(0,0,0,1,1,2,2,2)
  z[2L,,1L]<-c(0,0,1,1,1,2,2,2)
  x<-etr_trajectory_set(as.numeric(0:7),z,c("A","B"),"x",time_unit="s")
  a<-etr_recurrence_matrix(x,curve="A",radius=.01,theiler=1L)
  b<-etr_recurrence_matrix(x,curve="B",radius=.01,theiler=1L)
  a_sparse<-a;b_sparse<-b
  a_sparse$matrix<-Matrix::Matrix(a$matrix,sparse=TRUE)
  b_sparse$matrix<-Matrix::Matrix(b$matrix,sparse=TRUE)
  list(x=x,a=a,b=b,a_sparse=a_sparse,b_sparse=b_sparse)
}

# Coerce small test matrices explicitly from stored nonzero triplets.
# Avoid optional Matrix's S3 as.matrix dispatch inside package load_all().
.etr_sparse_test_dense <- function(x) {
  nz<-Matrix::summary(methods::as(x,"generalMatrix"))
  out<-matrix(FALSE,nrow(x),ncol(x))
  if(nrow(nz))out[cbind(nz$i,nz$j)]<-TRUE
  out
}

test_that("sparse source adjacency preserves native graph and joint RQA", {
  testthat::skip_if_not_installed("Matrix")
  z<-.etr_sparse_input_fixture()
  graph_dense<-etr_recurrence_network(z$a)
  graph_sparse<-etr_recurrence_network(z$a_sparse,adjacency_storage="sparse")
  expect_true(inherits(graph_sparse$adjacency,"sparseMatrix"))
  expect_equal(.etr_sparse_test_dense(graph_sparse$adjacency),graph_dense$adjacency,tolerance=0)
  for(nm in c("degree","normalized_degree","local_clustering",
      "component_labels","component_sizes","edge_count","graph_density",
      "transitivity","mean_local_clustering","n_connected_components",
      "largest_component_fraction","isolated_node_fraction"))
    expect_equal(graph_sparse[[nm]],graph_dense[[nm]],tolerance=0,info=nm)
  expect_identical(graph_sparse$provenance$native_source_matrix_storage,"sparse")
  expect_identical(graph_sparse$provenance$sparse_input_preserved_without_dense_copy,TRUE)
  graph_source_dense<-etr_recurrence_network(z$a_sparse)
  expect_equal(graph_source_dense$adjacency,graph_dense$adjacency,tolerance=0)
  joint_dense<-etr_joint_recurrence_matrix(list(z$a,z$b),labels=c("A","B"))
  joint_sparse<-etr_joint_recurrence_matrix(list(z$a_sparse,z$b_sparse),labels=c("A","B"))
  joint_mixed<-etr_joint_recurrence_matrix(list(z$a_sparse,z$b),labels=c("A","B"))
  for(j in list(joint_sparse,joint_mixed)) {
    expect_true(inherits(j$matrix,"sparseMatrix"))
    expect_equal(.etr_sparse_test_dense(j$matrix),joint_dense$matrix,tolerance=0)
    expect_equal(j$n_joint_recurrent_pairs,joint_dense$n_joint_recurrent_pairs,tolerance=0)
    expect_equal(j$joint_recurrence_rate,joint_dense$joint_recurrence_rate,tolerance=0)
    expect_equal(etr_joint_recurrence_component_frame(j),
      etr_joint_recurrence_component_frame(joint_dense),tolerance=0)
    metrics<-etr_joint_rqa_metrics(j)
    baseline<-etr_joint_rqa_metrics(joint_dense)
    for(key in c("recurrence_rate","determinism","laminarity",
      "mean_diagonal_length","max_diagonal_length","diagonal_entropy",
      "trapping_time","max_vertical_length","center_of_recurrence_mass"))
      expect_equal(metrics[[key]],baseline[[key]],tolerance=0,info=key)
  }
  bad<-z$a_sparse
  # [1,2] is Theiler-excluded in this fixture and cannot prove asymmetry.
  # Convert to sparse *general* storage so only one directed entry changes.
  bad$matrix<-methods::as(bad$matrix,"generalMatrix")
  expect_true(as.logical(bad$matrix[1L,3L]))
  expect_true(as.logical(bad$matrix[3L,1L]))
  bad$matrix[1L,3L]<-FALSE
  expect_true(as.logical(bad$matrix[3L,1L]))
  expect_error(etr_recurrence_network(bad,adjacency_storage="sparse"),"symmetric")
  bad<-z$a_sparse
  bad$matrix<-methods::as(bad$matrix,"generalMatrix")
  bad$matrix[1L,1L]<-TRUE
  expect_error(etr_recurrence_network(bad,adjacency_storage="sparse"),
    "main diagonal")
  bad<-z$a_sparse;bad$theiler<-2L
  expect_error(etr_recurrence_network(bad,adjacency_storage="sparse"),"Theiler")
  bad<-z$a_sparse;bad$time[1L]<-100
  expect_error(etr_recurrence_network(bad,adjacency_storage="sparse"),"increasing")
})

test_that("sparse recurrence inputs scale beyond the dense source domain", {
  testthat::skip_if_not_installed("Matrix")
  n<-12005L
  first<-c(1L,2L,1L,100L,101L)
  second<-c(2L,3L,3L,101L,102L)
  adj<-Matrix::sparseMatrix(i=c(first,second),j=c(second,first),
    x=rep(TRUE,2L*length(first)),dims=c(n,n))
  rec<-structure(list(matrix=adj,kind="auto",time=as.numeric(seq_len(n)),
    time_unit="s",theiler=0L,radius=.1,recurrence_rate=5/(n*(n-1)/2),
    state_dimension=1L,provenance=list()),class="etr_recurrence")
  graph<-etr_recurrence_network(rec,adjacency_storage="sparse")
  expect_true(inherits(graph$adjacency,"sparseMatrix"))
  expect_equal(graph$edge_count,5L,tolerance=0)
  expect_identical(graph$degree[c(1L,2L,3L,100L,101L,102L)],
    c(2L,2L,2L,1L,2L,1L))
  expect_equal(graph$transitivity,3/4,tolerance=1e-14)
  expect_identical(graph$n_connected_components,n-4L)
  # Component IDs follow ascending discovery order. Node 4 is an isolate,
  # so the first two component sizes are 3 and 1, not 3 and 3.
  expect_identical(sum(graph$component_sizes == 3L),2L)
  expect_identical(sum(graph$component_sizes == 1L),n-6L)
  expect_identical(sort(graph$component_sizes,decreasing=TRUE)[1:2],
    c(3L,3L))
  # Both declared groups are internally connected and mutually distinct.
  expect_identical(length(unique(graph$component_labels[1:3])),1L)
  expect_identical(length(unique(graph$component_labels[100:102])),1L)
  expect_false(identical(graph$component_labels[1L],
    graph$component_labels[100L]))
  expect_equal(graph$isolated_node_fraction,(n-6)/n,tolerance=0)
  expect_error(etr_recurrence_network(rec),"2500")
  # A sparse joint is computed on the original graph, never a dense square.
  j<-etr_joint_recurrence_matrix(list(rec,rec),labels=c("one","two"))
  expect_true(inherits(j$matrix,"sparseMatrix"))
  expect_equal(j$n_joint_recurrent_pairs,5L,tolerance=0)
  expect_equal(j$joint_recurrence_rate,5/(n*(n-1)/2),tolerance=1e-14)
  expect_error(etr_joint_rqa_metrics(j),"2500")
})

test_that("pinned Python 1.2 joint sparse CSR agrees with native Matrix", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("frozen Python 1.2 joint CSR numerical replay is opt-in")
  testthat::skip_if_not_installed("Matrix")
  expect_identical(et_python_version(),"1.2.0")
  z<-.etr_sparse_input_fixture()
  ctor<-etpy_get_export("TrajectorySet")
  py_x<-reticulate::py_call(ctor,time=z$x$time,
    values=reticulate::r_to_py(z$x$values),
    curve_ids=as.list(z$x$curve_ids),dimension_names=as.list(z$x$dimension_names),
    coordinate_system="unknown",time_unit="s")
  py_rec<-etpy_get_export("recurrence_matrix")
  pa<-reticulate::py_call(py_rec,source=py_x,curve=as.integer(0L),
    radius=.01,theiler_window=as.integer(1L),dimensions=as.list("x"))
  pb<-reticulate::py_call(py_rec,source=py_x,curve=as.integer(1L),
    radius=.01,theiler_window=as.integer(1L),dimensions=as.list("x"))
  pj<-reticulate::py_call(etpy_get_export("joint_recurrence_matrix"),
    recurrences=list(pa,pb),labels=as.list(c("A","B")))
  native<-etr_joint_recurrence_matrix(list(z$a_sparse,z$b_sparse),
    labels=c("A","B"))
  expect_equal(unname(.etr_sparse_test_dense(native$matrix)*1L),
    unname(as.matrix(et_to_r(pj$matrix$toarray()))*1L),tolerance=0)
  expect_equal(native$joint_recurrence_rate,
    as.numeric(et_to_r(pj$joint_recurrence_rate)),tolerance=1e-12)
  expect_equal(native$n_joint_recurrent_pairs,
    as.integer(et_to_r(pj$n_joint_recurrent_pairs)),tolerance=0)
  expect_equal(native$eligible_pair_count,
    as.integer(et_to_r(pj$eligible_pair_count)),tolerance=0)
  expect_equal(etr_joint_rqa_metrics(native)$recurrence_rate,
    as.numeric(et_to_r(reticulate::py_call(
      etpy_get_export("joint_rqa_metrics"),result=pj)$recurrence_rate)),
    tolerance=1e-12)
  # This source replay does not certify pandas/CSR/Python class identity.
})
