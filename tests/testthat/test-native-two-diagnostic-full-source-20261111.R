# Direct frozen Python eyetrajectoriespy==1.2.0, commit
# c1cd95ad718327550f7e55393ff38582872f7a94.
# Fully typed direct comparisons to native scientific R diagnostic records.
# Zero-row objects specifically exercise the pandas DataFrame([]) schema.

.etr_two_diagnostic_fixtures <- function(variant="base") {
  stopifnot(variant %in% c("base","extended","single","zero"))
  n <- if(variant=="zero") 0L else if(variant=="single") 1L else 3L
  d <- if(variant=="single") 1L else 2L
  spectral <- matrix(seq_len(n*d)/100,nrow=n,ncol=d,byrow=TRUE)
  cross <- matrix(seq_len(n*d)/1000,nrow=n,ncol=d,byrow=TRUE)
  iaaft <- list(n_surrogates=n,
    convergence_iterations=if(n==0L) numeric() else
      as.numeric(c(0,3,7)[seq_len(n)]),
    spectral_errors=spectral,cross_spectral_errors=cross)
  cov <- array(0,dim=c(n,2L,2L))
  if(n>0L){
    for(i in seq_len(n)) cov[i,,] <- diag(c(i,i+1))
  }
  coeff <- array(0,dim=c(n,1L,2L))
  eigen <- matrix(rep(c(.5,1.5),each=n),nrow=n,ncol=2L)
  boot <- list(
    bootstrap_coefficient_functions=coeff,
    residual_variances=as.numeric(seq_len(n)),
    log_likelihoods=as.numeric(-10-seq_len(n)),
    random_effect_covariance_eigenvalues=eigen,
    random_effect_covariances=cov,
    random_effect_covariance_condition_numbers=if(n==0L) numeric()
      else as.numeric(c(2,Inf,3)[seq_len(n)]),
    random_effect_boundary_flags=rep(FALSE,n),
    random_effect_singular_flags=rep(FALSE,n),
    random_slope_boundary_flags=rep(FALSE,n),
    convergence_flags=rep(TRUE,n),
    backend_warnings=lapply(seq_len(n),function(i)
      if(i==2L)c("optimizer","gradient") else character()),
    random_intercept_covariances=cov/2)
  if(variant=="extended"){
    boot$residual_correlation_parameters=c(.1,.2,.3)
    boot$residual_correlation_condition_numbers=c(1.1,Inf,1.3)
    boot$residual_correlation_boundary_flags=c(FALSE,TRUE,FALSE)
    boot$residual_correlation_independence_flags=rep(FALSE,n)
    boot$trial_random_effect_covariances=cov/4
    boot$trial_random_effect_covariance_eigenvalues=eigen/4
    boot$trial_random_effect_covariance_condition_numbers=c(2,Inf,3)
    boot$trial_random_effect_boundary_flags=rep(FALSE,n)
    boot$trial_random_effect_singular_flags=rep(FALSE,n)
    boot$random_slope_covariances=cov/3
    boot$random_intercept_slope_covariances=cov/5
  }
  list(iaaft=iaaft,bootstrap=boot)
}
test_that("zero typed surrogate and variance bootstrap records have source empty schema",{
  z<-.etr_two_diagnostic_fixtures("zero")
  x<-etr_multivariate_iaaft_diagnostics_frame(z$iaaft)
  y<-etr_functional_mixed_effects_variance_bootstrap_frame(z$bootstrap)
  expect_s3_class(x,"data.frame")
  expect_s3_class(y,"data.frame")
  expect_identical(dim(x),c(0L,0L))
  expect_identical(dim(y),c(0L,0L))
  expect_identical(names(x),character())
  expect_identical(names(y),character())
})
test_that("diagnostic science frame source domains cover base and extended covariance",{
  for(variant in c("base","extended","single")){
    z<-.etr_two_diagnostic_fixtures(variant)
    a<-etr_multivariate_iaaft_diagnostics_frame(z$iaaft)
    b<-etr_functional_mixed_effects_variance_bootstrap_frame(z$bootstrap)
    expect_identical(nrow(a),as.integer(z$iaaft$n_surrogates))
    expect_identical(nrow(b),as.integer(dim(z$bootstrap$bootstrap_coefficient_functions)[1L]))
    expect_identical(a$surrogate,seq_len(nrow(a))-1L)
    expect_identical(b$bootstrap_replicate,seq_len(nrow(b))-1L)
    expect_equal(a$max_spectral_error,apply(z$iaaft$spectral_errors,1L,max))
    expect_equal(a$max_cross_spectral_error,
      apply(z$iaaft$cross_spectral_errors,1L,max))
    expect_equal(a$mean_spectral_error,rowMeans(z$iaaft$spectral_errors))
    expect_equal(a$mean_cross_spectral_error,rowMeans(z$iaaft$cross_spectral_errors))
    expect_equal(b$covariance_condition_number,
      z$bootstrap$random_effect_covariance_condition_numbers)
    if(variant=="extended"){
      expect_identical(ncol(b),25L)
      expect_true(is.infinite(b$trial_covariance_condition_number[2L]))
      expect_true(is.infinite(b$residual_correlation_condition_number[2L]))
      expect_equal(b$trial_covariance_trace,c(.75,1.25,1.75))
      expect_equal(b$intercept_slope_cross_covariance_frobenius,
        vapply(seq_len(3L),function(i)
          sqrt(sum(z$bootstrap$random_intercept_slope_covariances[i,,]^2)),
          numeric(1L)))
    }else expect_identical(ncol(b),13L)
  }
})
test_that("native diagnosis rejects malformed source-domain and zero-row shapes",{
  z<-.etr_two_diagnostic_fixtures("zero")
  bad<-z$iaaft;bad$convergence_iterations<-2
  expect_error(etr_multivariate_iaaft_diagnostics_frame(bad),
    "convergence_iterations")
  bad<-z$iaaft;bad$cross_spectral_errors<-matrix(0,nrow=1L,ncol=2L)
  expect_error(etr_multivariate_iaaft_diagnostics_frame(bad),
    "cross_spectral_errors")
  bad<-z$bootstrap;bad$random_effect_covariance_eigenvalues<-
    matrix(0,nrow=1L,ncol=2L)
  expect_error(etr_functional_mixed_effects_variance_bootstrap_frame(bad),
    "random_effect_covariance_eigenvalues")
  z<-.etr_two_diagnostic_fixtures("base")
  bad<-z$iaaft;bad$convergence_iterations[1L]<--1
  expect_error(etr_multivariate_iaaft_diagnostics_frame(bad),
    "convergence_iterations")
  bad<-z$iaaft;bad$spectral_errors[1L,1L]<-Inf
  expect_error(etr_multivariate_iaaft_diagnostics_frame(bad),"spectral_errors")
  bad<-z$bootstrap;bad$random_effect_covariances[1L,1L,1L]<-NaN
  expect_error(etr_functional_mixed_effects_variance_bootstrap_frame(bad),
    "random_effect_covariances")
  bad<-z$bootstrap;bad$backend_warnings[[2L]]<-1L
  expect_error(etr_functional_mixed_effects_variance_bootstrap_frame(bad),
    "backend_warnings")
})
test_that("8 complete typed frozen Python diagnostic frames match native R",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 direct source oracle opt in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string(paste(c(
    "import numpy as np",
    "import eyetrajectoriespy as et",
    "def _etr_diag_typed(cls,**kw):",
    "    x=object.__new__(cls)",
    "    for k,v in kw.items(): object.__setattr__(x,k,v)",
    "    return x",
    "def _etr_two_diag_source(variant):",
    "    n=0 if variant=='zero' else 1 if variant=='single' else 3",
    "    d=1 if variant=='single' else 2",
    "    spectral=np.arange(1,n*d+1,dtype=float).reshape(n,d)/100.",
    "    cross=np.arange(1,n*d+1,dtype=float).reshape(n,d)/1000.",
    "    surrogate=_etr_diag_typed(et.MultivariateIAAFTResult,",
    "      n_surrogates=n,convergence_iterations=np.array([0,3,7][:n]),",
    "      spectral_errors=spectral,cross_spectral_errors=cross)",
    "    cov=np.zeros((n,2,2),dtype=float)",
    "    for i in range(n): cov[i]=np.diag([i+1,i+2])",
    "    eigen=np.tile(np.array([.5,1.5]),(n,1))",
    "    fields=dict(",
    "      bootstrap_coefficient_functions=np.zeros((n,1,2)),",
    "      residual_variances=np.arange(1,n+1,dtype=float),",
    "      log_likelihoods=-10.-np.arange(1,n+1,dtype=float),",
    "      random_effect_covariance_eigenvalues=eigen,",
    "      random_effect_covariances=cov,",
    "      random_effect_covariance_condition_numbers=np.array([2.,np.inf,3.][:n]),",
    "      random_effect_boundary_flags=np.zeros(n,dtype=bool),",
    "      random_effect_singular_flags=np.zeros(n,dtype=bool),",
    "      random_slope_boundary_flags=np.zeros(n,dtype=bool),",
    "      convergence_flags=np.ones(n,dtype=bool),",
    "      backend_warnings=tuple(('optimizer','gradient') if i==1 else () for i in range(n)),",
    "      random_intercept_covariances=cov/2.,",
    "      residual_correlation_parameters=None,",
    "      trial_random_effect_covariances=None,",
    "      random_slope_covariances=None)",
    "    if variant=='extended':",
    "      fields.update(residual_correlation_parameters=np.array([.1,.2,.3]),",
    "        residual_correlation_condition_numbers=np.array([1.1,np.inf,1.3]),",
    "        residual_correlation_boundary_flags=np.array([False,True,False]),",
    "        residual_correlation_independence_flags=np.array([False,False,False]),",
    "        trial_random_effect_covariances=cov/4.,",
    "        trial_random_effect_covariance_eigenvalues=eigen/4.,",
    "        trial_random_effect_covariance_condition_numbers=np.array([2.,np.inf,3.]),",
    "        trial_random_effect_boundary_flags=np.zeros(n,dtype=bool),",
    "        trial_random_effect_singular_flags=np.zeros(n,dtype=bool),",
    "        random_slope_covariances=cov/3.,",
    "        random_intercept_slope_covariances=cov/5.)",
    "    boot=_etr_diag_typed(et.FunctionalMixedEffectsFullRefitBootstrapResult,",
    "      **fields)",
    "    return (et.multivariate_iaaft_diagnostics_frame(surrogate),",
    "      et.functional_mixed_effects_variance_bootstrap_frame(boot))"
  ),collapse="\n"),convert=FALSE)
  oracle<-reticulate::py_get_attr(reticulate::py,"_etr_two_diag_source")
  for(variant in c("base","extended","single","zero")){
    z<-.etr_two_diagnostic_fixtures(variant)
    expected<-reticulate::py_to_r(reticulate::py_call(oracle,variant))
    actual<-list(etr_multivariate_iaaft_diagnostics_frame(z$iaaft),
      etr_functional_mixed_effects_variance_bootstrap_frame(z$bootstrap))
    expect_identical(length(actual),2L)
    for(i in 1:2){
      a<-actual[[i]];b<-expected[[i]]
      expect_identical(names(a),names(b),info=paste(variant,i))
      expect_identical(nrow(a),nrow(b),info=paste(variant,i))
      for(name in names(a)){
        av<-a[[name]];bv<-b[[name]]
        if(is.logical(av))expect_identical(as.logical(av),as.logical(bv),
          info=paste(variant,i,name))
        else expect_equal(as.numeric(av),as.numeric(bv),tolerance=1e-12,
          info=paste(variant,i,name))
      }
    }
  }
})
