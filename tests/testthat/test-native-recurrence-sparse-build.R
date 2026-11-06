# Native fixed-radius 1D sparse constructors: source geometry and bounds.
.test_sparse_construction_fixture <- function(values) {
  etr_trajectory_set(seq(0,by=.5,length.out=length(values)),
    array(as.numeric(values),dim=c(1L,length(values),1L)),
    curve_ids="trial_1",dimension_names="x",
    coordinate_system="normalized",time_unit="s")
}

.test_sparse_construction_dense <- function(z) {
  out<-matrix(FALSE,nrow(z$matrix),ncol(z$matrix))
  entries<-Matrix::summary(z$matrix)
  if(is.data.frame(entries)&&nrow(entries)>0L)
    out[cbind(entries$i,entries$j)]<-TRUE
  out
}

test_that("one-dimensional sparse auto construction retains threshold and Theiler",{
  testthat::skip_if_not_installed("Matrix")
  x<-.test_sparse_construction_fixture(c(0,1,.05,3,3.05,8,9))
  dense<-etr_recurrence_matrix(x,curve=1L,radius=.1,theiler=1L)
  sparse<-etr_recurrence_matrix(x,curve=1L,radius=.1,theiler=1L,
    sparse_output=TRUE)
  expect_true(inherits(sparse$matrix,"sparseMatrix"))
  expect_equal(.test_sparse_construction_dense(sparse),dense$matrix,tolerance=0)
  expect_equal(sparse$recurrence_rate,dense$recurrence_rate,tolerance=0)
  expect_equal(sparse$eligible_pairs,dense$eligible_pairs,tolerance=0)
  expect_equal(sum(.test_sparse_construction_dense(sparse)),2)
  expect_identical(sparse$kind,"auto")
  for(m in c("euclidean","cityblock","chebyshev"))
    expect_equal(etr_recurrence_matrix(x,curve=1L,radius=.1,
      theiler=1L,metric=m,sparse_output=TRUE)$matrix,
      sparse$matrix,tolerance=0)
})

test_that("inclusive zero radius, repeated states and empty edges are exact",{
  testthat::skip_if_not_installed("Matrix")
  x<-.test_sparse_construction_fixture(c(0,2,0,3,3,5))
  dense<-etr_recurrence_matrix(x,radius=0,theiler=0)
  sparse<-etr_recurrence_matrix(x,radius=0,theiler=0,sparse_output=TRUE)
  expect_equal(.test_sparse_construction_dense(sparse),dense$matrix,tolerance=0)
  empty<-etr_recurrence_matrix(x,radius=.1,theiler=2L,
    sparse_output=TRUE)
  expect_true(inherits(empty$matrix,"sparseMatrix"))
  expect_identical(empty$kind,"auto")
  expect_error(etr_recurrence_matrix(x,target_recurrence_rate=.2,
    sparse_output=TRUE),"fixed radius")
  xy<-x
  xy$values<-array(rep(c(0,1),each=length(x$time)),
    dim=c(1L,length(x$time),2L))
  xy$dimension_names<-c("x","y")
  expect_error(etr_recurrence_matrix(xy,radius=1,
    sparse_output=TRUE),"one-dimensional")
})

test_that("rectangular sparse cross construction equals dense at fixed radius",{
  testthat::skip_if_not_installed("Matrix")
  a<-matrix(c(0,1,2,3,4),ncol=1)
  b<-matrix(c(.01,1.02,2.2,3.05),ncol=1)
  dense<-etr_cross_recurrence_matrix(a,b,radius=.1)
  sparse<-etr_cross_recurrence_matrix(a,b,radius=.1,
    sparse_output=TRUE)
  expect_true(inherits(sparse$matrix,"sparseMatrix"))
  expect_equal(.test_sparse_construction_dense(sparse),dense$matrix,tolerance=0)
  expect_equal(sparse$recurrence_rate,dense$recurrence_rate,tolerance=0)
  expect_equal(sparse$eligible_pairs,dense$eligible_pairs,tolerance=0)
  expect_identical(sparse$kind,"cross")
  expect_error(etr_cross_recurrence_matrix(a,b,
    target_recurrence_rate=.2,sparse_output=TRUE),"fixed radius")
  expect_error(etr_cross_recurrence_matrix(a,b,
    radius=.1,metric="wrong",sparse_output=TRUE),"metric must be")
  expect_error(etr_cross_recurrence_matrix(cbind(a,a),cbind(b,b),
    radius=.1,sparse_output=TRUE),"one-dimensional")
})

test_that("large 1D source matrices avoid dense allocation limits",{
  testthat::skip_if_not_installed("Matrix")
  n<-12005L
  x<-.test_sparse_construction_fixture(seq.int(0L,n-1L))
  auto<-etr_recurrence_matrix(x,radius=.49,sparse_output=TRUE)
  expect_identical(dim(auto$matrix),c(n,n))
  expect_equal(auto$recurrence_rate,0,tolerance=0)
  expect_equal(auto$eligible_pairs,as.double(n)*(n-1)/2,tolerance=0)
  expect_equal(Matrix::nnzero(auto$matrix),0L)
  a<-matrix(seq.int(0L,2999L),ncol=1)
  b<-matrix(seq.int(10000L,12999L),ncol=1)
  cross<-etr_cross_recurrence_matrix(a,b,radius=.49,sparse_output=TRUE)
  expect_identical(dim(cross$matrix),c(3000L,3000L))
  expect_equal(cross$recurrence_rate,0,tolerance=0)
  expect_equal(cross$eligible_pairs,9e6,tolerance=0)
})

test_that("published Python 1.2 fixed-radius 1D recurrence matrices agree",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 sparse constructor oracle is opt-in")
  testthat::skip_if_not_installed("Matrix")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("\nimport numpy as np\nimport eyetrajectoriespy as et\ntime=np.arange(7,dtype=float)*.5\nvalues=np.array([0.,1.,.05,3.,3.05,8.,9.],dtype=float)\nt=et.TrajectorySet(time=time,values=values[None,:,None],curve_ids=('trial_1',),dimension_names=('x',),coordinate_system='normalized',time_unit='s')\nauto_source=et.recurrence_matrix(t,curve=0,radius=.1,theiler_window=1,dimensions=('x',))\nother=et.TrajectorySet(time=time,values=(values+.03)[None,:,None],curve_ids=('trial_2',),dimension_names=('x',),coordinate_system='normalized',time_unit='s')\ncross_source=et.cross_recurrence_matrix(t,other,curve_a=0,curve_b=0,radius=.1,dimensions_a=('x',),dimensions_b=('x',))\n")
  native<-.test_sparse_construction_fixture(c(0,1,.05,3,3.05,8,9))
  other<-.test_sparse_construction_fixture(c(0,1,.05,3,3.05,8,9)+.03)
  a<-etr_recurrence_matrix(native,radius=.1,theiler=1L,
    dimensions="x",sparse_output=TRUE)
  b<-etr_cross_recurrence_matrix(native,other,radius=.1,
    dimensions_a="x",dimensions_b="x",curve_a=1L,curve_b=1L,
    sparse_output=TRUE)
  # Evaluate sparse-to-dense conversion INSIDE Python. Extracting a SciPy
  # boolean CSR object through reticulate first can construct an invalid
  # R dgRMatrix (logical x slot where numeric is required).
  reticulate::py_run_string(paste(
    "auto_numeric_array = auto_source.matrix.toarray().astype(np.int32)",
    "cross_numeric_array = cross_source.matrix.toarray().astype(np.int32)",
    "auto_numeric_rate = float(auto_source.achieved_recurrence_rate)",
    "cross_numeric_rate = float(cross_source.achieved_recurrence_rate)",
    sep="\n"
  ))
  # NumPy numeric arrays enter R as ordinary matrices, not SciPy CSR objects.
  py_a<-as.matrix(reticulate::py$auto_numeric_array)!=0L
  py_b<-as.matrix(reticulate::py$cross_numeric_array)!=0L
  expect_equal(.test_sparse_construction_dense(a),py_a,tolerance=0)
  expect_equal(.test_sparse_construction_dense(b),py_b,tolerance=0)
  expect_equal(a$recurrence_rate,
    as.numeric(reticulate::py$auto_numeric_rate),
    tolerance=1e-14)
  expect_equal(b$recurrence_rate,
    as.numeric(reticulate::py$cross_numeric_rate),
    tolerance=1e-14)
})
