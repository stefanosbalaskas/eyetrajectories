# Pinned Python 1.2.0 read-only IAAFT and mixed-effects diagnostic frames.
# Plotting tests exercise R graphic output, not Matplotlib axes equivalence.
.etr_source_diagnostic_fixtures <- function(extended=FALSE) {
  surrogate<-list(n_surrogates=3L,reference_dimension="x",
    convergence_iterations=c(4L,5L,6L),
    spectral_errors=matrix(c(.1,.2,.3,.4,.5,.6),3,2,byrow=TRUE),
    cross_spectral_errors=matrix(c(.03,.07,.11),3,1))
  cov<-array(0,dim=c(2L,2L,2L))
  cov[1L,,]<-diag(c(1,2))
  cov[2L,,]<-diag(c(3,4))
  boot<-list(
    bootstrap_coefficient_functions=array(0,dim=c(2L,1L,2L)),
    residual_variances=c(1,2),
    log_likelihoods=c(-20,-21),
    random_effect_covariance_eigenvalues=
      matrix(c(1,2,3,4),nrow=2,byrow=TRUE),
    random_effect_covariances=cov,
    random_effect_covariance_condition_numbers=c(2,3),
    random_effect_boundary_flags=c(FALSE,TRUE),
    random_effect_singular_flags=c(FALSE,FALSE),
    random_slope_boundary_flags=c(FALSE,FALSE),
    convergence_flags=c(TRUE,FALSE),
    backend_warnings=list(character(),c("warning a","warning b")),
    random_intercept_covariances=cov/2)
  if(extended){
    boot$residual_correlation_parameters<-c(.1,.2)
    boot$residual_correlation_condition_numbers<-c(1.1,1.2)
    boot$residual_correlation_boundary_flags<-c(FALSE,TRUE)
    boot$residual_correlation_independence_flags<-c(FALSE,FALSE)
    boot$trial_random_effect_covariances<-cov/4
    boot$trial_random_effect_covariance_eigenvalues<-
      matrix(c(.25,.5,.75,1),nrow=2,byrow=TRUE)
    boot$trial_random_effect_covariance_condition_numbers<-c(2,3)
    boot$trial_random_effect_boundary_flags<-c(FALSE,FALSE)
    boot$trial_random_effect_singular_flags<-c(FALSE,FALSE)
    boot$random_slope_covariances<-cov/3
    boot$random_intercept_slope_covariances<-cov/5
  }
  list(surrogate=surrogate,bootstrap=boot,
    nonlinearity=list(surrogate_statistics=c(.1,.2,.3,.4,.5),
      observed_statistic=.36,statistic="joint_recurrence",p_value=.2))
}

test_that("diagnostics frames retain frozen source ordering and fields",{
  z<-.etr_source_diagnostic_fixtures()
  a<-etr_multivariate_iaaft_diagnostics_frame(z$surrogate)
  expect_identical(names(a),c("surrogate","iterations",
    "max_spectral_error","max_cross_spectral_error",
    "mean_spectral_error","mean_cross_spectral_error"))
  expect_equal(a$surrogate,0:2)
  expect_equal(a$max_spectral_error,c(.2,.4,.6))
  expect_equal(a$mean_spectral_error,c(.15,.35,.55))
  expect_equal(a$max_cross_spectral_error,c(.03,.07,.11))
  b<-etr_functional_mixed_effects_variance_bootstrap_frame(z$bootstrap)
  expect_equal(b$bootstrap_replicate,0:1)
  expect_equal(b$covariance_trace,c(3,7))
  expect_equal(b$random_intercept_covariance_trace,c(1.5,3.5))
  expect_identical(b$backend_warning_count,c(0L,2L))
  expect_identical(ncol(b),13L)
  extra<-etr_functional_mixed_effects_variance_bootstrap_frame(
    .etr_source_diagnostic_fixtures(TRUE)$bootstrap)
  expect_identical(ncol(extra),25L)
  expect_equal(extra$trial_covariance_trace,c(.75,1.75))
  expect_equal(extra$random_slope_covariance_trace,c(1,7/3))
  expect_true("intercept_slope_cross_covariance_frobenius"%in%names(extra))
})

test_that("diagnostics frames fail closed on invalid source domains",{
  z<-.etr_source_diagnostic_fixtures()
  bad<-z$surrogate;bad$spectral_errors<-matrix(1:5,5,1)
  expect_error(etr_multivariate_iaaft_diagnostics_frame(bad),
    "spectral_errors")
  bad<-z$surrogate;bad$convergence_iterations<-c(1,1.5,2)
  expect_error(etr_multivariate_iaaft_diagnostics_frame(bad),
    "convergence_iterations")
  bad<-z$surrogate;bad$cross_spectral_errors[1,1]<-NaN
  expect_error(etr_multivariate_iaaft_diagnostics_frame(bad),
    "cross_spectral_errors")
  bad<-z$bootstrap;bad$random_effect_covariances[1,1,1]<-Inf
  expect_error(etr_functional_mixed_effects_variance_bootstrap_frame(bad),
    "random_effect_covariances")
  bad<-z$bootstrap;bad$backend_warnings<-list("bad")
  expect_error(etr_functional_mixed_effects_variance_bootstrap_frame(bad),
    "backend_warnings")
  bad<-z$bootstrap;bad$residual_correlation_parameters<-c(.1,.2)
  expect_error(etr_functional_mixed_effects_variance_bootstrap_frame(bad),
    "residual_correlation_condition_numbers")
  bad<-z$nonlinearity;bad$p_value<-1.5
  expect_error(etr_plot_multivariate_surrogate_nonlinearity(bad),
    "p_value")
})

test_that("new diagnostics plots write base graphics and retain geometry",{
  z<-.etr_source_diagnostic_fixtures()
  path<-tempfile(fileext=".pdf")
  grDevices::pdf(path)
  on.exit({
    if(grDevices::dev.cur()>1L)grDevices::dev.off()
    unlink(path)
  },add=TRUE)
  first<-etr_plot_multivariate_iaaft_diagnostics(z$surrogate)
  expect_equal(first$surrogate,0:2)
  expect_equal(first$max_spectral_error,c(.2,.4,.6))
  second<-etr_plot_multivariate_surrogate_nonlinearity(
    z$nonlinearity,bins=4L)
  expect_equal(sum(second$histogram$counts),5)
  expect_length(second$histogram$counts,4L)
  expect_equal(second$observed_statistic,.36)
  expect_error(etr_plot_multivariate_surrogate_nonlinearity(
    z$nonlinearity,bins=1L),"bins")
})

test_that("two numeric diagnostics tables remain unsigned native counterparts",{
  names<-c("multivariate_iaaft_diagnostics_frame",
    "functional_mixed_effects_variance_bootstrap_frame",
    "plot_multivariate_iaaft_diagnostics",
    "plot_multivariate_surrogate_nonlinearity")
  p<-etr_native_parity_catalog()
  rows<-p[p$is_python_function & p$python_name%in%names,,drop=FALSE]
  expect_equal(nrow(rows),4L)
  expect_identical(sort(rows$native_r_candidate),sort(paste0("etr_",names)))
  expect_true(all(rows$native_implementation_started))
  expect_true(all(rows$source_contract_gap_unresolved))
  expect_false(any(rows$one_to_one_native_contract_complete))
  expect_equal(sum(p$is_python_function&p$named_native_candidate),304L)
  expect_equal(sum(p$native_implementation_started),279L)
  expect_equal(sum(p$source_contract_gap_unresolved),126L)
})

test_that("two diagnostic frames exactly match frozen Python 1.2 data tables",{
  if(!identical(Sys.getenv("ET_RUN_PYTHON_TESTS"),"true"))
    skip("pinned Python 1.2 diagnostic dataframe source oracle is opt-in")
  expect_identical(et_python_version(),"1.2.0")
  reticulate::py_run_string("
import numpy as np
import eyetrajectoriespy as et
def _df_obj(cls, **items):
    x=object.__new__(cls)
    for k,v in items.items(): object.__setattr__(x,k,v)
    return x
_df_surrogate=_df_obj(et.MultivariateIAAFTResult,
    n_surrogates=3,reference_dimension='x',
    convergence_iterations=np.array([4,5,6]),
    spectral_errors=np.array([[.1,.2],[.3,.4],[.5,.6]]),
    cross_spectral_errors=np.array([[.03],[.07],[.11]]))
_df_cov=np.array([np.diag([1.,2.]),np.diag([3.,4.])])
_df_boot=dict(
    bootstrap_coefficient_functions=np.zeros((2,1,2)),
    residual_variances=np.array([1.,2.]),
    log_likelihoods=np.array([-20.,-21.]),
    random_effect_covariance_eigenvalues=np.array([[1.,2.],[3.,4.]]),
    random_effect_covariances=_df_cov,
    random_effect_covariance_condition_numbers=np.array([2.,3.]),
    random_effect_boundary_flags=np.array([False,True]),
    random_effect_singular_flags=np.array([False,False]),
    random_slope_boundary_flags=np.array([False,False]),
    convergence_flags=np.array([True,False]),
    backend_warnings=((),('warning a','warning b')),
    random_intercept_covariances=_df_cov/2,
    residual_correlation_parameters=None,
    trial_random_effect_covariances=None,
    random_slope_covariances=None)
_df_full=_df_obj(et.FunctionalMixedEffectsFullRefitBootstrapResult,
    **_df_boot)
_df_more=dict(_df_boot,
    residual_correlation_parameters=np.array([.1,.2]),
    residual_correlation_condition_numbers=np.array([1.1,1.2]),
    residual_correlation_boundary_flags=np.array([False,True]),
    residual_correlation_independence_flags=np.array([False,False]),
    trial_random_effect_covariances=_df_cov/4,
    trial_random_effect_covariance_eigenvalues=np.array(
      [[.25,.5],[.75,1.]]),
    trial_random_effect_covariance_condition_numbers=np.array([2.,3.]),
    trial_random_effect_boundary_flags=np.array([False,False]),
    trial_random_effect_singular_flags=np.array([False,False]),
    random_slope_covariances=_df_cov/3,
    random_intercept_slope_covariances=_df_cov/5)
_df_extended=_df_obj(et.FunctionalMixedEffectsFullRefitBootstrapResult,
    **_df_more)
_df_oracle={
    'surrogate':et.multivariate_iaaft_diagnostics_frame(_df_surrogate),
    'base':et.functional_mixed_effects_variance_bootstrap_frame(_df_full),
    'extended':et.functional_mixed_effects_variance_bootstrap_frame(_df_extended)
}
")
  z<-.etr_source_diagnostic_fixtures()
  outputs<-list(
    surrogate=etr_multivariate_iaaft_diagnostics_frame(z$surrogate),
    base=etr_functional_mixed_effects_variance_bootstrap_frame(
      z$bootstrap),
    extended=etr_functional_mixed_effects_variance_bootstrap_frame(
      .etr_source_diagnostic_fixtures(TRUE)$bootstrap))
  for(n in names(outputs)){
    py<-reticulate::py_eval(paste0("_df_oracle['",n,"']"),
      convert=TRUE)
    expect_identical(names(py),names(outputs[[n]]),info=n)
    expect_equal(nrow(py),nrow(outputs[[n]]),info=n)
    for(column in names(py)) {
      expect_equal(outputs[[n]][[column]],py[[column]],
        tolerance=1e-12,ignore_attr=TRUE,
        info=paste(n,column))
    }
  }
})
