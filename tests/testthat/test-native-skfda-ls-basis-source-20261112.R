# Pinned eyetrajectoriespy==1.2.0 backends.py::to_skfda_basis
# and scikit-fda BasisSmoother unweighted observed-grid least squares.
# This suite excludes native Python FDataBasis class identity.

.etr_scikit_basis_fixture<-function(){
  time<-seq(2,4,length.out=25L)
  x<-array(0,c(5L,length(time),1L))
  for(i in 1:5)
    x[i,,1L]<-i/4+.3*sin(2*pi*time/2)+
      (.05*i)*cos(4*pi*time/2)+.01*time
  list(time=time,values=x,trajectories=etr_trajectory_set(time,x,
    paste0("c",1:5),"x",time_unit="seconds"))
}

test_that("scikit Fourier basis uses normalized source orientation and odd expansion",{
  f<-.etr_scikit_basis_fixture()
  out<-etr_to_skfda_basis(f$trajectories,"x",basis="fourier",
    n_basis=4L,strict_source_record=TRUE)
  expect_s3_class(out,"etr_skfda_basis_scientific_record")
  expect_s3_class(out,"etr_native_basis_projection")
  expect_identical(out$n_basis,4L)
  expect_identical(out$actual_backend_n_basis,5L)
  expect_identical(dim(out$basis_matrix),c(25L,5L))
  expect_identical(dim(out$coefficient_matrix),c(5L,5L))
  expect_equal(out$basis_matrix[,1L],rep(1/sqrt(2),25L))
  expect_equal(out$basis_matrix[,2L],
    sin(2*pi*f$time/2),tolerance=1e-12)
  expect_equal(out$basis_matrix[,3L],
    cos(2*pi*f$time/2),tolerance=1e-12)
  expect_equal(out$basis_matrix[,4L],
    sin(4*pi*f$time/2),tolerance=1e-12)
  expect_equal(out$basis_matrix[,5L],
    cos(4*pi*f$time/2),tolerance=1e-12)
  expect_equal(out$fitted_functions,
    out$coefficient_matrix%*%t(out$basis_matrix),tolerance=1e-12)
  expect_identical(out$source_projection$n_basis,4L)
  expect_identical(out$source_projection$basis_type,"fourier")
  expect_identical(out$source_projection$dimension,"x")
  expect_equal(out$source_projection$time_domain,c(2,4))
  expect_null(out$source_projection$provenance$basis_projection$order)
  expect_identical(out$source_projection$provenance$basis_projection$backend,
    "scikit-fda")
  expect_identical(out$dataset_name,"eyetrajectoriespy x")
  expect_false(out$source_equivalent)
  expect_false(out$independently_source_certified)
  expect_null(out$source_projection$backend_object)
  expect_false(out$full_backend_object_identity)
  # Old R basis remains unchanged without an opt-in.
  original<-etr_to_skfda_basis(f$trajectories,"x",basis="fourier",
    n_basis=4L)
  expect_s3_class(original,"etr_native_basis_projection")
  expect_false(inherits(original,"etr_skfda_basis_scientific_record"))
  expect_identical(dim(original$basis_matrix),c(25L,4L))
})

test_that("scikit B-spline source design uses repeated boundary knots",{
  f<-.etr_scikit_basis_fixture()
  out<-etr_to_skfda_basis(f$trajectories,"x",
    basis="bspline",n_basis=6L,order=3L,
    strict_source_record=TRUE)
  expect_identical(dim(out$basis_matrix),c(25L,6L))
  expect_identical(dim(out$coefficient_matrix),c(5L,6L))
  expect_equal(rowSums(out$basis_matrix),rep(1,25L),
    tolerance=1e-12)
  expect_identical(as.numeric(out$basis_matrix[25L,]),
    c(0,0,0,0,0,1))
  expect_equal(out$basis_knots,seq(2,4,length.out=5L))
  expect_identical(length(out$evaluation_knots),9L)
  expect_identical(out$order,3L)
  expect_identical(out$source_projection$provenance$
    basis_projection$order,3L)
  expect_identical(out$source_backend_basis_class,
    "skfda.representation.basis.BSplineBasis")
  expect_equal(out$fitted_functions,
    out$coefficient_matrix%*%t(out$basis_matrix),
    tolerance=1e-12)
})

test_that("scikit source QR projection recovers exact known Fourier and spline coefficients",{
  f<-.etr_scikit_basis_fixture()
  for(family in c("fourier","bspline")){
    n<-if(family=="fourier")5L else 6L
    B<-if(family=="fourier")
      .etr_skfda_source_fourier(f$time,n)$B
    else .etr_skfda_source_bspline(f$time,n,3L)$B
    coef<-matrix(seq_len(3L*n)/9,nrow=3L,ncol=n)
    y<-coef%*%t(B)
    arr<-array(as.numeric(y),c(3L,length(f$time),1L))
    # R matrix is column-major while the explicit array index order is
    # curve, time, dimension, matching generated y entries exactly.
    tr<-etr_trajectory_set(f$time,arr,c("A","B","C"),"x")
    got<-etr_to_skfda_basis(tr,"x",basis=family,n_basis=n,
      order=3L,strict_source_record=TRUE)
    expect_equal(got$coefficient_matrix,coef,tolerance=1e-10,
      ignore_attr=TRUE,info=family)
    expect_equal(got$fitted_functions,y,tolerance=1e-10,
      ignore_attr=TRUE,info=family)
  }
})

test_that("strict scikit basis enforces bounded source rank, completeness and control domain",{
  f<-.etr_scikit_basis_fixture()
  run<-function(...)etr_to_skfda_basis(f$trajectories,"x",
    strict_source_record=TRUE,...)
  expect_error(run(basis="wavelets"),"bspline.*fourier")
  expect_error(run(basis="fourier",n_basis=26L),"sufficient observed time")
  expect_error(run(basis="bspline",n_basis=3L,order=4L),
    "n_basis must be at least order")
  expect_error(run(n_basis=1L),"n_basis")
  expect_error(run(order=0L),"order")
  expect_error(run(n_basis=5L,order=NA_real_),"order")
  expect_error(etr_to_skfda_basis(f$trajectories,"unknown",
    strict_source_record=TRUE),"Unknown dimension")
  expect_error(etr_to_skfda_basis(f$trajectories,"x",
    strict_source_record=NA),"strict_source_record")
  incomplete<-f$values
  incomplete[1L,2L,1L]<-NA_real_
  tr<-etr_trajectory_set(f$time,incomplete,
    paste0("c",1:5),"x")
  expect_error(etr_to_skfda_basis(tr,"x",
    strict_source_record=TRUE),"complete observations")
  # No repair of original observations is permitted.
  expect_identical(f$trajectories$values,f$values)
})

test_that("actual frozen Python 1.2 to_skfda_basis matches native normalized Fourier and spline coefficients",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("opt-in frozen Python 1.2 with real pinned scikit-fda required")
  skip_if_not_installed("reticulate")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
import skfda
from skfda.representation.basis import BSplineBasis, FourierBasis
t=np.linspace(2.,4.,25)
y=np.empty((5,len(t),1))
for i in range(5):
    y[i,:,0]=(i+1)/4+.3*np.sin(2*np.pi*t/2)+(
       .05*(i+1))*np.cos(4*np.pi*t/2)+.01*t
tr=et.TrajectorySet(time=t,values=y,
    curve_ids=tuple('c'+str(i+1) for i in range(5)),
    dimension_names=('x',),time_unit='seconds')
raw={}
for family,n,order in (('fourier',4,4),('bspline',6,3)):
    result=et.to_skfda_basis(tr,dimension='x',basis=family,
        n_basis=n,order=order)
    obj=result.backend_object
    raw[family]=dict(
      coefficients=np.asarray(obj.coefficients),
      fitted=np.asarray(obj(t))[:,:,0],
      source_n_basis=result.n_basis,
      backend_n_basis=obj.basis.n_basis,
      time_domain=np.asarray(result.time_domain),
      backend_type=type(obj).__name__,
      basis_matrix=np.asarray(obj.basis(t)).T)
")
  f<-.etr_scikit_basis_fixture()
  for(family in c("fourier","bspline")){
    req<-if(family=="fourier")4L else 6L
    ord<-if(family=="fourier")4L else 3L
    ours<-etr_to_skfda_basis(f$trajectories,"x",basis=family,
      n_basis=req,order=ord,strict_source_record=TRUE)
    source<-reticulate::py_eval(paste0("raw['",family,"']"),convert=TRUE)
    expect_equal(ours$coefficient_matrix,
      as.matrix(source$coefficients),tolerance=1e-8,
      ignore_attr=TRUE,info=paste(family,"coefficients"))
    expect_equal(ours$fitted_functions,
      as.matrix(source$fitted),tolerance=1e-8,
      ignore_attr=TRUE,info=paste(family,"reconstructed values"))
    expect_equal(ours$basis_matrix,
      as.matrix(source$basis_matrix),tolerance=1e-8,
      ignore_attr=TRUE,info=paste(family,"basis values"))
    expect_equal(ours$n_basis,as.integer(source$source_n_basis))
    expect_equal(ours$actual_backend_n_basis,
      as.integer(source$backend_n_basis))
    expect_identical(source$backend_type,"FDataBasis")
    expect_equal(ours$domain_range,
      as.numeric(source$time_domain),tolerance=0)
  }
})
