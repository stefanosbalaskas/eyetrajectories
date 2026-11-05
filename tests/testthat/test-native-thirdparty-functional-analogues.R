test_that("native backend-independent functional grid is a lossless R object",{
  n<-12L;tt<-seq(0,1,length.out=21L)
  v<-array(0,c(n,21L,2L))
  for(i in seq_len(n)){
    v[i,,1L]<-sin(2*pi*tt)+.02*i*tt
    v[i,,2L]<-cos(2*pi*tt)+.03*i*tt
  }
  x<-etr_trajectory_set(tt,v,paste0("c",seq_len(n)),
    c("x","y"),time_unit="s")
  grid<-etr_to_skfda_grid(x)
  expect_s3_class(grid,"etr_native_functional_grid")
  expect_identical(grid$values,x$values)
  expect_identical(grid$time,x$time)
  expect_identical(grid$dimension_names,x$dimension_names)
  expect_identical(grid$source_object_type,
    "skfda.FDataGrid_NOT_RETURNED")
  expect_false(grid$independently_source_certified)
})

test_that("native functional basis projection calculates explicit LS coefficients",{
  n<-12L;tt<-seq(0,1,length.out=21L)
  v<-array(0,c(n,21L,1L))
  for(i in 1:n)v[i,,1L]<-sin(2*pi*tt)+.01*i*cos(pi*tt)
  x<-etr_trajectory_set(tt,v,paste0("c",seq_len(n)),
    "x",time_unit="s")
  for(family in c("bspline","fourier")){
    proj<-etr_to_skfda_basis(x,"x",basis=family,
      n_basis=7L,order=4L)
    expect_s3_class(proj,"etr_native_basis_projection")
    expect_identical(dim(proj$coefficient_matrix),c(12L,7L))
    expect_identical(dim(proj$fitted_functions),c(12L,21L))
    expect_true(all(is.finite(proj$coefficient_matrix)))
    expect_true(all(is.finite(proj$fitted_functions)))
    expect_equal(proj$fitted_functions,
      proj$coefficient_matrix%*%t(proj$basis_matrix),
      ignore_attr=TRUE,tolerance=1e-10)
    expect_false(proj$source_equivalent)
  }
  expect_error(etr_to_skfda_basis(x,"x",n_basis=30L),
    "observed time")
  expect_error(etr_to_skfda_basis(x,"x",basis="wavelet"),"bspline or fourier")
})

test_that("native functional Tukey outliers remain review-only",{
  n<-12L;tt<-seq(0,1,length.out=21L)
  v<-array(0,c(n,21L,1L))
  for(i in seq_len(n))v[i,,1L]<-.01*i*sin(pi*tt)
  v[12L,,1L]<-10*sin(pi*tt)
  x<-etr_trajectory_set(tt,v,paste0("c",seq_len(n)),
    "x",time_unit="s")
  y<-etr_detect_functional_outliers_skfda(x,"x",factor=1.5)
  expect_s3_class(y,"etr_native_functional_outlier_result")
  expect_true(y$diagnostics$review_flag[12L])
  expect_identical(dim(x$values),c(12L,21L,1L))
  expect_false(y$provenance$source_equivalent)
  expect_error(etr_detect_functional_outliers_skfda(
    x,"x",method="msplot"),"MSPlot")
})

test_that("native irregular channel adapter preserves original times",{
  n<-12L
  time<-lapply(seq_len(n),function(i)
    seq(0,1,length.out=6L)+(i-1)*.001)
  vals<-lapply(seq_len(n),function(i){
    cbind(x=sin(2*pi*time[[i]]),y=cos(2*pi*time[[i]]))
  })
  x<-etr_irregular_trajectory_set(time,vals,
    paste0("c",seq_len(n)),c("x","y"),time_unit="s")
  z<-etr_to_fdapy_irregular(x,"x")
  expect_s3_class(z,"etr_sparse_curves")
  expect_identical(z$times,time)
  expect_true(all(vapply(seq_len(n),function(i)
    identical(z$values[[i]],as.numeric(vals[[i]][,1L])),logical(1L))))
  expect_identical(z$source_python_object_type,
    "FDApy.IrregularFunctionalData_not_returned")
  expect_error(etr_fit_sparse_fpca_fdapy(
    x,"x",n_components=2L),"explicitly choose fdapace")
})

test_that("explicit fdapace sparse alternative never claims FDApy parity",{
  if(!identical(Sys.getenv("ET_RUN_FDAPACE_TESTS"),"true")||
     !requireNamespace("fdapace",quietly=TRUE))
    skip("optional native R fdapace integration numerical smoke opt-in")
  time<-lapply(1:16,function(i)seq(0,1,length.out=8L)+i*.0002)
  v<-lapply(1:16,function(i)
    cbind(x=sin(2*pi*time[[i]])+i*.01*cos(pi*time[[i]])))
  x<-etr_irregular_trajectory_set(time,v,paste0("c",1:16),"x")
  z<-etr_fit_sparse_fpca_fdapy(x,"x",n_components=2L,
    backend="fdapace")
  expect_s3_class(z,"etr_sparse_pace")
  expect_false(z$source_python_equivalent)
  expect_false(z$provenance$independent_source_contract_certified)
})

# Actual frozen-Python 1.2 source-symbol inspection on published exports.
# For alternate R estimands/backends this is NOT numerical source parity.
test_that("unreviewed Python 1.2 source symbols are inspectable: to_skfda_grid, to_skfda_basis, detect_functional_outliers_skfda, to_fdapy_irregular, fit_sparse_fpca_fdapy",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python source-symbol audit requires source runtime")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("to_skfda_grid"),"to_skfda_grid")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("to_skfda_basis"),"to_skfda_basis")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("detect_functional_outliers_skfda"),"detect_functional_outliers_skfda")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("to_fdapy_irregular"),"to_fdapy_irregular")
  .etr_expect_frozen_python_source_symbol(
    etpy_get_export("fit_sparse_fpca_fdapy"),"fit_sparse_fpca_fdapy")
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
