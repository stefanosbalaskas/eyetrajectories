# Frozen eyetrajectoriespy 1.2.0 analysis.py::
# fit_scalar_on_function_regression scientific native source contracts.
# Source commit: c1cd95ad718327550f7e55393ff38582872f7a94.
# Developer evidence only, not independently certified.

.etr_scalar_fpca_source_fixture <- function(){
  t<-seq(0,1,length.out=11L);n<-24L
  v<-array(0,c(n,length(t),2L))
  for(i in seq_len(n)){
    v[i,,1L]<-sin(2*pi*t)+i*.07*t+cos(.19*i)*.45
    v[i,,2L]<-cos(2*pi*t)+i*.04*t+sin(.31*i)*.65
  }
  x<-etr_trajectory_set(t,v,paste0("s",seq_len(n)),
    c("x","y"),coordinate_system="unknown",time_unit="s")
  fit<-etr_fit_mfpca(x,n_components=2L)
  cov<-data.frame(exposure=sin(seq_len(n)*.4),
    condition=rep(c(0,1,0,1,1,0),length.out=n))
  y<-as.numeric(.3 + fit$scores[,1L]*.47 -
    fit$scores[,2L]*.14 + cov$exposure*.7 -
    cov$condition*.28 + .03*cos(seq_len(n)))
  binary<-rep(c(0L,1L,1L,0L,1L,0L),length.out=n)
  list(x=x,fit=fit,cov=cov,y=y,binary=binary)
}

test_that("native original Gaussian score regression remains unchanged by default",{
  f<-.etr_scalar_fpca_source_fixture()
  result<-etr_fit_scalar_on_fpca(f$fit,f$y)
  expect_s3_class(result,"etr_scalar_on_fpca")
  expect_identical(result$method,"gaussian_scalar_on_fpca_scores")
  expect_equal(length(stats::fitted(result$model)),24L)
  expect_error(etr_fit_scalar_on_fpca(f$fit,f$binary,
    family="binomial"),"python_boundary_mode")
  expect_error(etr_fit_scalar_on_fpca(f$fit,f$y,
    covariates=f$cov),"python_boundary_mode")
})

test_that("native Python 1.2 Gaussian scalar regression has full named geometry",{
  f<-.etr_scalar_fpca_source_fixture()
  fit<-etr_fit_scalar_on_fpca(f$fit,f$y,n_components=2L,
    covariates=f$cov,python_boundary_mode=TRUE)
  expect_s3_class(fit,"etr_scalar_on_fpca")
  expect_identical(fit$family,"gaussian")
  expect_identical(names(fit$coefficients),
    c("const","FPC1","FPC2","exposure","condition"))
  expect_identical(fit$component_indices,as.integer(c(0,1)))
  expect_equal(length(fit$predictions),24L)
  expect_true(all(is.finite(fit$coefficients)))
  expect_true(all(is.finite(fit$predictions)))
  expect_equal(as.numeric(stats::fitted(fit$model)),
    fit$predictions,tolerance=1e-12)
  expect_equal(etr_predict_scalar_on_fpca(fit,f$x,covariates=f$cov),
    fit$predictions,tolerance=1e-8)
  expect_error(etr_predict_scalar_on_fpca(fit,f$x),
    "matching covariates")
  bad<-f$cov;bad$exposure[2L]<-NA_real_
  expect_error(etr_fit_scalar_on_fpca(f$fit,f$y,n_components=2L,
    covariates=bad,python_boundary_mode=TRUE),"finite numeric")
  expect_error(etr_fit_scalar_on_fpca(f$fit,f$y,n_components=1,
    python_boundary_mode=TRUE),"Python integer or Boolean")
  bool<-etr_fit_scalar_on_fpca(f$fit,f$y,n_components=TRUE,
    python_boundary_mode=TRUE)
  expect_identical(bool$n_components,1L)
  expect_equal(length(bool$coefficients),2L)
})

test_that("native Python 1.2 binomial scalar regression uses logit and predicts probabilities",{
  f<-.etr_scalar_fpca_source_fixture()
  bin<-etr_fit_scalar_on_fpca(f$fit,f$binary,n_components=2L,
    family="binomial",covariates=f$cov,python_boundary_mode=TRUE)
  expect_identical(bin$family,"binomial")
  expect_true(all(bin$predictions>0&bin$predictions<1))
  expect_equal(as.numeric(stats::fitted(bin$model)),bin$predictions,
    tolerance=1e-12)
  expect_equal(etr_predict_scalar_on_fpca(bin,f$x,covariates=f$cov),
    bin$predictions,tolerance=1e-7)
  wrong<-f$binary;wrong[1L]<-2L
  expect_error(etr_fit_scalar_on_fpca(f$fit,wrong,
    family="binomial",python_boundary_mode=TRUE),"0/1 values")
  expect_error(etr_fit_scalar_on_fpca(f$fit,f$y,n_components=2L,
    family="poisson",python_boundary_mode=TRUE),"family")
  dependent<-data.frame(duplicate=f$fit$scores[,1L])
  expect_error(etr_fit_scalar_on_fpca(f$fit,f$y,n_components=2L,
    covariates=dependent,python_boundary_mode=TRUE),"full-rank")
})

test_that("direct frozen Python 1.2 Gaussian/binomial regression agrees on coefficients and fits",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("Frozen Python Gaussian/binomial regression source oracle opt-in")
  expect_identical(et_python_version(),"1.2.0")
  f<-.etr_scalar_fpca_source_fixture()
  types<-reticulate::import("types",convert=FALSE)
  py_fit<-types$SimpleNamespace(
    scores=reticulate::r_to_py(f$fit$scores),
    curve_ids=reticulate::r_to_py(f$fit$curve_ids),
    n_components=as.integer(f$fit$n_components))
  for(family in c("gaussian","binomial")){
    outcome<-if(identical(family,"gaussian"))f$y else f$binary
    native<-etr_fit_scalar_on_fpca(f$fit,outcome,n_components=2L,
      family=family,covariates=f$cov,python_boundary_mode=TRUE)
    source<-reticulate::py_call(
      etpy_get_export("fit_scalar_on_function_regression"),
      fpca=py_fit,outcome=reticulate::r_to_py(outcome),
      n_components=as.integer(2L),family=family,
      covariates=reticulate::r_to_py(f$cov))
    expected_coef<-as.numeric(et_to_r(source$coefficients))
    expected_pred<-as.numeric(et_to_r(source$predictions))
    expect_equal(unname(native$coefficients),unname(expected_coef),
      tolerance=if(identical(family,"binomial"))1e-6 else 1e-10)
    expect_equal(unname(native$predictions),unname(expected_pred),
      tolerance=if(identical(family,"binomial"))1e-6 else 1e-10)
    expect_identical(native$provenance$n_components,2L)
    expect_identical(native$provenance$family,family)
    expect_identical(native$provenance$covariates,names(f$cov))
  }
  expect_false(any(etr_native_parity_catalog()$
    one_to_one_native_contract_complete))
})
