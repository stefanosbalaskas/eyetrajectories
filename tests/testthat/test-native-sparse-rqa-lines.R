# Frozen Python 1.2 recurrence.py and joint_recurrence.py line-RQA.
# Sparse COO coordinate enumeration must not materialize n-by-n arrays.
.etr_sparse_rqa_large_fixture <- function() {
  n<-12005L
  left<-c(1L,2L,1L,100L,101L)
  right<-c(2L,3L,3L,101L,102L)
  m<-Matrix::sparseMatrix(i=c(left,right),j=c(right,left),
    x=rep(TRUE,10L),dims=c(n,n))
  rec<-structure(list(matrix=m,kind="auto",time=as.numeric(seq_len(n)),
    time_unit="s",theiler=0L,radius=.1,
    recurrence_rate=5/(n*(n-1)/2),state_dimension=1L,
    provenance=list()),class="etr_recurrence")
  list(rec=rec,joint=etr_joint_recurrence_matrix(list(rec,rec),
    labels=c("one","two")))
}

.etr_sparse_rqa_compare <- function(a,b) {
  keys<-c("recurrence_rate","determinism","mean_diagonal_length",
    "max_diagonal_length","diagonal_entropy","laminarity",
    "trapping_time","max_vertical_length","center_of_recurrence_mass",
    "n_recurrence_points","n_diagonal_lines","n_vertical_lines",
    "min_diagonal_length","min_vertical_length")
  for(nm in keys) {
    # Legacy dense native R uses NA for undefined lines; frozen Python and
    # the new sparse engine use NaN. Both represent unavailable statistics.
    if(is.numeric(a[[nm]]) && is.numeric(b[[nm]]) &&
       length(a[[nm]])==1L && length(b[[nm]])==1L &&
       is.na(a[[nm]]) && is.na(b[[nm]])) next
    expect_equal(a[[nm]],b[[nm]],tolerance=1e-12,info=nm)
  }
}

test_that("sparse line-RQA preserves all source-style counts beyond 2500 nodes", {
  testthat::skip_if_not_installed("Matrix")
  z<-.etr_sparse_rqa_large_fixture()
  direct<-etr_rqa_metrics(z$rec)
  joint<-etr_joint_rqa_metrics(z$joint)
  .etr_sparse_rqa_compare(direct,joint)
  expect_true(isTRUE(joint$provenance$native_sparse_rqa))
  expect_true(isFALSE(joint$provenance$dense_materialized))
  expect_equal(joint$determinism,4/5,tolerance=1e-14)
  expect_equal(joint$laminarity,4/10,tolerance=1e-14)
  expect_identical(joint$n_recurrence_points,5L)
  expect_identical(joint$n_diagonal_lines,2L)
  expect_identical(joint$n_vertical_lines,2L)
  expect_equal(joint$mean_diagonal_length,2,tolerance=0)
  expect_equal(joint$max_diagonal_length,2L,tolerance=0)
  expect_equal(joint$diagonal_entropy,0,tolerance=0)
  expect_equal(joint$trapping_time,2,tolerance=0)
  expect_equal(joint$max_vertical_length,2L,tolerance=0)
  expect_equal(joint$center_of_recurrence_mass,
    100*6/(12004*5),tolerance=1e-14)
  # Tightened line lengths must change counted diagonal and vertical runs.
  q<-etr_joint_rqa_metrics(z$joint,3L,3L)
  expect_equal(q$determinism,0,tolerance=0)
  expect_equal(q$laminarity,0,tolerance=0)
  expect_true(is.nan(q$diagonal_entropy))
  expect_true(is.nan(q$trapping_time))
  expect_equal(q$max_diagonal_length,0L,tolerance=0)
  expect_equal(q$max_vertical_length,0L,tolerance=0)
})

test_that("sparse RQA equals dense on small synchronized graphs and rejects bad grids", {
  testthat::skip_if_not_installed("Matrix")
  n<-12L
  a<-matrix(FALSE,n,n)
  edges<-rbind(c(1,3),c(2,4),c(3,5),c(7,9),c(8,10),c(10,12))
  for(k in seq_len(nrow(edges))) {
    i<-edges[k,1];j<-edges[k,2];a[i,j]<-TRUE;a[j,i]<-TRUE
  }
  dense<-structure(list(matrix=a,kind="auto",time=as.numeric(0:(n-1L)),
    time_unit="s",theiler=1L,recurrence_rate=6/(choose(n,2)-(n-1)),
    state_dimension=1L),class="etr_recurrence")
  sparse<-dense;sparse$matrix<-Matrix::Matrix(a,sparse=TRUE)
  x<-etr_joint_rqa_metrics(etr_joint_recurrence_matrix(list(dense,dense)))
  y<-etr_joint_rqa_metrics(etr_joint_recurrence_matrix(list(sparse,sparse)))
  .etr_sparse_rqa_compare(x,y)
  bad<-sparse;bad$time[6L]<-bad$time[5L]+.3
  expect_error(etr_rqa_metrics(bad),"approximately regular")
  bad<-sparse;bad$theiler<-2L
  expect_error(etr_rqa_metrics(bad),"Theiler")
  empty<-sparse;empty$matrix<-Matrix::Matrix(matrix(FALSE,n,n),sparse=TRUE)
  empty$recurrence_rate<-0
  z<-etr_rqa_metrics(empty)
  for(nm in c("determinism","laminarity","mean_diagonal_length",
    "diagonal_entropy","trapping_time","center_of_recurrence_mass"))
    expect_true(is.nan(z[[nm]]),info=nm)
})

test_that("empty sparse inputs preserve source undefined line metrics", {
  testthat::skip_if_not_installed("Matrix")
  n<-12L
  empty_matrix<-Matrix::Matrix(matrix(FALSE,n,n),sparse=TRUE)
  rec<-structure(list(matrix=empty_matrix,kind="auto",
    time=as.numeric(0:(n-1L)),time_unit="s",theiler=0L,
    radius=.1,recurrence_rate=0,state_dimension=1L,provenance=list()),
    class="etr_recurrence")
  direct<-etr_rqa_metrics(rec)
  expect_identical(direct$n_recurrence_points,0L)
  expect_identical(direct$n_diagonal_lines,0L)
  expect_identical(direct$n_vertical_lines,0L)
  for(field in c("determinism","laminarity","mean_diagonal_length",
    "diagonal_entropy","trapping_time","center_of_recurrence_mass")) {
    expect_true(is.nan(direct[[field]]),info=field)
  }
  joint<-etr_joint_recurrence_matrix(list(rec,rec),labels=c("a","b"))
  expect_equal(joint$joint_recurrence_rate,0,tolerance=0)
  expect_identical(joint$n_joint_recurrent_pairs,0L)
  .etr_sparse_rqa_compare(direct,etr_joint_rqa_metrics(joint))
  network<-etr_recurrence_network(rec,adjacency_storage="sparse")
  expect_identical(network$edge_count,0L)
  expect_identical(network$n_connected_components,n)
  expect_true(all(network$degree==0L))
  expect_true(is.nan(network$transitivity))
  expect_equal(network$isolated_node_fraction,1,tolerance=0)
  # Validate the native zero-edge representation also converts under the
  # old bounded-dense path (no S4 -> dense dispatch assumptions).
  dense<-etr_recurrence_network(rec,adjacency_storage="dense")
  expect_true(is.matrix(dense$adjacency))
  expect_true(all(!dense$adjacency))
})

test_that("frozen Python 1.2 matches empty sparse RQA boundary", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned source Python 1.2 zero-edge oracle is opt-in")
  testthat::skip_if_not_installed("Matrix")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
from scipy.sparse import csr_matrix
import eyetrajectoriespy as et
n=12
t=np.arange(n,dtype=float)
r=et.RecurrenceResult(matrix=csr_matrix((n,n),dtype=bool),
    time_a=t,time_b=t,source_curve_ids=('a',),radius=.1,
    target_recurrence_rate=None,achieved_recurrence_rate=0.,
    metric='euclidean',theiler_window_samples=0,kind='auto',
    state_dimension=1,time_unit='s')
py_empty=et.joint_rqa_metrics(et.joint_recurrence_matrix((r,r)))
py_network=et.recurrence_network(r)
")
  rec<-structure(list(matrix=Matrix::Matrix(matrix(FALSE,12L,12L),sparse=TRUE),
    kind="auto",time=as.numeric(0:11),time_unit="s",theiler=0L,
    radius=.1,recurrence_rate=0,state_dimension=1L,provenance=list()),
    class="etr_recurrence")
  native<-etr_joint_rqa_metrics(etr_joint_recurrence_matrix(list(rec,rec)))
  for(nm in c("determinism","laminarity","mean_diagonal_length",
    "diagonal_entropy","trapping_time","center_of_recurrence_mass")) {
    expected<-as.numeric(et_to_r(reticulate::py_get_attr(
      reticulate::py$py_empty,nm)))
    expect_true(is.nan(expected),info=paste("Python",nm))
    expect_true(is.nan(native[[nm]]),info=paste("native",nm))
  }
  expect_equal(as.numeric(native$recurrence_rate),
    as.numeric(et_to_r(reticulate::py$py_empty$recurrence_rate)),tolerance=0)
  expect_equal(etr_recurrence_network(rec,adjacency_storage="sparse")$edge_count,
    as.integer(et_to_r(reticulate::py$py_network$edge_count)),tolerance=0)
})

test_that("frozen Python 1.2 sparse joint RQA agrees on every numeric field", {
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned source Python 1.2 sparse RQA oracle is opt-in")
  testthat::skip_if_not_installed("Matrix")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
from scipy.sparse import csr_matrix
import eyetrajectoriespy as et
n=12005
i=np.array([0,1,0,99,100,1,2,2,100,101],dtype=int)
j=np.array([1,2,2,100,101,0,1,0,99,100],dtype=int)
a=csr_matrix((np.ones(10,dtype=bool),(i,j)),shape=(n,n))
t=np.arange(n,dtype=float)
p=5/(n*(n-1)/2)
r=et.RecurrenceResult(matrix=a,time_a=t,time_b=t,source_curve_ids=('one',),radius=.1,target_recurrence_rate=None,achieved_recurrence_rate=p,metric='euclidean',theiler_window_samples=0,kind='auto',state_dimension=1,time_unit='s')
jr=et.joint_recurrence_matrix((r,r),labels=('one','two'))
pyr=et.joint_rqa_metrics(jr)
")
  z<-.etr_sparse_rqa_large_fixture()
  native<-etr_joint_rqa_metrics(z$joint)
  keys<-c("recurrence_rate","determinism","mean_diagonal_length",
    "max_diagonal_length","diagonal_entropy","laminarity",
    "trapping_time","max_vertical_length","center_of_recurrence_mass",
    "n_recurrence_points","n_diagonal_lines","n_vertical_lines",
    "min_diagonal_length","min_vertical_length")
  for(nm in keys) {
    expected<-as.numeric(et_to_r(reticulate::py_get_attr(
      reticulate::py$pyr,nm)))
    expect_equal(as.numeric(native[[nm]]),expected,tolerance=1e-12,info=nm)
  }
  expect_equal(native$n_recurrence_points,as.integer(et_to_r(
    reticulate::py$jr$n_joint_recurrent_pairs)),tolerance=0)
  # Numeric source agreement is bounded; CSR/dataclass vs Matrix/S3 remains.
})
