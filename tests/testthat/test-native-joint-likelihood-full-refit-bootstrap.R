# Actual 20+ full Gaussian nlme likelihood refits in a source-aligned
# participant-case bootstrap, not the original timewise moments analogue.
# The test fixture intentionally repeats complete participant permutations:
# each replicate has the same likelihood sufficient statistics but different
# participant source ordering, permitting deterministic recomputation checks.
.etr_joint_full_refit_reference<-function(){
  t<-seq(0,1,length.out=7L)
  ids<-sprintf("curve%02d",seq_len(24L))
  pid<-rep(sprintf("P%02d",seq_len(8L)),each=3L)
  x<-rep(c(-1,0,1),8L)
  y<-array(0,c(24L,7L,1L))
  for(i in seq_len(24L)){
    g<-ceiling(i/3)
    y[i,,1L]<-.7+.23*t+x[i]*(.25-.15*t)+
      .18*sin(g*.6)+.13*cos(g*.31)*t+
      .06*sin(i*.7+t*4)+.035*cos(1.5*i*t)
  }
  tr<-etr_trajectory_set(t,y,ids,"signal",
    metadata=data.frame(pid=pid),
    coordinate_system="degrees",time_unit="s")
  design<-data.frame(curve_id=rev(ids),x=rev(x))
  etr_fit_joint_bspline_functional_mixed_effects(
    tr,design,"x","pid","signal",
    fixed_basis_size=2L,random_basis_size=2L,
    spline_degree=1L,reml=TRUE,maxiter=500L)
}

test_that("joint likelihood full-refit repeats all variance-component fits",{
  skip_if_not_installed("nlme")
  reference<-.etr_joint_full_refit_reference()
  expect_identical(reference$maxiter,500L)
  expect_identical(reference$coordinate_system,"degrees")
  expect_identical(reference$participant_column,"pid")
  selected<-matrix(rep(0:7,times=20L),nrow=20L,byrow=TRUE)
  set.seed(319L)
  old<-.Random.seed
  z<-etr_bootstrap_functional_mixed_effects_full_refit(
    reference,n_bootstrap=20L,random_state=101L,
    sampled_participant_indices=selected)
  expect_identical(.Random.seed,old)
  expect_s3_class(z,"etr_joint_mixed_likelihood_full_refit_bootstrap")
  expect_identical(z$bootstrap_type,"full_refit")
  expect_identical(z$variance_components_refit,TRUE)
  expect_identical(dim(z$bootstrap_fixed_basis_coefficients),
    c(20L,2L,2L))
  expect_identical(dim(z$bootstrap_coefficient_functions),
    c(20L,2L,7L))
  expect_identical(dim(z$random_effect_covariances),
    c(20L,2L,2L))
  expect_identical(dim(z$random_intercept_covariances),
    c(20L,2L,2L))
  expect_identical(dim(z$random_effect_covariance_eigenvalues),
    c(20L,2L))
  expect_identical(z$sampled_participant_indices,selected)
  expect_true(all(z$convergence_flags))
  expect_true(all(is.finite(z$residual_variances)))
  expect_true(all(z$residual_variances>0))
  expect_true(all(is.finite(z$log_likelihoods)))
  expect_true(all(is.finite(z$random_effect_covariances)))
  expect_equal(z$bootstrap_coefficient_functions[1L,,],
    unname(reference$fixed_coefficient_functions),
    tolerance=1e-3,ignore_attr=TRUE)
  expect_equal(z$random_effect_covariances[1L,,],
    unname(reference$random_effect_covariance),
    tolerance=1e-3,ignore_attr=TRUE)
  expect_equal(z$residual_variances[1L],
    reference$residual_variance,tolerance=1e-3)
  expect_equal(z$log_likelihoods[1L],
    as.numeric(stats::logLik(reference$fitted_model)),
    tolerance=1e-3)
  expect_equal(z$bootstrap_mean,
    apply(z$bootstrap_coefficient_functions,c(2L,3L),mean),
    tolerance=1e-12,ignore_attr=TRUE)
  expect_equal(z$bootstrap_standard_errors,
    apply(z$bootstrap_coefficient_functions,c(2L,3L),stats::sd),
    tolerance=1e-12,ignore_attr=TRUE)
  expect_false(z$provenance$
    functional_mixed_effects_full_refit_bootstrap$
    python_statsmodels_optimizer_equivalent)
  expect_false(z$source_python_full_contract_certified)
  expect_false(z$independent_full_source_certified)
})

test_that("joint full-refit rejects source-invalid draws and unsupported domains",{
  skip_if_not_installed("nlme")
  fit<-.etr_joint_full_refit_reference()
  bootstrap<-etr_bootstrap_functional_mixed_effects_full_refit
  expect_error(bootstrap(fit,n_bootstrap=19L),"n_bootstrap")
  expect_error(bootstrap(fit,n_bootstrap=TRUE),"n_bootstrap")
  wrong<-matrix(0L,20L,7L)
  expect_error(bootstrap(fit,n_bootstrap=20L,
    sampled_participant_indices=wrong),"zero-based")
  out_of_range<-matrix(0L,20L,8L)
  out_of_range[1L,1L]<-8L
  expect_error(bootstrap(fit,n_bootstrap=20L,
    sampled_participant_indices=out_of_range),"zero-based")
  slope<-fit
  class(slope)<-c("etr_joint_bspline_mixed_slope",
    "etr_joint_bspline_mixed")
  expect_error(bootstrap(slope,n_bootstrap=20L),
    "structured reference design/covariance dimensions are inconsistent")
  serial<-fit
  serial$residual_correlation<-"ar1"
  expect_error(bootstrap(serial,n_bootstrap=20L),
    "only iid participant")
  nested<-fit
  nested$trial_random_effect<-"functional_intercept"
  expect_error(bootstrap(nested,n_bootstrap=20L),
    "only iid participant")
  expect_false(isTRUE(fit$source_python_full_parity))
})
