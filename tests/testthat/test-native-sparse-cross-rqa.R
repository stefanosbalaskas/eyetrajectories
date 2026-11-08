# Frozen Python eyetrajectoriespy==1.2.0: sparse cross-RQA source contract.
.sparse_cross_rqa_case <- function() {
  nr<-7L; nc<-9L
  i<-c(1L,2L,3L,3L,4L,5L,6L,1L,2L)
  j<-c(2L,3L,4L,7L,8L,9L,9L,6L,7L)
  m<-matrix(FALSE,nr,nc);m[cbind(i,j)]<-TRUE
  list(rec=structure(list(
    matrix=Matrix::Matrix(m,sparse=TRUE),kind="cross",
    time_a=seq(0,by=.5,length.out=nr),
    time_b=seq(0,by=.5,length.out=nc),time_unit="s",
    recurrence_rate=sum(m)/length(m),
    provenance=list(),theiler=NA_integer_),class="etr_recurrence"),
    matrix=m,i=i,j=j)
}

.test_sparse_cross_rqa_fields <- function(native,source) {
  keys<-c("recurrence_rate","determinism","mean_diagonal_length",
    "max_diagonal_length","diagonal_entropy","laminarity",
    "trapping_time","max_vertical_length","center_of_recurrence_mass",
    "n_recurrence_points","n_diagonal_lines","n_vertical_lines",
    "min_diagonal_length","min_vertical_length")
  for (name in keys) {
    a<-as.numeric(native[[name]]);b<-as.numeric(source[[name]])
    if(length(a)==1L && length(b)==1L && is.na(a) && is.na(b)) next
    expect_equal(a,b,tolerance=1e-12,info=name)
  }
}

test_that("native sparse cross RQA matches dense rectangular line counts",{
  testthat::skip_if_not_installed("Matrix")
  z<-.sparse_cross_rqa_case()
  sparse<-etr_rqa_metrics(z$rec)
  dense<-z$rec;dense$matrix<-z$matrix
  old<-etr_rqa_metrics(dense)
  for(name in names(old)) {
    if(!is.numeric(old[[name]]))next
    a<-as.numeric(sparse[[name]]);b<-as.numeric(old[[name]])
    if(length(a)==1L && length(b)==1L && is.na(a) && is.na(b))next
    expect_equal(a,b,tolerance=1e-12,info=name)
  }
  wrapper<-etr_cross_rqa_metrics(z$rec)
  .test_sparse_cross_rqa_fields(wrapper,sparse)
  expect_true(isTRUE(wrapper$provenance$native_sparse_rqa))
  expect_false(isTRUE(wrapper$provenance$dense_materialized))
  expect_true(is.nan(sparse$center_of_recurrence_mass))
  expect_identical(sparse$n_recurrence_points,as.integer(sum(z$matrix)))
  # Tightening the line threshold changes counts, never source geometry.
  tight<-etr_rqa_metrics(z$rec,3L,3L)
  expect_true(tight$determinism<=sparse$determinism)
  expect_true(tight$laminarity<=sparse$laminarity)
})

test_that("sparse cross RQA enforces source time grids and empty input",{
  testthat::skip_if_not_installed("Matrix")
  z<-.sparse_cross_rqa_case()
  x<-z$rec
  x$time_a[4]<-x$time_a[3]+.2
  expect_error(etr_rqa_metrics(x),"approximately regular")
  x<-z$rec;x$time_b<-seq(0,by=.7,length.out=9)
  expect_error(etr_rqa_metrics(x),"matching sampling steps")
  x<-z$rec;x$time_a<-NULL
  expect_error(etr_rqa_metrics(x),"first time grid")
  x<-z$rec;x$matrix<-Matrix::Matrix(matrix(FALSE,7,9),sparse=TRUE)
  x$recurrence_rate<-0
  empty<-etr_rqa_metrics(x)
  for(key in c("determinism","laminarity","mean_diagonal_length",
    "diagonal_entropy","trapping_time","center_of_recurrence_mass"))
    expect_true(is.nan(empty[[key]]),info=key)
  expect_identical(empty$n_recurrence_points,0L)
  expect_identical(empty$n_diagonal_lines,0L)
  expect_identical(empty$n_vertical_lines,0L)
})

test_that("frozen Python 1.2 sparse cross RQA agrees on 14 result fields",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("source Python 1.2 CSR oracle opt-in")
  testthat::skip_if_not_installed("Matrix")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("\nimport numpy as np\nimport eyetrajectoriespy as et\nfrom scipy.sparse import csr_matrix\ni=np.array([0,1,2,2,3,4,5,0,1],dtype=int)\nj=np.array([1,2,3,6,7,8,8,5,6],dtype=int)\na=csr_matrix((np.ones(i.size,dtype=bool),(i,j)),shape=(7,9))\nr=et.RecurrenceResult(matrix=a,time_a=np.arange(7)*.5,time_b=np.arange(9)*.5,source_curve_ids=('a','b'),radius=.5,target_recurrence_rate=None,achieved_recurrence_rate=float(i.size/(7*9)),metric='euclidean',theiler_window_samples=0,kind='cross',state_dimension=1,time_unit='s')\nsource=et.rqa_metrics(r)\n")
  z<-.sparse_cross_rqa_case()
  native<-etr_rqa_metrics(z$rec)
  keys<-c("recurrence_rate","determinism","mean_diagonal_length",
    "max_diagonal_length","diagonal_entropy","laminarity",
    "trapping_time","max_vertical_length","center_of_recurrence_mass",
    "n_recurrence_points","n_diagonal_lines","n_vertical_lines",
    "min_diagonal_length","min_vertical_length")
  for(nm in keys) {
    expected<-as.numeric(et_to_r(reticulate::py_get_attr(reticulate::py$source,nm)))
    actual<-as.numeric(native[[nm]])
    if(is.na(actual)&&is.na(expected))next
    expect_equal(actual,expected,tolerance=1e-12,info=nm)
  }
  reticulate::py_run_string("\nempty=csr_matrix((7,9),dtype=bool)\nfrom dataclasses import replace\nempty_source=et.rqa_metrics(replace(r,matrix=empty,achieved_recurrence_rate=0.))\n")
  x<-z$rec;x$matrix<-Matrix::Matrix(matrix(FALSE,7,9),sparse=TRUE)
  x$recurrence_rate<-0
  expect_true(is.nan(etr_rqa_metrics(x)$determinism))
  expect_true(is.nan(as.numeric(et_to_r(reticulate::py$empty_source$determinism))))
})
